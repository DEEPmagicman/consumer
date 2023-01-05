//
//  APIbuilder.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation

class APIBuilder {
    
    static let share = APIBuilder()
    
    let BASE_URL = "https://speakeasy-stag.cmdev.cc"
    let API_PATH = "/consumer"
    
    private let LoginWithPhone_URl = "/auth/phone-login"
    private let LoginOtpVerify_URL = "/auth/phone-login/otp-verify"
    private let LoginResendOtp_URL = "/auth/phone-login/otp-resend"
    private let signUpWithPhone_URL = "/signup"
    private let signUpOtpVerify_URL = "/signup/otp-verify"
    private let signUpOtpResend_URL = "/signup/otp-resend"
    private let LoginWithEmail_URL = "/auth/login"
    private let userProfile_URl = "/auth/profile"
    private let uploadPhoto_URL = "/upload/uploadFile"
    private let resetEmailPassword = "/auth/forgot-password"
    private let vibesList_URL = "/vibe"
    private let drinkList_URL = "/drink"
    private let socialMediaConnect_URL = "/auth/connect-social"
    private let socialLogin = "/auth/social-login"
    
    static let getInstagramCode = "https://api.instagram.com/oauth/authorize?client_id=" + Constant.String.InstagramClientId + "&redirect_uri=" + Constant.String.InstagramredirectUri + "&scope=user_profile,user_media&response_type=code"
    private let INSTAGRAMTOKEN =  "https://api.instagram.com/oauth/access_token"
    static let getInstagramImages = "https://graph.instagram.com/me/media?fields=id,media_url,media_type,username&access_token=%@"
    static let INSTAGRAMUSERNAME = "https://graph.instagram.com/me/media?fields=username&access_token=%@"
    static let getInstagramChilds = "https://graph.instagram.com/%@/children?fields=id,media_url,media_type&access_token=%@"
    
    func loginWithPhone() -> String {
        return BASE_URL + API_PATH + LoginWithPhone_URl
    }
    
    func loginotpVerify() -> String {
        return BASE_URL + API_PATH + LoginOtpVerify_URL
    }
    
    func loginresendOtp() -> String {
        return BASE_URL + API_PATH + LoginResendOtp_URL
    }
    
    func loginWithEmail() -> String {
        return BASE_URL + API_PATH + LoginWithEmail_URL
    }
    
    func forgotPassword() -> String {
        return BASE_URL + API_PATH + resetEmailPassword
    }
    
    func userProfile() -> String {
        return BASE_URL + API_PATH + userProfile_URl
    }
    
    func signUpWithPhone() -> String {
        return BASE_URL + API_PATH + signUpWithPhone_URL
    }
    
    func signUpOtpVerify() -> String {
        return BASE_URL + API_PATH + signUpOtpVerify_URL
    }
    
    func signUpOtpResend() -> String {
        return BASE_URL + API_PATH + signUpOtpResend_URL
    }
    
    func uploadPhoto() -> String {
        return BASE_URL + uploadPhoto_URL
    }
    
    func vibesList() -> String {
        return BASE_URL + API_PATH + vibesList_URL
    }
    
    func drinksList() -> String {
        return BASE_URL + API_PATH + drinkList_URL
    }
    
    func socialMediaConnection() -> String {
        return BASE_URL + API_PATH + socialMediaConnect_URL
    }
    
    func socialMedialLogin() -> String {
        return BASE_URL + API_PATH + socialLogin
    }
    
    func getInstagramToken() -> String {
        return INSTAGRAMTOKEN
    }
}
