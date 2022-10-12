//
//  UserModel.swift
//
//  Created by Hamza Hasan on 11/29/21
//  Copyright (c) . All rights reserved.
//


import ObjectMapper
import RealmSwift
import ObjectMapper_Realm

public class UserModel: Object, Mappable {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private struct SerializationKeys {
        static let email = "email"
        static let id = "_id"
        static let authToken = "authtoken"
    }
    
    // MARK: Properties

    @objc dynamic var email: String? = ""
    @objc dynamic var id: String? = ""
    @objc dynamic var authToken: String? = ""
    
    // MARK: ObjectMapper Initializers
    /// Map a JSON object to this class using ObjectMapper.
    ///
    /// - parameter map: A mapping from ObjectMapper.
    
    required convenience public init?(map : ObjectMapper.Map){
        self.init()
    }
    
    public override class func primaryKey() -> String? {
        return "id"
    }
    
    /// Map a JSON object to this class using ObjectMapper.
    ///
    /// - parameter map: A mapping from ObjectMapper.
    public func mapping(map: ObjectMapper.Map) {
        email <- map[SerializationKeys.email]
        id <- map[SerializationKeys.id]
        authToken <- map[SerializationKeys.authToken]
    
//        var allergies: [String]? = nil
//        allergies <- map["allergies"]
//
//        allergies?.forEach { allergie in
//            let value = ListCuisinesAllergies()
//            value.value = allergie
//            self.allergies.append(value)
//        }
    }
}
//class ListCuisinesAllergies:Object{
//    @objc dynamic var value: String = ""
//}
