//
//  SearchFlowService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 03/06/26.
//

import Foundation

struct SearchFlowResult {
    let venues: [SearchVenueItem]
    let events: [SearchEventItem]
    let artists: [SearchArtistItem]
    let hasMoreVenues: Bool
    let hasMoreEvents: Bool
}

final class SearchFlowService {

    static let shared = SearchFlowService()

    func search(
        keyword: String,
        venueSkip: Int,
        venueTake: Int,
        eventSkip: Int,
        eventTake: Int,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errorMessage: String?,
            _ result: SearchFlowResult
        ) -> Void
    ) {

        let trimmedKeyword =
        keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var params: [String: Any] = [
            "search": trimmedKeyword,
            "eventSkip": eventSkip,
            "eventTake": eventTake,
            "artistSkip": 0,
            "artistTake": 10
        ]

        if venueTake != 0 {
            params["venueSkip"] = venueSkip
            params["venueTake"] = venueTake
        }

        AFWrapper.getRequest(
            APIBuilder.consumerSearchURL,
            params: params,
            headers: Header.header(timeZone: TimeZone.current.identifier)
        ) { response in

            guard let responseDic = response as? [String: Any] else {
                completion(
                    false,
                    "Invalid Response",
                    SearchFlowResult(
                        venues: [],
                        events: [],
                        artists: [],
                        hasMoreVenues: false,
                        hasMoreEvents: false
                    )
                )
                return
            }

            let venuePage =
            Self.page(from: responseDic, keys: [
                "venues",
                "venue",
                "venueList",
                "venueData"
            ])

            let eventPage =
            Self.page(from: responseDic, keys: [
                "events",
                "event",
                "eventList",
                "eventData"
            ])

            let artistPage =
            Self.page(from: responseDic, keys: [
                "artists",
                "artist",
                "artistList",
                "artistData"
            ])

            let venueList = Self.list(from: venuePage)
            let eventList = Self.list(from: eventPage)
            let artistList = Self.list(from: artistPage)

            let venues = Self.parseVenues(venueList).map {
                SearchVenueItem(
                    id: $0.id,
                    name: $0.name,
                    imageURL: Self.mediaURL($0.logo?.key ?? $0.venueAttachment?.first?.key),
                    venue: $0
                )
            }

            let events = Self.parseEvents(eventList).map {
                SearchEventItem(
                    id: $0.uniqueId ?? $0.id,
                    title: $0.title,
                    dateText: Self.displayDate(for: $0),
                    imageURL: Self.mediaURL($0.flyer?.key),
                    venueName: $0.venue?.name,
                    event: $0
                )
            }

            let artists = Self.makeArtistItems(
                from: Self.parseArtists(artistList),
                events: events.compactMap(\.event)
            )

            completion(
                true,
                nil,
                SearchFlowResult(
                    venues: venues,
                    events: events,
                    artists: artists,
                    hasMoreVenues: Self.hasMore(from: venuePage, loadedCount: venues.count, requestedTake: venueTake),
                    hasMoreEvents: Self.hasMore(from: eventPage, loadedCount: events.count, requestedTake: eventTake)
                )
            )

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    SearchFlowResult(
                        venues: [],
                        events: [],
                        artists: [],
                        hasMoreVenues: false,
                        hasMoreEvents: false
                    )
                )
                return
            }

            completion(
                false,
                error?.localizedDescription,
                SearchFlowResult(
                    venues: [],
                    events: [],
                    artists: [],
                    hasMoreVenues: false,
                    hasMoreEvents: false
                )
            )
        }
    }

    func searchVenues(
        keyword: String,
        skip: Int = 0,
        take: Int = 10,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errorMessage: String?,
            _ venues: [SearchVenueItem],
            _ hasMore: Bool
        ) -> Void
    ) {

        let trimmedKeyword =
        keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        let params: [String: Any] = [
            "search": trimmedKeyword,
            "skip": skip,
            "take": take
        ]

        AFWrapper.getRequest(
            APIBuilder.consumerSearchVenuesURL,
            params: params,
            headers: Header.header(timeZone: TimeZone.current.identifier)
        ) { response in

            guard let responseDic = response as? [String: Any] else {
                completion(false, "Invalid Response", [], false)
                return
            }

            let page =
            Self.page(from: responseDic, keys: [
                "venues",
                "venue",
                "venueList",
                "venueData"
            ]) ?? responseDic

            let venueList = Self.list(from: page)
            let venues = Self.parseVenues(venueList).map {
                SearchVenueItem(
                    id: $0.uniqueId,
                    name: $0.name,
                    imageURL: Self.mediaURL($0.logo?.key ?? $0.venueAttachment?.first?.key),
                    venue: $0
                )
            }

            completion(
                true,
                nil,
                venues,
                Self.hasMore(
                    from: page,
                    loadedCount: venues.count,
                    requestedTake: take
                )
            )

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {
                completion(false, err.domain, [], false)
                return
            }

            completion(false, error?.localizedDescription, [], false)
        }
    }

    func searchEvents(
        venueId: String?,
        keyword: String?,
        fromDate: Date?,
        toDate: Date?,
        skip: Int = 0,
        take: Int = 10,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errorMessage: String?,
            _ events: [SearchEventItem],
            _ hasMore: Bool
        ) -> Void
    ) {
        let timeWindow = Self.eventTimeWindow(
            fromDate: fromDate,
            toDate: toDate
        )

        DiscoverService().fetchDiscoverEvents(
            city: UserDefault.shared.activeCity,
            venueId: venueId,
            skip: skip,
            take: take,
            timeWindow: timeWindow,
            eventListType: .eventsInCity,
            search: keyword,
            timeZone: TimeZone.current.identifier
        ) { isSuccess, errorMessage, page in
            guard isSuccess,
                  let page else {
                completion(false, errorMessage, [], false)
                return
            }

            completion(
                true,
                nil,
                page.list.map {
                    SearchEventItem(
                        id: $0.uniqueId ?? $0.id,
                        title: $0.title,
                        dateText: Self.displayDate(for: $0),
                        imageURL: ($0.flyer?.key ?? "").imageURL,
                        venueName: $0.venue?.name,
                        event: $0
                    )
                },
                page.hasMore
            )
        }
    }
}

