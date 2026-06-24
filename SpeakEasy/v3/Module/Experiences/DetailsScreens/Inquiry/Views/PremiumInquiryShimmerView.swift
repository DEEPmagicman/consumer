//
//  PremiumInquiryShimmerView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 19/06/26.
//

import UIKit

final class PremiumInquiryShimmerView: UIView {

    private let card = GradientBorderCardView()

    private let title = ShimmerViewV3()

    private let field1 = ShimmerViewV3()

    private let field2 = ShimmerViewV3()

    private let field3 = ShimmerViewV3()

    private let comment = ShimmerViewV3()

    private let checkbox = ShimmerViewV3()

    private let button = ShimmerViewV3(frame: .zero, lighter: true)

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        card.glassCornerRadius = 22
    }
}

private extension PremiumInquiryShimmerView {

    func setupUI() {

        backgroundColor = .clear

        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = AppColor.primaryWhiteColor
            .withAlphaComponent(0.05)
            .cgColor
        card.showsBlur = true
        card.blurAlpha = 0.60

        addSubview(card)

        [
            title,
            field1,
            field2,
            field3,
            comment,
            checkbox,
            button
        ].forEach {

            $0.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview($0)
        }

        title.cornerRadius = 8
        field1.cornerRadius = 8
        field2.cornerRadius = 8
        field3.cornerRadius = 8
        comment.cornerRadius = 8
        checkbox.cornerRadius = 6
        button.cornerRadius = 16

        setupConstraints()

        startShimmer()
    }
}

private extension PremiumInquiryShimmerView {

    func setupConstraints() {

        NSLayoutConstraint.activate([

            card.topAnchor.constraint(equalTo: topAnchor),

            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            card.bottomAnchor.constraint(equalTo: bottomAnchor),

            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),

            title.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            title.widthAnchor.constraint(equalToConstant: 120),

            title.heightAnchor.constraint(equalToConstant: 18),

            field1.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 22),

            field1.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),

            field1.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),

            field1.heightAnchor.constraint(equalToConstant: 48),

            field2.topAnchor.constraint(equalTo: field1.bottomAnchor, constant: 12),

            field2.leadingAnchor.constraint(equalTo: field1.leadingAnchor),

            field2.trailingAnchor.constraint(equalTo: field1.trailingAnchor),

            field2.heightAnchor.constraint(equalToConstant: 48),

            field3.topAnchor.constraint(equalTo: field2.bottomAnchor, constant: 12),

            field3.leadingAnchor.constraint(equalTo: field1.leadingAnchor),

            field3.trailingAnchor.constraint(equalTo: field1.trailingAnchor),

            field3.heightAnchor.constraint(equalToConstant: 48),

            comment.topAnchor.constraint(equalTo: field3.bottomAnchor, constant: 12),

            comment.leadingAnchor.constraint(equalTo: field1.leadingAnchor),

            comment.trailingAnchor.constraint(equalTo: field1.trailingAnchor),

            comment.heightAnchor.constraint(equalToConstant: 90),

            checkbox.topAnchor.constraint(equalTo: comment.bottomAnchor, constant: 18),

            checkbox.leadingAnchor.constraint(equalTo: field1.leadingAnchor),

            checkbox.widthAnchor.constraint(equalToConstant: 170),

            checkbox.heightAnchor.constraint(equalToConstant: 16),

            button.topAnchor.constraint(equalTo: checkbox.bottomAnchor, constant: 24),

            button.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            button.widthAnchor.constraint(equalToConstant: 150),

            button.heightAnchor.constraint(equalToConstant: 42),

            button.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22)
        ])
    }
}

private extension PremiumInquiryShimmerView {

    func startShimmer() {

        [
            title,
            field1,
            field2,
            field3,
            comment,
            checkbox,
            button
        ].forEach {

            $0.startShimmer()
        }
    }

    func stopShimmer() {

        [
            title,
            field1,
            field2,
            field3,
            comment,
            checkbox,
            button
        ].forEach {

            $0.stopShimmer()
        }
    }

    internal override func willMove(toWindow newWindow: UIWindow?) {

        super.willMove(toWindow: newWindow)

        if newWindow == nil {

            stopShimmer()

        } else {

            startShimmer()
        }
    }
}
