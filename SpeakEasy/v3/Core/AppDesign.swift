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

enum AppHaptic {

    private enum FeedbackKind: String {
        case tap
        case primaryAction
        case navigation
        case selection
        case cardOpen
        case stepper
        case success
        case warning
        case error
        case destructive
    }

    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)

    private static var lastFeedbackKind: FeedbackKind?
    private static var lastFeedbackTime: TimeInterval = 0
    private static let duplicateSuppressionInterval: TimeInterval = 0.04

    static func tap() {
        play(.tap)
    }

    static func primaryAction() {
        play(.primaryAction)
    }

    static func navigation() {
        play(.navigation)
    }

    static func selectionChanged() {
        play(.selection)
    }

    static func cardOpen() {
        play(.cardOpen)
    }

    static func stepperChanged() {
        play(.stepper)
    }

    static func success() {
        play(.success)
    }

    static func warning() {
        play(.warning)
    }

    static func error() {
        play(.error)
    }

    static func destructive() {
        play(.destructive)
    }

    private static func play(_ kind: FeedbackKind) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                play(kind)
            }
            return
        }

        guard shouldPlay(kind) else { return }

        switch kind {
        case .tap:
            softImpactGenerator.impactOccurred(intensity: 0.45)

        case .primaryAction:
            mediumImpactGenerator.impactOccurred(intensity: 0.72)

        case .navigation:
            lightImpactGenerator.impactOccurred(intensity: 0.55)

        case .selection:
            selectionGenerator.selectionChanged()

        case .cardOpen:
            softImpactGenerator.impactOccurred(intensity: 0.62)

        case .stepper:
            lightImpactGenerator.impactOccurred(intensity: 0.66)

        case .success:
            notificationGenerator.notificationOccurred(.success)

        case .warning:
            notificationGenerator.notificationOccurred(.warning)

        case .error:
            notificationGenerator.notificationOccurred(.error)

        case .destructive:
            rigidImpactGenerator.impactOccurred(intensity: 0.82)
        }

        prepareGenerators()
    }

    private static func shouldPlay(_ kind: FeedbackKind) -> Bool {
        let now = CACurrentMediaTime()
        defer {
            lastFeedbackKind = kind
            lastFeedbackTime = now
        }

        guard lastFeedbackKind == kind else { return true }

        return now - lastFeedbackTime > duplicateSuppressionInterval
    }

    private static func prepareGenerators() {
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        softImpactGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
    }
}
