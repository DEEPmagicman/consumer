//
//  AFWrapper.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation
import Alamofire

typealias DefaultAPISuccessClosure = (Any?) -> Void
typealias DefaultAPIFailureClosure = (Error?) -> Void

struct Connectivity {
    static let sharedInstance = NetworkReachabilityManager()!
    static var isConnectedToInternet: Bool {
        sharedInstance.isReachable
    }
}

final class AFWrapper: NSObject {
    
    private override init() {}
    
//    static func postRequest(_ strURL: String, params: [String: Any]? = nil, headers: [String: String]?, isJsonEncoding: Bool = true, shouldForceLogout: Bool = true,
//                            success: @escaping DefaultAPISuccessClosure,
//                            failure: @escaping DefaultAPIFailureClosure) {
//        
//        if !Connectivity.isConnectedToInternet {
//            failure(NSError(domain: Constant.String.internetNotConnect, code: 0, userInfo: [:]))
//            return
//        }
//        
//        var parameters: Parameters?
//        if let params = params {
//            parameters =  params.encrypted() 
//        }
//        
//        
//        let req = Alamofire.request(strURL, method: .post, parameters: parameters, encoding: isJsonEncoding ? JSONEncoding.default: URLEncoding.default, headers: headers).responseString { response in
//            
//            if let responseCode = response.response?.statusCode {
//                if responseCode == 200 || responseCode == 201 {
//                    guard let encryptedResponse = response.result.value else {
//                        return
//                    }
//                    let decryptedResponse = encryptedResponse.decrypted()
//                    success(decryptedResponse)
//                }  else if shouldForceLogout && responseCode == 401 {
//                    forceLogout()
//                } else if response.result.value != nil {
//                    let errorResponse = errorHandling(response.result.value)
//                    failure(NSError(domain: errorResponse.1, code: errorResponse.0 == true ? 0 : 1, userInfo: [:]))
//                } else {
//                    failure(response.result.error)
//                }
//            } else {
//                failure(response.result.error)
//            }
//        }
//        
//        debugPrint(req)
//    }
    
        static func postRequest(_ strURL: String, params: [String: Any]? = nil, headers: [String: String]?, isJsonEncoding: Bool = true, shouldForceLogout: Bool = true,
                                success: @escaping DefaultAPISuccessClosure,
                                failure: @escaping DefaultAPIFailureClosure) {
    
            if !Connectivity.isConnectedToInternet {
                failure(NSError(domain: Constant.String.internetNotConnect, code: 0, userInfo: [:]))
                return
            }
    
            let req = Alamofire.request(strURL, method: .post, parameters: params, encoding: isJsonEncoding ? JSONEncoding.default: URLEncoding.default, headers: headers).responseJSON { (responseObject) -> Void in
    
                if let responseCode = responseObject.response?.statusCode {
                    if responseCode == 200 || responseCode == 201 {
                        success(responseObject.result.value)
                    } else if shouldForceLogout && responseCode == 401 {
                        forceLogout()
                    } else if responseObject.result.value != nil {
                        let errorResponse = errorHandling(responseObject.result.value ?? "")
                        failure(NSError(domain: errorResponse.1, code: errorResponse.0 == true ? 0 : 1, userInfo: [:]))
                    } else {
                        failure(responseObject.result.error)
                    }
                } else {
                    failure(responseObject.result.error)
                }
            }
    
            debugPrint(req)
        }
    
    
//    static func patchRequest(_ strURL: String, params:  [String: Any]? = nil, headers: [String: String]?,
//                             success: @escaping DefaultAPISuccessClosure,
//                             failure: @escaping DefaultAPIFailureClosure) {
//        
//        if !Connectivity.isConnectedToInternet {
//            success(nil)
//            failure(nil)
//            return
//        }
//        
//        var parameters: Parameters?
//        if let params = params {
//            parameters = params.encrypted()
//        }
//        
//        let req = Alamofire.request(strURL, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseString { response in
//            
//            if let responseCode = response.response?.statusCode {
//                if responseCode == 200 || responseCode == 201 {
//                    guard let encryptedResponse = response.result.value else {
//                        return
//                    }
//                    let decryptedResponse = encryptedResponse.decrypted()
//                    success(decryptedResponse)
//                }  else if responseCode == 401 {
//                    forceLogout()
//                } else if response.result.value != nil {
//                    let errorResponse = errorHandling(response.result.value)
//                    failure(NSError(domain: errorResponse.1, code: errorResponse.0 == true ? 0 : 1, userInfo: [:]))
//                } else {
//                    failure(response.result.error)
//                }
//            } else {
//                failure(response.result.error)
//            }
//        }
//        
//        debugPrint(req)
//    }
    
