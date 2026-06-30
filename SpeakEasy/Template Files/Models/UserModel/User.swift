//
//  CurrentUser.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/22.
//

import Foundation
import CoreLocation

struct User {
    
    var id: String
//    var uniqueId: String
    var firstName: String
    var lastName: String
    var nickName: String
    var dateOfBirth: String
    var gender: String
    var email: String
    var location: String
    var city: String
//    var receiveMarketing: Bool
    var code: String
    var phone: String
    var phoneVerified: Bool
    var status: String
    var image: ImageDetail
    var instagramUserId: String?
//    var instagramToken: String?
//    var instaNextPageURL: String?
    var instaUserName: String?
//    var spotifyId: String
    var isDeleted: Bool
    var lastLogin: String
    var createdAt: String
    var updatedAt: String
//    var vibeIds: [String]
//    var drinkIds: [String]
    var stripeCusId: String
    var isProfileCompleted: Bool
    var isSocial: Bool?
    var useEmail: String {
        email.removeWhitespaces()
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
//        case uniqueId = "unique_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case nickName = "nick_name"
        case dateOfBirth = "dob"
        case gender = "gender"
        case email = "email"
        case location = "location"
        case city = "city"
//        case receiveMarketing = "receive_marketing"
        case code = "code"
        case phone = "phone"
        case phoneVerified = "phone_verified"
        case status = "status"
        case image = "image"
        case instagramUserId = "instagramUserId"
//        case instagramId = "instagram_id"
//        case instagramToken
//        case instaNextPageURL
//        case instaUserName
//        case spotifyId = "spotify_id"
        case isDeleted = "is_deleted"
        case lastLogin = "last_login"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
//        case vibeIds = "vibe_ids"
//        case drinkIds = "drink_ids"
        case stripeCusId = "stripeCustId"
        case isProfileCompleted
        case isSocial
    }
    
    init(fromDictionary dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
//        self.uniqueId = dictionary["uniqueId"] as? String ?? ""
        self.firstName = dictionary["firstName"] as? String ?? ""
        self.lastName = dictionary["lastName"] as? String ?? ""
        self.nickName = dictionary["nickName"] as? String ?? ""
        self.dateOfBirth = dictionary["dob"] as? String ?? ""
        self.gender = dictionary["gender"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.location = dictionary["location"] as? String ?? ""
        self.city = dictionary["city"] as? String ?? ""
//        self.receiveMarketing = dictionary["receiveMarketing"] as? Bool ?? false
        self.code = dictionary["code"] as? String ?? ""
        self.phone = dictionary["phone"] as? String ?? ""
        self.phoneVerified = dictionary["phoneVerified"] as? Bool ?? false
        self.status = dictionary["status"] as? String ?? ""
        self.image = ImageDetail(fromDictionary: dictionary["image"] as? [String:Any] ?? [:])
//        self.instagramId = dictionary["instagramId"] as? String ?? ""
//        self.instagramToken = dictionary["instagramToken"] as? String ?? ""
//        self.instaNextPageURL = dictionary["instaNextPageURL"] as? String ?? nil
//        self.instaUserName = dictionary["instaUserName"] as? String ?? ""
//        self.spotifyId = dictionary["spotifyId"] as? String ?? ""
        self.isDeleted = dictionary["isDeleted"] as? Bool ?? false
        self.lastLogin = dictionary["lastLogin"] as? String ?? ""
        self.createdAt = dictionary["createdAt"] as? String ?? ""
        self.updatedAt = dictionary["updatedAt"] as? String ?? ""
//        self.vibeIds = dictionary["vibeIds"] as? Array ?? []
//        self.drinkIds = dictionary["drinkIds"] as? Array ?? []
        self.stripeCusId = dictionary["stripeCustId"] as? String ?? ""
        self.instagramUserId = dictionary["instagramUserId"] as? String ?? ""
        self.isProfileCompleted = dictionary["isProfileCompleted"] as? Bool ?? false
        self.isSocial = dictionary["isSocial"] as? Bool ?? false
    }
}

extension User: Decodable, Encodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? values.decode(String.self, forKey: .id)) ?? ""
//        uniqueId = (try? values.decode(String.self, forKey: .uniqueId)) ?? ""
        firstName = (try? values.decode(String.self, forKey: .firstName)) ?? ""
        lastName = (try? values.decode(String.self, forKey: .lastName)) ?? ""
        nickName = (try? values.decode(String.self, forKey: .nickName)) ?? ""
        dateOfBirth = (try? values.decode(String.self, forKey: .dateOfBirth)) ?? ""
        gender = (try? values.decode(String.self, forKey: .gender)) ?? ""
        email = (try? values.decode(String.self, forKey: .email)) ?? ""
        location = (try? values.decode(String.self, forKey: .location)) ?? ""
        city = (try? values.decode(String.self, forKey: .city)) ?? ""
//        receiveMarketing = (try? values.decode(Bool.self, forKey: .receiveMarketing)) ?? false
        code = (try? values.decode(String.self, forKey: .code)) ?? ""
        phone = (try? values.decode(String.self, forKey: .phone)) ?? ""
        phoneVerified = (try? values.decode(Bool.self, forKey: .phoneVerified)) ?? false
        status = (try? values.decode(String.self, forKey: .status)) ?? ""
        instagramUserId = (try? values.decode(String.self, forKey: .instagramUserId)) ?? ""
        image = (try? values.decode(ImageDetail.self, forKey: .image)) ?? ImageDetail(fromDictionary: [:])
