//
//  ShimmerView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class ShimmerViewV3: UIView {

    private let gradientLayer =
        CAGradientLayer()

    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {

        backgroundColor =
            UIColor.white.withAlphaComponent(0.01)

        clipsToBounds = true

        layer.cornerRadius = 8
        layer.backgroundColor = UIColor.clear.cgColor
        gradientLayer.colors = [

            UIColor.white
                .withAlphaComponent(0.01)
                .cgColor,

            UIColor.white
                .withAlphaComponent(0.06)
                .cgColor,

            UIColor.white
                .withAlphaComponent(0.01)
                .cgColor
        ]

        gradientLayer.startPoint =
            CGPoint(x: 0, y: 0.5)

        gradientLayer.endPoint =
            CGPoint(x: 1, y: 0.5)

        layer.addSublayer(
            gradientLayer
        )
    }

    override func layoutSubviews() {

        super.layoutSubviews()

        gradientLayer.frame = CGRect(
            x: -bounds.width,
            y: 0,
            width: bounds.width * 3,
            height: bounds.height
        )
    }

    // MARK: - Start

    func startShimmer() {

        guard !isAnimating else {
            return
        }

        isAnimating = true

        let animation =
            CABasicAnimation(
                keyPath:
                    "transform.translation.x"
            )

        animation.fromValue =
        -bounds.width

        animation.toValue =
        bounds.width

        animation.duration = 1.4

        animation.repeatCount = .infinity

        gradientLayer.add(
            animation,
            forKey: "shimmer"
        )
    }

    // MARK: - Stop

    func stopShimmer() {

        isAnimating = false

        gradientLayer.removeAnimation(
            forKey: "shimmer"
        )
    }
}
