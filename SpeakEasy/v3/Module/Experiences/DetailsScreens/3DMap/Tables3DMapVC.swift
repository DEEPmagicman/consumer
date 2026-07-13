//
//  Tables3DMapVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 30/06/26.
//

import UIKit
import SceneKit
import GLTFKit2
import simd
import ObjectiveC.runtime
import MHLoadingButton

final class Tables3DMapVC: UIViewController {

    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var zoneSelector: ZoneSelectorView!
    @IBOutlet weak var buyNowBtnView: UIView!
    @IBOutlet weak var buyNowBtn: LoadingButton!

    var event: Event?
    var promotionLinkId = ""
    var promotionLinkUniqueCode = ""

    private let sceneView = SCNView()

    // MARK: Camera orbit rig

    private var cameraOrbit = SCNNode()
    private var cameraNode = SCNNode()
    private var currentYaw: Float = 0
    private var currentPitch: Float = 0

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

    private var roomItems: [Layout3DMap] = []
    private var selectedGlobalRoomIndex = 0

    private var activePitchLimits: ClosedRange<Float> = (-Float.pi / 2)...(-Float.pi / 20)
    private var activeYawLimits: ClosedRange<Float> = (-Float.pi)...(Float.pi)

    private var initialCameraOrbitPosition: SCNVector3?
    private var initialCameraNodePosition: SCNVector3?
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

    private var loadingView: UIView?
    private var loadingTextLayer: CATextLayer?
    private var panVelocity: CGPoint = .zero

    private let tableService = TableService()
    
    // MARK: - UI Styles

    private enum PinStyle {
        static let activeColor = UIColor(red: 0.39, green: 0.84, blue: 0.48, alpha: 1.0)
        static let inactiveColor = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1.0)
        static let djGold = UIColor(red: 0.85, green: 0.60, blue: 0.21, alpha: 1.0)
    }

    let resetViewBtn: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        config.baseForegroundColor = .black
        config.background.backgroundColor = .white
        config.background.cornerRadius = 10
        config.attributedTitle = AttributedString(
            "Reset View",
            attributes: AttributeContainer([
                .font: AppFont.font(.inter, weight: .medium, size: 11)
            ])
        )

        let btn = UIButton(configuration: config)
        btn.alpha = 0 // hidden initially
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        buyNowBtnView.isHidden = true
        zoneSelector.isHidden = true
        mapView.backgroundColor = .clear
        setupAdvancedLoader()
        showAdvancedLoader()
        setupResetViewButton()
        setupSceneView()
        setupCameraGestures()
        setupZoneSelector()
        fetchLayOut()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.frame = mapView.bounds
        mapView.bringSubviewToFront(resetViewBtn)
        if let loadingView = loadingView {
            mapView.bringSubviewToFront(loadingView)
        }
    }

    @IBAction func onClickBuyNow(_ sender: Any) {
        guard let selectedId = selectedSeatingId else { return }
        guard let selectedArea = seatingAreas.first(where: { $0.parentSeatingAreaId == selectedId }) else { return }
        openSeatingArea(selectedArea)
        setupBuyNowButton()
    }
}

extension Tables3DMapVC: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { self.applyInertia() }
    }
}

// MARK: - UI Setup

private extension Tables3DMapVC {

    func setupSceneView() {
        sceneView.frame = mapView.bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .clear
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode = .multisampling4X
        sceneView.isPlaying = true
        sceneView.isJitteringEnabled = true
        sceneView.rendersContinuously = true
        sceneView.scene = SCNScene()
        sceneView.delegate = self
        mapView.addSubview(sceneView)
    }

    func setupBuyNowButton() {
        buyNowBtn.backgroundColor = .white
        if let hex = self.event?.whiteLabelColor {
            let color = UIColor(hex: hex)
            buyNowBtn.bgColor = color
        }
    }

    func setupZoneSelector() {
        zoneSelector.onSelectItem = { [weak self] _, globalIdx in
            guard let self else { return }
            self.selectedGlobalRoomIndex = globalIdx
            self.loadSelectedRoomModel()
        }
        zoneSelector.onNextPage = nil
        zoneSelector.onPrevPage = nil
    }

    func adaptFovForAspect(
        baseFov: Float,     // vertical FOV from API (degrees), designed for baseAspect
        baseAspect: Float,  // aspect the API FOV was authored for (width/height, e.g. 1.6)
        targetAspect: Float // actual screen aspect (width/height)
    ) -> Float {
        let vFovRad = baseFov * .pi / 180
        // Recover horizontal FOV as authored on the web
        let hFovRad = 2 * atan(tan(vFovRad / 2) * baseAspect)
        // Convert to vertical FOV for the iOS screen
        let newVFovRad = 2 * atan(tan(hFovRad / 2) / targetAspect)
        return newVFovRad * 180 / .pi
    }
}

// MARK: - Data / API

