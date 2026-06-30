//
//  TableService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 02/06/26.
//

import Foundation

final class TableService {

    // MARK: - Seating Areas

    func fetchSeatingAreas(
        eventId: String,
        skip: Int = 0,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ list: [SeatingArea],
            _ hasMore: Bool
        ) -> Void
    ) {

        let url = APIBuilder.seatingAreasURL(
            eventId: eventId,
            includes: ["timeSlots"],
            take: 50,
            skip: skip,
            page: 1,
            orderBy: "order|asc"
        )

        AFWrapper.getRequest(
            url,
            params: nil,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let list = responseDic["list"] as? [[String: Any]],
                let hasMore = responseDic["hasMany"] as? Bool
            else {

                completion(false, nil, [], false)
                return
            }

            if let seatingAreas = [SeatingArea].parse(list) {

                completion(
                    true,
                    nil,
                    seatingAreas,
                    hasMore
                )

            } else {

                completion(
                    false,
                    "internal error",
                    [],
                    false
                )
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    [],
                    false
                )

                return
            }

            completion(
                false,
                nil,
                [],
                false
            )
        }
    }

    // MARK: - Create Seating Area Booking

    func createSeatingAreaBooking(
        eventId: String,
        seatingAreaId: String,
        timeSlotId: String?,
        venueId: String,
        guests: Int,
        queueId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ response: SeatingAreaBookingResponse?
        ) -> Void
    ) {

        let url = APIBuilder.seatingAreasBookingCreateURL(
            eventId: eventId,
            includes: []
        )

        var item: [String: Any] = [
            "seatingAreaId": seatingAreaId,
            "guests": guests
        ]

        if let timeSlotId,
           !timeSlotId.isEmpty {

            item["timeSlotId"] = timeSlotId
        }

        let params: [String: Any] = [
            "items": [item],
            "queueId": queueId
        ]

        AFWrapper.postRequest(
            url,
            params: params,
            headers: Header.header(venueId: venueId)
        ) { response in

            guard let dict = response as? [String: Any] else {

                completion(
                    false,
                    "Invalid response",
                    nil
                )

                return
            }

            do {

                let data = try JSONSerialization.data(
                    withJSONObject: dict
                )

                let decoded = try JSONDecoder().decode(
                    SeatingAreaBookingResponse.self,
                    from: data
                )

                if decoded.isSuccess {

                    completion(
                        true,
                        nil,
                        decoded
                    )

                } else {

                    completion(
                        false,
                        decoded.message ?? "Failed",
                        decoded
                    )
                }

            } catch {

                completion(
                    false,
                    error.localizedDescription,
                    nil
                )
            }

        } failure: { error in

            if let err = error as NSError? {

                completion(
                    false,
                    err.localizedDescription,
                    nil
                )

            } else {

                completion(
                    false,
                    "Something went wrong",
                    nil
                )
            }
        }
    }

    // MARK: - Reservation Request

    func createReservationRequest(
        firstName: String,
        lastName: String,
        email: String,
        totalGuests: Int,
        note: String?,
        dob: String,
        date: String,
        time: String,
        optedPolicy: Bool,
        eventId: String,
        seatingArea: String?,
        venueId: String,
        token: String,
        completion: @escaping (
            _ success: Bool,
            _ message: String?,
            _ response: [String: Any]?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "guests": [
                "total": totalGuests
            ],
            "note": note ?? "",
            "dob": dob,
            "date": date,
            "time": time,
            "optedPolicy": optedPolicy,
            "eventId": eventId,
            "seatingArea": seatingArea
        ]

        var headers = Header.header()
        headers["venue"] = venueId
        headers["token"] = token

        AFWrapper.postRequest(
            APIBuilder.reservationRequestURL(),
            params: params,
            headers: headers
        ) { response in

            guard let dict = response as? [String: Any] else {

                completion(
                    false,
                    "Invalid response",
                    nil
                )

                return
            }

            completion(
                (dict["isSuccess"] as? Bool) ?? true,
                dict["message"] as? String,
                dict
            )

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    nil
                )

                return
            }

            completion(
                false,
                "Something went wrong",
                nil
            )
        }
    }

    // MARK: - Consumer Layout

    func fetchConsumerLayout(
        date: String,
        venueId: String,
        completion: @escaping (
            _ success: Bool,
            _ message: String?,
            _ layout: ConsumerLayoutResponse?
        ) -> Void
    ) {

        var headers = Header.header()
        headers["venue"] = venueId

        AFWrapper.getRequest(
            APIBuilder.layoutURL(date: date),
            params: nil,
            headers: headers
        ) { response in

            guard let dict = response as? [String: Any] else {

                completion(
                    false,
                    "Invalid response",
                    nil
                )

                return
            }

            do {

                let data = try JSONSerialization.data(
                    withJSONObject: dict
                )

                let decoded = try JSONDecoder().decode(
                    ConsumerLayoutResponse.self,
                    from: data
                )

                completion(
                    true,
                    nil,
                    decoded
                )

            } catch {

                completion(
                    false,
                    error.localizedDescription,
                    nil
                )
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    nil
                )

                return
            }

            completion(
                false,
                "Something went wrong",
                nil
            )
        }
    }

    // MARK: - Apply Promo Code

    func applyPromoCode(
        eventId: String,
        tableBookingId: String,
        code: String,
        venueId: String,
        completion: @escaping (
            _ success: Bool,
            _ message: String?,
            _ data: PriceBreakdown?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "tableBookingId": tableBookingId,
            "code": code
        ]

        var headers = Header.header()
        headers["venue"] = venueId

        AFWrapper.postRequest(
            APIBuilder.seatingAreaApplyCode(eventId: eventId),
            params: params,
            headers: headers
        ) { response in

            guard let dict = response as? [String: Any] else {

                completion(
                    false,
                    "Invalid response",
                    nil
                )

                return
            }

            do {

                let data = try JSONSerialization.data(
                    withJSONObject: dict
                )

                let decoded = try JSONDecoder().decode(
                    PriceBreakdown.self,
                    from: data
                )

                completion(
                    true,
                    nil,
                    decoded
                )

            } catch {

                completion(
                    false,
                    error.localizedDescription,
                    nil
                )
            }

        } failure: { error in

            completion(
                false,
                error?.localizedDescription,
                nil
            )
        }
    }

    // MARK: - Remove Promo Code

    func removePromoCode(
        eventId: String,
        tableBookingId: String,
        venueId: String,
        completion: @escaping (
            _ success: Bool,
            _ message: String?,
            _ data: PriceBreakdown?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "tableBookingId": tableBookingId
        ]

        var headers = Header.header()
        headers["venue"] = venueId

        AFWrapper.postRequest(
            APIBuilder.seatingAreaRemoveCode(eventId: eventId),
            params: params,
            headers: headers
        ) { response in

            guard let dict = response as? [String: Any] else {

                completion(
                    false,
                    "Invalid response",
                    nil
                )

                return
            }

            do {

                let data = try JSONSerialization.data(
                    withJSONObject: dict
                )

                let decoded = try JSONDecoder().decode(
                    PriceBreakdown.self,
                    from: data
                )

                completion(
                    true,
                    nil,
                    decoded
                )

            } catch {

                completion(
                    false,
                    error.localizedDescription,
                    nil
                )
            }

        } failure: { error in

            completion(
                false,
                error?.localizedDescription,
                nil
            )
        }
    }

    // MARK: - Confirm Table Booking

    func confirmTableBooking(
        eventId: String,
        queueId: String,
        tableBookingId: String,
        consumerUserId: String,
        optedPolicy: Bool,
        notes: String?,
        venueId: String,
        completion: @escaping (
            _ success: Bool,
            _ message: String?,
            _ response: TableBookingConfirmResponse?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "queueId": queueId,
            "tableBookingId": tableBookingId,
            "guestInfo": [
                "consumerUserId": consumerUserId
            ],
            "optedPolicy": optedPolicy,
            "notes": notes ?? ""
        ]

        AFWrapper.postRequest(
            APIBuilder.seatingAreaBookingConfirmURL(eventId: eventId),
            params: params,
            headers: Header.header(venueId: venueId)
        ) { response in

            guard let dict = response as? [String: Any] else {

                completion(
                    false,
                    "Invalid response",
                    nil
                )

                return
            }

            do {

                let data = try JSONSerialization.data(
                    withJSONObject: dict
                )

                let decoded: TableBookingConfirmResponse
                if let response = try? JSONDecoder().decode(
                    TableBookingConfirmResponse.self,
                    from: data
                ) {
                    decoded = response
                } else {
                    let reservation = try JSONDecoder().decode(
                        Reservation.self,
                        from: data
                    )
                    decoded = TableBookingConfirmResponse(
                        reservations: [reservation],
                        tableBooking: reservation.tableBooking
                    )
                }

                completion(
                    true,
                    nil,
                    decoded
                )

            } catch {

                completion(
                    false,
                    error.localizedDescription,
                    nil
                )
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    nil
                )

                return
            }

            completion(
                false,
                error?.localizedDescription ?? "Something went wrong",
                nil
            )
        }
    }

    // MARK: - Cancel Table Booking

    func cancelTableBooking(
        bookingId: String,
        venueId: String?,
        completion: @escaping (
            _ success: Bool,
            _ message: String?
        ) -> Void
    ) {

        AFWrapper.putRequest(
            APIBuilder.cancelTableBooking(bookingId),
            headers: Header.header(venueId: venueId ?? "")
        ) { _ in

            completion(
                true,
                nil
            )

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain
                )

                return
            }

            completion(
                false,
                error?.localizedDescription ?? "Something went wrong"
            )
        }
    }

    // MARK: - Consumer Reservation Details

    func fetchConsumerReservation(
        uniqueId: String,
        completion: @escaping (
            _ success: Bool,
            _ message: String?,
            _ reservation: Reservation?
        ) -> Void
    ) {

        AFWrapper.postRequest(
            APIBuilder.consumerReservationURL(uniqueId),
            params: nil,
            headers: Header.header()
        ) { response in

            guard let dict = response as? [String: Any] else {

                completion(
                    false,
                    "Invalid response",
                    nil
                )

                return
            }

            do {

                let data = try JSONSerialization.data(
                    withJSONObject: dict
                )

                let decoded = try JSONDecoder().decode(
                    Reservation.self,
                    from: data
                )

                completion(
                    true,
                    nil,
                    decoded
                )

            } catch {

                completion(
                    false,
                    error.localizedDescription,
                    nil
                )
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    nil
                )

                return
            }

            completion(
                false,
                error?.localizedDescription ?? "Something went wrong",
                nil
            )
        }
    }
}
