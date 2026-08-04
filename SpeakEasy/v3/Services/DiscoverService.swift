//
//  DiscoverService.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 18/06/26.
//

import Foundation

struct DiscoverHomeData {
    let trendingEvents: [Event]
    let eventsTonight: [Event]
    let events: [Event]
    let venues: [ClipVenue]
}

struct DiscoverPage<T> {
    let list: [T]
    let hasMore: Bool
    let total: Int
    let count: Int
}

struct DiscoverEventTimeWindow {
    let startDateTime: String?
    let endDateTime: String?

    static func cityEvents(now: Date = Date()) -> DiscoverEventTimeWindow {
        DiscoverEventTimeWindow(
            startDateTime: Self.apiString(from: now),
            endDateTime: nil
        )
    }

    static func tonight(now: Date = Date()) -> DiscoverEventTimeWindow {
        DiscoverEventTimeWindow(
            startDateTime: Self.apiString(from: now),
            endDateTime: Self.apiString(from: Self.nextDayEightAM(after: now))
        )
    }

    static func selectedDay(_ dateString: String) -> DiscoverEventTimeWindow {
        let day = Self.dayDate(from: dateString) ?? Date()
        let start = Self.eightAM(on: day)
        let end =
        Self.calendar.date(
            byAdding: .day,
            value: 1,
            to: start
        ) ?? start

        return DiscoverEventTimeWindow(
            startDateTime: Self.apiString(from: start),
            endDateTime: Self.apiString(from: end)
        )
    }

    static func selectedRange(
        startDateString: String,
        endDateString: String
    ) -> DiscoverEventTimeWindow {
        let startDay = Self.dayDate(from: startDateString) ?? Date()
        let endDay = Self.dayDate(from: endDateString) ?? startDay
        let start = Self.eightAM(on: min(startDay, endDay))
        let endDayEightAM = Self.eightAM(on: max(startDay, endDay))
        let end =
        Self.calendar.date(
            byAdding: .day,
            value: 1,
            to: endDayEightAM
        ) ?? endDayEightAM

        return DiscoverEventTimeWindow(
            startDateTime: Self.apiString(from: start),
            endDateTime: Self.apiString(from: end)
        )
    }
}

enum DiscoverEventListType: String {
    case trendingEvents = "TRENDING_EVENTS"
    case eventsTonight = "EVENTS_TONIGHT"
    case eventsInCity = "EVENTS_IN_CITY"
}

final class DiscoverService {

    func fetchDiscover(
        city: String,
        timeZone: String = TimeZone.current.identifier,
        completion: @escaping (
            Bool,
            String?,
            DiscoverHomeData?
        ) -> Void
    ) {

        AFWrapper.getRequest(
            APIBuilder.discoverURL(city: city),
            params: nil,
            headers: Header.header(timeZone: timeZone)
        ) { response in

            guard let responseDic = response as? [String: Any] else {
                completion(false, "Invalid Response", nil)
                return
            }

            let eventsTonightPage =
            responseDic["eventsTonight"] as? [String: Any]

            let trendingEventsPage =
            responseDic["trendingEvents"] as? [String: Any]

            let eventsPage =
            responseDic["eventsInCity"] as? [String: Any]

            let venuesPage =
            responseDic["venues"] as? [String: Any]

            let eventsTonightList =
            eventsTonightPage?["list"] as? [[String: Any]] ?? []

            let trendingEventsList =
            trendingEventsPage?["list"] as? [[String: Any]] ?? []

            let eventsList =
            eventsPage?["list"] as? [[String: Any]] ?? []

            let venuesList =
            venuesPage?["list"] as? [[String: Any]] ?? []

            guard
                let trendingEvents = Self.parseEvents(trendingEventsList),
                let eventsTonight = Self.parseEvents(eventsTonightList),
                let events = Self.parseEvents(eventsList),
                let venues = Self.parseVenues(venuesList)
            else {
                completion(false, "Internal Error", nil)
                return
            }

            let data = DiscoverHomeData(
                trendingEvents: trendingEvents,
                eventsTonight: eventsTonight,
                events: events,
                venues: venues
            )

            completion(true, nil, data)

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, nil)
                return
            }

