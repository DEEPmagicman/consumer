//
//  OnBoardingPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import UIKit

final class OnBoardingPresenter {
        
    func loginWithPhoneApi(phonenum: String, code: String, completion: @escaping (_ otp: String?, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        let param = ["phone": phonenum.replacingOccurrences(of: "-", with: ""), "code": code]
        AFWrapper.postRequest(APIBuilder.loginWithPhoneURL, params: param, headers: Header.header()) { response in
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String else {
                completion("", "", false, nil)
                return
            }
            completion(responseDic["otp"] as? String , otpref, true, nil)

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion("", "", false, err.domain)
                return
            }
            print(error ?? "")
            completion("", "", false, nil)
        }
    }
    
    func loginOtpVerifyApi(otp: Int, otpRef: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        let param = ["otp": otp, "otpRef": otpRef] as [String: Any]
        AFWrapper.postRequest(APIBuilder.loginOTPVerifyURL, params: param, headers: Header.header(), shouldForceLogout: false) { response in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String: Any], let sessionDic = responseDic["session"] as? [String: Any] else {
                completion(false, nil)
                return
            }
            let imageDic = userDic["image"] as? [String: Any]
            UserDefault.shared.accessToken = sessionDic["accessToken"] as? String
            UserDefault.shared.refreshToken = sessionDic["refreshToken"] as? String
            UserDefault.shared.isLoggedIn = true
            UserDefault.shared.isGuest = false
            let user = User(fromDictionary: userDic)
            UserDefault.shared.user = user
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["": ""])
            completion(true, nil)

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }
            completion(false, nil)
            print(error ?? "")
        }
    }
    
    func loginResendOtpApi(otpref: String, completion: @escaping (_ otp: String?, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        let param = ["otpRef": otpref]
        AFWrapper.postRequest(APIBuilder.loginResendOTPURL, params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String else {
                completion("", "", false, nil)
                return
            }
            completion(responseDic["otp"] as? String, otpref, true, nil)

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion("", "", false, err.domain)
                return
            }
            print(error ?? "")
            completion("", "", false, nil)
        }
    }
    
    func signUpWithPhoneApi(phonenum: String, code: String, completion: @escaping (_ otp: String?, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        
        let param = ["phone": phonenum.replacingOccurrences(of: "-", with: ""), "code": code]
        AFWrapper.postRequest(APIBuilder.signUpWithPhoneURL, params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String else {
                completion("", "", false, nil)
                return
            }
            completion(responseDic["otp"] as? String, otpref, true, nil)

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion("", "", false, err.domain)
                return
            }
            print(error ?? "")
            completion("", "", false, nil)
        }
    }
    
    func signUpOtpVerifyApi(otp: Int, otpRef: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        let param = ["otp": otp, "otpRef": otpRef] as [String : Any]
        AFWrapper.postRequest(APIBuilder.signUpOTPVerifyURL, params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any] else {
                completion(false, nil)
                return
            }
            let imageDic = userDic["image"] as? [String: Any]
            UserDefault.shared.accessToken = sessionDic["accessToken"] as? String
            UserDefault.shared.refreshToken = sessionDic["refreshToken"] as? String
            UserDefault.shared.isLoggedIn = true
            UserDefault.shared.isGuest = false
            let user = User(fromDictionary: userDic)
            UserDefault.shared.user = user
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["":""])
            completion(true, nil)

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }
            completion(false, nil)
            print(error ?? "")
        }
    }
    
    func signUpResendOtpApi(otpref: String, completion: @escaping (_ otp: String?, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        let param = ["otpRef": otpref]
        AFWrapper.postRequest(APIBuilder.signUpOTPResendURL, params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String else {
                
                completion("", "", false, nil)
                return
            }
            completion(responseDic["otp"] as? String, otpref, true, nil)

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion("", "", false, err.domain)
                return
            }
            print(error ?? "")
            completion("", "", false, nil)
        }
    }
            
    func editUserProfileApi(fName: String? = nil, lName: String? = nil, nickName: String? = nil, email: String? = nil, password: String? = nil, dob: String? = nil, gender: String? = nil, image: ImageDetail? = nil, city: String? = nil, vibeIds: [String]? = nil, drinkIds: [String]? = nil, instagramToken: String? = nil, spotifyToken: String? = nil, isProfileCompleted: Bool? = nil, completion: @escaping (_ isSuccess: Bool, _ errorMsg:String?) -> Void) {
        var param: [String: Any] = [:]
        if let fName = fName, fName != "" {
            param["firstName"] = fName
        }
        if let lname = lName, lname != "" {
            param["lastName"] = lname
        }
        if let nickName = nickName, nickName != "" {
            param["nickName"] = nickName
        }
        if let email = email, email != "" {
            param["email"] = email
        }
        if let password = password, password != "" {
            param["password"] = password
        }
        if let dob = dob, dob != "No date Found" {
            if dob != "" {
                param["dob"] = dob
            }
        }
        if let gender = gender {
            param["gender"] = gender
        }
        if let image = image {
            param["image"] = image.toDictionary()
        }
        if let city = city {
            param["city"] = city
        }
        if let vibeIds = vibeIds {
            param["vibeIds"] = vibeIds
        }
        if let drinkIds = drinkIds {
            param["drinkIds"] = drinkIds
        }
        if let instagramToken = instagramToken {
            param["instagramToken"] = instagramToken
        }
        if let spotifyToken = spotifyToken {
            param["spotifyToken"] = spotifyToken
        }
        if let email = email {
            param["email"] = email
        }
        if let isProfileCompleted = isProfileCompleted {
            param["isProfileCompleted"] = isProfileCompleted
        }
        
        AFWrapper.patchRequest(APIBuilder.userProfileURL, params: param, headers: Header.header()) { response in
            
            guard response is [String: Any] else {
                completion(false,nil)
                return
            }
            completion(true,nil)

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }
            print(error ?? "")
            completion(false,nil)
        }
    }
    
    
    func uploadPhotoApi(image: UIImage, completion: @escaping (_ imgUrl: String, _ isSuccess: Bool) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            completion("", false)
            return
        }
        let param = ["file": image] as [String: Any]
        AFWrapper.multipart(APIBuilder.uploadPhotoURL, fileData: imageData, fileName: "\(UUID().uuidString).jpg", fileParamKey: "file", params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? NSDictionary, let imgUrl = responseDic["Location"] as? String else {
                completion("", false)
                return
            }
            
            completion(imgUrl, true)
        } failure: { error in
            completion("", false)
            print(error ?? "")
        }
    }
    
    func socialMediaConnectAPi(email: String,socialType: String,socialId: String, nonce: String? = nil, firstName: String? = "", lastName: String? = "", completion: @escaping (_ isSuccess: Bool,_ errorMsg: String?) -> Void) {
        
        let tsocialIdParts = socialId.components(separatedBy: ".")
     
        var param = ["email": email, "socialType": socialType, "socialId": socialId]
        if socialType == SocialType.apple.rawValue {
            param["nonce"] = nonce
        }
        if firstName != "" && lastName == "" {
            param["firstName"] = firstName
        } else if firstName == "" && lastName != "" {
            param["lastName"] = firstName
        } else if firstName != "" && lastName != "" {
            param["firstName"] = firstName
            param["lastName"] = lastName
        }

        AFWrapper.patchRequest(APIBuilder.socialMediaConnectURL, params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil)
                return
            }
            completion(true, nil)

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }
            print(error ?? "")
            completion(false, nil)
        }
    }
    
    func socialMediaLoginAPi(email: String,socialType: String, socialId: String, nonce: String? = nil, firstName: String? = "", lastName: String? = "", completion: @escaping (_ isSuccess: Bool, _ errorMsg: String?) -> Void) {
        
        var param = ["email": email, "socialType": socialType, "socialId": socialId]
        if socialType == SocialType.apple.rawValue {
            param["nonce"] = nonce
        }
        
        if firstName != "" && lastName == "" {
            param["firstName"] = firstName
        } else if firstName == "" && lastName != "" {
            param["lastName"] = firstName
        } else if firstName != "" && lastName != "" {
            param["firstName"] = firstName
            param["lastName"] = lastName
        }
        
        Loader.show()
        AFWrapper.postRequest(APIBuilder.socialLoginURL, params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any], let userDic = responseDic["user"] as? [String: Any], let sessionDic = responseDic["session"] as? [String: Any] else {
                completion(false, nil)
                return
            }
            let imageDic = userDic["image"] as? [String: Any]
            UserDefault.shared.accessToken = sessionDic["accessToken"] as? String
            UserDefault.shared.refreshToken = sessionDic["refreshToken"] as? String
            UserDefault.shared.isLoggedIn = true
            UserDefault.shared.isGuest = false
            let user = User(fromDictionary: userDic)
            UserDefault.shared.user = user
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["": ""])
            completion(true, nil)
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }
            print(error ?? "")
            completion(false, nil)
        }
    }
    
    func getCurrentUserDetail(completion: @escaping(_ isSuccess: Bool) -> Void) {
        AFWrapper.getRequest(APIBuilder.whoAmIURL, params: nil, headers: Header.header()) { response in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String: Any], let sessionDic = responseDic["session"] as? [String: Any]? else {
                completion(false)
                return
            }
            let imageDic = userDic["image"] as? [String: Any]
            if let sessionDic = sessionDic {
                UserDefault.shared.accessToken = sessionDic["accessToken"] as? String
                UserDefault.shared.refreshToken = sessionDic["refreshToken"] as? String
            }
            let user = User(fromDictionary: userDic)
            UserDefault.shared.user = user
            if let encryptedUserData = user as? Data,
                let decryptedData = try? decrypt(data: encryptedUserData, key: EncryptKeys.key, iv: EncryptKeys.iv) {
                if let decryptedUser = try? JSONDecoder().decode(User.self, from: decryptedData) {
                    
                } else {
                    print("Decrypted data does not represent a valid User object")
                }
            }

            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["": ""])
            completion(true)
        } failure: { error in
            completion(false)
            print(error ?? "")
        }
    }
    
    static func deleteUser(completion: @escaping(_ isSuccess: Bool, _ errorMsg: String?) -> Void) {
        AFWrapper.deleteRequest(APIBuilder.deleteUserURL, headers: Header.header()) { response in
            completion(true, nil)
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }
            print(error ?? "")
            completion(false, nil)
        }
    }
    
    static func logout(completion: @escaping(_ isSuccess: Bool, _ errorMsg: String?) -> Void) {
        AFWrapper.postRequest(APIBuilder.logoutAPI, headers: Header.header()) { _ in
            completion(true, nil)
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }
            print(error ?? "")
            completion(false, nil)
        }
    }
}
