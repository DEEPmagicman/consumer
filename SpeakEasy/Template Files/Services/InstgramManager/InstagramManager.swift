//
//  InstagramManager.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 30/12/22.
//

import Foundation
import SwiftUI

class InstagramManager {
    
    
    static func getInstagramToken(code: String) {
        
        if !Connectivity.isConnectedToInternet {
            Alert.showAlertSheet(style: .alert, title: "internet not connect", message: "")
            return
        }
        
        instagramLogin(code: code){ tokan,isSuccess  in
            if isSuccess {
                print("*-*\(tokan)")
//                self.onInstaGramTokenGet?()
            } else {
                Alert.showAlertSheet(style: .alert, title: "not get", message: "")
            }
        }
    }
    
    
    static func instagramLogin(code: String, complition: @escaping (_ tokan: String, _ isSuccess: Bool) -> Void) {
        
        let param = ["client_id" : Constant.String.InstagramClientId,
                     "client_secret" : Constant.String.InstagramclientSecret,
                     "grant_type" : Constant.String.authorizationCode,
                     "redirect_uri" : Constant.String.InstagramredirectUri,
                     "code" : code]
        AFWrapper.postRequest(APIBuilder.share.getInstagramToken(), params: param, headers: Header.shared.header(headerContentType: .xwwwformUrlencoded), isJsonEncoding: false) { (result) in
            if let data = result as? NSDictionary, let id = data["user_id"] as? Int, let token = data["access_token"] as? String {
                UserDefault.shared.user?.instagramId = id.description
                UserDefault.shared.user?.instagramTokan = token
                complition(token, true)
            } else {
                complition("", false)
            }
        } failure: { (error) in
            print(error ?? "")
            complition("", false)
        }
    }
    
    static func getInstaImages(token: String) {
//        if let nextPageURL = UserDefault.getCurrentUser().instanextPageURL {
//            guard nextPageURL != "" else {
//                return
//            }
//            service.urlExecute(url: nextPageURL) { (data) in
//                switch data {
//                case .Success(let result):
//                    if let response = result as? NSDictionary {
//                        self.instaParsing(response: response)
//                    }
//                default:
//                    break
//                }
//            }
//            return
//        }
        
        self.urlExecute(url: String(format: APIBuilder.getInstagramImages, token)) { respons,isSuccess  in
//            switch respons {
                if isSuccess {
                    if let response = respons as? NSDictionary {
                        self.instaParsing(response: response)
                    }
                }
//            default:
//                break
//            }
        }
    }
    
    static func urlExecute(url: String, completion: @escaping (_ respons : Any, _ isSuccess: Bool) -> Void) {
        
        AFWrapper.getRequest(url, params: nil, headers: Header.shared.header(headerContentType: .json)) { (response) in
            completion(response, true)
        } failure: { (error) in
            completion( "", false)
        }
    }
    
    static func instaParsing(response: NSDictionary) {
        if let data = response["data"] as? NSArray {
            if let paging = response["paging"] as? NSDictionary {
//                var userData = UserDefault.getCurrentUser()
                let nextPageUrl = paging["next"] as? String ?? ""
//                _ = UserDefault.saveCurrentUser(userData)
            }
//            mapInstaImages(data: data, index: 0, medias: [])
        }
    }
     
}
