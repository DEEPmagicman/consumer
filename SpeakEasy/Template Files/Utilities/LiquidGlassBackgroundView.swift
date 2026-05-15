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

    // MARK: - Public Properties

    var fillColor: UIColor = UIColor(
        white: 1,
        alpha: 0.04
    ) {
        didSet { apply() }
    }

    /// Pass custom background color when needed
    /// Example:
    /// glassView.overrideBackgroundColor = .white
    ///
    /// Default = nil (normal glass effect)
    var overrideBackgroundColor: UIColor? {
        didSet { apply() }
    }

    // MARK: - Private

    private var hostingController: UIHostingController<AnyView>?

    // MARK: - Init

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
        fillColor: UIColor = UIColor(
            white: 1,
            alpha: 0.04
        ),
        borderColor: UIColor? = nil,
        borderWidth: CGFloat = 0.75,
        tintColor: UIColor = .clear
    ) {

        self.init(frame: .zero)

        self.cornerRadius = cornerRadius
        self.fillColor    = fillColor
        self.borderColor  = borderColor
        self.borderWidth  = borderWidth
        self.tintColor    = tintColor

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

        hostingController?.view.removeFromSuperview()

        backgroundColor   = .clear
        layer.borderWidth = 0

        let surface = LiquidGlassSurface(
            cornerRadius: cornerRadius,
            tintColor: Color(tintColor),
            fillColor: Color(fillColor),
            overrideBackgroundColor: overrideBackgroundColor != nil
            ? Color(overrideBackgroundColor!)
            : nil
        )

        let hc = UIHostingController(
            rootView: AnyView(surface)
        )

        hc.view.backgroundColor = .clear
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
        hostingController = nil

        backgroundColor = overrideBackgroundColor ?? fillColor

        layer.cornerRadius = cornerRadius
        layer.cornerCurve  = .continuous
        clipsToBounds      = true

        layer.borderColor = borderColor?.cgColor
        layer.borderWidth = borderColor != nil
        ? borderWidth
        : 0
    }
}
