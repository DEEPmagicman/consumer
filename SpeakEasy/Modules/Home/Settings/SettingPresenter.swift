//
//  SettingPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 30/01/23.
//

import Foundation
import UIKit

final class SettingPresenter {
    func changeEmailApi(email: String, completion: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["email": email]
        AFWrapper.postRequest(APIBuilder.changeEmailURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String, let otp = responseDic["otp"] as? String
            else {
                completion("", "", false, nil)
                return
            }
            completion(otp, otpref, true, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion("", "", false, err.domain)
                return
            }
            print(error ?? "")
            completion("", "", false, nil)
        }
    }
    
    func changeEmailVerifyApi(otp: Int, otpRef: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["otp": otp, "otpRef": otpRef] as [String : Any]
        AFWrapper.postRequest(APIBuilder.changeEmailOtpVerifyURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic as? [String:Any]
            else {
                completion(false, nil)
                return
            }
            let imageDic = userDic["image"] as? [String:Any]
            let user = Currentuser(fromDictionary: userDic)
            UserDefault.shared.user = user
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
    
    func changeEmailResendOtpApi(otpref: String, completion: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["otpRef": otpref]
        AFWrapper.postRequest(APIBuilder.changeEmailResendOtpURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String, let otp = responseDic["otp"] as? String
            else {
                completion("", "", false, nil)
                return
            }
            completion(otp, otpref, true, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion("", "", false, err.domain)
                return
            }
            print(error ?? "")
            completion("", "", false, nil)
        }
    }
}
