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
    weak var sourceNode: SCNNode?
    let uniqueId: String
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
    private var cameraOrbit = SCNNode()
    private var cameraNode  = SCNNode()
    private var currentYaw:   Float = 0
    private var currentPitch: Float = 0
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
    
    var meshNodesBySeatingId: [String: [SCNNode]] = [:]
    var originalMaterials: [SCNNode: [SCNMaterial]] = [:]

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
    private var initialYaw: Float = 0
    private var initialPitch: Float = 0
 
    var currentDistance: Float = 0
    var minDistance: Float = 0
    var maxDistance: Float = 0

    var minYaw: Float = -.pi
    var maxYaw: Float = .pi

    var minPitch: Float = -Float.pi / 2
    var maxPitch: Float = Float.pi / 2
    
    private var currentLoadId = UUID()
    private var sceneScaleFactor: Float = 1
    
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
        guard let selectedId = selectedSeatingId else { return }
        guard let selectedArea = seatingAreas.first(where: { $0.parentSeatingAreaId == selectedId }) else { return }
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
        sceneView.isJitteringEnabled   = true
        sceneView.rendersContinuously  = true
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
    
    func adaptFovForAspect(
        baseFov: Float,       // vertical FOV from API (degrees), designed for baseAspect
        baseAspect: Float,    // aspect the API FOV was authored for (width/height, e.g. 1.6)
        targetAspect: Float   // actual screen aspect (width/height)
    ) -> Float {
        let vFovRad  = baseFov * .pi / 180
        // Recover horizontal FOV as authored on the web
        let hFovRad  = 2 * atan(tan(vFovRad / 2) * baseAspect)
        // Convert to vertical FOV for the iOS screen
        let newVFovRad = 2 * atan(tan(hFovRad / 2) / targetAspect)
        return newVFovRad * 180 / .pi
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
        else { return [:] }

        var result: [String: [String: String]] = [:]
        for (nodeName, props) in objectProperties {
            guard let propDict = props as? [String: Any] else { continue }
            var stringProps: [String: String] = [:]
            for (k, v) in propDict { stringProps[k.lowercased()] = "\(v)" }
            let variants = [
                nodeName,
                nodeName.replacingOccurrences(of: ".", with: ""),
                nodeName.replacingOccurrences(of: "_", with: "")
            ]
            for key in variants where !key.isEmpty { result[key] = stringProps }
            if let innerName = stringProps["name"], !innerName.isEmpty {
                let innerVariants = [
                    innerName,
                    innerName.replacingOccurrences(of: ".", with: ""),
                    innerName.replacingOccurrences(of: "_", with: "")
                ]
                for key in innerVariants where !key.isEmpty { result[key] = stringProps }
            }
        }
        return result
    }
 
    func fetchLayOut() {
        TablePresenter.getConsumerLayout(
            date: "2026-05-01",
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
        case let n as NSNumber: return n.stringValue
        case let d as Double:   return d == d.rounded() ? String(Int(d)) : String(d)
        case let i as Int:      return String(i)
        default:                return nil
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
            return dict.reduce(into: [:]) { $0[$1.key.lowercased()] = $1.value }
        }
        if let array = extras as? [[String: Any]] {
            var dict: [String: Any] = [:]
            for item in array {
                if let key = item["key"] as? String { dict[key.lowercased()] = item["value"] }
            }
            return dict
        }
        return [:]
    }

    func resolveSeatingArea(from extras: [String: Any]) -> SeatingAreaDTO? {
        let raw = firstExtraValue(in: extras, keys: [
            "seatingareatag", "seatingareaid", "parentseatingareaid", "areaid", "area_id"
        ])
        guard let raw else { return nil }

        if let area = seatingAreaByParentId[raw] {
            return SeatingAreaDTO(id: area.id, parentSeatingAreaId: area.parentSeatingAreaId,
                                  name: area.name, highlight: area.highlight, maxGuest: area.maxGuest,
                                  isDJBoot: false, minimum: area.minimum, allowActions: true)
        }
        if let area = seatingAreaById[raw] {
            return SeatingAreaDTO(id: area.id, parentSeatingAreaId: area.parentSeatingAreaId ?? area.id,
                                  name: area.name, highlight: area.highlight, maxGuest: area.maxGuest,
                                  isDJBoot: false, minimum: area.minimum, allowActions: true)
        }
        if let area = seatingAreaFilteredOutByParentId[raw] {
            return SeatingAreaDTO(id: area.id, parentSeatingAreaId: area.parentSeatingAreaId,
                                  name: area.name, highlight: area.highlight, maxGuest: area.maxGuest,
                                  isDJBoot: false, minimum: area.minimum, allowActions: false)
        }
        if let area = seatingAreaFilteredOutById[raw] {
            return SeatingAreaDTO(id: area.id, parentSeatingAreaId: area.parentSeatingAreaId ?? area.id,
                                  name: area.name, highlight: area.highlight, maxGuest: area.maxGuest,
                                  isDJBoot: false, minimum: area.minimum, allowActions: false)
        }
        print("⚠️ seating raw id \(raw) not found in any seating map")
        return nil
    }
 
    func applyPage(animated: Bool, direction: ZoneSelectorView.PageDirection) {
        guard !pagedRoomItems.isEmpty else {
            zoneSelector.setItems([], hasMoreLeft: false, hasMoreRight: false,
                                  selectedIndex: 0, animated: false,
                                  borderColors: event?.whiteLabelColor,
                                  direction: .none, notifySelection: false)
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
        zoneSelector.setItems(names,
                              hasMoreLeft:  arrows && hasLeft,
                              hasMoreRight: arrows && hasRight,
                              selectedIndex: selectedIndexInPage,
                              animated:      animated,
                              borderColors:  event?.whiteLabelColor,
                              direction:     direction,
                              notifySelection: false)
    }
    
    private func openSeatingArea(_ item: SeatingArea) {
        guard item.hideCheckout != true else {
            print("Inquire tapped for:", item.name ?? "")
            return
        }
        Navigate.to.tableSeatingVC(self, seatingArea: item, event: event) { [weak self] time, guestCount, _, _ in
            guard let self = self else { return }
            let uuid    = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
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
                } else { print(errMsg ?? "Booking failed") }
            }
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
 
// MARK: - GLB Loading
private extension Tables3DMapVC {
 
    func loadGLB_Local(from path: String, layout: Layout3DMap) {
        let baseURL = "https://media.speakeasygo.com/"
        guard let url = URL(string: baseURL + path) else { return }
        loadGLB(from: url, layout: layout)
    }
 
    func loadGLB(from url: URL, layout: Layout3DMap) {
        let loadId = UUID()
        currentLoadId = loadId
        resetSceneState()
        
        GLTFAsset.load(with: url, options: [:]) { [weak self] _, status, asset, error, _ in
            guard let self else { return }
            guard self.currentLoadId == loadId else { print("Old GLB ignored"); return }
            guard status == .complete, let asset, error == nil else {
                print("GLB load error:", error?.localizedDescription ?? "unknown")
                return
            }
            DispatchQueue.main.async {
                guard self.currentLoadId == loadId else { return }
                self.setupSeatingAreas {
                    let scene = SCNScene(gltfAsset: asset)
                    self.sceneView.scene = scene
                    self.setSceneScaleFactor(scene: scene)
                    self.buildMeshSeatingMap(asset: asset, layout: layout)
                    self.setupLights()
                    self.renderDots(scene: scene)
                    // ─── FIX 2: setupCamera is called AFTER layout is complete ───
                    // We defer by one run-loop tick so sceneView.bounds is valid.
                    DispatchQueue.main.async {
                        self.setupCamera(scene, layout: layout)
                        self.setupTapGesture()
                    }
                }
            }
        }
    }
 
    func setSceneScaleFactor(scene: SCNScene) {
        var minVec = SCNVector3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
        var maxVec = SCNVector3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)
        scene.rootNode.enumerateChildNodes { node, _ in
            let (bmin, bmax) = node.boundingBox
            let worldMin = node.convertPosition(bmin, to: nil)
            let worldMax = node.convertPosition(bmax, to: nil)
            minVec.x = Swift.min(minVec.x, worldMin.x); minVec.y = Swift.min(minVec.y, worldMin.y); minVec.z = Swift.min(minVec.z, worldMin.z)
            maxVec.x = Swift.max(maxVec.x, worldMax.x); maxVec.y = Swift.max(maxVec.y, worldMax.y); maxVec.z = Swift.max(maxVec.z, worldMax.z)
        }
        let size = SCNVector3(maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z)
        self.sceneScaleFactor = max(size.x, size.y, size.z)
    }
    
    func resetSceneState() {
        selectedSeatingId = nil
        sceneBounds       = nil
        seatingAreaByMeshName.removeAll()
        renderedDJPositions.removeAll()
        meshNodesBySeatingId.removeAll()
        originalMaterials.removeAll()
        renderedDJKeys.removeAll()
        currentDistance = 0; minDistance = 0; maxDistance = 0
        minYaw = -.pi; maxYaw = .pi
        minPitch = -Float.pi / 2; maxPitch = Float.pi / 2
        sceneView.gestureRecognizers?.filter { $0 is UITapGestureRecognizer }.forEach { sceneView.removeGestureRecognizer($0) }
        cameraOrbit = SCNNode()
        cameraNode  = SCNNode()
        sceneView.scene = SCNScene()
    }
}
 
