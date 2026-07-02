//
//  LiquidGlassBackgroundView.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 14/05/26.
//

import Foundation
import SwiftUI

@available(iOS 26.0, *)
private struct LiquidGlassSurface: View {

    let cornerRadius: CGFloat
    let tintColor: Color
    let fillColor: Color
    let overrideBackgroundColor: Color?

    var body: some View {

        Group {

            if let overrideBackgroundColor {

                Rectangle()
                    .foregroundStyle(overrideBackgroundColor)

            } else {

                Rectangle()
                    .foregroundStyle(fillColor)
                    .glassEffect(
                        .regular.interactive(),
                        in: .capsule
                    )
            }
        }
        .cornerRadius(cornerRadius)
    }
}

final class LiquidGlassBackgroundView: UIView {
    
    private var _glassCornerRadius: CGFloat = 12
    private var _glassFillColor: UIColor = UIColor(white: 1, alpha: 0.04)
    private var _glassTintColor: UIColor = .clear
    private var _glassBorderColor: UIColor?
    private var _glassBorderWidth: CGFloat = 0.75

    // MARK: - Public Properties

    var glassCornerRadius: CGFloat {
        get { _glassCornerRadius }
        set { _glassCornerRadius = newValue; apply() }
    }

    var fillColor: UIColor {
        get { _glassFillColor }
        set { _glassFillColor = newValue; apply() }
    }

    var glassTintColor: UIColor {
        get { _glassTintColor }
        set { _glassTintColor = newValue; apply() }
    }

    var glassBorderColor: UIColor? {
        get { _glassBorderColor }
        set { _glassBorderColor = newValue; apply() }
    }

    var glassBorderWidth: CGFloat {
        get { _glassBorderWidth }
        set { _glassBorderWidth = newValue; apply() }
    }

    var overrideBackgroundColor: UIColor? {
        didSet { apply() }
    }

    // MARK: - Private

    private lazy var hostingController = UIHostingController(
        rootView: AnyView(EmptyView())
    )

    private var hostingInstalled = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        apply()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        apply()
    }
    
    deinit {
        if #available(iOS 26.0, *) {
            hostingController.view.removeFromSuperview()
        }

        print("🔥 LiquidGlassBackgroundView deinit")
    }
    
    convenience init(
        cornerRadius: CGFloat = 12,
        fillColor: UIColor = UIColor(white: 1, alpha: 0.04),
        borderColor: UIColor? = nil,
        borderWidth: CGFloat = 0.75,
        tintColor: UIColor = .clear
    ) {
        self.init(frame: .zero)
        _glassCornerRadius = cornerRadius
        _glassFillColor = fillColor
        _glassBorderColor = borderColor
        _glassBorderWidth = borderWidth
        _glassTintColor = tintColor
        apply()
    }

    // MARK: - Apply

    private func apply() {

        if #available(iOS 26.0, *) {
            applyGlass()
        } else {
            applyFallback()
        }
    }
    
    @available(iOS 26.0, *)
    private func applyGlass() {

        installHostingIfNeeded()

        backgroundColor = .clear
        layer.borderWidth = 0

        let surface = LiquidGlassSurface(
            cornerRadius: glassCornerRadius,
            tintColor: Color(glassTintColor),
            fillColor: Color(fillColor),
            overrideBackgroundColor: overrideBackgroundColor.map(Color.init)
        )

        hostingController.rootView = AnyView(surface)
    }
    
    @available(iOS 26.0, *)
    private func installHostingIfNeeded() {

        guard !hostingInstalled else { return }

        hostingInstalled = true

        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.isUserInteractionEnabled = false

        insertSubview(hostingController.view, at: 0)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func applyFallback() {
        if #available(iOS 26.0, *) {
            hostingController.view.removeFromSuperview()
            hostingInstalled = false
        }

        backgroundColor = overrideBackgroundColor ?? fillColor

        layer.cornerRadius = glassCornerRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true

        layer.borderColor = glassBorderColor?.cgColor
        layer.borderWidth = glassBorderColor != nil ? glassBorderWidth : 0  
    }
}
