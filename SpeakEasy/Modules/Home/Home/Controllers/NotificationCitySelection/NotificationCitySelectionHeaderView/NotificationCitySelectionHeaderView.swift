//
//  NotificationCitySelectionHeaderView.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 08/09/2022.
//

import Foundation
import UIKit

class NotificationCitySelectionHeaderView: UIView{
    
    @IBOutlet weak var lblTitle: UILabelDeviceClass!
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "NotificationCitySelectionHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    public func setData(section: Int) {
        
        switch section {
            
        case 0:
            self.lblTitle.text = Strings.NEW.rawValue
        default :
            self.lblTitle.text = Strings.PREVIOUS.rawValue

        }
    }
    
}
