//
//  LiquidGlassBackgroundView.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 14/05/26.
//

import Foundation
import SwiftUI

private struct LiquidGlassSurface: View {

    let cornerRadius: CGFloat
    let tintColor: Color
    let fillColor: Color
    let borderColor: Color?
    let borderWidth: CGFloat
    let overrideBackgroundColor: Color?

    var body: some View {

        Group {

            if AppDesign.useModernIOS26Design {

                if #available(iOS 26.0, *) {

                    if let overrideBackgroundColor {

                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(overrideBackgroundColor)

                    } else {

                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .foregroundStyle(fillColor)
                            .glassEffect(.regular.interactive())
                    }

                } else {

                    LiquidGlassFallbackSurface(
                        cornerRadius: cornerRadius,
                        fillColor: fillColor,
                        borderColor: borderColor,
                        borderWidth: borderWidth,
                        overrideBackgroundColor: overrideBackgroundColor
                    )
                }

            } else {

                LiquidGlassFallbackSurface(
                    cornerRadius: cornerRadius,
                    fillColor: fillColor,
                    borderColor: borderColor,
                    borderWidth: borderWidth,
                    overrideBackgroundColor: overrideBackgroundColor
                )
            }
        }
    }
}

final class LiquidGlassBackgroundView: UIView {
    
    private var _glassCornerRadius: CGFloat = 12
    private var _glassFillColor: UIColor = UIColor(white: 1, alpha: 0.04)
    private var _glassTintColor: UIColor = .clear
    private var _glassBorderColor: UIColor?
    private var _glassBorderWidth: CGFloat = 0.75
    
    private lazy var blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
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
        if AppDesign.useModernIOS26Design {
            if #available(iOS 26.0, *) {
                hostingController.view.removeFromSuperview()
            }
        }
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
        
        installHostingIfNeeded()
        
        backgroundColor = .clear
        layer.borderWidth = 0
        
        let surface = LiquidGlassSurface(
            cornerRadius: glassCornerRadius,
            tintColor: Color(glassTintColor),
            fillColor: Color(fillColor),
            borderColor: glassBorderColor.map(Color.init),
            borderWidth: glassBorderWidth,
            overrideBackgroundColor: overrideBackgroundColor.map(Color.init)
        )
        
        hostingController.rootView = AnyView(surface)
    }
    
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
}

private struct LiquidGlassFallbackSurface: View {

    let cornerRadius: CGFloat
    let fillColor: Color
    let borderColor: Color?
    let borderWidth: CGFloat
    let overrideBackgroundColor: Color?

    var body: some View {

        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        overrideBackgroundColor?.opacity(0.24)
                        ?? fillColor
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        borderColor ?? Color.white.opacity(0.10),
                        lineWidth: borderColor == nil ? 0.8 : borderWidth
                    )
            }
            .shadow(radius: 10, y: 4)
    }
}
