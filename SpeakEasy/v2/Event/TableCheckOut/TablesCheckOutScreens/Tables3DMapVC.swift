import UIKit
import SceneKit
import GLTFKit2
import simd
import ObjectiveC.runtime

// MARK: - Global Constants

private enum PinStyle {
    static let normalColor = UIColor.systemGreen
    static let selectedColor = UIColor.systemPink
    static let djGold = UIColor(red: 0.83, green: 0.64, blue: 0.29, alpha: 1.0)
}

enum CameraConfig {
    static let minOrtho: Double = 5
    static let maxOrtho: Double = 60
}

final class Tables3DMapVC: UIViewController {

    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var zoneSelector: ZoneSelectorView!

    private let sceneView = SCNView()
    private let tapCategory: Int = 4
    var event: Event?

    private var sceneBounds: (min: SCNVector3, max: SCNVector3)?
    private var selectedSeatingId: String?

    var parentByChildId: [String: SeatingAreaAPIModel] = [:]
    var seatingAreaByMeshName: [String: SeatingAreaDTO] = [:]

    private var seatingAreaById: [String: SeatingArea] = [:]

    private var currentYaw: Float = -Float.pi / 14
    private var currentPitch: Float = -Float.pi / 7

    private let cameraOrbit = SCNNode()
    private let cameraNode = SCNNode()
    
    private var roomItems: [Layout3DMap] = []
    private var pagedRoomItems: [[Layout3DMap]] = []

    private var currentPageIndex: Int = 0
    private var selectedIndexInPage: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        setupCameraGestures()

        // replace with server URL
//        loadGLB_Local(from: "stage/url3dmap/l-1768979169047-CnOS.glb")
        
        zoneSelector.onSelectItem = { [weak self] name, idx in
               self?.selectedIndexInPage = idx
               print("Selected item:", name, "index:", idx)
            self?.loadSelectedRoomModel()
           }

           // Next page requested (arrow or swipe)
           zoneSelector.onNextPage = { [weak self] in
               self?.goNext()
           }

           // Prev page requested
           zoneSelector.onPrevPage = { [weak self] in
               self?.goPrev()
           }
           fetchLayOut()
           applyPage(animated: false, direction: .none)
    }

    private func fetchAllSeatingAreas(completion: @escaping () -> Void) {
        guard let eventId = event?.id, !eventId.isEmpty else { completion(); return }

        var all: [SeatingArea] = []
        var skip = 0
        var hasMore = true

        func fetchNext() {
            guard hasMore else {
                self.seatingAreaById = Dictionary(uniqueKeysWithValues: all.compactMap { sa in
                    guard let id = sa.id else { return nil }
                    return (id, sa)
                })
                completion()
                return
            }

            TablePresenter.getSeatingAreas(eventId: eventId, skip: skip) { [weak self] isSuccess, _, list, apiHasMore in
                guard self != nil else { return }
                if isSuccess {
                    all.append(contentsOf: list)
                    hasMore = apiHasMore
                    skip += list.count
                    fetchNext()
                } else {
                    completion()
                }
            }
        }

        fetchNext()
    }
    
    func fetchLayOut() {
        TablePresenter.getConsumerLayout(date: "2026-02-25") { [weak self] ok, msg, layout in
            guard let self else { return }

            DispatchQueue.main.async {
                if ok, let layout {
                 
                    self.roomItems = layout.layoutHistories?.first?.layoutHistoryHas3DMaps ?? []
                    self.pagedRoomItems =  self.roomItems.chunked(into: 3)

                    self.currentPageIndex = 0
                    self.selectedIndexInPage = 0

                    // Show first page names
                    self.applyPage(animated: false, direction: .none)

                    // Auto load first room model
                    self.loadSelectedRoomModel()
                } else {
                    print("error:", msg ?? "")
                }
            }
        }
    }
    
    private func applyPage(animated: Bool, direction: ZoneSelectorView.PageDirection) {
        guard !pagedRoomItems.isEmpty else { return }

        let page = pagedRoomItems[currentPageIndex]
        let names: [String] = page.compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let hasLeft = currentPageIndex > 0
        let hasRight = currentPageIndex < (pagedRoomItems.count - 1)

        zoneSelector.setItems(
            names,
            hasMoreLeft: hasLeft,
            hasMoreRight: hasRight,
            selectedIndex: min(selectedIndexInPage, max(names.count - 1, 0)),
            animated: animated,
            direction: direction
        )
    }

     private func goNext() {
         guard currentPageIndex < pagedRoomItems.count - 1 else { return }
         currentPageIndex += 1
         selectedIndexInPage = 0
         applyPage(animated: true, direction: .next)
         loadSelectedRoomModel()
     }

     private func goPrev() {
         guard currentPageIndex > 0 else { return }
         currentPageIndex -= 1
         selectedIndexInPage = 0
         applyPage(animated: true, direction: .prev)
         loadSelectedRoomModel()
     }
    
    private func loadSelectedRoomModel() {
        guard !pagedRoomItems.isEmpty else { return }
        let page = pagedRoomItems[currentPageIndex]
        guard selectedIndexInPage >= 0, selectedIndexInPage < page.count else { return }

        let item = page[selectedIndexInPage]

        guard let glb = item.url3dMap, !glb.isEmpty else {
            print("No 3D map for room:", item.name ?? "")
            return
        }

        print("Loading room:", item.name ?? "", "glb:", glb)

        // call your loader
        loadGLB_Local(from: glb)
    }
}

