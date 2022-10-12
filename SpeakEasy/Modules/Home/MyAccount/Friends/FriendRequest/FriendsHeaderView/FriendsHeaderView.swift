//
//  HeaderView.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 05/09/2022.
//

import Foundation
import UIKit


class FriendsHeaderView: UIView {
    
    @IBOutlet weak var lblTitle: UILabelDeviceClass!
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "FriendsHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    func setData(section: Int){
        
        switch section {
        case 0:
            break
        case 1:
            self.lblTitle.text = Strings.ACTIVE_REQUEST.rawValue
        case 2:
            self.lblTitle.text = Strings.FROM_YOUR_CONTACTS.rawValue
        case 3:
            self.lblTitle.text = Strings.FELLOW_TAO_PEOPLE.rawValue
        default:
            self.lblTitle.text = Strings.CHICAGE_VIPS.rawValue
        }
    }
}
