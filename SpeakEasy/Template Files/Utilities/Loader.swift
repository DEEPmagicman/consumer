//
//  Loader.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import UIKit

struct Loader {

    static var isVisible: Bool {
        return LoaderOverlayView.shared.superview != nil
    }

    static func show() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else { return }

            let overlay = LoaderOverlayView.shared
            overlay.frame = window.bounds
            window.addSubview(overlay)
            overlay.startAnimating()

            UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .forEach { $0.isUserInteractionEnabled = false }
            window.isUserInteractionEnabled = true // overlay handles touches
        }
    }

    static func show(progress: Double) {
        show() // extend later if you need a progress arc
    }

    static func hide() {
        DispatchQueue.main.async {
            LoaderOverlayView.shared.stopAnimating()
            LoaderOverlayView.shared.removeFromSuperview()

            UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .forEach { $0.isUserInteractionEnabled = true }
        }
    }
}

// MARK: - Overlay

private final class LoaderOverlayView: UIView {

    static let shared = LoaderOverlayView()

    private let loaderView = SpeakEasyLoaderView(size: 72)

    private override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.45)
        addSubview(loaderView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        loaderView.center = center
    }

    func startAnimating() { loaderView.startAnimating() }
    func stopAnimating() { loaderView.stopAnimating() }

    // Block all touches so nothing behind fires
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { self }
}

// MARK: - Reusable loader badge (drop anywhere)

final class SpeakEasyLoaderView: UIView {

    // MARK: - Public

    /// Size of the whole component (badge + ring). Badge is ~72% of this.
    var size: CGFloat { bounds.width }

    // MARK: - Layers

    private let badgeLayer   = CALayer()
    private let arcLayer     = CAShapeLayer()
    private let arcLayer2    = CAShapeLayer()

    // MARK: - Init

    init(size: CGFloat) {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        backgroundColor = .clear
        setupBadge(size: size)
        setupArcs(size: size)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let s = bounds.width
        let badgeSize = s * 0.72
        let inset = (s - badgeSize) / 2
        badgeLayer.frame = CGRect(x: inset, y: inset, width: badgeSize, height: badgeSize)
        badgeLayer.cornerRadius = badgeSize * 0.22

        let center = CGPoint(x: s / 2, y: s / 2)
        let radius = (s / 2) - 2
        let path = UIBezierPath(arcCenter: center, radius: radius,
                                startAngle: -.pi / 2,
                                endAngle: 3 * .pi / 2,
                                clockwise: true).cgPath
        arcLayer.path  = path
        arcLayer2.path = path
        arcLayer.frame  = bounds
        arcLayer2.frame = bounds
    }

    // MARK: - Setup

    private func setupBadge(size: CGFloat) {
        let badgeSize = size * 0.72
        let inset = (size - badgeSize) / 2

        // Badge background — match your logo card colours
        badgeLayer.frame = CGRect(x: inset, y: inset, width: badgeSize, height: badgeSize)
        badgeLayer.cornerRadius = badgeSize * 0.22
        badgeLayer.masksToBounds = true

        // Gradient matching the appLogo card
        let gradLayer = CAGradientLayer()
        gradLayer.frame = CGRect(origin: .zero, size: CGSize(width: badgeSize, height: badgeSize))
        gradLayer.colors = [
            UIColor(red: 0.35, green: 0.39, blue: 0.46, alpha: 1).cgColor,
            UIColor(red: 0.17, green: 0.19, blue: 0.25, alpha: 1).cgColor
        ]
        gradLayer.startPoint = CGPoint(x: 0.2, y: 0.1)
        gradLayer.endPoint   = CGPoint(x: 0.8, y: 0.9)
        badgeLayer.addSublayer(gradLayer)

        // Logo image
        let imgLayer = CALayer()
        let padding: CGFloat = badgeSize * 0.12
        imgLayer.frame = CGRect(x: padding, y: padding,
                                width: badgeSize - padding * 2,
                                height: badgeSize - padding * 2)
        imgLayer.contents = UIImage(named: "appLogo")?.cgImage
        imgLayer.contentsGravity = .resizeAspect
        badgeLayer.addSublayer(imgLayer)

        layer.addSublayer(badgeLayer)
    }

    private func setupArcs(size: CGFloat) {
        // Outer arc — primary purple
        arcLayer.fillColor   = nil
        arcLayer.strokeColor = Constant.Color.purpleColor.cgColor
        arcLayer.lineWidth   = size * 0.038
        arcLayer.lineCap     = .round
        arcLayer.strokeStart = 0
        arcLayer.strokeEnd   = 0.30
        layer.addSublayer(arcLayer)

        // Inner arc — dimmer, counter-spins
        arcLayer2.fillColor   = nil
        arcLayer2.strokeColor = Constant.Color.purpleColor.withAlphaComponent(0.35).cgColor
        arcLayer2.lineWidth   = size * 0.022
        arcLayer2.lineCap     = .round
        arcLayer2.strokeStart = 0.55
        arcLayer2.strokeEnd   = 0.75
        layer.addSublayer(arcLayer2)
    }

    // MARK: - Animation

    func startAnimating() {
        guard arcLayer.animation(forKey: "spin") == nil else { return }

        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue   = CGFloat.pi * 2
        spin.duration  = 1.4
        spin.repeatCount = .infinity
        spin.timingFunction = CAMediaTimingFunction(name: .linear)
        arcLayer.add(spin, forKey: "spin")

        let spinRev = CABasicAnimation(keyPath: "transform.rotation.z")
        spinRev.fromValue = 0
        spinRev.toValue   = -CGFloat.pi * 2
        spinRev.duration  = 2.2
        spinRev.repeatCount = .infinity
        spinRev.timingFunction = CAMediaTimingFunction(name: .linear)
        arcLayer2.add(spinRev, forKey: "spinRev")

        // Subtle pulse on the badge
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue  = 1.0
        pulse.toValue    = 0.94
        pulse.duration   = 0.9
        pulse.autoreverses = true
        pulse.repeatCount  = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        badgeLayer.add(pulse, forKey: "pulse")
    }

    func stopAnimating() {
        arcLayer.removeAllAnimations()
        arcLayer2.removeAllAnimations()
        badgeLayer.removeAllAnimations()
    }
}
