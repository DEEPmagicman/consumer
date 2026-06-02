//
//  VenueService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 02/06/26.
//

import Foundation

final class VenueService {
    
    // MARK: - Venue List
    
    func fetchVenueList(
        skip: Int,
        status: String = "OPEN",
        city: String? = nil,
        completion: @escaping (
            Bool,
            String?,
            [ClipVenue],
            Bool
        ) -> Void
    ) {
        
        let params: [String: Any] = [
            "skip": skip,
            "take": 10,
            "include": [
                "logo",
                "venueAttachment"
            ],
            "bookingStatus": status,
            "city": city ?? UserDefault.shared.localCity,
            "orderBy": "createdAt|desc"
        ]
        
        AFWrapper.getRequest(
            APIBuilder.venueListURL,
            params: params,
            headers: Header.header()
        ) { response in
            
            guard
                let responseDic = response as? [String: Any],
                let list = responseDic["list"] as? [[String: Any]]
            else {
                
                completion(false, nil, [], false)
                return
            }
            
            let hasMany =
            responseDic["hasMany"] as? Bool ?? false
            
            guard let venues = [ClipVenue].parse(list) else {
                
                completion(
                    false,
                    "Internal Error",
                    [],
                    false
                )
                
                return
            }
            
            completion(
                true,
                nil,
                venues,
                hasMany
            )
            
        } failure: { error in
            
            if let err = error as NSError?,
               err.code == 0 {
                
                completion(
                    false,
                    err.domain,
                    [],
                    false
                )
                
                return
            }
            
            completion(
                false,
                nil,
                [],
                false
            )
        }
    }
    
    // MARK: - Venue Detail
    
    func fetchVenueDetail(
        venueId: String,
        venueTimeZone: String? = nil,
        doormanId: String = "",
        completion: @escaping (
            Bool,
            String?,
            ClipVenue?
        ) -> Void
    ) {
        
        AFWrapper.getRequest(
            APIBuilder.MVPVenueDetailURL(venueId),
            params: nil,
            headers: Header.header(
                timeZone: venueTimeZone,
                doormanId: doormanId
            )
        ) { response in
            
            guard let responseDic =
                    response as? [String: Any]
            else {
                
                completion(
                    false,
                    nil,
                    nil
                )
                
                return
            }
            
            if let venue =
                ClipVenue.parse(responseDic) {
                
                completion(
                    true,
                    nil,
                    venue
                )
                
            } else {
                
                completion(
                    false,
                    "Internal Error",
                    nil
                )
            }
            
        } failure: { error in
            
            if let err = error as NSError?,
               err.code == 0 {
                
                completion(
                    false,
                    err.domain,
                    nil
                )
                
                return
            }
            
            completion(
                false,
                nil,
                nil
            )
        }
    }
    
    // MARK: - Deep Link
    
    func fetchDeepLinkData(
        id: String,
        completion: @escaping (
            Bool,
            String?,
            String?,
            String?
        ) -> Void
    ) {
        
        Loader.show()
        
        AFWrapper.getRequest(
            APIBuilder.deepLinkURL(id),
            params: nil,
            headers: Header.header()
        ) { response in
            
            guard
                let responseDic = response as? [String: Any],
                let venueId = responseDic["venueId"] as? String,
                let doormanId = responseDic["doormanId"] as? String
            else {
                
                completion(
                    false,
                    nil,
                    nil,
                    nil
                )
                
                return
            }
            
            completion(
                true,
                nil,
                doormanId,
                venueId
            )
            
        } failure: { error in
            
            if let err = error as NSError?,
               err.code == 0 {
                
                completion(
                    false,
                    err.domain,
                    nil,
                    nil
                )
                
                return
            }
            
            completion(
                false,
                nil,
                nil,
                nil
            )
        }
    }
    
    // MARK: - Discover Venue List
    
    func fetchVenuesForDiscover(
        skip: Int,
        bookingStatus: String,
        city: String,
        completion: @escaping (
            Bool,
            String?,
            [ClipVenue],
            Bool
        ) -> Void
    ) {
        
        let params: [String: Any] = [
            "skip": skip,
            "bookingStatus": bookingStatus,
            "city": city
        ]
        
        AFWrapper.getRequest(
            APIBuilder.MVPVenueListURL,
            params: params,
            headers: Header.header()
        ) { response in
            
            guard
                let responseDic = response as? [String: Any],
                let venueArray = responseDic["list"] as? [[String: Any]],
                let hasMany = responseDic["hasMany"] as? Bool
            else {
                
                completion(
                    false,
                    "Invalid Response",
                    [],
                    false
                )
                
                return
            }
            
            do {
                
                let data =
                try JSONSerialization.data(
                    withJSONObject: venueArray
                )
                
                let venues =
                try JSONDecoder().decode(
                    [ClipVenue].self,
                    from: data
                )
                
                completion(
                    true,
                    nil,
                    venues,
                    hasMany
                )
                
            } catch {
                
                completion(
                    false,
                    error.localizedDescription,
                    [],
                    false
                )
            }
            
        } failure: { error in
            
            if let err = error as NSError?,
               err.code == 0 {
                
                completion(
                    false,
                    err.domain,
                    [],
                    false
                )
                
                return
            }
            
            completion(
                false,
                nil,
                [],
                false
            )
        }
    }
    // MARK: - Deep Link
    
    func fetchDeepLinkData(
        _ id: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ doormanId: String?,
            _ venueId: String?
        ) -> Void
    ) {
        
        Loader.show()
        
        AFWrapper.getRequest(
            APIBuilder.deepLinkURL(id),
            params: nil,
            headers: Header.header()
        ) { response in
            
            guard let responseDic = response as? [String: Any],
                  let venueId = responseDic["venueId"] as? String,
                  let doormanId = responseDic["doormanId"] as? String
            else {
                
                completion(
                    false,
                    nil,
                    nil,
                    nil
                )
                
                return
            }
            
            completion(
                true,
                nil,
                doormanId,
                venueId
            )
            
        } failure: { error in
            
            if let err = error as? NSError,
               err.code == 0 {
                
                completion(
                    false,
                    err.domain,
                    nil,
                    nil
                )
                
                return
            }
            
            completion(
                false,
                nil,
                nil,
                nil
            )
        }
    }
    
    // MARK: - MVP City List
    
    func fetchCityList(
        completion: @escaping (
            _ cityList: [MVPCity],
            _ isSuccess: Bool,
            _ errMsg: String?
        ) -> Void
    ) {
        
        AFWrapper.getRequest(
            APIBuilder.mvpCityListURL,
            params: nil,
            headers: Header.unauthorizedHeader()
        ) { response in
            
            guard let responseDict = response as? [String: Any],
                  let cityArray = responseDict["city"] as? [[String: Any]]
            else {
                
                completion([], false, nil)
                return
            }
            
            do {
                
                let data = try JSONSerialization.data(
                    withJSONObject: cityArray
                )
                
                let cityList = try JSONDecoder().decode(
                    [MVPCity].self,
                    from: data
                )
                
                completion(
                    cityList,
                    true,
                    nil
                )
                
            } catch {
                
                completion(
                    [],
                    false,
                    error.localizedDescription
                )
            }
            
        } failure: { _ in
            
            completion(
                [],
                false,
                nil
            )
        }
    }
}
