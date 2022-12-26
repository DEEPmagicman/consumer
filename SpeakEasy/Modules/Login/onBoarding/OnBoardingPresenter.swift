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
    
    func otpVerifyApi(otp: Int, otpRef: String, complition: @escaping (_ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["otp": otp, "otpRef": otpRef] as [String : Any]
        AFWrapper.postRequest(APIBuilder.share.loginotpVerify(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any]
            else {
                complition(false)
                return
            }
            let user = Currentuser(fromDictionary: userDic)
//            UserDefault.shared.
        
            complition(true)

        } failure: { (error) in
            complition(false)
            print(error ?? "")
        }
    }
    
    func resendOtpApi(otpref: String, complition: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool) -> Void) {
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

}
