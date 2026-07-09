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

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        venueImageView.sd_cancelCurrentImageLoad()
        venueImageView.image = UIImage(named: "newSpeakeasy")
        nameLabel.text = nil
        addressLabel.text = nil
        badgeView.isHidden = true
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

        actionLabel.text = "View venue"
        badgeLabel.text = "Premium available"
        badgeView.isHidden = venue.isPremium != true

        let imageKey = venue.venueAttachment?.first?.key ?? venue.logo?.key ?? ""
        venueImageView.sd_setImage(
            with: URL(string: imageKey.imageURL),
            placeholderImage: UIImage(named: "newSpeakeasy")
        )
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        venueImageView.contentMode = .scaleAspectFill
        venueImageView.clipsToBounds = true
        venueImageView.layer.cornerRadius = 6
        nameLabel.numberOfLines = 2
        addressLabel.numberOfLines = 1
        badgeView.layer.cornerRadius = 7
        badgeView.clipsToBounds = true
    }
    
}
