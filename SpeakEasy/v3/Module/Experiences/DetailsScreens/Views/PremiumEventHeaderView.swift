//
//  PremiumEventHeaderViewDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

protocol PremiumEventHeaderViewDelegate: AnyObject {
    func premiumEventHeaderDidTapBack(_ view: PremiumEventHeaderView)
}

final class PremiumEventHeaderView: UIView {

    weak var delegate: PremiumEventHeaderViewDelegate?

    // MARK: UI

    private let backButton = AppIconButton()

    private let titleLabel = PremiumMarqueeLabel()

    private let venueLabel = UILabel()

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }
}

private extension PremiumEventHeaderView {

    func setup() {

        translatesAutoresizingMaskIntoConstraints = false

        setupBackButton()

        setupTitle()

        setupVenue()

        setupConstraints()
    }
}

private extension PremiumEventHeaderView {

    func setupBackButton() {
        backButton.iconTypeValue = AppIconType.leftSideBack.rawValue
        backButton.iconSize = 14
        backButton.buttonSize = 40
        backButton.iconTintColor = .white
        backButton.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backButton)
    }
    
    func setupTitle() {

        titleLabel.font = Constant.Font.geistMedium(size: 20)
        titleLabel.textColor = .white
        titleLabel.animationSpeed = 25
        titleLabel.animationDelay = 1.5
        titleLabel.setText("er")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
    }
}

private extension PremiumEventHeaderView {

    func setupVenue() {

        venueLabel.textColor = AppColor.primaryWhiteColor

        venueLabel.font = Constant.Font.geistMedium(size: 12)

        venueLabel.alpha = 0.95
        venueLabel.lineBreakMode = .byTruncatingTail
        venueLabel.textAlignment = .center

        venueLabel.numberOfLines = 1

        venueLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(venueLabel)
    }
}

private extension PremiumEventHeaderView {

    func setupConstraints() {

        NSLayoutConstraint.activate([

            heightAnchor.constraint(equalToConstant: 52),

            // Back Button

            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: topAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            // Title
            titleLabel.heightAnchor.constraint(equalToConstant: 26),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 26),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -56),
            
            // Venue

            venueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            venueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),

            venueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -60)
        ])
    }
}

extension PremiumEventHeaderView {

    func configure(title: String, venue: String) {

        titleLabel.setText(title)

        venueLabel.text = venue.uppercased()
    }
}

private extension PremiumEventHeaderView {

    @objc
    func onClickBack() {

        delegate?.premiumEventHeaderDidTapBack(self)
    }
}
