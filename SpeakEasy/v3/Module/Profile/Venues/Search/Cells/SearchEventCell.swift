//
//  SearchEventCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 03/06/26.
//

import UIKit

final class SearchEventCell: UITableViewCell {

    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        posterImageView.layer.cornerRadius = 6
        posterImageView.clipsToBounds = true
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(posterImageView)

        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistMedium(size: 14)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        dateLabel.textColor = .white.withAlphaComponent(0.65)
        dateLabel.font = Constant.Font.geistRegular(size: 12)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            posterImageView.widthAnchor.constraint(equalToConstant: 48),
            posterImageView.heightAnchor.constraint(equalToConstant: 48),

            titleLabel.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: posterImageView.topAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            contentView.heightAnchor.constraint(equalToConstant: 64)
        ])
    }

    func configure(_ item: SearchEventItem) {
        titleLabel.text = item.title
        dateLabel.text = item.dateText

        if let imageURL = item.imageURL, let url = URL(string: imageURL) {
            posterImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        } else {
            posterImageView.image = UIImage(named: "placeholder")
        }
    }
}
