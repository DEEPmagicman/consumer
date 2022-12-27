//
//  OnBoardingPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation

class OnBoardingPresenter {
        
    func loginWithPhoneApi(phonenum: String, code: String, complition: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["phone": phonenum, "code": code]
        AFWrapper.postRequest(APIBuilder.share.loginWithPhone(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String, let otp = responseDic["otp"] as? String
            else {
                
                complition("", "", false)
                return
            }
            complition(otp, otpref, true)

        } failure: { (error) in
            print(error ?? "")
            complition("", "", false)
        }
    }
    
    func loginOtpVerifyApi(otp: Int, otpRef: String, complition: @escaping (_ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["otp": otp, "otpRef": otpRef] as [String : Any]
        AFWrapper.postRequest(APIBuilder.share.loginotpVerify(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
            else {
                complition(false)
                return
            }
            let loginToken = sessionDic["accessToken"] as? String
            UserDefault.shared.loginToken = loginToken
            let user = Currentuser(fromDictionary: userDic)
            UserDefault.shared.user = user
            print("\(user)")
        
            complition(true)

        } failure: { (error) in
            complition(false)
            print(error ?? "")
        }
    }
    
    func loginResendOtpApi(otpref: String, complition: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["otpRef": otpref]
        AFWrapper.postRequest(APIBuilder.share.loginresendOtp(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String, let otp = responseDic["otp"] as? String
            else {
                
                complition("", "", false)
                return
            }
            complition(otp, otpref, true)

        } failure: { (error) in
            print(error ?? "")
            complition("", "", false)
        }
    }
    
    func signUpWithPhoneApi(phonenum: String, code: String, complition: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["phone": phonenum, "code": code]
        AFWrapper.postRequest(APIBuilder.share.signUpWithPhone(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String, let otp = responseDic["otp"] as? String
            else {
                
                complition("", "", false)
                return
            }
            complition(otp, otpref, true)

        } failure: { (error) in
            print(error ?? "")
            complition("", "", false)
        }
    }
    
    func signUpOtpVerifyApi(otp: Int, otpRef: String, complition: @escaping (_ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["otp": otp, "otpRef": otpRef] as [String : Any]
        AFWrapper.postRequest(APIBuilder.share.signUpOtpVerify(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
            else {
                complition(false)
                return
            }
            let loginToken = sessionDic["accessToken"] as? String
            UserDefault.shared.loginToken = loginToken
            let user = Currentuser(fromDictionary: userDic)
            UserDefault.shared.user = user
            print("\(user)")
        
            complition(true)

        } failure: { (error) in
            complition(false)
            print(error ?? "")
        }
    }
    
    func signUpResendOtpApi(otpref: String, complition: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["otpRef": otpref]
        AFWrapper.postRequest(APIBuilder.share.signUpOtpResend(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String, let otp = responseDic["otp"] as? String
            else {
                
                complition("", "", false)
                return
            }
            complition(otp, otpref, true)

        } failure: { (error) in
            print(error ?? "")
            complition("", "", false)
        }
    }
    
    func loginWithEmailApi(email: String, password: String, complition: @escaping (_ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["email": email, "password": password]
        AFWrapper.postRequest(APIBuilder.share.loginWithEmail(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any]
            else {
                complition(false)
                return
            }
            let user = Currentuser(fromDictionary: userDic)
            complition(true)

        } failure: { (error) in
            print(error ?? "")
            complition(false)
        }
    }
    
    func editUserProfileApi(fName: String? = nil, lName: String? = nil,nickName:String? = nil,email:String? = nil,password: String? = nil,dob: String? = nil,gender: String? = nil, complition: @escaping (_ isSuccess: Bool) -> Void) {
        var param: [String: Any] = [:]
        if let fName = fName {
            param["firstName"] = fName
        }
        if let lname = lName {
            param["lastName"] = lname
        }
        if let nickName = nickName {
            param["nickName"] = nickName
        }
        if let email = email {
            param["email"] = email
        }
        if let password = password {
            param["password"] = password
        }
        if let dob = dob {
            param["dob"] = dob
        }
        if let gender = gender {
            param["gender"] = gender
        }

        Loader.show()
        AFWrapper.patchRequest(APIBuilder.share.userProfile(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String:Any]
            else {
                complition(false)
                return
            }
            complition(true)

        } failure: { (error) in
            print(error ?? "")
            complition(false)
        }
    }

}
