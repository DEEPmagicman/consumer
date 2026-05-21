//
//  SettingPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 30/01/23.
//

import Foundation

final class SettingPresenter {
    func changeEmailApi(email: String, completion: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["email": email]
        AFWrapper.postRequest(APIBuilder.changeEmailURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String
            else {
                completion("", "", false, nil)
                return
            }
            let otp = responseDic["otp"] as? String
            completion(otp ?? "", otpref, true, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion("", "", false, err.domain)
                return
            }
            print(error ?? "")
            completion("", "", false, nil)
        }
    }
    
    func changeEmailPhoneVerifyApi(otp: Int, otpRef: String,isForPhone: Bool = false, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        let param = ["otp": otp, "otpRef": otpRef] as [String : Any]
        var url = ""
        if isForPhone  {
            url = APIBuilder.changePhoneOTPVerifyURL
        } else {
            url = APIBuilder.changeEmailOTPVerifyURL
        }
        AFWrapper.postRequest(url, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic as? [String:Any]
            else {
                completion(false, nil)
                return
            }
            let imageDic = userDic["image"] as? [String:Any]
            let user = User(fromDictionary: userDic)
            UserDefault.shared.user = user
            UserDefault.shared.isGuest = false
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["":""])
            print("\(user)")
        
            completion(true, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain)
                return
            }
            completion(false, nil)
            print(error ?? "")
        }
    }
    
    func changeEmailPhoneResendOtpApi(otpref: String,isForPhone: Bool = false, completion: @escaping (_ otp: String?, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        let param = ["otpRef": otpref]
        var url = ""
        if isForPhone {
            url = APIBuilder.changePhoneResendOTPURL
        } else {
            url = APIBuilder.changeEmailResendOTPURL
        }
        AFWrapper.postRequest(url, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String else {
                completion("", "", false, nil)
                return
            }
            completion(responseDic["otp"] as? String, otpref, true, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion("", "", false, err.domain)
                return
            }
            print(error ?? "")
            completion("", "", false, nil)
        }
    }
    
    func changePhoneNumberApi(phone: String,code: String, completion: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        
        let param = ["phone": phone.replacingOccurrences(of: "-", with: ""), "code": code]
        AFWrapper.postRequest(APIBuilder.changePhoneNumURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String
            else {
                completion("", "", false, nil)
                return
            }
            let otp = responseDic["otp"] as? String
            completion(otp ?? "", otpref, true, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion("", "", false, err.domain)
                return
            }
            print(error ?? "")
            completion("", "", false, nil)
        }
    }
    
    func changePasswordApi(oldPass: String, newPass: String, confirmPass: String, completion: @escaping (_ isSuccess: Bool,_ errorMsg: String?) -> Void) {
     
        let param = ["currentPassword": oldPass, "newPassword": newPass, "confirmPassword": confirmPass]
        Loader.show()
        AFWrapper.patchRequest(APIBuilder.changePasswordURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String:Any] else {
                completion(false, nil)
                return
            }
            completion(true, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain)
                return
            }
            print(error ?? "")
            completion(false, nil)
        }
    }
}
