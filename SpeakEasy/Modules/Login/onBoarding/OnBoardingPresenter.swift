//
//  OnBoardingPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation
import UIKit

class OnBoardingPresenter {
        
    func loginWithPhoneApi(phonenum: String, code: String, complition: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["phone": phonenum, "code": code]
        AFWrapper.postRequest(APIBuilder.share.loginWithPhone(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String, let otp = responseDic["otp"] as? String
            else {
                
                complition("", "", false, nil)
                return
            }
            complition(otp, otpref, true, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition("", "", false, err.domain)
                return
            }
            print(error ?? "")
            complition("", "", false, nil)
        }
    }
    
    func loginOtpVerifyApi(otp: Int, otpRef: String, complition: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["otp": otp, "otpRef": otpRef] as [String : Any]
        AFWrapper.postRequest(APIBuilder.share.loginotpVerify(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
            else {
                complition(false, nil)
                return
            }
            let imageDic = userDic["image"] as? [String:Any]
            let loginToken = sessionDic["accessToken"] as? String
            UserDefault.shared.loginToken = loginToken
            let user = Currentuser(fromDictionary: userDic)
            UserDefault.shared.user = user
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["":""])
            print("\(user)")
        
            complition(true,nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition(false, err.domain)
                return
            }
            complition(false,nil)
            print(error ?? "")
        }
    }
    
    func loginResendOtpApi(otpref: String, complition: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["otpRef": otpref]
        AFWrapper.postRequest(APIBuilder.share.loginresendOtp(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String, let otp = responseDic["otp"] as? String
            else {
                
                complition("", "", false,nil)
                return
            }
            complition(otp, otpref, true,nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition("", "", false, err.domain)
                return
            }
            print(error ?? "")
            complition("", "", false,nil)
        }
    }
    
    func signUpWithPhoneApi(phonenum: String, code: String, complition: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["phone": phonenum, "code": code]
        AFWrapper.postRequest(APIBuilder.share.signUpWithPhone(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String, let otp = responseDic["otp"] as? String
            else {
                
                complition("", "", false, nil)
                return
            }
            complition(otp, otpref, true, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition("", "", false, err.domain)
                return
            }
            print(error ?? "")
            complition("", "", false, nil)
        }
    }
    
    func signUpOtpVerifyApi(otp: Int, otpRef: String, complition: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["otp": otp, "otpRef": otpRef] as [String : Any]
        AFWrapper.postRequest(APIBuilder.share.signUpOtpVerify(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
            else {
                complition(false,nil)
                return
            }
            let loginToken = sessionDic["accessToken"] as? String
            let imageDic = userDic["image"] as? [String:Any]
            UserDefault.shared.loginToken = loginToken
            let user = Currentuser(fromDictionary: userDic)
            UserDefault.shared.user = user
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["":""])
            print("\(user)")
        
            complition(true,nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition(false, err.domain)
                return
            }
            complition(false,nil)
            print(error ?? "")
        }
    }
    
    func signUpResendOtpApi(otpref: String, complition: @escaping (_ otp: String, _ otpRef: String, _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        Loader.show()
        let param = ["otpRef": otpref]
        AFWrapper.postRequest(APIBuilder.share.signUpOtpResend(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String: Any], let otpref = responseDic["otpRef"] as? String, let otp = responseDic["otp"] as? String
            else {
                
                complition("", "", false,nil)
                return
            }
            complition(otp, otpref, true,nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition("", "", false, err.domain)
                return
            }
            print(error ?? "")
            complition("", "", false,nil)
        }
    }
    
    func loginWithEmailApi(email: String, password: String, complition: @escaping (_ isSuccess: Bool,_ errorMsg: String?) -> Void) {
        Loader.show()
        let param = ["email": email, "password": password]
        AFWrapper.postRequest(APIBuilder.share.loginWithEmail(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? NSDictionary, let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
            else {
                complition(false,nil)
                return
            }
            let imageDic = userDic["image"] as? [String:Any]
            let user = Currentuser(fromDictionary: userDic)
            let loginToken = sessionDic["accessToken"] as? String
            UserDefault.shared.loginToken = loginToken
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["":""])
            UserDefault.shared.user = user
            print("\(user)")
            complition(true,nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition(false, err.domain)
                return
            }
            print(error ?? "")
            complition(false,nil)
        }
    }
    
    func forgotPasswordApi(email: String, complition: @escaping (_ isSuccess: Bool,_ errorMsg: String?) -> Void) {
        Loader.show()
        let param = ["email": email]
        AFWrapper.postRequest(APIBuilder.share.forgotPassword(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? NSDictionary
            else {
                complition(false,nil)
                return
            }
            complition(true,nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition(false, err.domain)
                return
            }
            print(error ?? "")
            complition(false,nil)
        }
    }
    
    func editUserProfileApi(fName: String? = nil, lName: String? = nil, nickName:String? = nil, email:String? = nil, password: String? = nil, dob: String? = nil, gender: String? = nil, image: ImageDetail? = nil, city: String? = nil, vibeIds: [String]? = nil, drinkIds: [String]? = nil, complition: @escaping (_ isSuccess: Bool,_ errorMsg:String?) -> Void) {
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

        Loader.show()
        AFWrapper.patchRequest(APIBuilder.share.userProfile(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String:Any]
            else {
                complition(false,nil)
                return
            }
            complition(true,nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition(false, err.domain)
                return
            }
            print(error ?? "")
            complition(false,nil)
        }
    }
    
    func uploadPhotoApi(image: UIImage, complition: @escaping (_ imgUrl:String, _ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["file": image] as [String : Any]
        AFWrapper.multipart(APIBuilder.share.uploadPhoto(), fileData: image.jpegData(compressionQuality: 1), fileName: "\(UUID().uuidString).jpg", fileParamKey: "file", params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? NSDictionary, let imgUrl = responseDic["Location"] as? String
            else {
                complition("", false)
                return
            }
            complition(imgUrl, true)

        } failure: { (error) in
            complition("", false)
            print(error ?? "")
        }
    }
    
    func getVibesListAPi(from:Int? = 0, complition: @escaping(_ vibeList: [Vibe],_ hasMore: Bool, _ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["skip": from]
        AFWrapper.getRequest(APIBuilder.share.vibesList(), params: param as [String : Any], headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String:Any], let vibesArray = responseDic["list"] as? [[String:Any]], let more = responseDic["hasMany"] as? Bool
                    
            else {
                complition([Vibe](), false, false)
                return
            }
            var vibes = [Vibe]()
            vibesArray.forEach {
                vibes.append(Vibe(fromDictionary: $0))
            }
            complition(vibes, more, true)
        } failure: { (error) in
            complition([Vibe](), false, false)
            print(error ?? "")
        }
    }
    
    func getDrinkListAPi(from:Int? = 0, complition: @escaping(_ drinkList: [Drink],_ hasMore: Bool, _ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["skip": from]
        AFWrapper.getRequest(APIBuilder.share.drinksList(), params: param as [String : Any], headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String:Any], let drinkArray = responseDic["list"] as? [[String:Any]], let more = responseDic["hasMany"] as? Bool
                    
            else {
                complition([Drink](), false, false)
                return
            }
            var drinks = [Drink]()
            drinkArray.forEach {
                drinks.append(Drink(fromDictionary: $0))
            }
            complition(drinks, more, true)
        } failure: { (error) in
            complition([Drink](), false, false)
            print(error ?? "")
        }
    }
    
    func socialMediaConnectAPi(email: String,socialType: String,socialId: String, complition: @escaping (_ isSuccess: Bool,_ errorMsg: String?) -> Void) {
        
        let param = ["email": email, "socialType": socialType, "socialId":socialId]
        Loader.show()
        AFWrapper.patchRequest(APIBuilder.share.socialMediaConnection(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String:Any]
            else {
                complition(false,nil)
                return
            }
            complition(true,nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition(false, err.domain)
                return
            }
            print(error ?? "")
            complition(false,nil)
        }
    }
    
    func socialMediaLoginAPi(email: String,socialType: String,socialId: String, complition: @escaping (_ isSuccess: Bool,_ errorMsg: String?) -> Void) {
        
        let param = ["email": email, "socialType": socialType, "socialId":socialId]
        Loader.show()
        AFWrapper.postRequest(APIBuilder.share.socialMedialLogin(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String:Any], let userDic = responseDic["user"] as? [String:Any], let sessionDic = responseDic["session"] as? [String:Any]
            else {
                complition(false,nil)
                return
            }
            let imageDic = userDic["image"] as? [String:Any]
            let loginToken = sessionDic["accessToken"] as? String
            UserDefault.shared.loginToken = loginToken
            let user = Currentuser(fromDictionary: userDic)
            UserDefault.shared.user = user
            UserDefault.shared.user?.image = ImageDetail(fromDictionary: imageDic ?? ["":""])
            print("\(user)")
            complition(true,nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                complition(false, err.domain)
                return
            }
            print(error ?? "")
            complition(false,nil)
        }
    }
    
    func getCityListAPi(from:Int? = 0,searchText: String? = "", complition: @escaping(_ cityList: [City],_ hasMore: Bool, _ isSuccess: Bool) -> Void) {
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
        AFWrapper.getRequest(APIBuilder.share.getCityList(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String:Any], let cityArray = responseDic["list"] as? [[String:Any]], let more = responseDic["hasMany"] as? Bool
                    
            else {
                complition([City](), false, false)
                return
            }
            var citys = [City]()
            cityArray.forEach {
                citys.append(City(fromDictionary: $0))
            }
            complition(citys, more, true)
        } failure: { (error) in
            complition([City](), false, false)
            print(error ?? "")
        }
    }
}
