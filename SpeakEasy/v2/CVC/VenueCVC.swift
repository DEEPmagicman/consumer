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
    
    private var shimmerLayers: [ShimmerView] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerView.frame = contentView.bounds
        if shimmerLayers.isEmpty && contentView.bounds.width > 0 {
            setupShimmerUI()
        }
    }

    private func make(_ frame: CGRect, corner: CGFloat = 8) {
        let v = ShimmerView(frame: frame)
        v.layer.cornerRadius = corner
        v.clipsToBounds = true
        shimmerView.addSubview(v)
        shimmerLayers.append(v)
    }
    
    private func setupShimmerUI() {
        shimmerLayers.forEach { $0.removeFromSuperview() }
        shimmerLayers.removeAll()
        let width = 158
        make(CGRect(x: 0, y: 0, width: width, height: 158), corner: 8)
        make(CGRect(x: 0, y: 166, width: width - 16, height: 14))
    }

    func configure(with venue: ClipVenue) {
        shimmerView.isHidden = true
        venueName.text = venue.name
        let logoUrl = "\(SharedURL.amazonStorage)\(venue.logo?.key ?? "")"
        venueLogo.sd_setImage(with: URL(string: logoUrl), completed: nil)
        
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
