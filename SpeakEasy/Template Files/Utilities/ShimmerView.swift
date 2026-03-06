//
//  ShimmerView.swift
//  Doorman
//
//  Created by Square Infosoft on 04/03/25.
//

import UIKit

final class ShimmerView: UIView {

    var gradientColorOne: CGColor = UIColor(white: 0.24, alpha: 0.4).cgColor
    var gradientColorTwo: CGColor = UIColor(white: 0.28, alpha: 0.6).cgColor
    
    private var gradientLayer: CAGradientLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
        layer.cornerRadius = 8
        clipsToBounds = true
    }
    
    private func addGradientLayer() -> CAGradientLayer {
        gradientLayer?.removeFromSuperlayer()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.4)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.colors = [gradientColorOne, gradientColorTwo, gradientColorTwo, gradientColorOne]
        gradientLayer.locations = [0.0, 0.48, 0.52, 1.0]
        layer.addSublayer(gradientLayer)
        layer.cornerRadius = 8
        clipsToBounds = true
        self.gradientLayer = gradientLayer
        return gradientLayer
    }
    
    private func addAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.7, -0.4, 0.0]
        animation.toValue = [1.0, 1.3, 1.7, 2.0]
        animation.repeatCount = .infinity
        animation.duration = 1.4
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return animation
    }
    
    func startAnimating() {
        let gradientLayer = addGradientLayer()
        gradientLayer.add(addAnimation(), forKey: "shimmerAnimation")
    }
    
    func stopAnimating() {
        gradientLayer?.removeAllAnimations()
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
    }
}
