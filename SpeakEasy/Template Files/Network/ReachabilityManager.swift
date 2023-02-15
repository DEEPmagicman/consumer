//
//  ReachabilityManager.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 15/02/23.
//

import Foundation
import ReachabilitySwift

final class ReachabilityManager: NSObject {

    static let shared = ReachabilityManager()

    var isNetworkAvailable: Bool {
        reachabilityStatus != .notReachable
    }
    var reachabilityStatus: Reachability.NetworkStatus = .notReachable
    let reachability = Reachability()!

    @objc func reachabilityChanged(notification: Notification) {
        DispatchQueue.main.async {
            let reachability = notification.object as! Reachability
            switch reachability.currentReachabilityStatus {
            case .notReachable:
                print("Network became unreachable")
                self.reachabilityStatus = .notReachable
            case .reachableViaWiFi:
                print("Network reachable through WiFi")
                self.reachabilityStatus = .reachableViaWiFi
            case .reachableViaWWAN:
                print("Network reachable through Cellular Data")
                self.reachabilityStatus = .reachableViaWWAN
            @unknown default:
                break
            }
        }
    }

    func startMonitoring() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(self.reachabilityChanged),
            name: ReachabilityChangedNotification,
            object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("Could not start reachability notifier")
        }
    }
    
    func removeReachabilityObserver() {
        NotificationCenter.default.removeObserver(self, name: ReachabilityChangedNotification, object: reachability)
    }
}
