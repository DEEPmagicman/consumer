//
//  CollectionViewFlowLayout.swift
//  FoodChoo
//
//  Created by M.Usman Bin Rehan on 1/25/22.
//

import Foundation
import UIKit

class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }

            layoutAttribute.frame.origin.x = leftMargin

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY , maxY)
        }

        return attributes
    }
}
class DynamicCollectionView: UICollectionView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        return self.contentSize
    }
}
class WeiTabBarController: UITabBarController {
    
    init() {
        
        super.init(nibName: nil, bundle: nil)
        
        object_setClass(self.tabBar, WeiTabBar.self)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    class WeiTabBar: UITabBar {
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            
            var sizeThatFits = super.sizeThatFits(size)
            
            sizeThatFits.height = 110
            
            return sizeThatFits
            
        }
        
    }
    
}
