//
//  UserProfileUpdatePayload.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//

import Foundation

struct UserProfileUpdatePayload {

    let firstName: String?
    let lastName: String?
    let imageUrl: String?
}

final class ProfileUpdateNotifier {

    static func post(
        firstName: String? = nil,
        lastName: String? = nil,
        imageUrl: String? = nil
    ) {

        let payload = UserProfileUpdatePayload(
            firstName: firstName,
            lastName: lastName,
            imageUrl: imageUrl
        )

        NotificationCenter.default.post(
            name: .userProfileDidUpdate,
            object: payload
        )
    }
}
