//
//  BookingQueueSocketManager.swift
//  SpeakEasy-Consumer
//

import Foundation
import SocketIO

protocol BookingQueueSocketDelegate: AnyObject {
    func didUpdateQueue(seatingAreaBooking: SeatingAreaBookingResponse?)
}

final class BookingQueueSocketManager {

    static let shared = BookingQueueSocketManager()

    private enum Event {
        static let reconnectTableBookingQueue = "reconnect-event-table-booking-queue"
    }

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    weak var delegate: BookingQueueSocketDelegate?

    private(set) var isConnected = false
    private var currentQueueId: String?
    private var currentVenueId: String?

    func connect(queueId: String, venueId: String? = nil) {
        disconnect()
        currentQueueId = queueId
        currentVenueId = venueId

        guard let socketURL = URL(string: SharedURL.baseURL) else { return }

        var connectParams: [String: Any] = [
            "module": "consumer",
            "platform": "ios"
        ]

        var extraHeaders: [String: String] = [
            "module": "consumer",
            "platform": "ios"
        ]

        if let venueId, !venueId.isEmpty {
            connectParams["venue"] = venueId
            extraHeaders["venue"] = venueId
        }

        manager = SocketManager(
            socketURL: socketURL,
            config: [
                .log(false),
                .compress,
                .forceWebsockets(true),
                .forcePolling(false),
                .reconnects(true),
                .reconnectAttempts(5),
                .reconnectWait(2),
                .reconnectWaitMax(10),
                .connectParams(connectParams),
                .extraHeaders(extraHeaders)
            ]
        )

        socket = manager?.defaultSocket

        addListeners()
        socket?.connect()
    }

    func disconnect() {
        socket?.removeAllHandlers()
        socket?.disconnect()
        manager = nil
        socket = nil
        isConnected = false
    }

    func reconnectQueue() {
        guard let queueId = currentQueueId else { return }

        print("📤 Emitting reconnect for:", queueId)

        socket?.emit(Event.reconnectTableBookingQueue, [
            "id": queueId
        ])
    }

    private func addListeners() {

        guard let queueId = currentQueueId else { return }

        socket?.off(queueId)
        socket?.off(Event.reconnectTableBookingQueue)

        socket?.on(queueId) { [weak self] data, _ in
            self?.handleQueueUpdate(data)
        }

        socket?.on(Event.reconnectTableBookingQueue) { [weak self] data, _ in
            self?.handleQueueUpdate(data)
        }

        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self = self else { return }

            print("✅ Socket Connected")
            self.isConnected = true
            self.reconnectQueue()
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("❌ Socket Disconnected")
            self?.isConnected = false
        }
    }

    private func handleQueueUpdate(_ data: [Any]) {
        print("📩 Queue Update:", data)

        guard let booking = decodeQueueUpdate(from: data) else {
            print("Queue parsing failed")
            return
        }

        print("🔥 CALLBACK TRIGGERED:", booking.status)

        DispatchQueue.main.async {
            self.delegate?.didUpdateQueue(seatingAreaBooking: booking)
        }

        switch booking.status.lowercased() {

        case "queued":
            print("🟡 In Queue:", booking.position)

        case "payment":
            let clientSecret = booking.content?.clientSecret
            let bookingId = booking.content?.tableBooking?.id

            print("💳 Client Secret:", clientSecret ?? "")
            print("🧾 Booking ID:", bookingId ?? "")

        case "failed":
            print(" Failed:", booking.message ?? "")

        default:
            break
        }
    }

    private func decodeQueueUpdate(from data: [Any]) -> SeatingAreaBookingResponse? {
        for item in data {
            if let booking = decodeBooking(from: item) {
                return booking
            }
        }

        return nil
    }

    private func decodeBooking(from item: Any) -> SeatingAreaBookingResponse? {
        if let dict = item as? [String: Any] {
            if isQueueWrapper(dict),
               let content = dict["content"],
               let booking = decodeBooking(from: content) {
                return booking
            }

            return decode(dict, as: SeatingAreaBookingResponse.self)
        }

        if let dictArray = item as? [[String: Any]] {
            for dict in dictArray {
                if let booking = decodeBooking(from: dict) {
                    return booking
                }
            }
        }

        return nil
    }

    private func isQueueWrapper(_ dict: [String: Any]) -> Bool {
        dict["content"] != nil
            && dict["id"] == nil
            && dict["status"] == nil
            && dict["items"] == nil
    }

    private func decode<T: Decodable>(_ object: Any, as type: T.Type) -> T? {
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
}
