//
//  PremiumExperienceItem.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 16/06/26.
//

import Foundation

struct PremiumExperienceItem {

    let id: String
    let title: String
    let venueName: String
    let dateText: String
    let guestText: String
    let priceText: String
    let imageUrl: String
    let event: Event?

    // MARK: - Designated Initializer

    init(
        id: String,
        title: String,
        venueName: String,
        dateText: String,
        guestText: String,
        priceText: String,
        imageUrl: String,
        event: Event?
    ) {
        self.id = id
        self.title = title
        self.venueName = venueName
        self.dateText = dateText
        self.guestText = guestText
        self.priceText = priceText
        self.imageUrl = imageUrl
        self.event = event
    }
}

extension PremiumExperienceItem {

    init(event: Event) {
        self.init(
            id: event.id,
            title: event.title,
            venueName: Self.resolvedVenueName(event: event),
            dateText: Self.resolvedDateText(event: event),
            guestText: Self.resolvedGuestText(event: event),
            priceText: Self.resolvedPriceText(event: event),
            imageUrl: Self.resolvedImageUrl(key: event.flyer?.key),
            event: event
        )
    }

    init?(dictionary: [String: Any]) {

        if let event = Self.decodeEvent(from: dictionary) {
            self.init(event: event)
            return
        }

        guard let id = Self.firstString(
            in: dictionary,
            keys: ["id", "eventId", "_id", "uniqueId"]
        ) else {
            return nil
        }

        self.init(
            id: id,
            title: Self.firstString(
                in: dictionary,
                keys: ["title", "name", "eventName"]
            ) ?? "Premium Experience",
            venueName: Self.resolvedVenueName(dictionary: dictionary),
            dateText: Self.resolvedDateText(dictionary: dictionary),
            guestText: Self.resolvedGuestText(dictionary: dictionary),
            priceText: Self.resolvedPriceText(dictionary: dictionary),
            imageUrl: Self.resolvedImageUrl(dictionary: dictionary),
            event: nil
        )
    }
}

private extension PremiumExperienceItem {

