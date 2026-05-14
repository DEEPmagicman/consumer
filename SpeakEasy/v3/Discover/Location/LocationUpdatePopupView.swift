//
//  LocationUpdatePopupView.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 14/05/26.
//

import Foundation
import UIKit

final class LocationUpdatePopupView: UIView {

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "primaryLocationPopupIcon")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = AppColor.primaryWhiteColor
        l.font = Constant.Font.geistRegular(size: 24)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.6)
        l.font = Constant.Font.geistRegular(size: 12)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let confirmButton = PrimaryButton()
    private let cardView = GradientBorderCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)

        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, subtitleLabel, confirmButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(20, after: iconImageView)
        stack.setCustomSpacing(12, after: titleLabel)
        stack.setCustomSpacing(24, after: subtitleLabel)
        cardView.addSubview(stack)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconImageView.widthAnchor.constraint(equalToConstant: 31),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            confirmButton.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            confirmButton.trailingAnchor.constraint(equalTo: stack.trailingAnchor),

            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 32),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24)
        ])
    }

    func configure(
        title: String,
        subtitle: String,
        confirmTitle: String = "Confirm",
        onConfirm: @escaping () -> Void
    ) {
        titleLabel.text    = title
        subtitleLabel.text = subtitle
        confirmButton.configure(title: confirmTitle, cornerRadius: 16)
        confirmButton.addAction(UIAction { _ in onConfirm() }, for: .touchUpInside)
    }
}
