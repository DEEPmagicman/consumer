import UIKit
import SceneKit
import GLTFKit2
import simd
import ObjectiveC.runtime

// MARK: - Models
// Declared at the TOP of the file so every extension in this file can see them
// without any "not in scope" errors from the incremental compiler.

struct RootResponse: Codable {
    let list: [SeatingAreaAPIModel]
}

struct SeatingAreaAPIModel: Codable {
    let id:                  String
    let parentSeatingAreaId: String
    let name:                String
    let highlight:           String?
    let maxGuest:            Int?
}

/// Lightweight DTO used only inside this file to carry seating data from the
/// mesh-parsing step through to the pin-rendering step.
struct SeatingAreaDTO {
    let id:                  String?
    let parentSeatingAreaId: String?
    let name:                String?
    let highlight:           String?
    let maxGuest:            Int?
    let isDJBoot:            Bool
}

struct SeatingMeta {
    let seatingAreaId: String
    let name:          String
    let parentId:      String
    let maxGuest:      Int
}

private var seatingMetaKey: UInt8 = 0

extension SCNNode {
    var seatingMeta: SeatingMeta? {
        get { objc_getAssociatedObject(self, &seatingMetaKey) as? SeatingMeta }
        set { objc_setAssociatedObject(self, &seatingMetaKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - Collection Helpers

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Dictionary {
    func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: try map { (try transform($0.key), $0.value) })
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Global Constants

private enum PinStyle {
    static let normalColor   = UIColor.systemGreen
    static let selectedColor = UIColor.systemPink
    static let djGold        = UIColor(red: 0.83, green: 0.64, blue: 0.29, alpha: 1.0)
}

enum CameraConfig {
    static let minOrtho: Double = 5
    static let maxOrtho: Double = 120
}

// MARK: - ViewController

final class Tables3DMapVC: UIViewController {

    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var zoneSelector: ZoneSelectorView!

    var event: Event?

    // MARK: Scene
    private let sceneView   = SCNView()
    private var sceneBounds: (min: SCNVector3, max: SCNVector3)?

    // MARK: Camera orbit rig  (orbit pivot → cameraArm → cameraNode)
    private let cameraOrbit = SCNNode()   // pivot at scene centre
    private let cameraNode  = SCNNode()   // holds SCNCamera

    private var currentYaw:   Float = -Float.pi / 10
    private var currentPitch: Float = -Float.pi / 6
    /// World-space distance from orbit pivot to camera; driven by the model's extents.
    private var cameraArmLength: Float = 50

    // MARK: Seating data
    private var selectedSeatingId: String?
    private var seatingAreaByMeshName: [String: SeatingAreaDTO]  = [:]
    private var seatingAreaById:       [String: SeatingArea]     = [:]

    // MARK: Paging
    private var roomItems:       [Layout3DMap]   = []
    private var pagedRoomItems:  [[Layout3DMap]] = []
    private var currentPageIndex    = 0
    private var selectedIndexInPage = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        setupCameraGestures()
        setupZoneSelector()
        fetchLayOut()
        applyPage(animated: false, direction: .none)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.frame = mapView.bounds
    }
}

// MARK: - Scene View Setup

private extension Tables3DMapVC {

    func setupSceneView() {
        sceneView.frame                = mapView.bounds
        sceneView.autoresizingMask     = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor      = .black
        sceneView.allowsCameraControl  = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode     = .multisampling4X
        sceneView.isPlaying            = true
        sceneView.scene                = SCNScene()
        mapView.addSubview(sceneView)
    }

    func setupZoneSelector() {
        zoneSelector.onSelectItem = { [weak self] _, idx in
            guard let self else { return }
            self.selectedIndexInPage = idx
            self.loadSelectedRoomModel()
        }
        zoneSelector.onNextPage = { [weak self] in self?.goNext() }
        zoneSelector.onPrevPage = { [weak self] in self?.goPrev() }
    }
}

// MARK: - API / Data

private extension Tables3DMapVC {

    // Paginated fetch of ALL seating areas for the event.
    func fetchAllSeatingAreas(completion: @escaping () -> Void) {
        guard let eventId = event?.id, !eventId.isEmpty else {
            completion(); return
        }

        var all: [SeatingArea] = []
        var skip    = 0
        var hasMore = true

        func fetchNext() {
            guard hasMore else {
                // Build fast-lookup dictionary by id
                self.seatingAreaById = Dictionary(
                    uniqueKeysWithValues: all.compactMap { area in
                        guard let id = area.id else { return nil }
                        return (id, area)
                    }
                )
                completion()
                return
            }

            TablePresenter.getSeatingAreas(
                eventId: eventId, skip: skip
            ) { [weak self] ok, _, list, apiHasMore in
                guard self != nil else { return }
                if ok {
                    all.append(contentsOf: list)
                    hasMore = apiHasMore
                    skip   += list.count
                    fetchNext()
                } else {
                    completion()
                }
            }
        }
        fetchNext()
    }

    func fetchLayOut() {
        TablePresenter.getConsumerLayout(
            date: "2026-04-09",
            venueId: event?.venue?.id ?? ""
        ) { [weak self] ok, msg, layout in
            guard let self else { return }
            DispatchQueue.main.async {
                if ok, let layout {
                    self.roomItems      = layout.layoutHistories?.first?.layoutHistoryHas3DMaps ?? []
                    self.pagedRoomItems = self.roomItems.chunked(into: 3)
                    self.currentPageIndex    = 0
                    self.selectedIndexInPage = 0
                    self.applyPage(animated: false, direction: .none)
                    self.loadSelectedRoomModel()
                } else {
                    print("Layout error:", msg ?? "unknown")
                }
            }
        }
    }

    func applyPage(animated: Bool, direction: ZoneSelectorView.PageDirection) {
        guard !pagedRoomItems.isEmpty else {
            zoneSelector.setItems(
                [], hasMoreLeft: false, hasMoreRight: false,
                selectedIndex: 0, animated: false,
                borderColors: event?.whiteLabelColor,
                direction: .none, notifySelection: false
            )
            return
        }

        let page  = pagedRoomItems[currentPageIndex]
        let names = page
            .compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let hasLeft  = currentPageIndex > 0
        let hasRight = currentPageIndex < pagedRoomItems.count - 1
        let arrows   = pagedRoomItems.count > 1

        selectedIndexInPage = 0

        zoneSelector.setItems(
            names,
            hasMoreLeft:  arrows && hasLeft,
            hasMoreRight: arrows && hasRight,
            selectedIndex: selectedIndexInPage,
            animated:      animated,
            borderColors:  event?.whiteLabelColor,
            direction:     direction,
            notifySelection: false
        )
    }

    func goNext() {
        guard currentPageIndex < pagedRoomItems.count - 1 else { return }
        currentPageIndex    += 1
        selectedIndexInPage  = 0
        applyPage(animated: true, direction: .next)
        loadSelectedRoomModel()
    }

    func goPrev() {
        guard currentPageIndex > 0 else { return }
        currentPageIndex    -= 1
        selectedIndexInPage  = 0
        applyPage(animated: true, direction: .prev)
        loadSelectedRoomModel()
    }

    func loadSelectedRoomModel() {
        guard !pagedRoomItems.isEmpty else { return }
        let page = pagedRoomItems[currentPageIndex]
        guard selectedIndexInPage >= 0, selectedIndexInPage < page.count else { return }

        let item = page[selectedIndexInPage]
        guard let glb = item.url3dMap, !glb.isEmpty else {
            print("No 3D map for room:", item.name ?? "")
            return
        }
        print("Loading room:", item.name ?? "", "glb:", glb)
        loadGLB_Local(from: glb, layout: item)
    }
}

// MARK: - GLB Loading

private extension Tables3DMapVC {

    func loadGLB_Local(from path: String, layout: Layout3DMap) {
        let baseURL = "https://media.speakeasygo.com/"
        guard let url = URL(string: baseURL + path) else {
            print("Invalid GLB URL:", path); return
        }
        loadGLB(from: url, layout: layout)
    }

    func loadGLB(from url: URL, layout: Layout3DMap) {
        resetSceneState()

        GLTFAsset.load(with: url, options: [:]) { [weak self] _, status, asset, error, _ in
            guard let self,
                  status == .complete,
                  let asset,
                  error == nil else {
                print("GLB load error:", error?.localizedDescription ?? "unknown")
                return
            }

            DispatchQueue.main.async {
                self.fetchAllSeatingAreas {
                    let scene         = SCNScene(gltfAsset: asset)
                    self.sceneView.scene = scene

                    self.buildMeshSeatingMap(asset: asset)
                    self.setupLights()
                    self.renderParentDots(scene: scene)
                    // FIX: pass layout so camera can use API position/fov values
                    self.setupCamera(scene, layout: layout)
                    self.setupTapGesture()
                }
            }
        }
    }

    func resetSceneState() {
        selectedSeatingId = nil
        sceneBounds       = nil
        seatingAreaByMeshName.removeAll()

        // Remove only tap recognizers (pan/pinch stay forever)
        sceneView.gestureRecognizers?
            .filter { $0 is UITapGestureRecognizer }
            .forEach { sceneView.removeGestureRecognizer($0) }

        // Safe removal – nodes may or may not be in the scene yet
        cameraNode.removeFromParentNode()
        cameraOrbit.removeFromParentNode()
        sceneView.scene = SCNScene()
    }
}

// MARK: - Seating Map Parsing
// FIX: GLTF meshes and nodes are independent arrays; we must walk the node tree
// to find which node references which mesh, instead of using parallel indexing.

// MARK: - Gestures

private extension Tables3DMapVC {

    func setupTapGesture() {
        // Remove stale tap recognizers
        sceneView.gestureRecognizers?
            .filter { $0 is UITapGestureRecognizer }
            .forEach { sceneView.removeGestureRecognizer($0) }

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)

        sceneView.addGestureRecognizer(singleTap)
        sceneView.addGestureRecognizer(doubleTap)
    }

    func setupCameraGestures() {
        let pan   = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pan)
        sceneView.addGestureRecognizer(pinch)
    }

    // ── Double-tap: zoom in 25 % ──────────────────────────────────────────────
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let cam = cameraNode.camera else { return }
        let target = max(CameraConfig.minOrtho, cam.orthographicScale * 0.75)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        cam.orthographicScale = target
        SCNTransaction.commit()
    }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let delta = gesture.translation(in: sceneView)
            gesture.setTranslation(.zero, in: sceneView)