// MARK: - Mesh / Seating Map
private extension Tables3DMapVC {
    
    func buildMeshSeatingMap(asset: GLTFAsset, layout: Layout3DMap) {
        let metaProps = parseMetadata(layout.metadata)
        for node in asset.nodes {
            let nodeName = (node.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let meshName = (node.mesh?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let nodeExtras = normalizeExtras(node.extras)
            let meshExtras = normalizeExtras(node.mesh?.extras)
            let lookupKeys = [nodeName, meshName,
                              nodeName.replacingOccurrences(of: ".", with: ""),
                              meshName.replacingOccurrences(of: ".", with: ""),
                              nodeName.replacingOccurrences(of: "_", with: ""),
                              meshName.replacingOccurrences(of: "_", with: "")].filter { !$0.isEmpty }
            var metadataExtras: [String: Any] = [:]
            for key in lookupKeys {
                if let props = metaProps[key] {
                    for (k, v) in props { metadataExtras[k.lowercased()] = v }
                    break
                }
            }
            var extras = meshExtras
            for (k, v) in nodeExtras { extras[k] = v }
            for (k, v) in metadataExtras { extras[k] = v }
            let djBootValue = (normalizedString(extras["djboottag"]) ?? "").lowercased()
            let isDJ = djBootValue == "true"
            if isDJ {
                let dto = SeatingAreaDTO(id: nil, parentSeatingAreaId: nil, name: "DJ",
                                         highlight: nil, maxGuest: nil, isDJBoot: true,
                                         minimum: nil, allowActions: false)
                if !nodeName.isEmpty { seatingAreaByMeshName[nodeName] = dto }
                if !meshName.isEmpty { seatingAreaByMeshName[meshName] = dto }
                continue
            }
            guard let dto = resolveSeatingArea(from: extras) else { continue }
            if !nodeName.isEmpty { seatingAreaByMeshName[nodeName] = dto }
            if !meshName.isEmpty { seatingAreaByMeshName[meshName] = dto }
        }
        sceneView.scene?.rootNode.enumerateChildNodes { node, _ in
            let nodeName = (node.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = nodeName.replacingOccurrences(of: "_", with: "").replacingOccurrences(of: ".", with: "").lowercased()
            if let dto = seatingAreaByMeshName[nodeName] ?? seatingAreaByMeshName[normalized] {
                let seatingId = dto.parentSeatingAreaId ?? ""
                guard !seatingId.isEmpty else { return }
                meshNodesBySeatingId[seatingId, default: []].append(node)
            }
        }
        cacheOriginalMaterials()
    }
    
    func cacheOriginalMaterials() {
        for (_, nodes) in meshNodesBySeatingId {
            for node in nodes {
                if let geo = node.geometry {
                    originalMaterials[node] = geo.materials.map { $0.copy() as! SCNMaterial }
                }
            }
        }
    }
    
    func worldTopCenter(of node: SCNNode) -> simd_float3 {
        let (lo, hi) = node.boundingBox
        let topLocal = simd_float3((lo.x + hi.x) / 2, hi.y, (lo.z + hi.z) / 2)
        return node.simdConvertPosition(topLocal, to: nil)
    }

    func extractParentSeatingAreaId(from extras: [String: Any]) -> String? {
        let keys = ["seatingareaid","seatingAreaId","seatingAreaID","seatingareatag","seatingAreaTag","areaId","areaID","area_id"]
        for key in keys {
            if let s = extras[key] as? String, !s.isEmpty, s != "1", s != "1.0" { return s }
            if let d = extras[key] as? Double { let s = String(Int(d)); if s != "1" { return s } }
        }
        return nil
    }
}
 
// MARK: - Dot Rendering
private extension Tables3DMapVC {
 
    func renderDots(scene: SCNScene) {
        renderedDJPositions.removeAll()
        scene.rootNode.enumerateHierarchy { [weak self] node, _ in
            guard let self else { return }
            let candidateNames: [String] = [node.name, node.geometry?.name, node.parent?.name]
                .compactMap { $0 }.filter { !$0.isEmpty }
            var dto: SeatingAreaDTO?
            for name in candidateNames {
                if let found = self.seatingAreaByMeshName[name] { dto = found; break }
            }
            guard let seating = dto else { return }
            let anchorNode = bestVisualAnchorNode(for: node)
            let topCenter = self.worldTopCenter(of: anchorNode)
            if seating.isDJBoot {
                let posKey = String(format: "%.1f_%.1f_%.1f", topCenter.x, topCenter.y, topCenter.z)
                guard !renderedDJKeys.contains(posKey) else { return }
                renderedDJKeys.insert(posKey)
                scene.rootNode.addChildNode(makeDJDot(position: topCenter, sourceNode: node))
                return
            }
            let pinNode = self.makeTableDot(position: topCenter, seating: seating, sourceNode: node)
            self.sceneView.scene?.rootNode.addChildNode(pinNode)
        }
    }

    func makeTableDot(position: simd_float3, seating: SeatingAreaDTO, sourceNode: SCNNode) -> SCNNode {
        let root = SCNNode()
        let scale = uiScale(for: position)
        root.simdPosition = position + simd_float3(0, 0.05, 0)
        let uiNode = makeBillboardNode()
        uiNode.name = "pin"
        let dotColor: UIColor = seating.allowActions ? PinStyle.activeColor : PinStyle.inactiveColor
        let hitGeo = SCNPlane(width: 0.75 * scale, height: 0.75 * scale)
        hitGeo.cornerRadius = 0.375 * scale
        hitGeo.materials = [constantMaterial(color: UIColor.clear)]
        let hitNode = SCNNode(geometry: hitGeo); hitNode.name = "hit"
        uiNode.addChildNode(hitNode)
        if seating.allowActions {
            let pulseGeo = SCNPlane(width: 0.55 * scale, height: 0.55 * scale)
            pulseGeo.cornerRadius = (0.55 * scale) / 2
            pulseGeo.materials = [constantMaterial(color: dotColor.withAlphaComponent(0.22))]
            let pulse = SCNNode(geometry: pulseGeo); pulse.name = "wave"; pulse.position.z = -0.002
            addSoftPulseAnimation(to: pulse)
            uiNode.addChildNode(pulse)
        }
        let glowGeo = SCNPlane(width: 0.24 * scale, height: 0.24 * scale)
        glowGeo.cornerRadius = (0.24 * scale) / 2
        glowGeo.materials = [constantMaterial(color: dotColor.withAlphaComponent(0.45))]
        let glow = SCNNode(geometry: glowGeo); glow.name = "glow"; glow.position.z = -0.001
        uiNode.addChildNode(glow)
        let dotGeo = SCNPlane(width: 0.16 * scale, height: 0.16 * scale)
        dotGeo.cornerRadius = (0.16 * scale) / 2
        dotGeo.materials = [constantMaterial(color: dotColor)]
        let dot = SCNNode(geometry: dotGeo); dot.name = "circle"; dot.position.z = 0.001
        uiNode.addChildNode(dot)
        let ring = SCNNode(geometry: SCNTorus(ringRadius: 0.095 * scale, pipeRadius: 0.008 * scale))
        ring.name = "ring"
        ring.geometry?.materials = [constantMaterial(color: UIColor.white.withAlphaComponent(0.9))]
        ring.eulerAngles.x = -.pi / 2; ring.position.z = 0.003
        uiNode.addChildNode(ring)
        let line = makeStraightLine(height: 0.72 * scale); line.name = "line"; line.opacity = 0
        uiNode.addChildNode(line)
        let label = makeLabelCard(title: seating.name ?? "", guests: seating.maxGuest ?? 0,
                                  minAmount: seating.minimum, dotColor: dotColor, scale: scale)
        label.name = "label"; label.position = SCNVector3(0, Float(1.25 * scale), 0)
        label.opacity = 0; label.isHidden = true
        uiNode.addChildNode(label)
        uiNode.seatingMeta = SeatingMeta(
            seatingAreaId: seating.parentSeatingAreaId ?? seating.id ?? "",
            name: seating.name ?? "", parentId: seating.parentSeatingAreaId ?? "",
            maxGuest: seating.maxGuest ?? 0, allowActions: seating.allowActions,
            sourceNode: sourceNode, uniqueId: UUID().uuidString)
        root.addChildNode(uiNode)
        return root
    }
    
    func highlightMeshOnlySelected(meta: SeatingMeta) {
        resetAllMeshes()
        guard let nodes = meshNodesBySeatingId[meta.seatingAreaId] else { return }
        for node in nodes {
            applyUniqueMaterial(to: node)
            node.geometry?.materials.forEach { mat in
                mat.emission.contents = UIColor.systemPink.withAlphaComponent(0.05)
                mat.emission.intensity = 0.05
            }
        }
    }
    
    func applyUniqueMaterial(to node: SCNNode) {
        guard let geo = node.geometry else { return }
        geo.materials = geo.materials.map { $0.copy() as! SCNMaterial }
    }
    
    func resetAllMeshes() {
        for (node, mats) in originalMaterials {
            node.geometry?.materials = mats.map { $0.copy() as! SCNMaterial }
        }
    }
    
    func addSoftPulseAnimation(to node: SCNNode) {
        node.removeAllActions()
        let expand = SCNAction.group([.scale(to: 1.9, duration: 1.35), .fadeOpacity(to: 0.0, duration: 1.35)])
        let reset  = SCNAction.run { n in n.scale = SCNVector3(1, 1, 1); n.opacity = 1 }
        node.runAction(.repeatForever(.sequence([expand, reset, .wait(duration: 0.15)])))
    }
}
 
// MARK: - Gestures
private extension Tables3DMapVC {
    
    func setupTapGesture() {
        sceneView.gestureRecognizers?.filter { $0 is UITapGestureRecognizer }.forEach { sceneView.removeGestureRecognizer($0) }
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
        // Zoom in on double-tap
        currentDistance = max(minDistance, currentDistance * 0.75)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        updateCameraDistance()
        SCNTransaction.commit()
    }
 
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let delta = gesture.translation(in: sceneView)
        gesture.setTranslation(.zero, in: sceneView)
        let viewWidth  = Float(max(sceneView.bounds.width, 1))
        let viewHeight = Float(max(sceneView.bounds.height, 1))
        let yawSensitivity:   Float = Float.pi / viewWidth
        let pitchSensitivity: Float = Float.pi / viewHeight
        currentYaw   -= Float(delta.x) * yawSensitivity
        currentPitch -= Float(delta.y) * pitchSensitivity
        currentYaw   = currentYaw.clamped(to: activeYawLimits)
        currentPitch = currentPitch.clamped(to: activePitchLimits)
        cameraOrbit.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)
    }
    
    func normalizeAngle(_ angle: Float) -> Float {
        var a = angle
        while a > .pi  { a -= 2 * .pi }
        while a < -.pi { a += 2 * .pi }
        return a
    }
    
    func clampAngle(_ angle: Float, min: Float, max: Float) -> Float {
        let a    = normalizeAngle(angle)
        let minA = normalizeAngle(min)
        let maxA = normalizeAngle(max)
        if minA <= maxA { return Swift.min(Swift.max(a, minA), maxA) }
        if a >= minA || a <= maxA { return a }
        let distToMin = abs(a - minA); let distToMax = abs(a - maxA)
        return distToMin < distToMax ? minA : maxA
    }
    
    @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
        let zoomSpeed: Float = 0.25
        let delta = Float(1 - g.scale); g.scale = 1
        currentDistance += delta * zoomSpeed * currentDistance
        currentDistance  = Swift.min(Swift.max(currentDistance, minDistance), maxDistance)
        updateCameraDistance()
    }
    
