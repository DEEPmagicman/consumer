//
//  Loader.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/22.
//

import Foundation
import SVProgressHUD

struct Loader {

    static var isVisible:Bool {
        get {
            return SVProgressHUD.isVisible()
        }
    }
    
    private static func config() {
        SVProgressHUD.resetOffsetFromCenter()
        SVProgressHUD.setBackgroundColor(.black)
        SVProgressHUD.setForegroundColor(Constant.Color.primaryColor)
        SVProgressHUD.setRingThickness(4)
        SVProgressHUD.setDefaultAnimationType(.flat)
        SVProgressHUD.setHapticsEnabled(true)
    }
    
    static func show() {
        config()
        SVProgressHUD.show()
//        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    static func show(progress:Double) {
        self.config()
        SVProgressHUD.showProgress(Float(progress))
//        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    static func hide() {
        SVProgressHUD.dismiss()
//        UIApplication.shared.endIgnoringInteractionEvents()
    }
}
