//
//  OnBoardingPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation
import UIKit

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
            UserDefault.shared.user = user
            print("\(user)")
            complition(true)

        } failure: { (error) in
            print(error ?? "")
            complition(false)
        }
    }
    
    func forgotPasswordApi(email: String, complition: @escaping (_ isSuccess: Bool) -> Void) {
        Loader.show()
        let param = ["email": email]
        AFWrapper.postRequest(APIBuilder.share.forgotPassword(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? NSDictionary
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
    
    func editUserProfileApi(fName: String? = nil, lName: String? = nil, nickName:String? = nil, email:String? = nil, password: String? = nil, dob: String? = nil, gender: String? = nil, image: ImageDetail? = nil, city: String? = nil, vibeIds: [String]? = nil, drinkIds: [String]? = nil, complition: @escaping (_ isSuccess: Bool) -> Void) {
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
                complition(false)
                return
            }
            complition(true)

        } failure: { (error) in
            print(error ?? "")
            complition(false)
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
    
    func getVibesListAPi(complition: @escaping(_ vibeList: [Vibe], _ isSuccess: Bool) -> Void) {
        Loader.show()
        AFWrapper.getRequest(APIBuilder.share.vibesList(), params: nil, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String:Any], let vibesArray = responseDic["list"] as? [[String:Any]]
                    
            else {
                complition([Vibe](), false)
                return
            }
            var vibes = [Vibe]()
            vibesArray.forEach {
                vibes.append(Vibe(fromDictionary: $0))
            }
            complition(vibes, true)
        } failure: { (error) in
            complition([Vibe](), false)
            print(error ?? "")
        }
    }
    
    func getDrinkListAPi(complition: @escaping(_ drinkList: [Drink], _ isSuccess: Bool) -> Void) {
        Loader.show()
        AFWrapper.getRequest(APIBuilder.share.drinksList(), params: nil, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
            guard let responseDic = response as? [String:Any], let drinkArray = responseDic["list"] as? [[String:Any]]
                    
            else {
                complition([Drink](), false)
                return
            }
            var drinks = [Drink]()
            drinkArray.forEach {
                drinks.append(Drink(fromDictionary: $0))
            }
            complition(drinks, true)
        } failure: { (error) in
            complition([Drink](), false)
            print(error ?? "")
        }
    }
    
    func socialMediaConnectAPi(email: String,socialType: String,socialId: String, complition: @escaping (_ isSuccess: Bool) -> Void) {
        
        let param = ["email": email, "socialType": socialType, "socialId":socialId]
        Loader.show()
        AFWrapper.patchRequest(APIBuilder.share.socialMediaConnection(), params: param, headers: Header.shared.header(headerContentType: .json)) { (response) in
            
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