extension Tables3DMapVC {

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
            for (key, value) in propDict { stringProps[key.lowercased()] = "\(value)" }
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
        let timezone = event?.venue?.useTimezone ?? ""
        let dateText = event?.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss, to: .YYYYMMDD, customTimeZone: timezone
        ) ?? ""
        if timezone == "" { return }
        setupBuyNowButton()
        tableService.fetchConsumerLayout(
            date: dateText,
            venueId: event?.venue?.id ?? ""
        ) { [weak self] ok, msg, layout in
            guard let self else { return }
            DispatchQueue.main.async {
                if ok, let layout {
                    let items = layout.layoutHistories?.first?.layoutHistoryHas3DMaps ?? []
                    self.roomItems = items.sorted {
                        ($0.order ?? Int.max) < ($1.order ?? Int.max)
                    }
                    if self.roomItems.count > 1 {
                        self.zoneSelector.isHidden = false
                    }
                    self.selectedGlobalRoomIndex = 0
                    self.applyRoomItems(animated: false)
                    self.loadSelectedRoomModel()
                } else {
                    print("Layout error:", msg ?? "unknown")
                }
            }
        }
    }

    func normalizedString(_ value: Any?) -> String? {
        switch value {
        case let str as String:
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case let num as NSNumber:
            return num.stringValue
        case let dou as Double:
            return dou == dou.rounded() ? String(Int(dou)) : String(dou)
        case let int as Int:
            return String(int)
        default:
            return nil
        }
    }

    private func firstExtraValue(in extras: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = normalizedString(extras[key]), value != "1", value != "1.0" {
                return value
            }
        }
        return nil
    }

    private func normalizeExtras(_ extras: Any?) -> [String: Any] {
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

    private func resolveSeatingArea(from extras: [String: Any]) -> SeatingAreaDTO? {
        let raw = firstExtraValue(in: extras, keys: [
            "seatingareatag", "seatingareaid", "parentseatingareaid", "areaid", "area_id"
        ])
        guard let raw else { return nil }

        if let area = seatingAreaFilteredOutByParentId[raw] {
            return SeatingAreaDTO(
                id: area.id,
                parentSeatingAreaId: area.parentSeatingAreaId,
                name: area.name,
                highlight: area.highlight,
                maxGuest: area.maxGuest,
                isDJBoot: false,
                minimum: area.minimum,
                allowActions: true
            )
        }

        if let area = seatingAreaFilteredOutById[raw] {
            return SeatingAreaDTO(
                id: area.id,
                parentSeatingAreaId: area.parentSeatingAreaId ?? area.id,
                name: area.name,
                highlight: area.highlight,
                maxGuest: area.maxGuest,
                isDJBoot: false,
                minimum: area.minimum,
                allowActions: true
            )
        }

        if let area = seatingAreaByParentId[raw] {
            return SeatingAreaDTO(
                id: area.id,
                parentSeatingAreaId: area.parentSeatingAreaId,
                name: area.name,
                highlight: area.highlight,
                maxGuest: area.maxGuest,
                isDJBoot: false,
                minimum: area.minimum,
                allowActions: false
            )
        }

        if let area = seatingAreaById[raw] {
            return SeatingAreaDTO(
                id: area.id,
                parentSeatingAreaId: area.parentSeatingAreaId ?? area.id,
                name: area.name,
                highlight: area.highlight,
                maxGuest: area.maxGuest,
                isDJBoot: false,
                minimum: area.minimum,
                allowActions: false
            )
        }

        print("⚠️ seating raw id \(raw) not found in any seating map")
        return nil
    }

    func applyRoomItems(animated: Bool) {
        let names = roomItems
            .compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        zoneSelector.setItems(
            names,
            selectedIndex: selectedGlobalRoomIndex,
            borderColor: event?.whiteLabelColor
        )
    }

    private func openSeatingArea(_ item: SeatingArea) {
        guard item.hideCheckout != true else {
            print("Inquire tapped for:", item.name ?? "")
            return
        }

        Navigate.to.premiumTableSeatingVC(
            self,
            event: event,
            seatingArea: item,
            promotionLinkId: promotionLinkId,
            promotionLinkUniqueCode: promotionLinkUniqueCode
        )
//        Navigate.to.tableSeatingVC(self, seatingArea: item, event: event) { [weak self] time, guestCount, _, _ in
//            guard let self = self else { return }
//            let uuid    = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
//            let queueId = "TABLE_BOOKING_QUEUE_\(uuid)"
//            TablePresenter.createSeatingAreaBooking(
//                eventId: self.event?.id ?? "",
//                seatingAreaId: item.id ?? "",
//                timeSlotId: item.bookingType == .default ? nil : time,
//                venueId: event?.venue?.id ?? "",
//                guests: guestCount,
//                queueId: queueId
//            ) { isSuccess, errMsg, _ in
//                if isSuccess {
//                    if let event = self.event {
//                        Navigate.to.tablePurchaseVC(self, queueId: queueId, event: event, seatingAreas: self.seatingAreas)
//                    }
//                } else { print(errMsg ?? "Booking failed") }
//            }
//        }
    }

    func loadSelectedRoomModel() {
        guard selectedGlobalRoomIndex >= 0, roomItems.count > selectedGlobalRoomIndex else { return }
        let item = roomItems[selectedGlobalRoomIndex]
        hideResetViewButton()
        guard let glb = item.url3dMap, !glb.isEmpty else { return }
        loadGLBFromServerPath(from: glb, layout: item)
    }
}

// MARK: - GLB Loading

private extension Tables3DMapVC {

    func loadGLBFromServerPath(from path: String, layout: Layout3DMap) {
        let baseURL = "https://media.speakeasygo.com/"
        guard let url = URL(string: baseURL + path) else { return }
        loadGLB(from: url, layout: layout)
    }

