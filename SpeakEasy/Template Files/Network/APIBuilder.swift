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
    private let signUpWithPhone_URL = "signup"
    private let signUpOtpVerify_URL = "/signup/otp-verify"
    private let signUpOtpResend_URL = "/signup/otp-resend"
    private let LoginWithEmail_URL = "/auth/login"
    private let userProfile_URl = "/auth/profile"
    
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
}
