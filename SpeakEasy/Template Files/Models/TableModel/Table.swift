//
//  Table.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 17/02/26.
//

import Foundation

enum BookingType: String, Codable {
    case `default` = "DEFAULT"
    case timeWise = "TIME_WISE"
}

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
    let bookingType: BookingType?
    let inquiryEnabled: Bool?
    let depositWithFees: Double?
    
    let timeSlots: [tableTimeSlot]?
    
    
    enum CodingKeys: String, CodingKey {
        case id, name, highlight, minimum, deposit, maxGuest, defaultGuest, description,
             hideCheckout, hidePricing, bookingType, depositWithFees, timeSlots, inquiryEnabled
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


import Foundation

struct ConsumerLayoutResponse: Codable {
    let id: String?
    let venueId: String?
    let isDefault: Bool?
    let isDeleted: Bool?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
    let layoutHistories: [LayoutHistory]?
}

// MARK: - LayoutTableHistory
struct LayoutHistory: Codable {
    let id: String?
    let layoutId: String?
    let name: String?
    let url3dMap: String?
    let totalTables: Int?
    let createdAt: String?
    let layoutHistoryHas3DMaps: [Layout3DMap]?

    enum CodingKeys: String, CodingKey {
        case id
        case layoutId
        case name
        case url3dMap = "url3dMap"
        case totalTables
        case createdAt
        case layoutHistoryHas3DMaps
    }
}

struct Layout3DMap: Codable {
    let id: String?
    let layoutHistoryId: String?
    let name: String?
    let url3dMap: String?
    let metadata: String?

    let xPosition: Double?
    let yPosition: Double?
    let zPosition: Double?

    let fieldOfView: Double?
    let verticalRotationMin: Double?
    let verticalRotationMax: Double?
    let horizontalRotationMin: Double?
    let horizontalRotationMax: Double?

    let zoomMin: Double?
    let zoomMax: Double?
    let ratio: Double?

    let order: Int?
    let isDeleted: Bool?
    let status: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case layoutHistoryId
        case name
        case url3dMap = "url3dMap"
        case metadata
        case xPosition, yPosition, zPosition
        case fieldOfView
        case verticalRotationMin, verticalRotationMax
        case horizontalRotationMin, horizontalRotationMax
        case zoomMin, zoomMax
        case ratio
        case order
        case isDeleted
        case status
        case createdAt
    }
}
