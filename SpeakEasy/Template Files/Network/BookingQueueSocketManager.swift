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

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    weak var delegate: BookingQueueSocketDelegate?

    private let socketURL = URL(string: "https://table-preprod.speakeasygo.com")!

    private(set) var isConnected = false
    private var currentQueueId: String?

    func connect(queueId: String) {

        currentQueueId = queueId

        manager = SocketManager(
            socketURL: socketURL,
            config: [.log(true), .compress, .forceWebsockets(true)]
        )

        socket = manager?.defaultSocket

        addListeners()
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
        isConnected = false
    }

    func reconnectQueue() {
        guard let queueId = currentQueueId else { return }

        print("📤 Emitting reconnect for:", queueId)

        socket?.emit("reconnect-event-table-booking-queue", [
            "id": queueId
        ])
    }

    private func addListeners() {

        guard let queueId = currentQueueId else { return }

        socket?.off(queueId)

        socket?.on(queueId) { [weak self] data, _ in
            guard let self = self else { return }

            print("📩 Queue Update:", data)

            guard
                let arr = data as? [[String: Any]],
                let first = arr.first
            else { return }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: first)
                let decoded = try JSONDecoder().decode(QueueSocketResponse.self, from: jsonData)

                let content = decoded.content

                print("🔥 CALLBACK TRIGGERED:", content.status)

                DispatchQueue.main.async {
                    self.delegate?.didUpdateQueue(seatingAreaBooking: content)
                }

                switch content.status {

                case "queued":
                    print("🟡 In Queue:", content.position)

                case "payment":
                    let clientSecret = content.content?.clientSecret
                    let bookingId = content.content?.tableBooking?.id

                    print("💳 Client Secret:", clientSecret ?? "")
                    print("🧾 Booking ID:", bookingId ?? "")

                case "failed":
                    print(" Failed:", content.message ?? "")

                default:
                    break
                }

            } catch {
                print("Parsing error:", error)
            }
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
}
