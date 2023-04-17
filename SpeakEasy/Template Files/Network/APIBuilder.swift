//
//  APIbuilder.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation

struct APIBuilder {
    
    static private let baseURL = "https://api.speakeasygo.com"  //"https://speakeasy-stag.cmdev.cc"  
    static private let route = "/consumer"
    static private let auth = "/auth"
    static private let phoneLogin = "/phone-login"
    static private let signup = "/signup"
    static private let OTPVerify = "/otp-verify"
    static private let OTPResend = "/otp-resend"
    static private let login = "/login"
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
    static private let venueBottleCategory = "/venueBottleCategory"
    static private let whoAmI = "/who-am-i"
    static private let changeEmail = "/change-email"
    static private let changePhone = "/change-phone"
    static private let changePassword = "/change-password"
    static private let appClip = "/appclip"
    static private let appClipVenue = "/appClipVenue?include=appClipTicket"
    static private let appClipUser = "/appclip-user"
    static private let payment = "/payment"
    static private let statusSuccess = "/status?status=SUCCESS"
    static private let mvpCity = "/common-data/venueCitys"
    static private let include = "include=%@"
    static private let appleWallet = "/apple-wallet"

    static let getInstagramCode = "https://api.instagram.com/oauth/authorize?client_id=" + Constant.String.InstagramClientId + "&redirect_uri=" + Constant.String.InstagramDirectUri + "&scope=user_profile,user_media&response_type=code"
    static let spotifyAuthUrl = "https://accounts.spotify.com/authorize?response_type=token&client_id=" + APIBuilder.CLIENT_ID + "&scope=" + APIBuilder.SCOPE + "&redirect_uri=" + APIBuilder.REDIRECT_URI + "&show_dialog=false"
    static private let INSTAGRAMTOKEN =  "https://api.instagram.com/oauth/access_token"
    static let getInstagramImages = "https://graph.instagram.com/me/media?fields=id,media_url,media_type,username&access_token=%@"
    static let INSTAGRAMUSERNAME = "https://graph.instagram.com/me/media?fields=username&access_token=%@"
    static let getInstagramChilds = "https://graph.instagram.com/%@/children?fields=id,media_url,media_type&access_token=%@"
    
    static let CLIENT_ID = Constant.String.spotifyClientId
    static let SESSION_KEY = "spotifySessionKey"
    static let REDIRECT_URI = Constant.String.spotifyDirectUri
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
    
    static func eventDetailURL(_ id: String) -> String {
        baseURL + route + event + "/\(id)"
    }
    
    static func bottleListURL(_ id: String) -> String {
        baseURL + route + venueBottleCategory + "/\(id)"
    }
    
    static var whoAmIURL: String {
        baseURL + route + auth + whoAmI
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
    
    static func MVPVenueDetailURL(_ id: String) -> String{
        baseURL + appClip + "/\(id)"
    }
    
    static var MVPVenueListURL: String {
        baseURL + route + venue + appClipVenue + "&city=\(UserDefault.shared.localCity.replacingOccurrences(of: " ", with: "%20"))"
    }
    
    static var createBookingMVPURL: String {
        baseURL + appClipUser
    }
    
    static func addPaymentURL(_ id: String) -> String {
        baseURL + route + payment + "/\(id)"
    }
    
    static func successPaymentURL(_ paymentHistoryId: String, _ id: String) -> String {
        baseURL + route + payment + "/" + paymentHistoryId + "/" + id + statusSuccess
    }
    
    static var mvpCityListURL: String {
        baseURL + mvpCity
    }
    
    static func appClipAppleWallet(_ bookingId: String) -> String {
        baseURL + appClip + "/\(bookingId)" + appleWallet
    }
}

extension String {
    var imageURL: String {
        "https://speakeasy-storage.s3.amazonaws.com/\(self)"
    }
}
