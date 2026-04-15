import UIKit
import SceneKit
import GLTFKit2
import simd
import ObjectiveC.runtime
import MHLoadingButton
 
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

struct SeatingAreaDTO {
    let id:                  String?
    let parentSeatingAreaId: String?
    let name:                String?
    let highlight:           String?
    let maxGuest:            Int?
    let isDJBoot:            Bool
    let minimum:             Double?
    let allowActions:        Bool
}
 
struct SeatingMeta {
    let seatingAreaId: String
    let name:          String
    let parentId:      String
    let maxGuest:      Int
    let allowActions:  Bool
}
 
private var seatingMetaKey: UInt8 = 0
 
extension SCNNode {
    var seatingMeta: SeatingMeta? {
        get { objc_getAssociatedObject(self, &seatingMetaKey) as? SeatingMeta }
        set { objc_setAssociatedObject(self, &seatingMetaKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
 
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
 
extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: try map { (try transform($0.key), $0.value) })
    }
}
 
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
 
private enum PinStyle {
    static let activeColor   = UIColor(red: 0.39, green: 0.84, blue: 0.48, alpha: 1.0)
    static let inactiveColor = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1.0)
    static let selectedColor = UIColor.systemPink
    static let djGold        = UIColor(red: 0.85, green: 0.60, blue: 0.21, alpha: 1.0)
}
 
enum CameraConfig {
    static let minOrtho: Double = 5
    static let maxOrtho: Double = 120
}
 
final class Tables3DMapVC: UIViewController {
 
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var zoneSelector: ZoneSelectorView!
    @IBOutlet weak var buyNowBtnView: UIView!
    @IBOutlet weak var buyNowBtn: LoadingButton!
    
    var event: Event?

    private let sceneView   = SCNView()
    private var sceneBounds: (min: SCNVector3, max: SCNVector3)?
 
    // MARK: Camera orbit rig
    private let cameraOrbit = SCNNode()
    private let cameraNode  = SCNNode()
    private var currentYaw:   Float = -Float.pi / 10
    private var currentPitch: Float = -Float.pi / 6
    private var cameraArmLength: Float = 50
 
    // MARK: Seating data
    
    private var selectedSeatingId: String?
    private var seatingAreaByParentId: [String: SeatingArea] = [:]
    private var seatingAreaById: [String: SeatingArea] = [:]
    var seatingAreas: [SeatingArea] = []
    var seatingAreasFilteredOut: [SeatingArea] = []

    private var seatingAreaFilteredOutByParentId: [String: SeatingArea] = [:]
    private var seatingAreaFilteredOutById: [String: SeatingArea] = [:]

    private var seatingAreaByMeshName: [String: SeatingAreaDTO] = [:]
    private var renderedDJKeys = Set<String>()

    private var roomItems:       [Layout3DMap]   = []
    private var pagedRoomItems:  [[Layout3DMap]] = []
    private var currentPageIndex    = 0
    private var selectedIndexInPage = 0
    private var renderedDJPositions: Set<String> = []
    
    private var activePitchLimits: ClosedRange<Float> = (-Float.pi / 2)...(-Float.pi / 20)
    private var activeYawLimits: ClosedRange<Float> = (-Float.pi)...(Float.pi)
    private var activeZoomLimits: ClosedRange<Double> = CameraConfig.minOrtho...CameraConfig.maxOrtho

    private var initialCameraOrbitPosition: SCNVector3?
    private var initialCameraNodePosition: SCNVector3?
    private var initialCameraOrthoScale: Double?
    private var initialYaw: Float = -Float.pi / 10
    private var initialPitch: Float = -Float.pi / 6
 
