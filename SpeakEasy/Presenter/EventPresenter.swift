//
//  EventPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

final class EventPresenter {
    static func getEvents(completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ eventList: [Event]) -> Void) {

        AFWrapper.getRequest(APIBuilder.eventURL, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let menu = responseDic["list"] as? [[String: Any]] else {
                completion(false, nil, [])
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: menu, options: .prettyPrinted)
                let eventList = try decoder.decode([Event].self, from: data)
                completion(true, nil, eventList)
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
