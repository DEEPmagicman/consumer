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
        static let code7Acolor = UIColor(named: "code7a")
        static let code2Fcolor = UIColor(named: "code2f")
        static let submiteRequestBtnColor = UIColor(hex: "#0B78FF")
    }
    
    struct Icon {
        static let radioClick = UIImage(named: "blueCheck")
        static let radioIcon = UIImage(named: "radioCirculIcon")
        static let applePay = UIImage(named: "applePay")
        static let masterCard = UIImage(named: "masterCard")
        static let check = UIImage(named: "purpul_Check")
        static let defaultIcon = UIImage(named: "defaultIcon")
        static let maleIdentify = UIImage(named: "maleIdentify_Ic")
        static let femaleIdentify = UIImage(named: "femalIdentify_Ic")
    }
    
    struct String {
        static let googleClientId = "971202288158-9gap4p13k19hgr5r257doeqidhdu736o.apps.googleusercontent.com"
        static let InstagramClientSecret = "1aa210cc8cf5084ec246c62b7cf68519"
        static let InstagramClientId = "1996312040570930"
        static let confirmInfo = "Please confirm your information"
        static let nameNote = "Providing a different name than the one on your ID might result in the venue denying entry."
        static let confirmBirthDate = "Please confirm date of birth"
        static let over21Info = "By tapping confirm you attest that you are over the age of 21. This information can’t be changed later."
        static let privetOrPublicInfo = "Would you like others to see your account  details?"
        static let changesLaterInfo = "This information can be changed later."
        static let sendReceiptText = "Receipt emailed to rjohnson@gmail.com"
        static let confirm21YearText = "You must be over 21 years old to continue."
        static let genderList = ["Male", "Female"]
        static let InstagramDirectUri = "https://speakeasy.com/auth"
        static let authorizationCode = "authorization_code"
        static let internetNotConnect = "internet not connect"
        static let somethingWrong = "Something Went Wrong"
        static let max5FrdString = "you Can Invite Max 5 Friend"
    }
    
    struct Font {
        static func boldText(size: CGFloat) -> UIFont {
            return UIFont(name: "Poppins-Bold", size: size)!
        }
    }
}
