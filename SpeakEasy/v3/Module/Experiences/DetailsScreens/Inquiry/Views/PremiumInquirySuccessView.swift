//
//  PremiumInquirySuccessView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 19/06/26.
//

import UIKit

final class PremiumInquirySuccessView: UIView {

    private let descriptionLabel = UILabel()
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
}

private extension PremiumInquirySuccessView {

    func setupUI() {

        backgroundColor = .clear

        descriptionLabel.text =
            "Please complete the form to submit your request and a VIP Services Host will contact you. This request form is not a table reservation confirmation and does not guarantee entry."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font          = Constant.Font.geistRegular(size: 12)
        descriptionLabel.textColor     = .white.withAlphaComponent(0.88)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(descriptionLabel)

        // MARK: Card
        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = AppColor.primaryWhiteColor
            .withAlphaComponent(0.05)
            .cgColor
        card.showsBlur = true
        card.blurAlpha = 0.60
        addSubview(card)

        // MARK: Icon — chat bubble with checkmark
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .thin)
        iconImageView.image       = UIImage(systemName: "checkmark.message", withConfiguration: config)
        iconImageView.tintColor   = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconImageView)

        // MARK: Title
        titleLabel.text          = "We've received your request"
        titleLabel.font          = Constant.Font.geistMedium(size: 20)
        titleLabel.textColor     = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        // MARK: Desc
        descLabel.text          = "We'll be in touch soon"
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .center
        descLabel.font          = Constant.Font.geistRegular(size: 16)
        descLabel.textColor     = UIColor.white.withAlphaComponent(0.9)
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(descLabel)

        NSLayoutConstraint.activate([

            // Description label at top — same insets as form
            descriptionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),

            // Card below description
            card.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            card.heightAnchor.constraint(equalToConstant: 280),

            // Icon centered, upper portion of card
            iconImageView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: -30),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),

            // Title below icon
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),

            // Desc below title
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            descLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24)
        ])
    }
}
