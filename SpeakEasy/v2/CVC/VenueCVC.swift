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
    @IBOutlet weak var venueLogo: UIImageView!
    
    func configure(with venue: ClipVenue) {
        venueName.text = venue.name
        let logoUrl = "\(SharedURL.amazonStorage)\(venue.logo?.key ?? "")"
        self.venueLogo.sd_setImage(with: URL( string: logoUrl), completed: nil)
        let imageUrlString = "\(SharedURL.amazonStorage)\(venue.venueAttachment?.first?.key ?? "")"
        if let url = URL(string: imageUrlString) {
            venueImg.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "newSpeakeasy")
            )
        } else {
            venueImg.image = UIImage(named: "newSpeakeasy")
        }
    }
}
