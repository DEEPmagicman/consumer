//
//  HotVenueCVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 29/08/2022.
//

import UIKit

class HotVenueCVC: UICollectionViewCell {
    
    @IBOutlet weak var imgEventCover: UIImageView!
    @IBOutlet weak var lblPerformerName: UILabelDeviceClass!
    @IBOutlet weak var imgBrandLogo: UIImageView!
    @IBOutlet weak var btnFavourite: UIButton!
    @IBOutlet weak var lblClosesTime: UILabelDeviceClass!
    @IBOutlet weak var lblWaitingTime: UILabelDeviceClass!
    @IBOutlet weak var lblEntryFees: UILabelDeviceClass!
    
//    @IBOutlet weak var currentLiveEventFires: UIStackView!
    
    @IBAction func onBtnFavourite(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func setData(data: VenuesVIPEventDataSet) {
        self.imgEventCover.image = data.imgEventCover
        self.lblPerformerName.text = data.lblPerformerName
        self.imgBrandLogo.image = data.imgBrandLogo
        self.lblEntryFees.text = data.lblEventFees
        self.lblClosesTime.text = data.lblEventClosingTime
        self.lblWaitingTime.text = data.lblEventWaitingTime
        
//        self.currentLiveEventFires.isHidden = !(data.isLive ?? false)
    }
}
