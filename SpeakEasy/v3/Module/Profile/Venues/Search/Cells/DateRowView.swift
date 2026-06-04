//
//  SearchVenueItem.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 03/06/26.
//

import UIKit
import SDWebImage

// MARK: - Models

struct SearchVenueItem {
    let id: String
    let name: String
    let imageURL: String?
}

struct SearchEventItem {
    let id: String
    let title: String
    let dateText: String
    let imageURL: String?
}

// MARK: - Service

final class DateRowView: UIControl {

    private let iconBox = UIView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let arrowImageView = UIImageView()

    var value: String = "Add date" {
        didSet {
            valueLabel.text = value
        }
    }

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.06)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        iconBox.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.07)
        iconBox.layer.cornerRadius = 10
        iconBox.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconBox)

        let icon = UIImageView(image: UIImage(systemName: "calendar"))
        icon.tintColor = .white.withAlphaComponent(0.75)
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBox.addSubview(icon)

        titleLabel.textColor = .white.withAlphaComponent(0.35)
        titleLabel.font = Constant.Font.geistRegular(size: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        valueLabel.text = value
        valueLabel.textColor = .white
        valueLabel.font = Constant.Font.geistRegular(size: 16)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)

        arrowImageView.image = UIImage(systemName: "chevron.down")
        arrowImageView.tintColor = .white.withAlphaComponent(0.4)
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(arrowImageView)

        NSLayoutConstraint.activate([
            iconBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconBox.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconBox.widthAnchor.constraint(equalToConstant: 44),
            iconBox.heightAnchor.constraint(equalToConstant: 44),

            icon.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.leadingAnchor.constraint(equalTo: iconBox.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),

            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 14),
            arrowImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
}

// MARK: - Date Helpers

extension Date {

    func shortDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: self)
    }

    func dateFilterDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: self)
    }
}

