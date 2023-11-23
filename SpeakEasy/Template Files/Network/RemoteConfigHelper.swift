//
//  RemoteConfigHelper.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 24/04/23.
//

import UIKit
import FirebaseRemoteConfig

final class RemoteConfigHelper {
    
    private init() {
        let configSettings = RemoteConfigSettings()
        configSettings.minimumFetchInterval = 0
        remoteConfig.configSettings = configSettings
    }
    
    static let shared = RemoteConfigHelper()
    var remoteConfig = RemoteConfig.remoteConfig()
    var iOSConsumerHardUpdateVersion: Int = 0
    var iOSConsumerSoftUpdateVersion: Int = 0
    var isShowingAlert = false

    func getRemoteConfigValues(showSoftUpdate: Bool = false) {
        remoteConfig.fetch(withExpirationDuration: 300) { _, _ in
            self.remoteConfig.activate { _, _ in
                self.iOSConsumerHardUpdateVersion = Int(self.remoteConfig.configValue(forKey: "ios_consumer_hard_update_version").stringValue ?? "") ?? -1
                self.iOSConsumerSoftUpdateVersion = Int(self.remoteConfig.configValue(forKey: "ios_consumer_soft_update_version").stringValue ?? "") ?? -1
                
                if self.iOSConsumerHardUpdateVersion > Int(Bundle.main.releaseVersionNumber.replacingOccurrences(of: ".", with: "")) ?? 0 {
                    self.forceUpdateAlert()
                } else if self.iOSConsumerSoftUpdateVersion > Int(Bundle.main.releaseVersionNumber.replacingOccurrences(of: ".", with: "")) ?? 0 {
                    if showSoftUpdate == false { return }
                    self.softUpdateAlert()
                }
            }
        }
    }
    
    func forceUpdateAlert() {
        if isShowingAlert { return }
        let okAction = UIAlertAction(title: "Update", style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.openAppStore()
        }
        isShowingAlert = true
        Alert.showAlertSheet(style: .alert, title: "New version available", message: "Please update to continue using app", actions: [okAction])
    }
    
    func softUpdateAlert() {
        if isShowingAlert { return }
        let okAction = UIAlertAction(title: "Update", style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.openAppStore()
        }
        let cancelAction = UIAlertAction(title: "Skip", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            self.isShowingAlert = false
        }
        isShowingAlert = true
        Alert.showAlertSheet(style: .alert, title: "New version available", message: "Update to latest version for best experience", actions: [okAction, cancelAction])
    }
    
    func openAppStore() {
        isShowingAlert = false
        if let url = URL(string: SharedURL.appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
}
