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
