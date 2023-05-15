//
//  MVPPresenter.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 06/02/23.
//

import Foundation

final class MVPPresenter {
    func getVenuesDetailForaMVP(venueId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ venueDetail: ClipVenue?) -> Void) {
        AFWrapper.getRequest(APIBuilder.MVPVenueDetailURL(venueId),params: nil, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: responseDic, options: .prettyPrinted)
                let venueDetail = try decoder.decode(ClipVenue.self, from: data)
                completion(true, nil, venueDetail)
            } catch {
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
    
    func getVenueListForMVP(from: Int,status: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ venueList: [ClipVenue],_ hasMore: Bool) -> Void) {
        let param = ["skip": from,
                     "bookingStatus": status] as [String : Any]
        AFWrapper.getRequest(APIBuilder.MVPVenueListURL,params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any], let menu = responseDic["list"] as? [[String: Any]], let hasMore = responseDic["hasMany"] as? Bool else {
                completion(false, nil, [], false)
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: menu, options: .prettyPrinted)
                let venueList = try JSONDecoder().decode([ClipVenue].self, from: data)
                completion(true, nil, venueList, hasMore)
            } catch {
                completion(false, "internal error", [], false)
            }

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [],false)
                return
            }
            completion(false, nil, [],false)
        }
    }
    
    func mvpCityListAPi(completion: @escaping(_ cityList: [MVPCity], _ isSuccess: Bool) -> Void) {
        AFWrapper.getRequest(APIBuilder.mvpCityListURL, params: nil, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let cityArray = responseDic["city"] as? [[String: Any]] else {
                completion([], false)
                return
            }
        
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: cityArray, options: .prettyPrinted)
                let cityList = try decoder.decode([MVPCity].self, from: data)
                completion(cityList, true)
            } catch {
                completion([], false)
            }
        } failure: { (error) in
            completion([], false)
            print(error ?? "")
        }
    }
}
