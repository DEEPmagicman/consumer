//
//  InstagramManager.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 30/12/22.
//

import Foundation
import SwiftUI

class InstagramManager {
    
   static weak var instagramDelegate: InstagramPhotosDelegate?
    
    var onGetInstaPhotos: (([InstagramMedia], Bool) -> ())?
    
    static func getInstagramToken(code: String, compelition: @escaping (() -> Void)) {
        
        if !Connectivity.isConnectedToInternet {
            Alert.showAlertSheet(style: .alert, title: "internet not connect", message: "")
            return
        }
        
        instagramLogin(code: code){ tokan,isSuccess  in
            if isSuccess {
                print("*-*\(tokan)")
                compelition()
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
        if let nextPageURL = UserDefault.shared.user?.instanextPageURL {
            guard nextPageURL != "" else {
                return
            }
            self.urlExecute(url: nextPageURL) { respons,isSuccess in
                if isSuccess {
                    if let response = respons as? [String: Any] {
                        self.instaParsing(response: response)
                    }
                } else {
                    Alert.showAlertSheet(style: .alert, title: "No More Image", message: "")
                }
            }
            return
        }
        self.urlExecute(url: String(format: APIBuilder.getInstagramImages, token)) { respons,isSuccess  in
            if isSuccess {
                if let response = respons as? [String: Any] {
                    self.instaParsing(response: response)
                }
            } else {
                Alert.showAlertSheet(style: .alert, title: "No image Found", message: "")
            }
        }
    }
    
    static func urlExecute(url: String, completion: @escaping (_ respons : Any, _ isSuccess: Bool) -> Void) {
        
        AFWrapper.getRequest(url, params: nil, headers: Header.shared.header(headerContentType: .json)) { (response) in
            completion(response, true)
        } failure: { (error) in
            if let err = (error as? NSError)?.userInfo as? [String: Any], let instaErr = err["error"] as? [String: Any], let errCode = instaErr["code"] as? Int, errCode == 190 {
                print("")
                instagramDelegate?.getError(errorMsg: "Session has expired, please login again")
                return
            }
            completion("", false)
        }
    }
    
    static func instaParsing(response: [String: Any]) {
        if let data = response["data"] as? [[String: Any]] {
            if let paging = response["paging"] as? [String: Any] {
                UserDefault.shared.user?.instanextPageURL = paging["next"] as? String ?? ""
            }
            self.mapInstaImages(data: data, index: 0, medias: [])
        }
    }
    
    static func mapInstaImages(data: [[String: Any]], index: Int, medias: [InstagramMedia]) {
        guard index < data.count else {
            self.instagramDelegate?.getInstaImages(media: medias, isLastPage: UserDefault.shared.user?.instanextPageURL ?? "" == "")
            return
        }
        let val = data[index] as? [String : String]
        UserDefault.shared.user?.instaUserName = val?["username"] ?? ""
        if val?["media_type"] == "IMAGE" {
            var media = InstagramMedia.init()
            media.name = val?["id"] ?? ""
            media.url = val?["media_url"] ?? ""
            mapInstaImages(data: data, index: index + 1, medias: medias + [media])
            
        } else if val?["media_type"] == "CAROUSEL_ALBUM",
            let id = val?["id"],
                  let token = UserDefault.shared.user?.instagramTokan {
            InstagramManager.urlExecute(url: String(format: APIBuilder.getInstagramChilds, id, token)) { respons,isSuccess in
                if isSuccess {
                    if let response = respons as? NSDictionary,
                        let values = response["data"] as? NSArray {
                        
                        let childMedias = values.compactMap { (value) -> InstagramMedia? in
                            if let val = value as? [String : String], val["media_type"] == "IMAGE" {
                                var media = InstagramMedia.init()
                                media.name = val["id"] ?? ""
                                media.url = val["media_url"] ?? ""
                                return media
                            }
                            return nil
                        }
                        self.mapInstaImages(data: data, index: index + 1, medias: medias + childMedias)
                        return
                    }
                } else {
                    self.mapInstaImages(data: data, index: index + 1, medias: medias)
                }
            }
        } else {
            mapInstaImages(data: data, index: index + 1, medias: medias)
        }
    }
     
}
