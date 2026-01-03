//
//  Tables3DMapVC.swift
//  SpeakEasy-Consumer
//
//  Created by Deep on 03/01/26.
//

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
    private let sceneView = SCNView()
    private let tapCategory: Int = 4
    
    private var sceneBounds: (min: SCNVector3, max: SCNVector3)?
    private var selectedSeatingId: String? = nil
    
    var parentByChildId: [String: SeatingAreaAPIModel] = [:]
    var seatingAreaByMeshName: [String: SeatingAreaDTO] = [:]
    
    private var currentYaw: Float = -Float.pi / 14
    private var currentPitch: Float = -Float.pi / 7
    
    private let cameraOrbit = SCNNode()
    private let cameraNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSceneView()
        setupCameraGestures()
        
        // replace with server URL
        loadGLB_Local()
    }
}

// MARK: - Scene Setup

private extension Tables3DMapVC {
    
    func setupSceneView() {
        sceneView.frame = view.bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .black
        sceneView.allowsCameraControl = false
        sceneView.cameraControlConfiguration.allowsTranslation = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.scene = SCNScene()
        view.addSubview(sceneView)
    }
}

// MARK: - GLB Loading

private extension Tables3DMapVC {
    
    func loadGLB_Local() {
        guard let url = Bundle.main.url(forResource: "hotel_map", withExtension: "glb") else {
            fatalError("GLB not found")
        }
        loadGLB(from: url)
    }
    
    // SERVER READY
    func loadGLB(from url: URL) {
        GLTFAsset.load(with: url, options: [:]) { [weak self] _, status, asset, error, _ in
            guard let self, status == .complete, let asset, error == nil else { return }
            
            DispatchQueue.main.async {
                self.loadSeatingAreaMap()
                self.buildMeshSeatingMap(asset: asset)
                
                let scene = SCNScene(gltfAsset: asset)
                self.sceneView.scene = scene
                
                self.setupCamera(scene)
                self.setupLights()
                self.setupTapGesture()
                self.renderParentDots(scene: scene)
            }
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
    
    func buildMeshSeatingMap(asset: GLTFAsset) {
        
        for (index, mesh) in asset.meshes.enumerated() {
            guard let meshName = mesh.name else { continue }
            
            let meshExtras = normalizeExtras(mesh.extras)
            let nodeExtras = index < asset.nodes.count ? normalizeExtras(asset.nodes[index].extras) : [:]
            
            // Mesh has priority
            let extras = meshExtras.merging(nodeExtras) { _, new in new }
            var dto: SeatingAreaDTO?
            
            if extras["djtag"] != nil || extras["djboottag"] != nil {
                dto = SeatingAreaDTO(id: nil, parentSeatingAreaId: nil, name: "DJ", highlight: nil, maxGuest: nil, isDJBoot: true)
            }
            else if let tag = extras["seatingareatag"] as? String,
                    let parent = parentByChildId[tag] {
                dto = SeatingAreaDTO(
                    id: parent.parentSeatingAreaId,
                    parentSeatingAreaId: parent.parentSeatingAreaId,
                    name: parent.name,
                    highlight: parent.highlight,
                    maxGuest: parent.maxGuest,
                    isDJBoot: false
                )
            }
            else if let id = extras["seatingareaid"] as? String, (extras["seatingareatag"] as? String) == nil, !id.isEmpty {
                dto = SeatingAreaDTO(id: id, parentSeatingAreaId: nil, name: "Seating \(id)", highlight: nil, maxGuest: nil, isDJBoot: false)
            }
            
            if let dto {
                seatingAreaByMeshName[meshName] = dto
                print("🧩 Mesh mapped:", meshName, extras)
            }
        }
    }
    
    func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tap)
    }
    
    func setupCameraGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        
        sceneView.addGestureRecognizer(pan)
        sceneView.addGestureRecognizer(pinch)
    }
    
    @objc func handlePan(_ g: UIPanGestureRecognizer) {
        
        let delta = g.translation(in: sceneView)
        g.setTranslation(.zero, in: sceneView)
        
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
    
    @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
        
        guard let cam = cameraNode.camera else { return }
        
        cam.orthographicScale *= Double(1 / g.scale)
        g.scale = 1
        
        cam.orthographicScale = min(
            max(cam.orthographicScale, CameraConfig.minOrtho),
            CameraConfig.maxOrtho
        )
    }
    
    @objc func handleTap(_ g: UITapGestureRecognizer) {
        let p = g.location(in: sceneView)
        guard let hit = sceneView.hitTest(p).first?.node else { return }
        
        resetAllDots()
        
        var node: SCNNode? = hit
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
            updateCircle(node, color: PinStyle.normalColor)
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
        
        // Scene bounds
        let minVec = scene.rootNode.boundingBox.min
        let maxVec = scene.rootNode.boundingBox.max
        sceneBounds = (minVec, maxVec)
        
        // Scene center
        var center = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )
        
        // Scene size (used for zoom + distance)
        let sceneSize = max(
            maxVec.x - minVec.x,
            maxVec.z - minVec.z
        )
        
        // Camera
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = Double(sceneSize)
        camera.zNear = 0.1
        camera.zFar = 5000
        
        cameraNode.camera = camera
        // Camera distance (fixed)
        cameraNode.position = SCNVector3(0, sceneSize * 0.2, sceneSize * 0.2)
        
        // Orbit pivot at CENTER
        cameraOrbit.position = center
        cameraOrbit.addChildNode(cameraNode)
        
        // Initial angles
        currentPitch = -Float.pi / 7
        currentYaw   = -Float.pi / 14
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