private extension SearchFlowService {

    static func eventTimeWindow(
        fromDate: Date?,
        toDate: Date?
    ) -> DiscoverEventTimeWindow? {

        guard fromDate != nil || toDate != nil else { return nil }

        let calendar = Calendar.current
        let startDate = fromDate ?? toDate ?? Date()
        let endDate = toDate ?? fromDate ?? startDate

        let start = calendar.startOfDay(for: startDate)
        let endOfDay =
        calendar.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: endDate
        ) ?? endDate

        return DiscoverEventTimeWindow(
            startDateTime: apiDateString(from: start),
            endDateTime: apiDateString(from: endOfDay)
        )
    }

    static func apiDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = DateFormat.yyyyMMddHHmmss.rawValue
        return formatter.string(from: date)
    }
}

private extension SearchFlowService {

    static func page(
        from response: [String: Any],
        keys: [String]
    ) -> Any? {

        if let value = firstValue(in: response, keys: keys) {
            return value
        }

        for nestedKey in ["data", "result", "response"] {
            if let nested = response[nestedKey] as? [String: Any],
               let value = firstValue(in: nested, keys: keys) {
                return value
            }
        }

        return nil
    }

    static func firstValue(
        in dictionary: [String: Any],
        keys: [String]
    ) -> Any? {

        for key in keys {
            if let value = dictionary[key], !(value is NSNull) {
                return value
            }
        }

        return nil
    }

    static func list(from page: Any?) -> [[String: Any]] {

        if let list = page as? [[String: Any]] {
            return list
        }

        guard let dictionary = page as? [String: Any] else {
            return []
        }

        for key in ["list", "data", "items", "rows", "results"] {
            if let list = dictionary[key] as? [[String: Any]] {
                return list
            }
        }

        return []
    }

    static func hasMore(
        from page: Any?,
        loadedCount: Int,
        requestedTake: Int
    ) -> Bool {

        guard requestedTake > 0 else { return false }

        if let dictionary = page as? [String: Any] {
            for key in ["hasMany", "hasMore", "hasNextPage"] {
                if let value = dictionary[key] as? Bool {
                    return value
                }
            }

            let total =
            intValue(dictionary["total"])
            ?? intValue(dictionary["totalCount"])
            ?? intValue(dictionary["count"])

            if let total {
                return loadedCount < total
            }
        }

        return loadedCount >= requestedTake
    }

    static func parseEvents(_ list: [[String: Any]]) -> [Event] {

        decode([Event].self, from: list)
        ?? decode(
            [Event].self,
            from: list.map { normalizedEvent($0) }
        )
        ?? []
    }

