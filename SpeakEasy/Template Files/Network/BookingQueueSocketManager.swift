//
//  BookingQueueSocketManager.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 17/03/26.
//

import Foundation
import SocketIO

protocol BookingQueueSocketDelegate: AnyObject {
    func didUpdateQueue(position: Int, approxWait: Int, status: String, message: String?)
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

        socket?.emit("reconnect-event-table-booking-queue", [
            "id": queueId
        ])
    }

    private func addListeners() {

        socket?.on(clientEvent: .connect) { _, _ in
            self.isConnected = true
            self.reconnectQueue()
        }

        socket?.on(clientEvent: .disconnect) { _, _ in
            self.isConnected = false
        }

        socket?.on("table-booking-queue-update") { data, _ in
            print("📩 Queue Update:", data)

            guard
                let arr = data as? [[String: Any]],
                let dict = arr.first
            else { return }

            let position = dict["position"] as? Int ?? 0
            let approxWait = dict["approxWait"] as? Int ?? 0
            let status = dict["status"] as? String ?? ""
            let message = dict["message"] as? String

            DispatchQueue.main.async {
                self.delegate?.didUpdateQueue(
                    position: position,
                    approxWait: approxWait,
                    status: status,
                    message: message
                )
            }
        }
    }
}
