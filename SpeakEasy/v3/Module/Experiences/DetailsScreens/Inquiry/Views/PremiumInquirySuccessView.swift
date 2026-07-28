//
//  PremiumInquirySuccessView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 19/06/26.
//

import UIKit

final class PremiumInquirySuccessView: UIView {

    private let card             = GradientBorderCardView()
    private let iconImageView    = UIImageView()
    private let titleLabel       = UILabel()
    private let descLabel        = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        card.glassCornerRadius = 28
    }

    func configure(name: String, email: String, venueName: String) {
        let displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailText = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let venueText = venueName.trimmingCharacters(in: .whitespacesAndNewlines)
        let namePrefix = displayName.isEmpty ? "" : "\(displayName), "
        let emailLine = emailText.isEmpty
            ? "a confirmation email has been sent."
            : "a confirmation email has been sent to \(emailText)."
        let venueLine = venueText.isEmpty
            ? "Someone will be in touch with you."
            : "Someone from \(venueText) will be in touch with you."
        descLabel.text = "\(namePrefix)\(emailLine)\n\(venueLine)"
    }
}

private extension PremiumInquirySuccessView {

    func setupUI() {

        backgroundColor = .clear

        // MARK: Card
        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = AppColor.primaryWhiteColor
            .withAlphaComponent(0.05)
            .cgColor
        card.showsBlur = true
        card.blurAlpha = 0.60
        addSubview(card)

        // MARK: Icon — chat bubble with checkmark
        iconImageView.image       = UIImage(named: "requestSentIcon")
        iconImageView.tintColor   = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconImageView)

        // MARK: Title
        titleLabel.text          = "We've received your request."
        titleLabel.font          = Constant.Font.geistRegular(size: 18)
        titleLabel.textColor     = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        // MARK: Desc
        descLabel.text          = ""
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .center
        descLabel.font          = Constant.Font.geistRegular(size: 12)
        descLabel.textColor     = UIColor.white.withAlphaComponent(0.5)
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(descLabel)

        NSLayoutConstraint.activate([

            card.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -42),
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            card.heightAnchor.constraint(equalTo: card.widthAnchor),

            // Icon centered, upper portion of card
            iconImageView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: card.topAnchor, constant: 94),
            iconImageView.widthAnchor.constraint(equalToConstant: 65),
            iconImageView.heightAnchor.constraint(equalToConstant: 65),

            // Title below icon
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),

            // Desc below title
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            descLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24)
        ])
    }
}
