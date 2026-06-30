//
//  UserDefault.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation
import Combine

final class UserDefault {
    
    // MARK: - Singleton
    
    static let shared = UserDefault()
    private init() {}
    
    // MARK: - Keys
    
    enum UserDefaultKey: String {
        case accessToken
        case refreshToken
        case user
        case isLoggedIn
        case isGuest
        case localCity
        case defaultCitySelected
        case isNotificationOn
        case isVersionV3Key
        case filterCity
        case hasSeenPremiumIntro
        case selectedVenueId
    }
    
    // Publishers
    private let citySubject = CurrentValueSubject<String, Never>("")
    private let filterCitySubject = CurrentValueSubject<String?, Never>(nil)
    
    var localCityPublisher: AnyPublisher<String, Never> {
        citySubject.eraseToAnyPublisher()
    }
    
    var filterCityPublisher: AnyPublisher<String?, Never> {
        filterCitySubject.eraseToAnyPublisher()
    }
    
    // MARK: - Properties
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Generic Helpers
    
    private func getValue<T>(for key: UserDefaultKey) -> T? {
        defaults.object(forKey: key.rawValue) as? T
    }
    
    private func setValue<T>(_ value: T?, for key: UserDefaultKey) {
        defaults.set(value, forKey: key.rawValue)
    }
    
    private func getCodable<T: Codable>(for key: UserDefaultKey) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }
        
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func setCodable<T: Codable>(_ value: T?, for key: UserDefaultKey) {
        guard let value else {
            defaults.removeObject(forKey: key.rawValue)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key.rawValue)
        } catch {
            print("Failed to encode \(key.rawValue): \(error)")
        }
    }
    
    // MARK: - Access Token
    
    var accessToken: String? {
        get { getValue(for: .accessToken) }
        set { setValue(newValue, for: .accessToken) }
    }
    
    // MARK: - Refresh Token
    
    var refreshToken: String? {
        get { getValue(for: .refreshToken) }
        set { setValue(newValue, for: .refreshToken) }
    }
    
    // MARK: - User
    
    var user: User? {
        get { getCodable(for: .user) }
        set { setCodable(newValue, for: .user) }
    }
    
    // MARK: - Login
    
    var isLoggedIn: Bool {
        get { getValue(for: .isLoggedIn) ?? false }
        set { setValue(newValue, for: .isLoggedIn) }
    }
    
    var isGuest: Bool {
        get { getValue(for: .isGuest) ?? true }
        set { setValue(newValue, for: .isGuest) }
    }
    
    // MARK: - City
    
    var localCity: String {
        get { getValue(for: .localCity) ?? "Chicago" }
        set { setValue(newValue, for: .localCity) }
    }
    
    var defaultCitySelected: Bool {
        get { getValue(for: .defaultCitySelected) ?? false }
        set { setValue(newValue, for: .defaultCitySelected) }
    }
    
    // MARK: - Notification
    
    var isNotificationOn: Bool {
        get { getValue(for: .isNotificationOn) ?? false }
        set { setValue(newValue, for: .isNotificationOn) }
    }
    
    var isVersionV3: Bool? {
        get { getValue(for: .isVersionV3Key) ?? false }
        set { setValue(newValue, for: .isVersionV3Key) }
    }
    
    var hasPrimaryLocation: Bool {
        primaryCity != nil
    }
    
    func setPrimaryCity(_ city: String) {
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCity.isEmpty else { return }

        set { setValue(UserDefaultKey.localCity.rawValue, for: .trimmedCity) }
        defaultCitySelected = true
        citySubject.send(trimmedCity)
    }
    
    var hasSeenPremiumIntro: Bool? {
        get { getValue(for: .hasSeenPremiumIntro) ?? false }
        set { setValue(newValue, for: .hasSeenPremiumIntro) }
    }
    
    var filterCity: String? {
        get {
            guard let city: String = getValue(for: .filterCity) else {
                return nil
            }

            let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        set {
            let trimmed = newValue?.trimmingCharacters(in: .whitespacesAndNewlines)

            if let trimmed, !trimmed.isEmpty {
                setValue(trimmed, for: .filterCity)
                filterCitySubject.send(trimmed)
            } else {
                defaults.removeObject(forKey: UserDefaultKey.filterCity.rawValue)
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
    
    // MARK: - Selected Venue

    var selectedVenueId: String? {
        get { getValue(for: .selectedVenueId) }
        set { setValue(newValue, for: .selectedVenueId) }
    }
    
    // MARK: - Reset
    
    func clearAll(except preserved: Set<UserDefaultKey> = []) {
        let all = defaults.dictionaryRepresentation()
        
        all.keys.forEach { key in
            guard let typedKey = UserDefaultKey(rawValue: key) else {
                defaults.removeObject(forKey: key)
                return
            }
            
            if !preserved.contains(typedKey) {
                defaults.removeObject(forKey: key)
            }
        }
    }
    
    func emptyData() {
        clearAll()
    }
}
