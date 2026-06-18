//
//  PremiumReservationShimmerCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

final class PremiumReservationShimmerCell: UITableViewCell {

    private let shimmerView = PremiumReservationShimmerView()

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {

        super.init(
            style: style,
            reuseIdentifier: reuseIdentifier
        )

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {

        selectionStyle = .none

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        shimmerView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(shimmerView)

        NSLayoutConstraint.activate([

            shimmerView.topAnchor.constraint(equalTo: contentView.topAnchor),

            shimmerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),

            shimmerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            shimmerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
