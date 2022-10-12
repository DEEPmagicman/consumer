//
//  AdditionalGuestsTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 06/09/2022.
//

import UIKit

class AdditionalGuestsTVC: UITableViewCell {

    @IBOutlet weak var lblNumberOfFemale: UILabelDeviceClass!
    @IBOutlet weak var lblNumberOfMale: UILabelDeviceClass!
    @IBOutlet weak var btnMinusFemale: UIButton!
    @IBOutlet weak var btnAddFemail: UIButton!
    @IBOutlet weak var btnMinusMale: UIButton!
    @IBOutlet weak var btnAddMail: UIButton!
    
    func setData(noOfMale: Int,noOfFemale: Int) {
        self.lblNumberOfFemale.text = "\(noOfFemale)"
        self.lblNumberOfMale.text = "\(noOfMale)"
    }
}

