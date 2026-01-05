//
//  Fonts.swift
//  FreshDate
//
//  Created by Amir Shayegh on 2018-08-06.
//

import Foundation
import UIKit

class Fonts {

    static let regular: UIFont = UIFont(name: "HelveticaNeue", size: 17)!

    static let heavy: UIFont = UIFont(name: "HelveticaNeue-Bold", size: 17)!

    static let light: UIFont = UIFont(name: "HelveticaNeue-Light", size: 17)!

    static let medium: UIFont = UIFont(name: "HelveticaNeue-Medium", size: 17)!
    
    static func poppinsRegular(_ size: CGFloat) -> UIFont {
        UIFont(name: "Poppins-Regular", size: size) ?? UIFont.systemFont(ofSize: size, weight: .medium)
    }
}

enum AppFont {

    // MARK: - Font Family
    enum Family {
        case inter
        case poppins

        var prefix: String {
            switch self {
            case .inter:    return "Inter"
            case .poppins:  return "Poppins"
            }
        }
    }

    // MARK: - Weight
    enum Weight: String {
        case regular = "Regular"
        case medium = "Medium"
        case semibold = "SemiBold"
        case bold = "Bold"
    }

    // MARK: - Main Font
    static func font(
        _ family: Family = .inter,
        weight: Weight = .regular,
        size: CGFloat
    ) -> UIFont {

        let fontName = "\(family.prefix)-\(weight.rawValue)"

        return UIFont(name: fontName, size: size)
            ?? UIFont.systemFont(ofSize: size)
    }
}
