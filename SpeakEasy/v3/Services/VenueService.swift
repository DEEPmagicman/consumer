//
//  VenueService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 02/06/26.
//

import Foundation

struct FollowedVenueRelation: Codable {
    let id: String?
    let consumerUserId: String?
    let venueId: String?
    let status: String?
    let isDeleted: Bool?
    let createdAt: String?
    let updatedAt: String?
}

final class VenueService {
    
    // MARK: - Venue List
    
    func fetchVenueList(
        skip: Int,
        status: String = "OPEN",
        city: String? = nil,
        completion: @escaping (
            Bool,
            String?,
            [ClipVenue],
            Bool
        ) -> Void
    ) {
        
        let params: [String: Any] = [
            "skip": skip,
            "take": 10,
            "include": [
                "logo",
                "venueAttachment"
            ],
            "bookingStatus": status,
            "city": city ?? UserDefault.shared.activeCity,
            "orderBy": "createdAt|desc"
        ]
        
        AFWrapper.getRequest(
            APIBuilder.venueListURL,
            params: params,
            headers: Header.header()
        ) { response in
            
            guard
                let responseDic = response as? [String: Any],
                let list = responseDic["list"] as? [[String: Any]]
            else {
                
                completion(false, nil, [], false)
                return
            }
            
            let hasMany =
            responseDic["hasMany"] as? Bool ?? false
            
            guard let venues = [ClipVenue].parse(list) else {
                
                completion(
                    false,
                    "Internal Error",
                    [],
                    false
                )
                
                return
            }
            
            completion(
                true,
                nil,
                venues,
                hasMany
            )
            
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
    
    // MARK: - Venue Detail

    func fetchCoverVenueDetail(
        uniqueId: String,
        userId: String? = UserDefault.shared.user?.id,
        venueTimeZone: String? = nil,
        doormanId: String = "",
        completion: @escaping (
            Bool,
            String?,
            ClipVenue?
        ) -> Void
    ) {

        AFWrapper.getRequest(
            APIBuilder.v3CoverVenueDetailURL(
                uniqueId: uniqueId,
                userId: userId ?? ""
            ),
            params: nil,
            headers: Header.header(
                timeZone: venueTimeZone,
                doormanId: doormanId
            )
        ) { [weak self] response in

            guard let self else { return }

            guard var responseDic =
                    response as? [String: Any]
            else {

                completion(
                    false,
                    nil,
                    nil
                )

                return
            }

            let followedFlag =
            responseDic["isVenueFollowed"] as? Bool ??
            responseDic["isvenuefollowed"] as? Bool ??
            responseDic["isFollowed"] as? Bool ??
            responseDic["isFollowing"] as? Bool ??
            responseDic["isfollowed"] as? Bool

            responseDic =
            self.normalizedVenue(
                responseDic,
                followedRelationId: self.followedVenueId(
                    from: responseDic
                ),
                forceFollowing: followedFlag
            )

            if var venue =
                ClipVenue.parse(responseDic) {

                venue.venueFollowedId =
                venue.venueFollowedId ??
                self.followedVenueId(from: responseDic)

                if venue.isFollowing == nil {
                    venue.isFollowing =
                    followedFlag
                }

                completion(
                    true,
                    nil,
                    venue
                )

            } else {

                completion(
                    false,
                    "Internal Error",
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

    func followVenue(
        uniqueId: String,
        completion: @escaping (
            Bool,
            String?,
            FollowedVenueRelation?
        ) -> Void
    ) {

        AFWrapper.postRequest(
            APIBuilder.v3FollowedVenueURL(uniqueId),
            params: nil,
            headers: Header.header()
        ) { [weak self] response in

            guard let self else { return }

            guard let relation =
                    self.decode(
                        FollowedVenueRelation.self,
                        from: response
                    )
            else {

                completion(
                    false,
                    "Internal Error",
                    nil
                )

                return
            }

            completion(
                true,
                nil,
                relation
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
                error?.localizedDescription,
                nil
            )
        }
    }

    func unfollowVenue(
        followedVenueId: String,
        completion: @escaping (
            Bool,
            String?,
            FollowedVenueRelation?
        ) -> Void
    ) {

        AFWrapper.deleteRequest(
            APIBuilder.v3FollowedVenueURL(followedVenueId),
            headers: Header.header()
        ) { [weak self] response in

            guard let self else { return }

            let relation =
            self.decode(
                FollowedVenueRelation.self,
                from: response
            )

            completion(
                true,
                nil,
                relation
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
                error?.localizedDescription,
                nil
            )
        }
    }

    func fetchFollowedVenues(
        skip: Int,
        take: Int = 10,
        search: String? = nil,
        completion: @escaping (
            Bool,
            String?,
            [ClipVenue],
            Bool
        ) -> Void
    ) {

        var params: [String: Any] = [
            "skip": skip,
            "take": take
        ]

        if let search =
            search?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
           !search.isEmpty {

            params["search"] = search
        }

        AFWrapper.getRequest(
            APIBuilder.v3FollowedVenuesURL,
            params: params,
            headers: Header.header()
        ) { [weak self] response in

            guard let self else { return }

            guard let responseDic =
                    response as? [String: Any],
                  let list =
                    responseDic["list"] as? [[String: Any]]
            else {

                completion(
                    false,
                    nil,
                    [],
                    false
                )

                return
            }

            let venues =
            list.compactMap {
                self.decode(
                    ClipVenue.self,
                    from: self.normalizedFollowedVenueItem($0)
                )
            }

            completion(
                true,
                nil,
                venues,
                responseDic["hasMany"] as? Bool ?? false
            )

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
                error?.localizedDescription,
                [],
                false
            )
        }
    }

    func fetchFollowedVenueId(
        uniqueId: String,
        search: String?,
        completion: @escaping (
            _ followedVenueId: String?
        ) -> Void
    ) {

        fetchFollowedVenues(
            skip: 0,
            take: 10,
            search: search
        ) { isSuccess, _, venues, _ in

            guard isSuccess else {
                completion(nil)
                return
            }

            let followedVenueId =
            venues.first {
                $0.uniqueId == uniqueId
            }?.venueFollowedId

            completion(followedVenueId)
        }
    }
    
    func fetchVenueDetail(
        venueId: String,
        venueTimeZone: String? = nil,
        doormanId: String = "",
        completion: @escaping (
            Bool,
            String?,
            ClipVenue?
        ) -> Void
    ) {
        
        AFWrapper.getRequest(
            APIBuilder.MVPVenueDetailURL(venueId),
            params: nil,
            headers: Header.header(
                timeZone: venueTimeZone,
                doormanId: doormanId
            )
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
            
            if let venue =
                ClipVenue.parse(responseDic) {
                
                completion(
                    true,
                    nil,
                    venue
                )
                
            } else {
                
                completion(
                    false,
                    "Internal Error",
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

    func fetchVenueTableSettings(
        venueId: String,
        venueTimeZone: String? = nil,
        completion: @escaping (
            Bool,
            String?,
            ClipVenue?
        ) -> Void
    ) {

        AFWrapper.getRequest(
            APIBuilder.venueTableSettingsURL(venueId: venueId),
            params: nil,
            headers: Header.header(timeZone: venueTimeZone)
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

            guard let venue =
                    ClipVenue.parse(responseDic) else {

                completion(
                    false,
                    "Internal Error",
                    nil
                )

                return
            }

            completion(
                true,
                nil,
                venue
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
                error?.localizedDescription,
                nil
            )
        }
    }
    
    // MARK: - Deep Link
    
    func fetchDeepLinkData(
        id: String,
        completion: @escaping (
            Bool,
            String?,
            String?,
            String?
        ) -> Void
    ) {
        AFWrapper.getRequest(
            APIBuilder.deepLinkURL(id),
            params: nil,
            headers: Header.header()
        ) { response in
            
            guard
                let responseDic = response as? [String: Any],
                let venueId = responseDic["venueId"] as? String
            else {
                
                completion(
                    false,
                    nil,
                    nil,
                    nil
                )
                
                return
            }

            let doormanId = responseDic["doormanId"] as? String
            
            completion(
                true,
                nil,
                doormanId,
                venueId
            )
            
        } failure: { error in
            
            if let err = error as NSError?,
               err.code == 0 {
                
                completion(
                    false,
                    err.domain,
                    nil,
                    nil
                )
                
                return
            }
            
            completion(
                false,
                nil,
                nil,
                nil
            )
        }
    }
    
    // MARK: - Discover Venue List
    
    func fetchVenuesForDiscover(
        skip: Int,
        bookingStatus: String,
        city: String,
        completion: @escaping (
            Bool,
            String?,
            [ClipVenue],
            Bool
        ) -> Void
    ) {
        
        let params: [String: Any] = [
            "skip": skip,
            "bookingStatus": bookingStatus,
            "city": city
        ]
        
        AFWrapper.getRequest(
            APIBuilder.MVPVenueListURL,
            params: params,
            headers: Header.header()
        ) { response in
            
            guard
                let responseDic = response as? [String: Any],
                let venueArray = responseDic["list"] as? [[String: Any]],
                let hasMany = responseDic["hasMany"] as? Bool
            else {
                
                completion(
                    false,
                    "Invalid Response",
                    [],
                    false
                )
                
                return
            }
            
            do {
                
                let data =
                try JSONSerialization.data(
                    withJSONObject: venueArray
                )
                
                let venues =
                try JSONDecoder().decode(
                    [ClipVenue].self,
                    from: data
                )
                
                completion(
                    true,
                    nil,
                    venues,
                    hasMany
                )
                
            } catch {
                
                completion(
                    false,
                    error.localizedDescription,
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
    // MARK: - Deep Link
    
    func fetchDeepLinkData(
        _ id: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ doormanId: String?,
            _ venueId: String?
        ) -> Void
    ) {
        AFWrapper.getRequest(
            APIBuilder.deepLinkURL(id),
            params: nil,
            headers: Header.header()
        ) { response in
            
            guard let responseDic = response as? [String: Any],
                  let venueId = responseDic["venueId"] as? String
            else {
                
                completion(
                    false,
                    nil,
                    nil,
                    nil
                )
                
                return
            }

            let doormanId = responseDic["doormanId"] as? String
            
            completion(
                true,
                nil,
                doormanId,
                venueId
            )
            
        } failure: { error in
            
            if let err = error as? NSError,
               err.code == 0 {
                
                completion(
                    false,
                    err.domain,
                    nil,
                    nil
                )
                
                return
            }
            
            completion(
                false,
                nil,
                nil,
                nil
            )
        }
    }
    
    // MARK: - MVP City List
    
    func fetchCityList(
        completion: @escaping (
            _ cityList: [MVPCity],
            _ isSuccess: Bool,
            _ errMsg: String?
        ) -> Void
    ) {
        
        AFWrapper.getRequest(
            APIBuilder.mvpCityListURL,
            params: nil,
            headers: Header.unauthorizedHeader()
        ) { response in
            
            guard let responseDict = response as? [String: Any],
                  let cityArray = responseDict["city"] as? [[String: Any]]
            else {
                
                completion([], false, nil)
                return
            }
            
            do {
                
                let data = try JSONSerialization.data(
                    withJSONObject: cityArray
                )
                
                let cityList = try JSONDecoder().decode(
                    [MVPCity].self,
                    from: data
                )
                
                completion(
                    cityList,
                    true,
                    nil
                )
                
            } catch {
                
                completion(
                    [],
                    false,
                    error.localizedDescription
                )
            }
            
        } failure: { _ in
            
            completion(
                [],
                false,
                nil
            )
        }
    }

    private func decode<T: Decodable>(
        _ type: T.Type,
        from object: Any?
    ) -> T? {

        guard let object,
              !(object is NSNull),
              JSONSerialization.isValidJSONObject(object)
        else {
            return nil
        }

        do {
            let data =
            try JSONSerialization.data(
                withJSONObject: object
            )

            return try JSONDecoder().decode(
                type,
                from: data
            )

        } catch {

            print("Venue parsing error:", error)
            return nil
        }
    }

    private func normalizedFollowedVenueItem(
        _ item: [String: Any]
    ) -> [String: Any] {

        let relationId =
        item["id"] as? String

        guard var venue =
                item["venue"] as? [String: Any]
        else {
            return item
        }

        return normalizedVenue(
            venue,
            followedRelationId: relationId,
            forceFollowing: true
        )
    }

    private func normalizedVenue(
        _ venue: [String: Any],
        followedRelationId: String?,
        forceFollowing: Bool?
    ) -> [String: Any] {

        var venue = venue

        venue["isDeleted"] =
        venue["isDeleted"] ?? false

        venue["dressCode"] =
        venue["dressCode"] ?? ""

        venue["website"] =
        venue["website"] ?? ""

        venue["phone"] =
        venue["phone"] ?? ""

        venue["description"] =
        venue["description"] ?? ""

        venue["bookingCode"] =
        venue["bookingCode"] ?? ""

        if let logo =
            venue["logo"] as? [String: Any] {

            venue["logo"] =
            normalizedMedia(logo)
        }

        if let attachments =
            venue["venueAttachment"] as? [[String: Any]] {

            venue["venueAttachment"] =
            attachments.map {
                normalizedMedia($0)
            }

        } else {

            venue["venueAttachment"] = []
        }

        if let followedRelationId {
            venue["followedVenueId"] =
            followedRelationId
        }

        if let forceFollowing {
            venue["isFollowing"] =
            forceFollowing
        }

        return venue
    }

    private func normalizedMedia(
        _ media: [String: Any]
    ) -> [String: Any] {

        var media = media
        let key =
        media["key"] as? String ?? ""

        media["key"] =
        key

        media["name"] =
        media["name"] ?? key

        media["description"] =
        media["description"] ?? ""

        return media
    }

    private func followedVenueId(
        from venue: [String: Any]
    ) -> String? {

        if let id =
            venue["followedVenueId"] as? String {

            return id
        }

        if let followedVenue =
            venue["followedVenue"] as? [String: Any],
           let id =
            followedVenue["id"] as? String {

            return id
        }

        if let followedVenue =
            venue["followed"] as? [String: Any],
           let id =
            followedVenue["id"] as? String {

            return id
        }

        return nil
    }
}
