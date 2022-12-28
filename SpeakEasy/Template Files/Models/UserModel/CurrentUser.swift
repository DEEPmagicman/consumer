//
//  CurrentUser.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/22.
//

import Foundation

struct Currentuser {
    
    var id: String
    var uniqueId: String
    var firstName: String
    var lastName: String
    var nickName: String
    var dateOfBirth: String
    var gender: String
    var email: String
    var location: String
    var city: String
    var receiveMarketing: Bool
    var code: String
    var phone: String
    var phoneVerified: Bool
    var status: String
    var image: String
    var instagramId: String
    var spotifyId: String
    var isDeleted: Bool
    var lastLogin: String
    var createdAt: String
    var updatedAt: String
    var vibeIds: [String]
    var drinkIds: [String]
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case uniqueId = "unique_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case nickName = "nick_name"
        case dateOfBirth = "dob"
        case gender = "gender"
        case email = "email"
        case location = "location"
        case city = "city"
        case receiveMarketing = "receive_marketing"
        case code = "code"
        case phone = "phone"
        case phoneVerified = "phone_verified"
        case status = "status"
        case image = "image"
        case instagramId = "instagram_id"
        case spotifyId = "spotify_id"
        case isDeleted = "is_deleted"
        case lastLogin = "last_login"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case vibeIds = "vibe_ids"
        case drinkIds = "drink_ids"
    }
    
    init(fromDictionary dictionary: [String : Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.uniqueId = dictionary["uniqueId"] as? String ?? ""
        self.firstName = dictionary["firstName"] as? String ?? ""
        self.lastName = dictionary["lastName"] as? String ?? ""
        self.nickName = dictionary["nickName"] as? String ?? ""
        self.dateOfBirth = dictionary["dob"] as? String ?? ""
        self.gender = dictionary["gender"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.location = dictionary["location"] as? String ?? ""
        self.city = dictionary["city"] as? String ?? ""
        self.receiveMarketing = dictionary["receiveMarketing"] as? Bool ?? false
        self.code = dictionary["code"] as? String ?? ""
        self.phone = dictionary["phone"] as? String ?? ""
        self.phoneVerified = dictionary["phoneVerified"] as? Bool ?? false
        self.status = dictionary["status"] as? String ?? ""
        self.image = dictionary["image"] as? String ?? ""
        self.instagramId = dictionary["instagramId"] as? String ?? ""
        self.spotifyId = dictionary["spotifyId"] as? String ?? ""
        self.isDeleted = dictionary["isDeleted"] as? Bool ?? false
        self.lastLogin = dictionary["lastLogin"] as? String ?? ""
        self.createdAt = dictionary["createdAt"] as? String ?? ""
        self.updatedAt = dictionary["updatedAt"] as? String ?? ""
        self.vibeIds = dictionary["vibeIds"] as? Array ?? []
        self.drinkIds = dictionary["drinkIds"] as? Array ?? []
    }
}

extension Currentuser: Decodable, Encodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try! values.decode(String.self, forKey: .id)
        uniqueId = try! values.decode(String.self, forKey: .uniqueId)
        firstName = try! values.decode(String.self, forKey: .firstName)
        lastName = try! values.decode(String.self, forKey: .lastName)
        nickName = try! values.decode(String.self, forKey: .nickName)
        dateOfBirth = try! values.decode(String.self, forKey: .dateOfBirth)
        gender = try! values.decode(String.self, forKey: .gender)
        email = try! values.decode(String.self, forKey: .email)
        location = try! values.decode(String.self, forKey: .location)
        city = try! values.decode(String.self, forKey: .city)
        receiveMarketing = try! values.decode(Bool.self, forKey: .receiveMarketing)
        code = try! values.decode(String.self, forKey: .code)
        phone = try! values.decode(String.self, forKey: .phone)
        phoneVerified = try! values.decode(Bool.self, forKey: .phoneVerified)
        status = try! values.decode(String.self, forKey: .status)
        image = try! values.decode(String.self, forKey: .image)
        instagramId = try! values.decode(String.self, forKey: .instagramId)
        spotifyId = try! values.decode(String.self, forKey: .spotifyId)
        isDeleted = try! values.decode(Bool.self, forKey: .isDeleted)
        lastLogin = try! values.decode(String.self, forKey: .lastLogin)
        createdAt = try! values.decode(String.self, forKey: .createdAt)
        updatedAt = try! values.decode(String.self, forKey: .updatedAt)
        vibeIds = try! values.decode([String].self, forKey: .vibeIds)
        drinkIds = try! values.decode([String].self, forKey: .drinkIds)
    }
    
    func encode(to encoder: Encoder) throws {
        var val = encoder.container(keyedBy: CodingKeys.self)
        try val.encode(id, forKey: .id)
        try val.encode(uniqueId, forKey: .uniqueId)
        try val.encode(firstName, forKey: .firstName)
        try val.encode(lastName, forKey: .lastName)
        try val.encode(nickName, forKey: .nickName)
        try val.encode(dateOfBirth, forKey: .dateOfBirth)
        try val.encode(gender, forKey: .gender)
        try val.encode(email, forKey: .email)
        try val.encode(location, forKey: .location)
        try val.encode(city, forKey: .city)
        try val.encode(receiveMarketing, forKey: .receiveMarketing)
        try val.encode(code, forKey: .code)
        try val.encode(phone, forKey: .phone)
        try val.encode(phoneVerified, forKey: .phoneVerified)
        try val.encode(status, forKey: .status)
        try val.encode(image, forKey: .image)
        try val.encode(instagramId, forKey: .instagramId)
        try val.encode(spotifyId, forKey: .spotifyId)
        try val.encode(isDeleted, forKey: .isDeleted)
        try val.encode(lastLogin, forKey: .lastLogin)
        try val.encode(createdAt, forKey: .createdAt)
        try val.encode(updatedAt, forKey: .updatedAt)
        try val.encode(vibeIds, forKey: .vibeIds)
        try val.encode(drinkIds, forKey: .drinkIds)
    }
}
