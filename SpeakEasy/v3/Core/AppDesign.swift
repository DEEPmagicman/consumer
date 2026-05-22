//
//  AppDesign.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 22/05/26.
//

import UIKit

enum AppDesign {

    static var isIOS26OrLater: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }

    static var requiresCompatibilityMode: Bool {
        Bundle.main.object(
            forInfoDictionaryKey: "UIDesignRequiresCompatibility"
        ) as? Bool ?? false
    }

    /// New iOS 26 design only when:
    /// 1. Device is iOS 26+
    /// 2. UIDesignRequiresCompatibility == false
    static var useModernIOS26Design: Bool {
        isIOS26OrLater && requiresCompatibilityMode == false
    }

    /// Old design when:
    /// - iOS 16/17/18
    /// - OR UIDesignRequiresCompatibility == true
    static var useLegacyDesign: Bool {
        !useModernIOS26Design
    }
    
    static func adaptiveConstraint(
           modernValue: CGFloat = 0,
           smallDeviceValue: CGFloat,
           regularDeviceValue: CGFloat
       ) -> CGFloat {

           if useModernIOS26Design {
               return modernValue
           }

           let isSmallDevice = UIScreen.main.bounds.width <= 375

           return isSmallDevice
               ? smallDeviceValue
               : regularDeviceValue
       }
}
