//
//  FloorPlan.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 22/02/23.
//

import Foundation

struct FloorPlan: Codable {

    var floorImage: Flyer
    var id: String
    var floorPlanId: String
    var venueId: String
    var floorName: String
    var version: String
    var floorPlanStatus: String
    var status: String
    var rejectReason: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    var floorPlanShiftId: [String]?
    var floorPlanTable: [FloorPlanTable]?

    private enum CodingKeys: String, CodingKey {
        case floorImage
        case id
        case floorPlanId
        case venueId
        case floorName
        case version
        case floorPlanStatus
        case status
        case rejectReason
        case isDeleted
        case createdAt
        case updatedAt
        case floorPlanShiftId
        case floorPlanTable
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(floorImage, forKey: .floorImage)
        try container.encode(id, forKey: .id)
        try container.encode(floorPlanId, forKey: .floorPlanId)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(floorName, forKey: .floorName)
        try container.encode(version, forKey: .version)
        try container.encode(floorPlanStatus, forKey: .floorPlanStatus)
        try container.encode(status, forKey: .status)
        try container.encode(rejectReason, forKey: .rejectReason)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(floorPlanShiftId, forKey: .floorPlanShiftId)
        try container.encodeIfPresent(floorPlanTable, forKey: .floorPlanTable)
    }
}

struct FloorPlanTable: Codable {

    var id: String
    var floorPlanId: String
    var tableNo: String
    var top: Int
    var left: Int
    var color: String?
    var type: String
    var height: Int
    var width: Int
    var radius: String?
    var capacity: Int
    var booked: Bool
//    var booking: Any
    var noOfBookingRequest: Int
    var noOfReservationRequest: Int
    var status: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    var isSelected: Bool? = false

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(floorPlanId, forKey: .floorPlanId)
        try container.encode(tableNo, forKey: .tableNo)
        try container.encode(top, forKey: .top)
        try container.encode(left, forKey: .left)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encode(type, forKey: .type)
        try container.encode(height, forKey: .height)
        try container.encode(width, forKey: .width)
        try container.encodeIfPresent(radius, forKey: .radius)
        try container.encode(capacity, forKey: .capacity)
        try container.encode(booked, forKey: .booked)
        // TODO: Add code for encoding `booking`, It was null at the time of model creation.
        try container.encode(noOfBookingRequest, forKey: .noOfBookingRequest)
        try container.encode(noOfReservationRequest, forKey: .noOfReservationRequest)
        try container.encode(status, forKey: .status)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