    func loadGLB(from url: URL, layout: Layout3DMap) {
        let loadId = UUID()
        currentLoadId = loadId
        resetSceneState()
        showAdvancedLoader()

        GLTFAsset.load(with: url, options: [:]) { [weak self] _, status, asset, error, _ in
            guard let self else { return }
            guard self.currentLoadId == loadId else { print("Old GLB ignored"); return }
            guard status == .complete, let asset, error == nil else {
                DispatchQueue.main.async {
                    self.hideAdvancedLoader()
                }
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
                    DispatchQueue.main.async {
                        self.setupCamera(scene, layout: layout)
                        self.setupTapGesture()
                        self.hideAdvancedLoader()
                    }
                }
            }
        }
    }

    private func setSceneScaleFactor(scene: SCNScene) {
        var minVec = SCNVector3(
            Float.greatestFiniteMagnitude,
            Float.greatestFiniteMagnitude,
            Float.greatestFiniteMagnitude
        )
        var maxVec = SCNVector3(
            -Float.greatestFiniteMagnitude,
            -Float.greatestFiniteMagnitude,
            -Float.greatestFiniteMagnitude
        )

        scene.rootNode.enumerateChildNodes { node, _ in
            guard node.geometry != nil, !node.isHidden else { return }

            // Skip background/environment/sky meshes that inflate bounds
            let name = (node.name ?? node.geometry?.name ?? "").lowercased()
            let skipKeywords = [
                "sky", "dome", "sphere", "environment", "background",
                "backdrop", "city", "world", "ceiling", "floor", "ground",
                "wall", "room", "exterior", "terrain", "landscape"
            ]
            if skipKeywords.contains(where: { name.contains($0) }) { return }

            let (bmin, bmax) = node.boundingBox

            // Skip nodes with extremely large individual dimensions (likely background geo)
            let nodeSize = max(abs(bmax.x - bmin.x), abs(bmax.y - bmin.y), abs(bmax.z - bmin.z))
            if nodeSize > 500 { return } // skip anything bigger than 500 units

            let worldMin = node.convertPosition(bmin, to: nil)
            let worldMax = node.convertPosition(bmax, to: nil)
            minVec.x = Swift.min(minVec.x, worldMin.x)
            minVec.y = Swift.min(minVec.y, worldMin.y)
            minVec.z = Swift.min(minVec.z, worldMin.z)
            maxVec.x = Swift.max(maxVec.x, worldMax.x)
            maxVec.y = Swift.max(maxVec.y, worldMax.y)
            maxVec.z = Swift.max(maxVec.z, worldMax.z)
        }

        guard minVec.x.isFinite, maxVec.x.isFinite else {
            print("⚠️ setSceneScaleFactor: no valid nodes found, defaulting to 10")
            self.sceneScaleFactor = 10
            return
        }

        let size = SCNVector3(maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z)
        let raw = max(size.x, size.y, size.z)

        // Hard clamp: never let sceneScaleFactor go above 50
        self.sceneScaleFactor = raw

        print("📐 sceneScaleFactor: \(self.sceneScaleFactor) (raw: \(raw))")
    }

    private func resetSceneState() {
        selectedSeatingId = nil
        seatingAreaByMeshName.removeAll()
        meshNodesBySeatingId.removeAll()
        originalMaterials.removeAll()
        renderedDJKeys.removeAll()
        currentDistance = 0
        minDistance = 0
        maxDistance = 0
        minYaw = -.pi
        maxYaw = .pi
        minPitch = -Float.pi / 2
        maxPitch = Float.pi / 2
        sceneView.gestureRecognizers?
            .filter { $0 is UITapGestureRecognizer }
            .forEach { sceneView.removeGestureRecognizer($0) }
        cameraOrbit = SCNNode()
        cameraNode = SCNNode()
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
            let lookupKeys = [
                nodeName, meshName,
                nodeName.replacingOccurrences(of: ".", with: ""),
                meshName.replacingOccurrences(of: ".", with: ""),
                nodeName.replacingOccurrences(of: "_", with: ""),
                meshName.replacingOccurrences(of: "_", with: "")
            ].filter { !$0.isEmpty }
            var metadataExtras: [String: Any] = [:]
            for key in lookupKeys {
                if let props = metaProps[key] {
                    for (key, value) in props { metadataExtras[key.lowercased()] = value }
                    break
                }
            }
            var extras = meshExtras
            for (key, value) in nodeExtras { extras[key] = value }
            for (key, value) in metadataExtras { extras[key] = value }
            let djBootValue = (normalizedString(extras["djboottag"]) ?? "").lowercased()
            let isDJ = djBootValue == "true"
            if isDJ {
                let dto = SeatingAreaDTO(
                    id: nil, parentSeatingAreaId: nil, name: "DJ",
                    highlight: nil, maxGuest: nil, isDJBoot: true,
                    minimum: nil, allowActions: false
                )
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
            let normalized = nodeName
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: ".", with: "")
                .lowercased()
            if let dto = seatingAreaByMeshName[nodeName] ?? seatingAreaByMeshName[normalized] {
                let seatingId = dto.parentSeatingAreaId ?? ""
                guard !seatingId.isEmpty else { return }
                meshNodesBySeatingId[seatingId, default: []].append(node)
            }
        }
        cacheOriginalMaterials()
    }

    private func cacheOriginalMaterials() {
        for (_, nodes) in meshNodesBySeatingId {
            for node in nodes {
                if let geo = node.geometry {
                    originalMaterials[node] = geo.materials.map { $0.copy() as! SCNMaterial }
                }
            }
        }
    }

    private func worldTopCenter(of node: SCNNode) -> simd_float3 {
        let (lo, hi) = node.boundingBox
        let topLocal = simd_float3((lo.x + hi.x) / 2, hi.y, (lo.z + hi.z) / 2)
        return node.simdConvertPosition(topLocal, to: nil)
    }

    private func highlightMeshOnlySelected(meta: SeatingMeta) {
        resetAllMeshes()
        guard let nodes = meshNodesBySeatingId[meta.seatingAreaId] else { return }
        for node in nodes {
            applyUniqueMaterial(to: node)
            node.geometry?.materials.forEach { mat in
                if let hex = self.event?.whiteLabelColor {
                    let color = UIColor(hex: hex)
                    mat.emission.contents = color
                } else {
                    mat.emission.contents = UIColor.systemPink.withAlphaComponent(0.05)
                }
                mat.emission.intensity = 0.05
            }
        }
    }

    private func applyUniqueMaterial(to node: SCNNode) {
        guard let geo = node.geometry else { return }
        geo.materials = geo.materials.map { $0.copy() as! SCNMaterial }
    }

    private func resetAllMeshes() {
        for (node, mats) in originalMaterials {
            node.geometry?.materials = mats.map { $0.copy() as! SCNMaterial }
        }
    }
}

// MARK: - Dot Rendering

