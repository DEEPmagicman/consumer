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

protocol BookingQueueSocketDelegate: AnyObject {
    func didUpdateQueue(seatingAreaBooking: SeatingAreaBookingResponse?)
}

private final class WeakDelegateBox {
    weak var value: AnyObject?

    init(_ value: AnyObject) {
        self.value = value
    }
}

final class WebSocketWrapper: NSObject {
    
    static let shared = WebSocketWrapper()

    private var socket: SocketIOClient?
    private var manager: SocketManager = SocketManager(socketURL: URL(string: "www.google.com")!)
    private var webSocketSleepTime: Double = 0.5
    private var isSocketSetupDone = false
    var isSocketConnected = false
    private var currentVenueId: String?
    private var currentTableBookingQueueId: String?
    private var registeredTableBookingQueueId: String?
    private var lastTableBookingQueueId: String?
    private var lastTableBookingQueueUpdate: SeatingAreaBookingResponse?
    
    private var _delegates: [WeakDelegateBox] = []
    private var _bookingQueueDelegates: [WeakDelegateBox] = []
    
    var delegate: [WebSocketCallBackDelegate] {
        get {
            // Auto-purge dead entries on every access
            _delegates = _delegates.filter { $0.value != nil }
            return _delegates.compactMap { $0.value as? WebSocketCallBackDelegate }
        }
    }

    private var bookingQueueDelegates: [BookingQueueSocketDelegate] {
        get {
            _bookingQueueDelegates = _bookingQueueDelegates.filter { $0.value != nil }
            return _bookingQueueDelegates.compactMap { $0.value as? BookingQueueSocketDelegate }
        }
    }
    
    let isAppClip = Bundle.main.bundleIdentifier?.contains("Clip") == true
    private var isAbleToConnect: Bool {
        ReachabilityManager.shared.isNetworkAvailable == true
    }
    
    func addDelegate(_ delegate: WebSocketCallBackDelegate) {
        guard !_delegates.contains(where: { $0.value === (delegate as AnyObject) }) else { return }
        _delegates.append(WeakDelegateBox(delegate as AnyObject))
    }
    
    func removeDelegate(_ delegate: WebSocketCallBackDelegate) {
        _delegates.removeAll { $0.value === (delegate as AnyObject) }
    }

    func addBookingQueueDelegate(_ delegate: BookingQueueSocketDelegate) {
        guard !_bookingQueueDelegates.contains(where: { $0.value === (delegate as AnyObject) }) else { return }
        _bookingQueueDelegates.append(WeakDelegateBox(delegate as AnyObject))
    }

    func removeBookingQueueDelegate(_ delegate: BookingQueueSocketDelegate) {
        _bookingQueueDelegates.removeAll { $0.value === (delegate as AnyObject) }
    }

    func connectTableBookingQueue(queueId: String, venueId: String? = nil, delegate: BookingQueueSocketDelegate? = nil) {
        let normalizedQueueId = queueId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQueueId.isEmpty else { return }

        if currentTableBookingQueueId != normalizedQueueId {
            lastTableBookingQueueId = nil
            lastTableBookingQueueUpdate = nil
        }

        if let delegate {
            addBookingQueueDelegate(delegate)
        }

        currentTableBookingQueueId = normalizedQueueId

        if let venueId, !venueId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updateSocketContext(venueId: venueId)
        } else {
            connect()
        }

        addTableBookingQueueListeners()

        if isSocketConnected {
            reconnectTableBookingQueue()
        }

