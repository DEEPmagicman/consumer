//
//  PremiumExperienceItem.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 15/06/26.
//

import Foundation

final class PremiumExperienceService {

    func fetchPremiumExperiences(
        skip: Int,
        take: Int = 10,
        city: String = UserDefault.shared.localCity,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ items: [PremiumExperienceItem],
            _ hasMore: Bool
        ) -> Void
    ) {
        let url = APIBuilder.eventURL(
            includes: [
                "venue.venueAttachment",
                "venue.logo",
                "flyer",
                "eventTicket",
                "eventTicketSettings"
            ]
        )

        let params: [String: Any] = [
            "skip": skip,
            "take": take,
            "version": "PUBLISHED",
            "eventStatus": "APPROVED",
            "timeVersion": "UPCOMING",
            "status": "ENABLED",
            "city": city,
            "isPremiumExperience": true,
            "orderBy": "startDateTime|asc"
        ]

        AFWrapper.getRequest(
            url,
            params: params,
            headers: Header.header()
        ) { response in
            let parsed = Self.parseResponse(response)

            guard parsed.didParse else {
                completion(false, "Invalid response", [], false)
                return
            }

            completion(true, nil, parsed.items, parsed.hasMore)

        } failure: { error in
            if let err = error as NSError?, err.code == 0 {
                completion(false, err.domain, [], false)
                return
            }

            completion(
                false,
                error?.localizedDescription ?? Constant.String.somethingWrong,
                [],
                false
            )
        }
    }

    private static func parseResponse(
        _ response: Any?
    ) -> (
        didParse: Bool,
        items: [PremiumExperienceItem],
        hasMore: Bool
    ) {
        if let dict = response as? [String: Any] {
            if let list = dict["list"] as? [[String: Any]] {
                return (
                    true,
                    list.compactMap(PremiumExperienceItem.init(dictionary:)),
                    dict["hasMany"] as? Bool ?? false
                )
            }

            if let list = dict["data"] as? [[String: Any]] {
                return (
                    true,
                    list.compactMap(PremiumExperienceItem.init(dictionary:)),
                    dict["hasMany"] as? Bool ?? dict["hasMore"] as? Bool ?? false
                )
            }
        }

        if let list = response as? [[String: Any]] {
            return (
                true,
                list.compactMap(PremiumExperienceItem.init(dictionary:)),
                false
            )
        }

        return (false, [], false)
    }
}
