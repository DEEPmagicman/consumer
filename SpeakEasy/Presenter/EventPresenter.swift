//
//  EventPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

final class EventPresenter {
    static func getEvents(from: Int? = 0, venueId: String, time: String = "FUTURE", venueTimeZone: String? = nil, city: String? = nil, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ eventList: [Event], _ hasMore: Bool) -> Void) {
        let param = ["skip": from ?? 0,
                     "version": "PUBLISHED",
                     "eventStatus": "APPROVED",
                     "timeVersion": time,
                     "status": "ENABLED",
                     "city": city ?? "",
                     "orderBy": "startDateTime|asc"] as [String: Any]
        AFWrapper.getRequest(APIBuilder.`eventURL`(includes: ["eventTicket", "venue.venueSettings", "flyer", "customVenue"]), params: param, headers: Header.header(timeZone: venueTimeZone)) { response in
            
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
    
//    static func getEventDetail(eventId: String, venueTimeZone: String? = nil, promotionLinkId: String = "", completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ eventDetail: Event?, _ errCode: Int?) -> Void) {
//        
//        var param = [String: Any]()
//        if promotionLinkId.replacingOccurrences(of: " ", with: "") != "" {
//            param["promotionLinkId"] = promotionLinkId
//        }
//        AFWrapper.getRequest(APIBuilder.eventDetailURL(eventId), params: param, headers: Header.header(timeZone: venueTimeZone)) { response in
//            
//            guard let responseDic = response as? [String: Any] else {
//                completion(false, nil, nil, nil)
//                return
//            }
//            if let error = responseDic["error"] as? String, let code = responseDic["statusCode"] as? Int {
//                completion(false, error, nil, code)
//            } else if let eventList = Event.parse(responseDic) {
//                completion(true, nil, eventList, nil)
//            } else {
//                completion(false, "internal error", nil, nil)
//            }
//
//        } failure: { error in
//            if let err = error as? NSError, err.code == 0 {
//                completion(false, err.domain, nil, nil)
//                return
//            }
//            completion(false, nil, nil, nil)
//        }
//    }
    
    static func getEventDetail(
        eventId: String,
        venueTimeZone: String? = nil,
        promotionLinkId: String = "",
        completion: @escaping (_ isSuccess: Bool,
                               _ errMsg: String?,
                               _ eventDetail: Event?,
                               _ errCode: Int?) -> Void) {

        var params: [String: Any] = [:]

        params["isDiscounted"] = false

        params["include"] = "flyer,customVenue,eventHasArtist.artist,eventTicketSettings,venue,venue.logo,eventSettings"

        if !promotionLinkId.trimmingCharacters(in: .whitespaces).isEmpty {
            params["promotionLinkId"] = promotionLinkId
        }

        AFWrapper.getRequest(
            APIBuilder.eventDetailURL(eventId),
            params: params,
            headers: nil
        ) { response in

            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil, nil)
                return
            }

            if let error = responseDic["error"] as? String,
               let code = responseDic["statusCode"] as? Int {

                completion(false, error, nil, code)

            } else if let event = Event.parse(responseDic) {
                var newEvent = event
                if let cvDict = responseDic["customVenue"] as? [String: Any] {
                     print("✅ customVenue dict exists in response: \(cvDict)")
                     do {
                         let cvData = try JSONSerialization.data(withJSONObject: cvDict)
                         let cv = try JSONDecoder().decode(CustomVenue.self, from: cvData)
                         newEvent.customVenue = cv
                     } catch {
                     }
                 } else {
                 }

                completion(true, nil, newEvent, nil)

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
    
    static func getEventAttendees(
        eventId: String,
        completion: @escaping (_ isSuccess: Bool,
                               _ errMsg: String?,
                               _ attendees: [Attendee]?,
                               _ errCode: Int?) -> Void) {

        var params: [String: Any] = [:]

        params["include"] = "consumerUserImage"
        params["take"] = 10
        params["skip"] = 0
        params["page"] = 1
        params["orderBy"] = "createdAt|desc"

        AFWrapper.getRequest(
            APIBuilder.eventAttendeesURL(eventId),
            params: params,
            headers: nil
        ) { response in

            guard let dict = response as? [String: Any] else {
                completion(false, nil, nil, nil)
                return
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: dict)
                let decoded = try JSONDecoder().decode(AttendeesResponse.self, from: data)
                completion(true, nil, decoded.list, nil)
            } catch {
                print("Decoding error:", error)
                completion(false, "Parsing failed", nil, nil)
            }

        } failure: { error in
            completion(false, error?.localizedDescription, nil, nil)
        }
    }

    static func eventTicketCheckIn(bookingId: String, ticketIds: [String], completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ chekInData: [BookingHasCheckIn]?) -> Void) {
        
        let param = ["bookingId": bookingId,
                     "ticketIds": ticketIds] as [String: Any]
        
        AFWrapper.patchRequest(APIBuilder.eventCheckInAPI, params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let checkInData = responseDic["bookingHasCheckIn"] as? [[String: Any]] else {
                completion(false, nil, nil)
                return
            }
            if let data = [BookingHasCheckIn].parse(checkInData) {
                completion(true, nil, data)
            }
        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain, nil)
                return
            }
            print(error ?? "")
            completion(false, nil, nil)
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
    
    static func getTicketLinks(
        eventId: String,
        completion: @escaping (_ isSuccess: Bool,
                               _ errMsg: String?,
                               _ links: [EventTicketLink]?) -> Void
    ) {

        AFWrapper.getRequest(
            APIBuilder.ticketLinksURL(eventId: eventId), headers: Header.header(timeZone: "")
        ) { response in

            guard let responseArray = response as? [[String: Any]] else {
                completion(false, nil, [])
                return
            }

            if let links = [EventTicketLink].parse(responseArray) {
                completion(true, nil, links)
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
    
    static func getEventFAQs(
        eventId: String,
        completion: @escaping (_ isSuccess: Bool,
                               _ errMsg: String?,
                               _ faqs: [EventFAQ]?,
                               _ errCode: Int?) -> Void
    ) {

        AFWrapper.getRequest(
            APIBuilder.faqsURL(eventId: eventId),
            headers: Header.header()
        ) { response in

            guard let responseArray = response as? [[String: Any]] else {
                completion(false, nil, nil, nil)
                return
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: responseArray)
                let decoded = try JSONDecoder().decode([EventFAQ].self, from: data)
                completion(true, nil, decoded, nil)
            } catch {
                print("FAQ decoding error:", error)
                completion(false, "Parsing failed", nil, nil)
            }

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil, nil)
                return
            }
            completion(false, error?.localizedDescription, nil, nil)
        }
    }
    
    static func getInstagramProfile(
        instagramUserId: String,
        completion: @escaping (_ isSuccess: Bool,
                               _ errMsg: String?,
                               _ profileData: InstagramProfile?) -> Void
    ) {
        
        let params: [String: Any] = [
            "instagramUserId": instagramUserId
        ]
        
        AFWrapper.postRequest(
            APIBuilder.getInstaGramProfile,
            params: params,
            headers: Header.header()
        ) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, "Invalid response", nil)
                return
            }
            if let error = responseDic["error"] as? String {
                completion(false, error, nil)
                return
            }
        
            do {
                let data = try JSONSerialization.data(withJSONObject: responseDic)
                let decoded = try JSONDecoder().decode(InstagramProfile.self, from: data)
                completion(true, nil, decoded)
            } catch {
                print("Decoding error:", error)
                completion(false, "Parsing failed", nil)
            }
            
        } failure: { error in
            
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil)
                return
            }
            
            completion(false, error?.localizedDescription, nil)
        }
    }
}
