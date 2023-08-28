//
//  InvitePresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/06/23.
//

import Foundation

final class InvitePresenter {
    static func getInvite(inviteId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ invite: Invite?) -> Void) {

        AFWrapper.getRequest(APIBuilder.inviteLinkURL(inviteId), headers: Header.header()) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }
            if let invite = Invite.parse(responseDic) {
                completion(true, nil, invite)
            } else {
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
    
    static func redeemInvite(inviteId: String, venueTimeZone: String? = nil, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ booking: Booking?) -> Void) {

        let param = ["firstName": UserDefault.shared.user?.firstName ?? "",
                     "lastName": UserDefault.shared.user?.lastName ?? "",
                     "phone": UserDefault.shared.user?.phone ?? "",
                     "code": UserDefault.shared.user?.code ?? "",
                     "email": UserDefault.shared.user?.useEmail ?? "",
                     "gender": UserDefault.shared.user?.gender ?? ""] as [String: Any]

        AFWrapper.postRequest(APIBuilder.inviteRedeemURL(inviteId), params: param, headers: Header.header(timeZone: venueTimeZone)) { response in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }
            if let booking = Booking.parse(responseDic) {
                completion(true, nil, booking)
            } else {
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
}
