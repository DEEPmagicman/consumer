//
//  HoursTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/31/22.
//

import UIKit

class HoursTVC: UITableViewCell {

    @IBOutlet weak var lblTime: UILabelDeviceClass!
    @IBOutlet weak var lblDay: UILabelDeviceClass!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setData(data:HoursDataSet) {
        self.lblDay.text = data.day
        self.lblTime.text = data.time
    }
}
