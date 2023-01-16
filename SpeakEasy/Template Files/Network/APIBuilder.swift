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
    
    static let getInstagramCode = "https://api.instagram.com/oauth/authorize?client_id=" + Constant.String.InstagramClientId + "&redirect_uri=" + Constant.String.InstagramDirectUri + "&scope=user_profile,user_media&response_type=code"
    static private let INSTAGRAMTOKEN =  "https://api.instagram.com/oauth/access_token"
    static let getInstagramImages = "https://graph.instagram.com/me/media?fields=id,media_url,media_type,username&access_token=%@"
    static let INSTAGRAMUSERNAME = "https://graph.instagram.com/me/media?fields=username&access_token=%@"
    static let getInstagramChilds = "https://graph.instagram.com/%@/children?fields=id,media_url,media_type&access_token=%@"
    
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
}
