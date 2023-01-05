//
//  AFWrapper.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation
import Alamofire

struct Connectivity {
    static let sharedInstance = NetworkReachabilityManager()!
    static var isConnectedToInternet:Bool {
        return self.sharedInstance.isReachable
    }
}

class AFWrapper: NSObject {
    
    private override init() {
        
    }
    
    class func postRequest(_ strURL:String, params : [String : Any]? = nil, headers : [String : String]?, isJsonEncoding: Bool = true, success:@escaping (Any?) -> Void, failure:@escaping (Error?) -> Void) {
        
        if !Connectivity.isConnectedToInternet {
            success(nil)
            failure(nil)
            return
        }
        
        let req = Alamofire.request(strURL, method: .post, parameters: params, encoding: isJsonEncoding ? JSONEncoding.default : URLEncoding.default, headers: headers).responseJSON { (responseObject) -> Void in
            
            if let responseCode = responseObject.response?.statusCode {
                if responseCode == 200 || responseCode == 201 {
                    success(responseObject.result.value)
                } else {
                    failure(responseObject.result.error)
                }
            } else {
                failure(responseObject.result.error)
            }
        }
        
        debugPrint(req)
    }
    
    class func patchRequest(_ strURL:String, params : [String : Any]? = nil, headers : [String : String]?, success:@escaping (Any?) -> Void, failure:@escaping (Error?) -> Void) {
        
        if !Connectivity.isConnectedToInternet {
            success(nil)
            failure(nil)
            return
        }
        
        let req = Alamofire.request(strURL, method: .patch, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (responseObject) -> Void in
            
            if let responseCode = responseObject.response?.statusCode {
                if responseCode == 200 || responseCode == 201 {
                    success(responseObject.result.value)
                } else {
                    failure(responseObject.result.error)
                }
            } else {
                failure(responseObject.result.error)
            }
        }
        
        debugPrint(req)
    }
    
    class func multipart(_ strURL: String, fileData: Data?, fileName: String, fileParamKey: String, params: [String: Any], headers: [String: String]?, method: HTTPMethod = .post, success:@escaping (Any?) -> Void, failure:@escaping (Any?) -> Void) {
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
                  failure(response.result.value)
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
    
    class func getRequest(_ strURL:String, params : [String : Any]? = nil, headers : [String : String]?, success:@escaping (Any?) -> Void, failure:@escaping (Error?) -> Void) {
        
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
                    failure(NSError(domain: "", code: 0, userInfo: (responseObject.result.value as? [String : Any]) ?? [:]))
                } else {
                    failure(responseObject.result.error)
                }
            } else {
                failure(responseObject.result.error)
            }
        }
        
        debugPrint(req)
    }
}