    func updateCameraDistance() {
        let dir = cameraNode.position.normalized()
        cameraNode.position = SCNVector3(dir.x * currentDistance,
                                         dir.y * currentDistance,
                                         dir.z * currentDistance)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: sceneView)
        let hits = sceneView.hitTest(point, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .boundingBoxOnly: false,
            .ignoreHiddenNodes: true
        ])
        guard let pin = findPinNode(from: hits), let meta = pin.seatingMeta else {
            handleOutsideTap(); return
        }
        guard meta.allowActions else { print("Tapped unavailable area:", meta.name); return }
        applySelection(meta: meta)
    }
    
    private func findPinNode(from hits: [SCNHitTestResult]) -> SCNNode? {
        return hits.lazy.compactMap { result -> SCNNode? in
            var current: SCNNode? = result.node
            while let node = current { if node.seatingMeta != nil { return node }; current = node.parent }
            return nil
        }.first
    }
    
    private func handleOutsideTap() {
        guard selectedSeatingId != nil else { return }
        resetSelection(); selectedSeatingId = nil
        buyNowBtnView.isHidden = true; zoneSelector.isHidden = false
    }
    
    private func applySelection(meta: SeatingMeta) {
        selectedSeatingId = meta.seatingAreaId
        highlightOnlySelectedDot(meta: meta)
        highlightMeshOnlySelected(meta: meta)
        buyNowBtnView.isHidden = false; zoneSelector.isHidden = true
    }
    
    func resetSelection() {
        resetAllMeshes()
        sceneView.scene?.rootNode.enumerateHierarchy { node, _ in
            guard let m = node.seatingMeta else { return }
            if let wave = node.childNodes.first(where: { $0.name == "wave" }) {
                wave.geometry?.materials.first?.diffuse.contents =
                    (m.allowActions ? PinStyle.activeColor : PinStyle.inactiveColor).withAlphaComponent(0.4)
            }
            if let label = node.childNodes.first(where: { $0.name == "label" }) {
                label.removeAllActions(); label.isHidden = true; label.opacity = 0
            }
            if let line = node.childNodes.first(where: { $0.name == "line" }) {
                line.removeAllActions(); line.isHidden = true; line.opacity = 0
            }
        }
    }
    
    func highlightOnlySelectedDot(meta: SeatingMeta) {
        sceneView.scene?.rootNode.enumerateHierarchy { node, _ in
            guard let m = node.seatingMeta else { return }
            let isSelected = (m.uniqueId == meta.uniqueId)
            if let label = node.childNodes.first(where: { $0.name == "label" }) {
                label.isHidden = !isSelected; label.opacity = isSelected ? 1 : 0
            }
            if let line = node.childNodes.first(where: { $0.name == "line" }) {
                line.opacity = isSelected ? 1 : 0
            }
        }
    }
    
    private func showCheckoutMode() {
        buyNowBtnView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.buyNowBtnView.alpha = 1; self.zoneSelector.alpha = 0
        } completion: { _ in self.zoneSelector.isHidden = true }
    }

    private func hideCheckoutMode() {
        zoneSelector.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.buyNowBtnView.alpha = 0; self.zoneSelector.alpha = 1
        } completion: { _ in self.buyNowBtnView.isHidden = true }
    }

    private func updatePinColor(seatingAreaId: String, color: UIColor, in scene: SCNScene?) {
        scene?.rootNode.enumerateHierarchy { node, _ in
            guard let meta = node.seatingMeta, meta.seatingAreaId == seatingAreaId else { return }
            node.childNodes.first(where: { $0.name == "circle" })?.geometry?.materials.first?.diffuse.contents = color
            node.childNodes.first(where: { $0.name == "wave" })?.geometry?.materials.first?.diffuse.contents = color.withAlphaComponent(0.55)
        }
    }

    private func resetPinColor(seatingAreaId: String, in scene: SCNScene?) {
        scene?.rootNode.enumerateHierarchy { node, _ in
            guard let meta = node.seatingMeta, meta.seatingAreaId == seatingAreaId else { return }
            let baseColor = meta.allowActions ? PinStyle.activeColor : PinStyle.inactiveColor
            node.childNodes.first(where: { $0.name == "circle" })?.geometry?.materials.first?.diffuse.contents = baseColor
            node.childNodes.first(where: { $0.name == "wave" })?.geometry?.materials.first?.diffuse.contents = baseColor.withAlphaComponent(0.55)
        }
    }
}
 
