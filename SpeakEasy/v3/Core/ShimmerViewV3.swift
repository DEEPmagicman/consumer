//
//  ShimmerView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class ShimmerViewV3: UIView {

    private let gradientLayer = CAGradientLayer()
    private var isAnimating = false
    private var wantsShimmer = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    init(frame: CGRect, lighter: Bool) {
        super.init(frame: frame)
        setupUI(lighter: lighter)
    }
    
    deinit {
        releaseResources()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI(lighter: Bool = false) {
        backgroundColor = UIColor.white.withAlphaComponent(lighter ? 0.05 : 0.07)
        clipsToBounds = true
        layer.cornerRadius = 5
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Start

    func startShimmer() {
        wantsShimmer = true
        startAnimationIfPossible()
    }

    // MARK: - Stop

    func stopShimmer() {
        wantsShimmer = false
        stopLayerAnimations()
    }

    func releaseResources() {
        wantsShimmer = false
        stopLayerAnimations()
        layer.removeAllAnimations()
        gradientLayer.removeAllAnimations()
    }

    private func stopLayerAnimations() {
        isAnimating = false
        gradientLayer.removeAnimation(forKey: "shimmer")
        layer.removeAnimation(forKey: "pulse")
    }

    override var isHidden: Bool {
        didSet {
            if isHidden {
                stopLayerAnimations()
            } else if wantsShimmer {
                startAnimationIfPossible()
            }
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window == nil {
            stopLayerAnimations()
        } else if wantsShimmer {
            startAnimationIfPossible()
        }
    }

    // MARK: - Private

    private func startAnimationIfPossible() {
        guard window != nil,
              !isHidden,
              alpha > 0.01,
              !isAnimating else {
            return
        }

        isAnimating = true
        addShimmerAnimation()
    }

    private func addShimmerAnimation() {

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.3
        animation.toValue = 1.0

        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        layer.add(animation, forKey: "pulse")
    }
}
