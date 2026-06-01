//
//  VenueGridShimmerCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 29/05/26.
//

import UIKit

final class VenueGridShimmerCell: UICollectionViewCell {
    
    private let shimmer = ShimmerViewV3()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        shimmer.layer.cornerRadius = 16
        shimmer.clipsToBounds = true
        
        shimmer.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(shimmer)
        
        NSLayoutConstraint.activate([
            shimmer.topAnchor.constraint(equalTo: contentView.topAnchor),
            shimmer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shimmer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shimmer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        shimmer.startShimmer()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func willMove(
        toWindow newWindow: UIWindow?
    ) {
        
        super.willMove(
            toWindow: newWindow
        )
        
        if newWindow == nil {
            
            shimmer.stopShimmer()
            
        } else {
            
            shimmer.startShimmer()
        }
    }
}