// MARK: - DJ Dot
private extension Tables3DMapVC {
    
    func uiScale(for position: simd_float3) -> CGFloat { return 1.0 }
         
    func makeDJDot(position: simd_float3, sourceNode: SCNNode) -> SCNNode {
        let scale = uiScale(for: position)
        let base: CGFloat = CGFloat(sceneScaleFactor) * 0.01
        let root = SCNNode(); root.simdPosition = position + simd_float3(0, Float(base * 0.6 * scale), 0); root.name = "dj-pin"
        let uiNode = makeBillboardNode(); let gold = PinStyle.djGold; var z: Float = 0
        let glowSize = base * 2.1 * scale; let glowGeo = SCNPlane(width: glowSize, height: glowSize)
        glowGeo.cornerRadius = glowSize / 2; glowGeo.materials = [constantMaterial(color: gold.withAlphaComponent(0.25))]
        let glow = SCNNode(geometry: glowGeo); glow.position.z = z; z += 0.002; uiNode.addChildNode(glow)
        let waveSize = base * 1.9 * scale; let waveGeo = SCNPlane(width: waveSize, height: waveSize)
        waveGeo.cornerRadius = waveSize / 2; waveGeo.materials = [constantMaterial(color: gold.withAlphaComponent(0.6))]
        let wave = SCNNode(geometry: waveGeo); wave.position.z = z; z += 0.002; addDJWaveAnimation(to: wave); uiNode.addChildNode(wave)
        let outerRing = SCNNode(geometry: SCNTorus(ringRadius: base * 1.1 * scale, pipeRadius: base * 0.08 * scale))
        outerRing.geometry?.materials = [constantMaterial(color: UIColor.white)]; outerRing.eulerAngles.x = -.pi / 2; outerRing.position.z = z; z += 0.002; uiNode.addChildNode(outerRing)
        let innerRing = SCNNode(geometry: SCNTorus(ringRadius: base * 0.85 * scale, pipeRadius: base * 0.07 * scale))
        innerRing.geometry?.materials = [constantMaterial(color: UIColor.white)]; innerRing.eulerAngles.x = -.pi / 2; innerRing.position.z = z; z += 0.002; uiNode.addChildNode(innerRing)
        let fill = SCNNode(geometry: SCNCylinder(radius: base * 0.75 * scale, height: base * 0.10 * scale))
        fill.geometry?.materials = [constantMaterial(color: UIColor.white)]; fill.eulerAngles.x = -.pi / 2; fill.position.z = z; z += 0.002; uiNode.addChildNode(fill)
        let textGeo = SCNText(string: "DJ", extrusionDepth: base * 0.04 * scale)
        textGeo.font = .boldSystemFont(ofSize: base * 8 * scale); textGeo.flatness = 0.05; textGeo.materials = [constantMaterial(color: UIColor.black)]
        let textNode = SCNNode(geometry: textGeo)
        let (tmin, tmax) = textGeo.boundingBox; let centerX = (tmin.x + tmax.x) / 2; let centerY = (tmin.y + tmax.y) / 2
        textNode.pivot = SCNMatrix4MakeTranslation(centerX, centerY * 0.9, 0); textNode.scale = SCNVector3(0.12, 0.12, 0.12); textNode.position = SCNVector3(0, 0, z); textNode.renderingOrder = 1000
        uiNode.addChildNode(textNode)
//        root.runAction(.repeatForever(.sequence([.moveBy(x: 0, y: 1.0 * scale, z: 0, duration: 1.5), .moveBy(x: 0, y: -1.0 * scale, z: 0, duration: 1.5)])))
        root.addChildNode(uiNode); return root
    }

