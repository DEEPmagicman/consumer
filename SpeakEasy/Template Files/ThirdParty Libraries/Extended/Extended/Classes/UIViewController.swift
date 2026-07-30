//
//  UIViewController.swift
//  Extended
//
//  Created by Amir Shayegh on 2018-09-26.
//

import Foundation
import ObjectiveC
import QuartzCore
import UIKit

extension UIViewController {

    /// Make sure storyboard file has same name as the class name
    public static func storyboardInstance() -> UIViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: Bundle(for: self))
        let controller = storyboard.instantiateInitialViewController()
        return controller
    }

    public func showAlert(with title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        ac.addAction(cancel)

        present(ac, animated: true, completion: nil)
    }
    
    func pushVC(_ controller: UIViewController, animated: Bool = true) {
//        controller.hidesBottomBarWhenPushed = true
        if let self = self as? UINavigationController {
            self.pushViewController(controller, animated: animated)
        } else {
            self.navigationController?.pushViewController(controller, animated: animated)
        }
    }
    
    func setUIInterfaceOrientation(_ value: UIInterfaceOrientation) {
        UIDevice.current.setValue(value.rawValue, forKey: "orientation")
    }
    
    func presentVC(_ controller: UIViewController, animated: Bool = true) {
        self.navigationController?.present(controller, animated: animated, completion: nil)
    }
    
}

private enum NavigationPushGuard {
    static var isInstalled = false
    static var lastControllerNameKey: UInt8 = 0
    static var lastPushTimeKey: UInt8 = 0
    static let duplicateInterval: TimeInterval = 0.8
    static let topDuplicateInterval: TimeInterval = 4.0
}

private enum PresentationGuard {
    static var isInstalled = false
    static var lastControllerNameKey: UInt8 = 0
    static var lastPresentationTimeKey: UInt8 = 0
    static let duplicateInterval: TimeInterval = 0.8
}

extension UIViewController {

    static func installDuplicatePresentationGuard() {
        guard !PresentationGuard.isInstalled else { return }
        PresentationGuard.isInstalled = true

        guard
            let original = class_getInstanceMethod(
                UIViewController.self,
                #selector(UIViewController.present(_:animated:completion:))
            ),
            let swizzled = class_getInstanceMethod(
                UIViewController.self,
                #selector(UIViewController.se_present(_:animated:completion:))
            )
        else { return }

        method_exchangeImplementations(original, swizzled)
    }

    @objc private func se_present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        guard shouldAllowPresentation(viewControllerToPresent) else { return }
        se_present(viewControllerToPresent, animated: flag, completion: completion)
    }

    private func shouldAllowPresentation(_ viewController: UIViewController) -> Bool {
        guard presentedViewController == nil,
              transitionCoordinator == nil else {
            return false
        }

        let controllerName = String(describing: type(of: viewController))
        let now = CACurrentMediaTime()
        let lastControllerName = objc_getAssociatedObject(
            self,
            &PresentationGuard.lastControllerNameKey
        ) as? String
        let lastPresentationTime = objc_getAssociatedObject(
            self,
            &PresentationGuard.lastPresentationTimeKey
        ) as? NSNumber

        if lastControllerName == controllerName,
           now - (lastPresentationTime?.doubleValue ?? 0) < PresentationGuard.duplicateInterval {
            return false
        }

        objc_setAssociatedObject(
            self,
            &PresentationGuard.lastControllerNameKey,
            controllerName,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        objc_setAssociatedObject(
            self,
            &PresentationGuard.lastPresentationTimeKey,
            NSNumber(value: now),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        return true
    }
}

extension UINavigationController {

    static func installDuplicatePushGuard() {
        guard !NavigationPushGuard.isInstalled else { return }
        NavigationPushGuard.isInstalled = true

        guard
            let original = class_getInstanceMethod(
                UINavigationController.self,
                #selector(UINavigationController.pushViewController(_:animated:))
            ),
            let swizzled = class_getInstanceMethod(
                UINavigationController.self,
                #selector(UINavigationController.se_pushViewController(_:animated:))
            )
        else { return }

        method_exchangeImplementations(original, swizzled)
    }

    @objc private func se_pushViewController(
        _ viewController: UIViewController,
        animated: Bool
    ) {
        guard shouldAllowPush(viewController) else { return }
        se_pushViewController(viewController, animated: animated)
    }

    private func shouldAllowPush(_ viewController: UIViewController) -> Bool {
        guard transitionCoordinator == nil else { return false }

        let controllerName = String(describing: type(of: viewController))
        let now = CACurrentMediaTime()
        let lastControllerName = objc_getAssociatedObject(
            self,
            &NavigationPushGuard.lastControllerNameKey
        ) as? String
        let lastPushTime = objc_getAssociatedObject(
            self,
            &NavigationPushGuard.lastPushTimeKey
        ) as? NSNumber
        let elapsedTime = now - (lastPushTime?.doubleValue ?? 0)

        if lastControllerName == controllerName,
           elapsedTime < NavigationPushGuard.duplicateInterval {
            return false
        }

        if String(describing: type(of: topViewController)) == controllerName,
           lastControllerName == controllerName,
           elapsedTime < NavigationPushGuard.topDuplicateInterval {
            return false
        }

        objc_setAssociatedObject(
            self,
            &NavigationPushGuard.lastControllerNameKey,
            controllerName,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        objc_setAssociatedObject(
            self,
            &NavigationPushGuard.lastPushTimeKey,
            NSNumber(value: now),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        return true
    }
}
