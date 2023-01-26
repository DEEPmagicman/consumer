//
//  AppDelegate.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 25/01/23.
//

import UIKit
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate{ //}, NSApplicationDelegate, NSObject {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true
        return true
    }
    
//    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem) async -> Bool {
//        false
//    }
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        false
    }
    
    func application(_ application: UIApplication, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        print("")
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
            if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
                guard let url = userActivity.webpageURL else {
                    return false
                }
                //.example.com
                //Ferching query parameters
//                let queryParams = url.queryParams()
//                if let accessToken = queryParams["access_token"] as? String {
//                    //Do your actions here
//                }
              
            }
            return true
    }
    
//    func applicationDidBecomeActive(_ notification: Notification) {
//            // Restore first minimized window if app became active and no one window
//            // is visible
//            if NSApp.windows.compactMap({ $0.isVisible ? Optional(true) : nil }).isEmpty {
//                 NSApp.windows.first?.makeKeyAndOrderFront(self)
//            }
//        }
    
    func application(_ application: UIApplication,
                             continue userActivity: NSUserActivity,
                             restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
           true
        }
    
//    func application(_ application: NSApplication, open urls: [URL]) {
//            print("Unhandled: \(urls)")    // << here !!
//        }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