    func addDJWaveAnimation(to node: SCNNode) {
        node.removeAllActions()
        node.runAction(.repeatForever(.sequence([
            .group([.scale(to: 4.0, duration: 1.2), .fadeOut(duration: 1.2)]),
            .run { $0.opacity = 1; $0.scale = SCNVector3(1, 1, 1) },
            .wait(duration: 0.5)
        ])))
    }
}
 
// MARK: - Camera
private extension Tables3DMapVC {
 
    func setupCamera(_ scene: SCNScene, layout: Layout3DMap) {
        cameraOrbit.removeFromParentNode()
        cameraNode.removeFromParentNode()
        
        let config = layout
        
        // ── STEP 1: World bounds ─────────────────────────────────────────────
        var minVec = SCNVector3( Float.greatestFiniteMagnitude,  Float.greatestFiniteMagnitude,  Float.greatestFiniteMagnitude)
        var maxVec = SCNVector3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)
        scene.rootNode.enumerateChildNodes { node, _ in
            let (bmin, bmax) = node.boundingBox
            let worldMin = node.convertPosition(bmin, to: nil)
            let worldMax = node.convertPosition(bmax, to: nil)
            minVec.x = Swift.min(minVec.x, worldMin.x); minVec.y = Swift.min(minVec.y, worldMin.y); minVec.z = Swift.min(minVec.z, worldMin.z)
            maxVec.x = Swift.max(maxVec.x, worldMax.x); maxVec.y = Swift.max(maxVec.y, worldMax.y); maxVec.z = Swift.max(maxVec.z, worldMax.z)
        }
        
