//
//  VenueHours.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

struct VenueHours: Codable {

    var day: String
    var venueStatus: String
    var from: String
    var to: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(day, forKey: .day)
        try container.encode(venueStatus, forKey: .venueStatus)
        try container.encode(from, forKey: .from)
        try container.encode(to, forKey: .to)
    }
}
