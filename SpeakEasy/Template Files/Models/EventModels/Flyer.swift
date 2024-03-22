//
//  Flyer.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

struct Flyer: Codable {

    var key: String?
    var name: String?
    var description: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(key, forKey: .key)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
    }
}
