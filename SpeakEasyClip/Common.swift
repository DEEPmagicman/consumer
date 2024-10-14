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
        let testEmail = NSPredicate(format:"SELF MATCHES %@", regularExpressionForEmail)
        return testEmail.evaluate(with: self)
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
    
    func toDate(withFormat format: DateFormat, isUTC: Bool = true)-> Date? {
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
        if params["file"] as? UIImage != nil {
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
            let encryptedParamData = try encrypt(data: paramData, key: EncryptKeys.key, iv: EncryptKeys.iv)
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


