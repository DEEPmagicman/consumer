//
//  WebSocketWrapper.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 15/02/23.
//

import Foundation
import SocketIO

protocol webSocketCallBackDelegate: AnyObject {
    func didValueChange(venueId: String, uniqueId: String)
}

final class WebSocketWrapper: NSObject {
    
    static let shared = WebSocketWrapper()

    private var socket: SocketIOClient?
    private var manager: SocketManager = SocketManager(socketURL: URL(string: "www.google.com")!)
    private let webSocketURL = "ws://146.190.123.18:1563"
    private var webSocketSleepTime: Double = 0.5
    private var isSocketConnected = false
    var delegate: [webSocketCallBackDelegate] = []
    
    private var isAbleToConnect: Bool {
        ReachabilityManager.shared.isNetworkAvailable == true
    }
    
    func setUpWebSocket() {
        NotificationCenter.default.addObserver(self, selector: #selector(disConnect), name: UIApplication.didEnterBackgroundNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(connect), name: UIApplication.willEnterForegroundNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(disConnect), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(connect), name: UIApplication.didBecomeActiveNotification, object: nil)
        connect()
    }
    
    private func addEventListener() {
        socket?.on("venueListEvent") { data, ack in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let venueId = content["venueId"] as? String, let uniqueId = content["uniqueId"] as? String else {
                return
            }
            self.delegate.forEach { $0.didValueChange(venueId: venueId, uniqueId: uniqueId) }
        }
        
        socket?.on(clientEvent: .connect) {data, ack in
            self.isSocketConnected = true
        }
        
        socket?.on(clientEvent: .disconnect) { _, _ in
            self.isSocketConnected = false
        }
    }
    
    @objc func connect() {
        if !isAbleToConnect { return }
        if let socketUrl = URL(string: webSocketURL) {
            manager = SocketManager(socketURL: socketUrl, config: [.log(true), .compress])
            socket = manager.defaultSocket
            addEventListener()
            socket?.connect()
        }
    }
    
    @objc func disConnect() {
        socket?.disconnect()
        self.isSocketConnected = false
    }
}
