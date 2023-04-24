//
//  BottleMenu.swift
//  SpeakEasy
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

struct BottleList {

    var id: String
    var drinkName: String
    var venueId: String
    var venueBottleCategoryId: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case drinkName
        case venueId
        case venueBottleCategoryId
        case isDeleted
        case createdAt
        case updatedAt
    }
}
    
extension BottleList: Codable {

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        drinkName = try values.decode(String.self, forKey: .drinkName)
        venueId = try values.decode(String.self, forKey: .venueId)
        venueBottleCategoryId = try values.decode(String.self, forKey: .venueBottleCategoryId)
        isDeleted = try values.decode(Bool.self, forKey: .isDeleted)
        createdAt = try values.decode(String.self, forKey: .createdAt)
        updatedAt = try values.decode(String.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(drinkName, forKey: .drinkName)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(venueBottleCategoryId, forKey: .venueBottleCategoryId)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
