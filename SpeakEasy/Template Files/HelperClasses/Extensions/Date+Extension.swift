//
//  Date+Extension.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 17/09/2022.
//

import Foundation

extension Date {
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth())!
    }
    
    var age: Int{
        let now = Date()
        let calendar = Calendar.current

        let ageComponents = calendar.dateComponents([.year], from: self, to: now)
        return ageComponents.year ?? 0
    }
    
    func string(format: DateFormat, isUTC: Bool = true) -> String {
        let dateFormatter = DateFormatter()
        if isUTC {
            dateFormatter.timeZone = TimeZone(identifier: "UTC")!            
        }
        dateFormatter.dateFormat = format.rawValue
        return dateFormatter.string(from: self)
    }
}

enum DateFormat:String {
    case MMddyyyy = "MM/dd/yyyy"
    case MMMMDDYYYY = "MMMM dd, yyyy"
    case yyyyMMddTHHmmssSSSz = "yyyy-MM-dd'T'HH:mm:ss.SSSz"
    case yyyyMMddHHmmss = "yyyy-MM-dd HH:mm:ss"
    case YYYYMMDD = "yyyy-MM-dd"
    case EEEEMMMD = "EEEE, MMM d"
    case EEEMMMD = "EEE, MMM d"
    case hmm_a = "h:mm a"
    case hmma = "h:mma"
    case HHmmss = "HH:mm:ss"
    case MMMMddHHmm = "MMMM dd 'at' h:mm a"
}

