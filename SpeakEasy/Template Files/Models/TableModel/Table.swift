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
}

struct tableTimeSlot: Codable {
    let startTime: String?
    let endTime: String?
    let minimum: Double?
    let deposit: Double?
    let depositType: String?
}
