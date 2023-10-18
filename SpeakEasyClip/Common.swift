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
}