        if let delegate,
           lastTableBookingQueueId == normalizedQueueId,
           let lastTableBookingQueueUpdate {
            DispatchQueue.main.async {
                delegate.didUpdateQueue(seatingAreaBooking: lastTableBookingQueueUpdate)
            }
        }
    }

    func disconnectTableBookingQueue(delegate: BookingQueueSocketDelegate? = nil) {
        if let delegate {
            removeBookingQueueDelegate(delegate)
        } else {
            _bookingQueueDelegates.removeAll()
        }

        guard bookingQueueDelegates.isEmpty else { return }

        currentTableBookingQueueId = nil
        lastTableBookingQueueId = nil
        lastTableBookingQueueUpdate = nil
        removeTableBookingQueueListeners()
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
        socket?.on("DOORMAN_SETTINGS") { data, _ in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let venueId = content["id"] as? String, let uniqueId = content["uniqueId"] as? String else {
                return
            }
            self.delegate.forEach { $0.didGenderWiseTicketChange(venueId: venueId, uniqueId: uniqueId) }
        }
        
        socket?.on("VENUE") { data, _ in
            guard let arr = data as? [[String: Any]], let dic = arr.first, let content = dic["content"] as? [String: Any], let venueData = content["venueData"] as? [String: Any], let venueId = venueData["id"] as? String, let venueStatus = content["venueStatus"] as? String, let uniqueId = venueData["uniqueId"] as? String else {
                return
            }
            
            var newVenueId = venueId
            if self.isAppClip { newVenueId = uniqueId }
            self.delegate.forEach { $0.updateVenueStatus(venueId: newVenueId, venueStatus: venueStatus) }
        }
        
        socket?.on("updatedEvent") { data, _ in
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
            self?.reconnectTableBookingQueue()
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
        
        if let socketUrl = URL(string: SharedURL.baseURL) {
            let venueId = UserDefaults.standard.string(forKey: "selectedVenueId")?.trimmingCharacters(in: .whitespacesAndNewlines)
            var headerDic: [String: Any] = [
                "module": "consumer",
                "platform": "ios",
                "app_version": "\(Bundle.main.releaseVersionNumber)"
            ]

            if let venueId, !venueId.isEmpty {
                headerDic["venue"] = venueId
            }

            manager = SocketManager(socketURL: socketUrl, config: [
                .log(false),
                .compress,
                .forceWebsockets(true),
                .forcePolling(false),
                .connectParams(headerDic),
                .reconnectAttempts(5),
                .reconnectWait(2),
                .reconnectWaitMax(10)
            ])
            socket = manager.defaultSocket
            addEventListener()
            setArrData()
            addTableBookingQueueListeners()
            print("-1-1 Connect: -\(venueId ?? "") ")
            socket?.connect()
        }
    }
    
    @objc func disConnect() {
        guard let socket = socket else { return }
        
        if socket.status == .disconnected {
            return
        }
        
        socket.disconnect()
        isSocketConnected = false
        print("-1-1 disConnect:")
    }
}

private extension WebSocketWrapper {

    enum TableBookingQueueEvent {
        static let reconnect = "reconnect-event-table-booking-queue"
    }

    func addTableBookingQueueListeners() {
        guard let queueId = currentTableBookingQueueId,
              let socket
        else { return }

        if let registeredTableBookingQueueId, registeredTableBookingQueueId != queueId {
            socket.off(registeredTableBookingQueueId)
        }

        socket.off(queueId)
        socket.off(TableBookingQueueEvent.reconnect)

        socket.on(queueId) { [weak self] data, _ in
            self?.handleTableBookingQueueUpdate(data)
            print(data)
        }

        socket.on(TableBookingQueueEvent.reconnect) { [weak self] data, _ in
            self?.handleTableBookingQueueUpdate(data)
            print(data)
        }

        registeredTableBookingQueueId = queueId
    }

    func removeTableBookingQueueListeners() {
        if let registeredTableBookingQueueId {
            socket?.off(registeredTableBookingQueueId)
        }

        socket?.off(TableBookingQueueEvent.reconnect)
        registeredTableBookingQueueId = nil
    }

    func reconnectTableBookingQueue() {
        guard let queueId = currentTableBookingQueueId else { return }

        socket?.emit(TableBookingQueueEvent.reconnect, [
            "id": queueId
        ])
    }

    func handleTableBookingQueueUpdate(_ data: [Any]) {
        guard let booking = decodeTableBookingQueueUpdate(from: data) else {
            print("Queue parsing failed")
            return
        }

        lastTableBookingQueueId = currentTableBookingQueueId
        lastTableBookingQueueUpdate = booking

        DispatchQueue.main.async {
            self.bookingQueueDelegates.forEach {
                $0.didUpdateQueue(seatingAreaBooking: booking)
            }
        }
    }

    func decodeTableBookingQueueUpdate(from data: [Any]) -> SeatingAreaBookingResponse? {
        for item in data {
            if let booking = decodeTableBookingQueue(from: item) {
                return booking
            }
        }

        return nil
    }

    func decodeTableBookingQueue(from item: Any) -> SeatingAreaBookingResponse? {
        if let dict = item as? [String: Any] {
            if isTableBookingQueueWrapper(dict),
               let content = dict["content"],
               let booking = decodeTableBookingQueue(from: content) {
                return booking
            }

            return decode(dict, as: SeatingAreaBookingResponse.self)
        }

        if let dictArray = item as? [[String: Any]] {
            for dict in dictArray {
                if let booking = decodeTableBookingQueue(from: dict) {
                    return booking
                }
            }
        }

        return nil
    }

    func isTableBookingQueueWrapper(_ dict: [String: Any]) -> Bool {
        dict["content"] != nil
            && dict["id"] == nil
            && dict["status"] == nil
            && dict["items"] == nil
    }

    func decode<T: Decodable>(_ object: Any, as type: T.Type) -> T? {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object)
        else { return nil }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Parsing error:", error)
            return nil
        }
    }

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
