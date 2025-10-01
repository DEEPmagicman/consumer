//
//  Stripe.swift
//  SpeakEasy-Consumer
//
//  Created by Amit Surani on 11/05/23.
//

import Foundation

struct Stripe {
    #if DEBUG
        static let publishableKey = "pk_test_51MVrDLBuSsaUd7BTwD22BrfvI0QvLhYMe1b4usjbCW5NefmUVgc0Th4ZrdeOBDL5Xdh3GgzYgvPsct7qFOw9q97W00Dx516uA1"
   #else
        static let publishableKey = "pk_live_51MVrDLBuSsaUd7BTVNumpYdLm1NT3cnQF2HmwWRmedtNmDiHm20T8kwmPMSSI7lEXzSbfyXrJ2hcBqOMOJv0h0TD00krZxi0Tg"
    #endif
}

struct SharedURL {
#if DEBUG
    static let baseURL = "https://dev.speakeasygo.com"
    static let webBaseURL = "https://dev-consumer.speakeasygo.com"
    static let isEncryptionEnabled = false
#else
    static let baseURL = "https://production.speakeasygo.com"
    static let webBaseURL = "https://speakeasygo.com"
    static let isEncryptionEnabled = true
#endif
    static let amazonStorage = "https://media.speakeasygo.com/"
    static let appStoreURL = "https://apps.apple.com/app/speakeasy-go/id1642351956"
    
    static let coverShareURL = "\(webBaseURL)/%@/cover/booking?bid=%@"
    static let addOnsShareURL = "\(webBaseURL)/%@/addons/booking?aid=%@"
    static let tableBookingURL = "\(webBaseURL)/select-date?venueId=%@"
}

struct Const {
    static var CurrentUTCTime: String {
        Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC"))
    }
}