    // MARK: - Lifecycle
 
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        setupCameraGestures()
        setupZoneSelector()
        setUpbuyNowBtn()
        fetchLayOut()
        applyPage(animated: false, direction: .none)
        buyNowBtnView.isHidden = true
        zoneSelector.isHidden = false
    }
 
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.frame = mapView.bounds
    }
    
    private func deselectCurrentSeat() {
        selectedSeatingId = nil
        hideCheckoutMode()
    }

    @IBAction func onClickBuyNow(_ sender: Any) {

        guard let selectedId = selectedSeatingId else {
            return
        }

        guard let selectedArea = seatingAreas.first(where: { $0.parentSeatingAreaId == selectedId
        }) else {
            return
        }
        openSeatingArea(selectedArea)
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
    
    func setUpbuyNowBtn() {
        if let hex = self.event?.whiteLabelColor {
            let color = UIColor(hex: hex)
            buyNowBtn.backgroundColor = color
            buyNowBtn.bgColor = color
        }
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
    
    private func adaptFovForAspect(
        baseFov: Double,
        baseAspect: Double,
        targetAspect: Double
    ) -> Double {
        let vFovRad = baseFov * .pi / 180.0
        let hFovRad = 2.0 * atan(tan(vFovRad / 2.0) * baseAspect)
        let newVFovRad = 2.0 * atan(tan(hFovRad / 2.0) / targetAspect)
        return newVFovRad * 180.0 / .pi
    }
}
 
// MARK: - API / Data
private extension Tables3DMapVC {

    func setupSeatingAreas(completion: @escaping () -> Void) {

        let allAreas = seatingAreas
        self.seatingAreaByParentId = Dictionary(
            uniqueKeysWithValues: allAreas.compactMap { area in
                guard let key = area.parentSeatingAreaId, !key.isEmpty else { return nil }
                return (key, area)
            }
        )

        self.seatingAreaById = Dictionary(
            uniqueKeysWithValues: allAreas.compactMap { area in
                guard let key = area.id, !key.isEmpty else { return nil }
                return (key, area)
            }
        )
        self.seatingAreaFilteredOutByParentId = Dictionary(
            uniqueKeysWithValues: seatingAreasFilteredOut.compactMap { area in
                guard let key = area.parentSeatingAreaId, !key.isEmpty else { return nil }
                return (key, area)
            }
        )

        self.seatingAreaFilteredOutById = Dictionary(
            uniqueKeysWithValues: seatingAreasFilteredOut.compactMap { area in
                guard let key = area.id, !key.isEmpty else { return nil }
                return (key, area)
            }
        )

        completion()
    }
    
    func parseMetadata(_ metadata: String?) -> [String: [String: String]] {
        guard
            let metadata,
            let data = metadata.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let objectProperties = json["objectProperties"] as? [String: Any]
        else {
            return [:]
        }

        var result: [String: [String: String]] = [:]

        for (nodeName, props) in objectProperties {
            guard let propDict = props as? [String: Any] else { continue }

            var stringProps: [String: String] = [:]
            for (k, v) in propDict {
                stringProps[k.lowercased()] = "\(v)"
            }

            let variants = [
                nodeName,
                nodeName.replacingOccurrences(of: ".", with: ""),
                nodeName.replacingOccurrences(of: "_", with: "")
            ]

            for key in variants where !key.isEmpty {
                result[key] = stringProps
            }

            if let innerName = stringProps["name"], !innerName.isEmpty {
                let innerVariants = [
                    innerName,
                    innerName.replacingOccurrences(of: ".", with: ""),
                    innerName.replacingOccurrences(of: "_", with: "")
                ]
                for key in innerVariants where !key.isEmpty {
                    result[key] = stringProps
                }
            }
        }

        return result
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
    
    func normalizedString(_ value: Any?) -> String? {
        switch value {
        case let s as String:
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case let n as NSNumber:
            return n.stringValue
        case let d as Double:
            return d == d.rounded() ? String(Int(d)) : String(d)
        case let i as Int:
            return String(i)
        default:
            return nil
        }
    }

    func firstExtraValue(in extras: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = normalizedString(extras[key]), value != "1", value != "1.0" {
                return value
            }
        }
        return nil
    }

    func normalizeExtras(_ extras: Any?) -> [String: Any] {
        if let dict = extras as? [String: Any] {
            return dict.reduce(into: [:]) { partialResult, pair in
                partialResult[pair.key.lowercased()] = pair.value
            }
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

        return [:]
    }

    func resolveSeatingArea(from extras: [String: Any]) -> SeatingAreaDTO? {
        let raw = firstExtraValue(
            in: extras,
            keys: [
                "seatingareatag",
                "seatingareaid",
                "parentseatingareaid",
                "areaid",
                "area_id"
            ]
        )

        guard let raw else { return nil }

        if let area = seatingAreaByParentId[raw] {
            return SeatingAreaDTO(
                id: area.id,
                parentSeatingAreaId: area.parentSeatingAreaId,
                name: area.name,
                highlight: area.highlight,
                maxGuest: area.maxGuest,
                isDJBoot: false, minimum: area.minimum,
                allowActions: true
            )
        }
        
        if let area = seatingAreaById[raw] {
            return SeatingAreaDTO(
                id: area.id,
                parentSeatingAreaId: area.parentSeatingAreaId ?? area.id,
                name: area.name,
                highlight: area.highlight,
                maxGuest: area.maxGuest,
                isDJBoot: false, minimum: area.minimum,
                allowActions: true
            )
        }
        
        if let area = seatingAreaFilteredOutByParentId[raw] {
            return SeatingAreaDTO(
                id: area.id,
                parentSeatingAreaId: area.parentSeatingAreaId,
                name: area.name,
                highlight: area.highlight,
                maxGuest: area.maxGuest,
                isDJBoot: false, minimum: area.minimum,
                allowActions: false
            )
        }

        if let area = seatingAreaFilteredOutById[raw] {
            return SeatingAreaDTO(
                id: area.id,
                parentSeatingAreaId: area.parentSeatingAreaId ?? area.id,
                name: area.name,
                highlight: area.highlight,
                maxGuest: area.maxGuest,
                isDJBoot: false, minimum: area.minimum,
                allowActions: false
            )
        }

        print("⚠️ seating raw id \(raw) not found in any seating map")
        return nil
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
    
    private func openSeatingArea(_ item: SeatingArea) {

        guard item.hideCheckout != true else {
            print("Inquire tapped for:", item.name ?? "")
            return
        }

        Navigate.to.tableSeatingVC(self, seatingArea: item, event: event) { [weak self] time, guestCount, _, _ in
            
            guard let self = self else { return }
            let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            let queueId = "TABLE_BOOKING_QUEUE_\(uuid)"

            TablePresenter.createSeatingAreaBooking(
                eventId: self.event?.id ?? "",
                seatingAreaId: item.id ?? "",
                timeSlotId: item.bookingType == .default ? nil : time,
                venueId: event?.venue?.id ?? "",
                guests: guestCount,
                queueId: queueId
            ) { isSuccess, errMsg, _ in
                
                if isSuccess {
                    if let event = self.event {
                        Navigate.to.tablePurchaseVC(self, queueId: queueId, event: event, seatingAreas: self.seatingAreas)
                    }
                } else {
                    print(errMsg ?? "Booking failed")
                }
            }

            print("Queue ID:", queueId)
            print("Guest Count:", guestCount)
        }
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
        guard let glb = item.url3dMap, !glb.isEmpty else { return }
        loadGLB_Local(from: glb, layout: item)
    }
}
 
private extension Tables3DMapVC {
 
    func loadGLB_Local(from path: String, layout: Layout3DMap) {
        let baseURL = "https://media.speakeasygo.com/"
        guard let url = URL(string: baseURL + path) else { return }
        loadGLB(from: url, layout: layout)
    }
 
    func loadGLB(from url: URL, layout: Layout3DMap) {
        resetSceneState()
 
        GLTFAsset.load(with: url, options: [:]) { [weak self] _, status, asset, error, _ in
            guard let self, status == .complete, let asset, error == nil else {
                print("GLB load error:", error?.localizedDescription ?? "unknown")
                return
            }
 
            DispatchQueue.main.async {
                self.setupSeatingAreas {
                    let scene = SCNScene(gltfAsset: asset)
                    self.sceneView.scene = scene
                    self.buildMeshSeatingMap(asset: asset, layout: layout)
                    self.setupLights()
                    self.renderDots(scene: scene)
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
        renderedDJPositions.removeAll()
 
        sceneView.gestureRecognizers?
            .filter { $0 is UITapGestureRecognizer }
            .forEach { sceneView.removeGestureRecognizer($0) }
 
        cameraNode.removeFromParentNode()
        cameraOrbit.removeFromParentNode()
        sceneView.scene = SCNScene()
    }
}
 
private extension Tables3DMapVC {
    
    func buildMeshSeatingMap(asset: GLTFAsset, layout: Layout3DMap) {
        seatingAreaByMeshName.removeAll()

        let metaProps = parseMetadata(layout.metadata)

        for node in asset.nodes {
            let nodeName = (node.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let meshName = (node.mesh?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            let nodeExtras = normalizeExtras(node.extras)
            let meshExtras = normalizeExtras(node.mesh?.extras)

            let lookupKeys = [
                nodeName,
                meshName,
                nodeName.replacingOccurrences(of: ".", with: ""),
                meshName.replacingOccurrences(of: ".", with: ""),
                nodeName.replacingOccurrences(of: "_", with: ""),
                meshName.replacingOccurrences(of: "_", with: "")
            ].filter { !$0.isEmpty }

            var metadataExtras: [String: Any] = [:]
            for key in lookupKeys {
                if let props = metaProps[key] {
                    for (k, v) in props {
                        metadataExtras[k.lowercased()] = v
                    }
                    break
                }
            }

            var extras = meshExtras
            for (k, v) in nodeExtras { extras[k] = v }
            for (k, v) in metadataExtras { extras[k] = v }

            let djBootValue = (normalizedString(extras["djboottag"]) ?? "").lowercased()
            let djTagValue  = (normalizedString(extras["djtag"]) ?? "").lowercased()

            let isDJ =
                djBootValue == "true" ||
                djTagValue == "true" ||
                nodeName.lowercased() == "icosphere" ||
                meshName.lowercased() == "icosphere"

            if isDJ {
                let dto = SeatingAreaDTO(
                    id: nil,
                    parentSeatingAreaId: nil,
                    name: "DJ",
                    highlight: nil,
                    maxGuest: nil,
                    isDJBoot: true, minimum: nil,
                    allowActions: false
                )

                if !nodeName.isEmpty { seatingAreaByMeshName[nodeName] = dto }
                if !meshName.isEmpty { seatingAreaByMeshName[meshName] = dto }
                continue
            }

            guard let dto = resolveSeatingArea(from: extras) else { continue }

            if !nodeName.isEmpty { seatingAreaByMeshName[nodeName] = dto }
            if !meshName.isEmpty { seatingAreaByMeshName[meshName] = dto }
        }

        print("📦 seatingAreaByMeshName built: \(seatingAreaByMeshName.count) entries")
    }
    
    func worldTopCenter(of node: SCNNode) -> simd_float3 {
        let (lo, hi) = node.boundingBox
        let topLocal = simd_float3((lo.x + hi.x) / 2,
                                   hi.y,
                                   (lo.z + hi.z) / 2)
        return node.simdConvertPosition(topLocal, to: nil)
    }
 
    func extractParentSeatingAreaId(from extras: [String: Any]) -> String? {
        let keys = [
            "seatingareaid", "seatingAreaId", "seatingAreaID",
            "seatingareatag", "seatingAreaTag",
            "areaId", "areaID", "area_id"
        ]
        for key in keys {
            if let s = extras[key] as? String, !s.isEmpty, s != "1", s != "1.0" {
                return s
            }
            if let d = extras[key] as? Double {
                let s = String(Int(d))
                if s != "1" { return s }
            }
        }
        return nil
    }
}
 
// MARK: - Dot Rendering
 
private extension Tables3DMapVC {
 
    func renderDots(scene: SCNScene) {
        renderedDJPositions.removeAll()
 
        var renderedParentIds = Set<String>()
 
        scene.rootNode.enumerateHierarchy { [weak self] node, _ in
            guard let self else { return }
 
            let candidateNames: [String] = [
                node.name,
                node.geometry?.name,
                node.parent?.name
            ].compactMap { $0 }.filter { !$0.isEmpty }
 
            var dto: SeatingAreaDTO?
            for name in candidateNames {
                if let found = self.seatingAreaByMeshName[name] {
                    dto = found; break
                }
            }
            guard let seating = dto else { return }
 
            let topCenter = self.worldTopCenter(of: node)
 
            if seating.isDJBoot {
                let posKey = String(format: "%.1f_%.1f_%.1f", topCenter.x, topCenter.y, topCenter.z)
                guard !renderedDJKeys.contains(posKey) else { return }
                renderedDJKeys.insert(posKey)

                scene.rootNode.addChildNode(makeDJDot(position: topCenter))
                return
            }

            guard let parentId = seating.parentSeatingAreaId, !parentId.isEmpty else { return }
            guard !renderedParentIds.contains(parentId) else { return }
            renderedParentIds.insert(parentId)
 
            let pinNode = self.makeTableDot(position: topCenter, seating: seating)
            self.sceneView.scene?.rootNode.addChildNode(pinNode)
        }
    }

    func makeTableDot(position: simd_float3, seating: SeatingAreaDTO) -> SCNNode {
        let root = SCNNode()
        let scale = seatingUIScaleFactor()
        root.simdPosition = position + simd_float3(0, 0.05, 0)

        let uiNode = makeBillboardNode()
        uiNode.name = "pin"

        let dotColor: UIColor = seating.allowActions
            ? PinStyle.activeColor
            : PinStyle.inactiveColor

        // Invisible tap target so small visual dot is still easy to tap
        let hitGeo = SCNPlane(width: 0.75 * scale, height: 0.75 * scale)
        hitGeo.cornerRadius = 0.375 * scale
        hitGeo.materials = [constantMaterial(color: UIColor.clear)]
        let hitNode = SCNNode(geometry: hitGeo)
        hitNode.name = "hit"
        uiNode.addChildNode(hitNode)

        // Soft pulse like web
        if seating.allowActions {
            let pulseGeo = SCNPlane(width: 0.55, height: 0.55)
            pulseGeo.cornerRadius = 0.275
            pulseGeo.materials = [constantMaterial(color: dotColor.withAlphaComponent(0.22))]
            let pulse = SCNNode(geometry: pulseGeo)
            pulse.name = "wave"
            pulse.position.z = -0.002
            addSoftPulseAnimation(to: pulse)
            uiNode.addChildNode(pulse)
        }

        // Outer glow ring
        let glowGeo = SCNPlane(width: 0.24, height: 0.24)
        glowGeo.cornerRadius = 0.12
        glowGeo.materials = [constantMaterial(color: dotColor.withAlphaComponent(0.45))]
        let glow = SCNNode(geometry: glowGeo)
        glow.name = "glow"
        glow.position.z = -0.001
        uiNode.addChildNode(glow)

        // Main small dot
  
        let dotGeo = SCNPlane(width: 0.16 * scale, height: 0.16 * scale)
        dotGeo.cornerRadius = 0.08 * scale
        dotGeo.materials = [constantMaterial(color: dotColor)]
        let dot = SCNNode(geometry: dotGeo)
        dot.name = "circle"
        dot.position.z = 0.001
        uiNode.addChildNode(dot)

        // Thin white stroke like web
        let ring = SCNNode(geometry: SCNTorus(ringRadius: 0.095 * scale, pipeRadius: 0.008 * scale))
        ring.name = "ring"
        ring.geometry?.materials = [constantMaterial(color: UIColor.white.withAlphaComponent(0.9))]
        ring.eulerAngles.x = -.pi / 2
        ring.position.z = 0.003
        uiNode.addChildNode(ring)

        // Stem line hidden initially
        let line = makeStraightLine(height: 0.72 * scale)
        line.name = "line"
        line.opacity = 0
        uiNode.addChildNode(line)

        // Popup hidden initially
        let label = makeLabelCard(
            title: seating.name ?? "",
            guests: seating.maxGuest ?? 0,
            minAmount: seating.minimum,
            dotColor: dotColor,
            scale: scale
        )
        label.name = "label"
        label.position = SCNVector3(0, Float(1.25 * scale), 0)
        label.opacity = 0
        label.isHidden = true
        line.opacity = 0
        label.isHidden = true
        uiNode.addChildNode(label)

        uiNode.seatingMeta = SeatingMeta(
            seatingAreaId: seating.parentSeatingAreaId ?? seating.id ?? "",
            name: seating.name ?? "",
            parentId: seating.parentSeatingAreaId ?? "",
            maxGuest: seating.maxGuest ?? 0,
            allowActions: seating.allowActions
        )

        root.addChildNode(uiNode)
        return root
    }
    
    func addSoftPulseAnimation(to node: SCNNode) {
        node.removeAllActions()

        let expand = SCNAction.group([
            .scale(to: 1.9, duration: 1.35),
            .fadeOpacity(to: 0.0, duration: 1.35)
        ])

        let reset = SCNAction.run { n in
            n.scale = SCNVector3(1, 1, 1)
            n.opacity = 1
        }

        node.runAction(.repeatForever(.sequence([
            expand,
            reset,
            .wait(duration: 0.15)
        ])))
    }
    
    private func setPopupVisible(for seatingAreaId: String, visible: Bool, in scene: SCNScene?) {
        scene?.rootNode.enumerateHierarchy { node, _ in
            guard let meta = node.seatingMeta, meta.seatingAreaId == seatingAreaId else { return }

            if let label = node.childNodes.first(where: { $0.name == "label" }) {
                if visible {
                    label.isHidden = false
                    label.removeAllActions()
                    label.runAction(.fadeIn(duration: 0.18))
                } else {
                    label.removeAllActions()
                    label.runAction(.sequence([
                        .fadeOut(duration: 0.15),
                        .run { $0.isHidden = true }
                    ]))
                }
            }

            if let line = node.childNodes.first(where: { $0.name == "line" }) {
                line.removeAllActions()
                line.runAction(visible ? .fadeIn(duration: 0.18) : .fadeOut(duration: 0.15))
            }
        }
    }
}
 
// MARK: - Gestures
 
private extension Tables3DMapVC {
 
    func setupTapGesture() {
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
        let viewHeight = Float(max(sceneView.bounds.height, 1))

        let yawSensitivity: Float = Float.pi / viewWidth
        let pitchSensitivity: Float = Float.pi / viewHeight

        currentYaw -= Float(delta.x) * yawSensitivity
        currentPitch -= Float(delta.y) * pitchSensitivity

        currentYaw = currentYaw.clamped(to: activeYawLimits)
        currentPitch = currentPitch.clamped(to: activePitchLimits)

        cameraOrbit.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)
    }
 
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let cam = cameraNode.camera else { return }

        let newScale = cam.orthographicScale * Double(1 / gesture.scale)
        cam.orthographicScale = newScale.clamped(to: activeZoomLimits)
        gesture.scale = 1
    }
 
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: sceneView)

        let hits = sceneView.hitTest(point, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue,
            SCNHitTestOption.boundingBoxOnly: false,
            SCNHitTestOption.ignoreHiddenNodes: true
        ])

        guard let pin = hits.lazy.compactMap({ result -> SCNNode? in
            var current: SCNNode? = result.node
            while let node = current {
                if node.seatingMeta != nil { return node }
                current = node.parent
            }
            return nil
        }).first,
        let meta = pin.seatingMeta else {
            
            // outside tap
            if let prev = selectedSeatingId {
                resetPinColor(seatingAreaId: prev, in: sceneView.scene)
                setPopupVisible(for: prev, visible: false, in: sceneView.scene)
            }
            
            selectedSeatingId = nil
            buyNowBtnView.isHidden = true
            zoneSelector.isHidden = false
            return
        }

        guard meta.allowActions else {
            print("🚫 Tapped unavailable area:", meta.name)
            return
        }

        if let prev = selectedSeatingId, prev != meta.seatingAreaId {
            resetPinColor(seatingAreaId: prev, in: sceneView.scene)
            setPopupVisible(for: prev, visible: false, in: sceneView.scene)
        }

        selectedSeatingId = meta.seatingAreaId
        updatePinColor(seatingAreaId: meta.seatingAreaId, color: PinStyle.selectedColor, in: sceneView.scene)
        setPopupVisible(for: meta.seatingAreaId, visible: true, in: sceneView.scene)

        // added only this UI part
        buyNowBtnView.isHidden = false
        zoneSelector.isHidden = true

        focusCamera(on: pin)

        print("✅ Tapped seating:", meta.name, "id:", meta.seatingAreaId)
    }
//    func resetAllDots() {
//        sceneView.scene?.rootNode.enumerateChildNodes { node, _ in
//            if node.name == "pin" {
//                self.updateCircle(node, color: PinStyle.normalColor)
//            }
//        }
//
//        if let id = selectedSeatingId {
//            setChildPinColor(id, color: .clear)
//        }
//    }
    
    private func showCheckoutMode() {
        buyNowBtnView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.buyNowBtnView.alpha = 1
            self.zoneSelector.alpha = 0
        } completion: { _ in
            self.zoneSelector.isHidden = true
        }
    }

    private func hideCheckoutMode() {
        zoneSelector.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.buyNowBtnView.alpha = 0
            self.zoneSelector.alpha = 1
        } completion: { _ in
            self.buyNowBtnView.isHidden = true
        }
    }
    
    private func focusCamera(on pinNode: SCNNode) {
        let worldPos = pinNode.presentation.worldPosition

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        cameraOrbit.position = SCNVector3(worldPos.x, cameraOrbit.position.y, worldPos.z)

        if let cam = cameraNode.camera {
            let targetScale = max(activeZoomLimits.lowerBound, cam.orthographicScale * 0.88)
            cam.orthographicScale = min(targetScale, activeZoomLimits.upperBound)
        }

        SCNTransaction.commit()
    }
    
    private func resetCameraToInitialView() {
        guard
            let orbitPos = initialCameraOrbitPosition,
            let nodePos = initialCameraNodePosition,
            let ortho = initialCameraOrthoScale,
            let cam = cameraNode.camera
        else { return }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.35
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        cameraOrbit.position = orbitPos
        cameraNode.position = nodePos
        cam.orthographicScale = ortho
        currentYaw = initialYaw
        currentPitch = initialPitch
        cameraOrbit.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)

        SCNTransaction.commit()
    }
    
    private func clearCurrentSelectionUI() {
        guard let selectedId = selectedSeatingId else { return }
        resetPinColor(seatingAreaId: selectedId, in: sceneView.scene)
        setPopupVisible(for: selectedId, visible: false, in: sceneView.scene)
        selectedSeatingId = nil
    }
 
    private func updatePinColor(seatingAreaId: String, color: UIColor, in scene: SCNScene?) {
        scene?.rootNode.enumerateHierarchy { node, _ in
            guard let meta = node.seatingMeta, meta.seatingAreaId == seatingAreaId else { return }

            node.childNodes.first(where: { $0.name == "circle" })?
                .geometry?.materials.first?.diffuse.contents = color

            node.childNodes.first(where: { $0.name == "wave" })?
                .geometry?.materials.first?.diffuse.contents = color.withAlphaComponent(0.55)
        }
    }

    private func resetPinColor(seatingAreaId: String, in scene: SCNScene?) {
        scene?.rootNode.enumerateHierarchy { node, _ in
            guard let meta = node.seatingMeta, meta.seatingAreaId == seatingAreaId else { return }

            let baseColor = meta.allowActions ? PinStyle.activeColor : PinStyle.inactiveColor

            node.childNodes.first(where: { $0.name == "circle" })?
                .geometry?.materials.first?.diffuse.contents = baseColor

            node.childNodes.first(where: { $0.name == "wave" })?
                .geometry?.materials.first?.diffuse.contents = baseColor.withAlphaComponent(0.55)
        }
    }
}
 
