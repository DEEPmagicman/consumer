//
//  VenuePresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

final class VenuePresenter {
//    func getVenues(from: Int, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ venueList: [Venue],_ hasMore: Bool) -> Void) {
//        let param = ["skip": from]
//        Loader.show()
//        AFWrapper.getRequest(APIBuilder.venueURL,params: param, headers: Header.header()) { response in
//            
//            guard let responseDic = response as? [String: Any], let menu = responseDic["list"] as? [[String: Any]], let hasMore = responseDic["hasMany"] as? Bool else {
//                completion(false, nil, [], false)
//                return
//            }
//            if let venueList = [Venue].parse(menu) {
//                completion(true, nil, venueList,hasMore)
//            } else {
//                completion(false, "internal error", [], false)
//            }
//
//        } failure: { error in
//            if let err = error as? NSError, err.code == 0 {
//                completion(false, err.domain, [], false)
//                return
//            }
//            completion(false, nil, [], false)
//        }
//    }
        
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
    
    static func getEventVenues(
        venueId: String, skip: Int,
        time: String,
        completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ list: [Event], _ hasMore: Bool) -> Void
    ) {
        
        let url = APIBuilder.venueEvents(
            venueId: venueId,
            includes: ["venue.venueAttachment", "flyer", "eventTicketLinks", "eventTicket"],
            take: 5,
            skip: skip,
            timeVersion: time,
            orderBy: "startDateTime|asc"
        )
        
        AFWrapper.getRequest(
            url,
            params: nil,
            headers: Header.header()
        ) { response in
            
            do {
                let data = try JSONSerialization.data(withJSONObject: response)
                let decoded = try JSONDecoder().decode(EventResponse.self, from: data)
                
                completion(true, nil, decoded.list, decoded.hasMany)
                
            } catch {
                completion(false, error.localizedDescription, [], false)
            }
            
        } failure: { error in
            
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [], false)
                return
            }
            
            completion(false, nil, [], false)
        }
    }

    static func getVenueList(
        skip: Int,
        completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ venues: [ClipVenue], _ hasMany: Bool) -> Void
    ) {
        let params: [String: Any] = [
            "skip": skip,
            "take": 10,
            "include": [
                "logo",
                "venueAttachment"
            ],
            "bookingStatus": "OPEN",
            "city": UserDefault.shared.localCity,
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

            let hasMany = responseDic["hasMany"] as? Bool ?? false

            if let venues = [ClipVenue].parse(list) {
                completion(true, nil, venues, hasMany)
            } else {
                completion(false, "internal error", [], false)
            }

        } failure: { error in

            if let err = error as NSError?, err.code == 0 {
                completion(false, err.domain, [], false)
                return
            }

            completion(false, nil, [], false)
        }
    }
}
