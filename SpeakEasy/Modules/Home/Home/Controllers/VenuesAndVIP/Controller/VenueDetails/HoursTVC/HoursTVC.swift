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

    func setData(_ data: VenueHoursClip?) {
        lblDay.text = data?.day.capitalized
        lblTime.text = "\(data?.from.convertDateFormat(from: .HHmmss, to: .hmm_a, isUTC: false) ?? "") - \(data?.to.convertDateFormat(from: .HHmmss, to: .hmm_a, isUTC: false) ?? "")"
    }
}
