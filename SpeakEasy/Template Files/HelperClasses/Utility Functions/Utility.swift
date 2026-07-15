//
//  AppDelegate.swift
//  FoodChoo-Merchant
//
//  Created by Mac Book on 27/08/2020.
//  Copyright © 2020 Al-Tafseer. All rights reserved.
//

import UIKit
import MHLoadingButton

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
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: {
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
    
    func isDarkMode(for view: UIView? = nil) -> Bool {

        if #available(iOS 12.0, *) {

            if let view {
                return view.traitCollection.userInterfaceStyle == .dark
            }

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return false
            }

            return window.traitCollection.userInterfaceStyle == .dark
        }

        return false
    }
    
    func makeLabel(_ text: String, size: CGFloat = 18, numberOfLines: Int = 0, textAlignment: NSTextAlignment = .center, textColor: UIColor = AppColor.primaryWhiteColor, font: UIFont = Constant.Font.geistMedium(size: 18)) -> UILabel {

        var newFont = font
        if newFont == Constant.Font.geistMedium(size: 18) {
            newFont = Constant.Font.geistMedium(size: size)
        }
        let label = UILabel()
        label.text = text
        label.textColor = textColor
        label.font = newFont
        label.textAlignment = textAlignment
        label.numberOfLines = numberOfLines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    func makeSpacer(_ height: CGFloat) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }
    
    func stylePrimaryButton(_ button: LoadingButton, title: String, size: CGFloat = 17, cornerRadius: CGFloat = 16) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(AppColor.primaryBlackColor, for: .normal)
        button.titleLabel?.font = Constant.Font.geistMedium(size: size)
        button.bgColor = AuthTheme.primaryButtonBg
        button.layer.cornerRadius = cornerRadius
        button.clipsToBounds = true
        button.indicator = MaterialLoadingIndicator(color: AuthTheme.primaryButtonTitle)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setButton(_ button: LoadingButton, enabled: Bool) {
        button.isUserInteractionEnabled = enabled
        button.bgColor = enabled ? AuthTheme.primaryButtonBg : AuthTheme.disabledButtonBg
        button.setTitleColor(enabled ? AuthTheme.primaryButtonTitle : AppColor.primaryColor, for: .normal)
    }
    
    func makeBackButton(
        size: CGFloat = 56,
        iconSize: CGFloat = 26,
        backgroundColor: UIColor = .clear,
        iconColor: UIColor = AppColor.primaryWhiteColor,
        borderColor: UIColor = .clear,
        borderWidth: CGFloat = 0,
        target: Any?,
        action: Selector
    ) -> UIButton {

        let button = UIButton(type: .system)

        let imageConfig = UIImage.SymbolConfiguration(
            pointSize: iconSize,
            weight: .regular
        )

        button.setImage(
            UIImage(systemName: "arrow.left", withConfiguration: imageConfig),
            for: .normal
        )

        button.tintColor = iconColor
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = size / 2
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = borderWidth
        button.layer.borderColor = borderColor.cgColor
        button.clipsToBounds = true

        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])

        button.addTarget(target, action: action, for: .touchUpInside)

        return button
    }
}

final class PrimaryButton: LoadingButton {

    init() {
        super.init(frame: .zero)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {

        translatesAutoresizingMaskIntoConstraints = false

        setTitleColor(
            AppColor.primaryBlackColor,
            for: .normal
        )

        titleLabel?.font = Constant.Font.geistMedium(size: 17)

        bgColor = AuthTheme.primaryButtonBg

        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true

        indicator = MaterialLoadingIndicator(
            color: AuthTheme.primaryButtonTitle
        )

        heightAnchor.constraint(equalToConstant: 56).isActive = true
    }

    func configure(
        title: String,
        fontSize: CGFloat = 17,
        cornerRadius: CGFloat = 16
    ) {

        setTitle(title, for: .normal)

        titleLabel?.font = Constant.Font.geistMedium(size: fontSize)

        layer.cornerRadius = cornerRadius
    }

    func setEnabled(_ enabled: Bool) {

        isUserInteractionEnabled = enabled

        bgColor = enabled
        ? AuthTheme.primaryButtonBg
        : AuthTheme.disabledButtonBg

        setTitleColor(
            enabled
            ? AuthTheme.primaryButtonTitle
            : AppColor.primaryColor,
            for: .normal
        )
    }

    func startLoading() {
        showLoader(userInteraction: false)
    }

    func stopLoading() {
        hideLoader()
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
        DispatchQueue.main.async {
            if let vc = vc {
                vc.view.makeToast(message)
                return
            }
            UIApplication.getTopMostViewController()?.view.makeToast(message)
        }
    }
}
