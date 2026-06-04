//
//  SearchFlowService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 03/06/26.
//

import Foundation

final class SearchFlowService {

    static let shared = SearchFlowService()

    func searchVenues(keyword: String, completion: @escaping ([SearchVenueItem]) -> Void) {
        // TODO: Replace with venue API.
        completion([])
    }

    func searchEvents(
        venueId: String?,
        keyword: String?,
        fromDate: Date?,
        toDate: Date?,
        completion: @escaping ([SearchEventItem]) -> Void
    ) {
        // TODO: Replace with event API.
        completion([])
    }
}
