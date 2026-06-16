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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    init(frame: CGRect, lighter: Bool) {
        super.init(frame: frame)
        setupUI(lighter: lighter)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError()
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
        guard !isAnimating else { return }
        isAnimating = true
        addShimmerAnimation()
    }

    // MARK: - Stop

    func stopShimmer() {
        isAnimating = false
        gradientLayer.removeAnimation(forKey: "shimmer")
    }

    // MARK: - Private
//    
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
