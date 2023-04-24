//
//  ViewEventTicketTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/2/22.
//

import UIKit

class ViewEventTicketTVC: UITableViewCell {

    @IBOutlet weak var lblCount: UILabelDeviceClass!
    @IBOutlet weak var btnMinusQuantity: UIButton!
    @IBOutlet weak var btnPlusQuantity: UIButton!
    @IBOutlet weak var ticketTypeLbl: UILabelDeviceClass!
    @IBOutlet weak var ticketDescriptionLbl: UILabelDeviceClass!
    @IBOutlet weak var ticketPriceLbl: UILabelDeviceClass!
    
    func setData(data: EventTicket) {
        self.lblCount.text = "\(data.selectedTicketCount ?? 0)"
        ticketTypeLbl.text = data.tierName
        ticketDescriptionLbl.text = data.tierDescription
        ticketPriceLbl.text = "\(data.price)"
    }
}
