//
//  Drink.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 29/12/22.
//

import Foundation

struct Drink {
    
    internal init(id: String, drinkName: String, status: String, isDeleted: Bool,isSelected: Bool) {
        self.id = id
        self.drinkName = drinkName
        self.status = status
        self.isDeleted = isDeleted
        self.isSelected = isSelected
    }
    
    var id: String
    var drinkName: String
    var status: String
    var isDeleted: Bool
    var isSelected: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case drinkName = "drink_name"
        case status = "status"
        case isDeleted = "is_deleted"
        case isSelected = "is_selected"
    }
    
    init(fromDictionary dictionary: [String:Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.drinkName = dictionary["drinkName"] as? String ?? ""
        self.status = dictionary["status"] as? String ?? ""
        self.isDeleted = dictionary["isDeleted"] as? Bool ?? false
        self.isSelected = dictionary["isSelected"] as? Bool ?? false
    }
}

extension Drink: Codable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        drinkName = try values.decode(String.self, forKey: .drinkName)
        status = try values.decode(String.self, forKey: .status)
        isDeleted = try values.decode(Bool.self, forKey: .isDeleted)
        isSelected = try values.decode(Bool.self, forKey: .isSelected)
    }
    
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(drinkName, forKey: .drinkName)
        try values.encode(status, forKey: .status)
        try values.encode(isDeleted, forKey: .isDeleted)
        try values.encode(isSelected, forKey: .isSelected)
    }
}
