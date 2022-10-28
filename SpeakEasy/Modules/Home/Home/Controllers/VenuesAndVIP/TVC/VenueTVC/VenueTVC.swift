//
//  VenueTVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 29/08/2022.
//

import UIKit

class VenueTVC: UITableViewCell {

    @IBOutlet weak var viewSeeAll: UIView!
    @IBOutlet weak var btnSeeAll: UIButton!
    @IBOutlet weak var imgEventCover: UIImageView!
    @IBOutlet weak var lblPerformerName: UILabelDeviceClass!
    @IBOutlet weak var imgBrandLogo: UIImageView!
    @IBOutlet weak var btnFavourite: UIButton!
    @IBOutlet weak var lblClosesTime: UILabelDeviceClass!
    @IBOutlet weak var lblWaitingTime: UILabelDeviceClass!
    @IBOutlet weak var lblEntryFees: UILabelDeviceClass!
    
    func setData(seeAll: Bool){
        
        self.viewSeeAll.isHidden = !seeAll
    }
    
    func setData(data: VenuesVIPEventDataSet) {
        self.imgEventCover.image = data.imgEventCover
        self.lblPerformerName.text = "\(data.lblPerformerName ?? "") \(Constants.localizedCity)"
        self.imgBrandLogo.image = data.imgBrandLogo
        self.lblClosesTime.text = data.lblEventClosingTime
//        self.lblEntryFees.text = data.lblEventFees
//        self.lblWaitingTime.text = data.lblEventWaitingTime
        
//        self.currentLiveEventFires.isHidden = !(data.isLive ?? false)
    }
    @IBAction func onBtnFavourite(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
}