// MARK: - DJ Dot
 
private extension Tables3DMapVC {
 
    func makeDJDot(position: simd_float3) -> SCNNode {
        let root     = SCNNode()
        root.simdPosition = position + simd_float3(0, 5.0, 0)
        root.name    = "dj-pin"
 
        let uiNode   = makeBillboardNode()
        let gold     = PinStyle.djGold
        let scale = seatingUIScaleFactor()
 
        // Outer wave (kick-drum animation)
        let waveGeo  = SCNPlane(width: 8.0, height: 8.0)
        waveGeo.cornerRadius = 4.0
        waveGeo.materials    = [constantMaterial(color: gold.withAlphaComponent(0.8))]
        let wave     = SCNNode(geometry: waveGeo)
        wave.position.z = -0.01
        addDJWaveAnimation(to: wave)
        uiNode.addChildNode(wave)
 
        // Outer ring
        let outerRing = SCNNode(geometry: SCNTorus(ringRadius: 6.0, pipeRadius: 0.25))
        outerRing.geometry?.materials = [constantMaterial(color: UIColor.white)]
        outerRing.eulerAngles.x = -.pi / 2
        outerRing.position.z    = 0.01
        uiNode.addChildNode(outerRing)
 
        // Inner ring
        let innerRing = SCNNode(geometry: SCNTorus(ringRadius: 4.5, pipeRadius: 0.2))
        innerRing.geometry?.materials = [constantMaterial(color: UIColor.white)]
        innerRing.eulerAngles.x = -.pi / 2
        innerRing.position.z    = 0.015
        uiNode.addChildNode(innerRing)
 
        // Fill
        let fill = SCNNode(geometry: SCNCylinder(radius: 4.0, height: 0.05))
        fill.geometry?.materials = [constantMaterial(color: UIColor.white)]
        fill.eulerAngles.x = -.pi / 2
        fill.position.z    = 0.02
        uiNode.addChildNode(fill)
 
        // "DJ" text
        let textGeo = SCNText(string: "DJ", extrusionDepth: 0.05)
        textGeo.font      = .boldSystemFont(ofSize: 16)
        textGeo.flatness  = 0.05
        textGeo.materials = [constantMaterial(color: UIColor.white)]
        let textNode = SCNNode(geometry: textGeo)
        let (tMin, tMax) = textGeo.boundingBox
        textNode.pivot        = SCNMatrix4MakeTranslation(
            tMin.x + (tMax.x - tMin.x) / 2,
            tMin.y + (tMax.y - tMin.y) / 2, 0)
        textNode.scale        = SCNVector3(0.25, 0.25, 0.25)
        textNode.position.z   = 0.25
        textNode.renderingOrder = 1000
        uiNode.addChildNode(textNode)
 
        // Glow halo
        let glowGeo = SCNPlane(width: 0.24 * scale, height: 0.24 * scale)
        glowGeo.cornerRadius = 0.12 * scale
        
        glowGeo.materials     = [constantMaterial(color: gold.withAlphaComponent(0.4))]
        let glow = SCNNode(geometry: glowGeo)
        glow.position.z = -0.02
        glow.runAction(.repeatForever(.sequence([
            .scale(to: 1.5, duration: 0.8),
            .scale(to: 0.8, duration: 0.8)
        ])))
        uiNode.addChildNode(glow)
 
        // Float animation (matches web "dj-pulse" vertical oscillation)
        root.runAction(.repeatForever(.sequence([
            .moveBy(x: 0, y: 1.0, z: 0, duration: 1.5),
            .moveBy(x: 0, y: -1.0, z: 0, duration: 1.5)
        ])))
 
        root.addChildNode(uiNode)
        return root
    }
 
