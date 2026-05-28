//
//  OrderCardShimmerCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class OrderCardShimmerCell:
UICollectionViewCell {
    
    private let shimmerView =
        OrderCardShimmerContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {

        backgroundColor = .clear

        shimmerView.translatesAutoresizingMaskIntoConstraints =
            false

        contentView.addSubview(
            shimmerView
        )

        NSLayoutConstraint.activate([

            shimmerView.topAnchor.constraint(
                equalTo: contentView.topAnchor
            ),

            shimmerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),

            shimmerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),

            shimmerView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            )
        ])
    }
}
