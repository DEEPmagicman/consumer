//
//  PremiumExperienceIntroVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 15/06/26.
//

import UIKit

final class PremiumExperienceIntroVC: UIViewController {

    var onExplore: (() -> Void)?

    private let bgImageView = UIImageView()
    private let blurView = VisualEffectView(effect: UIBlurEffect(style: .dark))
    private let dimView = UIView()
    private let cardView = GradientBorderCardView()

    private let titleLabel = UILabel()
    private let iconImageView = UIImageView()
    private let subtitleLabel = UILabel()
    private let exploreBtn = PrimaryButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cardView.cornerRadius = 28
    }

    private func setupUI() {
        view.backgroundColor = AppColor.primaryBlackColor

        bgImageView.image = UIImage(resource: .premiumExpBg)
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bgImageView)

        cardView.fillColor = AppColor.primaryBlackColor.withAlphaComponent(0.40).cgColor
        cardView.showsBlur = true
        cardView.blurAlpha = 0.6
        cardView.cornerRadius = 28
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        titleLabel.text = "Elevated Access."
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 23)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        iconImageView.image = UIImage(resource: .premiumSEIcon)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconImageView)

        subtitleLabel.text = "Premium bookings, priority reservations, and\nhigh-demand experiences all in one place."
        subtitleLabel.textColor = AppColor.primaryWhiteColor
        subtitleLabel.font = Constant.Font.geistRegular(size: 13)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(subtitleLabel)

        exploreBtn.configure(title: "Explore Premium", fontSize: 17, cornerRadius: 26)
        exploreBtn.addTarget(self, action: #selector(onClickExplore), for: .touchUpInside)
        cardView.addSubview(exploreBtn)

        NSLayoutConstraint.activate([
            bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 21),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -21),
            cardView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            cardView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            cardView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            iconImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60),
            iconImageView.widthAnchor.constraint(equalToConstant: 90),
            iconImageView.heightAnchor.constraint(equalToConstant: 105),

            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            subtitleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 40),

            exploreBtn.topAnchor.constraint(greaterThanOrEqualTo: subtitleLabel.bottomAnchor, constant: 40),
            exploreBtn.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            exploreBtn.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            exploreBtn.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18),
            exploreBtn.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc private func onClickExplore() {
        UserDefault.shared.hasSeenPremiumIntro = true
        onExplore?()
    }
}
