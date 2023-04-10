//
//  OnBoardingPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import UIKit

final class OnBoardingPresenter {
        
    func loginWithPhoneApi(phonenum: String, code: String, completion: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["phone": phonenum.replacingOccurrences(of: "-", with: ""), "code": code]
        AFWrapper.postRequest(APIBuilder.loginWithPhoneURL, params: param, headers: Header.header()) { (response) in
            
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
    
    func loginOtpVerifyApi(otp: Int, otpRef: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["otp": otp, "otpRef": otpRef] as [String : Any]
        AFWrapper.postRequest(APIBuilder.loginOTPVerifyURL, params: param, headers: Header.header(), shouldForceLogout: false) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
            else {
                completion(false, nil)
                return
            }
            let imageDic = userDic["image"] as? [String:Any]
            UserDefault.shared.accessToken = sessionDic["accessToken"] as? String
            UserDefault.shared.isLoggedIn = true
            let user = User(fromDictionary: userDic)
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
    
    func loginResendOtpApi(otpref: String, completion: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["otpRef": otpref]
        AFWrapper.postRequest(APIBuilder.loginResendOTPURL, params: param, headers: Header.header()) { (response) in
            
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
    
    func signUpWithPhoneApi(phonenum: String, code: String, completion: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["phone": phonenum.replacingOccurrences(of: "-", with: ""), "code": code]
        AFWrapper.postRequest(APIBuilder.signUpWithPhoneURL, params: param, headers: Header.header()) { (response) in
            
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
    
    func signUpOtpVerifyApi(otp: Int, otpRef: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["otp": otp, "otpRef": otpRef] as [String : Any]
        AFWrapper.postRequest(APIBuilder.signUpOTPVerifyURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
            else {
                completion(false, nil)
                return
            }
            let imageDic = userDic["image"] as? [String:Any]
            UserDefault.shared.accessToken = sessionDic["accessToken"] as? String
            UserDefault.shared.isLoggedIn = true
            let user = User(fromDictionary: userDic)
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
    
    func signUpResendOtpApi(otpref: String, completion: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["otpRef": otpref]
        AFWrapper.postRequest(APIBuilder.signUpOTPResendURL, params: param, headers: Header.header()) { (response) in
            
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
    
    func loginWithEmailApi(email: String, password: String, completion: @escaping (_ isSuccess: Bool,_ errorMsg: String?) -> Void) {
        Loader.show()
        let param = ["email": email, "password": password]
        AFWrapper.postRequest(APIBuilder.loginWithEmailURL, params: param, headers: Header.header(), shouldForceLogout: false) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
            else {
                completion(false, nil)
                return
            }
            let imageDic = userDic["image"] as? [String:Any]
            let user = User(fromDictionary: userDic)
            UserDefault.shared.accessToken = sessionDic["accessToken"] as? String
            UserDefault.shared.isLoggedIn = true
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["":""])
            UserDefault.shared.user = user
            print("\(user)")
            completion(true, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain)
                return
            }
            print(error ?? "")
            completion(false,nil)
        }
    }
    
    func forgotPasswordApi(email: String, completion: @escaping (_ isSuccess: Bool,_ errorMsg: String?) -> Void) {
        Loader.show()
        let param = ["email": email]
        AFWrapper.postRequest(APIBuilder.forgotPasswordURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? NSDictionary
            else {
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
    
    func editUserProfileApi(fName: String? = nil, lName: String? = nil, nickName:String? = nil, email:String? = nil, password: String? = nil, dob: String? = nil, gender: String? = nil, image: ImageDetail? = nil, city: String? = nil, vibeIds: [String]? = nil, drinkIds: [String]? = nil,instagramToken: String? = nil,spotifyToken: String? = nil, completion: @escaping (_ isSuccess: Bool,_ errorMsg:String?) -> Void) {
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
        if let dob = dob, dob != "" {
            param["dob"] = dob
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

        Loader.show()
        AFWrapper.patchRequest(APIBuilder.userProfileURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String:Any]
            else {
                completion(false,nil)
                return
            }
            completion(true,nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain)
                return
            }
            print(error ?? "")
            completion(false,nil)
        }
    }
    
    func uploadPhotoApi(image: UIImage, completion: @escaping (_ imgUrl:String, _ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["file": image] as [String : Any]
        AFWrapper.multipart(APIBuilder.uploadPhotoURL, fileData: image.jpegData(compressionQuality: 1), fileName: "\(UUID().uuidString).jpg", fileParamKey: "file", params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? NSDictionary, let imgUrl = responseDic["Location"] as? String
            else {
                completion("", false)
                return
            }
            completion(imgUrl, true)

        } failure: { (error) in
            completion("", false)
            print(error ?? "")
        }
    }
    
    func getVibesListAPi(from:Int? = 0, completion: @escaping(_ vibeList: [Vibe],_ hasMore: Bool, _ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["skip": from]
        AFWrapper.getRequest(APIBuilder.vibesListURL, params: param as [String : Any], headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String:Any], let vibesArray = responseDic["list"] as? [[String:Any]], let more = responseDic["hasMany"] as? Bool
                    
            else {
                completion([Vibe](), false, false)
                return
            }
            var vibes = [Vibe]()
            vibesArray.forEach {
                vibes.append(Vibe(fromDictionary: $0))
            }
            completion(vibes, more, true)
        } failure: { (error) in
            completion([Vibe](), false, false)
            print(error ?? "")
        }
    }
    
    func getDrinkListAPi(from:Int? = 0, completion: @escaping(_ drinkList: [Drink],_ hasMore: Bool, _ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["skip": from]
        AFWrapper.getRequest(APIBuilder.drinksListURL, params: param as [String : Any], headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String:Any], let drinkArray = responseDic["list"] as? [[String:Any]], let more = responseDic["hasMany"] as? Bool
                    
            else {
                completion([Drink](), false, false)
                return
            }
            var drinks = [Drink]()
            drinkArray.forEach {
                drinks.append(Drink(fromDictionary: $0))
            }
            completion(drinks, more, true)
        } failure: { (error) in
            completion([Drink](), false, false)
            print(error ?? "")
        }
    }
    
    func socialMediaConnectAPi(email: String,socialType: String,socialId: String, nonce: String? = nil, completion: @escaping (_ isSuccess: Bool,_ errorMsg: String?) -> Void) {
     
        var param = ["email": email, "socialType": socialType, "socialId":socialId]
        if socialType == SocialType.apple.rawValue {
            param["nonce"] = nonce
        }

        Loader.show()
        AFWrapper.patchRequest(APIBuilder.socialMediaConnectURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String:Any]
            else {
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
    
    func socialMediaLoginAPi(email: String,socialType: String, socialId: String, nonce: String? = nil, completion: @escaping (_ isSuccess: Bool,_ errorMsg: String?) -> Void) {
        
        var param = ["email": email, "socialType": socialType, "socialId":socialId]
        if socialType == SocialType.apple.rawValue {
            param["nonce"] = nonce
        }
        
        Loader.show()
        AFWrapper.postRequest(APIBuilder.socialLoginURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String:Any], let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
            else {
                completion(false, nil)
                return
            }
            let imageDic = userDic["image"] as? [String:Any]
            UserDefault.shared.accessToken = sessionDic["accessToken"] as? String
            UserDefault.shared.isLoggedIn = true
            let user = User(fromDictionary: userDic)
            UserDefault.shared.user = user
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["":""])
            print("\(user)")
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
    
    func getCityListAPi(from: Int? = 0, searchText: String? = "", completion: @escaping(_ cityList: [City], _ hasMore: Bool, _ isSuccess: Bool) -> Void) {
        if from == 0 {
            Loader.show()
        }
        var param: [String:Any] = [:]
           param["skip"] = from
           param["search_column"] = "name"
           param["countryCode"] = "US"
        if searchText != "" {
            param["search"] = searchText
        }
        AFWrapper.getRequest(APIBuilder.getCityListURL, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String:Any], let cityArray = responseDic["list"] as? [[String:Any]], let more = responseDic["hasMany"] as? Bool
                    
            else {
                completion([City](), false, false)
                return
            }
            var citys = [City]()
            cityArray.forEach {
                citys.append(City(fromDictionary: $0))
            }
            completion(citys, more, true)
        } failure: { (error) in
            completion([City](), false, false)
            print(error ?? "")
        }
    }
    
    func getCurrentUserDetail(completion: @escaping(_ isSuccess: Bool) -> Void) {
            Loader.show()
        AFWrapper.getRequest(APIBuilder.whoAmIURL, params: nil, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
                    
            else {
                completion(false)
                return
            }
            let imageDic = userDic["image"] as? [String:Any]
            UserDefault.shared.accessToken = sessionDic["accessToken"] as? String
            let user = User(fromDictionary: userDic)
            UserDefault.shared.user = user
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["":""])
            print("\(user)")
            
            completion(true)
        } failure: { (error) in
            completion(false)
            print(error ?? "")
        }
    }
}
