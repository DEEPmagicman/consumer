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
    func alertPopup(_ title: String, _ message: String, _ btnTitle: String = "ok", completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title.localize(), message: message.localize(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: btnTitle.localize(), style: .default) { _ in
            completion?()
        })
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension Decodable {
    static func parse(_ obj: Any) -> Self? {
        do {
            let data = try JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
            return try JSONDecoder().decode(self, from: data)
        } catch {
            print("---\(error)")
            let error = NSError.init(domain: NSCocoaErrorDomain,
                                     code: 101,
                                     userInfo: ["type": "Model parsing error",
                                                "model type": "\(self)",
                                                "error": "\(error)",
                                                "environment": SharedURL.baseURL])            
            return nil
        }
    }
}
