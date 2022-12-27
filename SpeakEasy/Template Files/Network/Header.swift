//
//  Header.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation

enum HEADER_CONTENT_TYPE: String {
    case json = "application/json"
    case xwwwformUrlencoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
}

class Header {
    static let shared = Header()
    func header(headerContentType:HEADER_CONTENT_TYPE = .json) -> [String:String] {

        return ["Authorization": "Bearer \(UserDefault.shared.loginToken ?? "")",
                "Content-Type":"\(headerContentType.rawValue)"]
    }
}