        // ── STEP 2: Center & size ────────────────────────────────────────────
        let center = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )
        cameraOrbit.position = center
        
        let size   = SCNVector3(maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z)
        let width  = size.x
        let height = size.y
        let depth  = size.z

        // ── STEP 3: Screen aspect & adapted FOV ──────────────────────────────
        // Guard against zero bounds (happens if layout hasn't appeared yet).
        let viewSize    = sceneView.bounds.size
        let safeWidth   = viewSize.width  > 0 ? viewSize.width  : UIScreen.main.bounds.width
        let safeHeight  = viewSize.height > 0 ? viewSize.height : UIScreen.main.bounds.height
        let screenAspect = Float(safeWidth / safeHeight)
        
        // FIX 3: Use the API's authored aspect (web ratio) to recover horizontal FOV,
        // then produce a correct vertical FOV for the actual iOS screen aspect.
        let apiBaseFov    = Float(config.fieldOfView ?? 45)
        let apiBaseAspect = Float(config.ratio ?? 1.6)   // web aspect the FOV was designed for
        
        let adaptedFov = adaptFovForAspect(
            baseFov:      apiBaseFov,
            baseAspect:   apiBaseAspect,
            targetAspect: screenAspect
        )
        
        let camera = SCNCamera()
        camera.usesOrthographicProjection = false
        camera.fieldOfView = CGFloat(adaptedFov)
        camera.zNear = 0.1
        camera.zFar  = 5000
        cameraNode.camera = camera
        
        // ── STEP 4: Camera direction from API ────────────────────────────────
        let apiDir = SCNVector3(
            config.xPosition ?? 0,
            config.yPosition ?? 0,
            config.zPosition ?? 0
        ).normalized()
        
        // ── STEP 5: Fit distance (mirrors Three.js Bounds helper) ────────────
        let fovRad = adaptedFov * .pi / 180
        
        // Vertical fit: how far to see the full height
        let distanceV = height / (2 * tan(fovRad / 2))
        // Horizontal fit: how far to see the full width given screen aspect
        let distanceH = (depth > width ? depth : width) / (2 * tan(fovRad / 2)) / screenAspect
        let fitDistance = max(distanceV, distanceH)
        
        // ── STEP 6: Padding ──────────────────────────────────────────────────
        // FIX 4: Reduced padding so the scene fills the view like the web does.
        // Web uses a padding of ~1.0–1.1; we were using 1.2–1.5 which caused
        // the "zoomed in / camera too close" appearance on iOS.
        let yFactor      = abs(apiDir.y)
        let ratio1       = Float(config.ratio ?? 1.8)
        let ratioFactor  = max(0.85, min(1.1,  1.8 / ratio1))           // tighter than before
        let angleFactor  = 1.05 + (1.25 - 1.05) * (1 - yFactor)        // 1.05–1.25 (was 1.2–1.5)
        let paddingFactor = max(1.05, min(1.35, angleFactor * ratioFactor))
        let finalDistance = fitDistance * paddingFactor
        
        // ── STEP 7: Place camera in the API direction ────────────────────────
        cameraNode.position = SCNVector3(
            apiDir.x * finalDistance,
            apiDir.y * finalDistance,
            apiDir.z * finalDistance
        )
        
        // ── STEP 8: Look-at constraint ───────────────────────────────────────
        let lookAt = SCNLookAtConstraint(target: cameraOrbit)
        lookAt.isGimbalLockEnabled = true
        cameraNode.constraints = [lookAt]
        
        // ── STEP 9: Add to scene ─────────────────────────────────────────────
        cameraOrbit.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraOrbit)
        sceneView.pointOfView = cameraNode
        
        // ── STEP 10: Derive initial pitch/yaw from the camera's world position
        // FIX 5: Previously we read cameraNode.eulerAngles AFTER applying the
        // lookAt constraint. SceneKit computes eulerAngles lazily and they read
        // as 0,0,0 at this point, so cameraOrbit was never rotated.
        // Instead we derive pitch/yaw directly from the API direction vector.
        let dirLen = sqrt(apiDir.x * apiDir.x + apiDir.z * apiDir.z)
        let derivedPitch: Float = -atan2(apiDir.y, dirLen)          // elevation angle (negative = looking down)
        let derivedYaw:   Float =  atan2(apiDir.x, apiDir.z)        // horizontal angle

        // ── STEP 11: Rotation limits ─────────────────────────────────────────
        let apiPitchMin = Float(config.verticalRotationMin ?? 0)
        let apiPitchMax = Float(config.verticalRotationMax ?? 90)
        // The API encodes pitch as degrees-from-top (0=top,90=horizon).
        // Convert: pitchDeg 0→top → sceneKit angle -π/2, pitchDeg 90→horizon → 0
        minPitch = -deg2rad(apiPitchMax)   // more negative = more top-down
        maxPitch = -deg2rad(apiPitchMin)

        // Clamp so camera never goes below the floor
        minPitch = Swift.max(minPitch, -Float.pi / 2)
        maxPitch = Swift.min(maxPitch, -0.05)
        if minPitch > maxPitch { Swift.swap(&minPitch, &maxPitch) }

        activePitchLimits = minPitch...maxPitch

        let yawMinDeg = Float(config.horizontalRotationMin ?? -180)
        let yawMaxDeg = Float(config.horizontalRotationMax ??  180)
        minYaw = deg2rad(yawMinDeg); maxYaw = deg2rad(yawMaxDeg)
        if minYaw > maxYaw { Swift.swap(&minYaw, &maxYaw) }
        activeYawLimits = minYaw...maxYaw

        // ── STEP 12: Apply initial rotation, clamped to limits ───────────────
        currentPitch = derivedPitch.clamped(to: activePitchLimits)
        currentYaw   = derivedYaw.clamped(to: activeYawLimits)
        cameraOrbit.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)
        
        // Save initial state for reset
        initialCameraOrbitPosition = cameraOrbit.position
        initialCameraNodePosition  = cameraNode.position
        initialYaw   = currentYaw
        initialPitch = currentPitch

        // ── STEP 13: Zoom limits (distance-based) ────────────────────────────
        currentDistance = cameraNode.position.length()
        let zoomMin = config.zoomMin ?? 1
        let zoomMax = config.zoomMax ?? 100
        // Previously the ratio calculation could produce tiny minDistance
        // because zoomMax was used raw (100) vs currentDistance (e.g. 50), giving
        // ratio=0.5 and minDistance=0.5. Instead we scale linearly from currentDistance.
        let zoomRatio = currentDistance / Float(zoomMax)
        minDistance = Float(zoomMin) * zoomRatio
        maxDistance = Float(zoomMax) * zoomRatio
        // Also allow a sensible minimum so the user cannot zoom into the geometry.
        minDistance = Swift.max(minDistance, currentDistance * 0.2)
        maxDistance = Swift.max(maxDistance, currentDistance * 3.0)
        currentDistance = currentDistance.clamped(to: minDistance...maxDistance)

        print("📷 setupCamera complete")
        print("   adaptedFov: \(adaptedFov)° (base \(apiBaseFov)° @ \(apiBaseAspect) → screen \(screenAspect))")
        print("   fitDistance: \(fitDistance)  padding: \(paddingFactor)  final: \(finalDistance)")
        print("   currentPitch: \(currentPitch)  currentYaw: \(currentYaw)")
        print("   pitchLimits: \(minPitch)…\(maxPitch)  yawLimits: \(minYaw)…\(maxYaw)")
        print("   distanceLimits: \(minDistance)…\(maxDistance)")
    }
    
    func deg2rad(_ value: Float) -> Float { value * .pi / 180 }
 
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
    
    private func seatingUIScaleFactor(for node: SCNNode) -> CGFloat {
        let anchorNode = bestVisualAnchorNode(for: node)
        let (lo, hi)  = anchorNode.boundingBox
        let maxDim = max(CGFloat(abs(hi.x-lo.x)), CGFloat(abs(hi.z-lo.z)), CGFloat(abs(hi.y-lo.y)))
        switch maxDim {
        case ..<0.5: return 1.8; case ..<1.0: return 1.5; case ..<2.0: return 1.25
        case ..<4.0: return 1.0; case ..<8.0: return 0.9; default: return 0.8
        }
    }
    
    private func djUIScaleFactor(for node: SCNNode) -> CGFloat {
        let anchorNode = bestVisualAnchorNode(for: node)
        let (lo, hi)  = anchorNode.boundingBox
        let maxDim = max(CGFloat(abs(hi.x-lo.x)), CGFloat(abs(hi.z-lo.z)), CGFloat(abs(hi.y-lo.y)))
        switch maxDim {
        case ..<0.5: return 1.6; case ..<1.0: return 1.4; case ..<2.0: return 1.2
        case ..<4.0: return 1.0; case ..<8.0: return 0.9; default: return 0.8
        }
    }
    
    private func bestVisualAnchorNode(for node: SCNNode) -> SCNNode {
        var current: SCNNode? = node; var bestNode = node; var bestSize: Float = 0
        while let n = current {
            let (lo, hi) = n.boundingBox
            let size = max(abs(hi.x-lo.x), abs(hi.z-lo.z), abs(hi.y-lo.y))
            if n.geometry != nil, !n.isHidden, size > bestSize { bestSize = size; bestNode = n }
            current = n.parent
        }
        return bestNode
    }
     
    func worldBoundingCorners(node: SCNNode, min lo: SCNVector3, max hi: SCNVector3) -> [SCNVector3] {
        [SCNVector3(lo.x,lo.y,lo.z),SCNVector3(lo.x,lo.y,hi.z),
         SCNVector3(lo.x,hi.y,lo.z),SCNVector3(lo.x,hi.y,hi.z),
         SCNVector3(hi.x,lo.y,lo.z),SCNVector3(hi.x,lo.y,hi.z),
         SCNVector3(hi.x,hi.y,lo.z),SCNVector3(hi.x,hi.y,hi.z)].map { node.convertPosition($0, to: nil) }
    }
 
    func setupLights() {
        sceneView.scene?.rootNode.childNodes.filter { $0.light != nil }.forEach { $0.removeFromParentNode() }
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
        n.constraints = [c]; return n
    }
 
    func makeStraightLine(height: CGFloat) -> SCNNode {
        let geo = SCNPlane(width: 0.035, height: height)
        geo.materials = [constantMaterial(color: UIColor.white)]
        let node = SCNNode(geometry: geo)
        let c = SCNBillboardConstraint(); c.freeAxes = [.X, .Y, .Z]
        node.constraints = [c]; return node
    }
 
    func makeLabelCard(title: String, guests: Int, minAmount: Double?,
                       dotColor: UIColor, scale: CGFloat = 1.0) -> SCNNode {
        let uiScale = scale; let padding: CGFloat = 14 * uiScale
        let titleLabel = UILabel(); titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 42 * uiScale); titleLabel.textColor = .white; titleLabel.sizeToFit()
        let minAmountLabel = UILabel()
        minAmountLabel.text = minAmount != nil ? "$ \(Int(minAmount ?? 0)) min." : ""
        minAmountLabel.font = .systemFont(ofSize: 30 * uiScale, weight: .medium); minAmountLabel.textColor = .white; minAmountLabel.sizeToFit()
        let guestsLabel = UILabel(); guestsLabel.text = "\(guests) Guests"
        guestsLabel.font = .systemFont(ofSize: 32 * uiScale, weight: .medium); guestsLabel.textColor = .white; guestsLabel.sizeToFit()
        let dotSize: CGFloat = 18 * uiScale
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
        dot.layer.cornerRadius = dotSize / 2; dot.backgroundColor = dotColor
        let rowWidth = dot.frame.width + 8 + guestsLabel.bounds.width
        let width  = max(titleLabel.bounds.width, minAmountLabel.bounds.width, rowWidth) + padding * 2
        let height = titleLabel.bounds.height + minAmountLabel.bounds.height + guestsLabel.bounds.height + padding * 2 + (12 * uiScale)
        let container = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        container.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        container.layer.cornerRadius = 16; container.layer.borderWidth = 2; container.layer.borderColor = UIColor.white.cgColor
        titleLabel.frame.origin = CGPoint(x: (width - titleLabel.bounds.width) / 2, y: padding); container.addSubview(titleLabel)
        minAmountLabel.frame.origin = CGPoint(x: (width - minAmountLabel.bounds.width) / 2, y: titleLabel.frame.maxY + (6 * uiScale)); container.addSubview(minAmountLabel)
        dot.frame.origin = CGPoint(x: (width - rowWidth) / 2, y: minAmountLabel.frame.maxY + (6 * uiScale)); container.addSubview(dot)
        guestsLabel.frame.origin = CGPoint(x: dot.frame.maxX + (8 * uiScale), y: dot.frame.midY - guestsLabel.bounds.height / 2); container.addSubview(guestsLabel)
        let renderer = UIGraphicsImageRenderer(size: container.bounds.size)
        let image = renderer.image { ctx in container.layer.render(in: ctx.cgContext) }
        let plane = SCNPlane(width: width / 80, height: height / 80)
        plane.materials = [constantMaterial(color: image)]
        let node = SCNNode(geometry: plane)
        node.scale = SCNVector3(Float(scale), Float(scale), Float(scale))
        let c = SCNBillboardConstraint(); c.freeAxes = [.X, .Y, .Z]; node.constraints = [c]
        return node
    }
}

