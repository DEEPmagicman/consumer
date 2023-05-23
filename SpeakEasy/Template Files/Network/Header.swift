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

    static func header(_ headerContentType: HeaderContentType = .json, timeZone: String? = nil) -> [String: String] {
        ["Authorization": "Bearer \(UserDefault.shared.accessToken ?? "")",
         "Content-Type": "\(headerContentType.rawValue)",
         "timezone": timeZone ?? TimeZone.current.identifier.lowercased(),
         "app_version": Bundle.main.releaseVersionNumber,
         "build_number": Bundle.main.buildVersionNumber,
         "platform": "ios",
         "app_bundle_id": Bundle.main.bundleIdentifier ?? "invalid bundle id"
        ]
    }
}
