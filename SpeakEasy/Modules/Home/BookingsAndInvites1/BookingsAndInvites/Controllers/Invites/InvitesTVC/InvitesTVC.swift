//
//  InvitesTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 30/08/2022.
//

import UIKit

class InvitesTVC: UITableViewCell {

    @IBOutlet weak var btnBookingInvites: UIButton!
    @IBOutlet weak var lblCost: UILabelDeviceClass!
    
   
    func setData(data: String) {
        self.lblCost.text = data
    }
    
}
