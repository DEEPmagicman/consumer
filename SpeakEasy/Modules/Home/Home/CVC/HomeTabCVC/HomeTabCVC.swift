//
//  HomeTabCVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit
// TODO: check if being use anywhere or remove
class HomeTabCVC: UICollectionViewCell {

    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var lblOption: UILabelDeviceClass!
    @IBOutlet weak var viewSelectedTab: UIView!
    
    func setData(data: TabBarOption) {
        self.lblOption.text = data.label
        
        switch data.isSelected {
        case true:
            self.imgIcon.image = data.selectedIcon
            self.lblOption.textColor = .white
        case false:
            self.imgIcon.image = data.icon
            self.lblOption.textColor = Global.APP_COLOR_DARK_GREY
        }
        
        self.lblOption.isShadowed = data.isSelected
        self.lblOption.layoutSubviews()
        
        self.viewSelectedTab.isHidden = !data.isSelected
    }
}
