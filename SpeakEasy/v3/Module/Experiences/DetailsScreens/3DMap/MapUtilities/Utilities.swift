//
//  Extensions.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 30/06/26.
//

import UIKit
import SceneKit

// MARK: - Models & Metadata

struct SeatingAreaDTO {
    let id: String?
    let parentSeatingAreaId: String?
    let name: String?
    let highlight: String?
    let maxGuest: Int?
    let isDJBoot: Bool
    let minimum: Double?
    let allowActions: Bool
}

struct SeatingMeta {
    let seatingAreaId: String
    let name: String
    let parentId: String
    let maxGuest: Int
    let minimum: Double?
    let allowActions: Bool
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

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
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