// MARK: - Scene Setup

private extension Tables3DMapVC {

    func setupSceneView() {
        sceneView.frame = mapView.bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .black
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.scene = SCNScene()
        mapView.addSubview(sceneView)
    }
}

// MARK: - GLB Loading

private extension Tables3DMapVC {

    private func centeredContentNode(from scene: SCNScene) -> SCNNode {
        let container = SCNNode()
        container.name = "CONTENT_CONTAINER"

        // Move all children into container
        let children = scene.rootNode.childNodes
        children.forEach { child in
            child.removeFromParentNode()
            container.addChildNode(child)
        }

        // Compute bbox for container
        let (min, max) = container.boundingBox
        let center = SCNVector3(
            (min.x + max.x) / 2,
            (min.y + max.y) / 2,
            (min.z + max.z) / 2
        )

        // Pivot to center so container is centered at origin
        container.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)

        // Put it at origin
        container.position = SCNVector3Zero

        // Put container back
        scene.rootNode.addChildNode(container)
        return container
    }

    private func boundingBox(of node: SCNNode) -> (min: SCNVector3, max: SCNVector3) {
        let (min, max) = node.boundingBox
        return (min, max)
    }

    func loadGLB_Local(from path: String) {

        let baseURL = "https://media.speakeasygo.com/"

        guard let url = URL(string: baseURL + path) else {
            print("Invalid GLB URL")
            return
        }

        loadGLB(from: url)
    }

