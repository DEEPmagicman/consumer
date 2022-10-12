//
//  InviteFriendsHeaderView.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 06/09/2022.
//

import Foundation
import UIKit

class InviteFriendsHeaderView: UIView{
    
    @IBOutlet weak var lblTitle: UILabelDeviceClass!
    @IBOutlet weak var lblCount: UILabelDeviceClass!
    @IBOutlet weak var parentView: UIView!
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "InviteFriendsHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    func setData(data: InviteFriendsHeadersData) {
        switch data.title {
            
        case Strings.SELECTED_BOOKING.rawValue:
            self.lblTitle.text = data.title
            self.lblCount.text = ""
            parentView.backgroundColor = data.backGroundColor
        case Strings.INVITE_FRIENDS.rawValue:
            self.lblTitle.text = data.title
            self.lblCount.text = "Max: 5"
            parentView.backgroundColor = data.backGroundColor
        case Strings.INVITE_FROM_CONTACTS.rawValue:
            self.lblTitle.text = data.title
            self.lblCount.text = ""
            parentView.backgroundColor = data.backGroundColor
        default:
            self.lblTitle.text = ""
            self.lblCount.text = ""
        }
    }

    public func setAdditionalGuestData(section:Int) {
        
        switch section {
            
        case 1:
            self.lblTitle.text = Strings.INVITE_FROM_CONTACTS.rawValue
            self.lblCount.text = ""
            parentView.backgroundColor = Global.APP_COLOR_CALENDAR_BG

        default:
            self.lblTitle.text = ""
            self.lblCount.text = ""
        }
    }

}
