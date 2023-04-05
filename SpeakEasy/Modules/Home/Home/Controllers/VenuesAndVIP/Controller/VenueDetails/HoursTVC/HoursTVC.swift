//
//  HoursTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/31/22.
//

import UIKit

final class HoursTVC: UITableViewCell {

    @IBOutlet weak var lblTime: UILabelDeviceClass!
    @IBOutlet weak var lblDay: UILabelDeviceClass!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setData(data: HoursDataSet) {
        self.lblDay.text = data.day
        self.lblTime.text = data.time
    }
}
