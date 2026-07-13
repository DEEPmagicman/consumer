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
            return "No venues saved"
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
            return "No premium events yet"
        }
    }

    var imageName: String {
        switch self {
        case .savedEvents:
            return "savedEmptyIcon"
        case .venues:
            return "venueEmptyIcon"
        case .tickets, .events, .venueEvents, .premiumEvents:
            return "ticketsEmptyIcon"
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
        case .venues:
            return CGSize(width: 80, height: 80)
        case .tickets, .reservations, .events, .venueEvents, .premiumEvents:
            return CGSize(width: 60, height: 60)
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
        browseEventsButton.setTitle("Browse events", for: .normal)
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

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),

            imageWidthConstraint!,
            imageHeightConstraint!
        ])
    }

    @objc private func onClickBrowseEvents() {
        onBrowseEvents?()
    }
}
