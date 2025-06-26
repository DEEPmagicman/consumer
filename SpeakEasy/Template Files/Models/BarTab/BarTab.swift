//
//  BarTab.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/06/25.
//

import Foundation

struct BarTabData: Codable {
    
    var barTab: BarTab
    var clientSecret: String
    var ephemeralKey: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(barTab, forKey: .barTab)
        try container.encode(clientSecret, forKey: .clientSecret)
        try container.encode(ephemeralKey, forKey: .ephemeralKey)
    }
}

struct BarTab: Codable {
    
    var id: String
    var venueId: String
    var consumerUserId: String
//    var consumerUser: User?
    var barTabHasItem: BarTabHasItem?
    var barTabPayments: [BarTabPayments]?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(venueId, forKey: .venueId)
        try container.encodeIfPresent(consumerUserId, forKey: .consumerUserId)
//        try container.encodeIfPresent(consumerUser, forKey: .consumerUser)
        try container.encodeIfPresent(barTabHasItem, forKey: .barTabHasItem)
        try container.encodeIfPresent(barTabPayments, forKey: .barTabPayments)
    }
}

struct BarTabHasItem: Codable {
    
    var id: String?
    var coverTicketId: String?
    var ticketPrice: Int?
    var barTabId: String?
    var isDeleted: Bool?
    var createdAt: String?
    var updatedAt: String?
    var coverTicket: CoverTicket?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(coverTicketId, forKey: .coverTicketId)
        try container.encodeIfPresent(ticketPrice, forKey: .ticketPrice)
        try container.encodeIfPresent(barTabId, forKey: .barTabId)
        try container.encodeIfPresent(isDeleted, forKey: .isDeleted)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(coverTicket, forKey: .coverTicket)
    }
}

struct BarTabPayments: Codable {
    
    var id: String?
    var barTabId: String?
    var bookingFeesId: String?
    var orderNo: Int?
    var paymentIntent: String?
    var paymentStatus: String?
    var bookingFees: PaymentDetail?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(barTabId, forKey: .barTabId)
        try container.encodeIfPresent(bookingFeesId, forKey: .bookingFeesId)
        try container.encodeIfPresent(orderNo, forKey: .orderNo)
        try container.encodeIfPresent(paymentIntent, forKey: .paymentIntent)
        try container.encodeIfPresent(paymentStatus, forKey: .paymentStatus)
        try container.encodeIfPresent(bookingFees, forKey: .bookingFees)
    }
}
