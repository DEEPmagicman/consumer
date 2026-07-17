//
//  ShimmerView.swift
//  Doorman
//
//  Created by Square Infosoft on 04/03/25.
//

import UIKit

final class ShimmerView: UIView {

    private let gradientLayer = CAGradientLayer()
    private var wantsAnimation = false

    init(frame: CGRect = .zero, lighter: Bool = false) {
        super.init(frame: frame)
        setup(lighter: lighter)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(lighter: false)
    }

    deinit {
        releaseResources()
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
        wantsAnimation = true
        startAnimationIfPossible()
    }

    func stopAnimating() {
        wantsAnimation = false
        stopLayerAnimations()
    }

    func releaseResources() {
        wantsAnimation = false
        stopLayerAnimations()
        gradientLayer.removeAllAnimations()
    }

    override var isHidden: Bool {
        didSet {
            if isHidden {
                stopLayerAnimations()
            } else if wantsAnimation {
                startAnimationIfPossible()
            }
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window == nil {
            stopLayerAnimations()
        } else if wantsAnimation {
            startAnimationIfPossible()
        }
    }

    private func startAnimationIfPossible() {
        guard window != nil,
              !isHidden,
              alpha > 0.01,
              gradientLayer.animation(forKey: "shimmer") == nil else {
            return
        }

        let anim            = CABasicAnimation(keyPath: "locations")
        anim.fromValue      = [-0.8, -0.4, 0.0]
        anim.toValue        = [1.0, 1.4, 1.8]
        anim.duration       = 1.5
        anim.repeatCount    = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        gradientLayer.add(anim, forKey: "shimmer")
    }

    private func stopLayerAnimations() {
        gradientLayer.removeAnimation(forKey: "shimmer")
    }
}
