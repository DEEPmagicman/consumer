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

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        if let activity = connectionOptions.userActivities.filter({ $0.activityType == NSUserActivityTypeBrowsingWeb }).first {
            if let incomingURL = activity.webpageURL {
                guard let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
                    return
                }
                if let venue = queryItems.first(where: { $0.name == "v" })?.value {
                    venueId = venue
                    UserDefaults.standard.setValue(venue, forKey: "venueId")
                    return
                }
                if let venue = queryItems.first(where: { $0.name == "venueId" })?.value {
                    venueId = venue
                    UserDefaults.standard.setValue(venue, forKey: "venueId")
                }
            }
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