            let viewWidth = Float(max(sceneView.bounds.width, 1))
            // ✅ Simple constant sensitivity: full screen swipe ≈ 180°
            let sensitivity: Float = Float.pi / viewWidth

            currentYaw   -= Float(delta.x) * sensitivity
            currentPitch -= Float(delta.y) * sensitivity

            currentPitch = currentPitch.clamped(to: -Float.pi / 2 ... -Float.pi / 20)
            cameraOrbit.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)
        }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let cam = cameraNode.camera else { return }
        let newScale = cam.orthographicScale * Double(1 / gesture.scale)
        cam.orthographicScale = newScale.clamped(to: CameraConfig.minOrtho ... CameraConfig.maxOrtho)
        gesture.scale = 1
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: sceneView)

            let hits = sceneView.hitTest(point, options: [
                SCNHitTestOption.searchMode:        SCNHitTestSearchMode.all.rawValue,
                SCNHitTestOption.boundingBoxOnly:   false,
                SCNHitTestOption.ignoreHiddenNodes: true
            ])

            guard let pin = hits.lazy
                .compactMap({ result -> SCNNode? in
                    var n: SCNNode? = result.node
                    while let node = n {
                        if node.seatingMeta != nil { return node }
                        n = node.parent
                    }
                    return nil
                })
                .first,
                  let meta = pin.seatingMeta
            else { return }

            // ✅ Deselect previous pin
            if let prevId = selectedSeatingId {
                updatePinColor(nodeNamed: prevId, color: PinStyle.normalColor, in: sceneView.scene)
            }

            selectedSeatingId = meta.seatingAreaId

            // ✅ Highlight newly selected pin
            updatePinColor(nodeNamed: meta.seatingAreaId, color: PinStyle.selectedColor, in: sceneView.scene)

            print("✅ Tapped seating:", meta.name, "id:", meta.seatingAreaId)
        }
    
    private func updatePinColor(nodeNamed id: String, color: UIColor, in scene: SCNScene?) {
        scene?.rootNode.enumerateHierarchy { node, _ in
            guard let meta = node.seatingMeta, meta.seatingAreaId == id else { return }
            // Recolor the flat circle child
            node.childNodes
                .first(where: { $0.name == "circle" || $0.geometry is SCNPlane })?
                .geometry?.materials.first?.diffuse.contents = color

            // Also show/hide wave with new color
            node.childNodes
                .first(where: { $0.name == "wave" })?
                .geometry?.materials.first?.diffuse.contents = color.withAlphaComponent(0.6)
        }
    }
    
    func buildMeshSeatingMap(asset: GLTFAsset) {

            var meshIndexToNodeExtras: [Int: [String: Any]] = [:]
            for node in asset.nodes {
                if let meshIndex = asset.meshes.firstIndex(where: { $0 === node.mesh }) {
                    meshIndexToNodeExtras[meshIndex] = normalizeExtras(node.extras)
                }
            }

            for (index, mesh) in asset.meshes.enumerated() {
                guard let meshName = mesh.name else { continue }

                let meshExtras = normalizeExtras(mesh.extras)
                let nodeExtras = meshIndexToNodeExtras[index] ?? [:]
                let extras = nodeExtras.merging(meshExtras) { _, mesh in mesh }

                var dto: SeatingAreaDTO?

                if extras["djtag"] != nil || extras["djboottag"] != nil {
                    dto = SeatingAreaDTO(
                        id: nil, parentSeatingAreaId: nil,
                        name: "DJ", highlight: nil, maxGuest: nil, isDJBoot: true
                    )
                } else if let tag = extras["seatingareatag"] as? String,
                          let area = seatingAreaById[tag] {
                    dto = SeatingAreaDTO(
                        id: area.id,
                        parentSeatingAreaId: area.parentSeatingAreaId,
                        name: area.name,
                        highlight: area.highlight,
                        maxGuest: area.maxGuest,
                        isDJBoot: false
                    )
                } else if let id = extras["seatingareaid"] as? String, !id.isEmpty {
                    let area = seatingAreaById[id]
                    dto = SeatingAreaDTO(
                        id: area?.id ?? id,
                        parentSeatingAreaId: area?.parentSeatingAreaId,
                        name: area?.name ?? "Seating \(id)",
                        highlight: area?.highlight,
                        maxGuest: area?.maxGuest,
                        isDJBoot: false
                    )
                }

                if let dto {
                    seatingAreaByMeshName[meshName] = dto
                    print("🧩 Mesh mapped:", meshName, "→", dto.name ?? "?", "parentId:", dto.parentSeatingAreaId ?? "nil")
                }
            }
        }
}

