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
            
             self.viewCancelReques.isHidden = true
             self.btnCancelRequest.isHidden = true
             self.viewSubmitRequest.isHidden = false
             self.btnSubmitRequest.isHidden = false

        case .SubmitRequest:

             self.viewCancelReques.isHidden = true
             self.btnCancelRequest.isHidden = true
             self.viewSubmitRequest.isHidden = false
             self.btnSubmitRequest.isHidden = false

        case .BookingConfirmation:
             self.btnSubmitRequest.setTitle("View in Bookings", for: .normal)
            
             self.viewCancelReques.isHidden = true
             self.btnCancelRequest.isHidden = true
             self.viewSubmitRequest.isHidden = false
             self.btnSubmitRequest.isHidden = false

        }
    }
}
