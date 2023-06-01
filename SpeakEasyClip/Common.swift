//
//  Common.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 01/06/23.
//

import UIKit

extension UIView {
    func setGradientColor(colors: [CGColor] = CommonConstant.Color.gradientColors) -> CAGradientLayer {
        removeGradientBackgroundColor()
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.name = "gradientLayer"
        return gradientLayer
    }
    
    func removeGradientBackgroundColor() {
        layer.sublayers?.filter { $0.name == "gradientLayer" }.forEach { $0.removeFromSuperlayer() }
        layoutIfNeeded()
    }
}

struct CommonConstant {
    
    struct Color {
        static let gradientColors = [UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor]
    }

    struct Icon {
        static let checkBoxEmpty = UIImage(named: "checkBoxEmpty")
        static let checkBoxFull = UIImage(named: "checkBoxFull")
    }    
}