// MARK: - ZoneSelectorView (unchanged)
final class ZoneSelectorView: UIView {

    enum PageDirection { case none, next, prev }

    struct ViewModel: Equatable {
        let items: [String]; let hasMoreLeft: Bool; let hasMoreRight: Bool
        let selectedIndex: Int; let animated: Bool; let borderHexColor: String?
        let direction: PageDirection; let notifySelection: Bool
        init(items: [String], hasMoreLeft: Bool, hasMoreRight: Bool, selectedIndex: Int = 0,
             animated: Bool = true, borderHexColor: String? = nil,
             direction: PageDirection = .none, notifySelection: Bool = false) {
            self.items = items; self.hasMoreLeft = hasMoreLeft; self.hasMoreRight = hasMoreRight
            self.selectedIndex = selectedIndex; self.animated = animated
            self.borderHexColor = borderHexColor; self.direction = direction; self.notifySelection = notifySelection
        }
    }

    var onSelectItem: ((String, Int) -> Void)?
    var onNextPage: (() -> Void)?
    var onPrevPage: (() -> Void)?
    var titleText: String = "SELECT ZONE" { didSet { titleLabel.text = titleText } }

    func setItems(_ items: [String], hasMoreLeft: Bool, hasMoreRight: Bool,
                  selectedIndex: Int = 0, animated: Bool = true, borderColors: String?,
                  direction: PageDirection = .none, notifySelection: Bool = false) {
        let sanitizedItems = items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let model = ViewModel(items: sanitizedItems, hasMoreLeft: hasMoreLeft, hasMoreRight: hasMoreRight,
                              selectedIndex: selectedIndex, animated: animated, borderHexColor: borderColors,
                              direction: direction, notifySelection: notifySelection)
        apply(model)
    }

    private var currentItems: [String] = []; private var selectedIndex: Int = 0
    private var hasMoreLeft: Bool = false; private var hasMoreRight: Bool = false; private var borderHexColor: String?
    private var segmentButtons: [UIButton] = []; private var needsSelectionLayoutUpdate = false
    private let titleLabel = UILabel(); private let pillContainer = UIView()
    private let innerStack = UIStackView(); private let segmentsStack = UIStackView()
    private let leftButton = UIButton(type: .system); private let rightButton = UIButton(type: .system)
    private let selectionView = UIView()
    private let bgColor = UIColor.clear; private let pillFill = UIColor(white: 0.10, alpha: 1.0)
    private let selectedFill = UIColor(white: 0.20, alpha: 0.5)

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    override func layoutSubviews() {
        super.layoutSubviews()
        pillContainer.layer.cornerRadius = pillContainer.bounds.height / 2
        selectionView.layer.cornerRadius = selectionView.bounds.height / 2
        if needsSelectionLayoutUpdate { needsSelectionLayoutUpdate = false; updateSelection(animated: false) }
    }
}

