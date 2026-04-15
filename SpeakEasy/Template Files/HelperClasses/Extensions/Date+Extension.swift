//
//  Date+Extension.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 17/09/2022.
//

import Foundation

extension Date {
    func string(format: DateFormat, isUTC: Bool = true) -> String {
        let dateFormatter = DateFormatter()
        if isUTC {
            dateFormatter.timeZone = TimeZone(identifier: "UTC")!            
        }
        dateFormatter.dateFormat = format.rawValue
        return dateFormatter.string(from: self)
    }
}

enum DateFormat: String {
    case MMddyyyy = "MM/dd/yyyy"
    case MMMMDDYYYY = "MMMM dd, yyyy"
    case yyyyMMddTHHmmssSSSz = "yyyy-MM-dd'T'HH:mm:ss.SSSz"
    case yyyyMMddHHmmss = "yyyy-MM-dd HH:mm:ss"
    case YYYYMMDD = "yyyy-MM-dd"
    case EEEEMMMD = "EEEE, MMM d"
    case EEEMMMD = "EEE, MMM d"
    case hmmA = "h:mm a"
    case hmma = "h:mma"
    case HHmmss = "HH:mm:ss"
    case MMMMddHHmm = "MMMM dd 'at' h:mm a"
    case HMMAMMMDD = "h:mma MMMM dd"
    case EEEE = "EEEE"
    case MMM = "MMM"
    case DD = "d"
    case MMDDYYYYHMMA = "MM/dd/yyyy h:mm a"
    case MMMD = "MMM d"
    case EEEEMMMMDDAT = "EEE, MMMM d 'at' h:mm a"
}
