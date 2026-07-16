//
//  AppIconButton.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 14/05/26.
//

import UIKit
import SwiftUI

// MARK: - UIKit AppIconButton

enum AppIconType: String {
    case leftSideBack
    case back
    case close
    case seeAll
    case filter
    case share
    case map
    case search
    case questionMark

    var image: UIImage? {
        switch self {
        case .leftSideBack:
            return UIImage(systemName: "arrow.left")
        case .back:
            return UIImage(named: "backButtonIcon")
        case .close:
            return UIImage(named: "closeMarkIcon")
        case .seeAll:
            return UIImage(named: "seeAllButtonIcon")
        case .filter:
            return UIImage(named: "filterIcon")
        case .share:
            return UIImage(named: "shareIcon")
        case .map:
            return UIImage(named: "mapIcon")
        case .search:
            return UIImage(resource: .searchIconV3)
        case .questionMark:
            return UIImage(named: "questionMarkIcon")
        }
    }

    var buttonSize: CGFloat {
        switch self {
        case .leftSideBack, .back, .filter:
            return 50
        case .close, .share, .map, .search:
            return 40
        case .seeAll:
            return 36
        case .questionMark:
            return 24
        }
    }
}

private struct GlassButtonView: View {

    let iconType: AppIconType
    let iconSize: CGFloat
    let buttonSize: CGFloat
    let tintColor: UIColor
    let action: () -> Void

    var body: some View {

        Group {
            if AppDesign.useModernIOS26Design {
                if #available(iOS 26.0, *) {
                    
                    Button(action: action) {
                        if let image = iconType.image {
                            Image(uiImage: image)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: iconSize, height: iconSize)
                                .foregroundStyle(Color(tintColor))
                        }
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                    )
                    .glassEffect(.regular.interactive(), in: .circle)
                    
                }
            } else {

                Button(action: action) {
                    if let image = iconType.image {
                        Image(uiImage: image)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                            .foregroundStyle(Color(tintColor))
                    }
                }
                .frame(width: buttonSize, height: buttonSize)
                .glassFallback()
            }
        }
    }
}

@IBDesignable
final class AppIconButton: UIButton {

    // MARK: Inspectables

    @IBInspectable
    var iconTypeValue: String = AppIconType.back.rawValue {
        didSet {
            updateHostingView()
        }
    }

    @IBInspectable
    var iconSize: CGFloat = 12 {
        didSet {
            updateHostingView()
        }
    }

    @IBInspectable
    var buttonSize: CGFloat = 0 {
        didSet {
            setButtonSize(resolvedButtonSize)
            updateHostingView()
        }
    }

    @IBInspectable
    var iconTintColor: UIColor = .label {
        didSet {
            updateHostingView()
        }
    }

    // MARK: Private

    private var iconType: AppIconType {
        AppIconType(rawValue: iconTypeValue) ?? .back
    }

    private var resolvedButtonSize: CGFloat {
        buttonSize > 0 ? buttonSize : iconType.buttonSize
    }

    private var widthConstraintRef: NSLayoutConstraint?
    private var heightConstraintRef: NSLayoutConstraint?

    private lazy var hostingController = UIHostingController(
        rootView: AnyView(EmptyView())
    )

    private var hostingInstalled = false

    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    deinit {
        releaseResources()
    }

    // MARK: Setup

    private func commonInit() {

        backgroundColor = .clear
        setImage(nil, for: .normal)
        setTitle(nil, for: .normal)

        setButtonSize(resolvedButtonSize)

        installHostingIfNeeded()

        updateHostingView()
    }

    private func installHostingIfNeeded() {

        guard !hostingInstalled else { return }

        hostingInstalled = true

        let view = hostingController.view!

        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(view)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateHostingView() {
        installHostingIfNeeded()

        hostingController.rootView = AnyView(GlassButtonView(
            iconType: iconType,
            iconSize: iconSize,
            buttonSize: resolvedButtonSize,
            tintColor: iconTintColor
        ) { [weak self] in
            AppHaptic.navigation()
            self?.sendActions(for: .touchUpInside)
        })
    }

    func releaseResources() {
        hostingController.rootView = AnyView(EmptyView())
        hostingController.view.removeFromSuperview()
        hostingInstalled = false
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = resolvedButtonSize / 2
        clipsToBounds = false
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        backgroundColor = .white.withAlphaComponent(0.2)
        layer.cornerRadius = resolvedButtonSize / 2
        clipsToBounds = true

        setButtonSize(resolvedButtonSize)
        setIcon(iconType.image, size: iconSize)
    }

    // MARK: - Size

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

        widthConstraintRef?.constant = size
        heightConstraintRef?.constant = size
    }

    // MARK: - Interface Builder

    private func setIcon(_ image: UIImage?, size: CGFloat) {

        guard let image else {
            setImage(nil, for: .normal)
            return
        }

        let resized = resizeImage(
            image,
            targetSize: CGSize(width: size, height: size)
        )

        setImage(
            resized.withRenderingMode(.alwaysOriginal),
            for: .normal
        )

        imageView?.contentMode = .center
    }

    private func resizeImage(
        _ image: UIImage,
        targetSize: CGSize
    ) -> UIImage {

        UIGraphicsImageRenderer(size: targetSize).image { _ in
            image.draw(
                in: CGRect(
                    origin: .zero,
                    size: targetSize
                )
            )
        }
    }
}

struct GlassFallbackModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                    
                    Circle()
                        .fill(Color.white.opacity(0.02))
                }
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 0.2)
            )
            .shadow(radius: 10, y: 4)
    }
}

extension View {
    func glassFallback() -> some View {
        modifier(GlassFallbackModifier())
    }
}
