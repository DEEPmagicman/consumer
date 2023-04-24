//
//  IdentifierHelper.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import Foundation

struct IdentifierHelper {
    static func getIdentifier(_ className: AnyClass) -> String {
        String(describing: className.self)
    }
}
