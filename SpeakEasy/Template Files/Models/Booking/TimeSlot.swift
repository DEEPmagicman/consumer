//
//  TimeSlot.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 31/08/23.
//

import Foundation

struct TimeSlot: Codable {

    var id: String
    var bookingId: String
    var floorPlanTableTimeSlotId: String
    var createdAt: String
    var floorPlanTableTimeSlot: FloorPlanTableTimeSlot

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case bookingId = "bookingId"
        case floorPlanTableTimeSlotId = "floorPlanTableTimeSlotId"
        case createdAt = "createdAt"
        case floorPlanTableTimeSlot = "FloorPlanTableTimeSlot"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(bookingId, forKey: .bookingId)
        try container.encode(floorPlanTableTimeSlotId, forKey: .floorPlanTableTimeSlotId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(floorPlanTableTimeSlot, forKey: .floorPlanTableTimeSlot)
    }

}

struct FloorPlanTableTimeSlot: Codable {
    var id: String
    var floorPlanTableId: String
    var date: String
    var startTime: String
    var endTime: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(floorPlanTableId, forKey: .floorPlanTableId)
        try container.encode(date, forKey: .date)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
    }
}
