//
//  Table.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 17/02/26.
//

import Foundation

struct SeatingAreaResponse: Codable {
    let total: Int?
    let list: [SeatingArea]?
    let hasMany: Bool?
    let count: Int?
}

struct SeatingArea: Codable {
    let id: String?
    let parentSeatingAreaId: String?
    let name: String?
    let highlight: String?
    let minimum: Double?
    let deposit: Double?
    let maxGuest: Int?
    let defaultGuest: Int?
    let description: String?
    let hideCheckout: Bool?
    let hidePricing: Bool?
    let bookingType: String?
    let depositWithFees: Double?
    
    let timeSlots: [tableTimeSlot]?
    
    
    enum CodingKeys: String, CodingKey {
        case id, name, highlight, minimum, deposit, maxGuest, defaultGuest, description,
             hideCheckout, hidePricing, bookingType, depositWithFees, timeSlots
        case parentSeatingAreaId = "parentSeatingAreaId"
    }
}

struct tableTimeSlot: Codable {
    let startTime: String?
    let endTime: String?
    let minimum: Double?
    let deposit: Double?
    let depositType: String?
}




struct SeatingAreaBookingResponse: Codable {
    let id: String
    let eventId: String
    let venueId: String
    let status: String
    let items: [BookingItem]
    let createdAt: Int64
    let clientIp: String?
    let position: Int
    let approxWait: Int
    let isSuccess: Bool
    let message: String?
    let content: [String: String]?   
}

struct BookingItem: Codable {
    let seatingAreaId: String
    let guests: Int
}
