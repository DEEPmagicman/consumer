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
    let seatingAreas: [SeatingArea]
    let minimumSpend: Double?
    let isEnquiryOnly: Bool

    var isInquiryAction: Bool {
        isEnquiryOnly ||
        priceText.caseInsensitiveCompare("Request") == .orderedSame
    }

    var primaryActionTitle: String {
        guard !isInquiryAction else {
            return "Inquire"
        }

        let priceText = minimumSpend
            .map(Self.formattedPrice) ??
            self.priceText

        return "From \(priceText)"
    }

    // MARK: - Designated Initializer

    init(
        id: String,
        title: String,
        venueName: String,
        dateText: String,
        guestText: String,
        priceText: String,
        imageUrl: String,
        event: Event?,
        seatingAreas: [SeatingArea] = [],
        minimumSpend: Double? = nil,
        isEnquiryOnly: Bool = false
    ) {
        self.id = id
        self.title = title
        self.venueName = venueName
        self.dateText = dateText
        self.guestText = guestText
        self.priceText = priceText
        self.imageUrl = imageUrl
        self.event = event
        self.seatingAreas = seatingAreas
        self.minimumSpend = minimumSpend
        self.isEnquiryOnly = isEnquiryOnly
    }
}

extension PremiumExperienceItem {

    init(
        event: Event,
        seatingAreas: [SeatingArea] = [],
        minimumSpend: Double? = nil,
        isEnquiryOnly: Bool = false
    ) {
        self.init(
            id: event.id,
            title: event.title,
            venueName: Self.resolvedVenueName(event: event),
            dateText: Self.resolvedDateText(event: event),
            guestText: Self.resolvedGuestText(
                event: event,
                seatingAreas: seatingAreas
            ),
            priceText: Self.resolvedPriceText(
                event: event,
                seatingAreas: seatingAreas
            ),
            imageUrl: Self.resolvedImageUrl(key: event.flyer?.key),
            event: event,
            seatingAreas: seatingAreas,
            minimumSpend: minimumSpend,
            isEnquiryOnly: isEnquiryOnly
        )
    }

    init?(dictionary: [String: Any]) {
        let eventDictionary = Self.resolvedEventDictionary(from: dictionary)
        let eventSeatingAreas = Self.resolvedSeatingAreas(
            dictionary: eventDictionary
        )
        let seatingAreas = eventSeatingAreas.isEmpty
            ? Self.resolvedSeatingAreas(dictionary: dictionary)
            : eventSeatingAreas
        let minimumSpend = Self.resolvedMinimumSpend(from: dictionary)
        let isEnquiryOnly = Self.resolvedIsEnquiryOnly(from: dictionary)

        if let event = Self.decodeEvent(from: eventDictionary) {
            self.init(
                event: event,
                seatingAreas: seatingAreas,
                minimumSpend: minimumSpend,
                isEnquiryOnly: isEnquiryOnly
            )
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
            guestText: Self.resolvedGuestText(
                dictionary: dictionary,
                seatingAreas: seatingAreas
            ),
            priceText: minimumSpend.map(Self.formattedPrice) ?? Self.resolvedPriceText(
                dictionary: dictionary,
                seatingAreas: seatingAreas
            ),
            imageUrl: Self.resolvedImageUrl(dictionary: dictionary),
            event: nil,
            seatingAreas: seatingAreas,
            minimumSpend: minimumSpend,
            isEnquiryOnly: isEnquiryOnly
        )
    }
}

private extension PremiumExperienceItem {

    static func decodeEvent(from dictionary: [String: Any]) -> Event? {
        guard dictionary["startDateTime"] != nil else { return nil }

        do {
            let data = try JSONSerialization.data(
                withJSONObject: eventPayloadForDecoding(dictionary)
            )
            return try JSONDecoder().decode(Event.self, from: data)
        } catch {
            return nil
        }
    }

    static func resolvedEventDictionary(
        from dictionary: [String: Any]
    ) -> [String: Any] {

        if let nested = dictionary["event"] as? [String: Any] {
            return nested
        }

        return dictionary
    }

