//
//  Event.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

struct Event: Codable {

    var flyer: Flyer?
    var id: String
    var eventId: String?
    var venueId: String
    var title: String
    var date: String
    var eventType: String
    var time: String
    var artistId: String
    var isRecurring: Bool
    var version: String
    var eventStatus: String
    var status: String
    var rejectReason: String
    var recurringType: String
    var recurringTo: String
    var recurringFrom: String
    var description: String
    var disclaimer: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    var floorPlanId: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(flyer, forKey: .flyer)
        try container.encode(id, forKey: .id)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(time, forKey: .time)
        try container.encode(artistId, forKey: .artistId)
        try container.encode(isRecurring, forKey: .isRecurring)
        try container.encode(version, forKey: .version)
        try container.encode(eventStatus, forKey: .eventStatus)
        try container.encode(status, forKey: .status)
        try container.encode(rejectReason, forKey: .rejectReason)
        try container.encode(recurringType, forKey: .recurringType)
        try container.encode(recurringTo, forKey: .recurringTo)
        try container.encode(recurringFrom, forKey: .recurringFrom)
        try container.encode(description, forKey: .description)
        try container.encode(disclaimer, forKey: .disclaimer)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(floorPlanId, forKey: .floorPlanId)
    }
}
