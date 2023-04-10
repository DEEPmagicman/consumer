//
//  Vibe.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 29/12/22.
//

import Foundation

struct Vibe {

    internal init(id: String, vibeName: String, status: String, isDeleted: Bool,isSelected: Bool) {
        self.id = id
        self.vibeName = vibeName
        self.status = status
        self.isDeleted = isDeleted
        self.isSelected = isSelected
    }
    
    var id: String
    var vibeName: String
    var status: String
    var isDeleted: Bool
    var isSelected: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case vibeName = "vibe_name"
        case status = "status"
        case isDeleted = "is_deleted"
        case isSelected = "is_selected"
    }
    
    init(fromDictionary dictionary: [String:Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.vibeName = dictionary["vibeName"] as? String ?? ""
        self.status = dictionary["status"] as? String ?? ""
        self.isDeleted = dictionary["isDeleted"] as? Bool ?? false
        self.isSelected = dictionary["isSelected"] as? Bool ?? false
    }
}

extension Vibe: Codable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        vibeName = try values.decode(String.self, forKey: .vibeName)
        status = try values.decode(String.self, forKey: .status)
        isDeleted = try values.decode(Bool.self, forKey: .isDeleted)
        isSelected = try values.decode(Bool.self, forKey: .isSelected)
    }
    
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(vibeName, forKey: .vibeName)
        try values.encode(status, forKey: .status)
        try values.encode(isDeleted, forKey: .isDeleted)
        try values.encode(isSelected, forKey: .isSelected)
    }
}
