//
//  ThemeManager.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 11/05/26.
//

import UIKit

enum ThemeMode: String {
    case system
    case light
    case dark
}

final class ThemeManager {
    static let shared = ThemeManager()

    private let key = "app_theme"

    var current: ThemeMode {
        get {
            let value = UserDefaults.standard.string(forKey: key) ?? ThemeMode.system.rawValue
            return ThemeMode(rawValue: value) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            apply(theme: newValue)
        }
    }

    func apply(theme: ThemeMode) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        scene.windows.forEach { window in
            switch theme {
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            }
        }
    }
}

enum AuthTheme {
    
    static var title: UIColor {
        AppColor.primaryWhiteColor
    }

    static var subtitle: UIColor {
        AppColor.primaryWhiteColor
    }

    static var fieldBackground: UIColor {
        AppColor.primaryWhiteColor.withAlphaComponent(0.09)
    }

    static var fieldText: UIColor {
        AppColor.primaryWhiteColor
    }

    static var placeholder: UIColor {
        AppColor.primaryWhiteColor.withAlphaComponent(0.35)
    }

    static var border: UIColor {
        AppColor.primaryWhiteColor.withAlphaComponent(0.05)
    }

    static var primaryButtonBg: UIColor {
        AppColor.primaryWhiteColor
    }

    static var primaryButtonTitle: UIColor {
        AppColor.primaryBlackColor
    }

    static var disabledButtonBg: UIColor {
        AppColor.primaryWhiteColor.withAlphaComponent(0.12)
    }

    static var link: UIColor {
        UIColor.systemBlue
    }
    
    static var cardViewColor: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#232323").withAlphaComponent(0.50) : UIColor(hex: "#2141B1D").withAlphaComponent(0.11) }
    }
}
