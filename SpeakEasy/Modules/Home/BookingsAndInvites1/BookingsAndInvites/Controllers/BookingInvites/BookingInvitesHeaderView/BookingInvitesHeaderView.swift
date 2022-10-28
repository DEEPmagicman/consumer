//
//  BookingInvitesHeaderView.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 28/09/2022.
//

import Foundation
import UIKit

class BookingInvitesHeaderView: UIView {
    
    @IBOutlet weak var imgVenueCover: UIImageView!
    @IBOutlet weak var lblPerfomerName: UILabelDeviceClass!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblPhoneNumber: UILabel!
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "BookingInvitesHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    func setData(data: VenuesVIPEventDataSet) {
        self.lblLocation.text = "\(data.location ?? "") \(Constants.localizedCity)"
        self.lblPhoneNumber.text = data.phoneNumber ?? ""
        self.lblPerfomerName.text = "\(data.lblPerformerName ?? "") \(Constants.localizedCity)"
        self.imgVenueCover.image = data.imgEventCover
    }
}
