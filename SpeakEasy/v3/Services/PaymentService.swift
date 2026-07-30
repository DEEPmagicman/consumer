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
        doormanId: String = "",
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
            headers: Header.header(doormanId: doormanId)
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
            
            let clientSecret =
                responseDic["clientSecret"] as? String
            
            guard
                let isFreeTicket =
                    responseDic["isFreeTicket"] as? Bool,
                
                let paymentHistoryId =
                    responseDic["paymentHistoryId"] as? String,

                let ephemeralKey =
                    responseDic["ephemeralKey"] as? String
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
        optedEmailPolicy: Bool? = nil,
        doormanId: String = "",
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?
        ) -> Void
    ) {

        var params: [String: Any]?

        if optedPolicy != nil || optedEmailPolicy != nil {
            params = [:]
            if let optedPolicy {
                params?["optedPolicy"] = optedPolicy
            }
            if let optedEmailPolicy {
                params?["optedEmailPolicy"] = optedEmailPolicy
            }
        }

        AFWrapper.postRequest(
            APIBuilder.successPaymentURL(
                paymentHistoryId,
                bookingId
            ),
            params: params,
            headers: Header.header(doormanId: doormanId)
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

    func confirmAddOnsPaymentSuccess(
        bookingId: String,
        mainBookingId: String,
        doormanId: String = "",
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?
        ) -> Void
    ) {

        var params = [
            "bookingId": bookingId
        ]

        if !mainBookingId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["mainBookingId"] = mainBookingId
        }

        AFWrapper.postRequest(
            APIBuilder.successAddOnsPaymentURL(bookingId),
            params: params,
            headers: Header.header(doormanId: doormanId)
        ) { _ in

            completion(true, nil)

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {

                completion(false, err.domain)
                return
            }

            completion(false, nil)
        }
    }

    func confirmStripePaymentIntent(
        clientSecret: String,
        paymentMethodId: String,
        publishableKey: String?,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ status: String?
        ) -> Void
    ) {

        let intentId =
            clientSecret
            .components(separatedBy: "_secret_")
            .first ?? ""

        guard !intentId.isEmpty,
              let url = URL(
                string: "https://api.stripe.com/v1/payment_intents/\(intentId)/confirm"
              )
        else {
            completion(false, "Invalid payment intent.", nil)
            return
        }

        let bodyString = [
            "payment_method=\(paymentMethodId)",
            "client_secret=\(clientSecret)"
        ].joined(separator: "&")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "Bearer \(publishableKey ?? "")",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(false, error.localizedDescription, nil)
                return
            }

            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                completion(false, "Payment failed. Please try again.", nil)
                return
            }

            if let errorObj = json["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                completion(false, message, nil)
                return
            }

            completion(true, nil, json["status"] as? String ?? "")
        }.resume()
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
        optedPolicy: Bool? = nil,
        optedEmailPolicy: Bool? = nil,
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

        if let optedPolicy {
            params["optedPolicy"] = optedPolicy
        }

        if let optedEmailPolicy {
            params["optedEmailPolicy"] = optedEmailPolicy
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

    func createCoverBooking(
        coverTickets: [[String: Any]],
        venueId: String,
        doormanId: String = "",
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ bookingId: String?,
            _ message: String?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "coverTicket": coverTickets,
            "venueId": venueId
        ]

        AFWrapper.postRequest(
            APIBuilder.createCoverBookingURL,
            params: params,
            headers: Header.header(doormanId: doormanId)
        ) { response in

            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, "", "")
                return
            }

            if let id = responseDic["id"] as? String {
                completion(true, nil, id, "")
            } else if let booking = responseDic["booking"] as? [String: Any],
                      let id = booking["id"] as? String {
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

    func createCoverFreeBooking(
        coverTickets: [[String: Any]],
        venueId: String,
        optedPolicy: Bool? = nil,
        optedEmailPolicy: Bool? = nil,
        doormanId: String = "",
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ bookingId: String?,
            _ message: String?
        ) -> Void
    ) {

        var params: [String: Any] = [
            "coverTicket": coverTickets,
            "venueId": venueId,
            "optedPolicy": optedPolicy ?? false
        ]

        if let optedEmailPolicy {
            params["optedEmailPolicy"] = optedEmailPolicy
        }

        AFWrapper.postRequest(
            APIBuilder.createCoverFreeBooing,
            params: params,
            headers: Header.header(doormanId: doormanId)
        ) { response in

            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, "", "")
                return
            }

            if let id = responseDic["id"] as? String {
                completion(true, nil, id, "")
            } else if let booking = responseDic["booking"] as? [String: Any],
                      let id = booking["id"] as? String {
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

    func createAddOnsPaymentIntent(
        bookingId: String?,
        venueId: String,
        addOnsItems: [[String: Any]],
        doormanId: String = "",
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ clientSecret: String?,
            _ ephemeralKey: String,
            _ paymentDetail: PaymentDetail?,
            _ bookingId: String
        ) -> Void
    ) {

        var params: [String: Any] = [
            "addOnsItems": addOnsItems,
            "venueId": venueId
        ]

        params["phone"] = UserDefault.shared.user?.phone
        params["code"] = UserDefault.shared.user?.code

        if let bookingId,
           !bookingId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["bookingId"] = bookingId
        }

        AFWrapper.postRequest(
            APIBuilder.addOnsPaymentIntent,
            params: params,
            headers: Header.header(doormanId: doormanId)
        ) { response in

            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, "", "", nil, "")
                return
            }

            guard let clientSecret = responseDic["clientSecret"] as? String,
                  let ephemeralKey = responseDic["ephemeralKey"] as? String,
                  let responseBookingId = responseDic["bookingId"] as? String
            else {
                completion(false, "internal error", "", "", nil, "")
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
                ephemeralKey,
                paymentDetail,
                responseBookingId
            )

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {
                completion(false, err.domain, "", "", nil, "")
                return
            }

            completion(false, nil, "", "", nil, "")
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

    func fetchAddOnsBooking(
        addOnsBookingId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ booking: AddOnsBooking?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "include": [
                "addOnsBookingHasItem.addOns",
                "venue.venueAttachment",
                "venue.venueSettings",
                "addOnsBookingHasCheckIn.addOnsBookingItemCheckIn"
            ]
        ]

        AFWrapper.getRequest(
            APIBuilder.addOnBookingAPI(addOnsBookingId),
            params: params,
            headers: Header.header()
        ) { response in

            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }

            if let booking = AddOnsBooking.parse(responseDic) {
                completion(true, nil, booking)
            } else {
                completion(false, "internal error", nil)
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {
                completion(false, err.domain, nil)
                return
            }

            completion(false, nil, nil)
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

    func fetchUserSavedMethods(
        customerId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ paymentMethods: [PaymentMethod]
        ) -> Void
    ) {

        AFWrapper.getRequest(
            APIBuilder.customerMethod(customerId),
            params: nil,
            headers: Header.header()
        ) { response in

            if let responseArray = response as? [[String: Any]] {
                if let paymentMethods = [PaymentMethod].parse(responseArray) {
                    completion(true, nil, paymentMethods)
                } else {
                    completion(false, "Internal error", [])
                }
            } else {
                completion(true, nil, [])
            }

        } failure: { error in

            if let err = error as NSError?,
               err.code == 0 {
                completion(false, err.domain, [])
                return
            }

            completion(false, nil, [])
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