//
//    func loadGLB_Local() {
////        guard let url = Bundle.main.url(forResource: "hotel_map", withExtension: "glb") else {
////            fatalError("GLB not found")
////        }
////        loadGLB(from: url)
//    }

    // SERVER READY
    func loadGLB(from url: URL) {
        GLTFAsset.load(with: url, options: [:]) { [weak self] _, status, asset, error, _ in
            guard let self, status == .complete, let asset, error == nil else { return }

            DispatchQueue.main.async {
                self.fetchAllSeatingAreas {
                    let scene = SCNScene(gltfAsset: asset)
                    self.sceneView.scene = scene

                    self.buildMeshSeatingMap(asset: asset)
                    self.setupCamera(scene)
                    self.setupLights()
                    self.setupTapGesture()
                    self.renderParentDots(scene: scene)
                }
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - JSON

private extension Tables3DMapVC {

    func loadSeatingAreaMap() {

        guard
            let url = Bundle.main.url(forResource: "response", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let root = try? JSONDecoder().decode(RootResponse.self, from: data)
        else {
            print("❌ JSON load failed")
            return
        }

        for area in root.list {
            parentByChildId[area.parentSeatingAreaId] = area
        }
    }
}

private extension Tables3DMapVC {

    private func buildMeshSeatingMap(asset: GLTFAsset) {

        seatingAreaByMeshName.removeAll()

        func string(_ extras: [String: Any], keys: [String]) -> String? {
            for key in keys {
                if let ss = extras[key] as? String, !ss.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return ss
                }
                if let ss = extras[key] as? NSString {
                    let vv = String(ss)
                    if !vv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return vv }
                }
            }
            return nil
        }

        func hasAny(_ extras: [String: Any], keys: [String]) -> Bool {
            for key in keys where extras[key] != nil { return true }
            return false
        }

        for (index, mesh) in asset.meshes.enumerated() {

            guard let meshName = mesh.name else { continue }

            let meshExtras = normalizeExtras(mesh.extras)
            let nodeExtras = (index < asset.nodes.count) ? normalizeExtras(asset.nodes[index].extras) : [:]
            let extras = meshExtras.merging(nodeExtras) { _, new in new }

            // 1) DJ
            if hasAny(extras, keys: ["djtag", "djboottag", "dj", "djboot", "dj_booth"]) {
                seatingAreaByMeshName[meshName] = SeatingAreaDTO(
                    id: nil,
                    parentSeatingAreaId: nil,
                    name: "DJ",
                    highlight: nil,
                    maxGuest: nil,
                    isDJBoot: true
                )
                continue
            }

            // 2) Parent (seatingAreaTag)
            if let parentId = string(extras, keys: ["seatingareatag", "seating_area_tag", "seatingAreaTag", "parentseatingareaid", "parent_seating_area_id"]) {
                if let sa = seatingAreaById[parentId] {
                    seatingAreaByMeshName[meshName] = SeatingAreaDTO(
                        id: sa.id,
                        parentSeatingAreaId: sa.id, // ✅ parent
                        name: sa.name,
                        highlight: sa.highlight,
                        maxGuest: sa.maxGuest,
                        isDJBoot: false
                    )
                } else {
                    seatingAreaByMeshName[meshName] = SeatingAreaDTO(
                        id: parentId,
                        parentSeatingAreaId: parentId,
                        name: "Seating \(parentId)",
                        highlight: nil,
                        maxGuest: nil,
                        isDJBoot: false
                    )
                }
                continue
            }

            // 3) Child (seatingAreaId)
            if let childId = string(extras, keys: ["seatingareaid", "seating_area_id", "seatingAreaId", "seatId", "seat_id"]) {
                if let sa = seatingAreaById[childId] {
                    seatingAreaByMeshName[meshName] = SeatingAreaDTO(
                        id: sa.id,
                        parentSeatingAreaId: nil, // ✅ child
                        name: sa.name,
                        highlight: sa.highlight,
                        maxGuest: sa.maxGuest,
                        isDJBoot: false
                    )
                } else {
                    seatingAreaByMeshName[meshName] = SeatingAreaDTO(
                        id: childId,
                        parentSeatingAreaId: nil,
                        name: "Seating \(childId)",
                        highlight: nil,
                        maxGuest: nil,
                        isDJBoot: false
                    )
                }
                continue
            }
        }
    }

    func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tap)

        let tap2 = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap2.numberOfTapsRequired = 1

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2

        tap.require(toFail: doubleTap)

        sceneView.addGestureRecognizer(tap)
        sceneView.addGestureRecognizer(doubleTap)
    }

    func setupCameraGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))

        sceneView.addGestureRecognizer(pan)
        sceneView.addGestureRecognizer(pinch)
    }

    @objc func handleDoubleTap(_ ges: UITapGestureRecognizer) {
        guard let cam = cameraNode.camera else { return }

        // ✅ Zoom in by a step, clamp
        let target = max(CameraConfig.minOrtho, cam.orthographicScale * 0.75)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        cam.orthographicScale = target
        SCNTransaction.commit()
    }

    @objc func handlePan(_ ges: UIPanGestureRecognizer) {

        let delta = ges.translation(in: sceneView)
        ges.setTranslation(.zero, in: sceneView)

        let sensitivity: Float = 0.005

        // FULL LEFT ↔ RIGHT
        currentYaw -= Float(delta.x) * sensitivity

        // LIMITED TOP ↕ BOTTOM
        currentPitch -= Float(delta.y) * sensitivity

        let minPitch: Float = -Float.pi / 2
        let maxPitch: Float = -Float.pi / 20
        currentPitch = min(max(currentPitch, minPitch), maxPitch)

        // Rotate ORBIT (not camera)
        cameraOrbit.eulerAngles = SCNVector3(
            currentPitch,
            currentYaw,
            0
        )
    }