            completion(false, nil, nil)
        }
    }

    func fetchDiscoverEvents(
        city: String,
        venueId: String? = nil,
        skip: Int,
        take: Int = 10,
        timeWindow: DiscoverEventTimeWindow? = nil,
        eventListType: DiscoverEventListType? = nil,
        isPremiumOnly: Bool? = nil,
        search: String? = nil,
        timeZone: String = TimeZone.current.identifier,
        completion: @escaping (
            Bool,
            String?,
            DiscoverPage<Event>?
        ) -> Void
    ) {

        var params: [String: Any] = [
            "city": city,
            "skip": skip,
            "take": take
        ]

        if let venueId,
           !venueId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["venueId"] = venueId
        }

        if let eventListType {
            params["eventListType"] = eventListType.rawValue
        }

        if let startDateTime = timeWindow?.startDateTime {
            params["startDateTime"] = startDateTime
        }

        if let endDateTime = timeWindow?.endDateTime {
            params["endDateTime"] = endDateTime
        }

        if let isPremiumOnly {
            params["isPremiumOnly"] = isPremiumOnly
        }

        if let search,
           !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["search"] = search
        }

        AFWrapper.getRequest(
            APIBuilder.discoverEventsURL,
            params: params,
            headers: Header.header(timeZone: timeZone)
        ) { response in

            guard let responseDic = response as? [String: Any],
                  let list = responseDic["list"] as? [[String: Any]],
                  let events = Self.parseEvents(list) else {

                completion(false, "Invalid Response", nil)
                return
            }

            completion(
                true,
                nil,
                DiscoverPage(
                    list: events,
                    hasMore: responseDic["hasMany"] as? Bool ?? false,
                    total: responseDic["total"] as? Int ?? events.count,
                    count: responseDic["count"] as? Int ?? events.count
                )
            )

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, nil)
                return
            }

            completion(false, nil, nil)
        }
    }

    func fetchDiscoverVenues(
        city: String,
        skip: Int,
        take: Int = 10,
        search: String? = nil,
        checkIsPremium: Bool = false,
        timeZone: String = TimeZone.current.identifier,
        completion: @escaping (
            Bool,
            String?,
            DiscoverPage<ClipVenue>?
        ) -> Void
    ) {

        var params: [String: Any] = [
            "city": city,
            "skip": skip,
            "take": take
        ]

        if let search,
           !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["search"] = search
        }

        if checkIsPremium {
            params["checkIsPremium"] = "true"
        }
        print(params)

        AFWrapper.getRequest(
            APIBuilder.discoverVenuesURL,
            params: params,
            headers: Header.header(timeZone: timeZone)
        ) { response in

            guard let responseDic = response as? [String: Any],
                  let list = responseDic["list"] as? [[String: Any]],
                  let venues = Self.parseVenues(list) else {

                completion(false, "Invalid Response", nil)
                return
            }

            completion(
                true,
                nil,
                DiscoverPage(
                    list: venues,
                    hasMore: responseDic["hasMany"] as? Bool ?? false,
                    total: responseDic["total"] as? Int ?? venues.count,
                    count: responseDic["count"] as? Int ?? venues.count
                )
            )

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, nil)
                return
            }

            completion(false, nil, nil)
        }
    }

    func fetchArtistEvents(
        artistId: String,
        venueId: String,
        skip: Int,
        take: Int = 10,
        startDateTime: String = DiscoverEventTimeWindow.apiString(from: Date()),
        timeZone: String = TimeZone.current.identifier,
        completion: @escaping (
            Bool,
            String?,
            DiscoverPage<Event>?
        ) -> Void
    ) {

        let trimmedArtistId = artistId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedVenueId = venueId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedArtistId.isEmpty else {
            completion(
                false,
                "Artist not found",
                nil
            )
            return
        }

        var params: [String: Any] = [
            "startDateTime": startDateTime,
            "skip": skip,
            "take": take
        ]

        if !trimmedVenueId.isEmpty {
            params["venueId"] = trimmedVenueId
        }

        let url = trimmedVenueId.isEmpty
            ? APIBuilder.artistEventsURL(artistId: trimmedArtistId)
            : APIBuilder.artistVenueEventsURL(artistId: trimmedArtistId)

        AFWrapper.getRequest(
            url,
            params: params,
            headers: Header.header(timeZone: timeZone)
        ) { response in

            guard let responseDic = response as? [String: Any],
                  let list = responseDic["list"] as? [[String: Any]],
                  let events = Self.parseEvents(list) else {

                completion(false, "Invalid Response", nil)
                return
            }

            completion(
                true,
                nil,
                DiscoverPage(
                    list: events,
                    hasMore: responseDic["hasMany"] as? Bool ?? false,
                    total: responseDic["total"] as? Int ?? events.count,
                    count: responseDic["count"] as? Int ?? events.count
                )
            )

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, nil)
                return
            }

            completion(false, nil, nil)
        }
    }

    func fetchArtists(
        venueId: String,
        skip: Int,
        take: Int = 10,
        startDateTime: String = DiscoverEventTimeWindow.apiString(from: Date()),
        timeZone: String = TimeZone.current.identifier,
        completion: @escaping (
            Bool,
            String?,
            DiscoverPage<Artists>?
        ) -> Void
    ) {

        let trimmedVenueId = venueId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedVenueId.isEmpty else {
            completion(false, "Partner not found", nil)
            return
        }

        let params: [String: Any] = [
            "venueId": trimmedVenueId,
            "startDateTime": startDateTime,
            "skip": skip,
            "take": take
        ]

        AFWrapper.getRequest(
            APIBuilder.artistsURL,
            params: params,
            headers: Header.header(timeZone: timeZone)
        ) { response in

            guard let responseDic = response as? [String: Any],
                  let list = responseDic["list"] as? [[String: Any]],
                  let artists = Self.parseArtists(list) else {

                completion(false, "Invalid Response", nil)
                return
            }

            completion(
                true,
                nil,
                DiscoverPage(
                    list: artists,
                    hasMore: responseDic["hasMany"] as? Bool ?? false,
                    total: responseDic["total"] as? Int ?? artists.count,
                    count: responseDic["count"] as? Int ?? artists.count
                )
            )

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, nil)
                return
            }

            completion(false, nil, nil)
        }
    }
}

