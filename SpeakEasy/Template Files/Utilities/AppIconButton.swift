//
//  AppIconButton.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 14/05/26.
//

import Foundation
import UIKit
import SwiftUI
// MARK: - UIKit AppIconButton

private struct GlassButtonView: View {
    let iconType: AppIconType
    let iconSize: CGFloat
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                Image(uiImage: iconType.image ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
            }
            .frame(width: iconType.buttonSize, height: iconType.buttonSize)
            .glassEffect(.regular.interactive(), in: .circle)
        } else {
            // Fallback on earlier versions
        }
    }
}

@IBDesignable
final class AppIconButton: UIButton {

    @IBInspectable var iconTypeValue: String = AppIconType.back.rawValue {
        didSet { updateGlass() }
    }

    @IBInspectable var iconSize: CGFloat = 12 {
        didSet { updateGlass() }
    }

    private var iconType: AppIconType {
        AppIconType(rawValue: iconTypeValue) ?? .back
    }

    private var widthConstraintRef: NSLayoutConstraint?
    private var heightConstraintRef: NSLayoutConstraint?
    private var hostingController: UIHostingController<GlassButtonView>?

    // MARK: Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupGlass()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        // IB fallback — glass APIs not available at design time
        backgroundColor = .white.withAlphaComponent(0.2)
        layer.cornerRadius = iconType.buttonSize / 2
        clipsToBounds = true
        setButtonSize(iconType.buttonSize)
        setIcon(iconType.image, size: iconSize)
    }

    // MARK: Setup

    private func setupGlass() {
        // Hide the UIButton's own chrome — SwiftUI renders everything
        backgroundColor = .clear
        setImage(nil, for: .normal)
        setTitle(nil, for: .normal)

        setButtonSize(iconType.buttonSize)
        embedGlassView()
    }

    private func embedGlassView() {
        // Remove old hosting controller if re-embedding
        hostingController?.view.removeFromSuperview()

        let glassView = GlassButtonView(
            iconType: iconType,
            iconSize: iconSize
        ) { [weak self] in
            self?.sendActions(for: .touchUpInside)
        }

        let hc = UIHostingController(rootView: glassView)
        hc.view.backgroundColor = .clear
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hc.view.isUserInteractionEnabled = true
        addSubview(hc.view)

        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingController = hc
    }

    private func updateGlass() {
        setButtonSize(iconType.buttonSize)
        embedGlassView()
    }

    // MARK: Size (unchanged from your original)

    private func setButtonSize(_ size: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false

        if widthConstraintRef == nil {
            widthConstraintRef = widthAnchor.constraint(equalToConstant: size)
            widthConstraintRef?.isActive = true
        }
        if heightConstraintRef == nil {
            heightConstraintRef = heightAnchor.constraint(equalToConstant: size)
            heightConstraintRef?.isActive = true
        }

        widthConstraintRef?.constant  = size
        heightConstraintRef?.constant = size
    }

    // MARK: IB fallback helpers (only used in prepareForInterfaceBuilder)

    private func setIcon(_ image: UIImage?, size: CGFloat) {
        guard let image else { setImage(nil, for: .normal); return }
        let resized = resizeImage(image, targetSize: CGSize(width: size, height: size))
        setImage(resized.withRenderingMode(.alwaysOriginal), for: .normal)
        imageView?.contentMode         = .center
        contentHorizontalAlignment     = .center
        contentVerticalAlignment       = .center
        imageEdgeInsets                = .zero
        contentEdgeInsets              = .zero
    }

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: targetSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
