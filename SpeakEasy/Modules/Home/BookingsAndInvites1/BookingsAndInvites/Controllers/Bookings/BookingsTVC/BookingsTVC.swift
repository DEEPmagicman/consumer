//
//  BookingsTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 30/08/2022.
//

import UIKit

class BookingsTVC: UITableViewCell {

    @IBOutlet weak var btnBookingInvites: UIButton!
    @IBOutlet weak var lblBookingName: UILabelDeviceClass!
    @IBOutlet weak var imgBrand: UIImageView!
    @IBOutlet weak var viewArtistDetail: UIStackView!
    @IBOutlet weak var viewOthers: UIStackView!
    @IBOutlet weak var viewTable: UIStackView!
    @IBOutlet weak var viewTicket: UIStackView!
    @IBOutlet weak var lblDate: UILabelDeviceClass!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var imgArtist: UIImageView!
    @IBOutlet weak var viewCount: UIView!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var lblCount: UILabelDeviceClass!
    
    func setData(data: BookingsDataSet, isFromSettings: Bool = false){
        
        self.imgBrand.image = data.brand
        self.lblBookingName.text = data.bookingName
        self.imgArtist.image = data.performerCover
        self.lblDate.text = data.date
        
        self.lblStatus.text = data.status?.rawValue
        
        if data.isTicket {
            self.viewArtistDetail.isHidden = false
            self.viewTicket.isHidden = false
            self.viewTable.isHidden = true
            self.viewOthers.isHidden = true
        }
        else {
            self.viewArtistDetail.isHidden = true
            self.viewTicket.isHidden = true
            self.viewTable.isHidden = false
            self.viewOthers.isHidden = false
        }
        
        if data.status == .AwaitingVenueApproval {//} || data.status == .AwaitingVenueApproval {
            self.viewCount.isHidden = false
        }
        else {
            self.viewCount.isHidden = true
        }
        if isFromSettings {
            viewCount.isHidden = true
        }
        
        if data.status == .PurchaseConfirmed || data.status == .TicketPurchasedConfirmed {
            self.lblStatus.textColor = UIColor(hex: "#F581FE")
        }
        else {
            self.lblStatus.textColor = UIColor(hex: "#7D7D7D")
        }
        statusView.isHidden = isFromSettings
    }
}

