//
//  StoryboardAndXibManager.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit

struct StoryboardAndXibManager {
    struct StoryBoard {
        static let onBoarding = UIStoryboard(name: "OnBoarding", bundle: nil)
        static let login2 = UIStoryboard(name: "Login2", bundle: nil)
        static let settings = UIStoryboard(name: "Settings", bundle: nil)
        static let mvp = UIStoryboard(name: "MVPFlow", bundle: nil)
        static let peymentForMvp = UIStoryboard(name: "PeymentFlow", bundle: nil)
    }
}
