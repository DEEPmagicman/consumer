//
//  EventService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 02/06/26.
//

import Foundation

final class EventService {

    // MARK: - Events
    
    func fetchEvents(
        from: Int? = 0,
        venueId: String,
        time: String = "FUTURE",
        venueTimeZone: String? = nil,
        city: String? = nil,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ eventList: [Event],
            _ hasMore: Bool
        ) -> Void
    ) {
        
        let params: [String: Any] = [
            "skip": from ?? 0,
            "version": "PUBLISHED",
            "eventStatus": "APPROVED",
            "timeVersion": time,
            "status": "ENABLED",
            "city": city ?? "",
            "orderBy": "startDateTime|asc"
        ]
        
        AFWrapper.getRequest(
            APIBuilder.eventURL(
                includes: [
                    "eventTicket",
                    "venue.venueSettings",
                    "flyer",
                    "customVenue"
                ]
            ),
            params: params,
            headers: Header.header(
                timeZone: venueTimeZone
            )
        ) { response in
            
            guard
                let responseDic = response as? [String: Any],
                let list = responseDic["list"] as? [[String: Any]],
                let hasMore = responseDic["hasMany"] as? Bool
            else {
                
                completion(
                    false,
                    nil,
                    [],
                    false
                )
                
                return
            }
            
            if let eventList = [Event].parse(list) {
                
                completion(
                    true,
                    nil,
                    eventList,
                    hasMore
                )
                
            } else {
                
                completion(
                    false,
                    "Internal Error",
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
    
    func fetchVenueEvents(
        venueId: String,
        skip: Int,
        timeVersion: String,
        completion: @escaping (
            Bool,
            String?,
            [Event],
            Bool
        ) -> Void
    ) {

        let url = APIBuilder.venueEvents(
            venueId: venueId,
            includes: [
                "venue.venueAttachment",
                "flyer",
                "eventTicketLinks",
                "eventTicket"
            ],
            take: 5,
            skip: skip,
            timeVersion: timeVersion,
            orderBy: "startDateTime|asc"
        )

        AFWrapper.getRequest(
            url,
            params: nil,
            headers: Header.header()
        ) { response in

            do {

                let data =
                try JSONSerialization.data(
                    withJSONObject: response
                )

                let decoded =
                try JSONDecoder().decode(
                    EventResponse.self,
                    from: data
                )

                completion(
                    true,
                    nil,
                    decoded.list,
                    decoded.hasMany
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
    
    // MARK: - Event Detail
        
    func fetchEventDetail(
        eventId: String,
        venueTimeZone: String? = nil,
        promotionLinkId: String = "",
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ eventDetail: Event?,
            _ errCode: Int?
        ) -> Void
    ) {

        var params: [String: Any] = [:]

        params["isDiscounted"] = false

        params["include"] =
        "flyer,customVenue,eventHasArtist.artist,eventTicketSettings,venue,venue.logo,eventSettings"

        if !promotionLinkId
            .trimmingCharacters(in: .whitespaces)
            .isEmpty {

            params["promotionLinkId"] =
            promotionLinkId
        }

        AFWrapper.getRequest(
            APIBuilder.eventDetailURL(eventId),
            params: params,
            headers: nil
        ) { response in

            guard let responseDic =
                    response as? [String: Any]
            else {

                completion(
                    false,
                    nil,
                    nil,
                    nil
                )

                return
            }

            if let error =
                responseDic["error"] as? String,
               let code =
                responseDic["statusCode"] as? Int {

                completion(
                    false,
                    error,
                    nil,
                    code
                )

            } else if let event =
                        Event.parse(responseDic) {

                var newEvent = event

                if let customVenue =
                    responseDic["customVenue"] as? [String: Any] {

                    do {

                        let data =
                        try JSONSerialization.data(
                            withJSONObject: customVenue
                        )

                        let venue =
                        try JSONDecoder().decode(
                            CustomVenue.self,
                            from: data
                        )

                        newEvent.customVenue = venue

                    } catch { }
                }

                completion(
                    true,
                    nil,
                    newEvent,
                    nil
                )

            } else {

                completion(
                    false,
                    "internal error",
                    nil,
                    nil
                )
            }

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

    // MARK: - FAQ
    
    func fetchEventFAQs(
        eventId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ faqs: [EventFAQ]?,
            _ errCode: Int?
        ) -> Void
    ) {

        AFWrapper.getRequest(
            APIBuilder.faqsURL(eventId: eventId),
            headers: Header.header()
        ) { response in

            guard let responseArray =
                    response as? [[String: Any]]
            else {

                completion(
                    false,
                    nil,
                    nil,
                    nil
                )

                return
            }

            do {

                let data = try JSONSerialization.data(
                    withJSONObject: responseArray
                )

                let decoded = try JSONDecoder().decode(
                    [EventFAQ].self,
                    from: data
                )

                completion(
                    true,
                    nil,
                    decoded,
                    nil
                )

            } catch {

                completion(
                    false,
                    "Parsing failed",
                    nil,
                    nil
                )
            }

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
                error?.localizedDescription,
                nil,
                nil
            )
        }
    }

    // MARK: - Attendees
        
    func fetchEventAttendees(
        eventId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ attendees: [Attendee]?,
            _ errCode: Int?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "include": "consumerUserImage",
            "take": 10,
            "skip": 0,
            "page": 1,
            "orderBy": "createdAt|desc"
        ]

        AFWrapper.getRequest(
            APIBuilder.eventAttendeesURL(eventId),
            params: params,
            headers: nil
        ) { response in

            guard let dict =
                    response as? [String: Any]
            else {

                completion(
                    false,
                    nil,
                    nil,
                    nil
                )

                return
            }

            do {

                let data = try JSONSerialization.data(
                    withJSONObject: dict
                )

                let decoded =
                try JSONDecoder().decode(
                    AttendeesResponse.self,
                    from: data
                )

                completion(
                    true,
                    nil,
                    decoded.list,
                    nil
                )

            } catch {

                completion(
                    false,
                    "Parsing failed",
                    nil,
                    nil
                )
            }

        } failure: { error in

            completion(
                false,
                error?.localizedDescription,
                nil,
                nil
            )
        }
    }
    
    // MARK: - Ticket
    
    func fetchTicketLinks(
        eventId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ links: [EventTicketLink]?
        ) -> Void
    ) {

        AFWrapper.getRequest(
            APIBuilder.ticketLinksURL(eventId: eventId),
            headers: Header.header(timeZone: "")
        ) { response in

            guard let responseArray =
                    response as? [[String: Any]]
            else {

                completion(
                    false,
                    nil,
                    []
                )

                return
            }

            if let links =
                [EventTicketLink].parse(responseArray) {

                completion(
                    true,
                    nil,
                    links
                )

            } else {

                completion(
                    false,
                    "internal error",
                    []
                )
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    []
                )

                return
            }

            completion(
                false,
                nil,
                []
            )
        }
    }
    
    func fetchTicketsByPassword(
        eventId: String,
        venueTimeZone: String? = nil,
        password: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ tickets: [EventTicket]?
        ) -> Void
    ) {

        AFWrapper.getRequest(
            APIBuilder.getTicketPasswordAPI(eventId),
            params: [
                "password": password
            ],
            headers: Header.header(
                timeZone: venueTimeZone
            )
        ) { response in

            guard let responseArray =
                    response as? [[String: Any]]
            else {

                completion(
                    false,
                    nil,
                    []
                )

                return
            }

            if let tickets =
                [EventTicket].parse(responseArray) {

                completion(
                    true,
                    nil,
                    tickets
                )

            } else {

                completion(
                    false,
                    "internal error",
                    []
                )
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    []
                )

                return
            }

            completion(
                false,
                nil,
                []
            )
        }
    }
}
