//
//  Common.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 01/06/23.
//

import UIKit

extension UIView {
    func setGradientColor(colors: [CGColor] = CommonConstant.Color.gradientColors) -> CAGradientLayer {
        removeGradientBackgroundColor()
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.name = "gradientLayer"
        return gradientLayer
    }
    
    func removeGradientBackgroundColor() {
        layer.sublayers?.filter { $0.name == "gradientLayer" }.forEach { $0.removeFromSuperlayer() }
    }
    
    func setHorizontalGradientColor(
            colors: [CGColor]
        ) -> CAGradientLayer {

            removeGradientBackgroundColor()

            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = bounds
            gradientLayer.colors = colors
            gradientLayer.locations = [0, 1]

            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint   = CGPoint(x: 1.0, y: 0.5)

            gradientLayer.name = "gradientLayer"

            layer.insertSublayer(gradientLayer, at: 0)

            return gradientLayer
        }
    
}

struct CommonConstant {
    
    struct Color {
        static let gradientColors = [UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor]
    }

    struct Icon {
        static let checkBoxEmpty = UIImage(named: "checkBoxEmpty")
        static let checkBoxFull = UIImage(named: "checkBoxFull")
    }    
}

extension UITextField {
    func addNextButtonKeyboard(superViewCount: Int) {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(self.nextButtonTapped(_:)))
        nextButton.tag = superViewCount
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        keyboardToolbar.items = [flexibleSpace, nextButton]
        
        self.inputAccessoryView = keyboardToolbar
    }
    
    @objc func nextButtonTapped(_ btn: UIButton) {
        var superV = self.superview
        for _ in 0..<btn.tag - 1 {
            superV = superV?.superview
        }
        superV?.viewWithTag(self.tag + 1)?.becomeFirstResponder()
    }
    
    func addDoneButtonKeyboard() {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        keyboardToolbar.items = [flexibleSpace, doneButton]
        
        self.inputAccessoryView = keyboardToolbar
    }
    
    @objc private func doneButtonTapped() {
        self.resignFirstResponder()
    }
}

extension String {
    var isValidEmail: Bool {
        let regularExpressionForEmail = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let testEmail = NSPredicate(format: "SELF MATCHES %@", regularExpressionForEmail)
        return testEmail.evaluate(with: self.replacingOccurrences(of: " ", with: ""))
    }
    
    func convertDateFormat(from: String, to: String, isUTC: Bool = true, useDayLightSavingTime: Bool = false, customTimeZone: String = "") -> String {
        let olDateFormatter = DateFormatter()
        olDateFormatter.dateFormat = from
        if isUTC {
            olDateFormatter.timeZone = TimeZone(identifier: "UTC")!
        } else {
            olDateFormatter.timeZone = .current
        }
        guard let oldDate = olDateFormatter.date(from: self) else { return "No date Found" }
        let convertDateFormatter = DateFormatter()
        convertDateFormatter.dateFormat = to
        convertDateFormatter.locale = Locale(identifier: UserDefaults.standard.language)
        if customTimeZone != "", let timeZone = TimeZone(identifier: customTimeZone) {
            convertDateFormatter.timeZone = timeZone
        } else {
            convertDateFormatter.timeZone = .current
        }
        if useDayLightSavingTime {
            return convertDateFormatter.string(from: oldDate.addingTimeInterval(convertDateFormatter.timeZone.daylightSavingTimeOffset()))
        } else {
            return convertDateFormatter.string(from: oldDate)
        }
    }
    
    func toDate(withFormat format: DateFormat, isUTC: Bool = true) -> Date? {
        let dateFormatter = DateFormatter()
        if isUTC {
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
        } else {
            dateFormatter.timeZone = .current
        }
        dateFormatter.dateFormat = format.rawValue
        return dateFormatter.date(from: self)
    }
}

// NOTE: for localisation
extension String {
    func localize(comment: String = "") -> String {
        return NSLocalizedString(self, tableName: "Localizable", comment: comment)
    }
    
