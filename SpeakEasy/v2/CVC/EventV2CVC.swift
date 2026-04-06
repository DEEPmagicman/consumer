//
//  EventV2CVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit

final class EventV2CVC: UICollectionViewCell {
    
    @IBOutlet weak var shimmerView: UIView!
    
    private var shimmerLayers: [ShimmerView] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupShimmerUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        shimmerView.frame = contentView.bounds
        
        if shimmerLayers.isEmpty {
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
        make(CGRect(x: 0, y: 186, width: width - 40, height: 12))
    }
}
