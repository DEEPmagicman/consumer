//
//  ProfileService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 02/06/26.
//

import UIKit

final class ProfileService {

    //MARK: - Profile
    
    func updateProfile(
        firstName: String? = nil,
        lastName: String? = nil,
        nickName: String? = nil,
        email: String? = nil,
        dob: String? = nil,
        gender: String? = nil,
        image: ImageDetail? = nil,
        city: String? = nil,
        vibeIds: [String]? = nil,
        drinkIds: [String]? = nil,
        instagramToken: String? = nil,
        spotifyToken: String? = nil,
        instagramUserId: String? = nil,
        isProfileCompleted: Bool? = nil,
        completion: @escaping (Bool, String?) -> Void
    ) {

        var params: [String: Any] = [:]

        if let firstName, !firstName.isEmpty {
            params["firstName"] = firstName
        }

        if let lastName, !lastName.isEmpty {
            params["lastName"] = lastName
        }

        if let nickName, !nickName.isEmpty {
            params["nickName"] = nickName
        }
        
        if let email, !email.isEmpty {
            params["email"] = email
        }

        if let dob,
           !dob.isEmpty,
           dob != "No date Found" {
            params["dob"] = dob
        }

        if let gender {
            params["gender"] = gender
        }

        if let image {
            params["image"] = image.toDictionary()
        }

        if let city {
            params["city"] = city
        }

        if let vibeIds {
            params["vibeIds"] = vibeIds
        }

        if let drinkIds {
            params["drinkIds"] = drinkIds
        }

        if let instagramToken {
            params["instagramToken"] = instagramToken
        }

        if let spotifyToken {
            params["spotifyToken"] = spotifyToken
        }

        if let instagramUserId {
            params["instagramUserId"] = instagramUserId
        }

        if let isProfileCompleted {
            params["isProfileCompleted"] = isProfileCompleted
        }

        AFWrapper.patchRequest(
            APIBuilder.userProfileURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard response is [String: Any] else {
                completion(false, nil)
                return
            }

            completion(true, nil)

        } failure: { error in

            if let err = error as? NSError,
               err.code == 0 {
                completion(false, err.domain)
                return
            }

            completion(false, nil)
        }
    }

    func uploadProfileImage(
        image: UIImage,
        completion: @escaping (String, Bool) -> Void
    ) {

        guard let imageData = image.jpegData(compressionQuality: 1) else {
            completion("", false)
            return
        }

        let params: [String: Any] = [
            "file": image
        ]

        AFWrapper.multipart(
            APIBuilder.uploadPhotoURL,
            fileData: imageData,
            fileName: "\(UUID().uuidString).jpg",
            fileParamKey: "file",
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let imageUrl = responseDic["Location"] as? String
            else {
                completion("", false)
                return
            }

            completion(imageUrl, true)

        } failure: { _ in
            completion("", false)
        }
    }
    
    // MARK: - Social
    
    func fetchInstagramProfile(
        instagramUserId: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errMsg: String?,
            _ profileData: InstagramProfile?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "instagramUserId": instagramUserId
        ]

        AFWrapper.postRequest(
            APIBuilder.getInstaGramProfile,
            params: params,
            headers: Header.header()
        ) { response in

            guard let responseDic =
                    response as? [String: Any]
            else {

                completion(
                    false,
                    "Invalid response",
                    nil
                )

                return
            }

            if let error =
                responseDic["error"] as? String {

                completion(
                    false,
                    error,
                    nil
                )

                return
            }

            do {

                let data = try JSONSerialization.data(
                    withJSONObject: responseDic
                )

                let profile =
                try JSONDecoder().decode(
                    InstagramProfile.self,
                    from: data
                )

                completion(
                    true,
                    nil,
                    profile
                )

            } catch {

                print(
                    "Instagram Profile Decode Error:",
                    error
                )

                completion(
                    false,
                    "Parsing failed",
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
                error?.localizedDescription,
                nil
            )
        }
    }
}
