//
//  SearchEmptyStateView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 04/06/26.
//

import UIKit
import AVFoundation

final class SearchEmptyStateView: UIView {

    private let iconContainer = UIView()
    private let searchIcon = UIImageView()

    private let titleLabel = UILabel()

    private let rippleLayer1 = CAShapeLayer()
    private let rippleLayer2 = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else { return }

        rippleLayer1.removeAllAnimations()
        rippleLayer2.removeAllAnimations()
        searchIcon.layer.removeAllAnimations()

        startAnimations()
    }

    private func setupUI() {

        let symbolConfig = UIImage.SymbolConfiguration(
            pointSize: 42,
            weight: .regular,
            scale: .medium
        )
        searchIcon.image = UIImage(systemName: "magnifyingglass", withConfiguration: symbolConfig)
        searchIcon.tintColor = .white
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.preferredSymbolConfiguration = symbolConfig
        searchIcon.layer.shouldRasterize = false
        searchIcon.layer.allowsEdgeAntialiasing = true

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        searchIcon.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconContainer)
        iconContainer.addSubview(searchIcon)

        titleLabel.text = "No Results Found"
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        titleLabel.font = Constant.Font.geistMedium(size: 16)
        titleLabel.textAlignment = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([

            iconContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconContainer.topAnchor.constraint(equalTo: topAnchor),

            iconContainer.widthAnchor.constraint(equalToConstant: 120),
            iconContainer.heightAnchor.constraint(equalToConstant: 120),

            searchIcon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            searchIcon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 44),
            searchIcon.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])

        createRipple(layer: rippleLayer1)
        createRipple(layer: rippleLayer2)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        rippleLayer1.frame = iconContainer.bounds
        rippleLayer2.frame = iconContainer.bounds

        let center = CGPoint(
            x: iconContainer.bounds.midX,
            y: iconContainer.bounds.midY
        )

        let path = UIBezierPath(
            ovalIn: CGRect(
                x: center.x - 50,
                y: center.y - 50,
                width: 100,
                height: 100
            )
        )

        rippleLayer1.path = path.cgPath
        rippleLayer2.path = path.cgPath
    }

    private func createRipple(layer: CAShapeLayer) {
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.withAlphaComponent(0.15).cgColor
        layer.lineWidth = 1
        iconContainer.layer.insertSublayer(layer, at: 0)
    }

    private func startAnimations() {

        let float = CABasicAnimation(keyPath: "transform.translation.y")
        float.fromValue = -6
        float.toValue = 6
        float.duration = 1.8
        float.autoreverses = true
        float.repeatCount = .infinity

        searchIcon.layer.add(float, forKey: "float")

        animateRipple(rippleLayer1, delay: 0)
        animateRipple(rippleLayer2, delay: 0.8)
    }

    private func animateRipple(
        _ layer: CAShapeLayer,
        delay: CFTimeInterval
    ) {

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.8
        scale.toValue = 1.8

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0.6
        opacity.toValue = 0

        let group = CAAnimationGroup()
        group.animations = [scale, opacity]
        group.duration = 2
        group.repeatCount = .infinity
        group.beginTime = AVCoreAnimationBeginTimeAtZero + delay
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards

        layer.add(group, forKey: nil)
    }
}