    func addDJWaveAnimation(to node: SCNNode) {
        node.removeAllActions()
        node.runAction(.repeatForever(.sequence([
            .group([.scale(to: 4.0, duration: 1.2),
                    .fadeOut(duration: 1.2)]),
            .run { $0.opacity = 1; $0.scale = SCNVector3(1, 1, 1) },
            .wait(duration: 0.5)
        ])))
    }
}
 
// MARK: - Camera / Lights / Bounds
 
private extension Tables3DMapVC {
 
    func setupCamera(_ scene: SCNScene, layout: Layout3DMap) {
        cameraNode.removeFromParentNode()
        cameraOrbit.removeFromParentNode()

        guard let bounds = cameraFitBounds(in: scene) else { return }

        let minX = bounds.min.x, maxX = bounds.max.x
        let minY = bounds.min.y, maxY = bounds.max.y
        let minZ = bounds.min.z, maxZ = bounds.max.z

        let sceneWidth  = max(maxX - minX, 1)
        let sceneDepth  = max(maxZ - minZ, 1)
        let sceneHeight = max(maxY - minY, 1)

        let viewSize = mapView.bounds.size == .zero ? UIScreen.main.bounds.size : mapView.bounds.size
        let aspect = Double(max(viewSize.width / max(viewSize.height, 1), 0.1))

        let autoOrtho: Double = {
            let halfD = Double(sceneDepth * 1.15) / 2.0
            let halfW = Double(sceneWidth * 1.15) / (2.0 * aspect)
            return max(halfD, halfW)
        }()

        // MARK: Safe zoom limits
        let rawZoomMin = layout.zoomMin ?? CameraConfig.minOrtho
        let rawZoomMax = layout.zoomMax ?? CameraConfig.maxOrtho
        let zoomLower = min(rawZoomMin, rawZoomMax)
        let zoomUpper = max(rawZoomMin, rawZoomMax)
        activeZoomLimits = zoomLower...zoomUpper

        // MARK: Safe pitch limits
        let rawPitchMin = Float(layout.verticalRotationMin ?? -80) * .pi / 180
        let rawPitchMax = Float(layout.verticalRotationMax ?? -10) * .pi / 180

        var pitchLower = min(rawPitchMin, rawPitchMax)
        var pitchUpper = max(rawPitchMin, rawPitchMax)

        // Prevent camera from going under / too flat
        pitchUpper = min(pitchUpper, -0.15)

        // Final safety
        if pitchLower > pitchUpper {
            pitchLower = -Float.pi / 2
            pitchUpper = -0.15
        }

        activePitchLimits = pitchLower...pitchUpper

        // MARK: Safe yaw limits
        let rawYawMin = Float(layout.horizontalRotationMin ?? -180) * .pi / 180
        let rawYawMax = Float(layout.horizontalRotationMax ?? 180) * .pi / 180
        let yawLower = min(rawYawMin, rawYawMax)
        let yawUpper = max(rawYawMin, rawYawMax)
        activeYawLimits = yawLower...yawUpper

        let initialOrtho = autoOrtho.clamped(to: activeZoomLimits)

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = initialOrtho
        camera.zNear = 0.1
        camera.zFar = 10_000
        cameraNode.camera = camera

        let pivotX = layout.xPosition.map { Float($0) } ?? ((minX + maxX) / 2)
        let pivotY = layout.yPosition.map { Float($0) } ?? (minY + (maxY - minY) * 0.45)
        let pivotZ = layout.zPosition.map { Float($0) } ?? ((minZ + maxZ) / 2)

        cameraArmLength = max(sceneWidth, sceneDepth, sceneHeight) * 1.35

        currentYaw = (-Float.pi / 10).clamped(to: activeYawLimits)
        currentPitch = (-Float.pi / 4.5).clamped(to: activePitchLimits)

        cameraOrbit.position = SCNVector3(pivotX, pivotY, pivotZ)
        cameraOrbit.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)
        cameraNode.position = SCNVector3(0, 0, cameraArmLength)

