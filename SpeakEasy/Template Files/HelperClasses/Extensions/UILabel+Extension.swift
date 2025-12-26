//
//  UILabel+Extension.swift
//  Quick Delivery
//
//  Created by Shakeel Khan on 8/8/20.
//  Copyright © 2020 Quick Delivery. All rights reserved.
//

import UIKit

extension UILabel {
    
    func highlightBold(_ text: [String], size: CGFloat, textColor: UIColor?, isCaseInsensitive: Bool = false, addUnderLine: Bool = false) {
        guard let labelText = self.text else { return }
        let mutableAttributedString = NSMutableAttributedString.init(string: labelText)
        text.forEach {
            var range = isCaseInsensitive ? (labelText as NSString).range(of: $0, options: .caseInsensitive) : (labelText as NSString).range(of: $0)
            mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: Constant.Font.boldText(size: size), range: range)
            mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor as Any, range: range)
            if addUnderLine {
                mutableAttributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            }
            while range.upperBound < labelText.count {
                range = (labelText as NSString).range(of: $0, range: NSRange(location: range.upperBound, length: labelText.count - range.upperBound))
                mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: Constant.Font.boldText(size: size), range: range)
                mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor as Any, range: range)
                if addUnderLine {
                    mutableAttributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                }
            }
        }
        self.attributedText = mutableAttributedString
    }
    
    func getWidth(text: String) -> CGFloat {
        self.numberOfLines = 1
        self.text = text
        self.sizeToFit()
        return self.frame.width
    }
}
