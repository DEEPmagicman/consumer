//
//  UserDefault.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation

final class UserDefault: NSObject {
    
    private let token = "token"
    private let USER = "user"
    
    let userDefaults = UserDefaults.standard
    
    class var shared: UserDefault {
        struct Static {
            static let instance: UserDefault = UserDefault()
        }
        return Static.instance
    }
    
    var loginToken: String? {
        get {
            return UserDefaults.standard.value(forKey: token) as? String
        } set {
            UserDefaults.standard.setValue(newValue, forKey: token)
        }
    }
    
    var user: Currentuser? {
        get {
            if let savedUser = UserDefaults.standard.object(forKey: USER) as? Data {
                do {
                    let loadedUser = try JSONDecoder().decode(Currentuser.self, from: savedUser)
                    return loadedUser
                } catch { }
            }
            return nil
        } set {
            do {
                let encoded = try JSONEncoder().encode(newValue)
                UserDefaults.standard.set(encoded, forKey: USER)
                UserDefaults.standard.synchronize()
            } catch { }
        }
    }
    
    func removeInstaConnection() {
        user?.instagramId = ""
        user?.instagramToken = nil
        user?.instaNextPageURL = nil
        user?.instaUserName = nil
    }
}
