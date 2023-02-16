//
//  WebSocketWrapper.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 15/02/23.
//

import Foundation
import Starscream

protocol webSocketCallBackDelegate: AnyObject {
    func didValueChange()
}

final class WebSocketWrapper: NSObject {
    
    static let shared = WebSocketWrapper()

    private var socket: WebSocket?
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
    
    @objc func connect() {
        if !isAbleToConnect { return }
        if let socketUrl = URL(string: webSocketURL) {
            var request = URLRequest(url: socketUrl)
            request.timeoutInterval = 5
            socket = WebSocket(request: request)
            socket?.delegate = self
            socket?.connect()
        }
    }
    
    @objc func disConnect() {
        socket?.disconnect()
        self.isSocketConnected = false
    }
}

extension WebSocketWrapper: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected(let dictionary):
            print(dictionary)
            self.isSocketConnected = true
            self.webSocketSleepTime = 0.5
        case .disconnected(let string, let uInt16):
            self.isSocketConnected = false
            print("websocket is disconnected WSError: \(string), WSError Code:\(uInt16)")

//            if let e = error as? WSError {
//                print("websocket is disconnected WSError: \(e.message), WSError Code:\(e.code)")
//            } else if let e = error {
//                print("websocket is disconnected local error: \(e.localizedDescription)")
//            } else {
//                print("websocket disconnected without any error")
//            }
//            if WebSocketWrapper.isAbleToConnect {
//                DispatchQueue.main.asyncAfter(deadline: .now() + WebSocketWrapper.webSocketSleepTime, execute: {
//                    socket?.connect()
//                })
//            }
//            self.webSocketSleepTime = self.webSocketSleepTime * 2
        case .text(let string):
            print("get text socket \(string)")
//            if let data = text.data(using: .utf8) {
//                do {
//                    //change method later
////                    let response = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
////                    self.JSONParser(from: response, isForWebSocket: true, completion: { (WSModel) in
////                        guard let webSocketModel = WSModel else {
////                            return
////                        }
////                        self.setApplicationBadgeCount(count: webSocketModel.messagesCount)
////                        let broadCastData = [WebSocketNotification.data.rawValue:webSocketModel] as [String : WebSocketModel]
////                        NotificationCenter.default.post(name: NSNotification.Name(WebSocketNotification.onGetMessage.rawValue), object: nil, userInfo: broadCastData)
////                    })
////
//                } catch {
//                    print("Failed websocket response JSONSerialization")
//                }
//            }
        case .binary(let data):
            break
        case .pong(let data):
            break
        case .ping(let data):
            break
        case .error(let error):
            print(error?.localizedDescription)
            break
        case .viabilityChanged(let bool):
            break
        case .reconnectSuggested(let bool):
            break
        case .cancelled:
            break
        }
    }
}