        static func patchRequest(_ strURL: String, params: [String: Any]? = nil, headers: [String: String]?,
                                 success: @escaping DefaultAPISuccessClosure,
                                 failure: @escaping DefaultAPIFailureClosure) {
    
            if !Connectivity.isConnectedToInternet {
                success(nil)
                failure(nil)
                return
            }
    
            let req = Alamofire.request(strURL, method: .patch, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (responseObject) -> Void in
    
                if let responseCode = responseObject.response?.statusCode {
                    if responseCode == 200 || responseCode == 201 {
                        success(responseObject.result.value)
                    } else if responseCode == 401 {
                        forceLogout()
                    } else if responseObject.result.value != nil {
                        let errorResponse = errorHandling(responseObject.result.value ?? "")
                        failure(NSError(domain: errorResponse.1, code: errorResponse.0 == true ? 0 : 1, userInfo: [:]))
                    } else {
                        failure(responseObject.result.error)
                    }
                } else {
                    failure(responseObject.result.error)
                }
            }
    
            debugPrint(req)
        }
    
    static func multipart(_ strURL: String, fileData: Data?, fileName: String, fileParamKey: String, params: [String: Any], headers: [String: String]?, method: HTTPMethod = .post,
                          success: @escaping DefaultAPISuccessClosure,
                          failure: @escaping DefaultAPIFailureClosure) {

        if !Connectivity.isConnectedToInternet {
            success(nil)
            failure(nil)
            return
        }
        Alamofire.upload(multipartFormData: { (multipartParam) in
            for param in params {
                if param.key == fileParamKey, let data = fileData {
                    multipartParam.append(data, withName: param.key, fileName: fileName, mimeType: ".\((fileName as NSString).pathExtension)")
                } else {
                    multipartParam.append(Data((param.value as? String ?? "").utf8), withName: param.key)
                }
            }
        }, to: strURL, method: method, headers: headers) { (result) in
            switch result {
            case .success(let upload, _, _):
                let req = upload.responseJSON { (response) in
                    if let responseCode = response.response?.statusCode {
                        if responseCode == 200 {
                            success(response.result.value)
                        } else if responseCode == 201 {
                            success(response.result.value)
                        } else if responseCode == 401 {
                            forceLogout()
                        } else {
                            failure(response.result.error)
                        }
                    } else {
                        failure(response.result.error)
                    }
                }
                debugPrint(req)
            case .failure(let error):
                failure(error)
            }
        }
    }
    
//    static func multipart(_ strURL: String, fileData: Data?, fileName: String, fileParamKey: String, params: [String: Any], headers: [String: String]?, method: HTTPMethod = .post,
//                          success: @escaping DefaultAPISuccessClosure,
//                          failure: @escaping DefaultAPIFailureClosure) {
//        
//        if !Connectivity.isConnectedToInternet {
//            success(nil)
//            failure(nil)
//            return
//        }
//        
//        var multipartParams = params
//        multipartParams = multipartParams.encrypted() ?? params
//        
//        Alamofire.upload(multipartFormData: { (multipartData) in
//            if let imageData = fileData {
//                multipartData.append(imageData, withName: fileParamKey, fileName: fileName, mimeType: "image/jpeg")
//            }
//            
//            for (key, value) in multipartParams {
//                if let stringValue = value as? String, let data = stringValue.data(using: .utf8) {
//                    multipartData.append(data, withName: key)
//                }
//            }
//        }, to: strURL, method: method, headers: headers) { (result) in
//            switch result {
//            case .success(let upload, _, _):
//                let req = upload.responseString { response in
//                    if let responseCode = response.response?.statusCode {
//                        if responseCode == 200 || responseCode == 201 {
//                            guard let encryptedResponse = response.result.value else {
//                                return
//                            }
//                            let decryptedResponse = encryptedResponse.decrypted()
//                            success(decryptedResponse)
//                        } else if responseCode == 401 {
//                            forceLogout()
//                        } else {
//                            failure(response.result.error)
//                        }
//                    } else {
//                        failure(response.result.error)
//                    }
//                }
//                debugPrint(req)
//            case .failure(let error):
//                failure(error)
//            }
//        }
//    }

//    static func getRequest(_ strURL: String,isForCard:Bool = false, params: [String: Any]? = nil, headers: [String: String]?, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure) {
//        if !Connectivity.isConnectedToInternet {
//            failure(nil)
//            return
//        }
//        
//        let req = Alamofire.request(strURL, method: .get, parameters: params, headers: headers).responseString(queue: nil, encoding: .utf8) { response in
//            switch response.result {
//            case .success(let value):
//                if let responseCode = response.response?.statusCode {
//                    if responseCode == 200 || responseCode == 201 {
//                        guard let responseInString = response.result.value else {
//                            return
//                        }
//                        if isForCard{
//                            let decryptedResponse = responseInString.decryptedArry()
//                            success(decryptedResponse ?? [:])
//                        }else{
//                            let decryptedResponse = responseInString.decrypted()
//                            success(decryptedResponse ?? [:])
//                        }
//                    } else if responseCode == 401 {
//                        forceLogout()
//                    } else {
//                        let errorMessage = "Request failed with status code \(responseCode)"
//                        failure(NSError(domain: errorMessage, code: responseCode, userInfo: [:]))
//                    }
//                } else {
//                    failure(nil)
//                }
//            case .failure(let error):
//                failure(error)
//            }
//        }
//        debugPrint(req)
//    }
    
