//
//  PremiumReservationShimmerView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

final class PremiumReservationShimmerView: UIView {

    private let card = GradientBorderCardView()

    private let title = ShimmerViewV3()

    private let guest = ShimmerViewV3(frame: .zero, lighter: true)

    private let time = ShimmerViewV3(frame: .zero, lighter: true)

    private let line1 = ShimmerViewV3()

    private let line2 = ShimmerViewV3()

    private let price = ShimmerViewV3()

    private let minimum = ShimmerViewV3()

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

        card.glassCornerRadius = 20
    }

    override func willMove(toWindow newWindow: UIWindow?) {

        super.willMove(toWindow: newWindow)

        if newWindow == nil {

            stopShimmer()

        } else {

            startShimmer()
        }
    }
}

private extension PremiumReservationShimmerView {

    func setupUI() {

        backgroundColor = .clear

        title.cornerRadius = 8
        guest.cornerRadius = 6
        time.cornerRadius = 6
        line1.cornerRadius = 6
        line2.cornerRadius = 6
        price.cornerRadius = 7
        minimum.cornerRadius = 6
        button.cornerRadius = 14

        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = AppColor.primaryWhiteColor
            .withAlphaComponent(0.05)
            .cgColor
        card.showsBlur = true
        card.blurAlpha = 0.60

        addSubview(card)

        [
            title,
            guest,
            time,
            line1,
            line2,
            price,
            minimum,
            button
        ].forEach {

            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        setupConstraints()

        startShimmer()
    }
}

private extension PremiumReservationShimmerView {

    func setupConstraints() {

        NSLayoutConstraint.activate([

            card.topAnchor.constraint(equalTo: topAnchor, constant: 8),

            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            card.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            title.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.58),
            title.heightAnchor.constraint(equalToConstant: 18),

            guest.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            guest.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            guest.widthAnchor.constraint(equalToConstant: 60),
            guest.heightAnchor.constraint(equalToConstant: 14),

            time.centerYAnchor.constraint(equalTo: guest.centerYAnchor),
            time.leadingAnchor.constraint(equalTo: guest.trailingAnchor, constant: 8),
            time.widthAnchor.constraint(equalToConstant: 60),
            time.heightAnchor.constraint(equalToConstant: 14),

            line1.topAnchor.constraint(equalTo: guest.bottomAnchor, constant: 14),
            line1.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            line1.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            line1.heightAnchor.constraint(equalToConstant: 12),

            line2.topAnchor.constraint(equalTo: line1.bottomAnchor, constant: 8),
            line2.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            line2.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.62),
            line2.heightAnchor.constraint(equalToConstant: 12),

            price.topAnchor.constraint(equalTo: line2.bottomAnchor, constant: 18),
            price.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            price.widthAnchor.constraint(equalToConstant: 80),
            price.heightAnchor.constraint(equalToConstant: 18),

            minimum.topAnchor.constraint(equalTo: price.bottomAnchor, constant: 6),
            minimum.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            minimum.widthAnchor.constraint(equalToConstant: 120),
            minimum.heightAnchor.constraint(equalToConstant: 12),

            button.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            button.centerYAnchor.constraint(equalTo: price.centerYAnchor, constant: 6),
            button.widthAnchor.constraint(equalToConstant: 94),
            button.heightAnchor.constraint(equalToConstant: 36),

            minimum.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
    }
}

private extension PremiumReservationShimmerView {

    func startShimmer() {

        [
            title,
            guest,
            time,
            line1,
            line2,
            price,
            minimum,
            button
        ].forEach {

            $0.startShimmer()
        }
    }

    func stopShimmer() {

        [
            title,
            guest,
            time,
            line1,
            line2,
            price,
            minimum,
            button
        ].forEach {

            $0.stopShimmer()
        }
    }

}
