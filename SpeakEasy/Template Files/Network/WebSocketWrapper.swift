//
//  WebSocketWrapper.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 15/02/23.
//

import Foundation
import UIKit
import SocketIO

struct EventTicketSoldCountUpdate {
    let ticketId: String
    let eventId: String?
    let soldUnits: Int?
    let issuedUnits: Int?
}

protocol WebSocketCallBackDelegate: AnyObject {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool)
    func didGenderWiseTicketChange(venueId: String, uniqueId: String)
    func didUpdateEvent(eventId: String)
    func didUpdateEventTicket(ticket: EventTicket)
    func didUpdateEventTicketSoldCount(_ update: EventTicketSoldCountUpdate)
    
    func updateTicketPrice(ticket: [CoverTicket])
    func updateAddOnsTicketPrice(ticket: [UpSellTicket])
    func updateVenueStatus(venueId: String, venueStatus: String)
    
    func checkInTicket(checkIndata: [BookingHasCheckIn], bookingId: String)
    func unCheckTicket(checkIndata: [BookingHasCheckIn], bookingId: String)
    func checkInAddOnsTicket(checkIndata: [AddOnsBookingHasCheckIn], bookingId: String)
    func unCheckAddOnsTicket(checkIndata: [AddOnsBookingHasCheckIn], bookingId: String)
    
    func checkinBarBooking(barItems: [BarTabHasItem])
    func uncheckBarBooking(barItems: [BarTabHasItem])
}

final class WebSocketWrapper: NSObject {
    
    static let shared = WebSocketWrapper()

    private var socket: SocketIOClient?
    private var manager: SocketManager = SocketManager(socketURL: URL(string: "www.google.com")!)
    private var webSocketSleepTime: Double = 0.5
    private var isSocketSetupDone = false
    var isSocketConnected = false
    private var currentVenueId: String?
    var delegate: [WebSocketCallBackDelegate] = []
    
    let isAppClip = Bundle.main.bundleIdentifier?.contains("Clip") == true
    private var isAbleToConnect: Bool {
        ReachabilityManager.shared.isNetworkAvailable == true
    }
    
    func setUpWebSocket() {
        guard !isSocketSetupDone else {
            return
        }
        
        isSocketSetupDone = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(disConnect), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(connect), name: UIApplication.didBecomeActiveNotification, object: nil)
        connect()
    }

    func updateSocketContext(venueId: String?) {
        let normalizedVenueId = venueId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextVenueId = normalizedVenueId?.isEmpty == false ? normalizedVenueId : nil

        let venueId = UserDefaults.standard.string(forKey: "selectedVenueId") ?? ""
        guard venueId != nextVenueId else { return }

        UserDefaults.standard.set(nextVenueId, forKey: "selectedVenueId")
        disConnect()
        connect()
    }
    
    @objc func setArrData() {
        socket?.on("DOORMAN_SETTINGS") { data, ack in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let venueId = content["id"] as? String, let uniqueId = content["uniqueId"] as? String else {
                return
            }
            self.delegate.forEach { $0.didGenderWiseTicketChange(venueId: venueId, uniqueId: uniqueId) }
        }
        
        socket?.on("VENUE") { data, ack in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let venueData = content["venueData"] as? [String: Any], let venueId = venueData["id"] as? String, let venueStatus = content["venueStatus"] as? String, let uniqueId = venueData["uniqueId"] as? String else {
                return
            }
            
            var newVenueId = venueId
            if self.isAppClip { newVenueId = uniqueId }
            self.delegate.forEach { $0.updateVenueStatus(venueId: newVenueId, venueStatus: venueStatus) }
        }
        
        socket?.on("updatedEvent") { data, ack in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let eventId = content["eventId"] as? String else {
                return
            }
            self.delegate.forEach { $0.didUpdateEvent(eventId: eventId) }
        }
        
        socket?.on("COVER_TICKET") { data, _ in
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
        
        socket?.on("ADDONS_TICKET") { data, _ in
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
        
        socket?.on("EVENT_TICKET") { data, _ in
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

        socket?.on("EVENT_TICKET_SOLD_COUNT_CHANGED") { data, _ in
            let updates = self.parseEventTicketSoldCountUpdates(from: data)
            guard !updates.isEmpty else {
                return
            }
            updates.forEach { update in
                self.delegate.forEach {
                    $0.didUpdateEventTicketSoldCount(update)
                }
            }
        }
        
        socket?.on("CHECK_IN_BOOKING") { data, _ in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let checkInData = content["bookingHasCheckIn"] as? [[String: Any]], let bookingId = content["id"] as? String else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: checkInData, options: .prettyPrinted)
                let tickets = try decoder.decode([BookingHasCheckIn].self, from: data)
                self.delegate.forEach { $0.checkInTicket(checkIndata: tickets, bookingId: bookingId) }
            } catch {
                return
            }
        }
        
        socket?.on("UNCHECK_BOOKING") { data, _ in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let checkInData = content["bookingHasCheckIn"] as? [[String: Any]], let bookingId = content["id"] as? String else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: checkInData, options: .prettyPrinted)
                let tickets = try decoder.decode([BookingHasCheckIn].self, from: data)
                self.delegate.forEach { $0.unCheckTicket(checkIndata: tickets, bookingId: bookingId) }
            } catch {
                return
            }
        }
        
        socket?.on("CHECK_IN_ADDONS") { data, _ in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let checkInData = content["addOnsBookingHasCheckIn"] as? [[String: Any]], let bookingId = content["id"] as? String else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: checkInData, options: .prettyPrinted)
                let tickets = try decoder.decode([AddOnsBookingHasCheckIn].self, from: data)
                self.delegate.forEach { $0.checkInAddOnsTicket(checkIndata: tickets, bookingId: bookingId) }
            } catch {
                return
            }
        }
        
        socket?.on("UNCHECK_ADDONS") { data, _ in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let checkInData = content["addOnsBookingHasCheckIn"] as? [[String: Any]], let bookingId = content["id"] as? String else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: checkInData, options: .prettyPrinted)
                let tickets = try decoder.decode([AddOnsBookingHasCheckIn].self, from: data)
                self.delegate.forEach { $0.unCheckAddOnsTicket(checkIndata: tickets, bookingId: bookingId) }
            } catch {
                return
            }
        }
        
        socket?.on("CHECK_IN_BAR_TAB") { data, _ in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let checkInData = content["barTabHasItems"] as? [[String: Any]] else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: checkInData, options: .prettyPrinted)
                let tickets = try decoder.decode([BarTabHasItem].self, from: data)
                self.delegate.forEach { $0.checkinBarBooking(barItems: tickets) }
            } catch {
                return
            }
        }
        
        socket?.on("UNCHECK_BAR_TAB") { data, _ in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let checkInData = content["barTabHasItems"] as? [[String: Any]] else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: checkInData, options: .prettyPrinted)
                let tickets = try decoder.decode([BarTabHasItem].self, from: data)
                self.delegate.forEach { $0.uncheckBarBooking(barItems: tickets) }
            } catch {
                return
            }
        }
        
        socket?.on("EVENT") { data, _ in
            guard let eventId = self.eventIdentifier(from: data) else {
                return
            }
            self.delegate.forEach { $0.didUpdateEvent(eventId: eventId) }
        }
    }
    
    private func addEventListener() {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            self?.isSocketConnected = true
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?.isSocketConnected = false
        }
    }
    
    @objc func connect() {
        if !isAbleToConnect { return }
        
        if isSocketConnected {
            print("Socket already connected")
            return
        }
        
        if socket?.status == .connected ||
            socket?.status == .connecting {
            return
        }
        
        guard let venueId = UserDefaults.standard.string(forKey: "selectedVenueId") else {
            return
        }
        if let socketUrl = URL(string: SharedURL.baseURL) {
            let headerDic = ["venue": venueId,
                             "module": "consumer",
                             "platform": "ios",
                             "app_version": "\(Bundle.main.releaseVersionNumber)"]
            manager = SocketManager(socketURL: socketUrl, config: [.log(true), .compress, .connectParams(headerDic)])
            socket = manager.defaultSocket
            addEventListener()
            setArrData()
            socket?.connect()
        }
    }
    
    @objc func disConnect() {
        guard let socket = socket else { return }
        
        if socket.status == .disconnected {
            return
        }
        
        print("-1-1disConnect:")
        socket.disconnect()
        isSocketConnected = false
    }
}