private extension Tables3DMapVC {

    func renderDots(scene: SCNScene) {
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

    private func makeTableDot(position: simd_float3, seating: SeatingAreaDTO, sourceNode: SCNNode) -> SCNNode {
        let root = SCNNode()
        let scale = uiScale(for: position)
        let yOffset = Float(0.15 * scale)
        root.simdPosition = position + simd_float3(0, yOffset, 0)

        let uiNode = makeBillboardNode()
        uiNode.renderingOrder = 100
        uiNode.name = "pin"

        let dotColor: UIColor = seating.allowActions ? PinStyle.activeColor : PinStyle.inactiveColor

        let hitGeo = SCNPlane(width: 0.75 * scale, height: 0.75 * scale)
        hitGeo.cornerRadius = 0.375 * scale
        hitGeo.materials = [constantMaterial(color: UIColor.clear)]

        let hitNode = SCNNode(geometry: hitGeo)
        hitNode.name = "hit"
        uiNode.addChildNode(hitNode)

        let pulseGeo = SCNPlane(width: 0.45 * scale, height: 0.45 * scale)
        pulseGeo.cornerRadius = (0.45 * scale) / 2
        pulseGeo.materials = [constantMaterial(color: dotColor.withAlphaComponent(0.40))]
        let pulse = SCNNode(geometry: pulseGeo)
        pulse.name = "wave"
        pulse.position.z = -0.002
        addSoftPulseAnimation(to: pulse)
        uiNode.addChildNode(pulse)

        let glowGeo = SCNPlane(width: 0.12 * scale, height: 0.12 * scale)
        glowGeo.cornerRadius = (0.12 * scale) / 2
        glowGeo.materials = [constantMaterial(color: dotColor.withAlphaComponent(0.45))]

        let glow = SCNNode(geometry: glowGeo)
        glow.name = "glow"
        glow.position.z = -0.001
        uiNode.addChildNode(glow)

        let dotGeo = SCNPlane(width: 0.15 * scale, height: 0.15 * scale)
        dotGeo.cornerRadius = (0.15 * scale) / 2
        dotGeo.materials = [constantMaterial(color: dotColor)]

        let dot = SCNNode(geometry: dotGeo)
        dot.name = "circle"
        dot.position.z = 0.001
        uiNode.addChildNode(dot)

        let ring = SCNNode(geometry: SCNTorus(ringRadius: 0.090 * scale, pipeRadius: 0.003 * scale))
        ring.name = "ring"
        ring.geometry?.materials = [constantMaterial(color: UIColor.white.withAlphaComponent(0.9))]
        ring.eulerAngles.x = -.pi / 2
        ring.position.z = 0.003
        uiNode.addChildNode(ring)

        let line = makeStraightLine(height: 0.25 * scale, scale: scale)
        line.name = "line"
        line.position = SCNVector3(0, Float(0.21 * scale), 0)
        line.opacity = 0
        line.isHidden = true
        uiNode.addChildNode(line)

        let label = makeLabelCard(
            title: seating.name ?? "", guests: seating.maxGuest ?? 0,
            minAmount: seating.minimum, dotColor: dotColor, scale: scale
        )
        label.name = "label"
        label.position = SCNVector3(0, Float(0.9 * scale), 0)
        label.opacity = 0
        label.isHidden = true
        uiNode.addChildNode(label)

        uiNode.seatingMeta = SeatingMeta(
            seatingAreaId: seating.parentSeatingAreaId ?? seating.id ?? "",
            name: seating.name ?? "", parentId: seating.parentSeatingAreaId ?? "",
            maxGuest: seating.maxGuest ?? 0, minimum: seating.minimum, allowActions: seating.allowActions,
            sourceNode: sourceNode, uniqueId: UUID().uuidString
        )
        root.addChildNode(uiNode)
        return root
    }

    private func highlightOnlySelectedDot(meta: SeatingMeta) {
        sceneView.scene?.rootNode.enumerateHierarchy { node, _ in
            guard let mesh = node.seatingMeta else { return }
            let isSelected = (mesh.uniqueId == meta.uniqueId)
            if let label = node.childNodes.first(where: { $0.name == "label" }) {
                label.isHidden = !isSelected
                label.opacity = isSelected ? 1 : 0
            }
            if let line = node.childNodes.first(where: { $0.name == "line" }) {
                line.isHidden = !isSelected
                line.opacity = isSelected ? 1 : 0
            }
        }
    }

    private func resetSelection() {
        resetAllMeshes()
        sceneView.scene?.rootNode.enumerateHierarchy { node, _ in
            guard let mesh = node.seatingMeta else { return }
            if let wave = node.childNodes.first(where: { $0.name == "wave" }) {
                wave.geometry?.materials.first?.diffuse.contents =
                    (mesh.allowActions ? PinStyle.activeColor : PinStyle.inactiveColor).withAlphaComponent(0.4)
            }
            if let label = node.childNodes.first(where: { $0.name == "label" }) {
                label.removeAllActions()
                label.isHidden = true
                label.opacity = 0
            }
            if let line = node.childNodes.first(where: { $0.name == "line" }) {
                line.removeAllActions()
                line.isHidden = true
                line.opacity = 0
            }
        }
    }

    private func hideCheckoutMode() {
        zoneSelector.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.buyNowBtnView.alpha = 0
            self.zoneSelector.alpha = 1
        } completion: { _ in self.buyNowBtnView.isHidden = true }
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

    private func addSoftPulseAnimation(to node: SCNNode) {
        node.removeAllActions()

        node.scale = SCNVector3(0.6, 0.6, 0.6)
        node.opacity = 0.6

        let expand = SCNAction.group([
            SCNAction.scale(to: 2.2, duration: 1.6),
            SCNAction.fadeOpacity(to: 0.0, duration: 1.6)
        ])

        expand.timingMode = .easeOut

        let reset = SCNAction.group([
            SCNAction.scale(to: 0.6, duration: 0.0),
            SCNAction.fadeOpacity(to: 0.6, duration: 0.0)
        ])

        let sequence = SCNAction.sequence([
            expand,
            reset
        ])

        node.runAction(.repeatForever(sequence))
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
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pan)
        sceneView.addGestureRecognizer(pinch)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        // Zoom in on double-tap
        currentDistance = max(minDistance, currentDistance * 0.75)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        updateCameraDistance()
        SCNTransaction.commit()
        showResetViewButton()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let delta = gesture.translation(in: sceneView)
        gesture.setTranslation(.zero, in: sceneView)

        let viewWidth = Float(max(sceneView.bounds.width, 1))
        let viewHeight = Float(max(sceneView.bounds.height, 1))

        let dyaw = -Float(delta.x) * (Float.pi / viewWidth)
        let dpitch = -Float(delta.y) * (Float.pi / viewHeight)

        applyRotation(dyaw: dyaw, dpitch: dpitch)

        if gesture.state == .ended {
            let vel = gesture.velocity(in: sceneView)
            panVelocity = CGPoint(
                x: vel.x * CGFloat(Float.pi / viewWidth) * 0.001,
                y: vel.y * CGFloat(Float.pi / viewHeight) * 0.001
            )
        } else {
            panVelocity = .zero
        }

        showResetViewButton()
    }

