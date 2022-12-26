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
    var LastName: String
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
    
    init(fromDictionary dictionary: [String : Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.uniqueId = dictionary["uniqueId"] as? String ?? ""
        self.firstName = dictionary["firstName"] as? String ?? ""
        self.LastName = dictionary["LastName"] as? String ?? ""
        self.nickName = dictionary["nickName"] as? String ?? ""
        self.dateOfBirth = dictionary["dateOfBirth"] as? String ?? ""
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
