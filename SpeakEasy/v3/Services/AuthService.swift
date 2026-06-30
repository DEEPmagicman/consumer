//
//  AuthService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 02/06/26.
//

import Foundation

final class AuthService {

    // MARK: - Login

    func sendLoginOTP(
        phone: String,
        code: String,
        completion: @escaping (_ otp: String?, _ otpRef: String, _ isSuccess: Bool, _ errorMsg: String?) -> Void
    ) {

        let params = [
            "phone": phone.replacingOccurrences(of: "-", with: ""),
            "code": code
        ]

        AFWrapper.postRequest(
            APIBuilder.loginWithPhoneURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let otpRef = responseDic["otpRef"] as? String
            else {
                completion(nil, "", false, nil)
                return
            }

            completion(
                responseDic["otp"] as? String,
                otpRef,
                true,
                nil
            )

        } failure: { error in

            if let err = error as? NSError, err.code == 0 {
                completion(nil, "", false, err.domain)
                return
            }

            completion(nil, "", false, nil)
        }
    }

    func verifyLoginOTP(
        otp: String,
        otpRef: String,
        completion: @escaping (_ isSuccess: Bool, _ errorMsg: String?) -> Void
    ) {

        let params: [String: Any] = [
            "otp": otp,
            "otpRef": otpRef
        ]

        AFWrapper.postRequest(
            APIBuilder.loginOTPVerifyURL,
            params: params,
            headers: Header.header(),
            shouldForceLogout: false
        ) { response in

            guard
                let responseDic = response as? NSDictionary,
                let userDic = responseDic["user"] as? [String: Any],
                let sessionDic = responseDic["session"] as? [String: Any]
            else {
                completion(false, nil)
                return
            }

            self.saveUserSession(
                userDic: userDic,
                sessionDic: sessionDic
            )

            completion(true, nil)

        } failure: { error in

            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }

            completion(false, nil)
        }
    }

    func resendLoginOTP(
        otpRef: String,
        completion: @escaping (_ otp: String?, _ otpRef: String, _ isSuccess: Bool, _ errorMsg: String?) -> Void
    ) {

        AFWrapper.postRequest(
            APIBuilder.loginResendOTPURL,
            params: ["otpRef": otpRef],
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let otpRef = responseDic["otpRef"] as? String
            else {
                completion(nil, "", false, nil)
                return
            }

            completion(
                responseDic["otp"] as? String,
                otpRef,
                true,
                nil
            )

        } failure: { error in

            if let err = error as? NSError, err.code == 0 {
                completion(nil, "", false, err.domain)
                return
            }

            completion(nil, "", false, nil)
        }
    }

    // MARK: - Signup

    func sendSignupOTP(
        phone: String,
        code: String,
        completion: @escaping (_ otp: String?, _ otpRef: String, _ isSuccess: Bool, _ errorMsg: String?) -> Void
    ) {

        let params = [
            "phone": phone.replacingOccurrences(of: "-", with: ""),
            "code": code
        ]

        AFWrapper.postRequest(
            APIBuilder.signUpWithPhoneURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let otpRef = responseDic["otpRef"] as? String
            else {
                completion(nil, "", false, nil)
                return
            }

            completion(
                responseDic["otp"] as? String,
                otpRef,
                true,
                nil
            )

        } failure: { error in

            if let err = error as? NSError, err.code == 0 {
                completion(nil, "", false, err.domain)
                return
            }

            completion(nil, "", false, nil)
        }
    }

    func verifySignupOTP(
        otp: String,
        otpRef: String,
        completion: @escaping (_ isSuccess: Bool, _ errorMsg: String?) -> Void
    ) {

        let params: [String: Any] = [
            "otp": otp,
            "otpRef": otpRef
        ]

        AFWrapper.postRequest(
            APIBuilder.signUpOTPVerifyURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? NSDictionary,
                let userDic = responseDic["user"] as? [String: Any],
                let sessionDic = responseDic["session"] as? [String: Any]
            else {
                completion(false, nil)
                return
            }

            self.saveUserSession(
                userDic: userDic,
                sessionDic: sessionDic
            )

            completion(true, nil)

        } failure: { error in

            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }

            completion(false, nil)
        }
    }

    func resendSignupOTP(
        otpRef: String,
        completion: @escaping (_ otp: String?, _ otpRef: String, _ isSuccess: Bool, _ errorMsg: String?) -> Void
    ) {

        AFWrapper.postRequest(
            APIBuilder.signUpOTPResendURL,
            params: ["otpRef": otpRef],
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let otpRef = responseDic["otpRef"] as? String
            else {
                completion(nil, "", false, nil)
                return
            }

            completion(
                responseDic["otp"] as? String,
                otpRef,
                true,
                nil
            )

        } failure: { error in

            if let err = error as? NSError, err.code == 0 {
                completion(nil, "", false, err.domain)
                return
            }

            completion(nil, "", false, nil)
        }
    }

    // MARK: - User
    
    func fetchCurrentUser(completion: @escaping (_ isSuccess: Bool) -> Void) {

        AFWrapper.getRequest(
            APIBuilder.whoAmIURL,
            params: nil,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? NSDictionary,
                let userDic = responseDic["user"] as? [String: Any]
            else {
                completion(false)
                return
            }

            let sessionDic = responseDic["session"] as? [String: Any]
            let imageDic = userDic["consumerUserImage"] as? [String: Any]

            if let sessionDic {

                UserDefault.shared.accessToken =
                    sessionDic["accessToken"] as? String

                UserDefault.shared.refreshToken =
                    sessionDic["refreshToken"] as? String
            }

            let user = User(fromDictionary: userDic)

            UserDefault.shared.user = user

            UserDefault.shared.user?.image =
            ImageDetail(fromDictionary: imageDic ?? [:])
            
            completion(true)
            
        } failure: { error in
            
            print(error ?? "")
            completion(false)
        }
    }
    
    func logout(
        completion: @escaping (_ isSuccess: Bool, _ errorMsg: String?) -> Void
    ) {
        
        AFWrapper.postRequest(
            APIBuilder.logoutAPI,
            headers: Header.header()
        ) { _ in
            
            completion(true, nil)
            
        } failure: { error in
            
            if let err = error as? NSError,
               err.code == 0 {
                
                completion(false, err.domain)
                return
            }
            
            completion(false, nil)
        }
    }
    
    func deleteAccount(
        completion: @escaping (_ isSuccess: Bool, _ errorMsg: String?) -> Void
    ) {
        
        AFWrapper.deleteRequest(
            APIBuilder.deleteUserURL,
            headers: Header.header()
        ) { _ in
            
            completion(true, nil)
            
        } failure: { error in
            
            if let err = error as? NSError,
               err.code == 0 {
                
                completion(false, err.domain)
                return
            }
            
            completion(false, nil)
        }
    }
    
    // MARK: - Helper

    private func saveUserSession(
        userDic: [String: Any],
        sessionDic: [String: Any]
    ) {

        let imageDic = userDic["consumerUserImage"] as? [String: Any]

        UserDefault.shared.accessToken = sessionDic["accessToken"] as? String
        UserDefault.shared.refreshToken = sessionDic["refreshToken"] as? String
        UserDefault.shared.isLoggedIn = true
        UserDefault.shared.isGuest = false

        let user = User(fromDictionary: userDic)
        UserDefault.shared.user = user
        UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? [:])
    }
}
