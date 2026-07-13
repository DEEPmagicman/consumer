//
//  TablePresenter.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 17/02/26.
//

import Foundation


final class TablePresenter {
    
    static func getSeatingAreas(
        eventId: String,
        skip: Int = 0,
        completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ list: [SeatingArea], _ hasMore: Bool) -> Void
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
            
            guard let responseDic = response as? [String: Any],
                  let list = responseDic["list"] as? [[String: Any]],
                  let hasMore = responseDic["hasMany"] as? Bool else {
                completion(false, nil, [], false)
                return
            }
            
            if let seatingList = [SeatingArea].parse(list) {
                completion(true, nil, seatingList, hasMore)
            } else {
                completion(false, "internal error", [], false)
            }
            
        } failure: { error in
            
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [], false)
                return
            }
            
            completion(false, nil, [], false)
        }
    }
    
    static func createSeatingAreaBooking(
        eventId: String,
        seatingAreaId: String,
        timeSlotId: String?,
        venueId: String,
        guests: Int,
        queueId: String,
        promotionLinkId: String = "",
        promotionLinkUniqueCode: String = "",
        completion: @escaping (_ isSuccess: Bool,
                               _ errMsg: String?,
                               _ response: SeatingAreaBookingResponse?) -> Void
    ) {

        let url = APIBuilder.seatingAreasBookingCreateURL(
            eventId: eventId,
            includes: []
        )
        var item: [String: Any] = [
            "seatingAreaId": seatingAreaId,
            "guests": guests
        ]
        if let timeSlotId = timeSlotId, !timeSlotId.isEmpty {
            item["timeSlotId"] = timeSlotId
        }
        var params: [String: Any] = [
            "items": [item],
            "queueId": queueId
        ]
        let trimmedPromotionLinkId = promotionLinkId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPromotionLinkId.isEmpty {
            params["promotionLinkId"] = trimmedPromotionLinkId
        }
        let trimmedPromotionLinkUniqueCode = promotionLinkUniqueCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPromotionLinkUniqueCode.isEmpty {
            params["promotionLinkUniqueCode"] = trimmedPromotionLinkUniqueCode
        }
        AFWrapper.postRequest(
            url,
            params: params,
            headers: Header.header(venueId: venueId)
        ) { response in

            guard let dict = response as? [String: Any] else {
                completion(false, "Invalid response", nil)
                return
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: dict)
                let decoded = try JSONDecoder().decode(SeatingAreaBookingResponse.self, from: data)

                if decoded.isSuccess {
                    completion(true, nil, decoded)
                } else {
                    completion(false, decoded.message ?? "Failed", decoded)
                }

            } catch {
                completion(false, error.localizedDescription, nil)
            }

        } failure: { error in

            if let err = error as? NSError {
                completion(false, err.localizedDescription, nil)
            } else {
                completion(false, "Something went wrong", nil)
            }
        }
    }
    
    static func createReservationRequest(
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
        answers: [Any] = [],
        completion: @escaping (_ success: Bool, _ message: String?, _ response: [String: Any]?) -> Void
    ) {

        let url = APIBuilder.reservationRequestURL()

        var params: [String: Any] = [
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

        if !answers.isEmpty {
            params["answers"] = answers
        }

        var headers = Header.header()
        headers["venue"] = venueId
        headers["token"] = token

        AFWrapper.postRequest(
            url,
            params: params,
            headers: headers
        ) { response in

            guard let dict = response as? [String: Any] else {
                completion(false, "Invalid response", nil)
                return
            }

            let message = dict["message"] as? String
            let success = (dict["isSuccess"] as? Bool) ?? true

            completion(success, message, dict)

        } failure: { error in

            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil)
                return
            }

            completion(false, "Something went wrong", nil)
        }
    }

    static func getReservationRequestQuestions(
        eventId: String,
        venueId: String,
        completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ questions: [Questions]?) -> Void
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

            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [])
                return
            }

            completion(false, "Something went wrong", [])
        }
    }
    
    
    static func getConsumerLayout(
        date: String,
        venueId: String,
        completion: @escaping (_ success: Bool, _ message: String?, _ layout: ConsumerLayoutResponse?) -> Void
    ) {

        let url = APIBuilder.layoutURL(date: date)
        
        var headers = Header.header()
        headers["venue"] = venueId

        AFWrapper.getRequest(
            url,
            params: nil,
            headers: headers
        ) { response in

            guard let dict = response as? [String: Any] else {
                completion(false, "Invalid response", nil)
                return
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: dict)
                let decoded = try JSONDecoder().decode(ConsumerLayoutResponse.self, from: data)
                completion(true, nil, decoded)
            } catch {
                completion(false, error.localizedDescription, nil)
            }

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil)
                return
            }
            completion(false, "Something went wrong", nil)
        }
    }
    
    
    static func applyCode(
        eventId: String,
        tableBookingId: String,
        code: String,
        venueId: String,
        completion: @escaping (_ success: Bool,
                               _ message: String?,
                               _ data: PriceBreakdown?) -> Void
    ) {
        
        let url = APIBuilder.seatingAreaApplyCode(eventId: eventId)
        
        let params: [String: Any] = [
            "tableBookingId": tableBookingId,
            "code": code
        ]
        
        var headers = Header.header()
        headers["venue"] = venueId
        
        AFWrapper.postRequest(url, params: params, headers: headers) { response in
            
            guard let dict = response as? [String: Any] else {
                completion(false, "Invalid response", nil)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: dict)
                let decoded = try JSONDecoder().decode(PriceBreakdown.self, from: data)
                completion(true, nil, decoded)
            } catch {
                completion(false, error.localizedDescription, nil)
            }
            
        } failure: { error in
            completion(false, error?.localizedDescription, nil)
        }
    }
    
    static func removeCode(
        eventId: String,
        tableBookingId: String,
        venueId: String,
        completion: @escaping (_ success: Bool,
                               _ message: String?,
                               _ data: PriceBreakdown?) -> Void
    ) {
        
        let url = APIBuilder.seatingAreaRemoveCode(eventId: eventId)
        
        let params: [String: Any] = [
            "tableBookingId": tableBookingId
        ]
        
        var headers = Header.header()
        headers["venue"] = venueId
        
        AFWrapper.postRequest(url, params: params, headers: headers) { response in
            
            guard let dict = response as? [String: Any] else {
                completion(false, "Invalid response", nil)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: dict)
                let decoded = try JSONDecoder().decode(PriceBreakdown.self, from: data)
                completion(true, nil, decoded)
            } catch {
                completion(false, error.localizedDescription, nil)
            }
            
        } failure: { error in
            completion(false, error?.localizedDescription, nil)
        }
    }
    
    static func confirmSeatingAreaBooking(
        eventId: String,
        queueId: String,
        tableBookingId: String,
        consumerUserId: String,
        optedPolicy: Bool,
        notes: String?,
        venueId: String,
        completion: @escaping (_ success: Bool,
                               _ message: String?,
                               _ response: TableBookingConfirmResponse?) -> Void
    ) {
        
        let url = APIBuilder.seatingAreaBookingConfirmURL(eventId: eventId)
        
        let params: [String: Any] = [
            "queueId": queueId,
            "tableBookingId": tableBookingId,
            "guestInfo": [
                "consumerUserId": consumerUserId
            ],
            "optedPolicy": optedPolicy,
            "notes": notes ?? ""
        ]
        
        let headers = Header.header(venueId: venueId)
        
        AFWrapper.postRequest(
            url,
            params: params,
            headers: headers
        ) { response in
            
            guard let dict = response as? [String: Any] else {
                completion(false, "Invalid response", nil)
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: dict)
                let decoded = try JSONDecoder().decode(TableBookingConfirmResponse.self, from: data)
                completion(true, nil, decoded)
            } catch {
                completion(false, error.localizedDescription, nil)
            }
            
        } failure: { error in
            
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil)
                return
            }
            
            completion(false, error?.localizedDescription ?? "Something went wrong", nil)
        }
    }
    
}
