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
            do {
                let data = try JSONSerialization.data(withJSONObject: menu, options: .prettyPrinted)
                let venueList = try JSONDecoder().decode([Venue].self, from: data)
                completion(true, nil, venueList,hasMore)
            } catch {
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
    
    func getBottleList(venueId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ eventList: [BottleCategory], _ hasMore: Bool) -> Void) {
        Loader.show()
        AFWrapper.getRequest(APIBuilder.bottleListURL(venueId),params: nil, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any], let menu = responseDic["list"] as? [[String: Any]], let hasMore = responseDic["hasMany"] as? Bool
            else {
                completion(false, nil, [], false)
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: menu, options: .prettyPrinted)
                let bottleCategoryList = try JSONDecoder().decode([BottleCategory].self, from: data)
                completion(true, nil, bottleCategoryList, hasMore)
            } catch {
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
}
