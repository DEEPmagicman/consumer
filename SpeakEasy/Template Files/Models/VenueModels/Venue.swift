//
//  Venue.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

struct Venue: Codable {

    var logo: ImageDetail?
    var venueAttachment: [ImageDetail]
    var venueHours: [VenueHours]
    var id: String
    var uniqueId: String
    var name: String
    var address: String
    var city: String
    var pinCode: String
    var code: String
    var phone: String
    var website: String
    var description: String
    var status: String
    var venueVibes: [String]
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String

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
        try container.encode(venueVibes, forKey: .venueVibes)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

struct VenueHours: Codable {

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