    func localize(comment: String = "", args: CVarArg...) -> String {
        let format = NSLocalizedString(self, comment: comment)
        let result = withVaList(args) {
            (NSString(format: format, locale: NSLocale.current, arguments: $0) as String)
        }
        return result
    }
    
    func toVenueDate(timezone: String?) -> Date? {
        guard !self.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timezone ?? "") ?? .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return formatter.date(from: self)
    }
}

extension Bundle {
    static func swizzleLocalization() {
        let orginalSelector = #selector(localizedString(forKey:value:table:))
        guard let orginalMethod = class_getInstanceMethod(self, orginalSelector) else { return }
        
        let mySelector = #selector(myLocaLizedString(forKey:value:table:))
        guard let myMethod = class_getInstanceMethod(self, mySelector) else { return }
        
        if class_addMethod(self, orginalSelector, method_getImplementation(myMethod), method_getTypeEncoding(myMethod)) {
            class_replaceMethod(self, mySelector, method_getImplementation(orginalMethod), method_getTypeEncoding(orginalMethod))
        } else {
            method_exchangeImplementations(orginalMethod, myMethod)
        }
    }
    
    @objc private func myLocaLizedString(forKey key: String, value: String?, table: String?) -> String {

        guard let bundlePath = Bundle.main.path(forResource: UserDefaults.standard.language, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else {
            return Bundle.main.myLocaLizedString(forKey: key, value: value, table: table)
        }
        if table == "Main" {
            return bundle.myLocaLizedString(forKey: key, value: value, table: table)
        }
        return bundle.myLocaLizedString(forKey: key, value: value, table: "Localizable")
    }
}

extension UserDefaults {
    var language: String {
        var systemLanguage: Language = .english
        if let arr = UserDefaults.standard.stringArray(forKey: "AppleLanguages"), let language = arr.first {
            let languageCode = language.components(separatedBy: "-").first ?? language
            systemLanguage = Language(rawValue: languageCode) ?? .english
        }
        return systemLanguage.rawValue
    }
}

extension Date {
    func toString(dateFormat format: DateFormat, timeZone: TimeZone? = nil) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        if let timeZone = timeZone {
            dateFormatter.timeZone = timeZone
        }
        return dateFormatter.string(from: self)
    }
}

extension Dictionary {
    func encrypted() -> [String: Any]? {
        guard var params = self as? [String: Any] else {
            return nil
        }
        if params["file"] is UIImage {
            params["file"] = ""
        }
        do {
            let paramData = try JSONSerialization.data(withJSONObject: params)
            let encryptedParamData = try encrypt(data: paramData, key: EncryptKeys.key, iv: EncryptKeys.iv)
            let encryptedParamBase64 = encryptedParamData.base64EncodedString()
            return ["data": encryptedParamBase64]
        } catch {
            print("Error serializing parameters: \(error)")
            return nil
        }
    }
    
    func headerEncrypt() -> String? {
        guard let params = self as? [String: Any] else {
            return nil
        }
        do {
            let paramData = try JSONSerialization.data(withJSONObject: params)
            let encryptedParamData = try encrypt(data: paramData, key: EncryptKeys.headerKey, iv: EncryptKeys.headerIV)
            let encryptedParamBase64 = encryptedParamData.base64EncodedString()
            return encryptedParamBase64
        } catch {
            print("Error serializing parameters: \(error)")
            return nil
        }
    }
}

extension String {
    func decrypted() -> [String: Any]? {
        guard let encryptedData = Data(base64Encoded: self) else {
            return nil
        }
        do {
            let decryptedData = try decrypt(data: encryptedData, key: EncryptKeys.key, iv: EncryptKeys.iv)
            guard let responseStr = try JSONSerialization.jsonObject(with: decryptedData, options: .fragmentsAllowed) as? String,
                  let responseDic = try JSONSerialization.jsonObject(with: responseStr.data(using: .utf8)!, options: .fragmentsAllowed) as? [String: Any] else {
                return nil
            }
            return responseDic
        } catch {
            print("Error decrypting response: \(error)")
            return nil
        }
    }
    
