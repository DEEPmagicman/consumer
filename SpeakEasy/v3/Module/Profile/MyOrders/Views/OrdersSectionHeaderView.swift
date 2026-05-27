//
//  OrdersSectionHeaderView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 27/05/26.
//


import UIKit

final class OrdersSectionHeaderView: UICollectionReusableView {

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistRegular(size: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
