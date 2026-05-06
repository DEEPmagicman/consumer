//
//  ShimmerView.swift
//  Doorman
//
//  Created by Square Infosoft on 04/03/25.
//

import UIKit

//final class ShimmerView2: UIView {
//
//    var gradientColorOne: CGColor = UIColor(white: 0.24, alpha: 0.4).cgColor
//    var gradientColorTwo: CGColor = UIColor(white: 0.28, alpha: 0.6).cgColor
//    
//    private var gradientLayer: CAGradientLayer?
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        gradientLayer?.frame = bounds
//    }
//    
//    private func addGradientLayer() -> CAGradientLayer {
//        gradientLayer?.removeFromSuperlayer()
//        
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.frame = bounds
//        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.4)
//        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
//        gradientLayer.colors = [gradientColorOne, gradientColorTwo, gradientColorTwo, gradientColorOne]
//        gradientLayer.locations = [0.0, 0.48, 0.52, 1.0]
//        layer.addSublayer(gradientLayer)
//        clipsToBounds = true
//        self.gradientLayer = gradientLayer
//        return gradientLayer
//    }
//    
//    private func addAnimation() -> CABasicAnimation {
//        let animation = CABasicAnimation(keyPath: "locations")
//        animation.fromValue = [-1.0, -0.7, -0.4, 0.0]
//        animation.toValue = [1.0, 1.3, 1.7, 2.0]
//        animation.repeatCount = .infinity
//        animation.duration = 1.4
//        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//        return animation
//    }
//    
//    func startAnimating() {
//        let gradientLayer = addGradientLayer()
//        gradientLayer.add(addAnimation(), forKey: "shimmerAnimation")
//    }
//    
//    func stopAnimating() {
//        gradientLayer?.removeAllAnimations()
//        gradientLayer?.removeFromSuperlayer()
//        gradientLayer = nil
//    }
//}

final class ShimmerView: UIView {

    private let gradientLayer = CAGradientLayer()

    init(frame: CGRect = .zero, lighter: Bool = false) {
        super.init(frame: frame)
        setup(lighter: lighter)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(lighter: false)
    }

    private func setup(lighter: Bool) {
        let base      = UIColor(white: lighter ? 0.14 : 0.17, alpha: 1).cgColor
        let highlight = UIColor(white: lighter ? 0.14 : 0.26, alpha: 1).cgColor

        gradientLayer.colors     = [base, highlight, base]
        gradientLayer.locations  = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func startAnimating() {
        guard gradientLayer.animation(forKey: "shimmer") == nil else { return }
        let anim            = CABasicAnimation(keyPath: "locations")
        anim.fromValue      = [-0.8, -0.4, 0.0]
        anim.toValue        = [1.0,  1.4,  1.8]
        anim.duration       = 1.5
        anim.repeatCount    = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        gradientLayer.add(anim, forKey: "shimmer")
    }

    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: "shimmer")
    }
}
