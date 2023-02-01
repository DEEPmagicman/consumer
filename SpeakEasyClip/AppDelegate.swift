//
//  AppDelegate.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 25/01/23.
//

import UIKit
import IQKeyboardManagerSwift
import StripeApplePay

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true
        StripeAPI.defaultPublishableKey = "pk_test_51MVrDLBuSsaUd7BTwD22BrfvI0QvLhYMe1b4usjbCW5NefmUVgc0Th4ZrdeOBDL5Xdh3GgzYgvPsct7qFOw9q97W00Dx516uA1"
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