private extension Tables3DMapVC {
    
    func makeDJDot(position: simd_float3) -> SCNNode {
        
        let root = SCNNode()
        root.simdPosition = position + simd_float3(0, 1.0, 0)
        root.name = "dj-pin"
        
        let uiNode = makeBillboardNode()
        
        let gold = PinStyle.djGold
        
        // Outer wave
        let waveGeo = SCNPlane(width: 0.8, height: 0.8)
        waveGeo.cornerRadius = 0.4
        waveGeo.materials = [constantMaterial(color: gold.withAlphaComponent(0.7))]
        
        let wave = SCNNode(geometry: waveGeo)
        wave.position.z = -0.001
        addWaveAnimation(to: wave)
        uiNode.addChildNode(wave)
        
        // Outer ring
        let outerRing = SCNNode(
            geometry: SCNTorus(ringRadius: 0.60, pipeRadius: 0.030)
        )
        outerRing.geometry?.materials = [constantMaterial(color: UIColor.white)]
        outerRing.eulerAngles.x = -.pi / 2
        outerRing.position.z = 0.002
        uiNode.addChildNode(outerRing)
        
        // Inner ring
        let innerRing = SCNNode(
            geometry: SCNTorus(ringRadius: 0.40, pipeRadius: 0.025)
        )
        innerRing.geometry?.materials = [constantMaterial(color: UIColor.white)]
        innerRing.eulerAngles.x = -.pi / 2
        innerRing.position.z = 0.004
        uiNode.addChildNode(innerRing)
        
        // Inner fill
        let fill = SCNNode(
            geometry: SCNCylinder(radius: 0.34, height: 0.01)
        )
        fill.geometry?.materials = [constantMaterial(color: gold)]
        fill.eulerAngles.x = -.pi / 2
        fill.position.z = 0.006
        uiNode.addChildNode(fill)
        
        // DJ text
        let textGeo = SCNText(string: "DJ", extrusionDepth: 0)
        textGeo.font = .boldSystemFont(ofSize: 12)
        textGeo.flatness = 0.2
        textGeo.materials = [constantMaterial(color: UIColor.white)]
        
        let textNode = SCNNode(geometry: textGeo)
        let (min, max) = textGeo.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation(
            min.x + (max.x - min.x) / 2,
            min.y + (max.y - min.y) / 2,
            0
        )
        textNode.scale = SCNVector3(0.035, 0.035, 0.035)
        textNode.position.z = 0.035
        textNode.renderingOrder = 1000
        uiNode.addChildNode(textNode)
        
        root.addChildNode(uiNode)
        return root
    }
    