        cameraOrbit.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraOrbit)
        sceneView.pointOfView = cameraNode

        initialCameraOrbitPosition = cameraOrbit.position
        initialCameraNodePosition = cameraNode.position
        initialCameraOrthoScale = initialOrtho
        initialYaw = currentYaw
        initialPitch = currentPitch
    }
 
    func cameraFitBounds(in scene: SCNScene) -> (min: SCNVector3, max: SCNVector3)? {
        var relevantNodes: [SCNNode] = []
        scene.rootNode.enumerateHierarchy { node, _ in
            if self.shouldIncludeNodeForCameraFit(node) { relevantNodes.append(node) }
        }
        if relevantNodes.isEmpty {
            scene.rootNode.enumerateHierarchy { node, _ in
                guard node.geometry != nil, !node.isHidden else { return }
                relevantNodes.append(node)
            }
        }
        guard !relevantNodes.isEmpty else { return nil }
 
        var minVec = SCNVector3( Float.greatestFiniteMagnitude,  Float.greatestFiniteMagnitude,  Float.greatestFiniteMagnitude)
        var maxVec = SCNVector3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)
 
        for node in relevantNodes {
            let (lo, hi) = node.boundingBox
            for corner in worldBoundingCorners(node: node, min: lo, max: hi) {
                minVec.x = min(minVec.x, corner.x); minVec.y = min(minVec.y, corner.y); minVec.z = min(minVec.z, corner.z)
                maxVec.x = max(maxVec.x, corner.x); maxVec.y = max(maxVec.y, corner.y); maxVec.z = max(maxVec.z, corner.z)
            }
        }
        guard minVec.x.isFinite, maxVec.x.isFinite else { return nil }
        return (minVec, maxVec)
    }
 
    func shouldIncludeNodeForCameraFit(_ node: SCNNode) -> Bool {
        guard let geometry = node.geometry, !node.isHidden else { return false }
        let name = (node.name ?? geometry.name ?? "").lowercased()
        let excluded = ["sky", "sphere", "dome", "environment", "background", "backdrop", "city", "world"]
        if excluded.contains(where: { name.contains($0) }) { return false }
        if let geoName = geometry.name, seatingAreaByMeshName[geoName] != nil { return true }
        let (lo, hi) = node.boundingBox
        let maxDim = max(abs(hi.x - lo.x), abs(hi.y - lo.y), abs(hi.z - lo.z))
        return maxDim <= 200
    }
    
    private func seatingUIScaleFactor() -> CGFloat {
        guard let bounds = sceneBounds else { return 1.0 }

        let width = CGFloat(bounds.max.x - bounds.min.x)
        let depth = CGFloat(bounds.max.z - bounds.min.z)
        let maxDim = max(width, depth)

        switch maxDim {
        case ..<20:
            return 1.8
        case ..<40:
            return 1.4
        case ..<80:
            return 1.0
        case ..<140:
            return 0.85
        default:
            return 0.7
        }
    }
 
    func worldBoundingCorners(node: SCNNode, min lo: SCNVector3, max hi: SCNVector3) -> [SCNVector3] {
        [
            SCNVector3(lo.x, lo.y, lo.z), SCNVector3(lo.x, lo.y, hi.z),
            SCNVector3(lo.x, hi.y, lo.z), SCNVector3(lo.x, hi.y, hi.z),
            SCNVector3(hi.x, lo.y, lo.z), SCNVector3(hi.x, lo.y, hi.z),
            SCNVector3(hi.x, hi.y, lo.z), SCNVector3(hi.x, hi.y, hi.z)
        ].map { node.convertPosition($0, to: nil) }
    }
 
    func setupLights() {
        sceneView.scene?.rootNode.childNodes
            .filter { $0.light != nil }
            .forEach { $0.removeFromParentNode() }
 
        let ambient = SCNLight(); ambient.type = .ambient; ambient.intensity = 2
        let ambientNode = SCNNode(); ambientNode.light = ambient
        sceneView.scene?.rootNode.addChildNode(ambientNode)
 
        let dir = SCNLight(); dir.type = .directional; dir.intensity = 350; dir.castsShadow = false
        let dirNode = SCNNode(); dirNode.light = dir
        dirNode.eulerAngles = SCNVector3(-0.9, -0.6, 0)
        sceneView.scene?.rootNode.addChildNode(dirNode)
 
        sceneView.scene?.lightingEnvironment.intensity = 1
    }
}
 
