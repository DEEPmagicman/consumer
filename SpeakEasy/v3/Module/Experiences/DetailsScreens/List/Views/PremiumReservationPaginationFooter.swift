//
//  PremiumReservationPaginationFooter.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

final class PremiumReservationPaginationFooter: UITableViewHeaderFooterView {

    private let firstCard = PremiumReservationShimmerView()
    private let secondCard = PremiumReservationShimmerView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {

        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear

        contentView.backgroundColor = .clear

        firstCard.translatesAutoresizingMaskIntoConstraints = false
        secondCard.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(firstCard)
        contentView.addSubview(secondCard)

        NSLayoutConstraint.activate([

            firstCard.topAnchor.constraint(
                equalTo: contentView.topAnchor
            ),

            firstCard.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),

            firstCard.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),

            secondCard.topAnchor.constraint(
                equalTo: firstCard.bottomAnchor,
                constant: 8
            ),

            secondCard.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),

            secondCard.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),

            secondCard.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            )
        ])
    }
}