private extension DiscoverService {

    static func parseEvents(
        _ list: [[String: Any]]
    ) -> [Event]? {

        if let events = decode([Event].self, from: list) {
            return events
        }

        return decode(
            [Event].self,
            from: list.map { normalizedEvent($0) }
        )
    }

    static func parseVenues(
        _ list: [[String: Any]]
    ) -> [ClipVenue]? {

        if let venues = decode([ClipVenue].self, from: list) {
            return venues
        }

        return decode(
            [ClipVenue].self,
            from: list.map { normalizedVenue($0) }
        )
    }

    static func parseArtists(
        _ list: [[String: Any]]
    ) -> [Artists]? {

        if let artists = decode([Artists].self, from: list) {
            return artists
        }

        return decode(
            [Artists].self,
            from: list.map { normalizedArtist($0) }
        )
    }

    static func decode<T: Decodable>(
        _ type: T.Type,
        from object: Any
    ) -> T? {

        guard JSONSerialization.isValidJSONObject(object) else {
            return nil
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: object)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return nil
        }
    }

    static func normalizedEvent(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var event = dictionary

        event["description"] = event["description"] ?? ""
        event["isEnableOnlineTables"] =
        event["isEnableOnlineTables"] ?? false
        event["isEnable3DMap"] =
        event["isEnable3DMap"] ?? false
        event["isEnableReservationRequest"] =
        event["isEnableReservationRequest"] ?? false

        if let venue = event["venue"] as? [String: Any] {
            event["venue"] = normalizedVenue(venue)
        }

        return event
    }

    static func normalizedVenue(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var venue = dictionary

        let id = venue["id"] as? String ?? ""
        let name = venue["name"] as? String ?? ""
        let now = Date().toString(
            dateFormat: .yyyyMMddTHHmmssSSSz,
            timeZone: TimeZone(identifier: "UTC")
        )

        venue["id"] = id
        venue["uniqueId"] = venue["uniqueId"] ?? id
        venue["name"] = name
        venue["address"] = venue["address"] ?? ""
        venue["city"] = venue["city"] ?? ""
        venue["code"] = venue["code"] ?? ""
        venue["phone"] = venue["phone"] ?? ""
        venue["website"] = venue["website"] ?? ""
        venue["status"] = venue["status"] ?? "ENABLED"
        venue["isDeleted"] = venue["isDeleted"] ?? false
        venue["isPremium"] = venue["isPremium"] ?? false
        venue["createdAt"] = venue["createdAt"] ?? now
        venue["updatedAt"] = venue["updatedAt"] ?? now
        venue["lat"] = venue["lat"] ?? "0"
        venue["lng"] = venue["lng"] ?? "0"

        if let logo = venue["logo"] as? [String: Any] {
            venue["logo"] = normalizedMedia(logo)
        }

        if let attachments =
            venue["venueAttachment"] as? [[String: Any]] {

            venue["venueAttachment"] =
            attachments.map { normalizedMedia($0) }
        } else if let logo = venue["logo"] as? [String: Any] {
//            venue["venueAttachment"] = [normalizedMedia(logo)]
        }

        return venue
    }

    static func normalizedArtist(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var artist = dictionary

        artist["id"] = stringValue(artist["id"])
        artist["name"] = stringValue(artist["name"])
        artist["instagramUsername"] = stringValue(artist["instagramUsername"])
        artist["status"] = stringValue(artist["status"], fallback: "ENABLED")
        artist["source"] = stringValue(artist["source"])

        if let image = artist["artistImage"] as? [String: Any] {
            artist["artistImage"] = normalizedMedia(image)
        } else if artist["artistImage"] is NSNull {
            artist["artistImage"] = nil
        }

        return artist
    }

    static func stringValue(
        _ value: Any?,
        fallback: String = ""
    ) -> String {

        if let value = value as? String {
            return value
        }

        return fallback
    }

    static func normalizedMedia(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var media = dictionary
        let key = media["key"] as? String ?? ""

        media["key"] = key
        media["name"] = media["name"] ?? key
        media["description"] = media["description"] ?? ""

        return media
    }
}

