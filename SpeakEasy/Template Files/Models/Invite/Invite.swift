//
//  Invite.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/06/23.
//

import Foundation

struct Invite: Codable {

    var id: String
    var uniqueId: String
    var date: String
    var name: String
    var maxTickets: Int
    var unlimitedTickets: Bool
    var clicks: Int
    var description: String
    var venueId: String
    var ticketId: String
    var status: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    var venue: ClipVenue

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uniqueId, forKey: .uniqueId)
        try container.encode(date, forKey: .date)
        try container.encode(name, forKey: .name)
        try container.encode(maxTickets, forKey: .maxTickets)
        try container.encode(unlimitedTickets, forKey: .unlimitedTickets)
        try container.encode(clicks, forKey: .clicks)
        try container.encode(description, forKey: .description)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(ticketId, forKey: .ticketId)
        try container.encode(status, forKey: .status)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(venue, forKey: .venue)
    }
}