    func makeChildDot(position: simd_float3, seatingArea: SeatingAreaDTO) -> SCNNode {
        
        let root = SCNNode()
        root.simdPosition = position + simd_float3(0, 0.2, 0)
        
        let uiNode = makeBillboardNode()
        uiNode.name = "pin"
        
        let circleGeo = SCNPlane(width: 0.20, height: 0.20)
        circleGeo.cornerRadius = 0.1
        circleGeo.materials = [constantMaterial(color: UIColor.clear)]
        
        let circle = SCNNode(geometry: circleGeo)
        circle.name = seatingArea.id ?? ""
        uiNode.addChildNode(circle)
        
        let waveGeo = SCNPlane(width: 0.2, height: 0.2)
        waveGeo.cornerRadius = 0.1
        waveGeo.materials = [
            constantMaterial(color: PinStyle.normalColor.withAlphaComponent(0.6))
        ]
        
        let wave = SCNNode(geometry: waveGeo)
        wave.position.z = -0.001
        wave.isHidden = true
        wave.name = seatingArea.id ?? ""
        addWaveAnimation(to: wave)
        uiNode.addChildNode(wave)
        
        uiNode.seatingMeta = SeatingMeta(
            seatingAreaId: seatingArea.id ?? "",
            name: seatingArea.name ?? "",
            parentId: seatingArea.parentSeatingAreaId ?? "",
            maxGuest: seatingArea.maxGuest ?? 0
        )
        
        root.addChildNode(uiNode)
        return root
    }
    
        func makeParentDot(position: simd_float3, seatingArea: SeatingAreaDTO) -> SCNNode {

            let root = SCNNode()
            root.simdPosition = position + simd_float3(0, 0.8, 0)

            let uiNode = makeBillboardNode()
            uiNode.name = "pin"

            let circle = makeFlatCircle(color: PinStyle.normalColor)
            circle.name = "circle"
            uiNode.addChildNode(circle)

            let line = makeStraightLine(height: 0.8)
            uiNode.addChildNode(line)

            let label = makeLabelCard(
                title: seatingArea.name ?? "",
                guests: seatingArea.maxGuest ?? 0
            )
            label.position = SCNVector3(0, 1.9, 0)
            uiNode.addChildNode(label)

            uiNode.seatingMeta = SeatingMeta(
                seatingAreaId: seatingArea.id ?? seatingArea.parentSeatingAreaId ?? "",
                name: seatingArea.name ?? "",
                parentId: seatingArea.parentSeatingAreaId ?? "",
                maxGuest: seatingArea.maxGuest ?? 0
            )

            root.addChildNode(uiNode)
            return root
        }
    
    func renderParentDots(scene: SCNScene) {
           var renderedParents = Set<String>()

           scene.rootNode.enumerateHierarchy { node, _ in
               guard
                   let geoName = node.geometry?.name,
                   let seating = self.seatingAreaByMeshName[geoName]
               else { return }

               let center = self.worldCenter(of: node)

               if seating.isDJBoot {
                   scene.rootNode.addChildNode(self.makeDJDot(position: center))
                   return
               }

               if let parentId = seating.parentSeatingAreaId, !parentId.isEmpty {
                   // This mesh belongs to a group — render one parent dot per group
                   guard !renderedParents.contains(parentId) else { return }
                   renderedParents.insert(parentId)
                   scene.rootNode.addChildNode(
                       self.makeParentDot(position: center, seatingArea: seating)
                   )
               } else if let id = seating.id, !id.isEmpty {
                   // Top-level / standalone seating area
                   guard !renderedParents.contains(id) else { return }
                   renderedParents.insert(id)
                   scene.rootNode.addChildNode(
                       self.makeChildDot(position: center, seatingArea: seating)
                   )
               }
           }
       }
    
    func makeFlatCircle(color: UIColor) -> SCNNode {
        
        let geo = SCNPlane(width: 0.60, height: 0.60)
        geo.cornerRadius = 0.30
        geo.materials = [
            constantMaterial(color: color)
        ]
        
        let node = SCNNode(geometry: geo)
        
        // Wave
        let waveGeo = SCNPlane(width: 0.60, height: 0.60)
        waveGeo.cornerRadius = 0.30
        waveGeo.materials = [
            constantMaterial(
                color: PinStyle.normalColor.withAlphaComponent(0.6)
            )
        ]
        
        let wave = SCNNode(geometry: waveGeo)
        wave.name = "wave"
        wave.position.z = -0.001
        node.addChildNode(wave)
        
        addWaveAnimation(to: wave)
        
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = [.X, .Y, .Z]
        node.constraints = [billboard]
        
        return node
    }
    
    // MARK: - makeStraightLine: remove the double Y offset

        func makeStraightLine(height: CGFloat) -> SCNNode {
            let geo = SCNPlane(width: 0.035, height: height)
            geo.materials = [constantMaterial(color: UIColor.white)]

            let node = SCNNode(geometry: geo)
            // ✅ SCNPlane is centered at origin — no position offset needed here
            // The caller places the node at the right world position

            let billboard = SCNBillboardConstraint()
            billboard.freeAxes = [.X, .Y, .Z]
            node.constraints = [billboard]

            return node
        }
    
    func makeLabelCard(title: String, guests: Int) -> SCNNode {
        
        let padding: CGFloat = 14
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 42)
        titleLabel.textColor = .white
        titleLabel.sizeToFit()
        
        let guestsLabel = UILabel()
        guestsLabel.text = "\(guests) Guests"
        guestsLabel.font = .systemFont(ofSize: 32, weight: .medium)
        guestsLabel.textColor = .white
        guestsLabel.sizeToFit()
        
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
        dot.backgroundColor = PinStyle.normalColor
        dot.layer.cornerRadius = 9
        
        let rowWidth = dot.frame.width + 8 + guestsLabel.bounds.width
        let width = max(titleLabel.bounds.width, rowWidth) + padding * 2
        let height = titleLabel.bounds.height + guestsLabel.bounds.height + padding * 2 + 8
        
        let container = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        container.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.white.cgColor
        
