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

    static func header(_ headerContentType: HeaderContentType = .json) -> [String: String] {
        ["Authorization": "Bearer \(UserDefault.shared.loginToken ?? "")",
         "Content-Type": "\(headerContentType.rawValue)"]
    }
}
