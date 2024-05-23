//
//  VenuePresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

final class VenuePresenter {
    func getVenues(from: Int, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ venueList: [Venue],_ hasMore: Bool) -> Void) {
        let param = ["skip": from]
        Loader.show()
        AFWrapper.getRequest(APIBuilder.venueURL,params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any], let menu = responseDic["list"] as? [[String: Any]], let hasMore = responseDic["hasMany"] as? Bool else {
                completion(false, nil, [], false)
                return
            }
            if let venueList = [Venue].parse(menu) {
                completion(true, nil, venueList,hasMore)
            } else {
                completion(false, "internal error", [], false)
            }

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [], false)
                return
            }
            completion(false, nil, [], false)
        }
    }
        
    static func getDeepLinkData(_ id: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ doormanId: String?, _ venueId: String?) -> Void) {
        Loader.show()
        AFWrapper.getRequest(APIBuilder.deepLinkURL(id), params: nil, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any], let venueId = responseDic["venueId"] as? String, let doormanId = responseDic["doormanId"] as? String else {
                completion(false, nil, nil, nil)
                return
            }
            
            completion(true, nil, doormanId, venueId)

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil, nil)
                return
            }
            completion(false, nil, nil, nil)
        }
    }
}
