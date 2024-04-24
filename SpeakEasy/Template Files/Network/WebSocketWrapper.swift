//
//  WebSocketWrapper.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 15/02/23.
//

import Foundation
import UIKit
import SocketIO

protocol WebSocketCallBackDelegate: AnyObject {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool)
    func didGenderWiseTicketChange(venueId: String, uniqueId: String)
    func didUpdateEvent(eventId: String)
    func didUpdateEventTicket(ticket: EventTicket)
    
    func updateTicketPrice(ticket: [CoverTicket])
    func updateAddOnsTicketPrice(ticket: [UpSellTicket])
    func updateVenueStatus(venueId: String, venueStatus: String)
    
}

final class WebSocketWrapper: NSObject {
    
    static let shared = WebSocketWrapper()

    private var socket: SocketIOClient?
    private var manager: SocketManager = SocketManager(socketURL: URL(string: "www.google.com")!)
    private var webSocketSleepTime: Double = 0.5
    private var isSocketConnected = false
    var delegate: [WebSocketCallBackDelegate] = []
    
    private var isAbleToConnect: Bool {
        ReachabilityManager.shared.isNetworkAvailable == true
    }
    
    func setUpWebSocket() {
        NotificationCenter.default.addObserver(self, selector: #selector(disConnect), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(connect), name: UIApplication.didBecomeActiveNotification, object: nil)
        connect()
    }
    
    @objc func setArrData() {
        socket?.on("COVER_TICKET") { data, ack in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [[String: Any]] else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
                let tickets = try decoder.decode([CoverTicket].self, from: data)
                self.delegate.forEach { $0.updateTicketPrice(ticket: tickets) }
            } catch {
                return
            }
        }
        
        socket?.on("ADDONS_TICKET") { data, ack in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [[String: Any]] else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
                let tickets = try decoder.decode([UpSellTicket].self, from: data)
                self.delegate.forEach { $0.updateAddOnsTicketPrice(ticket: tickets) }
            } catch {
                return
            }
        }
        
        socket?.on("EVENT_TICKET") { data, ack in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any] else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
                let tickets = try decoder.decode(EventTicket.self, from: data)
                self.delegate.forEach { $0.didUpdateEventTicket(ticket: tickets) }
            } catch {
                return
            }
        }
    }
    
    private func addEventListener() {
        
        socket?.on("VENUE") { data, ack in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let venueId = content["venueId"] as? String, let venueStatus = content["venueStatus"] as? String else {
                return
            }
            self.delegate.forEach { $0.updateVenueStatus(venueId: venueId, venueStatus: venueStatus) }
        }
        
        socket?.on(clientEvent: .connect) { _, _ in
            self.isSocketConnected = true
        }
        
        socket?.on(clientEvent: .disconnect) { _, _ in
            self.isSocketConnected = false
        }
        
        socket?.on("DOORMAN_SETTINGS") { data, ack in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let venueId = content["id"] as? String, let uniqueId = content["uniqueId"] as? String else {
                return
            }
            self.delegate.forEach { $0.didGenderWiseTicketChange(venueId: venueId, uniqueId: uniqueId) }
        }
        
        socket?.on("updatedEvent") { data, ack in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let eventId = content["eventId"] as? String else {
                return
            }
            self.delegate.forEach { $0.didUpdateEvent(eventId: eventId) }
        }
    }
    
    @objc func connect() {
        if !isAbleToConnect { return }
        if let socketUrl = URL(string: SharedURL.baseURL) {
            manager = SocketManager(socketURL: socketUrl, config: [.log(true), .compress])
            socket = manager.defaultSocket
            addEventListener()
            setArrData()
            socket?.connect()
        }
    }
    
    @objc func disConnect() {
        socket?.disconnect()
        self.isSocketConnected = false
    }
}

extension WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool) {}
    func didGenderWiseTicketChange(venueId: String, uniqueId: String) {}
    func didUpdateEvent(eventId: String) {}
    func didUpdateEventTicket(ticket: EventTicket) {}
    func updateVenueStatus(venueId: String, venueStatus: String) {}
    func updateTicketPrice(ticket: [CoverTicket]) {}
    func updateAddOnsTicketPrice(ticket: [UpSellTicket]) {}
}

