//
//  GuestListPopupCell.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 24/03/26.
//

import Foundation
import UIKit
import SDWebImage

final class GuestListPopupCell: UITableViewCell {


    var onInstagramTap: (() -> Void)?

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let instagramButton = UIButton(type: .system)
    private let separatorView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        nameLabel.text = nil
        instagramButton.isHidden = true
        onInstagramTap = nil
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.backgroundColor = UIColor.white.withAlphaComponent(0.08)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .white
        nameLabel.font = Constant.Font.interMedium(size: 16)
        nameLabel.numberOfLines = 1

        instagramButton.translatesAutoresizingMaskIntoConstraints = false
        instagramButton.tintColor = .white
        instagramButton.setImage(UIImage(named: "ic-Insta") ?? UIImage(systemName: "camera"), for: .normal)
        instagramButton.addTarget(self, action: #selector(handleInstagramTap), for: .touchUpInside)

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = UIColor.white.withAlphaComponent(0.08)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(instagramButton)
        contentView.addSubview(separatorView)

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 14),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: instagramButton.leadingAnchor, constant: -12),

            instagramButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            instagramButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            instagramButton.widthAnchor.constraint(equalToConstant: 24),
            instagramButton.heightAnchor.constraint(equalToConstant: 24),

            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    func configure(with attendee: Attendee, isLast: Bool) {
        let displayName = attendee.fullName.isEmpty ? "Unknown User" : attendee.fullName
        nameLabel.text = displayName
        
        if let imageUrl = attendee.consumerUserImage?.key,
           let url = URL(string: imageUrl) {
            avatarImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "user_placeholder"))
        } else {
            avatarImageView.isHidden = true
//              bgView.isHidden = false
//              attendeesName.isHidden = false
//              attendeesName.text = getInitials(from: attendee)
//              bgView.applyGradient(id: attendee.id ?? UUID().uuidString)
        }
        
        let instaId = attendee.instagramUserId?
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        instagramButton.isHidden = instaId.isEmpty
        separatorView.isHidden = isLast
    }

    @objc private func handleInstagramTap() {
        onInstagramTap?()
    }
}



