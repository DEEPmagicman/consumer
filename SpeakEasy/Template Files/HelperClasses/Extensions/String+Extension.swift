//
//  String+Extension.swift
//  Utorny
//
//  Created by macbook on 14/09/2019.
//  Copyright © 2019 Ingic. All rights reserved.
//

import Foundation
import UIKit

//extension String {
//    func image() -> UIImage? {
//        let size = CGSize(width: 50, height: 50)
//        UIGraphicsBeginImageContextWithOptions(size, false, 0)
//        UIColor.clear.set()
//        let rect = CGRect(origin: .zero, size: size)
//        UIRectFill(CGRect(origin: .zero, size: size))
//        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 40)])
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return image
//    }
//    func getWidth(with height: CGFloat, font: UIFont) -> CGFloat {
//        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
//        let actualSize = self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: font], context: nil)
//        return actualSize.width
//    }
//}
//extension String {
//    var htmlToAttributedString: NSAttributedString? {
//        guard let data = data(using: .utf8) else { return nil }
//        do {
//            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
//        } catch {
//            return nil
//        }
//    }
//    var htmlToString: String {
//        return (htmlToAttributedString?.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
//    }
//}


//extension Double {
//    /// Rounds the double to decimal places value
//    func rounded(toPlaces places:Int) -> Double {
//        let divisor = pow(10.0, Double(places))
//        return (self * divisor).rounded() / divisor
//    }
//}
extension Date {

    func dateFormatWithSuffix() -> String {
        return "EEEE, dd'\(self.daySuffix())' MMM, yyyy"
    }
    func mediumDateFormatWithSuffix() -> String {
        return "EE, dd'\(self.daySuffix())' MMM, yyyy h:mm a"
    }

    func daySuffix() -> String {
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components(.day, from: self)
        let dayOfMonth = components.day
        switch dayOfMonth {
        case 1, 21, 31:
            return "st"
        case 2, 22:
            return "nd"
        case 3, 23:
            return "rd"
        default:
            return "th"
        }
    }
    
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    static func - (recent: Date, previous: Date) -> (month: Int?, day: Int?, hour: Int?, minute: Int?, second: Int?) {
        let day = Calendar.current.dateComponents([.day], from: previous, to: recent).day
        let month = Calendar.current.dateComponents([.month], from: previous, to: recent).month
        let hour = Calendar.current.dateComponents([.hour], from: previous, to: recent).hour
        let minute = Calendar.current.dateComponents([.minute], from: previous, to: recent).minute
        let second = Calendar.current.dateComponents([.second], from: previous, to: recent).second

        return (month: month, day: day, hour: hour, minute: minute, second: second)
    }
}
//extension Double {
//    func reduceScale(to places: Int) -> Double {
//        let multiplier = pow(10, Double(places))
//        let newDecimal = multiplier * self // move the decimal right
//        let truncated = Double(Int(newDecimal)) // drop the fraction
//        let originalDecimal = truncated / multiplier // move the decimal back
//        return originalDecimal
//    }
//}

//func formatNumber(_ n: Int) -> String {
//    let num = abs(Double(n))
//    let sign = (n < 0) ? "-" : ""
//
//    switch num {
//    case 1_000_000_000...:
//        var formatted = num / 1_000_000_000
//        formatted = formatted.reduceScale(to: 1)
//        return "\(sign)\(formatted)B"
//
//    case 1_000_000...:
//        var formatted = num / 1_000_000
//        formatted = formatted.reduceScale(to: 1)
//        return "\(sign)\(formatted)M"
//
//    case 1_000...:
//        var formatted = num / 1_000
//        formatted = formatted.reduceScale(to: 1)
//        return "\(sign)\(formatted)K"
//
//    case 0...:
//        return "\(n)"
//
//    default:
//        return "\(sign)\(n)"
//    }
//}
//extension Double {
//    func withCommas() -> String {
//        let numberFormatter = NumberFormatter()
//        numberFormatter.numberStyle = NumberFormatter.Style.decimal
//        return numberFormatter.string(from: NSNumber(value:self)) ?? ""
//    }
//}
//extension Double {
//    func string(fractionDigits:Int) -> String {
//        let formatter = NumberFormatter()
//        formatter.minimumFractionDigits = fractionDigits
//        formatter.maximumFractionDigits = fractionDigits
//        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
//    }
//}
extension String {
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
}
//extension Double {
//  func asString(style: DateComponentsFormatter.UnitsStyle) -> String {
//    let formatter = DateComponentsFormatter()
//    formatter.allowedUnits = [.hour, .minute, .second, .nanosecond]
//    formatter.unitsStyle = style
//    return formatter.string(from: self) ?? ""
//  }
//}
func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}
extension String {
    func capitalizingFirstLetter() -> String {
        var string = ""
        for component in self.components(separatedBy: " "){
            string += component.prefix(1).uppercased() + component.dropFirst() + " "
        }
        return String(string.dropLast())
    }
}
extension Int {
    func withCommas() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value:self))!
    }
}
