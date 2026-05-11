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
