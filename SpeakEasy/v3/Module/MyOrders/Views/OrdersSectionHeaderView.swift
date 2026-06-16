//
//  OrdersSectionHeaderView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class OrdersSectionHeaderView:
UICollectionReusableView {

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {

        backgroundColor = .clear

        titleLabel.textColor = .white

        titleLabel.font =
            Constant.Font.geistMedium(size: 20)

        titleLabel.translatesAutoresizingMaskIntoConstraints =
            false

        addSubview(titleLabel)

        NSLayoutConstraint.activate([

            titleLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 24
            ),

            titleLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -24
            ),

            titleLabel.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -6
            )
        ])
    }

    func configure(
        text: String,
        isEmpty: Bool = false
    ) {

        titleLabel.text = text

        if isEmpty {

            titleLabel.font =
                Constant.Font.geistRegular(size: 17)

            titleLabel.textColor =
                UIColor.white.withAlphaComponent(0.8)

        } else {

            titleLabel.font =
                Constant.Font.geistMedium(size: 20)

            titleLabel.textColor = .white
        }
    }
}
