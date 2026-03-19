//
//  HoursTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/31/22.
//

import UIKit

final class HoursTVC: UITableViewCell {

    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblDay: UILabel!
    
    func setData(_ data: VenueHoursClip?, timezone: String = "") {
        lblDay.text = data?.day.capitalized
        lblTime.text = "\(data?.from.convertDateFormat(from: .HHmmss, to: .hmmA, useDayLightSavingTime: true, customTimeZone: timezone) ?? "") - \(data?.to.convertDateFormat(from: .HHmmss, to: .hmmA, useDayLightSavingTime: true, customTimeZone: timezone) ?? "")"
    }
}
