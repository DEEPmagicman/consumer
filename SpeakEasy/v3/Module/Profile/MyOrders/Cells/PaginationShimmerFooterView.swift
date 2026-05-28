//
//  PaginationShimmerFooterView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class PaginationShimmerFooterView:
UICollectionReusableView {

    private let leftCard =
        OrderCardShimmerContentView()

    private let rightCard =
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

        [
            leftCard,
            rightCard
        ].forEach {

            $0.translatesAutoresizingMaskIntoConstraints =
                false

            addSubview($0)
        }

        NSLayoutConstraint.activate([

            // LEFT

            leftCard.topAnchor.constraint(
                equalTo: topAnchor
            ),

            leftCard.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 24
            ),

            leftCard.widthAnchor.constraint(
                equalToConstant: 160
            ),

            // RIGHT

            rightCard.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 40
            ),

            rightCard.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -24
            ),

            rightCard.widthAnchor.constraint(
                equalToConstant: 160
            ),

            rightCard.bottomAnchor.constraint(
                equalTo: bottomAnchor
            )
        ])
    }
}
