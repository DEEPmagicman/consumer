//
//  PaymentPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 17/04/23.
//

import Foundation

enum PaymentIntentType {
    case appClip
    case singleTickedEvent
    case tieredTickedEvent
}

final class PaymentPresenter {
    static func createCoverBooking(appClipTickets: [[String: Any]], venueId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ id: String?) -> Void) {
        let param = ["appclipTicket": appClipTickets,
                     "venueId": venueId] as [String: Any]
        AFWrapper.postRequest(APIBuilder.createCoverBookingURL, params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, "")
                return
            }
            if let id = responseDic["id"] as? String {
                completion(true, nil, id)
            } else if let booking = responseDic["booking"] as? [String: Any], let id = booking["id"] as? String {
                completion(true, nil, id)
            } else if let error = responseDic["error"] as? String, let message = responseDic["message"] as? String {
                completion(false, error, message)
            } else {
                completion(false, "Alert", "Booking failed")
            }

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, "")
                return
            }
            completion(false, nil, "")
        }
    }
    
    static func createEventBooking(eventId: String, phone: String, userId: String, tickets: [[String: Any]], promoteId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ id: String?) -> Void) {
        var param = ["isAppClipUser": false,
                     "phone": phone,
                     "tickets": tickets,
                     "consumerUserId": userId,
                     "eventId": eventId] as [String: Any]
        if promoteId != "" {
            param["promotionLinkId"] = promoteId
        }
        AFWrapper.postRequest(APIBuilder.createEventBookingURL, params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, "")
                return
            }
            if let id = responseDic["id"] as? String {
                completion(true, nil, id)
            } else if let error = responseDic["error"] as? String, let message = responseDic["message"] as? String {
                completion(false, error, message)
            } else {
                completion(false, "Alert", "Booking failed")
            }

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, "")
                return
            }
            completion(false, nil, "")
        }
    }
    
    static func createCoverFreeBooking(appClipTickets: [[String: Any]], venueId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ id: String?) -> Void) {
        let param = ["appclipTicket": appClipTickets,
                     "venueId": venueId,
                     "optedPolicy": false] as [String: Any]
        AFWrapper.postRequest(APIBuilder.createCoverFreeBooing, params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, "")
                return
            }
            if let id = responseDic["id"] as? String {
                completion(true, nil, id)
            } else if let booking = responseDic["booking"] as? [String: Any], let id = booking["id"] as? String {
                completion(true, nil, id)
            } else if let error = responseDic["error"] as? String, let message = responseDic["message"] as? String {
                completion(false, error, message)
            } else {
                completion(false, "Alert", "Booking failed")
            }

        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, "")
                return
            }
            completion(false, nil, "")
        }
    }
    
    static func getBooking(bookingId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ booking: Booking?) -> Void) {
        AFWrapper.getRequest(APIBuilder.getBookingURL(bookingId), params: nil, headers: Header.header()) { response in
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: responseDic, options: .prettyPrinted)
                let booking = try JSONDecoder().decode(Booking.self, from: data)
                completion(true, nil, booking)
            } catch {
                completion(false, "internal error", nil)
            }
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, nil)
                return
            }
            completion(false, nil, nil)
        }
    }
    
    static func getPaymentIntent(bookingId: String, selectedTickets: [[String: Any]], type: PaymentIntentType, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ clientSecret: String?, _ paymentHistoryId: String, _ ephemeralKey: String, _ paymentDetail: PaymentDetail?) -> Void) {
        var param = ["cart": selectedTickets] as [String: Any]
        switch type {
        case .appClip:
            param["isAppClipPayment"] = true
        case .singleTickedEvent:
            param["isAppClipPayment"] = false
            param["isTieredTicket"] = false
        case .tieredTickedEvent:
            param["isAppClipPayment"] = false
            param["isTieredTicket"] = true
        }

        AFWrapper.postRequest(APIBuilder.addPaymentURL(bookingId), params: param, headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, "", "", "", nil)
                return
            }
            if let paymentIntentClientSecret = responseDic["clientSecret"] as? String, let paymentHistoryId = responseDic["paymentHistoryId"] as? String, let ephemeralKey = responseDic["ephemeralKey"] as? String, let paymentDetail = responseDic["payment_detail"] as? [String: Any] {
                do {
                    let data = try JSONSerialization.data(withJSONObject: paymentDetail, options: .prettyPrinted)
                    let detail = try JSONDecoder().decode(PaymentDetail.self, from: data)
                    completion(true, nil, paymentIntentClientSecret, paymentHistoryId, ephemeralKey, detail)
                } catch {
                    completion(true, nil, paymentIntentClientSecret, paymentHistoryId, ephemeralKey, nil)
                }
            } else {
                completion(false, "internal error", "", "", "", nil)
            }
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, "", "", "", nil)
                return
            }
            completion(false, nil, "", "", "", nil)
        }
    }
    
    static func getUserSavedMethods(customerId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ paymentMethods: [PaymentMethod]) -> Void) {

        AFWrapper.getRequest(APIBuilder.customerMethod(customerId), params: nil, headers: Header.header()) { response in
            guard let responseArray = response as? [[String: Any]] else {
                completion(false, nil, [])
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: responseArray, options: .prettyPrinted)
                let paymentMethods = try JSONDecoder().decode([PaymentMethod].self, from: data)
                completion(true, nil, paymentMethods)
            } catch {
                completion(false, "internal error", [])
            }
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [])
                return
            }
            completion(false, nil, [])
        }
    }
    
    static func getPastTickets(completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ bookings: [Booking]) -> Void) {
        AFWrapper.getRequest(APIBuilder.pastTicketsURL, headers: Header.header()) { response in
            
            guard let responseArray = response as? [[String: Any]] else {
                completion(false, nil, [])
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: responseArray, options: .prettyPrinted)
                let bookings = try JSONDecoder().decode([Booking].self, from: data)
                completion(true, nil, bookings)
            } catch {
                completion(false, "internal error", [])
            }
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [])
                return
            }
            completion(false, nil, [])
        }
    }
    
    static func getUpcomingTickets(completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ bookings: [Booking]) -> Void) {
        AFWrapper.getRequest(APIBuilder.upcomingTicketsURL, headers: Header.header()) { response in
            
            guard let responseArray = response as? [[String: Any]] else {
                completion(false, nil, [])
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: responseArray, options: .prettyPrinted)
                let bookings = try JSONDecoder().decode([Booking].self, from: data)
                completion(true, nil, bookings)
            } catch {
                completion(false, "internal error", [])
            }
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [])
                return
            }
            completion(false, nil, [])
        }
    }
    
    static func deleteMethod(customerId: String, methodId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        AFWrapper.deleteRequest(APIBuilder.deleteMethod(customerId, methodId: methodId), headers: Header.header()) { response in
            guard let responseArray = response as? [String: Any] else {
                completion(false, nil)
                return
            }
            completion(true, nil)
        } failure: { error in
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain)
                return
            }
            completion(false, nil)
        }
    }
    
    static func successPayment(paymentHistoryId: String, bookingId: String, optedPolicy: Bool? = nil, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        var param: [String: Any]?
        if let optedPolicy = optedPolicy {
            param = ["optedPolicy": optedPolicy]
        }
        AFWrapper.postRequest(APIBuilder.successPaymentURL(paymentHistoryId, bookingId), params: param, headers: Header.header()) { response in
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil)
                return
            }
            completion(true, nil)
        } failure: { error in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain)
                return
            }
            completion(false, nil)
        }
    }
}

extension URLSession {
    func fetchData(at url: URL, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        var request = URLRequest(url: url)
        request.addValue("Bearer \(UserDefault.shared.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        self.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(nil, error)
            }
            if let data = data {
                completion(data, nil)
            } else {
                completion(nil, error)
            }
        }.resume()
    }
}
