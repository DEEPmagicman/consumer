//
//  APIbuilder.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation

struct APIBuilder {
    
    static private var baseURL: String {
        get {
            SharedURL.baseURL
        }
    }
    static private let route = "/consumer"
    static private let auth = "/auth"
    static private let phoneLogin = "/phone-login"
    static private let signup = "/signup"
    static private let OTPVerify = "/otp-verify"
    static private let OTPResend = "/otp-resend"
    static private let login = "/login"
    static private let logout = "/logout"
    static private let refreshToken = "/refresh-token"
    static private let profile = "/profile"
    static private let upload = "/upload"
    static private let uploadFile = "/uploadFile"
    static private let forgotPassword = "/forgot-password"
    static private let vibe = "/vibe"
    static private let drink = "/drink"
    static private let connectSocial = "/connect-social"
    static private let socialLogin = "/social-login"
    static private let city = "/common-data/city"
    static private let venue = "/venue"
    static private let event = "/event"
    static private let tickets = "/tickets"
    static private let venueBottleCategory = "/venueBottleCategory"
    static private let whoAmI = "/who-am-i"
    static private let changeEmail = "/change-email"
    static private let changePhone = "/change-phone"
    static private let changePassword = "/change-password"
    static private let cover = "/cover"
    static private let coverVenue = "/CoverVenue?include=coverTicket&"
    static private let payment = "/payment"
    static private let statusSuccess = "/status?status=SUCCESS"
    static private let mvpCity = "/common-data/venueCitys"
    static private let include = "include=%@"
    static private let appleWallet = "/apple-wallet"
    static private let method = "/method"
    static private let ticketBooking = "/ticket-booking"
    static private let past = "/past"
    static private let upcoming = "/upcoming"
    static private let booking = "/booking"
    static private let freeTicket = "/free-booking"
    static private let recommendedEvents = "/recommended-events"
    static private let deleteAccount = "/delete-account"
    static private let inviteLink = "/invite-link"
    static private let redeem = "/redeem"
    static private let redirect = "/redirect"
    static private let addOns = "/add-ons"
    static private let status = "/status"
    static private let deepLink = "/deep-link"
    static private let checkin = "/checkin"
    static private let question = "/question"
    static private let answer = "/answer"
    static private let barTab = "/bar-tab"
    static private let payments = "/payments"
    static private let complete = "/complete"
    static private let paymentDetails = "/payment-details"
    static private let attendees = "/attendees"
    static private let seatingAreas = "/seating-areas"
    static private let applyCode = "/apply-code"
    static private let removeCode = "/remove-code"
    static private let ticket = "/ticket"
    static private let links = "/links"
    static private let faq = "/faq"
    
    static let getInstagramCode = "https://api.instagram.com/oauth/authorize?client_id=" + Constant.String.InstagramClientId + "&redirect_uri=" + Constant.String.InstagramDirectUri + "&scope=user_profile,user_media&response_type=code"
    static let spotifyAuthUrl = "https://accounts.spotify.com/authorize?response_type=token&client_id=" + APIBuilder.clientId + "&scope=" + APIBuilder.SCOPE + "&redirect_uri=" + APIBuilder.redirectURI + "&show_dialog=false"
    static private let INSTAGRAMTOKEN =  "https://api.instagram.com/oauth/access_token"
    static let getInstagramImages = "https://graph.instagram.com/me/media?fields=id,media_url,media_type,username&access_token=%@"
    static let INSTAGRAMUSERNAME = "https://graph.instagram.com/me/media?fields=username&access_token=%@"
    static let getInstagramChilds = "https://graph.instagram.com/%@/children?fields=id,media_url,media_type&access_token=%@"
    
    static let clientId = Constant.String.spotifyClientId
//    static let SESSION_KEY = "spotifySessionKey"
    static let redirectURI = Constant.String.spotifyDirectUri
    static let SCOPE = "user-read-email"
    static let spotifyURL = "https://api.spotify.com/v1/me"
    
    static var loginWithPhoneURL: String {
        baseURL + route + auth + phoneLogin
    }
    
    static var loginOTPVerifyURL: String {
        baseURL + route + auth + phoneLogin + OTPVerify
    }
    
    static var loginResendOTPURL: String {
        baseURL + route + auth + phoneLogin + OTPResend
    }
    
    static var loginWithEmailURL: String {
        baseURL + route + auth + login
    }
    
    static var logoutAPI: String {
        baseURL + route + auth + logout
    }
    
    static var refreshTokenAPI: String {
        baseURL + route + auth + refreshToken
    }
    
    static var forgotPasswordURL: String {
        baseURL + route + auth + forgotPassword
    }
    
    static var userProfileURL: String {
        baseURL + route + auth + profile
    }
    
    static var signUpWithPhoneURL: String {
        baseURL + route + signup
    }
    
    static var signUpOTPVerifyURL: String {
        baseURL + route + signup + OTPVerify
    }
    