    static func decodeEvent(from dictionary: [String: Any]) -> Event? {
        guard dictionary["startDateTime"] != nil else { return nil }

        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            return try JSONDecoder().decode(Event.self, from: data)
        } catch {
            return nil
        }
    }

    static func resolvedVenueName(event: Event) -> String {
        let customVenue = event.customVenue?.name?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let customVenue = customVenue, !customVenue.isEmpty {
            return customVenue
        }

        let venue = event.venue?.name
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return venue?.isEmpty == false ? venue! : "Premium Experience"
    }

    static func resolvedVenueName(dictionary: [String: Any]) -> String {
        if let venueName = firstString(
            in: dictionary,
            keys: ["venueName", "venueTitle", "locationName"]
        ) {
            return venueName
        }

        if let customVenue = dictionary["customVenue"] as? [String: Any],
           let name = firstString(in: customVenue, keys: ["name"]) {
            return name
        }

        if let venue = dictionary["venue"] as? [String: Any],
           let name = firstString(in: venue, keys: ["name"]) {
            return name
        }

        return "Premium Experience"
    }

    static func resolvedDateText(event: Event) -> String {
        if let customText = event.openTimeCustomText?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !customText.isEmpty {
            return customText
        }

        return event.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .MMMDDATHMMA,
            useDayLightSavingTime: true,
            customTimeZone: event.venue?.useTimezone ?? ""
        )
    }

    static func resolvedDateText(dictionary: [String: Any]) -> String {
        if let customText = firstString(
            in: dictionary,
            keys: ["openTimeCustomText", "dateText", "displayDate"]
        ) {
            return customText
        }

        guard let startDate = firstString(
            in: dictionary,
            keys: ["startDateTime", "startsAt", "date"]
        ) else {
            return "Date announced soon"
        }

        let timezone =
            (dictionary["venue"] as? [String: Any]).flatMap {
                firstString(in: $0, keys: ["useTimezone", "timezone"])
            } ?? firstString(in: dictionary, keys: ["timezone"]) ?? ""

        let formatted = startDate.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .MMMDDATHMMA,
            useDayLightSavingTime: true,
            customTimeZone: timezone
        )

        return formatted == "No date Found" ? startDate : formatted
    }

    static func resolvedGuestText(event: Event) -> String {
        let ranges = (event.eventTicket ?? []).compactMap { ticket -> (Int, Int)? in
            guard
                let minGuests = ticket.miniPurchaseQuantity,
                let maxGuests = ticket.maxPurchaseQuantity,
                maxGuests > 0
            else {
                return nil
            }

            return (Swift.max(minGuests, 1), maxGuests)
        }

        return resolvedGuestText(from: ranges)
    }

    static func resolvedGuestText(dictionary: [String: Any]) -> String {
        if let text = firstString(
            in: dictionary,
            keys: ["guestText", "guestRange", "capacityText"]
        ) {
            return text
        }

        let directRange: (Int, Int)? = {
            let min = intValue(
                dictionary["minGuests"] ??
                dictionary["minimumGuests"] ??
                dictionary["minGuest"]
            )

            let maxGuests = intValue(
                dictionary["maxGuests"] ??
                dictionary["maximumGuests"] ??
                dictionary["maxGuest"] ??
                dictionary["capacity"]
            )

            guard let maxGuests = maxGuests, maxGuests > 0 else { return nil }
            return (Swift.max(min ?? 1, 1), maxGuests)
        }()

        var ranges = directRange.map { [$0] } ?? []

        if let tickets = dictionary["eventTicket"] as? [[String: Any]] {
            ranges += tickets.compactMap {
                guard
                    let maxGuests = intValue(
                        $0["maxPurchaseQuantity"] ??
                        $0["maximumGuests"] ??
                        $0["capacity"]
                    ),
                    maxGuests > 0
                else {
                    return nil
                }

                let min = intValue(
                    $0["miniPurchaseQuantity"] ??
                    $0["minPurchaseQuantity"] ??
                    $0["minimumGuests"]
                ) ?? 1

                return (Swift.max(min, 1), maxGuests)
            }
        }

        return resolvedGuestText(from: ranges)
    }

    static func resolvedGuestText(from ranges: [(Int, Int)]) -> String {
        guard !ranges.isEmpty else { return "8-12 guests" }

        let minGuests = ranges.map { $0.0 }.min() ?? 1
        let maxGuests = ranges.map { $0.1 }.max() ?? minGuests

        if minGuests == maxGuests {
            return maxGuests == 1 ? "1 guest" : "\(maxGuests) guests"
        }

        return "\(minGuests)-\(maxGuests) guests"
    }

    static func resolvedPriceText(event: Event) -> String {
        guard let price = event.lowestPriceTicket?.price, price > 0 else {
            return "Request"
        }

        return formattedPrice(price)
    }

    static func resolvedPriceText(dictionary: [String: Any]) -> String {
        let price = doubleValue(
            dictionary["price"] ??
            dictionary["startingPrice"] ??
            dictionary["minPrice"] ??
            dictionary["lowestPrice"]
        )

        if let price = price, price > 0 {
            return formattedPrice(price)
        }

        let ticketPrices =
            (dictionary["eventTicket"] as? [[String: Any]])?
            .compactMap { doubleValue($0["price"]) }
            .filter { $0 > 0 } ?? []

        guard let minPrice = ticketPrices.min() else {
            return "Request"
        }

        return formattedPrice(minPrice)
    }

    static func formattedPrice(_ price: Double) -> String {
        if price.rounded() == price {
            return "$\(Int(price))"
        }

        return String(format: "$%.2f", price)
    }

    static func resolvedImageUrl(key: String?) -> String {
        guard let key = key?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty else {
            return ""
        }

        if key.hasPrefix("http://") || key.hasPrefix("https://") {
            return key
        }

        return key.imageURL
    }

    static func resolvedImageUrl(dictionary: [String: Any]) -> String {
        if let url = firstString(
            in: dictionary,
            keys: ["imageUrl", "imageURL", "image", "flyerUrl"]
        ) {
            return resolvedImageUrl(key: url)
        }

        if let flyer = dictionary["flyer"] as? [String: Any],
           let key = firstString(in: flyer, keys: ["key", "url"]) {
            return resolvedImageUrl(key: key)
        }

        if let attachments = dictionary["venueAttachment"] as? [[String: Any]],
           let key = attachments.first.flatMap({ firstString(in: $0, keys: ["key"]) }) {
            return resolvedImageUrl(key: key)
        }

        if let venue = dictionary["venue"] as? [String: Any],
           let attachments = venue["venueAttachment"] as? [[String: Any]],
           let key = attachments.first.flatMap({ firstString(in: $0, keys: ["key"]) }) {
            return resolvedImageUrl(key: key)
        }

        return ""
    }

    static func firstString(
        in dictionary: [String: Any],
        keys: [String]
    ) -> String? {
        for key in keys {
            guard let text = stringValue(dictionary[key]) else { continue }
            return text
        }

        return nil
    }

    static func stringValue(_ value: Any?) -> String? {
        if let value = value as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        if let value = value as? NSNumber {
            return value.stringValue
        }

        return nil
    }

    static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? Double { return Int(value) }
        if let value = value as? NSNumber { return value.intValue }

        guard let text = stringValue(value) else { return nil }
        return Int(text)
    }

    static func doubleValue(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? NSNumber { return value.doubleValue }

        guard let text = stringValue(value)?
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        else {
            return nil
        }

        return Double(text)
    }
}