private extension WebSocketWrapper {

    func eventIdentifier(from data: [Any]) -> String? {
        guard let arr = data as? [[String: Any]],
              let dic = arr.first
        else { return nil }

        let content = (dic["content"] as? [String: Any]) ?? dic
        let eventId =
            content["eventId"] as? String ??
            content["uniqueId"] as? String ??
            content["id"] as? String

        guard let eventId, !eventId.isEmpty else { return nil }

        return eventId
    }

    func parseEventTicketSoldCountUpdates(from data: [Any]) -> [EventTicketSoldCountUpdate] {
        guard let arr = data as? [[String: Any]],
              let dic = arr.first
        else { return [] }

        if let contents = dic["content"] as? [[String: Any]] {
            return contents.compactMap { eventTicketSoldCountUpdate(from: $0) }
        }

        if let content = dic["content"] as? [String: Any],
           let update = eventTicketSoldCountUpdate(from: content) {
            return [update]
        }

        if let update = eventTicketSoldCountUpdate(from: dic) {
            return [update]
        }

        return []
    }

    func eventTicketSoldCountUpdate(from content: [String: Any]) -> EventTicketSoldCountUpdate? {
        let ticketId =
            content["ticketId"] as? String ??
            content["eventTicketId"] as? String ??
            content["id"] as? String

        guard let ticketId, !ticketId.isEmpty else { return nil }

        return EventTicketSoldCountUpdate(
            ticketId: ticketId,
            eventId: content["eventId"] as? String,
            soldUnits: intValue(from: content["soldUnits"] ?? content["soldCount"]),
            issuedUnits: intValue(from: content["issuedUnits"])
        )
    }

    func intValue(from value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }

        if let value = value as? Double {
            return Int(value)
        }

        if let value = value as? String {
            return Int(value)
        }

        return nil
    }
}

extension WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool) { }

    func didGenderWiseTicketChange(venueId: String, uniqueId: String) { }

    func didUpdateEvent(eventId: String) { }

    func didUpdateEventTicket(ticket: EventTicket) { }

    func didUpdateEventTicketSoldCount(_ update: EventTicketSoldCountUpdate) { }

    func updateVenueStatus(venueId: String, venueStatus: String) { }

    func updateTicketPrice(ticket: [CoverTicket]) { }

    func updateAddOnsTicketPrice(ticket: [UpSellTicket]) { }
    
    func checkInTicket(checkIndata: [BookingHasCheckIn], bookingId: String) { }

    func unCheckTicket(checkIndata: [BookingHasCheckIn], bookingId: String) { }

    func checkInAddOnsTicket(checkIndata: [AddOnsBookingHasCheckIn], bookingId: String) { }

    func unCheckAddOnsTicket(checkIndata: [AddOnsBookingHasCheckIn], bookingId: String) { }
    
    func checkinBarBooking(barItems: [BarTabHasItem]) { }

    func uncheckBarBooking(barItems: [BarTabHasItem]) { }
}