        titleLabel.frame.origin = CGPoint(
            x: (width - titleLabel.bounds.width) / 2,
            y: padding
        )
        container.addSubview(titleLabel)
        
        dot.frame.origin = CGPoint(
            x: (width - rowWidth) / 2,
            y: titleLabel.frame.maxY + 8
        )
        container.addSubview(dot)
        
        guestsLabel.frame.origin = CGPoint(
            x: dot.frame.maxX + 8,
            y: dot.frame.midY - guestsLabel.bounds.height / 2
        )
        container.addSubview(guestsLabel)
        
        let renderer = UIGraphicsImageRenderer(size: container.bounds.size)
        let image = renderer.image { ctx in
            container.layer.render(in: ctx.cgContext)
        }
        
        let plane = SCNPlane(width: width / 80, height: height / 80)
        plane.materials = [
            constantMaterial(color: image)
        ]
        
        let node = SCNNode(geometry: plane)
        
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = [.X, .Y, .Z]
        node.constraints = [billboard]
        
        return node
    }
}



// MARK: - Camera / Lights / Bounds

private extension Tables3DMapVC {

    /// Sets up the camera using API values when available, falling back to
    /// auto-fitting the scene bounding box.
    ///
    /// Layout3DMap fields consumed:
    ///  - xPosition / yPosition / zPosition  → orbit pivot override
    ///  - fieldOfView                         → converted to ortho scale
    ///  - zoomMin / zoomMax                   → clamp range override
    ///  - verticalRotationMin / Max           → pitch limits
    ///  - horizontalRotationMin / Max         → yaw limits (currently stored for gestures)
    ///  - ratio                               → aspect ratio hint (ignored if view is live)
    func setupCamera(_ scene: SCNScene, layout: Layout3DMap) {
        cameraNode.removeFromParentNode()
        cameraOrbit.removeFromParentNode()

        guard let bounds = cameraFitBounds(in: scene) else {
            print("Cannot compute camera bounds"); return
        }

        let minX = bounds.min.x, maxX = bounds.max.x
        let minY = bounds.min.y, maxY = bounds.max.y
        let minZ = bounds.min.z, maxZ = bounds.max.z

        let sceneWidth  = max(maxX - minX, 1)
        let sceneDepth  = max(maxZ - minZ, 1)
        let sceneHeight = max(maxY - minY, 1)

        // ── Pivot position ────────────────────────────────────────────────────
        // Use API xPosition/yPosition/zPosition when non-nil and non-zero,
        // otherwise default to the horizontal centre at the floor.
        let pivotX: Float = layout.xPosition.flatMap { $0 != 0 ? Float($0) : nil }
                          ?? (minX + maxX) / 2
        let pivotY: Float = layout.yPosition.flatMap { $0 != 0 ? Float($0) : nil }
                          ?? minY
        let pivotZ: Float = layout.zPosition.flatMap { $0 != 0 ? Float($0) : nil }
                          ?? (minZ + maxZ) / 2

        // ── Orthographic scale ────────────────────────────────────────────────
        // Derive from fieldOfView if provided; otherwise auto-fit.
        let viewSize = mapView.bounds.size == .zero ? UIScreen.main.bounds.size : mapView.bounds.size
        let aspect   = Double(max(viewSize.width / max(viewSize.height, 1), 0.1))

        let autoOrtho: Double = {
            let halfD = Double(sceneDepth  * 1.20) / 2
            let halfW = Double(sceneWidth  * 1.20) / (2 * aspect)
            return max(halfD, halfW)
        }()

        let fovOrtho: Double? = layout.fieldOfView.map { fov -> Double in
            // fieldOfView in degrees → half-height of ortho frustum at arm length
            let radians    = fov * .pi / 180
            let armLength  = Double(max(sceneWidth, sceneDepth, sceneHeight) * 1.4)
            return armLength * tan(radians / 2)
        }

        let rawOrtho = fovOrtho ?? autoOrtho

        // Zoom clamp: use API values when provided
        let zMin = layout.zoomMin ?? CameraConfig.minOrtho
        let zMax = layout.zoomMax ?? CameraConfig.maxOrtho
        let initialOrtho = rawOrtho.clamped(to: zMin ... zMax)

        // ── Pitch limits from API ─────────────────────────────────────────────
        let pitchMin = Float(layout.verticalRotationMin ?? Double(-Float.pi / 2))
        let pitchMax = Float(layout.verticalRotationMax ?? Double(-Float.pi / 20))

        // Clamp initial pitch inside API-specified limits
        currentPitch = currentPitch.clamped(to: pitchMin ... pitchMax)
        currentYaw   = -Float.pi / 10

        // ── Build camera ──────────────────────────────────────────────────────
        let camera                       = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale         = initialOrtho
        camera.zNear                     = 0.1
        camera.zFar                      = 10_000
        cameraNode.camera                = camera

        // ── Build orbit rig ───────────────────────────────────────────────────
        // Orbit pivot sits at scene centre (or API-specified position).
        // Camera is positioned along the arm in the orbit's local space;
        // eulerAngles rotate the whole rig so the camera circles the pivot.
        cameraArmLength = max(sceneWidth, sceneDepth, sceneHeight) * 1.4

        cameraOrbit.position    = SCNVector3(pivotX, pivotY, pivotZ)
        cameraOrbit.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)

        // Camera sits directly ahead on the +Z axis of the (un-rotated) rig.
        // After eulerAngles are applied, it ends up at the correct orbit position.
        cameraNode.position = SCNVector3(0, 0, cameraArmLength)

        cameraOrbit.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraOrbit)
        sceneView.pointOfView = cameraNode

        sceneBounds = (
            SCNVector3(minX, minY, minZ),
            SCNVector3(maxX, maxY, maxZ)
        )

        // Store pitch limits so the pan gesture can clamp to them
//        activePitchLimits = pitchMin ... pitchMax
    }

    // Stored per-model pitch limits set during setupCamera