private extension DiscoverEventTimeWindow {

    static var timeZone: TimeZone {
        Constant.venueTimeZone ?? .current
    }

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func apiString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = DateFormat.yyyyMMddHHmmss.rawValue
        return formatter.string(from: date)
    }

    static func dayDate(from string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        let apiFormatter = DateFormatter()
        apiFormatter.locale = Locale(identifier: "en_US_POSIX")
        apiFormatter.timeZone = timeZone
        apiFormatter.dateFormat = DateFormat.YYYYMMDD.rawValue

        if let date = apiFormatter.date(from: trimmed) {
            return date
        }

        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "en_US_POSIX")
        displayFormatter.timeZone = timeZone
        displayFormatter.dateFormat = "yyyy MMM dd"

        let year = calendar.component(.year, from: Date())
        return displayFormatter.date(from: "\(year) \(trimmed)")
    }

    static func eightAM(on date: Date) -> Date {
        var components =
        calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        components.hour = 8
        components.minute = 0
        components.second = 0

        return calendar.date(from: components) ?? date
    }

    static func nextDayEightAM(after date: Date) -> Date {
        let tomorrow =
        calendar.date(
            byAdding: .day,
            value: 1,
            to: date
        ) ?? date

        return eightAM(on: tomorrow)
    }
}
