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
    private let avatarFallbackView = UIView()
    private let initialsLabel = UILabel()
    private let nameLabel = UILabel()
    private let instagramButton = UIButton(type: .system)
    private let separatorView = UIView()
    private var gradientLayer: CAGradientLayer?

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
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        avatarImageView.sd_cancelCurrentImageLoad()
        avatarImageView.image = nil
        avatarImageView.isHidden = false
        avatarFallbackView.isHidden = true
        initialsLabel.text = nil
        nameLabel.text = nil
        instagramButton.isHidden = true
        onInstagramTap = nil
    }

    deinit {
        gradientLayer?.removeFromSuperlayer()
        avatarImageView.sd_cancelCurrentImageLoad()
        onInstagramTap = nil
        instagramButton.removeTarget(nil, action: nil, for: .allEvents)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = avatarFallbackView.bounds
        gradientLayer?.cornerRadius = avatarFallbackView.bounds.height / 2
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

        avatarFallbackView.translatesAutoresizingMaskIntoConstraints = false
        avatarFallbackView.clipsToBounds = true
        avatarFallbackView.layer.cornerRadius = 22
        avatarFallbackView.isHidden = true

        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.textAlignment = .center
        initialsLabel.textColor = .black
        initialsLabel.font = Constant.Font.interMedium(size: 14)

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

        avatarFallbackView.addSubview(initialsLabel)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(avatarFallbackView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(instagramButton)
        contentView.addSubview(separatorView)

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44),

            avatarFallbackView.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            avatarFallbackView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            avatarFallbackView.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            avatarFallbackView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),

            initialsLabel.centerXAnchor.constraint(equalTo: avatarFallbackView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarFallbackView.centerYAnchor),

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
           !imageUrl.isEmpty,
           let url = URL(string: imageUrl) {

            showImageAvatar()
            avatarImageView.sd_setImage(with: url) { [weak self] image, _, _, _ in
                guard let self else { return }

                if image == nil {
                    self.showInitialsAvatar(for: attendee)
                }
            }
        } else {
            showInitialsAvatar(for: attendee)
        }
        
        let instaId = attendee.instagramUserId?
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        instagramButton.isHidden = instaId.isEmpty
        separatorView.isHidden = isLast
    }

    private func getInitials(from attendee: Attendee) -> String {
        let first = attendee.firstName?.prefix(1).uppercased() ?? ""
        let last = attendee.lastName?.prefix(1).uppercased() ?? ""
        let initials = first + last

        if !initials.isEmpty {
            return initials
        }

        return attendee.fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first?.uppercased() }
            .joined()
    }

    private func showImageAvatar() {
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        avatarImageView.isHidden = false
        avatarFallbackView.isHidden = true
    }

    private func showInitialsAvatar(for attendee: Attendee) {
        avatarImageView.sd_cancelCurrentImageLoad()
        avatarImageView.image = nil
        avatarImageView.isHidden = true
        avatarFallbackView.isHidden = false
        initialsLabel.text = getInitials(from: attendee)
        applyGradient(for: attendee.id ?? attendee.fullName)
    }

    private func applyGradient(for id: String) {
        gradientLayer?.removeFromSuperlayer()

        let colors = gradientColors(for: id)
        let gradient = CAGradientLayer()
        gradient.frame = avatarFallbackView.bounds
        gradient.cornerRadius = avatarFallbackView.bounds.height / 2
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)

        avatarFallbackView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }

    private func gradientColors(for id: String) -> [UIColor] {
        let palettes: [[UIColor]] = [
            [UIColor(hex: "#f9d423"), UIColor(hex: "#ff4e50")],
            [UIColor(hex: "#a1ffce"), UIColor(hex: "#faffd1")],
            [UIColor(hex: "#fbc2eb"), UIColor(hex: "#a6c1ee")],
            [UIColor(hex: "#fad0c4"), UIColor(hex: "#ffd1ff")],
            [UIColor(hex: "#89f7fe"), UIColor(hex: "#66a6ff")],
            [UIColor(hex: "#fbc2eb"), UIColor(hex: "#f9d423")],
            [UIColor(hex: "#ffecd2"), UIColor(hex: "#fcb69f")],
            [UIColor(hex: "#a18cd1"), UIColor(hex: "#fbc2eb")]
        ]

        let index = abs(id.hashValue) % palettes.count
        return palettes[index]
    }

    @objc private func handleInstagramTap() {
        onInstagramTap?()
    }
}
