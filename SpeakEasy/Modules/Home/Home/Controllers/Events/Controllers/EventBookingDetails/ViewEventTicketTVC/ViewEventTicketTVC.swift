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
    
    func setData(data: EventBooking) {
        self.lblCount.text = "\(data.ticketCount)"
    }
}
