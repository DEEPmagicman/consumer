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
        static let baseURL = "https://stage.speakeasygo.com"
        static let webBaseURL = "https://stage-consumer.speakeasygo.com"
    #else
        static let baseURL = "https://api.speakeasygo.com"
        static let webBaseURL = "https://speakeasygo.com"
    #endif
    static let amazonStorage = "https://speakeasy-storage.s3.amazonaws.com/"
    static let appStoreURL = "https://apps.apple.com/app/speakeasy-go/id1642351956"
    static let QAWebURL = "\(webBaseURL)/ticket-qrcode-generate?qrFor=booking&bookingId=%@"
    static let tableBookingURL = "\(webBaseURL)/select-date?venueId=%@"
}