//    private(set) var activePitchLimits: ClosedRange<Float> = (-Float.pi / 2) ... (-Float.pi / 20)

    func cameraFitBounds(in scene: SCNScene) -> (min: SCNVector3, max: SCNVector3)? {
        var relevantNodes: [SCNNode] = []

        scene.rootNode.enumerateHierarchy { node, _ in
            if self.shouldIncludeNodeForCameraFit(node) {
                relevantNodes.append(node)
            }
        }

        // Fallback: use every visible geometry
        if relevantNodes.isEmpty {
            scene.rootNode.enumerateHierarchy { node, _ in
                guard node.geometry != nil, !node.isHidden else { return }
                relevantNodes.append(node)
            }
        }
        guard !relevantNodes.isEmpty else { return nil }

        var minVec = SCNVector3(Float.greatestFiniteMagnitude,
                                Float.greatestFiniteMagnitude,
                                Float.greatestFiniteMagnitude)
        var maxVec = SCNVector3(-Float.greatestFiniteMagnitude,
                                -Float.greatestFiniteMagnitude,
                                -Float.greatestFiniteMagnitude)

        for node in relevantNodes {
            let (lo, hi) = node.boundingBox
            for corner in worldBoundingCorners(node: node, min: lo, max: hi) {
                minVec.x = min(minVec.x, corner.x)
                minVec.y = min(minVec.y, corner.y)
                minVec.z = min(minVec.z, corner.z)
                maxVec.x = max(maxVec.x, corner.x)
                maxVec.y = max(maxVec.y, corner.y)
                maxVec.z = max(maxVec.z, corner.z)
            }
        }

        guard minVec.x.isFinite, minVec.y.isFinite, minVec.z.isFinite,
              maxVec.x.isFinite, maxVec.y.isFinite, maxVec.z.isFinite
        else { return nil }

        return (minVec, maxVec)
    }

    func shouldIncludeNodeForCameraFit(_ node: SCNNode) -> Bool {
        guard let geometry = node.geometry, !node.isHidden else { return false }

        let name = (node.name ?? geometry.name ?? "").lowercased()
        let excluded = ["sky", "sphere", "dome", "environment",
                        "background", "backdrop", "city", "world"]
        if excluded.contains(where: { name.contains($0) }) { return false }

        // Always include tagged seating meshes
        if let geoName = geometry.name, seatingAreaByMeshName[geoName] != nil { return true }

        let (lo, hi) = node.boundingBox
        let maxDim = max(abs(hi.x - lo.x), abs(hi.y - lo.y), abs(hi.z - lo.z))
        return maxDim <= 200
    }

    func worldBoundingCorners(node: SCNNode, min lo: SCNVector3, max hi: SCNVector3) -> [SCNVector3] {
        [
            SCNVector3(lo.x, lo.y, lo.z), SCNVector3(lo.x, lo.y, hi.z),
            SCNVector3(lo.x, hi.y, lo.z), SCNVector3(lo.x, hi.y, hi.z),
            SCNVector3(hi.x, lo.y, lo.z), SCNVector3(hi.x, lo.y, hi.z),
            SCNVector3(hi.x, hi.y, lo.z), SCNVector3(hi.x, hi.y, hi.z)
        ].map { node.convertPosition($0, to: nil) }
    }

    // ── Lighting ──────────────────────────────────────────────────────────────

    func setupLights() {
        sceneView.scene?.rootNode.childNodes
            .filter { $0.light != nil }
            .forEach { $0.removeFromParentNode() }

        let ambient      = SCNLight(); ambient.type = .ambient; ambient.intensity = 2
        let ambientNode  = SCNNode();  ambientNode.light = ambient
        sceneView.scene?.rootNode.addChildNode(ambientNode)

        let directional  = SCNLight()
        directional.type = .directional; directional.intensity = 350; directional.castsShadow = false
        let dirNode      = SCNNode(); dirNode.light = directional
        dirNode.eulerAngles = SCNVector3(-0.9, -0.6, 0)
        sceneView.scene?.rootNode.addChildNode(dirNode)

        sceneView.scene?.lightingEnvironment.intensity = 1
    }
}

// MARK: - Helpers

private extension Tables3DMapVC {

    func normalizeExtras(_ extras: Any?) -> [String: Any] {
        if let dict = extras as? [String: Any] {
            return dict.mapKeys { $0.lowercased() }
        }
        if let array = extras as? [[String: Any]] {
            var dict: [String: Any] = [:]
            for item in array {
                if let key = item["key"] as? String { dict[key.lowercased()] = item["value"] }
            }
            return dict
        }
        if let array = extras as? [[Any]] {
            var dict: [String: Any] = [:]
            for item in array where item.count == 2 {
                if let key = item[0] as? String { dict[key.lowercased()] = item[1] }
            }
            return dict
        }
        return [:]
    }

    func worldCenter(of node: SCNNode) -> simd_float3 {
        let (lo, hi) = node.boundingBox
        let local    = simd_float3((lo.x + hi.x) / 2,
                                   (lo.y + hi.y) / 2,
                                   (lo.z + hi.z) / 2)
        return node.simdConvertPosition(local, to: nil)
    }

    func constantMaterial(color: Any, doubleSided: Bool = true) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents    = color
        mat.lightingModel       = .constant
        mat.isDoubleSided       = doubleSided
        mat.writesToDepthBuffer = false
        mat.readsFromDepthBuffer = false
        return mat
    }

    func addWaveAnimation(to node: SCNNode) {
        node.removeAllActions()
        let scaleUp  = SCNAction.scale(to: 2.2, duration: 1.4)
        let fadeOut  = SCNAction.fadeOut(duration: 1.4)
        let group    = SCNAction.group([scaleUp, fadeOut])
        let reset    = SCNAction.run { $0.opacity = 1; $0.scale = SCNVector3(1, 1, 1) }
        let delay    = SCNAction.wait(duration: 0.3)
        node.runAction(.repeatForever(.sequence([group, reset, delay])))
    }

    func makeBillboardNode() -> SCNNode {
        let n = SCNNode()
        n.constraints = [makeBillboardConstraint()]
        return n
    }

    func makeBillboardConstraint() -> SCNBillboardConstraint {
        let c = SCNBillboardConstraint()
        c.freeAxes = [.X, .Y, .Z]
        return c
    }
}