    static func resolvedSeatingAreas(
        dictionary: [String: Any]
    ) -> [SeatingArea] {

        let raw =
        dictionary["seatingArea"] ??
        dictionary["seatingAreas"]

        guard let rawList = raw as? [[String: Any]] else {
            return []
        }

        return [SeatingArea].parse(
            rawList.map(sanitizedSeatingAreaPayload)
        ) ?? []
    }

    static func resolvedMinimumSpend(
        from dictionary: [String: Any]
    ) -> Double? {

        let eventDictionary = resolvedEventDictionary(from: dictionary)

        return firstPositiveDouble(
            in: [dictionary, eventDictionary],
            keys: ["minimumSpend", "minimum_spend", "minSpend"]
        ) ??
        firstPositiveDouble(
            in: [dictionary, eventDictionary],
            keys: ["minimum"]
        ) ??
        firstPositiveDouble(
            in: [dictionary, eventDictionary],
            keys: ["minimumDeposit"]
        )
    }

    static func resolvedIsEnquiryOnly(
        from dictionary: [String: Any]
    ) -> Bool {

        let eventDictionary = resolvedEventDictionary(from: dictionary)

        return boolValue(dictionary["isEnqiryOnly"]) ??
        boolValue(dictionary["isEnquiryOnly"]) ??
        boolValue(eventDictionary["isEnqiryOnly"]) ??
        boolValue(eventDictionary["isEnquiryOnly"]) ??
        false
    }

    static func eventPayloadForDecoding(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var payload = dictionary

        payload["description"] = stringValue(payload["description"]) ?? ""
        payload["isEnableOnlineTables"] =
        boolValue(payload["isEnableOnlineTables"]) ?? false
        payload["isEnable3DMap"] =
        boolValue(payload["isEnable3DMap"]) ?? false
        payload["isEnableReservationRequest"] =
        boolValue(payload["isEnableReservationRequest"]) ?? false

        if let venue = payload["venue"] as? [String: Any] {
            payload["venue"] = sanitizedVenuePayload(venue)
        }

        if let customVenue = payload["customVenue"] as? [String: Any] {
            payload["customVenue"] = sanitizedCustomVenuePayload(customVenue)
        }

        if let flyer = payload["flyer"] as? [String: Any] {
            payload["flyer"] = sanitizedFlyerPayload(flyer)
        }

        if let seatingAreas = payload["seatingArea"] as? [[String: Any]] {
            payload["seatingArea"] =
            seatingAreas.map(sanitizedSeatingAreaPayload)
        } else if let seatingAreas = payload["seatingAreas"] as? [[String: Any]] {
            payload["seatingAreas"] =
            seatingAreas.map(sanitizedSeatingAreaPayload)
        }

        return payload
    }

    static func sanitizedVenuePayload(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var venue = dictionary
        venue["id"] = stringValue(venue["id"]) ?? ""
        venue["uniqueId"] =
        stringValue(venue["uniqueId"]) ?? stringValue(venue["id"]) ?? ""
        venue["name"] = stringValue(venue["name"]) ?? ""
        venue["address"] = stringValue(venue["address"]) ?? ""
        venue["city"] = stringValue(venue["city"]) ?? ""
        venue["pinCode"] = stringValue(venue["pinCode"])
        venue["code"] = stringValue(venue["code"])
        venue["status"] = stringValue(venue["status"]) ?? "ENABLED"
        venue["createdAt"] = stringValue(venue["createdAt"]) ?? ""
        venue["updatedAt"] = stringValue(venue["updatedAt"]) ?? ""
        venue["lat"] = stringValue(venue["lat"]) ?? "0"
        venue["lng"] = stringValue(venue["lng"]) ?? "0"
        venue["isDeleted"] = boolValue(venue["isDeleted"]) ?? false

        return venue
    }

    static func sanitizedCustomVenuePayload(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var venue = dictionary
        venue["pinCode"] = stringValue(venue["pinCode"])
        venue["lat"] = stringValue(venue["lat"])
        venue["lng"] = stringValue(venue["lng"])

        return venue
    }

    static func sanitizedFlyerPayload(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var flyer = dictionary
        flyer["aspectRatio"] = stringValue(flyer["aspectRatio"])

        return flyer
    }

