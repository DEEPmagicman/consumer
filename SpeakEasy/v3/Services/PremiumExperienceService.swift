//
//  PremiumExperienceItem.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 15/06/26.
//

import Foundation

final class PremiumExperienceService {

    private struct ParsedResponse {
        let didParse: Bool
        let items: [PremiumExperienceItem]
        let hasMore: Bool
    }

    func fetchPremiumExperiences(
        skip: Int,
        take: Int = 10,
        city: String = UserDefault.shared.activeCity,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ items: [PremiumExperienceItem],
            _ hasMore: Bool
        ) -> Void
    ) {
        let params: [String: Any] = [
            "skip": skip,
            "take": take,
            "city": city,
            "eventListType": DiscoverEventListType.eventsInCity.rawValue,
            "isPremiumOnly": "true"
        ]

        AFWrapper.getRequest(
            APIBuilder.discoverEventsURL,
            params: params,
            headers: Header.header(timeZone: TimeZone.current.identifier)
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
    ) -> ParsedResponse {
        if let dict = response as? [String: Any] {
            if let list = dict["list"] as? [[String: Any]] {
                return ParsedResponse(
                    didParse: true,
                    items: list.compactMap(PremiumExperienceItem.init(dictionary:)),
                    hasMore: dict["hasMany"] as? Bool ?? false
                )
            }

            if let list = dict["data"] as? [[String: Any]] {
                return ParsedResponse(
                    didParse: true,
                    items: list.compactMap(PremiumExperienceItem.init(dictionary:)),
                    hasMore: dict["hasMany"] as? Bool ?? dict["hasMore"] as? Bool ?? false
                )
            }

            if let page = pageDictionary(from: dict),
               let list = page["list"] as? [[String: Any]] {
                return ParsedResponse(
                    didParse: true,
                    items: list.compactMap(PremiumExperienceItem.init(dictionary:)),
                    hasMore: page["hasMany"] as? Bool ?? page["hasMore"] as? Bool ?? false
                )
            }
        }

        if let list = response as? [[String: Any]] {
            return ParsedResponse(
                didParse: true,
                items: list.compactMap(PremiumExperienceItem.init(dictionary:)),
                hasMore: false
            )
        }

        return ParsedResponse(didParse: false, items: [], hasMore: false)
    }

    private static func pageDictionary(
        from response: [String: Any]
    ) -> [String: Any]? {
        for key in ["data", "result", "response"] {
            if let page = response[key] as? [String: Any],
               page["list"] is [[String: Any]] {
                return page
            }
        }

        return nil
    }
}
