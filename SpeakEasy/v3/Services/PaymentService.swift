//
//  PaymentService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 02/06/26.
//

import Foundation

final class PaymentService {

    // MARK: - Payment

    func createPaymentIntent(
        bookingId: String,
        selectedTickets: [[String: Any]],
        promoCode: String? = "",
        type: PaymentIntentType,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ clientSecret: String?,
            _ paymentHistoryId: String,
            _ ephemeralKey: String,
            _ paymentDetail: PaymentDetail?,
            _ isFreeTicket: Bool
        ) -> Void
    ) {

        var params: [String: Any] = [
            "cart": selectedTickets
        ]

        switch type {

        case .appClip:

            params["isAppClipPayment"] = true

        case .singleTickedEvent:

            params["isAppClipPayment"] = false

            if promoCode?.isEmpty == false {
                params["promoCode"] = promoCode
            }
        }

        let url =
        type == .singleTickedEvent
        ? APIBuilder.addEventPaymentURL(bookingId)
        : APIBuilder.addPaymentURL(bookingId)

        AFWrapper.postRequest(
            url,
            params: params,
            headers: Header.header()
        ) { response in

            guard let responseDic =
                    response as? [String: Any]
            else {

                completion(
                    false,
                    nil,
                    "",
                    "",
                    "",
                    nil,
                    false
                )

                return
            }

            guard
                let clientSecret =
                    responseDic["clientSecret"] as? String,

                let paymentHistoryId =
                    responseDic["paymentHistoryId"] as? String,

                let ephemeralKey =
                    responseDic["ephemeralKey"] as? String,

                let isFreeTicket =
                    responseDic["isFreeTicket"] as? Bool
            else {

                completion(
                    false,
                    "internal error",
                    "",
                    "",
                    "",
                    nil,
                    false
                )

                return
            }

            let paymentDetail =
                (responseDic["payment_detail"] as? [String: Any])
                .flatMap {
                    PaymentDetail.parse($0)
                }

            completion(
                true,
                nil,
                clientSecret,
                paymentHistoryId,
                ephemeralKey,
                paymentDetail,
                isFreeTicket
            )

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    "",
                    "",
                    "",
                    nil,
                    false
                )

                return
            }

            completion(
                false,
                nil,
                "",
                "",
                "",
                nil,
                false
            )
        }
    }
        
    func confirmPaymentSuccess(
        paymentHistoryId: String,
        bookingId: String,
        optedPolicy: Bool? = nil,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?
        ) -> Void
    ) {

        var params: [String: Any]?

        if let optedPolicy {
            params = [
                "optedPolicy": optedPolicy
            ]
        }

        AFWrapper.postRequest(
            APIBuilder.successPaymentURL(
                paymentHistoryId,
                bookingId
            ),
            params: params,
            headers: Header.header()
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
                nil
            )
        }
    }

    // MARK: - Booking

    func checkEventTicketStock(
        eventId: String,
        code: String,
        phone: String,
        gender: String,
        userId: String,
        tickets: [[String: Any]],
        completion: @escaping (
            _ isAvailable: Bool,
            _ errMsg: String?
        ) -> Void
    ) {

        let stockTickets = tickets.map {
            [
                "ticketId": $0["ticketId"] ?? "",
                "ticketQuantity": $0["ticketQuantity"] ?? 0
            ] as [String: Any]
        }

        let params: [String: Any] = [
            "code": code,
            "phone": phone,
            "gender": gender,
            "eventId": eventId,
            "consumerUserId": userId,
            "isAppClipUser": false,
            "tickets": stockTickets
        ]

        AFWrapper.postRequest(
            APIBuilder.checkEventTicketStockURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard let isAvailable = response as? Bool else {
                completion(false, "internal error")
                return
            }

            completion(isAvailable, isAvailable ? nil : Constant.String.somethingWrong)

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain)
                return
            }

            completion(false, nil)
        }
    }

    func createEventFreeBooking(
        eventId: String,
        phone: String,
        userId: String,
        tickets: [[String: Any]],
        bookingId: String? = "",
        promotionLinkId: String = "",
        promotionLinkUniqueCode: String = "",
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ bookingId: String?,
            _ message: String?
        ) -> Void
    ) {

        var params: [String: Any] = [
            "isAppClipUser": false,
            "phone": phone,
            "tickets": tickets,
            "consumerUserId": userId,
            "eventId": eventId
        ]

        if let bookingId,
           !bookingId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

            params["bookingId"] = bookingId
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
            APIBuilder.freeEventTicketURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, "", "")
                return
            }

            if let id = responseDic["id"] as? String {
                completion(true, nil, id, "")
            } else if let error = responseDic["error"] as? String,
                      let message = responseDic["message"] as? String {

                completion(false, error, "", message)
            } else {
                completion(false, "Alert", "", "Booking failed")
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain, "", "")
                return
            }

            completion(false, nil, "", "")
        }
    }
    
    func createEventBooking(
        eventId: String,
        code: String,
        phone: String,
        gender: String,
        userId: String,
        tickets: [[String: Any]],
        promotionLinkId: String = "",
        promotionLinkUniqueCode: String = "",
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ bookingId: String?,
            _ message: String?
        ) -> Void
    ) {

        var params: [String: Any] = [
            "code": code,
            "phone": phone,
            "gender": gender,
            "eventId": eventId,
            "consumerUserId": userId,
            "isAppClipUser": false,
            "tickets": tickets
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
            APIBuilder.createEventBookingURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard let responseDic =
                    response as? [String: Any]
            else {

                completion(
                    false,
                    nil,
                    "",
                    ""
                )

                return
            }

            if let bookingId =
                responseDic["id"] as? String {

                completion(
                    true,
                    nil,
                    bookingId,
                    ""
                )

            } else if let error =
                        responseDic["error"] as? String,
                      let message =
                        responseDic["message"] as? String {

                completion(
                    false,
                    error,
                    "",
                    message
                )

            } else {

                completion(
                    false,
                    "Alert",
                    "",
                    "Booking failed"
                )
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    "",
                    ""
                )

                return
            }

            completion(
                false,
                nil,
                "",
                ""
            )
        }
    }
    
    func fetchBookingDetail(
        bookingId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ booking: Booking?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "include": [
                "inviteLink.guestList",
                "bookingHasItem",
                "venue.venueAttachment",
                "event.customVenue",
                "event.eventSettings",
                "fees",
                "event.flyer",
                "venue.venueSettings",
                "bookingHasCheckIn.bookingItemCheckIn",
                "venue.logo",
                "bookingDetails"
            ]
        ]

        AFWrapper.getRequest(
            APIBuilder.getBookingURL(bookingId),
            params: params,
            headers: Header.header()
        ) { response in

            guard let responseDic =
                    response as? [String: Any]
            else {

                completion(
                    false,
                    nil,
                    nil
                )

                return
            }

            if let booking =
                Booking.parse(responseDic) {

                completion(
                    true,
                    nil,
                    booking
                )

            } else {

                completion(
                    false,
                    "internal error",
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
                nil,
                nil
            )
        }
    }
    
    func cancelBooking(
        bookingId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?
        ) -> Void
    ) {

        AFWrapper.putRequest(
            APIBuilder.cancelBooking(bookingId),
            headers: Header.header()
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
                nil
            )
        }
    }
    
    // MARK: - Event Questions
    
    func fetchEventBookingQuestions(
        eventUniqueId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ questions: [Questions]?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "take": 50,
            "orderBy": "order|asc",
            "include": "eventQuestionHasOption"
        ]

        AFWrapper.getRequest(
            APIBuilder.getEventQuestion(eventUniqueId),
            params: params,
            headers: Header.header()
        ) { response in

            guard let responseDic = response as? [String: Any],
                  let questions = responseDic["list"] as? [[String: Any]]
            else {

                completion(
                    false,
                    nil,
                    []
                )

                return
            }

            if let data = [Questions].parse(questions) {

                completion(
                    true,
                    nil,
                    data
                )

            } else {

                completion(
                    false,
                    "Internal Error",
                    []
                )
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(
                    false,
                    err.domain,
                    []
                )

                return
            }

            completion(
                false,
                nil,
                []
            )
        }
    }
        
    func submitEventBookingAnswers(
        eventUniqueId: String,
        answers: [Any],
        bookingId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "answers": answers,
            "bookingId": bookingId
        ]

        AFWrapper.postRequest(
            APIBuilder.postEventQueAns(eventUniqueId),
            params: params,
            headers: Header.header()
        ) { response in

            guard let responseBool = response as? Bool else {

                completion(
                    false,
                    nil
                )

                return
            }

            completion(
                responseBool,
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
                nil
            )
        }
    }
}
