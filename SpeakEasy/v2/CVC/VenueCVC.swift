//
//  VenueCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit

final class VenueCVC: UICollectionViewCell {

    @IBOutlet weak var shimmerView: UIView!
    @IBOutlet weak var venueImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!

    func configure(with venue: ClipVenue) {
        venueName.text = venue.name
        let imageUrlString = "\(SharedURL.amazonStorage)\(venue.venueAttachment?.first?.key ?? "")"
        if let url = URL(string: imageUrlString) {
            venueImg.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "venue_placeholder")
            )
        } else {
            venueImg.image = UIImage(named: "venue_placeholder")
        }
    }
}
