//
//  MapVenueTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 18/05/26.
//

import UIKit

class MapVenueTableViewCell: UITableViewCell {

    @IBOutlet weak var venueImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var badgeView: UIView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!

    private let logoImageView = UIImageView()
    private let imageDimView = UIView()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        releaseImageResources()
        nameLabel.text = nil
        addressLabel.text = nil
        badgeView.isHidden = true
    }

    deinit {
        releaseImageResources()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(with venue: ClipVenue) {
        nameLabel.text = venue.name.uppercased()
        addressLabel.text = [venue.address, venue.city]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: ", ")

        actionLabel.text = "See events"
        badgeLabel.text = "Premium available"
        badgeView.isHidden = venue.isPremium != true

        let imageKey = venue.venueAttachment?.first?.key ?? venue.logo?.key ?? ""
        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: 160 * scale,
            height: 120 * scale
        )

        venueImageView.sd_setImage(
            with: URL(string: imageKey.imageURL),
            placeholderImage: UIImage(named: "newSpeakeasy"),
            options: [.scaleDownLargeImages],
            context: [
                .imageThumbnailPixelSize: NSValue(cgSize: targetSize)
            ]
        )

        let logoKey = venue.logo?.key ?? ""
        let logoSize = CGSize(
            width: 50 * scale,
            height: 50 * scale
        )

        logoImageView.sd_setImage(
            with: URL(string: logoKey.imageURL),
            placeholderImage: nil,
            options: [.scaleDownLargeImages],
            context: [
                .imageThumbnailPixelSize: NSValue(cgSize: logoSize)
            ]
        )
    }

    func releaseImageResources() {
        venueImageView.sd_cancelCurrentImageLoad()
        logoImageView.sd_cancelCurrentImageLoad()
        venueImageView.image = UIImage(named: "newSpeakeasy")
        logoImageView.image = nil
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        venueImageView.contentMode = .scaleAspectFill
        venueImageView.clipsToBounds = true
        venueImageView.layer.cornerRadius = 6
        setupLogoOverlay()
        nameLabel.numberOfLines = 2
        addressLabel.numberOfLines = 1
        badgeView.layer.cornerRadius = 7
        badgeView.clipsToBounds = true
        styleActionPill()
    }

    private func setupLogoOverlay() {
        imageDimView.backgroundColor = .clear
        imageDimView.translatesAutoresizingMaskIntoConstraints = false
        venueImageView.addSubview(imageDimView)

        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        venueImageView.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            imageDimView.topAnchor.constraint(equalTo: venueImageView.topAnchor),
            imageDimView.leadingAnchor.constraint(equalTo: venueImageView.leadingAnchor),
            imageDimView.trailingAnchor.constraint(equalTo: venueImageView.trailingAnchor),
            imageDimView.bottomAnchor.constraint(equalTo: venueImageView.bottomAnchor),

            logoImageView.centerXAnchor.constraint(equalTo: venueImageView.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: venueImageView.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 42),
            logoImageView.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    private func styleActionPill() {
        actionLabel.textColor = AppColor.primaryWhiteColor
        actionLabel.superview?.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.10)
    }
    
}
