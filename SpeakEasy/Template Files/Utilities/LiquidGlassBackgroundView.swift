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
    let tintColor: Color  // ✅ added
    let fillColor: Color = Color.white.opacity(0.04)

    var body: some View {
        Rectangle()
            .foregroundStyle(fillColor)
            .glassEffect(.regular.interactive(), in: .capsule)
            .cornerRadius(cornerRadius)
    }
}

final class LiquidGlassBackgroundView: UIView {

    var fillColor: UIColor = UIColor(white: 1, alpha: 0.04) { didSet { apply() } }

    private var hostingController: UIHostingController<AnyView>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        apply()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        apply()
    }

    convenience init(
        cornerRadius: CGFloat = 12,
        fillColor: UIColor = UIColor(white: 1, alpha: 0.04),
        borderColor: UIColor? = nil,
        borderWidth: CGFloat = 0.75,
        tintColor: UIColor = .clear  // ✅ added
    ) {
        self.init(frame: .zero)
        self.cornerRadius = cornerRadius
        self.fillColor    = fillColor
        self.borderColor  = borderColor
        self.borderWidth  = borderWidth
        self.tintColor    = tintColor  // ✅ added
        apply()
    }

    private func apply() {
        if #available(iOS 26.0, *) {
            applyGlass()
        } else {
            applyFallback()
        }
    }

    @available(iOS 26.0, *)
    private func applyGlass() {
        hostingController?.view.removeFromSuperview()
        backgroundColor   = .clear  // ✅ was fillColor, glass handles its own bg
        layer.borderWidth = 0

        let surface = LiquidGlassSurface(
            cornerRadius: cornerRadius,
            tintColor: Color(tintColor)
        )
        let hc = UIHostingController(rootView: AnyView(surface))
        hc.view.backgroundColor          = .clear
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hc.view.isUserInteractionEnabled = false
        insertSubview(hc.view, at: 0)

        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingController = hc
    }

    private func applyFallback() {
        hostingController?.view.removeFromSuperview()
        hostingController    = nil
        backgroundColor      = fillColor
        layer.cornerRadius   = cornerRadius
        layer.cornerCurve    = .continuous
        clipsToBounds        = true
        layer.borderColor    = borderColor?.cgColor
        layer.borderWidth    = borderColor != nil ? borderWidth : 0
    }
}
