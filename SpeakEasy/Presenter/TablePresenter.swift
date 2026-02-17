//
//  TablePresenter.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 17/02/26.
//

import Foundation


final class TablePresenter {
    
    static func getSeatingAreas(
        eventId: String,
        skip: Int = 0,
        completion: @escaping (_ isSuccess: Bool, _ errMsg: String?, _ list: [SeatingArea], _ hasMore: Bool) -> Void
    ) {
        
        let url = APIBuilder.seatingAreasURL(
            eventId: eventId,
            includes: ["timeSlots"],
            take: 50,
            skip: skip,
            page: 1,
            orderBy: "order|asc"
        )
        
        AFWrapper.getRequest(
            url,
            params: nil,
            headers: Header.header()
        ) { response in
            
            guard let responseDic = response as? [String: Any],
                  let list = responseDic["list"] as? [[String: Any]],
                  let hasMore = responseDic["hasMany"] as? Bool else {
                completion(false, nil, [], false)
                return
            }
            
            if let seatingList = [SeatingArea].parse(list) {
                completion(true, nil, seatingList, hasMore)
            } else {
                completion(false, "internal error", [], false)
            }
            
        } failure: { error in
            
            if let err = error as? NSError, err.code == 0 {
                completion(false, err.domain, [], false)
                return
            }
            
            completion(false, nil, [], false)
        }
    }
}
