//
//  BarTabPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/06/25.
//

import Foundation

final class BarTabPresenter {
    static func getPaymentDetails(param: [String: Any], completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ barTabDetails: BarTabData?) -> Void) {
        
        AFWrapper.postRequest(APIBuilder.barTabAPI, params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }
            if let data = BarTabData.parse(responseDic) {
                completion(true, nil, data)
            } else {
                completion(false, "internal error", nil)
            }
            
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil)
                return
            }
            completion(false, nil, nil)
        }
    }
    
    static func barTabPaymentCompleteAPI(barId: String, paymentId: String, completion: @escaping(_ isSuccess: Bool, _ errMsg: String?, _ barTab: BarTab?) -> Void) {
        
        AFWrapper.postRequest(APIBuilder.barTabPaymentComplete(barId: barId, paymentId: paymentId), headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }
            if let data = BarTab.parse(responseDic) {
                completion(true, nil, data)
            } else {
                completion(false, "internal error", nil)
            }
            
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil)
                return
            }
            completion(false, nil, nil)
        }
    }
    
    
    static func getBarTabPaymentDetails(posCheckId: String, completion: @escaping(_ isSuccess: Bool, _ errMsg: String?, _ barTabBooking: BarTabBooking?) -> Void) {
        AFWrapper.getRequest(APIBuilder.barTabPaymentDetails(posCheckId: posCheckId), headers: Header.header()) { response in
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }
            if let booking = BarTabBooking.parse(responseDic) {
                completion(true, nil, booking)
            } else {
                completion(false, "internal error", nil)
            }
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil)
                return
            }
            completion(false, nil, nil)
        }
    }
}
