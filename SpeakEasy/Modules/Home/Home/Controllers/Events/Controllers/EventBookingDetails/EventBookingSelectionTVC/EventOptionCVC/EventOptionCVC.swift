//
//  EventOptionCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/2/22.
//

import UIKit

class EventOptionCVC: UICollectionViewCell {

    @IBOutlet weak var lblOption: UILabelDeviceClass!
    @IBOutlet weak var viewSelectedTab: UIView!
    
    func setData(data: EventHeaderOptions) {
        self.lblOption.text = data.label
        
        switch data.isSelected {
        case true:
            self.lblOption.textColor = .white
        case false:
            self.lblOption.textColor = Global.APP_COLOR_DARK_GREY
        }

        self.viewSelectedTab.isHidden = !data.isSelected
        lblOption.isShadowed = data.isSelected
    }
}
