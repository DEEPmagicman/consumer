//
//  BundleExtension.swift
//  SpeakEasy-Consumer
//
//  Created by Amit Surani on 12/05/23.
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var buildVersionNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}

extension UserDefaults {
    func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
}
