//
//  TabVenueCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 16/09/2022.
//

import UIKit

class TabVenueCVC: UICollectionViewCell {
    
    @IBOutlet weak var lblOption: UILabelDeviceClass!
    @IBOutlet weak var viewSelectedTab: UIView!
    @IBOutlet weak var imgVenueType: UIImageView!
    
    func setData(data: TabBarOption) {
        self.lblOption.text = data.label
        self.imgVenueType.image = data.icon
        switch data.isSelected {
        case true:
            self.lblOption.textColor = .white
        case false:
            self.lblOption.textColor = Global.APP_COLOR_DARK_GREY
        }
        
//        self.lblOption.isShadowed = data.isSelected
        self.lblOption.layoutSubviews()
        
        self.viewSelectedTab.isHidden = !data.isSelected
    }
}