// MARK: - Helpers
 
private extension Tables3DMapVC {
 
    func constantMaterial(color: Any, doubleSided: Bool = true) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents      = color
        mat.lightingModel         = .constant
        mat.isDoubleSided         = doubleSided
        mat.writesToDepthBuffer   = false
        mat.readsFromDepthBuffer  = false
        return mat
    }
 
    func addWaveAnimation(to node: SCNNode) {
        node.removeAllActions()
        node.runAction(.repeatForever(.sequence([
            .group([.scale(to: 2.2, duration: 1.4), .fadeOut(duration: 1.4)]),
            .run { $0.opacity = 1; $0.scale = SCNVector3(1, 1, 1) },
            .wait(duration: 0.3)
        ])))
    }
 
    func makeBillboardNode() -> SCNNode {
        let n = SCNNode()
        let c = SCNBillboardConstraint(); c.freeAxes = [.X, .Y, .Z]
        n.constraints = [c]
        return n
    }
 
    func makeStraightLine(height: CGFloat) -> SCNNode {
        let geo = SCNPlane(width: 0.035, height: height)
        geo.materials = [constantMaterial(color: UIColor.white)]
        let node = SCNNode(geometry: geo)
        let c = SCNBillboardConstraint(); c.freeAxes = [.X, .Y, .Z]
        node.constraints = [c]
        return node
    }
 
    func makeLabelCard(title: String,
                       guests: Int,
                       minAmount: Double?,
                       dotColor: UIColor,
                       scale: CGFloat = 1.0) -> SCNNode {

        let padding: CGFloat = 14

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 42)
        titleLabel.textColor = .white
        titleLabel.sizeToFit()
    
        let minAmountLabel = UILabel()
        minAmountLabel.text = minAmount != nil ? "$ \(Int(minAmount ?? 0)) min." : ""
        minAmountLabel.font = .systemFont(ofSize: 30, weight: .medium)
        minAmountLabel.textColor = .white
        minAmountLabel.sizeToFit()

        let guestsLabel = UILabel()
        guestsLabel.text = "\(guests) Guests"
        guestsLabel.font = .systemFont(ofSize: 32, weight: .medium)
        guestsLabel.textColor = .white
        guestsLabel.sizeToFit()

        let dot = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
        dot.backgroundColor = dotColor
        dot.layer.cornerRadius = 9

        let rowWidth = dot.frame.width + 8 + guestsLabel.bounds.width
        let width = max(titleLabel.bounds.width,
                        minAmountLabel.bounds.width,
                        rowWidth) + padding * 2

        let height = titleLabel.bounds.height
                   + minAmountLabel.bounds.height
                   + guestsLabel.bounds.height
                   + padding * 2
                   + 12

        let container = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        container.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        container.layer.cornerRadius = 16
        container.layer.borderWidth  = 2
        container.layer.borderColor  = UIColor.white.cgColor

        // Title
        titleLabel.frame.origin = CGPoint(
            x: (width - titleLabel.bounds.width) / 2,
            y: padding
        )
        container.addSubview(titleLabel)

        // Min Amount
        minAmountLabel.frame.origin = CGPoint(
            x: (width - minAmountLabel.bounds.width) / 2,
            y: titleLabel.frame.maxY + 6
        )
        container.addSubview(minAmountLabel)

        // Dot
        dot.frame.origin = CGPoint(
            x: (width - rowWidth) / 2,
            y: minAmountLabel.frame.maxY + 6
        )
        container.addSubview(dot)

        // Guests
        guestsLabel.frame.origin = CGPoint(
            x: dot.frame.maxX + 8,
            y: dot.frame.midY - guestsLabel.bounds.height / 2
        )
        container.addSubview(guestsLabel)

        let renderer = UIGraphicsImageRenderer(size: container.bounds.size)
        let image = renderer.image { ctx in container.layer.render(in: ctx.cgContext) }

        let plane = SCNPlane(width: (width / 80) * scale,
                             height: (height / 80) * scale)
        plane.materials = [constantMaterial(color: image)]

        let node = SCNNode(geometry: plane)
        let c = SCNBillboardConstraint()
        c.freeAxes = [.X, .Y, .Z]
        node.constraints = [c]

        return node
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
