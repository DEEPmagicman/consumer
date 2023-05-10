//
//  ClipVenue.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 03/02/23.
//

import Foundation

struct ClipVenue: Codable {

    var logo: LogoClip?
    var venueAttachment: [VenueAttachmentClip]
    var venueHours: [VenueHoursClip]
    var id: String
    var uniqueId: String
    var name: String
    var address: String
    var city: String
    var pinCode: String
    var code: String
    var phone: String
    var website: String
    var description: String?
    var status: String
    var bookingStatus: String
    var venueVibes: [String]
    var isDeleted: Bool
    var isEnabledGenderBasedTicket: Bool?
    var createdAt: String
    var updatedAt: String
    var bookingWaiting: String?
    var lat: String
    var lng: String
    var appClipTicket: [AppClipTicket]?
    var checkInUser: Int?
    // MARK: app side parameters
    var latitude: Double {
        Double(lat) ?? 0.0
    }
    var longitude: Double {
        Double(lng) ?? 0.0
    }
    var displayWaitTime: String {
        if let waitTime = bookingWaiting {
            if waitTime.contains("mins") || waitTime.contains("Hour") {
                return "\(waitTime.replacingOccurrences(of: "mins", with: "Minute")) Wait"
            } else {
                return waitTime
            }
        } else {
            return ""
        }
    }
    var openHours: [VenueHoursClip] {
        venueHours.filter({ $0.venueStatus == "OPEN" })
    }
    var lowestPriceTicket: AppClipTicket? {
        let filterTickets = appClipTicket?.filter({ $0.status == "ENABLED" })
        let lowest = filterTickets?.min(by: { LHS, RHS in
            LHS.price < RHS.price
        })
        return lowest
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(logo, forKey: .logo)
        try container.encode(venueAttachment, forKey: .venueAttachment)
        try container.encode(venueHours, forKey: .venueHours)
        try container.encode(id, forKey: .id)
        try container.encode(uniqueId, forKey: .uniqueId)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(city, forKey: .city)
        try container.encode(pinCode, forKey: .pinCode)
        try container.encode(code, forKey: .code)
        try container.encode(phone, forKey: .phone)
        try container.encode(website, forKey: .website)
        try container.encode(description, forKey: .description)
        try container.encode(status, forKey: .status)
        try container.encode(bookingStatus, forKey: .bookingStatus)
        try container.encode(venueVibes, forKey: .venueVibes)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(isEnabledGenderBasedTicket, forKey: .isEnabledGenderBasedTicket)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(bookingWaiting, forKey: .bookingWaiting)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
        try container.encode(checkInUser, forKey: .checkInUser)
    }
}

struct LogoClip: Codable {

    var key: String
    var name: String
    var description: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
    }
}

struct VenueAttachmentClip: Codable {

    var key: String
    var name: String
    var description: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
    }
}

struct VenueHoursClip: Codable {

    var day: String
    var venueStatus: String
    var from: String
    var to: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(day, forKey: .day)
        try container.encode(venueStatus, forKey: .venueStatus)
        try container.encode(from, forKey: .from)
        try container.encode(to, forKey: .to)
    }
}

struct AppClipTicket: Codable {

    var id: String
    var venueId: String?
    var name: String
    var price: Int
    var parentId: String?
    var status: String?
    var description: String?
    var isDeleted: Bool?
    var createdAt: String?
    var updatedAt: String?
    // MARK: app side parameters
    var selectedQuantity: Int?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(parentId, forKey: .parentId)
        try container.encode(status, forKey: .status)
        try container.encode(description, forKey: .description)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
