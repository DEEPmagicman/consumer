//
//  BottleMenuTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/1/22.
//

import UIKit

class BottleMenuTVC: UITableViewCell {

    @IBOutlet weak var lblType: UILabelDeviceClass!
    @IBOutlet weak var lblDrinkOne: UILabelDeviceClass!
    @IBOutlet weak var lblDrinkTwo: UILabelDeviceClass!
    @IBOutlet weak var lblDrinkThree: UILabelDeviceClass!
    @IBOutlet weak var lblDrinkFour: UILabelDeviceClass!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
