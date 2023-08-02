//
//  Helper.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 06/02/23.
//

import UIKit

extension UILabel {
    func highlightBold(_ text: [String], size: CGFloat, textColor: UIColor?, isCaseInsensitive: Bool = false, underLineText: String = "") {
        guard let labelText = self.text else { return }
        let mutableAttributedString = NSMutableAttributedString.init(string: labelText)
        text.forEach {
            var range = isCaseInsensitive ? (labelText as NSString).range(of: $0, options: .caseInsensitive) : (labelText as NSString).range(of: $0)
            mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "Poppins-Bold", size: size) as Any, range: range)
            mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor as Any, range: range)
            if $0 == underLineText {
                mutableAttributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            }
            while range.upperBound < labelText.count {
                range = (labelText as NSString).range(of: $0, range: NSRange(location: range.upperBound, length: labelText.count - range.upperBound))
                mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "Poppins-Bold", size: size) as Any, range: range)
                mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor as Any, range: range)
                if $0 == underLineText {
                    mutableAttributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                }
            }
        }
        attributedText = mutableAttributedString
    }
}

struct AppClipLoader {
    static private var indicator = UIActivityIndicatorView(style: .medium)
    static func showLoader(_ view: UIView) {
        DispatchQueue.main.async {
            indicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            indicator.center = view.center
            indicator.color = .white
            view.addSubview(indicator)
            view.bringSubviewToFront(indicator)
            indicator.startAnimating()
            if !UIApplication.shared.isIgnoringInteractionEvents {
                UIApplication.shared.beginIgnoringInteractionEvents()
            }
        }
    }
    static func hideLoader() {
        DispatchQueue.main.async {
            indicator.stopAnimating()
            indicator.removeFromSuperview()
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }
}

extension UIViewController {
    func alertPopup(_ title: String, _ message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .default) { _ in
            completion?()
        })
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
