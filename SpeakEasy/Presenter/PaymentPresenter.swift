//
//  PaymentPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 17/04/23.
//

import Foundation

final class PaymentPresenter {
//    static func getAppleWalletFile(bookingId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
//
//        AFWrapper.getRequest(APIBuilder.appClipAppleWallet(bookingId), params: nil, headers: Header.header()) { response in
//
//            guard let responseDic = response as? [String: Any] else {
//                completion(false, nil)
//                return
//            }
//            do {
//                let decoder = JSONDecoder()
//                let data = try JSONSerialization.data(withJSONObject: responseDic, options: .prettyPrinted)
//                let venueDetail = try decoder.decode(ClipVenue.self, from: data)
//                completion(true, nil)
//            } catch {
//                completion(false, "internal error")
//            }
//
//        } failure: { error in
//            if let err = error as? NSError, err.code == 0 {
//                completion(false, err.domain)
//                return
//            }
//            completion(false, nil)
//        }
//    }
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
