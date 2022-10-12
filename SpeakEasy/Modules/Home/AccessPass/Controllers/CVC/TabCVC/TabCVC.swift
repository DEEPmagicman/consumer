//
//  TabCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 05/09/2022.
//

import UIKit

class TabCVC: UICollectionViewCell {

    @IBOutlet weak var lblOption: UILabelDeviceClass!
    @IBOutlet weak var viewSelectedTab: UIView!
    @IBOutlet weak var btnSelected: UIButton!
    
    func setData(data: TabBarOption) {
        self.lblOption.text = data.label
        
        switch data.isSelected {
        case true:
            self.lblOption.textColor = .white
        case false:
            self.lblOption.textColor = Global.APP_COLOR_DARK_GREY
        }
        
        self.lblOption.isShadowed = data.isSelected
        self.lblOption.layoutSubviews()
        
        self.viewSelectedTab.isHidden = !data.isSelected
    }
    
    func setEventDetailsData(data: EventHeaderOptions) {
        self.lblOption.text = data.label
        
        switch data.isSelected {
        case true:
            self.lblOption.textColor = .white
        case false:
            self.lblOption.textColor = Global.APP_COLOR_DARK_GREY
        }
        
        self.lblOption.isShadowed = data.isSelected
        self.lblOption.layoutSubviews()
        
        self.viewSelectedTab.isHidden = !data.isSelected
    }
}
