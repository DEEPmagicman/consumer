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
    
    static func postRequest(_ strURL: String, params: [String: Any]? = nil, headers: [String: String]?, isJsonEncoding: Bool = true,
                            success: @escaping DefaultAPISuccessClosure,
                            failure: @escaping DefaultAPIFailureClosure) {

        if !Connectivity.isConnectedToInternet {
            success(nil)
            failure(nil)
            return
        }
        
        let req = Alamofire.request(strURL, method: .post, parameters: params, encoding: isJsonEncoding ? JSONEncoding.default : URLEncoding.default, headers: headers).responseJSON { (responseObject) -> Void in
            
            if let responseCode = responseObject.response?.statusCode {
                if responseCode == 200 || responseCode == 201 {
                    success(responseObject.result.value)
                } else if responseObject.result.value != nil {
                    let errorResponse = errorHandling(responseObject.result.value)
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
                } else if responseObject.result.value != nil {
                    let errorResponse = errorHandling(responseObject.result.value)
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
    
    static func getRequest(_ strURL:String, params: [String: Any]? = nil, headers: [String: String]?,
                           success: @escaping DefaultAPISuccessClosure,
                           failure: @escaping DefaultAPIFailureClosure) {
        
        if !Connectivity.isConnectedToInternet {
            success(nil)
            failure(nil)
            return
        }
        
        let req = Alamofire.request(strURL, method: .get, parameters: params, headers: headers).responseJSON { (responseObject) -> Void in
            
            if let responseCode = responseObject.response?.statusCode {
                if responseCode == 200 || responseCode == 201 {
                    success(responseObject.result.value)
                } else if responseObject.result.value != nil {
                    let errorResponse = errorHandling(responseObject.result.value)
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
}
