//
//  BottleCategory.swift
//  SpeakEasy
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

struct BottleCategory: Codable {

    var id: String
    var venueId: String
    var name: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    var bottleMenu: [BottleList]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case venueId
        case name
        case isDeleted
        case createdAt
        case updatedAt
        case bottleMenu = "venueBottleMenu"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(name, forKey: .name)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(bottleMenu, forKey: .bottleMenu)
    }
}
