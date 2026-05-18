//
//  VenueCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

//
//  VenueCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit

final class VenueCVC: UICollectionViewCell {

    @IBOutlet weak var venueImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var bgView: UIView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        venueImg.image = nil
        venueLogo.image = nil
        venueName.text = nil
    }
    
    func configure(with venue: ClipVenue) {
        
        venueName.text = venue.name
        
        // Venue Logo
        let logoUrl = "\(SharedURL.amazonStorage)\(venue.logo?.key ?? "")"
        
        venueLogo.sd_setImage(
            with: URL(string: logoUrl),
            placeholderImage: UIImage(named: "newSpeakeasy")
        )
        
        // Venue Main Image
        let imageUrlString = "\(SharedURL.amazonStorage)\(venue.venueAttachment?.first?.key ?? "")"
        
        if let url = URL(string: imageUrlString) {
            
            venueImg.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "newSpeakeasy")
            ) { [weak self] _, _, _, _ in
                
                guard let self = self else { return }
            }
            
        } else {
            
            venueImg.image = UIImage(named: "newSpeakeasy")
        }
    }
}
