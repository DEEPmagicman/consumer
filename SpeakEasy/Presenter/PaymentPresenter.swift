//
//  PaymentPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 17/04/23.
//

import Foundation

final class PaymentPresenter {
    static func getUserSavedMethods(customerId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ paymentMethods: [PaymentMethod]) -> Void) {

        AFWrapper.getRequest(APIBuilder.customerMethod(customerId), params: nil, headers: Header.header()) { response in
            guard let responseArray = response as? [[String: Any]] else {
                completion(false, nil, [])
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: responseArray, options: .prettyPrinted)
                let paymentMethods = try JSONDecoder().decode([PaymentMethod].self, from: data)
                completion(true, nil, paymentMethods)
            } catch {
                completion(false, "internal error", [])
            }
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [])
                return
            }
            completion(false, nil, [])
        }
    }
    
    static func deleteMethod(customerId: String, methodId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        AFWrapper.deleteRequest(APIBuilder.deleteMethod(customerId, methodId: methodId), headers: Header.header()) { response in
            guard let responseArray = response as? [String: Any] else {
                completion(false, nil)
                return
            }
            completion(true, nil)
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }
            completion(false, nil)
        }
    }
}

extension URLSession {
    func fetchData(at url: URL, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        self.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(nil, error)
            }
            if let data = data {
                completion(data, nil)
            } else {
                completion(nil, error)
            }
        }.resume()
    }
}
