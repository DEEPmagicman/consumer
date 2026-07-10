//
//  OrderService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 02/06/26.
//

import Foundation

final class OrderService {

    func fetchUpcomingTickets(
        skip: Int,
        completion: @escaping (
            Bool,
            String?,
            [Booking],
            Bool
        ) -> Void
    ) {

        let params: [String: Any] = [
            "skip": skip,
            "include": [
                "bookingHasItem",
                "event.customVenue",
                "event.eventSettings",
                "event.flyer",
                "venue",
                "venue.venueSettings",
                "inviteLink.guestList"
            ],
            "orderBy": "createdAt|desc"
        ]

        AFWrapper.getRequest(
            APIBuilder.upcomingTicketsURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let list = responseDic["list"] as? [[String: Any]],
                let hasMany = responseDic["hasMany"] as? Bool
            else {
                completion(false, nil, [], false)
                return
            }

            guard let bookings = [Booking].parse(list) else {
                completion(false, "internal error", [], false)
                return
            }

            completion(true, nil, bookings, hasMany)

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, [], false)
                return
            }

            completion(false, nil, [], false)
        }
    }

    func fetchPastTickets(
        skip: Int,
        completion: @escaping (
            Bool,
            String?,
            [Booking],
            Bool
        ) -> Void
    ) {

        let params: [String: Any] = [
            "skip": skip,
            "include": [
                "bookingHasItem",
                "event.customVenue",
                "event.eventSettings",
                "event.flyer",
                "event",
                "fees",
                "venue",
                "venue.venueSettings"
            ],
            "orderBy": "createdAt|desc"
        ]

        AFWrapper.getRequest(
            APIBuilder.pastTicketsURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let list = responseDic["list"] as? [[String: Any]],
                let hasMany = responseDic["hasMany"] as? Bool
            else {
                completion(false, nil, [], false)
                return
            }

            guard let bookings = [Booking].parse(list) else {
                completion(false, "internal error", [], false)
                return
            }

            completion(true, nil, bookings, hasMany)

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, [], false)
                return
            }

            completion(false, nil, [], false)
        }
    }

    func fetchUpcomingTableReservations(
        skip: Int,
        completion: @escaping (
            Bool,
            String?,
            [Booking],
            Bool
        ) -> Void
    ) {

        let params: [String: Any] = [
            "skip": skip,
            "take": 8,
            "include": [
                "venue",
                "venue.venueSettings",
                "venue.venueAttachment",
                "event",
                "event.flyer",
                "event.venue.venueSettings",
                "seatingArrangement",
                "tableBooking",
                "tableBooking.tableBookingHasItems",
                "tableBooking.tableBookingPriceBreakdown",
                "tableBooking.spendAgreement"
            ],
            "orderBy": "createdAt|desc"
        ]

        AFWrapper.getRequest(
            APIBuilder.upcomingTableReservationsURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let list = responseDic["list"] as? [[String: Any]],
                let hasMany = responseDic["hasMany"] as? Bool
            else {
                completion(false, nil, [], false)
                return
            }

            guard let bookings = [Booking].parse(list) else {
                completion(false, "internal error", [], false)
                return
            }

            completion(true, nil, bookings, hasMany)

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, [], false)
                return
            }

            completion(false, nil, [], false)
        }
    }

    func fetchPastTableReservations(
        skip: Int,
        completion: @escaping (
            Bool,
            String?,
            [Booking],
            Bool
        ) -> Void
    ) {

        let params: [String: Any] = [
            "skip": skip,
            "take": 8,
            "include": [
                "venue",
                "venue.venueSettings",
                "venue.venueAttachment",
                "event",
                "event.flyer",
                "event.venue.venueSettings",
                "seatingArrangement",
                "tableBooking",
                "tableBooking.tableBookingHasItems",
                "tableBooking.tableBookingPriceBreakdown",
                "tableBooking.spendAgreement"
            ],
            "orderBy": "createdAt|desc"
        ]

        AFWrapper.getRequest(
            APIBuilder.pastTableReservationsURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let list = responseDic["list"] as? [[String: Any]],
                let hasMany = responseDic["hasMany"] as? Bool
            else {
                completion(false, nil, [], false)
                return
            }

            guard let bookings = [Booking].parse(list) else {
                completion(false, "internal error", [], false)
                return
            }

            completion(true, nil, bookings, hasMany)

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, [], false)
                return
            }

            completion(false, nil, [], false)
        }
    }
}
