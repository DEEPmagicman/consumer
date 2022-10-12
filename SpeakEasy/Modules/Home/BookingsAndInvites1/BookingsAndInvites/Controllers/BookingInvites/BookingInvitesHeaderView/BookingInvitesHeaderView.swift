//
//  BookingInvitesHeaderView.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 28/09/2022.
//

import Foundation
import UIKit

class BookingInvitesHeaderView: UIView {
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "BookingInvitesHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
}
