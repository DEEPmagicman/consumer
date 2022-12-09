//
//  IdentifierHelper.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import Foundation

class IdentifierHelper {
    
    static let shared = IdentifierHelper()
    
    private init() {
        
    }
    
    func getIdentifier(_ className:AnyClass) -> String {
        return String(describing: className.self)
    }

}
