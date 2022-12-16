//
//  Constant.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import Foundation
import UIKit

struct Constant {
    struct Color {
        static let primaryColor = UIColor(red: 117/255, green: 48/255, blue: 159/255,alpha: 1)
        static let vibesSelectedBgColor = UIColor(hex: "#75309F")
        static let selectedItemTextColor = UIColor(hex: "#F2F2F2")
        static let selectedDrinkColor = UIColor(hex: "#007AFF")
    }
    
    struct Icon {
        static let radioClick = UIImage(named: "blueCheck")
        static let radioIcon = UIImage(named: "radioCirculIcon")
    }
    
    struct String {
        static let confirmInfo = "Please confirm your information"
        static let nameNote = "Providing a different name than the one on your ID might result in the venue denying entry."
        static let confirmBirthDate = "Please confirm date of birth"
        static let over21Info = "By tapping confirm you attest that you are over the age of 21. This information can’t be changed later."
        static let privetOrPublicInfo = "Would you like others to see your account  details?"
        static let changeslaterinfo = "This information can be changed later."
        static let sendReceiptText = "Receipt emailed to rjohnson@gmail.com"
        static let confirm21YearText = "You must be over 21 years old to continue."
    }
}
