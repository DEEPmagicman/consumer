//
//  EventPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

final class EventPresenter {
    static func getEvents(from: Int? = 0, venueId: String, time: String = "FUTURE", venueTimeZone: String? = nil, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ eventList: [Event], _ hasMore: Bool) -> Void) {
        let param = ["skip": from ?? 0,
                     "venueId": venueId,
                     "version": "PUBLISHED",
                     "eventStatus": "APPROVED",
                     "timeVersion": time,
                     "status": "ENABLED",
                     "orderBy": "startDateTime|asc"] as [String : Any]
        AFWrapper.getRequest(APIBuilder.`eventURL`(includes: ["eventTicket", "venue.venueSettings"]), params: param, headers: Header.header(timeZone: venueTimeZone)) { response in
            
            guard let responseDic = response as? [String: Any], let menu = responseDic["list"] as? [[String: Any]], let hasMore = responseDic["hasMany"] as? Bool else {
                completion(false, nil, [], false)
                return
            }
            if let eventList = [Event].parse(menu) {
                completion(true, nil, eventList, hasMore)
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
    
    static func getRecommendedEvents(completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ eventList: [Event]) -> Void) {
        AFWrapper.getRequest(APIBuilder.recommendedEventURL, headers: Header.header()) { response in
            
            guard let responseArray = response as? [[String: Any]] else {
                completion(false, nil, [])
                return
            }
            if let eventList = [Event].parse(responseArray) {
                completion(true, nil, eventList)
            } else {
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
    
    static func getEventDetail(eventId: String, venueTimeZone: String? = nil, promotionLinkId: String = "", completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ eventDetail: Event?, _ errCode: Int?) -> Void) {
        
        var param = [String: Any]()
        if promotionLinkId.replacingOccurrences(of: " ", with: "") != "" {
            param["promotionLinkId"] = promotionLinkId
        }
        AFWrapper.getRequest(APIBuilder.eventDetailURL(eventId), params: param, headers: Header.header(timeZone: venueTimeZone)) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil, nil)
                return
            }
            if let error = responseDic["error"] as? String, let code = responseDic["statusCode"] as? Int {
                completion(false, error, nil, code)
            } else if let eventList = Event.parse(responseDic) {
                completion(true, nil, eventList, nil)
            } else {
                completion(false, "internal error", nil, nil)
            }

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil, nil)
                return
            }
            completion(false, nil, nil, nil)
        }
    }
    
    static func eventTicketCheckIn(bookingId: String, ticketIds: [String], completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        
        let param = ["bookingId" : bookingId,
                     "ticketIds": ticketIds] as [String: Any]
        
        AFWrapper.patchRequest(APIBuilder.eventCheckInAPI, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? Bool else {
                completion(false, nil)
                return
            }
            completion(responseDic, nil)

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain)
                return
            }
            print(error ?? "")
            completion(false, nil)
        }
    }
    
    static func getEventTicketByPassWord(eventId: String, venueTimeZone: String? = nil, password: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ ticket: [EventTicket]?) -> Void) {
        
        AFWrapper.getRequest(APIBuilder.getTicketPasswordAPI(eventId), params: ["password": password], headers: Header.header(timeZone: venueTimeZone)) { response in
            
            guard let responseArray = response as? [[String: Any]] else {
                completion(false, nil, [])
                return
            }
            if let tickets = [EventTicket].parse(responseArray) {
                completion(true, nil, tickets)
            } else {
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
}