//        instagramId = (try? values.decode(String.self, forKey: .instagramId)) ?? ""
//        instagramToken = try? values.decode(String.self, forKey: .instagramToken)
//        instaNextPageURL = try? values.decode(String.self, forKey: .instaNextPageURL)
//        instaUserName = try? values.decode(String.self, forKey: .instaUserName)
//        spotifyId = (try? values.decode(String.self, forKey: .spotifyId)) ?? ""
        isDeleted = (try? values.decode(Bool.self, forKey: .isDeleted)) ?? false
        lastLogin = (try? values.decode(String.self, forKey: .lastLogin)) ?? ""
        createdAt = (try? values.decode(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? values.decode(String.self, forKey: .updatedAt)) ?? ""
//        vibeIds = (try? values.decode([String].self, forKey: .vibeIds)) ?? []
//        drinkIds = (try? values.decode([String].self, forKey: .drinkIds)) ?? []
        stripeCusId = (try? values.decode(String.self, forKey: .stripeCusId)) ?? ""
        isProfileCompleted = (try? values.decode(Bool.self, forKey: .isProfileCompleted)) ?? false
        isSocial = (try? values.decode(Bool.self, forKey: .isSocial)) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var val = encoder.container(keyedBy: CodingKeys.self)
        try val.encode(id, forKey: .id)
//        try val.encode(uniqueId, forKey: .uniqueId)
        try val.encode(firstName, forKey: .firstName)
        try val.encode(lastName, forKey: .lastName)
        try val.encode(nickName, forKey: .nickName)
        try val.encode(dateOfBirth, forKey: .dateOfBirth)
        try val.encode(gender, forKey: .gender)
        try val.encode(email, forKey: .email)
        try val.encode(location, forKey: .location)
        try val.encode(city, forKey: .city)
//        try val.encode(receiveMarketing, forKey: .receiveMarketing)
        try val.encode(code, forKey: .code)
        try val.encode(phone, forKey: .phone)
        try val.encode(phoneVerified, forKey: .phoneVerified)
        try val.encode(status, forKey: .status)
        try val.encode(image, forKey: .image)
//        try val.encode(instagramId, forKey: .instagramId)
//        try val.encode(instagramToken, forKey: .instagramToken)
//        try val.encode(instaNextPageURL, forKey: .instaNextPageURL)
//        try val.encode(instaUserName, forKey: .instaUserName)
//        try val.encode(spotifyId, forKey: .spotifyId)
        try val.encode(isDeleted, forKey: .isDeleted)
        try val.encode(lastLogin, forKey: .lastLogin)
        try val.encode(createdAt, forKey: .createdAt)
        try val.encode(updatedAt, forKey: .updatedAt)
//        try val.encode(vibeIds, forKey: .vibeIds)
//        try val.encode(drinkIds, forKey: .drinkIds)
        try val.encode(stripeCusId, forKey: .stripeCusId)
        try val.encode(instagramUserId, forKey: .instagramUserId)
        try val.encode(isProfileCompleted, forKey: .isProfileCompleted)
        try val.encode(isSocial, forKey: .isSocial)
    }
}

struct ImageDetail {
   
    var key: String
    var name: String?
    var description: String?
    
    enum CodingKeys: String, CodingKey {
        case key
        case name
        case description
    }
    
    internal init(key: String, name: String, description: String) {
        self.key = key
        self.name = name
        self.description = description
    }
    
    init(fromDictionary dictionary: [String : Any]) {
        self.key = dictionary["key"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.description = dictionary["description"] as? String ?? ""
    }
    
    func toDictionary() -> [String: Any] {
        var jsonDict = [String: Any]()
        jsonDict["key"] = key
        jsonDict["name"] = name
        jsonDict["description"] = description
        return jsonDict
    }
}

extension ImageDetail: Decodable, Encodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = (try? values.decode(String.self, forKey: .key)) ?? ""
        name = (try? values.decode(String.self, forKey: .name)) ?? ""
        description = (try? values.decode(String.self, forKey: .description)) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var val = encoder.container(keyedBy: CodingKeys.self)
        try val.encode(key, forKey: .key)
        try val.encode(name, forKey: .name)
        try val.encode(description, forKey: .description)
    }
}

struct MVPCity: Codable {
    var label: String
    var value: String
    var lat: String?
    var lng: String?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(value, forKey: .value)
        try container.encodeIfPresent(lat, forKey: .lat)
        try container.encodeIfPresent(lng, forKey: .lng)
    }
}

extension MVPCity {
    var latitudeValue: CLLocationDegrees? {
        guard let lat else { return nil }
        return CLLocationDegrees(lat)
    }

    var longitudeValue: CLLocationDegrees? {
        guard let lng else { return nil }
        return CLLocationDegrees(lng)
    }

    var location: CLLocation? {
        guard let latitudeValue,
              let longitudeValue else {
            return nil
        }

        return CLLocation(latitude: latitudeValue, longitude: longitudeValue)
    }

    static func matching(locality: String?, in cities: [MVPCity]) -> MVPCity? {
        let normalizedLocality = locality?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        guard let normalizedLocality,
              !normalizedLocality.isEmpty else {
            return nil
        }

        return cities.first { city in
            let value = city.value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .lowercased()

            let label = city.label
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .lowercased()

            return value == normalizedLocality || label == normalizedLocality
        }
    }

    static func nearest(to location: CLLocation, in cities: [MVPCity]) -> MVPCity? {
        cities
            .compactMap { city -> (city: MVPCity, distance: CLLocationDistance)? in
                guard let cityLocation = city.location else { return nil }
                return (city, cityLocation.distance(from: location))
            }
            .min { $0.distance < $1.distance }?
            .city
    }
}
