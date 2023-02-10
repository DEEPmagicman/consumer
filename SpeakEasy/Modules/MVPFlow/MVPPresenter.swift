//
//  MVPPresenter.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 06/02/23.
//

import Foundation

final class MVPPresenter {
    func getVenuesDetailForaMvp(venueId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ venueDetail: ClipVenue?) -> Void) {
        Loader.show()
        AFWrapper.getRequest(APIBuilder.mvpVenueDetailUrl(venueId),params: nil, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: responseDic, options: .prettyPrinted)
                let venueDetail = try decoder.decode(ClipVenue.self, from: data)
                completion(true, nil, venueDetail)
            } catch {
                completion(false, "internal error", nil)
            }

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain, nil)
                return
            }
            completion(false, nil, nil)
        }
    }
    
    func getVenueListForMvp(from: Int, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ venueList: [ClipVenue],_ hasMore: Bool) -> Void) {
        let param = ["skip": from]
        Loader.show()
        AFWrapper.getRequest(APIBuilder.mvpVenueListUrl,params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let menu = responseDic["list"] as? [[String: Any]], let hasMore = responseDic["hasMany"] as? Bool else {
                completion(false, nil, [], false)
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: menu, options: .prettyPrinted)
                let venueList = try decoder.decode([ClipVenue].self, from: data)
                completion(true, nil, venueList,hasMore)
            } catch {
                completion(false, "internal error", [],false)
            }

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain, [],false)
                return
            }
            completion(false, nil, [],false)
        }
    }
    
    func createbookingForMvp(phone: String,ticketId: String,totalTicket:Int, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?,_ id: String?) -> Void) {
        let param = ["phone": phone,
                     "appclipTicketId":ticketId,
                     "ticketQuantity": totalTicket] as [String : Any]
        Loader.show()
        AFWrapper.postRequest(APIBuilder.createBookingMvpUrl,params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil,"")
                return
            }
            if let id = responseDic["id"] as? String {
                completion(true, nil, id)
            } else if let booking = responseDic["booking"] as? [String: Any], let id = booking["id"] as? String {
                completion(true, nil, id)
            } else {
                completion(false, "Alert", "Booking failed")
            }

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain,"")
                return
            }
            completion(false, nil,"")
        }
    }
    
    func addPaymentApiForMvp(bookingId: String,name: String,price: Int,totalTicket:Int, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?,_ clientSecret: String?) -> Void) {
        let param = ["cart":
                        [
                            ["name": name,
                             "price": price,
                             "quantity": totalTicket
                            ]
                        ]
        ] as [String: Any]
        Loader.show()
        AFWrapper.postRequest(APIBuilder.addPaymentUrl(bookingId),params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil,"")
                return
            }
            do {
                let customerId = responseDic["customer"] as? String
                let customerEphemeralKeySecret = responseDic["ephemeralKey"] as? String
                let paymentIntentClientSecret = responseDic["clientSecret"] as? String
                completion(true, nil, paymentIntentClientSecret)
            } catch {
                completion(false, "internal error","")
            }

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain,"")
                return
            }
            completion(false, nil,"")
        }
    }
    
    func successPeyment(bookingId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?) -> Void) {
        AFWrapper.postRequest(APIBuilder.successPeymentUrl(bookingId),params: nil, headers: Header.header()) { (response) in
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil)
                return
            }
            do {
                completion(true, nil)
            } catch {
                completion(false, "internal error")
            }

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain)
                return
            }
            completion(false, nil)
        }
    }
}