    // Call this from sceneView renderer or a CADisplayLink
    private func applyInertia() {
        guard abs(panVelocity.x) > 0.0001 || abs(panVelocity.y) > 0.0001 else {
            panVelocity = .zero
            return
        }
        applyRotation(dyaw: -Float(panVelocity.x), dpitch: -Float(panVelocity.y))
        panVelocity.x *= 0.98 // friction — lower = stops faster
        panVelocity.y *= 0.98
    }

    private func applyRotation(dyaw: Float, dpitch: Float) {
        currentYaw = (currentYaw + dyaw).clamped(to: activeYawLimits)
        currentPitch = (currentPitch + dpitch).clamped(to: activePitchLimits)
        cameraOrbit.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let zoomSpeed: Float = 0.25
        let delta = Float(1 - gesture.scale)
        gesture.scale = 1
        currentDistance += delta * zoomSpeed * currentDistance
        currentDistance = Swift.min(Swift.max(currentDistance, minDistance), maxDistance)
        updateCameraDistance()
        showResetViewButton()
    }

    private func updateCameraDistance() {
        let dir = cameraNode.position.normalized()
        cameraNode.position = SCNVector3(
            dir.x * currentDistance,
            dir.y * currentDistance,
            dir.z * currentDistance
        )
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: sceneView)
        let hits = sceneView.hitTest(point, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .boundingBoxOnly: false,
            .ignoreHiddenNodes: true
        ])
        guard let pin = findPinNode(from: hits), let meta = pin.seatingMeta else {
            handleOutsideTap()
            return
        }
        guard meta.allowActions else {
            print("Tapped unavailable area:", meta.name)
            return
        }
        applySelection(meta: meta)
    }

    private func findPinNode(from hits: [SCNHitTestResult]) -> SCNNode? {
        return hits.lazy.compactMap { result -> SCNNode? in
            var current: SCNNode? = result.node
            while let node = current {
                if node.seatingMeta != nil { return node }
                current = node.parent
            }
            return nil
        }.first
    }

    private func handleOutsideTap() {
        guard let previousId = selectedSeatingId else { return }
        resetSelection()
        resetPinColor(seatingAreaId: previousId, in: sceneView.scene)
        selectedSeatingId = nil
        buyNowBtnView.isHidden = true
        zoneSelector.isHidden = false
    }

    private func applySelection(meta: SeatingMeta) {
        selectedSeatingId = meta.seatingAreaId
        highlightOnlySelectedDot(meta: meta)
        highlightMeshOnlySelected(meta: meta)

        let highlightColor = event?.whiteLabelColor.map { UIColor(hex: $0) } ?? PinStyle.activeColor
        updatePinColor(seatingAreaId: meta.seatingAreaId, color: highlightColor, in: sceneView.scene)

        buyNowBtnView.isHidden = false
        zoneSelector.isHidden = true
    }
}

// MARK: - DJ Dot

private extension Tables3DMapVC {

    private func uiScale(for position: simd_float3) -> CGFloat {
        let raw = CGFloat(sceneScaleFactor) * 0.07
        return raw
    }

