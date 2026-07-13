//
//  SceneDelegate.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 25/01/23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var venueId = ""
    var deepLinkId = ""

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        if let activity = connectionOptions.userActivities.filter({ $0.activityType == NSUserActivityTypeBrowsingWeb }).first {
            self.extractVenueIdFromUrl(userActivity: activity)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        self.extractVenueIdFromUrl(userActivity: userActivity)
        NotificationCenter.default.post(name: Notification.Name("DeepLinkReceived"), object: nil, userInfo: nil)
    }
    
    func extractVenueIdFromUrl(userActivity: NSUserActivity) {
        UserDefaults.standard.removeObject(forKey: "venueId")
        UserDefaults.standard.removeObject(forKey: "deepLinkId")
        UserDefaults.standard.removeObject(forKey: "selectedVenueId")
        
        if let incomingURL = userActivity.webpageURL {
            guard let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
                  let queryItems = components.queryItems else { return }
            
            if let value = value(for: ["v"], in: queryItems) {
                checkForDeepLink(value)
                return
            }
            if let venue = value(for: ["venueId"], in: queryItems) {
                venueId = venue
                UserDefaults.standard.setValue(venue, forKey: "venueId")
                return
            }
            if let venue = value(for: ["vid"], in: queryItems) {
                checkForDeepLink(venue)
                return
            }
        }
    }

    private func value(for names: [String], in queryItems: [URLQueryItem]) -> String? {
        let lowercasedNames = names.map { $0.lowercased() }
        return queryItems.compactMap { item -> String? in
            guard lowercasedNames.contains(item.name.lowercased()) else { return nil }
            let value = item.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty ? nil : value
        }.first
    }
    
    func checkForDeepLink(_ value: String) {
        if value.uppercased().hasPrefix("DL") {
            deepLinkId = value
            UserDefaults.standard.setValue(deepLinkId, forKey: "deepLinkId")
        } else {
            venueId = value
            UserDefaults.standard.setValue(value, forKey: "venueId")
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
