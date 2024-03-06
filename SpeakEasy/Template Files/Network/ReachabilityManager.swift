//
//  ReachabilityManager.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 15/02/23.
//

import Foundation
import Reachability

final class ReachabilityManager: NSObject {

    static let shared = ReachabilityManager()

    var isNetworkAvailable: Bool {
        reachabilityStatus != .unavailable
    }
    var reachabilityStatus: Reachability.Connection = .unavailable
    let reachability = try! Reachability()

    @objc func reachabilityChanged(notification: Notification) {
        DispatchQueue.main.async {
            let reachability = notification.object as! Reachability
            switch reachability.connection {
            case .unavailable:
                print("Network became unreachable")
                self.reachabilityStatus = .unavailable
                WebSocketWrapper.shared.disConnect()
            case .wifi:
                print("Network reachable through WiFi")
                self.reachabilityStatus = .wifi
                WebSocketWrapper.shared.setUpWebSocket()
            case .cellular:
                print("Network reachable through Cellular Data")
                self.reachabilityStatus = .cellular
                WebSocketWrapper.shared.setUpWebSocket()
            }
        }
    }

    func startMonitoring() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(self.reachabilityChanged),
            name: Notification.Name.reachabilityChanged,
            object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("Could not start reachability notifier")
        }
    }
    
    func removeReachabilityObserver() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.reachabilityChanged, object: reachability)
    }
}
