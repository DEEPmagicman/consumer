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
    
    @IBOutlet weak var shimmerView: UIView!
    @IBOutlet weak var venueImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var bgView: UIView!
    
    private var shimmerLayers: [ShimmerView] = []
    
    // MARK: - Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupShimmerUI()
        showShimmer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        shimmerView.frame = contentView.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset UI
        venueImg.image = nil
        venueLogo.image = nil
        venueName.text = nil
        
        // Show shimmer again
        showShimmer()
    }
    
    // MARK: - Shimmer Methods
    
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
        
        let width: CGFloat = 158
        
        // Image shimmer
        make(
            CGRect(x: 0, y: 0, width: width, height: 158),
            corner: 8
        )
        
        // Title shimmer
        make(
            CGRect(x: 0, y: 166, width: width - 16, height: 14)
        )
    }
    
    private func showShimmer() {
        
        shimmerView.isHidden = false
        shimmerLayers.forEach { $0.isHidden = false }
        
        // Hide content while loading
        bgView.isHidden = true
    }
    
    private func hideShimmer() {
        
        shimmerView.isHidden = true
        shimmerLayers.forEach { $0.isHidden = true }
        
        // Show content after loading
        bgView.isHidden = false
    }
    
    // MARK: - Configure
    
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
                
                self.hideShimmer()
            }
            
        } else {
            
            venueImg.image = UIImage(named: "newSpeakeasy")
            hideShimmer()
        }
    }
}
