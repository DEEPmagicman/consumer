//
//  MVPPresenter.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 06/02/23.
//

import Foundation

final class MVPPresenter {
    func getVenuesDetailForaMVP(venueId: String, venueTimeZone: String? = nil, doormanId: String = "", completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ venueDetail: ClipVenue?) -> Void) {
        AFWrapper.getRequest(APIBuilder.MVPVenueDetailURL(venueId),params: nil, headers: Header.header( timeZone: venueTimeZone, doormanId: doormanId)) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }
            if let venueDetail = ClipVenue.parse(responseDic) {
                completion(true, nil, venueDetail)
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
    
    func getVenueListForMVP(from: Int, status: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ venueList: [ClipVenue], _ hasMore: Bool) -> Void) {
        let param = ["skip": from, 
                     "bookingStatus": status] as [String : Any]
        
        AFWrapper.getRequest(APIBuilder.MVPVenueListURL, params: param, headers: Header.header(), success: { response in
            if let responseDict = response as? [String: Any] {
                do {
                    guard let venueArray = responseDict["list"] as? [[String: Any]],
                          let hasMore = responseDict["hasMany"] as? Bool else {
                        completion(false, "Invalid response format", [], false)
                        return
                    }
                    
                    let jsonDecoder = JSONDecoder()
                    let data = try JSONSerialization.data(withJSONObject: venueArray, options: .prettyPrinted)
                    let venueList = try jsonDecoder.decode([ClipVenue].self, from: data)
                    
                    completion(true, nil, venueList, hasMore)
                } catch {
                    completion(false, "Decoding error: \(error)", [], false)
                    print(error)
                }
            } else {
                completion(false, "Invalid response format", [], false)
            }
        }, failure: { error in
            if let err = error as NSError?, err.code == 0 {
                completion(false, err.domain, [], false)
            } else {
                completion(false, nil, [], false)
            }
        })
    }

    func mvpCityListAPi(completion: @escaping (_ cityList: [MVPCity], _ isSuccess: Bool, _ errMsg: String?) -> Void) {
        AFWrapper.getRequest(APIBuilder.mvpCityListURL, params: nil, headers: Header.unauthorizedHeader(), success: { response in
            guard let responseDict = response as? [String: Any] else {
                completion([], false, nil)
                return
            }
            do {
                guard let cityArray = responseDict["city"] as? [[String: Any]] else {
                    completion([], false, nil)
                    return
                }
                let data = try JSONSerialization.data(withJSONObject: cityArray, options: .prettyPrinted)
                let cityList = try JSONDecoder().decode([MVPCity].self, from: data)
                completion(cityList, true, nil)
            } catch {
                completion([], false, nil)
            }
        }, failure: { error in
            completion([], false, nil)
        })
    }

    static func getUpSellItem(skip: Int, doormanId: String = "", venueId: String = "", completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ upSellItem: [UpSellTicket],_ hasMore: Bool, _ total: Int) -> Void) {
        let param = ["skip": skip,"include": "addOns"] as [String: Any]
        
        AFWrapper.getRequest(APIBuilder.getAddOnsAPI, params: param, headers: Header.header(doormanId: doormanId ,venueId: venueId)) { response in
            
            guard let responseDic = response as? [String: Any], let menu = responseDic["list"] as? [[String: Any]], let hasMore = responseDic["hasMany"] as? Bool, let total = responseDic["total"] as? Int else {
                completion(false, nil, [], false, 0)
                return
            }
            if let venueList = [UpSellTicket].parse(menu) {
                completion(true, nil, venueList, hasMore, total)
            } else {
                completion(false, "internal error", [], false, 0)
            }

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [], false, 0)
                return
            }
            completion(false, nil, [],false, 0)
        }
    }
}
