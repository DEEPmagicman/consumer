//
//  AppDelegate.swift
//  FoodChoo-Merchant
//
//  Created by Mac Book on 27/08/2020.
//  Copyright © 2020 Al-Tafseer. All rights reserved.
//

import UIKit

@objc class Utility: NSObject{
    static let main = Utility()
    fileprivate override init() {}
}
extension Utility {
    
    static var isDebug: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    func topViewController(base: UIViewController? = (AppDelegate.shared).window?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    
    func showAlert(message: String, title: String, usingCompletionHandler handler:@escaping (() -> Swift.Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.OK.text, style: .default, handler: {
            (action) in
            handler()
        }))
        Utility().topViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    func shareSocialWith(text: String){
        let textToShare = [text]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = Utility.main.topViewController()?.view
        Utility.main.topViewController()?.present(activityViewController, animated: true, completion: nil)
    }
}

class Alert {
    
    static func showAlertSheet(style: UIAlertController.Style, title: String?, message: String?, actions: [UIAlertAction] = [UIAlertAction(title: "ok", style: .cancel, handler: nil)], completion: (() -> Swift.Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        for action in actions {
            alert.addAction(action)
        }
        if let topVC = UIApplication.getTopMostViewController() {
            alert.popoverPresentationController?.sourceView = topVC.view
            alert.popoverPresentationController?.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
            DispatchQueue.main.async {
                topVC.present(alert, animated: true, completion: completion)
            }
        }
    }
    
    static func showToast(_ message: String, vc: UIViewController? = nil) {
        if let vc = vc {
            vc.view.makeToast(message)
            return
        }
        if let vcc = UIApplication.shared.keyWindow?.rootViewController {
            vcc.view.makeToast(message)
        }
    }
}