    static func parseVenues(_ list: [[String: Any]]) -> [ClipVenue] {

        decode([ClipVenue].self, from: list)
        ?? decode(
            [ClipVenue].self,
            from: list.map { normalizedVenue($0) }
        )
        ?? []
    }

    static func parseArtists(_ list: [[String: Any]]) -> [Artists] {

        decode([Artists].self, from: list)
        ?? decode([ArtistData].self, from: list)?.map(\.artist)
        ?? decode(
            [Artists].self,
            from: list.map {
                normalizedArtist(($0["artist"] as? [String: Any]) ?? $0)
            }
        )
        ?? []
    }

    static func makeArtistItems(
        from artists: [Artists],
        events: [Event]
    ) -> [SearchArtistItem] {

        var seenIds = Set<String>()
        var items: [SearchArtistItem] = []

        func append(_ artist: Artists) {
            guard artist.status == "ENABLED" else { return }
            let id = artist.id ?? artist.name
            guard !seenIds.contains(id) else { return }

            seenIds.insert(id)
            items.append(
                SearchArtistItem(
                    id: id,
                    name: artist.name,
                    imageURL: mediaURL(artist.artistImage?.key),
                    artist: artist
                )
            )
        }

        artists.forEach(append)
        events
            .flatMap { $0.eventHasArtist ?? [] }
            .map(\.artist)
            .forEach(append)

        return items
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
        let id = stringValue(event["id"])

        event["id"] = id
        event["title"] = stringValue(event["title"])
        event["startDateTime"] = stringValue(event["startDateTime"])
        event["description"] = stringValue(event["description"])
        event["isEnableOnlineTables"] = event["isEnableOnlineTables"] ?? false
        event["isEnable3DMap"] = event["isEnable3DMap"] ?? false
        event["isEnableReservationRequest"] = event["isEnableReservationRequest"] ?? false

        if let venue = event["venue"] as? [String: Any] {
            event["venue"] = normalizedVenue(venue)
        }

        if let flyer = event["flyer"] as? [String: Any] {
            event["flyer"] = normalizedMedia(flyer)
        }

        return event
    }

    static func normalizedVenue(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var venue = dictionary
        let id = stringValue(venue["id"])
        let name = stringValue(venue["name"])
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
        venue["createdAt"] = venue["createdAt"] ?? now
        venue["updatedAt"] = venue["updatedAt"] ?? now
        venue["lat"] = venue["lat"] ?? "0"
        venue["lng"] = venue["lng"] ?? "0"

        if let logo = venue["logo"] as? [String: Any] {
            venue["logo"] = normalizedMedia(logo)
        }

        if let attachments = venue["venueAttachment"] as? [[String: Any]] {
            venue["venueAttachment"] =
            attachments.map { normalizedMedia($0) }
        }

        return venue
    }

    static func normalizedMedia(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var media = dictionary
        let key = stringValue(media["key"])

        media["key"] = key
        media["name"] = media["name"] ?? key
        media["description"] = media["description"] ?? ""

        return media
    }

    static func normalizedArtist(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var artist = dictionary
        artist["id"] = stringValue(artist["id"])
        artist["name"] = stringValue(artist["name"])
        artist["instagramUsername"] = stringValue(artist["instagramUsername"])
        artist["status"] = stringValue(artist["status"], fallback: "ENABLED")

        if let image = artist["artistImage"] as? [String: Any] {
            artist["artistImage"] = normalizedMedia(image)
        } else if artist["artistImage"] is NSNull {
            artist["artistImage"] = nil
        }

        return artist
    }

    static func mediaURL(_ key: String?) -> String? {

        guard let key = key?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty else { return nil }

        if key.lowercased().hasPrefix("http") {
            return key
        }

        return key.imageURL
    }

    static func stringValue(
        _ value: Any?,
        fallback: String = ""
    ) -> String {

        if let value = value as? String {
            return value
        }

        if let value = value as? NSNumber {
            return value.stringValue
        }

        return fallback
    }

    static func intValue(_ value: Any?) -> Int? {

        if let value = value as? Int {
            return value
        }

        if let value = value as? NSNumber {
            return value.intValue
        }

        if let value = value as? String {
            return Int(value)
        }

        return nil
    }

    static func displayDate(for event: Event) -> String? {

        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customText
        }

        return event.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .MMMDDATHMMA,
            useDayLightSavingTime: true,
            customTimeZone: event.venue?.useTimezone ?? ""
        )
    }
}
