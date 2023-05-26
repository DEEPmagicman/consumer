//
//  Constant.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import UIKit

struct Constant {
    struct Color {
        static let primaryColor = UIColor(red: 117/255, green: 48/255, blue: 159/255,alpha: 1)
        static let vibesSelectedBgColor = UIColor(hex: "#75309F")
        static let selectedItemTextColor = UIColor(hex: "#F2F2F2")
        static let selectedDrinkColor = UIColor(hex: "#007AFF")
        static let code7Acolor = UIColor(named: "code7a")
        static let code2Fcolor = UIColor(named: "code2f")
        static let codea1Color = UIColor(named: "codea1")
        static let submiteRequestBtnColor = UIColor(hex: "#0B78FF")
        static let primaryBlue = UIColor(named: "primaryBlue")
        static let purpleColor = UIColor(red: 0.96, green: 0.51, blue: 1.00, alpha: 1.00)
        static let customGray = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.00)
        static let gradientColors = [UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor]
    }
    
    struct Icon {
        static let radioClick = UIImage(named: "blueCheck")
        static let radioIcon = UIImage(named: "radioCirculIcon")
        static let check = UIImage(named: "purpul_Check")
        static let defaultIcon = UIImage(named: "defaultIcon")
        static let maleIdentify = UIImage(named: "maleIdentify_Ic")
        static let femaleIdentify = UIImage(named: "femalIdentify_Ic")
        static let liveCover = UIImage(named: "liveCover")
        static let uploadImage = UIImage(named: "uploadImage")
    }
    
    struct String {
        static let googleClientId = "327697476599-4kbspuivil9hh6vacef3oe2j1u29iu4m.apps.googleusercontent.com"
        static let InstagramClientSecret = "1aa210cc8cf5084ec246c62b7cf68519"
        static let InstagramClientId = "1996312040570930"
        static let spotifyClientId = "7fe9739926f84543abb666bf8aeef274"
        static let confirmInfo = "Please Confirm:"
        static let nameNote = "Providing a different name than the one on your ID might result in the venue denying entry. List any nicknames to avoid any confusion!"
        static let confirmBirthDate = "Please confirm date of birth"
        static let over21Info = "By tapping confirm you attest that you are over the age of 21. This information can’t be changed later."
        static let privetOrPublicInfo = "Would you like others to see your account  details?"
        static let changesLaterInfo = "This information can be changed later."
        static let sendReceiptText = "Receipt emailed to rjohnson@gmail.com"
        static let confirm21YearText = "You must be over 21 years old to continue."
        static let genderList = ["Female", "Male", "Other"]
        static let InstagramDirectUri = "https://speakeasy.com/auth"
        static let spotifyDirectUri = "https://speakeasy.com/sauth"
        static let authorizationCode = "authorization_code"
        static let internetNotConnect = "Internet not connect"
        static let somethingWrong = "Something Went Wrong"
        static let max5FrdString = "you Can Invite Max 5 Friend"
        static let updateWhileAgo = "Updated a While Ago"
        static let updated = "Updated:"
        static let sessionTimeOut = "Your current session has expired, \n Please login again."
        static let enableLocationServices = "Enable Location Services"
        static let notSupported = "Not Supported"
        static let applePayNotSupported = "This device not support Apple Pay, Please choose different Payment Method"
        static let addCardToApplePay = "Add Card to Apple Pay"
        static let addCardToYourApplePayWallet = "Please add a card to your Apple Pay wallet and check again."
        static let defaultSelectedPM = "Apple Pay"
        static let addNewCard = "addNewCard"
        static let venuePolicy = "%@ is a strictly 21+ venue, no minors will be admitted. Visibly intoxicated guests will not be admitted to venue. Security reserves the right to remove any disruptive guests without prior warning."
        static let liveCoverTicket = "Live Cover Ticket"
        static let soldOut = "Sold Out"
        static let saleEnded = "Sale Ended"
        static let salePaused = "Sale Paused"
        static let ticketSellingWillStartAt = "Ticket selling will start at %@"
    }
    
    struct Font {
        static func boldText(size: CGFloat) -> UIFont {
            return UIFont(name: "Poppins-Bold", size: size)!
        }
    }
    
    struct Card {
        static let visa = UIImage(named: "visa")
        static let cardIc = UIImage(named: "cardIc")
        static let applePay = UIImage(named: "applePay")
        static let masterCard = UIImage(named: "mastercard")
        static let amex = UIImage(named: "amex")
        static let discover = UIImage(named: "discover")
        static let diners = UIImage(named: "diners")
        static let jcb = UIImage(named: "jcb")
    }
}
