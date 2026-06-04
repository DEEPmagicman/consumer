//
//  SearchVenueCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 03/06/26.
//

import UIKit

final class SearchVenueCell: UITableViewCell {

    private let posterImageView = UIImageView()
    private let nameLabel = UILabel()
    private let typeLabel = UILabel()

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

        nameLabel.textColor = .white
        nameLabel.font = Constant.Font.geistMedium(size: 14)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        typeLabel.text = "Venue"
        typeLabel.textColor = .white.withAlphaComponent(0.55)
        typeLabel.font = Constant.Font.geistRegular(size: 12)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(typeLabel)

        NSLayoutConstraint.activate([
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            posterImageView.widthAnchor.constraint(equalToConstant: 44),
            posterImageView.heightAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: posterImageView.topAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            typeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            typeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            typeLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            contentView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    func configure(_ item: SearchVenueItem) {
        nameLabel.text = item.name

        if let imageURL = item.imageURL, let url = URL(string: imageURL) {
            posterImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        } else {
            posterImageView.image = UIImage(named: "placeholder")
        }
    }
}
