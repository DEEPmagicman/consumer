//
//  Logo.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

struct Logo: Codable {

    var key: String
    var name: String
    var description: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
    }
}