    static func getRequest(_ strURL: String, params: [String: Any]? = nil, headers: [String: String]?, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure) {
        
        if !Connectivity.isConnectedToInternet {
            success(nil)
            failure(nil)
            return
        }
        
        let req = Alamofire.request(strURL, method: .get, parameters: params, headers: headers).responseJSON { responseObject in
            
            if let responseCode = responseObject.response?.statusCode {
                if responseCode == 200 || responseCode == 201 {
                    success(responseObject.result.value)
                } else if responseCode == 401 {
                    forceLogout()
                } else if responseObject.result.value != nil {
                    let errorResponse = errorHandling(responseObject.result.value ?? "")
                    failure(NSError(domain: errorResponse.1, code: errorResponse.0 == true ? 0 : 1, userInfo: [:]))
                } else {
                    failure(responseObject.result.error)
                }
            } else {
                failure(responseObject.result.error)
            }
        }
        debugPrint(req)
    }
    
    static func deleteRequest(_ strURL: String, params: [String: Any]? = nil, headers: [String: String]?,
                              success: @escaping DefaultAPISuccessClosure,
                              failure: @escaping DefaultAPIFailureClosure) {
        
        if !Connectivity.isConnectedToInternet {
            success(nil)
            failure(nil)
            return
        }
        
        var encryptedParams = params
        // Encrypting parameters
        encryptedParams = encryptedParams?.encrypted()
        
        let req = Alamofire.request(strURL, method: .delete, parameters: encryptedParams, headers: headers).responseString { (response) in
            
            if let responseCode = response.response?.statusCode {
                if responseCode == 200 || responseCode == 201 {
                    guard let encryptedResponse = response.result.value else {
                        return
                    }
                    let decryptedResponse = encryptedResponse.decrypted()
                    success(decryptedResponse)
                } else if responseCode == 401 {
                    forceLogout()
                } else {
                    failure(response.result.error)
                }
            } else {
                failure(response.result.error)
            }
        }
        
        debugPrint(req)
    }
    
//    static func putRequest(_ strURL: String, params: [String: Any]? = nil, headers: [String: String]?, isJsonEncoding: Bool = true, isForceLogout: Bool = true, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure) {
//        
//        if !Connectivity.isConnectedToInternet {
//            success(nil)
//            failure(nil)
//            return
//        }
//        
//        var parameters: Parameters?
//        if let params = params {
//            parameters = params.encrypted()
//        }
//        
//        let req = Alamofire.request(strURL, method: .put, parameters: parameters, encoding: isJsonEncoding ? JSONEncoding.default : URLEncoding.default, headers: headers).responseString { response in
//            
//            if let responseCode = response.response?.statusCode {
//                if responseCode == 200 || responseCode == 201 {
//                    guard let encryptedResponse = response.result.value else {
//                        return
//                    }
//                    let decryptedResponse = encryptedResponse.decrypted()
//                    success(decryptedResponse)
//                } else if response.result.value != nil {
//                    let errorResponse = errorHandling(response.result.value ?? "")
//                    failure(NSError(domain: errorResponse.1, code: errorResponse.0 == true ? 0 : 1, userInfo: [:]))
//                } else if responseCode == 401 {
//                    if isForceLogout { forceLogout() } else { failure(response.result.error) }
//                } else if responseCode >= 500 {
//                    failure(NSError(domain: "", code: 500, userInfo: [:]))
//                } else {
//                    failure(response.result.error)
//                }
//            } else {
//                failure(response.result.error)
//            }
//        }
//        
//        debugPrint(req)
//    }
    
