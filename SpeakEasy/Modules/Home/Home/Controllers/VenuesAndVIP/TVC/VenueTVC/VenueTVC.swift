//
//  VenueTVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 29/08/2022.
//

import UIKit
import SDWebImage

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
    
    func setData(data: VenuesVIPEventDataSet, seeAll: Bool) {
//        let imgUrl = "https://speakeasy-storage.s3.amazonaws.com/\(data.venueAttachment.first?.key ?? "")"
//        let logoUrl = "https://speakeasy-storage.s3.amazonaws.com/\(data.logo?.key ?? "")"
//        self.imgEventCover.sd_setImage(with: URL( string: imgUrl), completed: nil)
//        self.imgBrandLogo.sd_setImage(with: URL( string: logoUrl), completed: nil)
        
        self.imgEventCover.image = data.imgEventCover
        self.lblPerformerName.text = data.lblPerformerName
        self.imgBrandLogo.image = data.imgBrandLogo
        self.lblClosesTime.text = data.lblEventClosingTime
//        self.lblEntryFees.text = data.lblEventFees
//        self.lblWaitingTime.text = data.lblEventWaitingTime
        
//        self.currentLiveEventFires.isHidden = !(data.isLive ?? false)
        self.viewSeeAll.isHidden = !seeAll
    }
    
    func setDataNew(data: Venue, seeAll: Bool) {
        let imgUrl = "\(SharedURL.amazonStorage)\(data.venueAttachment.first?.key ?? "")"
        let logoUrl = "\(SharedURL.amazonStorage)\(data.logo?.key ?? "")"
        self.imgEventCover.sd_setImage(with: URL( string: imgUrl), completed: nil)
        self.imgBrandLogo.sd_setImage(with: URL( string: logoUrl), completed: nil)
        self.lblPerformerName.text = data.name
        self.lblClosesTime.text = "Closes 2:00 AM" //data.lblEventClosingTime
        //        self.lblEntryFees.text = data.lblEventFees
        //        self.lblWaitingTime.text = data.lblEventWaitingTime
        //        self.currentLiveEventFires.isHidden = !(data.isLive ?? false)
        self.viewSeeAll.isHidden = !seeAll
    }

    
    @IBAction func onBtnFavourite(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
}
