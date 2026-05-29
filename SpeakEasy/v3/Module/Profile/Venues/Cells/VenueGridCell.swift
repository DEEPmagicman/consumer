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
            logoView.heightAnchor.constraint(equalToConstant: 90)
        ])
    }

    func configure(_ venue: ClipVenue) {

        imageView.sd_setImage(
            with: URL(
                string:
                "\(SharedURL.amazonStorage)\(venue.venueAttachment?.first?.key ?? "")"
            ),
            placeholderImage: UIImage(named: "newSpeakeasy")
        )

        logoView.sd_setImage(
            with: URL(
                string:
                "\(SharedURL.amazonStorage)\(venue.logo?.key ?? "")"
            )
        )
    }
}
