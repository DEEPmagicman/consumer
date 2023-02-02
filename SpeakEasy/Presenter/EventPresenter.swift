//
//  EventPresenter.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

final class EventPresenter {
    func getEvents(from: Int? = 0, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ eventList: [Event], _ hasMore: Bool) -> Void) {
        Loader.show()
        let param = ["skip": from]
        AFWrapper.getRequest(APIBuilder.eventURL,params: param, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any], let menu = responseDic["list"] as? [[String: Any]], let hasMore = responseDic["hasMany"] as? Bool else {
                completion(false, nil, [],false)
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: menu, options: .prettyPrinted)
                let eventList = try decoder.decode([Event].self, from: data)
                completion(true, nil, eventList,hasMore)
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
    
    func getEventDetail(eventId: String, completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ eventList: Event?) -> Void) {
        Loader.show()
//        let param = ["skip": from]
        AFWrapper.getRequest(APIBuilder.eventDetailURL(eventId),params: nil, headers: Header.header()) { (response) in
            
            guard let responseDic = response as? [String: Any] else {
                completion(false, nil, nil)
                return
            }
            do {
                let decoder = JSONDecoder()
                let data = try JSONSerialization.data(withJSONObject: responseDic, options: .prettyPrinted)
                let eventList = try decoder.decode(Event.self, from: data)
                completion(true, nil, eventList)
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
}
