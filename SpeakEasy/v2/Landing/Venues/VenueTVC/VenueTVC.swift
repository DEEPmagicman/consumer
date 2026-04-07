//
//  VenueTVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 04/02/26.
//

import UIKit
import SDWebImage

final class VenueTVC: UITableViewCell {
    
    @IBOutlet weak var venueImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var shimmerView: ShimmerView!
    
    private var pendingImageLoads = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        venueImg.sd_cancelCurrentImageLoad()
        venueLogo.sd_cancelCurrentImageLoad()
        
        venueImg.image = UIImage(named: "newSpeakeasy")
        venueLogo.image = nil
        venueName.text = nil
        
        pendingImageLoads = 0
        showShimmer(false)
    }
    
    private func setupUI() {
        selectionStyle = .none
        showShimmer(false)
    }
    
    private func showShimmer(_ show: Bool) {
        shimmerView.isHidden = !show
        
        if show {
            contentView.bringSubviewToFront(shimmerView)
            shimmerView.startAnimating()
        } else {
            shimmerView.stopAnimating()
        }
    }
    
    private func beginLoadingState() {
        pendingImageLoads = 0
        venueName.text = nil
        venueImg.image = UIImage(named: "newSpeakeasy")
        venueLogo.image = nil
        showShimmer(true)
    }
    
    private func finishOneLoad() {
        pendingImageLoads -= 1
        if pendingImageLoads <= 0 {
            showShimmer(false)
        }
    }
    
    func configure(with venue: ClipVenue) {
        beginLoadingState()
        
        venueName.text = venue.name
        
        let logoKey = venue.logo?.key ?? ""
        let logoUrlString = "\(SharedURL.amazonStorage)\(logoKey)"
        
        let imageKey = venue.venueAttachment?.first?.key ?? ""
        let imageUrlString = "\(SharedURL.amazonStorage)\(imageKey)"
        
        var totalLoads = 0
        
        if let logoURL = URL(string: logoUrlString), !logoKey.isEmpty {
            totalLoads += 1
            venueLogo.sd_setImage(with: logoURL, placeholderImage: nil) { [weak self] _, _, _, _ in
                self?.finishOneLoad()
            }
        }
        
        if let imageURL = URL(string: imageUrlString), !imageKey.isEmpty {
            totalLoads += 1
            venueImg.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "newSpeakeasy")
            ) { [weak self] _, _, _, _ in
                self?.finishOneLoad()
            }
        } else {
            venueImg.image = UIImage(named: "newSpeakeasy")
        }
        
        pendingImageLoads = totalLoads
        
        if totalLoads == 0 {
            showShimmer(false)
        }
    }
    
    func showSkeleton() {
        venueName.text = nil
        venueImg.image = nil
        venueLogo.image = nil
        showShimmer(true)
    }
}