final class ZoneSelectorView: UIView {

    enum PageDirection {
        case none
        case next
        case prev
    }

    struct ViewModel: Equatable {
        let items: [String]
        let hasMoreLeft: Bool
        let hasMoreRight: Bool
        let selectedIndex: Int
        let animated: Bool
        let borderHexColor: String?
        let direction: PageDirection
        let notifySelection: Bool

        init(
            items: [String],
            hasMoreLeft: Bool,
            hasMoreRight: Bool,
            selectedIndex: Int = 0,
            animated: Bool = true,
            borderHexColor: String? = nil,
            direction: PageDirection = .none,
            notifySelection: Bool = false
        ) {
            self.items = items
            self.hasMoreLeft = hasMoreLeft
            self.hasMoreRight = hasMoreRight
            self.selectedIndex = selectedIndex
            self.animated = animated
            self.borderHexColor = borderHexColor
            self.direction = direction
            self.notifySelection = notifySelection
        }
    }

    // MARK: - Public API

    var onSelectItem: ((String, Int) -> Void)?
    var onNextPage: (() -> Void)?
    var onPrevPage: (() -> Void)?

    var titleText: String = "SELECT ZONE" {
        didSet { titleLabel.text = titleText }
    }

    func setItems(
        _ items: [String],
        hasMoreLeft: Bool,
        hasMoreRight: Bool,
        selectedIndex: Int = 0,
        animated: Bool = true,
        borderColors: String?,
        direction: PageDirection = .none,
        notifySelection: Bool = false
    ) {
        let sanitizedItems = items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let model = ViewModel(
            items: sanitizedItems,
            hasMoreLeft: hasMoreLeft,
            hasMoreRight: hasMoreRight,
            selectedIndex: selectedIndex,
            animated: animated,
            borderHexColor: borderColors,
            direction: direction,
            notifySelection: notifySelection
        )

        apply(model)
    }

    // MARK: - Private State

    private var currentItems: [String] = []
    private var selectedIndex: Int = 0
    private var hasMoreLeft: Bool = false
    private var hasMoreRight: Bool = false
    private var borderHexColor: String?

    private var segmentButtons: [UIButton] = []
    private var needsSelectionLayoutUpdate = false

    // MARK: - UI

    private let titleLabel = UILabel()
    private let pillContainer = UIView()
    private let innerStack = UIStackView()
    private let segmentsStack = UIStackView()
    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)
    private let selectionView = UIView()

    private let bgColor = UIColor.clear
    private let pillFill = UIColor(white: 0.10, alpha: 1.0)
    private let selectedFill = UIColor(white: 0.20, alpha: 0.5)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        pillContainer.layer.cornerRadius = pillContainer.bounds.height / 2
        selectionView.layer.cornerRadius = selectionView.bounds.height / 2

        if needsSelectionLayoutUpdate {
            needsSelectionLayoutUpdate = false
            updateSelection(animated: false)
        }
    }
}

// MARK: - Setup

private extension ZoneSelectorView {

    func setup() {
        backgroundColor = bgColor

        titleLabel.text = titleText
        titleLabel.textColor = .white.withAlphaComponent(0.92)
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        pillContainer.backgroundColor = pillFill
        pillContainer.layer.borderWidth = 1.5
        pillContainer.layer.borderColor = UIColor.white.cgColor
        pillContainer.clipsToBounds = true
        pillContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pillContainer)

        selectionView.backgroundColor = selectedFill
        selectionView.isUserInteractionEnabled = false
        pillContainer.addSubview(selectionView)

        configureArrowButton(leftButton, systemName: "chevron.left")
        configureArrowButton(rightButton, systemName: "chevron.right")

        leftButton.addTarget(self, action: #selector(didTapLeft), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(didTapRight), for: .touchUpInside)

        segmentsStack.axis = .horizontal
        segmentsStack.alignment = .fill
        segmentsStack.distribution = .fillEqually
        segmentsStack.spacing = 0
        segmentsStack.translatesAutoresizingMaskIntoConstraints = false

        innerStack.axis = .horizontal
        innerStack.alignment = .center
        innerStack.spacing = 10
        innerStack.translatesAutoresizingMaskIntoConstraints = false

        innerStack.addArrangedSubview(leftButton)
        innerStack.addArrangedSubview(segmentsStack)
        innerStack.addArrangedSubview(rightButton)

        pillContainer.addSubview(innerStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            pillContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            pillContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            pillContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            pillContainer.heightAnchor.constraint(equalToConstant: 42),
            pillContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            innerStack.leadingAnchor.constraint(equalTo: pillContainer.leadingAnchor, constant: 10),
            innerStack.trailingAnchor.constraint(equalTo: pillContainer.trailingAnchor, constant: -10),
            innerStack.topAnchor.constraint(equalTo: pillContainer.topAnchor, constant: 1),
            innerStack.bottomAnchor.constraint(equalTo: pillContainer.bottomAnchor, constant: -1),

            leftButton.widthAnchor.constraint(equalToConstant: 30),
            leftButton.heightAnchor.constraint(equalToConstant: 30),
            rightButton.widthAnchor.constraint(equalToConstant: 30),
            rightButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        pillContainer.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        pillContainer.addGestureRecognizer(swipeRight)

        renderCurrentState(animatedSelection: false, notifySelection: false, pageDirection: .none)
    }

    func configureArrowButton(_ button: UIButton, systemName: String) {
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.9)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
    }
}

// MARK: - State Application

private extension ZoneSelectorView {

