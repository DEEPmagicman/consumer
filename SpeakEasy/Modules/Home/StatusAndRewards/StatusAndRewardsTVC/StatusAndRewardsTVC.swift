//
//  StatusAndRewardsTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/30/22.
//

import UIKit

class StatusAndRewardsTVC: UITableViewCell {

    @IBOutlet weak var imgBrand: RoundedImage!
    @IBOutlet weak var lblVenueName: UILabelDeviceClass!
    
    @IBOutlet weak var viewPerformer: UIStackView!
    @IBOutlet weak var lblPerformerName: UILabelDeviceClass!
    
    @IBOutlet weak var viewTicket: UIStackView!
    @IBOutlet weak var lblTicketName: UILabelDeviceClass!
    
    @IBOutlet weak var viewTable: UIStackView!
    @IBOutlet weak var lblTableName: UILabelDeviceClass!
    
    @IBOutlet weak var viewGroup: UIStackView!
    @IBOutlet weak var lblGroupLength: UILabelDeviceClass!
    
    @IBOutlet weak var lblDate: UILabelDeviceClass!
    
    @IBOutlet weak var imgCover: UIImageView!
    @IBOutlet weak var lblReward: UILabelDeviceClass!
    
    func setData(data: StatusAndRewardDataSet) {
        self.imgBrand.image = data.brand
        self.lblVenueName.text = data.venueName
        
        self.viewPerformer.isHidden = !data.isPerformer
        self.lblPerformerName.text = data.performerName
        
        self.viewTicket.isHidden = !data.isTicket
        self.lblTicketName.text = data.ticketDescription
        
        self.viewTable.isHidden = !data.isTable
//        self.lblTableName.text = ""
        
        self.viewGroup.isHidden = !data.isGroupInvite
//        self.lblGroupLength.text = ""
        
        self.lblDate.text = data.date
        
        self.imgCover.image = data.eventCover
        self.lblReward.text = data.rewardDescription
        if data.rewardDescription == "FREE" {
            lblReward.textColor = UIColor(hex: "#CC00FF")
        } else {
            lblReward.textColor = UIColor(hex: "#007AFF")
        }
    }
}
