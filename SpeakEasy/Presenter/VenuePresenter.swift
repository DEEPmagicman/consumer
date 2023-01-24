//
//  VenuePresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

final class VenuePresenter {
     func getVenues(completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ venueList: [Venue]) -> Void) {

        AFWrapper.getRequest(APIBuilder.venueURL, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let menu = responseDic["list"] as? [[String: Any]] else {
                completion(false, nil, [])
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: menu, options: .prettyPrinted)
                let venueList = try decoder.decode([Venue].self, from: data)
                completion(true, nil, venueList)
            } catch {
                completion(false, "internal error", [])
            }

        } failure: { (error) in
            if let err = (error as? NSError), err.code == 0 {
                completion(false, err.domain, [])
                return
            }
            completion(false, nil, [])
        }
    }
}
