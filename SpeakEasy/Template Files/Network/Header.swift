//
//  Header.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation

enum HeaderContentType: String {
    case json = "application/json"
    case xWwwFormUrlEncoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
}

struct Header {

    static func header(_ headerContentType: HeaderContentType = .json, timeZone: String? = nil, doormanId: String = "", venueId: String = "") -> [String: String] {
        var header = ["Authorization": "Bearer \(UserDefault.shared.accessToken ?? "")",
         "Content-Type": "\(headerContentType.rawValue)",
         "app_version": Bundle.main.releaseVersionNumber,
         "build_number": Bundle.main.buildVersionNumber,
         "platform": "ios",
         "app_bundle_id": Bundle.main.bundleIdentifier ?? "invalid bundle id"]
        if timeZone?.lowercased() != "" {
            header["timezone"] = timeZone?.lowercased() ?? TimeZone.current.identifier.lowercased()
        }
        if doormanId != "" {
            header["doorman"] = doormanId
        }
        if venueId != "" {
            header["venue"] = String(venueId)
        }
        return header
    }
}