private extension ZoneSelectorView {
    func setup() {
        backgroundColor = bgColor
        titleLabel.text = titleText; titleLabel.textColor = .white.withAlphaComponent(0.92)
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold); titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false; addSubview(titleLabel)
        pillContainer.backgroundColor = pillFill; pillContainer.layer.borderWidth = 1.5
        pillContainer.layer.borderColor = UIColor.white.cgColor; pillContainer.clipsToBounds = true
        pillContainer.translatesAutoresizingMaskIntoConstraints = false; addSubview(pillContainer)
        selectionView.backgroundColor = selectedFill; selectionView.isUserInteractionEnabled = false; pillContainer.addSubview(selectionView)
        configureArrowButton(leftButton, systemName: "chevron.left"); configureArrowButton(rightButton, systemName: "chevron.right")
        leftButton.addTarget(self, action: #selector(didTapLeft), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(didTapRight), for: .touchUpInside)
        segmentsStack.axis = .horizontal; segmentsStack.alignment = .fill; segmentsStack.distribution = .fillEqually
        segmentsStack.spacing = 0; segmentsStack.translatesAutoresizingMaskIntoConstraints = false
        innerStack.axis = .horizontal; innerStack.alignment = .center; innerStack.spacing = 10
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        innerStack.addArrangedSubview(leftButton); innerStack.addArrangedSubview(segmentsStack); innerStack.addArrangedSubview(rightButton)
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
            leftButton.widthAnchor.constraint(equalToConstant: 30), leftButton.heightAnchor.constraint(equalToConstant: 30),
            rightButton.widthAnchor.constraint(equalToConstant: 30), rightButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:))); swipeLeft.direction = .left; pillContainer.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:))); swipeRight.direction = .right; pillContainer.addGestureRecognizer(swipeRight)
        renderCurrentState(animatedSelection: false, notifySelection: false, pageDirection: .none)
    }
    func configureArrowButton(_ button: UIButton, systemName: String) {
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.9); button.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        button.layer.cornerRadius = 15; button.clipsToBounds = true
    }
}

private extension ZoneSelectorView {
    func apply(_ model: ViewModel) {
        currentItems = model.items; hasMoreLeft = model.hasMoreLeft; hasMoreRight = model.hasMoreRight; borderHexColor = model.borderHexColor
        if let hex = borderHexColor, !hex.isEmpty { pillContainer.layer.borderColor = UIColor(hex: hex).cgColor }
        else { pillContainer.layer.borderColor = UIColor.white.cgColor }
        selectedIndex = clampedIndex(model.selectedIndex, for: currentItems)
        renderCurrentState(animatedSelection: false, notifySelection: model.notifySelection,
                           pageDirection: model.animated ? model.direction : .none)
    }
    func renderCurrentState(animatedSelection: Bool, notifySelection: Bool, pageDirection: PageDirection) {
        updateArrowState()
        let contentUpdate = { [weak self] in
            guard let self = self else { return }
            self.rebuildButtons(); self.setNeedsLayout(); self.layoutIfNeeded()
            self.needsSelectionLayoutUpdate = true; self.updateSelection(animated: animatedSelection)
            if notifySelection { self.emitSelectionIfPossible() }
        }
        guard pageDirection != .none else { contentUpdate(); return }
        animatePageChange(direction: pageDirection, update: contentUpdate)
    }
    func clampedIndex(_ index: Int, for items: [String]) -> Int {
        guard !items.isEmpty else { return 0 }; return min(max(0, index), items.count - 1)
    }
}

private extension ZoneSelectorView {
    func rebuildButtons() {
        segmentButtons.forEach { $0.removeTarget(nil, action: nil, for: .allEvents) }
        for view in segmentsStack.arrangedSubviews { segmentsStack.removeArrangedSubview(view); view.removeFromSuperview() }
        segmentButtons.removeAll()
        guard !currentItems.isEmpty else { selectionView.isHidden = true; return }
        for (index, title) in currentItems.enumerated() {
            let button = UIButton(type: .system); button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal); button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            button.backgroundColor = .clear; button.clipsToBounds = true; button.tag = index
            button.addTarget(self, action: #selector(didTapSegment(_:)), for: .touchUpInside)
            segmentButtons.append(button); segmentsStack.addArrangedSubview(button)
        }
        selectionView.isHidden = false
    }
}

private extension ZoneSelectorView {
    @objc func didTapSegment(_ sender: UIButton) {
        let newIndex = clampedIndex(sender.tag, for: currentItems)
        guard newIndex != selectedIndex || currentItems.indices.contains(newIndex) else { emitSelectionIfPossible(); return }
        selectedIndex = newIndex; updateSelection(animated: true); emitSelectionIfPossible()
    }
    @objc func didTapLeft()  { guard hasMoreLeft  else { return }; onPrevPage?() }
    @objc func didTapRight() { guard hasMoreRight else { return }; onNextPage?() }
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction { case .left: didTapRight(); case .right: didTapLeft(); default: break }
    }
    func emitSelectionIfPossible() {
        guard currentItems.indices.contains(selectedIndex) else { return }
        onSelectItem?(currentItems[selectedIndex], selectedIndex)
    }
}

private extension ZoneSelectorView {
    func updateArrowState() { setArrow(leftButton, enabled: hasMoreLeft); setArrow(rightButton, enabled: hasMoreRight) }
    func setArrow(_ button: UIButton, enabled: Bool) {
        button.isEnabled = enabled; button.isHidden = !enabled
        UIView.animate(withDuration: 0.15) { button.alpha = enabled ? 1.0 : 0.0 }
    }
    func updateSelection(animated: Bool) {
        guard !currentItems.isEmpty, selectedIndex >= 0, selectedIndex < segmentButtons.count else { selectionView.isHidden = true; return }
        guard segmentButtons[selectedIndex].bounds.width > 0 else { needsSelectionLayoutUpdate = true; return }
        selectionView.isHidden = false
        let selectedButton = segmentButtons[selectedIndex]
        let frameInPill = selectedButton.superview?.convert(selectedButton.frame, to: pillContainer) ?? .zero
        let expandX: CGFloat = 6; let insetY: CGFloat = 1
        let targetFrame = frameInPill.insetBy(dx: -expandX, dy: insetY)
        for (index, button) in segmentButtons.enumerated() { button.alpha = (index == selectedIndex) ? 1.0 : 0.85 }
        let applyFrame = { self.selectionView.frame = targetFrame; self.selectionView.layer.cornerRadius = targetFrame.height / 2 }
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0.25,
                           options: [.beginFromCurrentState, .curveEaseOut]) { applyFrame() }
        } else { applyFrame() }
    }
}

private extension ZoneSelectorView {
    func animatePageChange(direction: PageDirection, update: @escaping () -> Void) {
        let offset: CGFloat = (direction == .next) ? -40 : 40
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseIn]) {
            self.segmentsStack.transform = CGAffineTransform(translationX: offset, y: 0)
            self.segmentsStack.alpha = 0; self.selectionView.alpha = 0
        } completion: { _ in
            update(); self.segmentsStack.transform = CGAffineTransform(translationX: -offset, y: 0)
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.92, initialSpringVelocity: 0.2,
                           options: [.curveEaseOut]) {
                self.segmentsStack.transform = .identity; self.segmentsStack.alpha = 1; self.selectionView.alpha = 1
            } completion: { _ in self.updateSelection(animated: false) }
        }
    }
}

private extension UIColor {
    static func seatingDotColor(from hex: String?) -> UIColor {
        guard let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !hex.isEmpty else { return UIColor.systemGreen }
        return UIColor(hex: hex)
    }
}

extension SCNVector3 {
    func length() -> Float { sqrt(x*x + y*y + z*z) }
    func normalized() -> SCNVector3 { let l = length(); return l == 0 ? self : SCNVector3(x/l, y/l, z/l) }
}
