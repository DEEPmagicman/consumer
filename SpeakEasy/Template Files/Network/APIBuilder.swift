//
//  APIbuilder.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation

struct APIBuilder {
    
    static private let baseURL = "https://speakeasy-stag.cmdev.cc"
    static private let route = "/consumer"
    static private let loginWithPhone = "/auth/phone-login"
    static private let loginOTPVerify = "/auth/phone-login/otp-verify"
    static private let loginResendOTP = "/auth/phone-login/otp-resend"
    static private let signUpWithPhone = "/signup"
    static private let signUpOTPVerify = "/signup/otp-verify"
    static private let signUpOTPResend = "/signup/otp-resend"
    static private let loginWithEmail = "/auth/login"
    static private let userProfile = "/auth/profile"
    static private let uploadPhoto = "/upload/uploadFile"
    static private let resetEmailPassword = "/auth/forgot-password"
    static private let vibesList = "/vibe"
    static private let drinkList = "/drink"
    static private let socialMediaConnect = "/auth/connect-social"
    static private let socialLogin = "/auth/social-login"
    static private let cityList = "/common-data/city"
    static private let venue = "/venue"
    static private let event = "/event"
    static private let bottleList = "/manager/venue-bottle-category"
    static private let whoAmI = "/auth/who-am-i"
    static private let changeEmail = "/auth/change-email"
    static private let changeEmailOtpVerify = "/auth/change-email/otp-verify"
    static private let changeEmailResendOtp = "/auth/change-email/otp-resend"
    static let include = "?include=%@"

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
        baseURL + route + loginWithPhone
    }
    
    static var loginOTPVerifyURL: String {
        baseURL + route + loginOTPVerify
    }
    
    static var loginResendOTPURL: String {
        baseURL + route + loginResendOTP
    }
    
    static var loginWithEmailURL: String {
        baseURL + route + loginWithEmail
    }
    
    static var forgotPasswordURL: String {
        baseURL + route + resetEmailPassword
    }
    
    static var userProfileURL: String {
        baseURL + route + userProfile
    }
    
    static var signUpWithPhoneURL: String {
        baseURL + route + signUpWithPhone
    }
    
    static var signUpOTPVerifyURL: String {
        baseURL + route + signUpOTPVerify
    }
    
    static var signUpOTPResendURL: String {
        baseURL + route + signUpOTPResend
    }
    
    static var uploadPhotoURL: String {
        baseURL + uploadPhoto
    }
    
    static var vibesListURL: String {
        baseURL + route + vibesList
    }
    
    static var drinksListURL: String {
        baseURL + route + drinkList
    }
    
    static var socialMediaConnectURL: String {
        baseURL + route + socialMediaConnect
    }
    
    static var socialLoginURL: String {
        baseURL + route + socialLogin
    }
    
    static var getInstagramToken: String {
        INSTAGRAMTOKEN
    }
    
    static var getCityListURL: String {
        baseURL + cityList
    }
    
    static var venueURL: String {
        baseURL + route + venue
    }
    
    static var eventURL: String {
        baseURL + route + event
    }
    
    static var bottleListURL: String {
        baseURL + bottleList
    }
    
    static var whoAmIURL: String {
        baseURL + route + whoAmI
    }
    
    static var changeEmailURL: String {
        baseURL + route + changeEmail
    }
    
    static var changeEmailOtpVerifyURL: String {
        baseURL + route + changeEmailOtpVerify
    }
    
    static var changeEmailResendOtpURL: String {
        baseURL + route + changeEmailResendOtp
    }
}
