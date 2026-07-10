//
//  VenueGridCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 29/05/26.
//

import UIKit

final class VenueGridCell: UICollectionViewCell {

    private let imageView = UIImageView()
    private let logoView = UIImageView()
    private let overlayView = UIView()
    private let venueNameBadgeContainerView = UIView()
    private let venueNameBlurView = VisualEffectView(effect: UIBlurEffect(style: .light))
    private let venueNameTintView = UIView()
    private let venueNameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.sd_cancelCurrentImageLoad()
        logoView.sd_cancelCurrentImageLoad()

        imageView.image = nil
        logoView.image = nil
        venueNameLabel.attributedText = nil
        venueNameBadgeContainerView.isHidden = true
    }

    private func setupUI() {

        backgroundColor = .clear

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(imageView)

        overlayView.backgroundColor =
            UIColor.black.withAlphaComponent(0.28)

        overlayView.isUserInteractionEnabled = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        imageView.addSubview(overlayView)
        
        logoView.contentMode = .scaleAspectFit
        logoView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(logoView)
        imageView.bringSubviewToFront(logoView)

        venueNameBadgeContainerView.backgroundColor = .clear
        venueNameBadgeContainerView.clipsToBounds = true
        venueNameBadgeContainerView.layer.masksToBounds = true
        venueNameBadgeContainerView.isUserInteractionEnabled = false
        venueNameBadgeContainerView.translatesAutoresizingMaskIntoConstraints = false
        venueNameBadgeContainerView.isHidden = true
        venueNameBadgeContainerView.layer.cornerRadius = 10

        venueNameBlurView.blurRadius = 28
        venueNameBlurView.colorTint = UIColor(hex: "#FFF2F2")
        venueNameBlurView.colorTintAlpha = 0.14
        venueNameBlurView.translatesAutoresizingMaskIntoConstraints = false

        venueNameTintView.backgroundColor =
            UIColor(hex: "#FFF2F2").withAlphaComponent(0.14)
        venueNameTintView.translatesAutoresizingMaskIntoConstraints = false

        venueNameLabel.font = Constant.Font.geistRegular(size: 11)
        venueNameLabel.textColor = .white
        venueNameLabel.numberOfLines = 1
        venueNameLabel.lineBreakMode = .byTruncatingTail
        venueNameLabel.translatesAutoresizingMaskIntoConstraints = false

        imageView.addSubview(venueNameBadgeContainerView)
        venueNameBadgeContainerView.addSubview(venueNameBlurView)
        venueNameBadgeContainerView.addSubview(venueNameTintView)
        venueNameBadgeContainerView.addSubview(venueNameLabel)
        imageView.bringSubviewToFront(venueNameBadgeContainerView)
        
        NSLayoutConstraint.activate([

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            
            logoView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),

            logoView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.55),
            logoView.heightAnchor.constraint(equalToConstant: 90),

            venueNameBadgeContainerView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 15),
            venueNameBadgeContainerView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -11),
            venueNameBadgeContainerView.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -15),
            venueNameBadgeContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 21),

            venueNameBlurView.topAnchor.constraint(equalTo: venueNameBadgeContainerView.topAnchor),
            venueNameBlurView.leadingAnchor.constraint(equalTo: venueNameBadgeContainerView.leadingAnchor),
            venueNameBlurView.trailingAnchor.constraint(equalTo: venueNameBadgeContainerView.trailingAnchor),
            venueNameBlurView.bottomAnchor.constraint(equalTo: venueNameBadgeContainerView.bottomAnchor),

            venueNameTintView.topAnchor.constraint(equalTo: venueNameBadgeContainerView.topAnchor),
            venueNameTintView.leadingAnchor.constraint(equalTo: venueNameBadgeContainerView.leadingAnchor),
            venueNameTintView.trailingAnchor.constraint(equalTo: venueNameBadgeContainerView.trailingAnchor),
            venueNameTintView.bottomAnchor.constraint(equalTo: venueNameBadgeContainerView.bottomAnchor),

            venueNameLabel.topAnchor.constraint(equalTo: venueNameBadgeContainerView.topAnchor, constant: 3),
            venueNameLabel.leadingAnchor.constraint(equalTo: venueNameBadgeContainerView.leadingAnchor, constant: 12),
            venueNameLabel.trailingAnchor.constraint(equalTo: venueNameBadgeContainerView.trailingAnchor, constant: -12),
            venueNameLabel.bottomAnchor.constraint(equalTo: venueNameBadgeContainerView.bottomAnchor, constant: -3)
        ])
    }

//    override func layoutSubviews() {
//        super.layoutSubviews()
//
//        venueNameBadgeContainerView.layer.cornerRadius =
//        venueNameBadgeContainerView.bounds.height / 2
//    }

    func configure(_ venue: ClipVenue) {

        let imageKey =
        venue.venueAttachment?.first?.key ??
        venue.logo?.key ??
        ""

        imageView.sd_setImage(
            with: URL(
                string:
                "\(SharedURL.amazonStorage)\(imageKey)"
            ),
            placeholderImage: UIImage(named: "newSpeakeasy")
        )

        logoView.sd_setImage(
            with: URL(
                string:
                "\(SharedURL.amazonStorage)\(venue.logo?.key ?? "")"
            )
        )

        setVenueName(venue.name)
    }

    private func setVenueName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        venueNameBadgeContainerView.isHidden = trimmedName.isEmpty
        venueNameLabel.attributedText = NSAttributedString(
            string: trimmedName,
            attributes: [
                .font: Constant.Font.geistRegular(size: 11),
                .foregroundColor: UIColor.white,
                .kern: -0.22
            ]
        )
    }
}
