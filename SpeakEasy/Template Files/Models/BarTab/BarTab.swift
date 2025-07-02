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
//    var venueId: String
//    var consumerUserId: String
//    var consumerUser: User?
//    var barTabHasItem: BarTabHasItem?
    var posChecksId: String?
    var barTabPayments: [BarTabPayments]?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
//        try container.encodeIfPresent(venueId, forKey: .venueId)
//        try container.encodeIfPresent(consumerUserId, forKey: .consumerUserId)
//        try container.encodeIfPresent(consumerUser, forKey: .consumerUser)
//        try container.encodeIfPresent(barTabHasItem, forKey: .barTabHasItem)
        try container.encodeIfPresent(posChecksId, forKey: .posChecksId)
        try container.encodeIfPresent(barTabPayments, forKey: .barTabPayments)
    }
}

struct BarTabHasItem: Codable {
    
    var id: String?
    var coverTicketId: String?
    var ticketPrice: Int?
    var barTabId: String?
    var isDeleted: Bool?
//    var createdAt: String?
//    var updatedAt: String?
    var coverTicket: CoverTicket?
    // MARK: app side parameters
    var selectedQuantity: Int? = nil
    var checkedInQuantity: Int? = nil
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(coverTicketId, forKey: .coverTicketId)
        try container.encodeIfPresent(ticketPrice, forKey: .ticketPrice)
        try container.encodeIfPresent(barTabId, forKey: .barTabId)
        try container.encodeIfPresent(isDeleted, forKey: .isDeleted)
//        try container.encodeIfPresent(createdAt, forKey: .createdAt)
//        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
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

struct BarTabBooking: Codable {

    var id: String
    var venueId: String
    var consumerUserId: String
    var posChecksId: String
    var totalCredit: Int?
    var usedCredit: Int?
    var createdAt: String
    var updatedAt: String
//    var consumerUser: User?
    var barTabHasItems: [BarTabHasItem]
    var barTabPayments: [BarTabPayments]?
    var venue: ClipVenue?
    
    var uniqueTickets: [BarTabHasItem] {
        var tickets = [BarTabHasItem]()
        barTabHasItems.forEach { ticket in
            if let index = tickets.firstIndex(where: { $0.coverTicketId == ticket.coverTicketId }), let quantity = tickets[index].selectedQuantity {
                tickets[index].selectedQuantity = quantity + 1
//                if bookingHasCheckIn?.first?.bookingItemCheckIn.contains(where: { $0.bookingHasItemId == ticket.id }) == true {
//                    let alreadyCheckInCount = tickets[index].checkedInQuantity ?? 0
//                    tickets[index].checkedInQuantity = alreadyCheckInCount + 1
//                }
            } else {
                var ticket = ticket
                ticket.selectedQuantity = 1
//                if bookingHasCheckIn?.first?.bookingItemCheckIn.contains(where: { $0.bookingHasItemId == ticket.id }) == true {
//                    ticket.checkedInQuantity = 1
//                } else {
//                    ticket.checkedInQuantity = 0
//                }
                tickets.append(ticket)
            }
        }
        return tickets
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(consumerUserId, forKey: .consumerUserId)
        try container.encode(posChecksId, forKey: .posChecksId)
        try container.encodeIfPresent(totalCredit, forKey: .totalCredit)
        try container.encodeIfPresent(usedCredit, forKey: .usedCredit)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
//        try container.encodeIfPresent(consumerUser, forKey: .consumerUser)
        try container.encodeIfPresent(barTabHasItems, forKey: .barTabHasItems)
        try container.encodeIfPresent(barTabPayments, forKey: .barTabPayments)
        try container.encodeIfPresent(venue, forKey: .venue)
    }
}
