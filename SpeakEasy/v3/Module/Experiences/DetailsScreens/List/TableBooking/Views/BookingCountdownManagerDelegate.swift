//
//  BookingCountdownManagerDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 25/06/26.
//

import Foundation

protocol BookingCountdownManagerDelegate: AnyObject {

    func bookingCountdownDidUpdate(_ text: String)

    func bookingCountdownDidFinish()

}

final class BookingCountdownManager {

    weak var delegate: BookingCountdownManagerDelegate?

    private var timer: Timer?

    private var remainingSeconds: Int

    init(seconds: Int = 600) {

        remainingSeconds = seconds

    }

    func start() {

        stop()

        notify()

        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(tick),
            userInfo: nil,
            repeats: true
        )

    }

    func stop() {

        timer?.invalidate()

        timer = nil

    }

    @objc
    private func tick() {

        remainingSeconds -= 1

        notify()

        if remainingSeconds <= 0 {

            stop()

            delegate?.bookingCountdownDidFinish()

        }

    }

    private func notify() {

        let min = remainingSeconds / 60

        let sec = remainingSeconds % 60

        delegate?.bookingCountdownDidUpdate(

            String(format: "%02d:%02d", min, sec)

        )

    }

}