        static func putRequest(_ strURL: String, params: [String: Any]? = nil, headers: [String: String]?, isJsonEncoding: Bool = true, isForceLogout: Bool = true, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure) {
            
            if !Connectivity.isConnectedToInternet {
                success(nil)
                failure(nil)
                return
            }
    
            let req = Alamofire.request(strURL, method: .put, parameters: params, encoding: isJsonEncoding ? JSONEncoding.default : URLEncoding.default, headers: headers).responseJSON { (responseObject) -> Void in
    
                if let responseCode = responseObject.response?.statusCode {
                    if responseCode == 200 || responseCode == 201 {
                        success(responseObject.result.value)
                    } else if responseObject.result.value != nil {
                        let errorResponse = errorHandling(responseObject.result.value ?? "")
                        failure(NSError(domain: errorResponse.1, code: errorResponse.0 == true ? 0 : 1, userInfo: [:]))
                    } else if responseCode == 401 {
                        if isForceLogout { forceLogout() } else { failure(responseObject.result.error) }
                    } else if responseCode >= 500 {
                        failure(NSError(domain: "", code: 500, userInfo: [:]))
                    } else {
                        failure(responseObject.result.error)
                    }
                } else {
                    failure(responseObject.result.error)
                }
            }
    
            debugPrint(req)
        }
    
    static func errorHandling(_ response: Any) -> (Bool, String) {
            if let response = response as? [String: Any], let errMsg = response["message"] {
                if let stringErr = errMsg as? String {
                    return (true, stringErr)
                } else if let arrayErr = errMsg as? [String], let stringErr = arrayErr.first {
                    return (true, stringErr)
                }
                return (false, "")
            } else {
                return (false, "")
            }
        }
    
//    static func errorHandling(_ response: String?) -> (Bool, String) {
//        guard let jsonString = response else {
//            return (false, "")
//        }
//        guard let jsonData = jsonString.data(using: .utf8) else {
//            return (false, "")
//        }
//        do {
//            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
//                if let errMsg = json["message"] as? String {
//                    return (true, errMsg)
//                }
//            }
//        } catch {
//            print("Error decoding JSON: \(error)")
//        }
//        return (false, "")
//    }

    
    static func forceLogout() {
        CustomLoader.sharedInstance.stopAnimation()
        Loader.hide()
        Utility.main.showAlert(message: Constant.String.sessionTimeOut, title: "") {
            UserDefault.shared.emptyData()
            AppDelegate.shared.changeRootViewController()
        }
    }
}