    private func makeDJDot(position: simd_float3, sourceNode: SCNNode) -> SCNNode {
        let oldScale = uiScale(for: position)
        let scale = CGFloat(min(oldScale, 12.0))
        let rawBase = CGFloat(sceneScaleFactor) * 0.018
        let base = CGFloat(min(rawBase, 1.8))

        let root = SCNNode()
        root.simdPosition = position + simd_float3(0, Float(0.5 * scale), 0)
        root.name = "dj-pin"

        let uiNode = makeBillboardNode()
        uiNode.renderingOrder = 900

        let gold = PinStyle.djGold
        var zPos: Float = 0

        let glowSize = base * 2.2 * scale
        let glowGeo = SCNPlane(width: glowSize, height: glowSize)
        glowGeo.cornerRadius = glowSize / 2
        glowGeo.materials = [djMaterial(color: gold.withAlphaComponent(0.20))]
        let glow = SCNNode(geometry: glowGeo)
        glow.position.z = zPos
        zPos += 0.001
        glow.renderingOrder = 900
        addDJWaveAnimation(to: glow)
        uiNode.addChildNode(glow)

        let outerCircleSize = base * 1.85 * scale
        let outerCircleGeo = SCNPlane(width: outerCircleSize, height: outerCircleSize)
        outerCircleGeo.cornerRadius = outerCircleSize / 2
        outerCircleGeo.materials = [djMaterial(color: UIColor.white.withAlphaComponent(0.9))]
        let outerCircle = SCNNode(geometry: outerCircleGeo)
        outerCircle.position.z = zPos
        zPos += 0.001
        outerCircle.renderingOrder = 901
        uiNode.addChildNode(outerCircle)

        let innerFillSize = base * 1.70 * scale
        let innerFillGeo = SCNPlane(width: innerFillSize, height: innerFillSize)
        innerFillGeo.cornerRadius = innerFillSize / 2
        innerFillGeo.materials = [djMaterial(color: gold.withAlphaComponent(0.9))]
        let innerFill = SCNNode(geometry: innerFillGeo)
        innerFill.position.z = zPos
        zPos += 0.001
        innerFill.renderingOrder = 902
        uiNode.addChildNode(innerFill)

        let innerRingSize = base * 1.35 * scale
        let innerRingGeo = SCNPlane(width: innerRingSize, height: innerRingSize)
        innerRingGeo.cornerRadius = innerRingSize / 2
        innerRingGeo.materials = [djMaterial(color: UIColor.white)]
        let innerRing = SCNNode(geometry: innerRingGeo)
        innerRing.position.z = zPos
        zPos += 0.001
        innerRing.renderingOrder = 903
        uiNode.addChildNode(innerRing)

        let centerFillSize = base * 1.22 * scale
        let centerFillGeo = SCNPlane(width: centerFillSize, height: centerFillSize)
        centerFillGeo.cornerRadius = centerFillSize / 2
        centerFillGeo.materials = [djMaterial(color: gold)]
        let centerFill = SCNNode(geometry: centerFillGeo)
        centerFill.position.z = zPos
        zPos += 0.001
        centerFill.renderingOrder = 904
        uiNode.addChildNode(centerFill)

        let djImage = makeDJTextImage(size: centerFillSize * 0.75)
        let labelSize = centerFillSize * 0.72
        let labelGeo = SCNPlane(width: labelSize, height: labelSize * 0.55)
        labelGeo.materials = [djMaterial(color: djImage)]
        let labelNode = SCNNode(geometry: labelGeo)
        labelNode.position.z = zPos
        labelNode.renderingOrder = 1000
        uiNode.addChildNode(labelNode)

        root.addChildNode(uiNode)
        return root
    }

    private func makeDJTextImage(size: CGFloat) -> UIImage {
        let width: CGFloat = 200
        let height: CGFloat = 130
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { ctx in
            // transparent background
            UIColor.clear.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 130),
                .foregroundColor: UIColor.white
            ]
            let str = "DJ" as NSString
            let textSize = str.size(withAttributes: attrs)
            let rect = CGRect(
                x: (width - textSize.width) / 2,
                y: (height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            str.draw(in: rect, withAttributes: attrs)
        }
    }

    private func addDJWaveAnimation(to node: SCNNode) {
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

        // World bounds ─────────────────────────────────────────────
        var minVec = SCNVector3(
            Float.greatestFiniteMagnitude,
            Float.greatestFiniteMagnitude,
            Float.greatestFiniteMagnitude
        )
        var maxVec = SCNVector3(
            -Float.greatestFiniteMagnitude,
            -Float.greatestFiniteMagnitude,
            -Float.greatestFiniteMagnitude
        )
        scene.rootNode.enumerateChildNodes { node, _ in
            let (bmin, bmax) = node.boundingBox
            let worldMin = node.convertPosition(bmin, to: nil)
            let worldMax = node.convertPosition(bmax, to: nil)
            minVec.x = Swift.min(minVec.x, worldMin.x)
            minVec.y = Swift.min(minVec.y, worldMin.y)
            minVec.z = Swift.min(minVec.z, worldMin.z)
            maxVec.x = Swift.max(maxVec.x, worldMax.x)
            maxVec.y = Swift.max(maxVec.y, worldMax.y)
            maxVec.z = Swift.max(maxVec.z, worldMax.z)
        }

        // Center & size ────────────────────────────────────────────
        let center = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )
        cameraOrbit.position = center

        let size = SCNVector3(maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z)
        let width = size.x
        let height = size.y
        let depth = size.z

        // Guard against zero bounds (happens if layout hasn't appeared yet).
        let viewSize = sceneView.bounds.size
        let safeWidth = viewSize.width > 0 ? viewSize.width : UIScreen.main.bounds.width
        let safeHeight = viewSize.height > 0 ? viewSize.height : UIScreen.main.bounds.height
        let screenAspect = Float(safeWidth / safeHeight)

        // then produce a correct vertical FOV for the actual iOS screen aspect.
        let apiBaseFov = Float(config.fieldOfView ?? 45)
        let apiBaseAspect = Float(config.ratio ?? 1.6) // web aspect the FOV was designed for

        let adaptedFov = adaptFovForAspect(
            baseFov: apiBaseFov,
            baseAspect: apiBaseAspect,
            targetAspect: screenAspect
        )

        let camera = SCNCamera()
        camera.usesOrthographicProjection = false
        camera.fieldOfView = CGFloat(adaptedFov)
        camera.zNear = 0.1
        camera.zFar = 5000
        cameraNode.camera = camera

        // Camera direction from API ────────────────────────────────
        let apiDir = SCNVector3(
            config.xPosition ?? 0,
            config.yPosition ?? 0,
            config.zPosition ?? 0
        ).normalized()

        let fovRad = adaptedFov * .pi / 180

        // Vertical fit: how far to see the full height
        let distanceV = height / (2 * tan(fovRad / 2))
        // Horizontal fit: how far to see the full width given screen aspect
        let distanceH = (depth > width ? depth : width) / (2 * tan(fovRad / 2)) / screenAspect
        let fitDistance = max(distanceV, distanceH)

