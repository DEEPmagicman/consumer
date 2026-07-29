//
//  Constant.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import UIKit

struct Constant {
    
    struct Color {
        static let code7Acolor = UIColor(named: "code7a")
        static let primaryBlue = UIColor(named: "primaryBlue")
        static let purpleColor = UIColor(red: 0.96, green: 0.51, blue: 1.00, alpha: 1.00)
        static let customGray = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.00)
        static let backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.00)
        static let textLabelColor = UIColor(red: 0.63, green: 0.63, blue: 0.63, alpha: 1.00)
    }
    
    struct Icon {
        static let liveCover = UIImage(named: "liveCover")
        static let uploadImage = UIImage(named: "appLogo")
        static let defaultProfile = UIImage(named: "default-profile")
        static let checkedIcon = UIImage(named: "checkedIcon")
        static let uncheckedIcon = UIImage(named: "uncheckedIcon")
    }
    
    struct String {
        static let googleClientId = "327697476599-4kbspuivil9hh6vacef3oe2j1u29iu4m.apps.googleusercontent.com"
        static let InstagramClientSecret = "1aa210cc8cf5084ec246c62b7cf68519"
        static let InstagramClientId = "1996312040570930"
        static let spotifyClientId = "7fe9739926f84543abb666bf8aeef274"
        static let confirmInfo = "Please Confirm:"
        static let nameNote = "Providing a different name than the one on your ID might result in the partner denying entry. List any nicknames to avoid any confusion!"
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
        static let venuePolicy = "%@ is a strictly 21+ partner, no minors will be admitted. Visibly intoxicated guests will not be admitted to partner. Security reserves the right to remove any disruptive guests without prior warning."
        static let liveCoverTicket = "Live Cover Ticket"
        static let liveCoverTickets = "Live Cover Tickets"
        static let upSellTicket = "Upsell Ticket"
        static let soldOut = "Sold Out"
        static let saleEnded = "Sale Ended"
        static let salePaused = "Sale Paused"
        static let ticketSellingWillStartAt = "Ticket selling will start at %@"
        static let checkoutTextEvent = "By buying the ticket you agree to the terms of service and privacy policy. Entry is subject to doorman discretion."
        static let checkoutTextCover = "By buying the ticket you agree to the terms of service and privacy policy. Entry is subject to doorman discretion. Patrons must adhere to partner dress code. Cover tickets expire in 2 hours after time of purchase. Only purchase tickets at the partner or immediately upon arrival."
//        static let coverTicketText = "Cover tickets expire in 2 hours after time of purchase."
        static let compedFreeTicket = "Comped Free Ticket"
        static let enjoyYourFreeTicket = "Enjoy your free ticket!"
        static let dotDoorsOpenAt = "• Doors open at"
        static let dash = "-"
        static let tableReservation = "Table Reservation"
        static let maxTicketSelectionReached = "Max ticket selection reached"
        static let skipAndContinueBtnTitle = "SKIP THIS & CONTINUE TO CHECKOUT"
        static let skipAndGetMyFreeTicket = "SKIP THIS & GET MY FREE TICKET"
        static let continueBtnTitle = "CONTINUE TO CHECKOUT"
    }
    
    struct Font {
        static func boldText(size: CGFloat) -> UIFont {
            return UIFont(name: "Poppins-Bold", size: size)!
        }
        
        static func poppinsMedium(size: CGFloat) -> UIFont {
            return UIFont(name: "Poppins-Medium", size: size)!
        }
        
        static func poppinsRegular(size: CGFloat) -> UIFont {
            return UIFont(name: "Poppins-Regular", size: size)!
        }
        
        static func interRegular(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter-Regular", size: size)!
        }
        
        static func interMedium(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter-Medium", size: size)!
        }
        
        static func interSemiBold(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter-SemiBold", size: size)!
        }
        
        static func interBold(size: CGFloat) -> UIFont {
            return UIFont(name: "Inter-Bold", size: size)!
        }
        
        static func geistRegular(size: CGFloat) -> UIFont {
            return AppFont.font(weight: .regular, size: size)
        }
        
        static func geistMedium(size: CGFloat) -> UIFont {
            return AppFont.font(weight: .medium, size: size)
        }
        
        static func geistSemiBold(size: CGFloat) -> UIFont {
            return AppFont.font(weight: .semibold, size: size)
        }
        
        static func geistBold(size: CGFloat) -> UIFont {
            return AppFont.font(weight: .bold, size: size)
        }
        
        static func geistExtraBold(size: CGFloat) -> UIFont {
            return AppFont.font(weight: .extraBold, size: size)
        }
        
        static func geistThin(size: CGFloat) -> UIFont {
            return AppFont.font(weight: .thin, size: size)
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
    
    static var venueTimeZone: TimeZone? {
        TimeZone(identifier: "america/chicago".capitalized)
    }
    
    static var venueTimeZoneWithOffset: TimeZone? {
        TimeZone(secondsFromGMT: ((venueTimeZone?.secondsFromGMT() ?? 0) - 28800))
    }
    
    static func venueTodayDate(_ format: DateFormat = .YYYYMMDD) -> Swift.String {
        Date().toString(dateFormat: format, timeZone: Constant.venueTimeZone)
    }
}

extension String {
    var withEmptyPlaceHolder: String {
        if self.removeWhitespaces().isEmpty == true {
            return Constant.String.dash
        }
        return self
    }
}
