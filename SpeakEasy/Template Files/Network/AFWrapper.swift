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
    
    class func postRequest(_ strURL:String, params : [String : Any]? = nil, headers : [String : String]?, success:@escaping (Any?) -> Void, failure:@escaping (Error?) -> Void) {
        
        if !Connectivity.isConnectedToInternet {
            success(nil)
            failure(nil)
            return
        }
        
        let req = Alamofire.request(strURL, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (responseObject) -> Void in
            
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
}
