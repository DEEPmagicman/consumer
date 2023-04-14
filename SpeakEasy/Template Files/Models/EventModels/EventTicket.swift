//
//  EventTicket.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 01/02/23.
//

import Foundation

struct EventTicket: Codable {

    var id: String
    var eventId: String?
    var tierName: String
    var price: Int
    var issuedUnits: Int
    var beginSale: String
    var endSale: String
    var soldUnits: Int?
    var status: String
    var tierDescription: String
    var isDeleted: Bool
    var sellingPaused: Bool
    var createdAt: String
    var updatedAt: String
    var eventTicketHasTier: [EventTicketHasTier]?
    var selectedTicketCount: Int?
    var remainingQuantity: Int? {
        issuedUnits - (soldUnits ?? 0)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(tierName, forKey: .tierName)
        try container.encode(price, forKey: .price)
        try container.encode(issuedUnits, forKey: .issuedUnits)
        try container.encode(beginSale, forKey: .beginSale)
        try container.encode(endSale, forKey: .endSale)
        try container.encode(soldUnits, forKey: .soldUnits)
        try container.encode(status, forKey: .status)
        try container.encode(tierDescription, forKey: .tierDescription)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(sellingPaused, forKey: .sellingPaused)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(eventTicketHasTier, forKey: .eventTicketHasTier)
    }
}

struct EventTicketHasTier: Codable {

    var id: String
    var eventId: String
    var price: Int
    var issuedUnits: Int
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(price, forKey: .price)
        try container.encode(issuedUnits, forKey: .issuedUnits)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
