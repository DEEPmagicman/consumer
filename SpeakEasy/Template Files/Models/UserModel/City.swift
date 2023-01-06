//
//  City.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 06/01/23.
//

import Foundation

struct City {

    internal init(id: String, name: String, stateCode: String, countryCode: String,latitude: String, longitude: String, isDeleted: Bool) {
        self.id = id
        self.name = name
        self.stateCode = stateCode
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
        self.isDeleted = isDeleted
    }
    
    var id: String
    var name: String
    var stateCode: String
    var countryCode: String
    var latitude: String
    var longitude: String
    var isDeleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case stateCode = "state_code"
        case countryCode = "country_code"
        case latitude = "latitude"
        case longitude = "longitude"
        case isDeleted = "is_deleted"
    }
    
    init(fromDictionary dictionary: [String:Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.stateCode = dictionary["stateCode"] as? String ?? ""
        self.countryCode = dictionary["countryCode"] as? String ?? ""
        self.latitude = dictionary["latitude"] as? String ?? ""
        self.longitude = dictionary["longitude"] as? String ?? ""
        self.isDeleted = dictionary["isDeleted"] as? Bool ?? false
    }
}

extension City: Codable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        stateCode = try values.decode(String.self, forKey: .stateCode)
        countryCode = try values.decode(String.self, forKey: .countryCode)
        latitude = try values.decode(String.self, forKey: .latitude)
        longitude = try values.decode(String.self, forKey: .longitude)
        isDeleted = try values.decode(Bool.self, forKey: .isDeleted)
    }
    
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(name, forKey: .name)
        try values.encode(stateCode, forKey: .stateCode)
        try values.encode(countryCode, forKey: .countryCode)
        try values.encode(latitude, forKey: .latitude)
        try values.encode(longitude, forKey: .longitude)
        try values.encode(isDeleted, forKey: .isDeleted)
    }
}