        // adding ──────────────────────────────────────────────────
        let yFactor = abs(apiDir.y)
        let ratio1 = Float(config.ratio ?? 1.8)
        let ratioFactor = max(0.85, min(1.1, 1.8 / ratio1))
        let angleFactor = 1.05 + (1.25 - 1.05) * (1 - yFactor)
        let paddingFactor = max(1.05, min(1.35, angleFactor * ratioFactor))
        let finalDistance = fitDistance * paddingFactor

        // Place camera in the API direction ────────────────────────
        cameraNode.position = SCNVector3(
            apiDir.x * finalDistance,
            apiDir.y * finalDistance,
            apiDir.z * finalDistance
        )

        // Look-at constraint ───────────────────────────────────────
        let lookAt = SCNLookAtConstraint(target: cameraOrbit)
        lookAt.isGimbalLockEnabled = true
        cameraNode.constraints = [lookAt]

        // Add to scene ─────────────────────────────────────────────
        cameraOrbit.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraOrbit)
        sceneView.pointOfView = cameraNode

        // Rotation limits ─────────────────────────────────────────
        var apiPitchMin = Float(config.verticalRotationMin ?? 0)
        let apiPitchMax = Float(config.verticalRotationMax ?? 90)
        apiPitchMin = max(apiPitchMin - 25, 0)

        minPitch = -deg2rad(apiPitchMax)
        maxPitch = -deg2rad(apiPitchMin)

        minPitch = Swift.max(minPitch, -Float.pi / 2)
        maxPitch = Swift.min(maxPitch, -0.05)

        if minPitch > maxPitch { Swift.swap(&minPitch, &maxPitch) }
        activePitchLimits = minPitch...maxPitch

        let yawMinDeg = Float(config.horizontalRotationMin ?? -180)
        let yawMaxDeg = Float(config.horizontalRotationMax ?? 180)
        minYaw = deg2rad(yawMinDeg)
        maxYaw = deg2rad(yawMaxDeg)
        if minYaw > maxYaw { Swift.swap(&minYaw, &maxYaw) }
        activeYawLimits = minYaw...maxYaw

        let camPos = cameraNode.position
        let xzLen = sqrt(camPos.x * camPos.x + camPos.z * camPos.z)
        let initPitch: Float = atan2(-camPos.y, max(xzLen, 0.001)) // negative = looking down
        let initYaw: Float = atan2(camPos.x, camPos.z)

        // Clamp to API limits before applying
        currentPitch = initPitch.clamped(to: activePitchLimits)
        currentYaw = initYaw.clamped(to: activeYawLimits)

        let distance = camPos.length()
        cameraNode.position = SCNVector3(0, 0, distance)
        cameraOrbit.eulerAngles = SCNVector3(currentPitch, currentYaw, 0)

        // Save initial state for reset
        initialCameraOrbitPosition = cameraOrbit.position
        initialCameraNodePosition = cameraNode.position
        initialPitch = currentPitch
        initialYaw = currentYaw

        // Zoom limits (distance-based) ────────────────────────────
        currentDistance = cameraNode.position.length()
        let zoomMin = config.zoomMin ?? 1
        let zoomMax = config.zoomMax ?? 100

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

    private func deg2rad(_ value: Float) -> Float { value * .pi / 180 }

    private func bestVisualAnchorNode(for node: SCNNode) -> SCNNode {
        var current: SCNNode? = node
        var bestNode = node
        var bestSize: Float = 0
        while let num = current {
            let (lo, hi) = num.boundingBox
            let size = max(abs(hi.x - lo.x), abs(hi.z - lo.z), abs(hi.y - lo.y))
            if num.geometry != nil, !num.isHidden, size > bestSize {
                bestSize = size
                bestNode = num
            }
            current = num.parent
        }
        return bestNode
    }

    func setupLights() {
        sceneView.scene?.rootNode.childNodes
            .filter { $0.light != nil }
            .forEach { $0.removeFromParentNode() }

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 2
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        sceneView.scene?.rootNode.addChildNode(ambientNode)

        let dir = SCNLight()
        dir.type = .directional
        dir.intensity = 350
        dir.castsShadow = false
        let dirNode = SCNNode()
        dirNode.light = dir
        dirNode.eulerAngles = SCNVector3(-0.9, -0.6, 0)
        sceneView.scene?.rootNode.addChildNode(dirNode)
        sceneView.scene?.lightingEnvironment.intensity = 1
    }
}

// MARK: - UI Helpers

private extension Tables3DMapVC {

