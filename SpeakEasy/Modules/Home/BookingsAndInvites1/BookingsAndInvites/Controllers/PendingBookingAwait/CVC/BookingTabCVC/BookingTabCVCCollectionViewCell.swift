//
//  BookingTabCVCCollectionViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 03/09/2022.
//

import UIKit

class BookingTabCVCCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var lblOption: UILabelDeviceClass!
    @IBOutlet weak var viewSelectedTab: UIView!
    @IBOutlet weak var countMessage: UIView!
    @IBOutlet weak var lblCount: UILabelDeviceClass!
    
    func setData(data: TabBarOption) {
        self.lblOption.text = data.label
        if data.label == Strings.MESSAGES.text {
            self.countMessage.isHidden = false
        }else{
            self.countMessage.isHidden = true
        }
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
    
    func setFriendsData(data: TabBarOption) {
        self.lblOption.text = data.label
        if data.label == Strings.SEARCH_AND_ADD.text {
            self.countMessage.isHidden = false
            self.lblCount.text = "2"

        }else{
            self.countMessage.isHidden = true
        }
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
