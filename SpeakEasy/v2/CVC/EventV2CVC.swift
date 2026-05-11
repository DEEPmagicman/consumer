//
//  EventV2CVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit

final class EventV2CVC: UICollectionViewCell {
    
    @IBOutlet weak var shimmerView: UIView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    
    private var shimmerLayers: [ShimmerView] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupShimmerUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerView.frame = contentView.bounds
    }
    
    // EventV2CVC
    func clearHeroIDs() {
        image.hero.id     = nil
        eventName.hero.id = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset UI (prevents flicker)
        image.image = nil
        eventName.text = nil
        eventDate.text = nil
        venueName.text = nil
        
        // Show shimmer again
        shimmerView.isHidden = false
        bgView.isHidden = true
        shimmerLayers.forEach { $0.isHidden = false }
    }
    
    // MARK: - Shimmer Setup
    
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
        
        make(CGRect(x: 0, y: 0, width: width, height: 158), corner: 8)
        make(CGRect(x: 0, y: 166, width: width - 16, height: 14))
        make(CGRect(x: 0, y: 186, width: width - 40, height: 12))
    }
    
    // MARK: - Data Setup
    
    func setupData(event: Event) {
        
        // Hide shimmer
        shimmerView.isHidden = true
        shimmerLayers.forEach { $0.isHidden = true }
        
        // Show actual content
        bgView.isHidden = false
        
        // Image
        image.sd_setImage(
            with: URL(string: (event.flyer?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )
        
        // Text
        venueName.text = event.venue?.name.uppercased()
        eventName.text = event.title
        
        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            
            eventDate.text = customText
            
        } else {
            
            let timezone = event.venue?.useTimezone ?? ""
            
            let dateText = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .EEEMMMD,
                customTimeZone: timezone
            )
            
            eventDate.text = dateText.isEmpty ? "" : dateText
        }
    }
}