    static var signUpOTPResendURL: String {
        baseURL + route + signup + OTPResend
    }
    
    static var uploadPhotoURL: String {
        baseURL + upload + uploadFile
    }
    
    static var vibesListURL: String {
        baseURL + route + vibe
    }
    
    static var drinksListURL: String {
        baseURL + route + drink
    }
    
    static var socialMediaConnectURL: String {
        baseURL + route + auth + connectSocial
    }
    
    static var socialLoginURL: String {
        baseURL + route + auth + socialLogin
    }
    
    static var deleteUserURL: String {
        baseURL + route + auth + deleteAccount
    }
    
    static var getInstagramToken: String {
        INSTAGRAMTOKEN
    }
    
    static var getCityListURL: String {
        baseURL + city
    }
    
    static var venueURL: String {
        baseURL + route + venue
    }
    
    static var eventURL: String {
        baseURL + route + event
    }
    
    static func eventURL(includes: [String]) -> String {
        baseURL + route + event + "?" + includes.map { String(format: "include=%@", $0) }.joined(separator: "&")
    }
        
    static func seatingAreasURL(
        eventId: String,
        includes: [String] = [],
        take: Int = 50,
        skip: Int = 0,
        page: Int = 1,
        orderBy: String = "order|asc"
    ) -> String {
        
        let base = SharedURL.tableBaseURL + route  + event + "/\(eventId)" + seatingAreas
        
        var queryItems: [String] = []
        
        queryItems += includes.map { "include=\($0)" }
        queryItems.append("take=\(take)")
        queryItems.append("skip=\(skip)")
        queryItems.append("page=\(page)")
        queryItems.append("orderBy=\(orderBy.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        
        return base + "?" + queryItems.joined(separator: "&")
    }
    
    static func seatingAreasBookingCreateURL(
        eventId: String,
        includes: [String] = []
    ) -> String {

        let base = SharedURL.tableBaseURL + route + event + "/\(eventId)" + seatingAreas + "/booking-create"

        guard !includes.isEmpty else { return base }

        let query = includes
            .map { "include=\($0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        return base + "?" + query
    }
    
    static func seatingAreaApplyCode(
        eventId: String
    ) -> String {
        let base = SharedURL.tableBaseURL + route + event + "/\(eventId)" + seatingAreas + applyCode
        return base
    }
    
    static func seatingAreaRemoveCode(eventId: String) -> String {
        return SharedURL.tableBaseURL + route + event + "/\(eventId)" + seatingAreas + removeCode
    }
    
    static func reservationRequestURL() -> String {
        return SharedURL.tableBaseURL + route + "/reservation-request"
    }
    
    static func layoutURL(date: String) -> String {
        let base = SharedURL.tableBaseURL + "/consumer/layout"
        let qry = "date=\(date.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        return base + "?" + qry
    }
    
    static func ticketLinksURL(eventId: String) -> String {
        return SharedURL.baseURL + route + event + "/" + eventId + ticket + links
    }
    
    static func faqsURL(eventId: String) -> String {
        return SharedURL.baseURL + route + event + "/" + eventId + faq
    }
    
    static var recommendedEventURL: String {
        baseURL + route + event + recommendedEvents
    }

    static func eventDetailURL(_ id: String) -> String {
        baseURL + route + event + "/\(id)"
    }
    
    static func eventAttendeesURL(_ id: String) -> String {
        return baseURL + "/v2" + route + event + "/\(id)/attendees"
    }

    static func getTicketPasswordAPI(_ eventId: String) -> String {
        baseURL + route + event + "/\(eventId)" + tickets
    }
    
    static func bottleListURL(_ id: String) -> String {
        baseURL + route + venueBottleCategory + "/\(id)"
    }
    
    static func deepLinkURL(_ id: String) -> String {
        baseURL + route + deepLink + "/\(id)"
    }
    
    static func inviteLinkURL(_ id: String) -> String {
        baseURL + route + inviteLink + "/\(id)"
    }
    
    static func inviteRedeemURL(_ id: String) -> String {
        baseURL + route + inviteLink + "/\(id)" + redeem
    }
    
    static var whoAmIURL: String {
        baseURL + route + auth + whoAmI + "?include=image"
    }
    
    static var changeEmailURL: String {
        baseURL + route + auth + changeEmail
    }
    
    static var changeEmailOTPVerifyURL: String {
        baseURL + route + auth + changeEmail + OTPVerify
    }
    
    static var changeEmailResendOTPURL: String {
        baseURL + route + auth + changeEmail + OTPResend
    }
    
    static var changePhoneNumURL: String {
        baseURL + route + auth + changePhone
    }
    
    static var changePhoneOTPVerifyURL: String {
        baseURL + route + auth + changePhone + OTPVerify
    }
    
    static var changePhoneResendOTPURL: String {
        baseURL + route + auth + changePhone + OTPResend
    }
    
    static var changePasswordURL: String {
        baseURL + route + auth + changePassword
    }
    
    static func MVPVenueDetailURL(_ id: String) -> String {
        baseURL + route + cover + "/\(id)"
    }
    
    static var MVPVenueListURL: String {
        baseURL + route + venue + coverVenue + "&city=\(UserDefault.shared.localCity.replacingOccurrences(of: " ", with: "%20"))"
    }
    
    static var MVPVenueURL: String {
        baseURL + route  + venue + "?include=venueAttachment&include=venueHours" + "&city=\(UserDefault.shared.localCity.replacingOccurrences(of: " ", with: "%20"))"
    }
    
    static func getBookingURL(_ bookingId: String) -> String {
        baseURL + route + booking + "/\(bookingId)"
    }
    
    static func addOnBookingAPI(_ bookingId: String) -> String {
        baseURL + route + addOns + "/\(bookingId)"
    }
    
    static var createCoverBookingURL: String {
        baseURL + route + cover + ticketBooking
    }

    static var createCoverFreeBooing: String {
        baseURL + route + booking + freeTicket
    }

    static var createEventBookingURL: String {
        baseURL + route + event + ticketBooking
    }
    
    static var upcomingTicketsURL: String {
          baseURL + route + booking + upcoming + "?include=bookingHasItem&include=venue.venueAttachment&include=venue.logo"
      }
    
    static var pastTicketsURL: String {
        baseURL + route + booking + past
    }
    
    static func addPaymentURL(_ id: String) -> String {
        baseURL + route + payment + "/\(id)"
    }
    
    static func addEventPaymentURL(_ id: String) -> String {
        baseURL + "/v2" + route + payment + "/\(id)"
    }
    
    static func successPaymentURL(_ paymentHistoryId: String, _ id: String, paymentFrom: String? = nil) -> String {
        var url = baseURL + route + payment + "/" + "\(paymentHistoryId)" + "/" + "\(id)" + statusSuccess
        if let paymentFrom = paymentFrom {
            url += "&paymentType=\(paymentFrom.replacingOccurrences(of: " ", with: "%20"))"
        }
        return url
    }
    
    static func successAddOnsPaymentURL(_ bookingId: String) -> String {
        return baseURL + route + payment + addOns  + "/" + bookingId + statusSuccess
    }
    
    static var mvpCityListURL: String {
        baseURL + mvpCity
    }
    
    static func appClipAppleWallet(_ bookingId: String) -> String {
        baseURL + cover + "/\(bookingId)" + appleWallet
    }
    
    static func eventAppleWallet(_ bookingId: String) -> String {
        baseURL + route + event + "/\(bookingId)" + appleWallet
    }
    
    static func customerMethod(_ customerId: String) -> String {
        baseURL + route + payment + method + "/\(customerId)"
    }
    
    static func deleteMethod(_ customerId: String, methodId: String) -> String {
        baseURL + route + payment + method + "/\(customerId)" + "/\(methodId)"
    }
    
    static var freeEventTicketURL: String {
        baseURL + route + event + freeTicket
    }
    
    static func cancelBooking(_ bookingId: String) -> String {
        baseURL + route + event + "/\(bookingId)" + redirect + ticketBooking
    }
    
    static var getAddOnsAPI: String {
        baseURL + route + addOns
    }
    
    static var addOnsPaymentIntent: String {
        baseURL + route + payment + addOns
    }
    
    static var eventCheckInAPI: String {
        baseURL + route + booking + tickets + checkin
    }
    
    static func getEventQuestion(_ eventUniqueId: String) -> String {
        baseURL + route + event + "/\(eventUniqueId)" + question
    }
    
    static func postEventQueAns(_ eventUniqueId: String) -> String {
        baseURL + route + event + "/\(eventUniqueId)" + question + answer
    }
    
    static var barTabAPI: String {
        baseURL + route + barTab
    }
    
    static func barTabPaymentComplete(barId: String, paymentId: String) -> String {
        baseURL + route + barTab + "/\(barId)" + payments + "/\(paymentId)" + complete
    }
    
    static func barTabPaymentDetails(posCheckId: String) -> String {
        baseURL + route + barTab + "/\(posCheckId)" + paymentDetails
    }
}

extension String {
    var imageURL: String {
        "\(SharedURL.amazonStorage)\(self)"
    }
}

extension APIBuilder {
    static var webBaseURL: String {
        get {
            SharedURL.webBaseURL
        }
    }
    static let privacyConsumerURL = "\(webBaseURL)/privacy-consumer"
    static let termsConsumerURL = "\(webBaseURL)/terms-consumer"
    static let supportURL = "\(webBaseURL)/support"
    static let eventWebURL = "\(webBaseURL)/%@/%@?eid=%@"
    static let eventLink = "\(webBaseURL)/event/%@"
    static let venueWebURL = "\(webBaseURL)/%@?vid=%@"
    static let invitationURL = "\(webBaseURL)?L=%@"
    static let openBarTab = "\(webBaseURL)/%@/bar-tab/%@"
}