    func decryptedArry() -> [[String: Any]]? {
        guard let encryptedData = Data(base64Encoded: self) else {
            return nil
        }
        do {
            let decryptedData = try decrypt(data: encryptedData, key: EncryptKeys.key, iv: EncryptKeys.iv)
            guard let responseStr = try JSONSerialization.jsonObject(with: decryptedData, options: .fragmentsAllowed) as? String,
                  let responseDic = try JSONSerialization.jsonObject(with: responseStr.data(using: .utf8)!, options: .fragmentsAllowed) as? [[String: Any]] else {
                return nil
            }
            return responseDic
        } catch {
            print("Error decrypting response: \(error)")
            return nil
        }
    }
    
    func decryptedBool() -> Bool? {
        guard let encryptedData = Data(base64Encoded: self) else {
            return nil
        }
        do {
            let decryptedData = try decrypt(data: encryptedData, key: EncryptKeys.key, iv: EncryptKeys.iv)
            guard let responseStr = try JSONSerialization.jsonObject(with: decryptedData, options: .fragmentsAllowed) as? String,
                  let responseDic = try JSONSerialization.jsonObject(with: responseStr.data(using: .utf8)!, options: .fragmentsAllowed) as? Bool else {
                return nil
            }
            return responseDic
        } catch {
            print("Error decrypting response: \(error)")
            return nil
        }
    }
    
    func encryptedHeader() -> String {
        var data = [String: Any]()
        data["date"] = self
        return data.headerEncrypt() ?? ""
    }
}

enum Language: String {
    case english = "en"
    case spanish = "es"
    
    var display: String {
        switch self {
        case .english:
            "English"
        case .spanish:
            "Español"
        }
    }
    
    init(language: String) {
        switch language {
        case "English":
            self = .english
        case "Español":
            self = .spanish
        default:
            self = .english
        }
    }
}

extension UITextView {
    func setHTMLFromString(htmlText: String) {
        let fontName = self.font?.fontName ?? "-apple-system"
        let fontSize = self.font?.pointSize ?? 16
        let modifiedFont = String(format: "<span style=\"font-family: \(fontName); font-size: \(fontSize)\">%@</span>", htmlText)

        guard let data = modifiedFont.data(using: .unicode) else { return }

        do {
            let attributedString = try NSMutableAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil)

            let fullRange = NSRange(location: 0, length: attributedString.length)
            if let currentTextColor = self.textColor {
                attributedString.addAttribute(.foregroundColor, value: currentTextColor, range: fullRange)
            }

            self.attributedText = attributedString
            self.isEditable = false
            self.isScrollEnabled = false
            self.dataDetectorTypes = .link
            self.textContainerInset = .zero
            self.isSelectable = true
            self.textContainer.lineFragmentPadding = 0
        } catch {
            print("Failed to parse HTML:", error)
        }
    }
}

extension String {
    func htmlToPlainText() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        
        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
            )
            return attributedString.string
        } catch {
            print("Error converting HTML to plain text: \(error)")
            return self
        }
    }
}

enum CurrencyPosition: String {
    case prefix
    case suffix
}

struct CurrencyFormatter {

    static func amount(
        _ value: Double,
        symbol: String?,
        position: String?,
        haseValueInt: Bool = false
    ) -> String {

        let currencySymbol = symbol ?? "$"
        let formattedAmount = haseValueInt ? "\(Int(value))" : value.decimalFormat(true)

        switch CurrencyPosition(rawValue: position?.lowercased() ?? "prefix") {
        case .suffix:
            return "\(formattedAmount)\(currencySymbol)"
        case .prefix, .none:
            return "\(currencySymbol)\(formattedAmount)"
        }
    }
}