    static func sanitizedSeatingAreaPayload(
        _ dictionary: [String: Any]
    ) -> [String: Any] {

        var area = dictionary

        [
            "inquiryEnabled",
            "hideCheckout",
            "hidePricing",
            "isDeleted"
        ].forEach { key in
            if let value = boolValue(area[key]) {
                area[key] = value
            }
        }

        return area
    }

    static func resolvedVenueName(event: Event) -> String {
        event.displayVenueNameOrFallback("Premium Experience")
    }

    static func resolvedVenueName(dictionary: [String: Any]) -> String {
        if let customVenue = dictionary["customVenue"] as? [String: Any],
           let name = firstString(in: customVenue, keys: ["name"]) {
            return name
        }

        if let venueName = firstString(
            in: dictionary,
            keys: ["venueName", "venueTitle", "locationName"]
        ) {
            return venueName
        }

        if let venue = dictionary["venue"] as? [String: Any],
           let name = firstString(in: venue, keys: ["name"]) {
            return name
        }

        return "Premium Experience"
    }

    static func resolvedDateText(event: Event) -> String {
        event.eventCardDateText()
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

        let formatted = Event.eventCardDateText(
            customText: nil,
            startDate: startDate,
            timezone: timezone
        )

        return formatted
    }

    static func resolvedGuestText(
        event: Event,
        seatingAreas: [SeatingArea]
    ) -> String {
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

        return resolvedGuestText(
            from: ranges.isEmpty
            ? guestRanges(from: seatingAreas)
            : ranges
        )
    }

    static func resolvedGuestText(
        dictionary: [String: Any],
        seatingAreas: [SeatingArea]
    ) -> String {
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

        return resolvedGuestText(
            from: ranges.isEmpty
            ? guestRanges(from: seatingAreas)
            : ranges
        )
    }

    static func guestRanges(
        from seatingAreas: [SeatingArea]
    ) -> [(Int, Int)] {

        seatingAreas.compactMap { area in
            guard let maxGuests = area.maxGuest, maxGuests > 0 else {
                return nil
            }

            let minGuests = area.defaultGuest ?? 1
            return (Swift.max(minGuests, 1), maxGuests)
        }
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

    static func resolvedPriceText(
        event: Event,
        seatingAreas: [SeatingArea]
    ) -> String {
        if !seatingAreas.isEmpty {
            return resolvedPriceText(from: seatingAreas)
        }

        guard let price = event.lowestPriceTicket?.price, price > 0 else {
            return "Request"
        }

        return formattedPrice(price)
    }

    static func resolvedPriceText(
        dictionary: [String: Any],
        seatingAreas: [SeatingArea]
    ) -> String {
        if !seatingAreas.isEmpty {
            return resolvedPriceText(from: seatingAreas)
        }

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
            return resolvedPriceText(from: seatingAreas)
        }

        return formattedPrice(minPrice)
    }

    static func resolvedPriceText(
        from seatingAreas: [SeatingArea]
    ) -> String {

        let visibleAreas = seatingAreas
            .filter { $0.hidePricing != true }

        let minimumSpends = visibleAreas
            .compactMap(\.minimum)
            .filter { $0 > 0 }

        if let minimumSpend = minimumSpends.min() {
            return formattedPrice(minimumSpend)
        }

        let deposits = visibleAreas
            .flatMap { area in
                [
                    area.depositWithFees,
                    area.deposit
                ]
            }
            .compactMap { $0 }
            .filter { $0 > 0 }

        if let deposit = deposits.min() {
            return formattedPrice(deposit)
        }

        return "Request"
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

    static func boolValue(_ value: Any?) -> Bool? {
        if let value = value as? Bool {
            return value
        }

        if let value = value as? NSNumber {
            return value.boolValue
        }

        guard let text = stringValue(value)?
            .lowercased() else {
            return nil
        }

        switch text {
        case "true", "1", "yes":
            return true
        case "false", "0", "no":
            return false
        default:
            return nil
        }
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

    static func firstPositiveDouble(
        in dictionaries: [[String: Any]],
        keys: [String]
    ) -> Double? {
        for dictionary in dictionaries {
            for key in keys {
                guard let value = doubleValue(dictionary[key]),
                      value > 0 else {
                    continue
                }

                return value
            }
        }

        return nil
    }
}
