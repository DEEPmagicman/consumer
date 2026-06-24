//
//  EventService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 02/06/26.
//

import Foundation

struct EventDetailBundle {
    let event: Event
    let seatingAreas: [SeatingArea]
    let faqs: [EventFAQ]
    let ticketLinks: [EventTicketLink]
    let attendees: [Attendee]?
}

struct SavedEventRelation: Codable {
    let id: String?
    let consumerUserId: String?
    let eventId: String?
    let status: String?
    let isDeleted: Bool?
    let createdAt: String?
    let updatedAt: String?
}

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

    func fetchV3EventDetail(
        eventId: String,
        venueTimeZone: String? = nil,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ detail: EventDetailBundle?,
            _ errCode: Int?
        ) -> Void
    ) {

        AFWrapper.getRequest(
            APIBuilder.v3EventDetailURL(eventId),
            params: nil,
            headers: Header.header(timeZone: venueTimeZone)
        ) { [weak self] response in

            guard let self else { return }

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

                return
            }

            guard var event =
                    self.decode(
                        Event.self,
                        from: responseDic
                    )
            else {

                completion(
                    false,
                    "internal error",
                    nil,
                    nil
                )

                return
            }

            if let savedEventId =
                self.savedEventId(from: responseDic) {

                event.savedEventId = savedEventId
                event.hasSavedEvent = true
            }

            let seatingAreas =
            self.decodeArray(
                [SeatingArea].self,
                from: responseDic["seatingArea"]
            )

            let faqs =
            self.decodeArray(
                [EventFAQ].self,
                from: responseDic["eventFAQ"]
            )

            let ticketLinks =
            self.decodeArray(
                [EventTicketLink].self,
                from: responseDic["eventTicketLinks"]
            )

            completion(
                true,
                nil,
                EventDetailBundle(
                    event: event,
                    seatingAreas: seatingAreas,
                    faqs: faqs,
                    ticketLinks: ticketLinks,
                    attendees: self.decodeAttendees(
                        from: responseDic
                    )
                ),
                nil
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

    func saveEvent(
        uniqueId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ savedEvent: SavedEventRelation?
        ) -> Void
    ) {

        AFWrapper.postRequest(
            APIBuilder.v3SavedEventURL(uniqueId),
            params: nil,
            headers: Header.header()
        ) { [weak self] response in

            guard let self else { return }

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

            if let savedEvent =
                self.decode(
                    SavedEventRelation.self,
                    from: responseDic
                ) {

                completion(
                    true,
                    nil,
                    savedEvent
                )

            } else {

                completion(
                    false,
                    "internal error",
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
                error?.localizedDescription,
                nil
            )
        }
    }

    func unsaveEvent(
        savedEventId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ savedEvent: SavedEventRelation?
        ) -> Void
    ) {

        AFWrapper.deleteRequest(
            APIBuilder.v3SavedEventURL(savedEventId),
            headers: Header.header()
        ) { [weak self] response in

            guard let self else { return }

            let savedEvent =
            self.decode(
                SavedEventRelation.self,
                from: response
            )

            completion(
                true,
                nil,
                savedEvent
            )

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
                error?.localizedDescription,
                nil
            )
        }
    }

    func fetchSavedEvents(
        skip: Int,
        take: Int = 10,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ bookings: [Booking],
            _ hasMany: Bool
        ) -> Void
    ) {

        let params: [String: Any] = [
            "skip": skip,
            "take": take
        ]

        AFWrapper.getRequest(
            APIBuilder.v3SavedEventsURL,
            params: params,
            headers: Header.header()
        ) { [weak self] response in

            guard let self else { return }

            guard let responseDic =
                    response as? [String: Any],
                  let list =
                    responseDic["list"] as? [[String: Any]]
            else {

                completion(
                    false,
                    nil,
                    [],
                    false
                )

                return
            }

            let hasMany =
            responseDic["hasMany"] as? Bool ?? false

            let bookings =
            list.compactMap {
                self.decode(
                    Booking.self,
                    from: self.normalizedSavedEventItem($0)
                )
            }

            completion(
                true,
                nil,
                bookings,
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
                error?.localizedDescription,
                [],
                false
            )
        }
    }

    func fetchSavedEventId(
        uniqueId: String,
        skip: Int = 0,
        take: Int = 50,
        completion: @escaping (
            _ savedEventId: String?
        ) -> Void
    ) {

        fetchSavedEvents(
            skip: skip,
            take: take
        ) { [weak self] isSuccess, _, bookings, hasMany in

            guard let self else { return }

            guard isSuccess else {
                completion(nil)
                return
            }

            if let savedEventId =
                bookings.first(
                    where: {
                        $0.event?.uniqueId == uniqueId
                    }
                )?.event?.savedEventId {

                completion(savedEventId)
                return
            }

            if hasMany {
                self.fetchSavedEventId(
                    uniqueId: uniqueId,
                    skip: skip + take,
                    take: take,
                    completion: completion
                )
                return
            }

            completion(nil)
        }
    }
        
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

    private func decode<T: Decodable>(
        _ type: T.Type,
        from object: Any?
    ) -> T? {

        guard let object,
              !(object is NSNull),
              JSONSerialization.isValidJSONObject(object)
        else {
            return nil
        }

        do {
            let data =
            try JSONSerialization.data(
                withJSONObject: object
            )

            return try JSONDecoder().decode(
                type,
                from: data
            )

        } catch {

            print("Event detail parsing error:", error)
            return nil
        }
    }

    private func decodeArray<T: Decodable>(
        _ type: [T].Type,
        from object: Any?
    ) -> [T] {

        decode(
            type,
            from: object
        ) ?? []
    }

    private func decodeAttendees(
        from responseDic: [String: Any]
    ) -> [Attendee]? {

        if let rawAttendees = responseDic["attendees"] as? [[String: Any]],
           let attendees =
            decode(
                [Attendee].self,
                from: rawAttendees
            ) {

            return attendees
        }

        if let rawAttendees = responseDic["eventAttendees"] as? [[String: Any]],
           let attendees =
            decode(
                [Attendee].self,
                from: rawAttendees
            ) {

            return attendees
        }

        if let rawAttendees = responseDic["attendees"] as? [String: Any],
           let attendeesResponse =
            decode(
                AttendeesResponse.self,
                from: rawAttendees
            ) {

            return attendeesResponse.list
        }

        return nil
    }

    private func savedEventId(
        from responseDic: [String: Any]
    ) -> String? {

        if let savedEventId =
            responseDic["savedEventId"] as? String {

            return savedEventId
        }

        if let savedEvent =
            responseDic["savedEvent"] as? [String: Any],
           let id =
            savedEvent["id"] as? String {

            return id
        }

        if let savedEvent =
            responseDic["saved"] as? [String: Any],
           let id =
            savedEvent["id"] as? String {

            return id
        }

        return nil
    }

    private func normalizedSavedEventItem(
        _ item: [String: Any]
    ) -> [String: Any] {

        var item = item

        if let consumerUserId =
            item["consumerUserId"] as? String {

            item["consumerUserId"] = [consumerUserId]
        }

        item["bookingHasItem"] =
        item["bookingHasItem"] ?? []

        item["createdAt"] =
        item["createdAt"] ??
        Date().string(format: .yyyyMMddTHHmmssSSSz)

        if var event =
            item["event"] as? [String: Any] {

            event["description"] =
            event["description"] ?? ""

            event["isEnableOnlineTables"] =
            event["isEnableOnlineTables"] ?? false

            event["isEnable3DMap"] =
            event["isEnable3DMap"] ?? false

            event["isEnableReservationRequest"] =
            event["isEnableReservationRequest"] ?? false

            event["eventTicket"] =
            event["eventTicket"] ?? []

            event["eventAddOnTicket"] =
            event["eventAddOnTicket"] ?? []

            event["protectedEventTicket"] =
            event["protectedEventTicket"] ?? []

            event["protectedeventAddOnTicket"] =
            event["protectedeventAddOnTicket"] ?? []

            event["eventGallery"] =
            event["eventGallery"] ?? []

            event["savedEventId"] =
            item["id"]

            event["isSaved"] = true

            if var venue =
                event["venue"] as? [String: Any] {

                venue["isDeleted"] =
                venue["isDeleted"] ?? false

                venue["dressCode"] =
                venue["dressCode"] ?? ""

                venue["website"] =
                venue["website"] ?? ""

                venue["phone"] =
                venue["phone"] ?? ""

                venue["description"] =
                venue["description"] ?? ""

                venue["bookingCode"] =
                venue["bookingCode"] ?? ""

                venue["venueAttachment"] =
                venue["venueAttachment"] ?? []

                event["venue"] = venue

                if item["venue"] == nil {
                    item["venue"] = venue
                }
            }

            item["event"] = event
        }

        return item
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
