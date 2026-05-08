//
//  ShimmerView.swift
//  Doorman
//
//  Created by Square Infosoft on 04/03/25.
//

import UIKit

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
        let base      = UIColor(white: lighter ? 0.08 : 0.10, alpha: 1).cgColor
        let highlight = UIColor(white: lighter ? 0.13 : 0.16, alpha: 1).cgColor

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
