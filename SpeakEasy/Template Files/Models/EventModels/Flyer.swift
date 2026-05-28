//
//  Flyer.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

struct Flyer: Codable {

    var id: String?
    var key: String?
    var name: String?
    var description: String?
    var venueId: String?
    var aspectRatio: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(key, forKey: .key)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(venueId, forKey: .venueId)
        try container.encodeIfPresent(aspectRatio, forKey: .aspectRatio)
    }
}
