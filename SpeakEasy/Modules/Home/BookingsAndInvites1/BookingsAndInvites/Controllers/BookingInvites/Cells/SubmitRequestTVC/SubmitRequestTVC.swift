//
//  SubmitRequestTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 28/09/2022.
//

import UIKit

class SubmitRequestTVC: UITableViewCell {

    @IBOutlet weak var viewCancelReques: UIView!
    @IBOutlet weak var btnSubmitRequest: UIButtonDeviceClass!
    @IBOutlet weak var viewSubmitRequest: UIView!
    @IBOutlet weak var btnCancelRequest: UIButton!
    @IBOutlet weak var infoLbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setData(data: BookingsDataSet) {
        
        guard let status = data.status else {return}
        
        switch status {
        case .PurchaseConfirmed,.TicketPurchasedConfirmed:
            break
        case .AwaitingApproval:
            
             self.viewCancelReques.isHidden = false
             self.btnCancelRequest.isHidden = false
             self.viewSubmitRequest.isHidden = true
             self.btnSubmitRequest.isHidden = true
            
        case .AwaitingVenueApproval:
            self.btnSubmitRequest.setTitle("View in Bookings", for: .normal)
           self.infoLbl.highlightBold(["Once confirmed by the venue, all bookings are FINAL"], size: 15, textColor: .white)
             self.viewCancelReques.isHidden = false
             self.btnCancelRequest.isHidden = false
             self.viewSubmitRequest.isHidden = true
             self.btnSubmitRequest.isHidden = true

        case .SubmitRequest:
            self.infoLbl.highlightBold(["Once confirmed by the venue, all bookings are FINAL"], size: 15, textColor: .white)
             self.viewCancelReques.isHidden = true
             self.btnCancelRequest.isHidden = true
             self.viewSubmitRequest.isHidden = false
             self.btnSubmitRequest.isHidden = false
            self.viewSubmitRequest.backgroundColor = Constant.Color.submiteRequestBtnColor

        case .BookingConfirmation:
             self.btnSubmitRequest.setTitle("View in Bookings", for: .normal)
//            self.infoLbl.text = Constant.String.sendReceiptText
            self.infoLbl.highlightBold(["Once confirmed by the venue, all bookings are FINAL"], size: 15, textColor: .white)
             self.viewCancelReques.isHidden = false
             self.btnCancelRequest.isHidden = false
             self.viewSubmitRequest.isHidden = true
             self.btnSubmitRequest.isHidden = true

        }
    }
}
