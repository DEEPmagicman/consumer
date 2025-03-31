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
        if let incomingURL = userActivity.webpageURL {
            guard let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
                  let queryItems = components.queryItems else { return }
            
            if let value = queryItems.first(where: { $0.name == "v" })?.value {
                checkForDeepLink(value)
                return
            }
            if let venue = queryItems.first(where: { $0.name == "venueId" })?.value {
                venueId = venue
                UserDefaults.standard.setValue(venue, forKey: "venueId")
                return
            }
            if let venue = queryItems.first(where: { $0.name == "vid" })?.value {
                checkForDeepLink(venue)
                return
            }
        }
    }
    
    func checkForDeepLink(_ value: String) {
        if value.contains("VN") {
            venueId = value
            UserDefaults.standard.setValue(value, forKey: "venueId")
            
        } else {
            deepLinkId = value
            UserDefaults.standard.setValue(deepLinkId, forKey: "deepLinkId")
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
