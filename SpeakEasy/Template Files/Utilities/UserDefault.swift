//
//  UserDefault.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation

final class UserDefault: NSObject {
    
    enum UserDefaultKey: String {
        case accessTokenKey = "accessToken"
        case userKey = "user"
        case isLoggedInKey = "isLoggedIn"
        case isGuest = "isGuest"
        case isMvp = "isMvp"
        case hasVisitedStartingPage = "hasVisitedStartingPage"
        case localCity = "Surat"
    }
    
    let userDefaults = UserDefaults.standard
    
    class var shared: UserDefault {
        struct Static {
            static let instance: UserDefault = UserDefault()
        }
        return Static.instance
    }
    
    var accessToken: String? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaultKey.accessTokenKey.rawValue) as? String
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.accessTokenKey.rawValue)
        }
    }
    
    var user: Currentuser? {
        get {
            if let savedUser = UserDefaults.standard.object(forKey: UserDefaultKey.userKey.rawValue) as? Data {
                do {
                    let loadedUser = try JSONDecoder().decode(Currentuser.self, from: savedUser)
                    return loadedUser
                } catch { }
            }
            return nil
        } set {
            do {
                let encoded = try JSONEncoder().encode(newValue)
                UserDefaults.standard.set(encoded, forKey: UserDefaultKey.userKey.rawValue)
                UserDefaults.standard.synchronize()
            } catch { }
        }
    }
    
    var isLoggedIn: Bool? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaultKey.isLoggedInKey.rawValue) as? Bool
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.isLoggedInKey.rawValue)
        }
    }
    
    var isGuest: Bool? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaultKey.isGuest.rawValue) as? Bool
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.isGuest.rawValue)
        }
    }
    
    var isMvp: Bool? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaultKey.isMvp.rawValue) as? Bool
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.isMvp.rawValue)
        }
    }
    
    var hasVisitedStartingPage: Bool {
        get {
            (UserDefaults.standard.value(forKey: UserDefaultKey.hasVisitedStartingPage.rawValue) as? Bool) ?? false
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.hasVisitedStartingPage.rawValue)
        }
    }
    
    var localCity: String {
        get {
            (UserDefaults.standard.value(forKey: UserDefaultKey.localCity.rawValue) as? String) ?? "Cleveland"
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.localCity.rawValue)
        }
    }
    
    func removeInstaConnection() {
        user?.instagramId = ""
        user?.instagramToken = nil
        user?.instaNextPageURL = nil
        user?.instaUserName = nil
    }
    
    func emptyData() {
        accessToken = nil
        user = nil
        isLoggedIn = false
        isGuest = false
    }
}