    func apply(_ model: ViewModel) {
        currentItems = model.items
        hasMoreLeft = model.hasMoreLeft
        hasMoreRight = model.hasMoreRight
        borderHexColor = model.borderHexColor

        if let hex = borderHexColor, !hex.isEmpty {
            pillContainer.layer.borderColor = UIColor(hex: hex).cgColor
        } else {
            pillContainer.layer.borderColor = UIColor.white.cgColor
        }

        selectedIndex = clampedIndex(
            model.selectedIndex,
            for: currentItems
        )

        renderCurrentState(
            animatedSelection: false,
            notifySelection: model.notifySelection,
            pageDirection: model.animated ? model.direction : .none
        )
    }

    func renderCurrentState(
        animatedSelection: Bool,
        notifySelection: Bool,
        pageDirection: PageDirection
    ) {
        updateArrowState()

        let contentUpdate = { [weak self] in
            guard let self = self else { return }
            self.rebuildButtons()
            self.setNeedsLayout()
            self.layoutIfNeeded()
            self.needsSelectionLayoutUpdate = true
            self.updateSelection(animated: animatedSelection)

            if notifySelection {
                self.emitSelectionIfPossible()
            }
        }

        guard pageDirection != .none else {
            contentUpdate()
            return
        }

        animatePageChange(direction: pageDirection, update: contentUpdate)
    }

    func clampedIndex(_ index: Int, for items: [String]) -> Int {
        guard !items.isEmpty else { return 0 }
        return min(max(0, index), items.count - 1)
    }
}

// MARK: - Button Building

private extension ZoneSelectorView {

    func rebuildButtons() {
        segmentButtons.forEach {
            $0.removeTarget(nil, action: nil, for: .allEvents)
        }

        for view in segmentsStack.arrangedSubviews {
            segmentsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        segmentButtons.removeAll()

        guard !currentItems.isEmpty else {
            selectionView.isHidden = true
            return
        }

        for (index, title) in currentItems.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            button.backgroundColor = .clear
            button.clipsToBounds = true
            button.tag = index
            button.addTarget(self, action: #selector(didTapSegment(_:)), for: .touchUpInside)

            segmentButtons.append(button)
            segmentsStack.addArrangedSubview(button)
        }

        selectionView.isHidden = false
    }
}

// MARK: - Actions

private extension ZoneSelectorView {

    @objc func didTapSegment(_ sender: UIButton) {
        let newIndex = clampedIndex(sender.tag, for: currentItems)
        guard newIndex != selectedIndex || currentItems.indices.contains(newIndex) else {
            emitSelectionIfPossible()
            return
        }

        selectedIndex = newIndex
        updateSelection(animated: true)
        emitSelectionIfPossible()
    }

    @objc func didTapLeft() {
        guard hasMoreLeft else { return }
        onPrevPage?()
    }

    @objc func didTapRight() {
        guard hasMoreRight else { return }
        onNextPage?()
    }

    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            didTapRight()
        case .right:
            didTapLeft()
        default:
            break
        }
    }

    func emitSelectionIfPossible() {
        guard currentItems.indices.contains(selectedIndex) else { return }
        onSelectItem?(currentItems[selectedIndex], selectedIndex)
    }
}

// MARK: - Selection UI

private extension ZoneSelectorView {

    func updateArrowState() {
        setArrow(leftButton, enabled: hasMoreLeft)
        setArrow(rightButton, enabled: hasMoreRight)
    }

    func setArrow(_ button: UIButton, enabled: Bool) {
        button.isEnabled = enabled
        button.isHidden = !enabled

        UIView.animate(withDuration: 0.15) {
            button.alpha = enabled ? 1.0 : 0.0
        }
    }

    func updateSelection(animated: Bool) {
        guard !currentItems.isEmpty,
              selectedIndex >= 0,
              selectedIndex < segmentButtons.count else {
            selectionView.isHidden = true
            return
        }

        guard segmentButtons[selectedIndex].bounds.width > 0 else {
            needsSelectionLayoutUpdate = true
            return
        }

        selectionView.isHidden = false

        let selectedButton = segmentButtons[selectedIndex]
        let frameInPill = selectedButton.superview?.convert(selectedButton.frame, to: pillContainer) ?? .zero

        let expandX: CGFloat = 6
        let insetY: CGFloat = 1
        let targetFrame = frameInPill.insetBy(dx: -expandX, dy: insetY)

        for (index, button) in segmentButtons.enumerated() {
            button.alpha = (index == selectedIndex) ? 1.0 : 0.85
        }

        let applyFrame = {
            self.selectionView.frame = targetFrame
            self.selectionView.layer.cornerRadius = targetFrame.height / 2
        }

        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.88,
                initialSpringVelocity: 0.25,
                options: [.beginFromCurrentState, .curveEaseOut]
            ) {
                applyFrame()
            }
        } else {
            applyFrame()
        }
    }
}

// MARK: - Page Animation

private extension ZoneSelectorView {

    func animatePageChange(direction: PageDirection, update: @escaping () -> Void) {
        let offset: CGFloat = (direction == .next) ? -40 : 40

        UIView.animate(
            withDuration: 0.18,
            delay: 0,
            options: [.curveEaseIn]
        ) {
            self.segmentsStack.transform = CGAffineTransform(translationX: offset, y: 0)
            self.segmentsStack.alpha = 0
            self.selectionView.alpha = 0
        } completion: { _ in
            update()

            self.segmentsStack.transform = CGAffineTransform(translationX: -offset, y: 0)

            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                usingSpringWithDamping: 0.92,
                initialSpringVelocity: 0.2,
                options: [.curveEaseOut]
            ) {
                self.segmentsStack.transform = .identity
                self.segmentsStack.alpha = 1
                self.selectionView.alpha = 1
            } completion: { _ in
                self.updateSelection(animated: false)
            }
        }
    }
}


private extension UIColor {
    static func seatingDotColor(from hex: String?) -> UIColor {
        guard let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines),
              !hex.isEmpty else {
            return UIColor.systemGreen
        }
        return UIColor(hex: hex)
    }
}
