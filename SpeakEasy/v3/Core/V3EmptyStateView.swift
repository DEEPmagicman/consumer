//
//  V3EmptyStateView.swift
//  SpeakEasy-Consumer
//
//  Created by Codex on 11/07/26.
//

import UIKit

enum V3EmptyStateStyle {
    case savedEvents
    case venues
    case mapVenues
    case tickets
    case reservations
    case artists
    case events
    case venueEvents
    case premiumEvents

    var title: String {
        switch self {
        case .savedEvents:
            return "No events saved"
        case .venues:
            return "No partners saved"
        case .mapVenues:
            return "No partners found"
        case .tickets:
            return "No tickets"
        case .reservations:
            return "No reservations"
        case .artists:
            return "No artist yet"
        case .events:
            return "No events found"
        case .venueEvents:
            return "No events yet"
        case .premiumEvents:
            return "No premium experiences"
        }
    }

    var imageName: String {
        switch self {
        case .savedEvents:
            return "savedEmptyIcon"
        case .venues, .mapVenues:
            return "venueEmptyIcon"
        case .tickets, .events, .venueEvents:
            return "ticketsEmptyIcon"
        case .premiumEvents:
            return "noPremiumEvents"
        case .reservations:
            return "reservationEmptyIcon"
        case .artists:
            return "artistEmptyIcon"
        }
    }

    var imageSize: CGSize {
        switch self {
        case .savedEvents:
            return CGSize(width: 100, height: 100)
        case .venues, .mapVenues:
            return CGSize(width: 80, height: 80)
        case .tickets, .reservations, .events, .venueEvents:
            return CGSize(width: 60, height: 60)
        case .premiumEvents:
            return CGSize(width: 84, height: 84)
        case .artists:
            return CGSize(width: 75, height: 75)
        }
    }

    var showsBrowseEventsButton: Bool {
        self == .savedEvents
    }
}

final class V3EmptyStateView: UIView {

    var onBrowseEvents: (() -> Void)?

    private let stackView = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let browseEventsButton = UIButton(type: .system)
    private var imageWidthConstraint: NSLayoutConstraint?
    private var imageHeightConstraint: NSLayoutConstraint?
    private var stackCenterYConstraint: NSLayoutConstraint?

    init(style: V3EmptyStateStyle) {
        super.init(frame: .zero)
        setupUI()
        configure(style: style)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configure(style: .savedEvents)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        configure(style: .savedEvents)
    }

    func configure(style: V3EmptyStateStyle) {
        imageView.image = UIImage(named: style.imageName)
        titleLabel.text = style.title
        browseEventsButton.isHidden = !style.showsBrowseEventsButton
        isUserInteractionEnabled = style.showsBrowseEventsButton

        imageWidthConstraint?.constant = style.imageSize.width
        imageHeightConstraint?.constant = style.imageSize.height
        stackCenterYConstraint?.constant = style == .savedEvents ? -72 : 0
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    private func setupUI() {
        backgroundColor = .clear

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
        addSubview(stackView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        stackView.addArrangedSubview(imageView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistRegular(size: 16)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        stackView.addArrangedSubview(titleLabel)
        stackView.setCustomSpacing(10, after: imageView)

        browseEventsButton.translatesAutoresizingMaskIntoConstraints = false
        browseEventsButton.backgroundColor = UIColor(hex: "#FFFFFF")
        browseEventsButton.setTitle("Browse Events", for: .normal)
        browseEventsButton.setTitleColor(UIColor(hex: "#121212"), for: .normal)
        browseEventsButton.titleLabel?.font = Constant.Font.geistMedium(size: 16)
        browseEventsButton.contentEdgeInsets = UIEdgeInsets(
            top: 9,
            left: 34,
            bottom: 9,
            right: 34
        )
        browseEventsButton.layer.cornerRadius = 18
        browseEventsButton.layer.masksToBounds = true
        browseEventsButton.addTarget(
            self,
            action: #selector(onClickBrowseEvents),
            for: .touchUpInside
        )
        stackView.addArrangedSubview(browseEventsButton)
        stackView.setCustomSpacing(28, after: titleLabel)

        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 100)
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 100)

        stackCenterYConstraint = stackView.centerYAnchor.constraint(equalTo: centerYAnchor)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackCenterYConstraint!,
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),

            imageWidthConstraint!,
            imageHeightConstraint!
        ])
    }

    @objc private func onClickBrowseEvents() {
        AppHaptic.primaryAction()
        onBrowseEvents?()
    }
}

final class V3NoInternetView: UIView {

    var onTryAgain: (() -> Void)?

    private let stackView = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let tryAgainButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    static func isNoInternet(_ message: String?) -> Bool {
        if !Connectivity.isConnectedToInternet {
            return true
        }

        guard let message else {
            return false
        }

        let normalizedMessage =
        message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalizedMessage.isEmpty else {
            return false
        }

        let noInternetMessage =
        Constant.String.internetNotConnect.lowercased()

        return normalizedMessage == noInternetMessage
            || normalizedMessage.contains("no internet")
            || normalizedMessage.contains("connection lost")
            || normalizedMessage.contains("request timed out")
            || normalizedMessage.contains("timed out")
            || normalizedMessage.contains("not connected to the internet")
            || normalizedMessage.contains("internet connection appears to be offline")
            || normalizedMessage.contains("network connection was lost")
    }

    static func backgroundView(
        frame: CGRect,
        onTryAgain: @escaping () -> Void
    ) -> UIView {
        let container = UIView(frame: frame)
        container.backgroundColor = .clear

        let noInternetView = V3NoInternetView()
        noInternetView.onTryAgain = onTryAgain
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(noInternetView)

        NSLayoutConstraint.activate([
            noInternetView.topAnchor.constraint(equalTo: container.topAnchor),
            noInternetView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            noInternetView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func setupUI() {
        backgroundColor = .clear

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
        addSubview(stackView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "noInternetIcon")
        imageView.contentMode = .scaleAspectFit
        stackView.addArrangedSubview(imageView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Internet Connection"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 16)
        titleLabel.textAlignment = .center
        stackView.addArrangedSubview(titleLabel)
        stackView.setCustomSpacing(24, after: imageView)

        tryAgainButton.translatesAutoresizingMaskIntoConstraints = false
        tryAgainButton.backgroundColor = UIColor(hex: "#FFFFFF")
        tryAgainButton.setTitle("Try Again", for: .normal)
        tryAgainButton.setTitleColor(UIColor(hex: "#121212"), for: .normal)
        tryAgainButton.titleLabel?.font = Constant.Font.geistMedium(size: 16)
        tryAgainButton.layer.cornerRadius = 21
        tryAgainButton.layer.masksToBounds = true
        tryAgainButton.addTarget(
            self,
            action: #selector(onClickTryAgain),
            for: .touchUpInside
        )
        stackView.addArrangedSubview(tryAgainButton)
        stackView.setCustomSpacing(24, after: titleLabel)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),

            imageView.widthAnchor.constraint(equalToConstant: 85),
            imageView.heightAnchor.constraint(equalToConstant: 85),

            tryAgainButton.widthAnchor.constraint(equalToConstant: 177),
            tryAgainButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    @objc private func onClickTryAgain() {
        AppHaptic.primaryAction()
        onTryAgain?()
    }
}
