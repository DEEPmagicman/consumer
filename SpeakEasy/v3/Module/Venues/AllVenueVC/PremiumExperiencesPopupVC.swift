//
//  PremiumExperiencesPopupVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 01/06/26.
//

import UIKit

final class PremiumExperiencesPopupVC: UIViewController {

    // MARK: - Callbacks

    var onDismiss: (() -> Void)?

    // MARK: - UI

    private let dimmedView = UIView()
    private let popupView = GradientBorderCardView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let dismissButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        animateIn()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .clear

        // Dimmed background
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        dimmedView.alpha = 0
        view.addSubview(dimmedView)

        let dimTap = UITapGestureRecognizer(target: self, action: #selector(handleDismiss))
        dimmedView.addGestureRecognizer(dimTap)

        // Popup card
        popupView.translatesAutoresizingMaskIntoConstraints = false
        popupView.backgroundColor = UIColor(hex: "#171717")
        popupView.layer.cornerRadius = 34
        popupView.layer.cornerCurve = .continuous
        popupView.clipsToBounds = true
        popupView.alpha = 0
        view.addSubview(popupView)

        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = UIImage(named: "premiumExperienceIcon")
        popupView.addSubview(iconImageView)

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "How Premium\nExperiences work"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistMedium(size: 24)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        popupView.addSubview(titleLabel)

        // Description
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.0
        paragraphStyle.alignment = .center

        let kern = -0.01 * 12.0

        let attributedDesc = NSAttributedString(
            string: "Your direct connection to the world's most coveted live experiences. Secure access, reservations, and curated packages in seconds. By directly powering the live experience economy's top global brands, we eliminate third-party friction and grant you unparalleled access to extraordinary moments.",
            attributes: [
                .font: Constant.Font.geistRegular(size: 12),
                .foregroundColor: UIColor.white.withAlphaComponent(0.75),
                .paragraphStyle: paragraphStyle,
                .kern: kern
            ]
        )

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.attributedText = attributedDesc
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        popupView.addSubview(descriptionLabel)

        // Divider
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        popupView.addSubview(divider)

        // Dismiss button
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.backgroundColor = .white
        dismissButton.layer.cornerRadius = 28
        dismissButton.layer.cornerCurve = .continuous
        dismissButton.clipsToBounds = true

        let kern2 = -0.01 * 17.0
        let dismissTitle = NSAttributedString(
            string: "Dismiss",
            attributes: [
                .font: Constant.Font.geistMedium(size: 17),
                .foregroundColor: UIColor.black,
                .kern: kern2
            ]
        )
        dismissButton.setAttributedTitle(dismissTitle, for: .normal)
        dismissButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        popupView.addSubview(dismissButton)

        // MARK: - Constraints

        NSLayoutConstraint.activate([

            // Dimmed
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Popup — centered
            popupView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            popupView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Icon
            iconImageView.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 36),
            iconImageView.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 50),
            iconImageView.heightAnchor.constraint(equalToConstant: 50),

            // Title
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -24),

            // Description
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -24),

            // Dismiss button
            dismissButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 27),
            dismissButton.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 12),
            dismissButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -12),
            dismissButton.heightAnchor.constraint(equalToConstant: 56),
            dismissButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Animation

    private func animateIn() {
        popupView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.4,
            options: .curveEaseOut
        ) {
            self.dimmedView.alpha = 1
            self.popupView.alpha = 1
            self.popupView.transform = .identity
        }
    }

    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.dimmedView.alpha = 0
                self.popupView.alpha = 0
                self.popupView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            }
        ) { _ in
            completion?()
        }
    }

    // MARK: - Actions

    @objc private func handleDismiss() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
            self?.onDismiss?()
        }
    }
}

// MARK: - Present Helper

extension PremiumExperiencesPopupVC {

    static func show(from viewController: UIViewController, onDismiss: (() -> Void)? = nil) {
        let popup = PremiumExperiencesPopupVC()
        popup.onDismiss = onDismiss
        popup.modalPresentationStyle = .overFullScreen
        popup.modalTransitionStyle = .crossDissolve
        viewController.present(popup, animated: false)
    }
}
