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
        consumerUserId: String = "",
        mininumSpend: Double? = nil,
        promotionLinkId: String = "",
        promotionLinkUniqueCode: String = "",
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

        var params: [String: Any] = [
            "items": [item],
            "queueId": queueId
        ]

        let trimmedConsumerUserId =
        consumerUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedConsumerUserId.isEmpty {
            params["consumerUserId"] = trimmedConsumerUserId
        }

        if let mininumSpend {
            params["mininumSpend"] = mininumSpend
        }

        let trimmedPromotionLinkId =
        promotionLinkId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPromotionLinkId.isEmpty {
            params["promotionLinkId"] = trimmedPromotionLinkId
        }
        let trimmedPromotionLinkUniqueCode =
        promotionLinkUniqueCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPromotionLinkUniqueCode.isEmpty {
            params["promotionLinkUniqueCode"] = trimmedPromotionLinkUniqueCode
        }

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

    // MARK: - Reservation Questions

    func getReservationRequestQuestions(
        eventId: String,
        venueId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ questions: [Questions]?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "questionFor": "RESERVATION_REQUEST",
            "eventId": eventId,
            "orderBy": "order|asc",
            "include": "reservationQuestionHasOption"
        ]

        var headers = Header.header()
        if !venueId.isEmpty {
            headers["venue"] = venueId
        }

        AFWrapper.getRequest(
            APIBuilder.reservationQuestionsURL(),
            params: params,
            headers: headers
        ) { response in

            let questionObjects: [[String: Any]]?

            if let list = response as? [[String: Any]] {
                questionObjects = list
            } else if let dict = response as? [String: Any] {
                questionObjects = dict["list"] as? [[String: Any]]
            } else {
                questionObjects = nil
            }

            guard let questionObjects else {
                completion(false, nil, [])
                return
            }

            if let questions = [Questions].parse(questionObjects) {
                completion(true, nil, questions)
            } else {
                completion(false, "Internal Error", [])
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, [])
                return
            }

            completion(false, "Something went wrong", [])
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
        optedEmailPolicy: Bool = true,
        maleGuests: Int? = nil,
        femaleGuests: Int? = nil,
        answers: [Any] = [],
        completion: @escaping (
            _ success: Bool,
            _ message: String?,
            _ response: [String: Any]?
        ) -> Void
    ) {

        var guests: [String: Any] = [
            "total": totalGuests
        ]
        if let maleGuests {
            guests["male"] = maleGuests
        }
        if let femaleGuests {
            guests["female"] = femaleGuests
        }

        var params: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "guests": guests,
            "note": note ?? "",
            "dob": dob,
            "date": date,
            "time": time,
            "optedPolicy": optedPolicy,
            "optedEmailPolicy": optedEmailPolicy,
            "eventId": eventId,
            "seatingArea": seatingArea
        ]

        if !answers.isEmpty {
            params["answers"] = answers
        }

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
        eventUniqueId: String? = nil,
        completion: @escaping (
            _ success: Bool,
            _ message: String?,
            _ layout: ConsumerLayoutResponse?
        ) -> Void
    ) {

        var headers = Header.header()
        headers["venue"] = venueId

        AFWrapper.getRequest(
            APIBuilder.layoutURL(date: date, eventUniqueId: eventUniqueId),
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
                    dict["message"] as? String ?? error.localizedDescription,
                    nil
                )
            }

        } failure: { error in

            completion(
                false,
                self.apiErrorMessage(error),
                nil
            )
        }
    }

    private func apiErrorMessage(_ error: Error?) -> String? {
        guard let error else { return nil }

        let nsError = error as NSError
        let domainMessage = nsError.domain.trimmingCharacters(in: .whitespacesAndNewlines)
        if !domainMessage.isEmpty {
            return domainMessage
        }

        let localizedMessage = nsError.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return localizedMessage.isEmpty ? nil : localizedMessage
    }

    // MARK: - Remove Promo Code

    func removePromoCode(
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
            APIBuilder.seatingAreaRemoveCode(),
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
                    dict["message"] as? String ?? error.localizedDescription,
                    nil
                )
            }

        } failure: { error in

            completion(
                false,
                self.apiErrorMessage(error),
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
        promotionLinkId: String = "",
        promotionLinkUniqueCode: String = "",
        completion: @escaping (
            _ success: Bool,
            _ message: String?,
            _ response: TableBookingConfirmResponse?
        ) -> Void
    ) {

        var params: [String: Any] = [
            "queueId": queueId,
            "tableBookingId": tableBookingId,
            "guestInfo": [
                "consumerUserId": consumerUserId
            ],
            "optedPolicy": optedPolicy,
            "notes": notes ?? ""
        ]
        let trimmedPromotionLinkId =
        promotionLinkId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPromotionLinkId.isEmpty {
            params["promotionLinkId"] = trimmedPromotionLinkId
        }
        let trimmedPromotionLinkUniqueCode =
        promotionLinkUniqueCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPromotionLinkUniqueCode.isEmpty {
            params["promotionLinkUniqueCode"] = trimmedPromotionLinkUniqueCode
        }

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

    func cancelTableBookingQueue(
        eventId: String,
        queueId: String,
        tableBookingId: String,
        venueId: String?,
        completion: @escaping (
            _ success: Bool,
            _ message: String?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "queueId": queueId,
            "tableBookingId": tableBookingId
        ]

        AFWrapper.postRequest(
            APIBuilder.seatingAreaBookingCancelURL(eventId: eventId),
            params: params,
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
                error?.localizedDescription ?? "Failed to cancel booking"
            )
        }
    }

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