//    @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
//
//        guard let cam = cameraNode.camera else { return }
//
//        cam.orthographicScale *= Double(1 / g.scale)
//        g.scale = 1
//
//        cam.orthographicScale = min(
//            max(cam.orthographicScale, CameraConfig.minOrtho),
//            CameraConfig.maxOrtho
//        )
//    }

    @objc func handleTap(_ ges: UITapGestureRecognizer) {
        let pp = ges.location(in: sceneView)

        // ✅ Better hit test (don’t miss thin nodes)
        let hits = sceneView.hitTest(pp, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue,
            SCNHitTestOption.boundingBoxOnly: false,
            SCNHitTestOption.ignoreHiddenNodes: true
        ])

        guard let hitNode = hits.first?.node else { return }

        resetAllDots()

        // climb until you reach pin container
        var node: SCNNode? = hitNode
        while node != nil && node?.name != "pin" {
            node = node?.parent
        }

        guard let pin = node, let meta = pin.seatingMeta else { return }

        setPinSelected(pin, color: PinStyle.selectedColor)
        selectedSeatingId = meta.seatingAreaId
        setChildPinColor(meta.seatingAreaId, color: PinStyle.selectedColor)
    }

    func resetAllDots() {
        sceneView.scene?.rootNode.enumerateChildNodes { node, _ in
            if node.name == "pin" {
                updateCircle(node, color: PinStyle.normalColor)
            }
        }

        if let id = selectedSeatingId {
            setChildPinColor(id, color: .clear)
            selectedSeatingId = nil
        }
    }

    private func setPinSelected(_ pin: SCNNode, color: UIColor) {
        updateCircle(pin, color: color)
    }

    func setChildPinColor(_ seatingId: String, color: UIColor) {
        sceneView.scene?.rootNode.enumerateChildNodes { node, _ in
            if node.name == seatingId,
               let plane = node.geometry as? SCNPlane {
                plane.firstMaterial?.diffuse.contents = color
                node.isHidden = color == .clear
            }
        }
    }

    private func updateCircle(_ node: SCNNode, color: UIColor) {
        guard let circle = node.childNode(withName: "circle", recursively: true),
              let plane = circle.geometry as? SCNPlane
        else { return }

        plane.firstMaterial?.diffuse.contents = color

        if let wave = circle.childNode(withName: "wave", recursively: true),
           let wavePlane = wave.geometry as? SCNPlane {
            wavePlane.firstMaterial?.diffuse.contents = color
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
        line.position = SCNVector3(0, 0.7, 0)
        uiNode.addChildNode(line)

        let label = makeLabelCard(
            title: seatingArea.name ?? "",
            guests: seatingArea.maxGuest ?? 0
        )
        label.position = SCNVector3(0, 1.9, 0)
        uiNode.addChildNode(label)

        uiNode.seatingMeta = SeatingMeta(
            seatingAreaId: seatingArea.parentSeatingAreaId ?? "",
            name: seatingArea.name ?? "",
            parentId: seatingArea.parentSeatingAreaId ?? "",
            maxGuest: seatingArea.maxGuest ?? 0
        )

        root.addChildNode(uiNode)
        return root
    }

    func renderParentDots(scene: SCNScene) {

        let renderedParents = Set<String>()

        scene.rootNode.enumerateHierarchy { node, _ in
            guard
                let geoName = node.geometry?.name,
                let seating = seatingAreaByMeshName[geoName]
            else { return }

            let center = worldCenter(of: node)

            if seating.isDJBoot {
                scene.rootNode.addChildNode(makeDJDot(position: center))
                return
            }

            if let parentId = seating.parentSeatingAreaId {
                if renderedParents.contains(parentId) { return }
                scene.rootNode.addChildNode(
                    makeParentDot(position: center, seatingArea: seating)
                )
            } else if let id = seating.id, seating.parentSeatingAreaId == nil {
                if renderedParents.contains(id) { return }
                scene.rootNode.addChildNode(
                    makeChildDot(position: center, seatingArea: seating)
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

    func makeStraightLine(height: CGFloat) -> SCNNode {

        let geo = SCNPlane(width: 0.035, height: height)
        geo.materials = [
            constantMaterial(color: UIColor.white)
        ]

        let node = SCNNode(geometry: geo)
        node.position = SCNVector3(0, Float(height / 2), 0)

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

private extension Tables3DMapVC {

    func constantMaterial(
        color: Any,
        doubleSided: Bool = true,
        alpha: CGFloat = 1.0
    ) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.lightingModel = .constant
        mat.isDoubleSided = doubleSided
        mat.writesToDepthBuffer = false
        mat.readsFromDepthBuffer = false
        return mat
    }

    func addWaveAnimation(to node: SCNNode) {
        let scaleUp = SCNAction.scale(to: 2.2, duration: 1.4)
        let fadeOut = SCNAction.fadeOut(duration: 1.4)
        let group = SCNAction.group([scaleUp, fadeOut])

        let reset = SCNAction.run {
            $0.opacity = 1.0
            $0.scale = SCNVector3(1, 1, 1)
        }

        let delay = SCNAction.wait(duration: 0.3)
        let sequence = SCNAction.sequence([group, reset, delay])
        node.runAction(.repeatForever(sequence))
    }

    func makeBillboardNode() -> SCNNode {
        let node = SCNNode()
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = [.X, .Y, .Z]
        node.constraints = [billboard]
        return node
    }
}

private extension Tables3DMapVC {

    func setupCamera(_ scene: SCNScene) {

        // Use the scene’s real bounds
        let minVec = scene.rootNode.boundingBox.min
        let maxVec = scene.rootNode.boundingBox.max
        sceneBounds = (minVec, maxVec)

        // Center of model
        let center = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )

        // Size of model (largest axis)
        let sizeX = maxVec.x - minVec.x
        let sizeZ = maxVec.z - minVec.z
        let sceneSize = max(sizeX, sizeZ)

        // Camera
        let cam = SCNCamera()
        cam.usesOrthographicProjection = true
        cam.zNear = 0.01
        cam.zFar = 10000

        // ✅ Fit to your available container (mapView height matters)
        // More padding = smaller zoom (more space around model)
        let padding: Double = 1.15
        cam.orthographicScale = Double(sceneSize) * padding

        cameraNode.camera = cam

        // ✅ Place camera (distance doesn’t zoom in ortho, but affects perspective of billboards)
        cameraNode.position = SCNVector3(0, Float(sceneSize) * 0.6, Float(sceneSize) * 0.6)

        // ✅ Orbit pivot at model center
        cameraOrbit.position = center
        cameraOrbit.addChildNode(cameraNode)

        // Initial angles (slightly top-down)
        currentPitch = -Float.pi / 6
        currentYaw   = -Float.pi / 10
        cameraOrbit.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)

        scene.rootNode.addChildNode(cameraOrbit)
        sceneView.pointOfView = cameraNode
    }

    func setupLights() {

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 2

        let aNode = SCNNode()
        aNode.light = ambient
        sceneView.scene?.rootNode.addChildNode(aNode)

        let dir = SCNLight()
        dir.type = .directional
        dir.intensity = 350
        dir.castsShadow = false

        let dNode = SCNNode()
        dNode.light = dir
        dNode.eulerAngles = SCNVector3(-0.9, -0.6, 0)
        sceneView.scene?.rootNode.addChildNode(dNode)

        sceneView.scene?.lightingEnvironment.intensity = 1
    }

    func normalizeExtras(_ extras: Any?) -> [String: Any] {

        if let dict = extras as? [String: Any] {
            return dict.mapKeys { $0.lowercased() }
        }

        if let array = extras as? [[String: Any]] {
            var dict: [String: Any] = [:]
            for item in array {
                if let key = item["key"] as? String {
                    dict[key.lowercased()] = item["value"]
                }
            }
            return dict
        }

        if let array = extras as? [[Any]] {
            var dict: [String: Any] = [:]
            for item in array {
                if item.count == 2,
                   let key = item[0] as? String {
                    dict[key.lowercased()] = item[1]
                }
            }
            return dict
        }

        return [:]
    }

    func worldCenter(of node: SCNNode) -> simd_float3 {

        let (min, max) = node.boundingBox

        let localCenter = simd_float3(
            (min.x + max.x) / 2,
            (min.y + max.y) / 2,
            (min.z + max.z) / 2
        )

        return node.simdConvertPosition(localCenter, to: nil)
    }

    @objc func handlePinch(_ ges: UIPinchGestureRecognizer) {

        guard let cam = cameraNode.camera else { return }

        // ✅ Smooth zoom
        // pinch > 1 => zoom in (scale smaller)
        // pinch < 1 => zoom out (scale bigger)
        let zoomFactor = Double(1 / ges.scale)
        let newScale = cam.orthographicScale * zoomFactor

        cam.orthographicScale = min(max(newScale, CameraConfig.minOrtho), CameraConfig.maxOrtho)
        ges.scale = 1
    }
}

struct RootResponse: Codable {
    let list: [SeatingAreaAPIModel]
}

struct SeatingAreaAPIModel: Codable {
    let id: String
    let parentSeatingAreaId: String
    let name: String
    let highlight: String?
    let maxGuest: Int?
}

struct SeatingAreaDTO {
    let id: String?                    // seatingAreaID
    let parentSeatingAreaId: String?   // seatingAreaTag
    let name: String?
    let highlight: String?
    let maxGuest: Int?
    let isDJBoot: Bool                 // djBootTag
}

private var seatingMetaKey: UInt8 = 0

struct SeatingMeta {
    let seatingAreaId: String
    let name: String
    let parentId: String
    let maxGuest: Int
}

extension SCNNode {

    var seatingMeta: SeatingMeta? {
        get {
            objc_getAssociatedObject(self, &seatingMetaKey) as? SeatingMeta
        }
        set {
            objc_setAssociatedObject(
                self,
                &seatingMetaKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

extension Dictionary {
    func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        Dictionary<T, Value>(
            uniqueKeysWithValues: try map { (try transform($0.key), $0.value) }
        )
    }
}

final class ZoneSelectorView: UIView {

    func setItems(_ items: [String],
                  hasMoreLeft: Bool,
                  hasMoreRight: Bool,
                  selectedIndex: Int = 0,
                  animated: Bool = true,
                  direction: PageDirection = .none) {

        self.hasMoreLeft = hasMoreLeft
        self.hasMoreRight = hasMoreRight
        self.currentItems = items
        self.selectedIndex = min(max(0, selectedIndex), max(items.count - 1, 0))

        updateArrowState()

        let apply = { [weak self] in
            self?.rebuildButtons()
            self?.updateSelection(animated: false)
        }

        guard animated, direction != .none else {
            apply()
            return
        }

        animatePageChange(direction: direction, update: apply)
    }

    var onSelectItem: ((String, Int) -> Void)?
    var onNextPage: (() -> Void)?
    var onPrevPage: (() -> Void)?
    var titleText: String = "SELECT ZONE" {
        didSet { titleLabel.text = titleText }
    }

    var pageSize: Int = 3

    // MARK: - Internals

    enum PageDirection { case none, next, prev }

    private var currentItems: [String] = ["Test123", "Heart", "Live"]
    private var selectedIndex: Int = 0

    private var hasMoreLeft: Bool = false
    private var hasMoreRight: Bool = false

    // MARK: - UI

    private let titleLabel = UILabel()
    private let pillContainer = UIView()
    private let innerStack = UIStackView()

    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)

    private let segmentsStack = UIStackView()
    private var segmentButtons: [UIButton] = []

    // Selected capsule behind
    private let selectionView = UIView()

    // MARK: - Style (tweak to match screenshot)

    private let bordersColor = UIColor.systemOrange
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

        // update selection frame after autolayout
        updateSelection(animated: false)
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = bgColor

        // Title
        titleLabel.text = titleText
        titleLabel.textColor = .white.withAlphaComponent(0.92)
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Pill container
        pillContainer.backgroundColor = pillFill
        pillContainer.layer.borderColor = bordersColor.cgColor
        pillContainer.layer.borderWidth = 1.5
        pillContainer.clipsToBounds = true
        pillContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pillContainer)

        // Selected capsule behind segments
        selectionView.backgroundColor = selectedFill
        selectionView.translatesAutoresizingMaskIntoConstraints = true // manual frame
        pillContainer.addSubview(selectionView)

        // Arrow buttons
        configureArrowButton(leftButton, systemName: "chevron.left")
        configureArrowButton(rightButton, systemName: "chevron.right")
        leftButton.addTarget(self, action: #selector(didTapLeft), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(didTapRight), for: .touchUpInside)

        // Segments stack
        segmentsStack.axis = .horizontal
        segmentsStack.distribution = .fillEqually
        segmentsStack.alignment = .fill
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

            pillContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            pillContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            pillContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            pillContainer.heightAnchor.constraint(equalToConstant: 42),
            pillContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            innerStack.leadingAnchor.constraint(equalTo: pillContainer.leadingAnchor, constant: 10),
            innerStack.trailingAnchor.constraint(equalTo: pillContainer.trailingAnchor, constant: -10),
            innerStack.topAnchor.constraint(equalTo: pillContainer.topAnchor, constant: 5),
            innerStack.bottomAnchor.constraint(equalTo: pillContainer.bottomAnchor, constant: -5),

            leftButton.widthAnchor.constraint(equalToConstant: 30),
            leftButton.heightAnchor.constraint(equalToConstant: 30),
            rightButton.widthAnchor.constraint(equalToConstant: 30),
            rightButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        // Swipe gestures
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        pillContainer.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        pillContainer.addGestureRecognizer(swipeRight)

        // Initial render
        rebuildButtons()
        updateArrowState()
        updateSelection(animated: false)
    }

    private func configureArrowButton(_ button: UIButton, systemName: String) {
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.9)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    private func rebuildButtons() {
        segmentButtons.forEach { $0.removeFromSuperview() }
        segmentButtons.removeAll()

        for (idx, title) in currentItems.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            btn.backgroundColor = .clear
            btn.cornerRadius = 8
            btn.clipsToBounds = true
            btn.tag = idx
            btn.addTarget(self, action: #selector(didTapSegment(_:)), for: .touchUpInside)
            segmentButtons.append(btn)
            segmentsStack.addArrangedSubview(btn)
        }

        // If items are fewer than 1, keep selection hidden
        selectionView.isHidden = currentItems.isEmpty
    }

    // MARK: - Actions

    @objc private func didTapSegment(_ sender: UIButton) {
        selectedIndex = sender.tag
        updateSelection(animated: true)

        guard selectedIndex < currentItems.count else { return }
        onSelectItem?(currentItems[selectedIndex], selectedIndex)
    }

    @objc private func didTapLeft() {
        guard hasMoreLeft else { return }
        onPrevPage?()
    }

    @objc private func didTapRight() {
        guard hasMoreRight else { return }
        onNextPage?()
    }

    @objc private func handleSwipe(_ ges: UISwipeGestureRecognizer) {
        if ges.direction == .left {
            didTapRight()
        } else if ges.direction == .right {
            didTapLeft()
        }
    }

    // MARK: - Arrow State

    private func updateArrowState() {
        setArrow(leftButton, enabled: hasMoreLeft)
        setArrow(rightButton, enabled: hasMoreRight)
    }

    private func setArrow(_ button: UIButton, enabled: Bool) {
        button.isEnabled = enabled
        UIView.animate(withDuration: 0.15) {
            button.alpha = enabled ? 1.0 : 0.35
        }
    }

    // MARK: - Selection Capsule

    private func updateSelection(animated: Bool) {
        guard !currentItems.isEmpty,
              selectedIndex >= 0,
              selectedIndex < segmentButtons.count else {
            selectionView.isHidden = true
            return
        }

        selectionView.isHidden = false

        let selectedButton = segmentButtons[selectedIndex]
        let frameInPill = selectedButton.superview!.convert(selectedButton.frame, to: pillContainer)

        let expandX: CGFloat = 6
        let expandY: CGFloat = 1

        let target = frameInPill.insetBy(dx: -expandX, dy: expandY)

        for (ii, bb) in segmentButtons.enumerated() {
            bb.alpha = (ii == selectedIndex) ? 1.0 : 0.85
        }

        let applyFrame = {
            self.selectionView.frame = target
            self.selectionView.layer.cornerRadius = self.selectionView.bounds.height / 2
        }

        if animated {
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           usingSpringWithDamping: 0.88,
                           initialSpringVelocity: 0.25,
                           options: [.beginFromCurrentState, .curveEaseOut]) {
                applyFrame()
            }
        } else {
            applyFrame()
        }
    }

    // MARK: - Page Animation

    private func animatePageChange(direction: PageDirection, update: @escaping () -> Void) {
        let offset: CGFloat = (direction == .next) ? -40 : 40

        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseIn]) {
            self.segmentsStack.transform = CGAffineTransform(translationX: offset, y: 0)
            self.segmentsStack.alpha = 0.0
            self.selectionView.alpha = 0.0
        } completion: { _ in
            update()

            self.segmentsStack.transform = CGAffineTransform(translationX: -offset, y: 0)

            UIView.animate(withDuration: 0.22,
                           delay: 0,
                           usingSpringWithDamping: 0.92,
                           initialSpringVelocity: 0.2,
                           options: [.curveEaseOut]) {
                self.segmentsStack.transform = .identity
                self.segmentsStack.alpha = 1.0
                self.selectionView.alpha = 1.0
            } completion: { _ in
                self.setNeedsLayout()
                self.layoutIfNeeded()
                self.updateSelection(animated: false)
            }
        }
    }
}