    func constantMaterial(color: Any, doubleSided: Bool = true) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.lightingModel = .constant
        mat.isDoubleSided = doubleSided
        mat.writesToDepthBuffer = true
        mat.readsFromDepthBuffer = false
        return mat
    }

    private func djMaterial(color: Any) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.lightingModel = .constant
        mat.isDoubleSided = true
        mat.writesToDepthBuffer = false
        mat.readsFromDepthBuffer = false
        return mat
    }

    func makeBillboardNode() -> SCNNode {
        let node = SCNNode()
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = [.X, .Y, .Z]
        node.constraints = [constraint]
        node.renderingOrder = 900
        return node
    }

    func makeStraightLine(height: CGFloat, scale: CGFloat) -> SCNNode {
        let geo = SCNPlane(width: 0.01 * scale, height: height)
        geo.materials = [constantMaterial(color: UIColor.white)]
        let node = SCNNode(geometry: geo)
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = [.X, .Y, .Z]
        node.constraints = [constraint]
        return node
    }

    func makeLabelCard(
        title: String, guests: Int, minAmount: Double?,
        dotColor: UIColor, scale: CGFloat = 1.0
    ) -> SCNNode {

//        let padding: CGFloat = 14
//        let titleFont: CGFloat = 22
//        let subFont: CGFloat = 19
//        let guestFont: CGFloat = 19
//        let gap: CGFloat = 6

        let padding: CGFloat = 20      // was 14
        let titleFont: CGFloat = 26    // was 22
        let subFont: CGFloat = 22      // was 19
        let guestFont: CGFloat = 22    // was 19
        let gap: CGFloat = 10          // was 6
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: titleFont)
        titleLabel.textColor = .white
        titleLabel.sizeToFit()

        let minAmountLabel = UILabel()
        minAmountLabel.text = minAmount != nil ? "$ \(Int(minAmount ?? 0)) min." : ""
        minAmountLabel.font = .systemFont(ofSize: subFont, weight: .medium)
        minAmountLabel.textColor = UIColor(white: 0.95, alpha: 1)
        minAmountLabel.sizeToFit()

        let guestsLabel = UILabel()
        guestsLabel.text = "\(guests) Guests"
        guestsLabel.font = .systemFont(ofSize: guestFont, weight: .medium)
        guestsLabel.textColor = UIColor(white: 0.95, alpha: 1)
        guestsLabel.sizeToFit()

        let rowWidth = guestsLabel.bounds.width
        let canvasW = max(titleLabel.bounds.width, minAmountLabel.bounds.width, rowWidth) + padding * 2
        
        let canvasH = padding
            + titleLabel.bounds.height + gap
            + (minAmountLabel.text?.isEmpty == false ? minAmountLabel.bounds.height + gap : 0)
            + guestsLabel.bounds.height
            + padding

        let container = UIView(frame: CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
        container.backgroundColor = UIColor.black.withAlphaComponent(0.82)
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor

        var yPos: CGFloat = padding

        titleLabel.frame.origin = CGPoint(x: (canvasW - titleLabel.bounds.width) / 2, y: yPos)
        container.addSubview(titleLabel)
        yPos = titleLabel.frame.maxY + gap

        if minAmountLabel.text?.isEmpty == false {
            minAmountLabel.frame.origin = CGPoint(x: (canvasW - minAmountLabel.bounds.width) / 2, y: yPos)
            container.addSubview(minAmountLabel)
            yPos = minAmountLabel.frame.maxY + gap
        }

        let rowX = (canvasW - rowWidth) / 2
        guestsLabel.frame.origin = CGPoint(x: rowX, y: yPos)
        container.addSubview(guestsLabel)

        let renderer = UIGraphicsImageRenderer(size: container.bounds.size)
        let image = renderer.image { ctx in container.layer.render(in: ctx.cgContext) }

        let pxPerUnit: CGFloat = 100
        let planeW = (canvasW / pxPerUnit) * scale
        let planeH = (canvasH / pxPerUnit) * scale

        let plane = SCNPlane(width: planeW, height: planeH)
        plane.materials = [constantMaterial(color: image)]

        let node = SCNNode(geometry: plane)
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = [.X, .Y, .Z]
        node.constraints = [constraint]
        return node
    }
}

private extension Tables3DMapVC {

    func setupAdvancedLoader() {
        let container = UIView()
        container.backgroundColor = UIColor.clear
        container.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: mapView.topAnchor),
            container.bottomAnchor.constraint(equalTo: mapView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: mapView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: mapView.trailingAnchor)
        ])

        loadingView = container

        create3DLoadingText(in: container)
    }

    func create3DLoadingText(in view: UIView) {
        DispatchQueue.main.async {
            let textLayer = CATextLayer()
            textLayer.string = "Loading 3D Map..."
            textLayer.font = AppFont.font(.inter, weight: .medium, size: 14)
            textLayer.fontSize = 14
            textLayer.alignmentMode = .center
            textLayer.foregroundColor = UIColor(hex: (self.event?.whiteLabelColor ?? "#FFFFFF")).cgColor
            textLayer.contentsScale = UIScreen.main.scale

            textLayer.frame = CGRect(
                x: 0,
                y: view.bounds.midY - 60,
                width: view.bounds.width,
                height: 40
            )

            view.layer.addSublayer(textLayer)
            self.loadingTextLayer = textLayer

            self.addFloatingAnimation(to: textLayer)
        }
    }
    
    func addFloatingAnimation(to layer: CALayer) {
        let anim = CABasicAnimation(keyPath: "transform.translation.y")
        anim.fromValue = -5
        anim.toValue = 5
        anim.duration = 1.2
        anim.autoreverses = true
        anim.repeatCount = .infinity
        
        layer.add(anim, forKey: "float")
    }
    
    func showAdvancedLoader() {
        let loadingViewHidden = loadingView?.isHidden == true
        loadingView?.isHidden = false
        if let textLayer = self.loadingTextLayer, loadingViewHidden {
            self.addFloatingAnimation(to: textLayer)
        }
    }

    func hideAdvancedLoader() {
        loadingView?.isHidden = true
        loadingTextLayer?.removeAllAnimations()
    }
}

// MARK: - Reset View UI

private extension Tables3DMapVC {

    func setupResetViewButton() {
        mapView.addSubview(resetViewBtn)
        resetViewBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            resetViewBtn.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 10),
            resetViewBtn.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -12)
        ])

        resetViewBtn.addTarget(self, action: #selector(onTapResetView), for: .touchUpInside)
    }

    func showResetViewButton() {
        guard resetViewBtn.alpha == 0 else { return }

        UIView.animate(withDuration: 0.2) {
            self.resetViewBtn.alpha = 1
        }
    }

    func hideResetViewButton() {
        UIView.animate(withDuration: 0.2) {
            self.resetViewBtn.alpha = 0
        }
    }

    @objc func onTapResetView() {
        guard let orbitPos = initialCameraOrbitPosition,
              let camPos = initialCameraNodePosition else { return }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4

        cameraOrbit.position = orbitPos
        cameraNode.position = camPos
        cameraOrbit.eulerAngles = SCNVector3(initialPitch, initialYaw, 0)

        currentPitch = initialPitch
        currentYaw = initialYaw

        currentDistance = cameraNode.position.length()

        SCNTransaction.commit()

        hideResetViewButton()
    }
}
