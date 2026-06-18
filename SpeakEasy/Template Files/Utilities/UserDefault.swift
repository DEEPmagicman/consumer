//
//  UserDefault.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation
import Combine

final class UserDefault: NSObject {
    
    enum UserDefaultKey: String {
        case accessTokenKey = "accessToken"
        case refreshTokenKey = "refreshToken"
        case userKey = "user"
        case isLoggedInKey = "isLoggedIn"
        case isVersionV3Key = "isVersionV3"
        case isGuest = "isGuest"
        case localCity = "localCity"
        case filterCity = "filterCity"
        case defaultCitySelected = "defaultCitySelected"
        case isNotificationOnKey = "isNotificationOn"
        case hasSeenPremiumIntro = "has_seen_premium_intro"
    }
    
    let userDefaults = UserDefaults.standard
    
    class var shared: UserDefault {
        struct Static {
            static let instance: UserDefault = UserDefault()
        }
        return Static.instance
    }
    
    private let citySubject = CurrentValueSubject<String, Never>("")
    private let filterCitySubject = CurrentValueSubject<String?, Never>(nil)

       var localCityPublisher: AnyPublisher<String, Never> {
           citySubject.eraseToAnyPublisher()
       }

    var filterCityPublisher: AnyPublisher<String?, Never> {
        filterCitySubject.eraseToAnyPublisher()
    }
    
    var accessToken: String? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaultKey.accessTokenKey.rawValue) as? String
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.accessTokenKey.rawValue)
        }
    }
    
    var refreshToken: String? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaultKey.refreshTokenKey.rawValue) as? String
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.refreshTokenKey.rawValue)
        }
    }
    
    var user: User? {
        get {
            if let savedUser = UserDefaults.standard.object(forKey: UserDefaultKey.userKey.rawValue) as? Data {
                do {
                    let loadedUser = try JSONDecoder().decode(User.self, from: savedUser)
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
    
    var isVersionV3: Bool? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaultKey.isVersionV3Key.rawValue) as? Bool
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.isVersionV3Key.rawValue)
        }
    }
    
    var isGuest: Bool {
        get {
            return UserDefaults.standard.value(forKey: UserDefaultKey.isGuest.rawValue) as? Bool ?? true
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.isGuest.rawValue)
        }
    }
    
    var localCity: String {
        get {
            (UserDefaults.standard.value(forKey: UserDefaultKey.localCity.rawValue) as? String) ?? "Chicago"
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.localCity.rawValue)
            citySubject.send(newValue)
        }
    }

    var filterCity: String? {
        get {
            guard let city = UserDefaults.standard.value(forKey: UserDefaultKey.filterCity.rawValue) as? String else {
                return nil
            }

            let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedCity.isEmpty ? nil : trimmedCity
        } set {
            let trimmedCity = newValue?.trimmingCharacters(in: .whitespacesAndNewlines)

            if let trimmedCity,
               !trimmedCity.isEmpty {
                UserDefaults.standard.setValue(trimmedCity, forKey: UserDefaultKey.filterCity.rawValue)
                filterCitySubject.send(trimmedCity)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultKey.filterCity.rawValue)
                filterCitySubject.send(nil)
            }
        }
    }

    var activeCity: String {
        let temporaryCity = filterCity?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let temporaryCity,
           !temporaryCity.isEmpty {
            return temporaryCity
        }

        let primaryCity = localCity
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return primaryCity.isEmpty ? "Chicago" : primaryCity
    }
    
    var defaultCitySelected: Bool {
        get {
            (UserDefaults.standard.value(forKey: UserDefaultKey.defaultCitySelected.rawValue) as? Bool) ?? false
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.defaultCitySelected.rawValue)
        }
    }
    
    var isNotificationOn: Bool {
        get {
            (UserDefaults.standard.value(forKey: UserDefaultKey.isNotificationOnKey.rawValue) as? Bool) ?? false
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.isNotificationOnKey.rawValue)
        }
    }
    
    var hasSeenPremiumIntro: Bool? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaultKey.hasSeenPremiumIntro.rawValue) as? Bool
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultKey.hasSeenPremiumIntro.rawValue)
        }
    }
    
//    func removeInstaConnection() {
//        user?.instagramId = ""
//        user?.instagramToken = nil
//        user?.instaNextPageURL = nil
//        user?.instaUserName = nil
//    }
    
    func emptyData() {
        accessToken = nil
        user = nil
        isLoggedIn = false
        isGuest = true
        filterCity = nil
        isNotificationOn = false
    }
}
