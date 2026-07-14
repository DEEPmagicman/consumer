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

enum AgreementTextFormatter {

    static let collapsedLines = 2
    static let bodyFont = Constant.Font.geistRegular(size: 10)
    static let toggleFont = Constant.Font.geistMedium(size: 10)
    static let bodyColor = UIColor.white.withAlphaComponent(0.78)
    static let toggleColor = UIColor.white

    static func clean(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func configure(_ label: UILabel) {
        label.font = bodyFont
        label.textColor = bodyColor
        label.isUserInteractionEnabled = true
        label.numberOfLines = collapsedLines
        label.lineBreakMode = .byWordWrapping
    }

    static func apply(
        to label: UILabel,
        text: String,
        isExpanded: Bool,
        widthFallback: CGFloat,
        expandedAttributedText: NSAttributedString? = nil
    ) -> Bool {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else {
            label.attributedText = nil
            label.text = ""
            label.numberOfLines = 0
            return false
        }

        let width = resolvedWidth(for: label, fallback: widthFallback)
        let needsToggle = shouldShowToggle(for: cleanText, width: width)
        let toggleText = isExpanded ? "View Less" : "View More"
        let attributed: NSMutableAttributedString

        if isExpanded,
           let expandedAttributedText {
            attributed = normalizedExpandedAttributedText(expandedAttributedText)
        } else {
            let bodyText = isExpanded || !needsToggle
                ? cleanText
                : collapsedPreview(
                    from: cleanText,
                    width: width,
                    toggleText: toggleText
                )
            attributed = NSMutableAttributedString(
                string: needsToggle ? "\(bodyText) \(toggleText)" : bodyText,
                attributes: bodyAttributes
            )
        }

        if needsToggle {
            if isExpanded, expandedAttributedText != nil {
                attributed.append(NSAttributedString(string: " \(toggleText)"))
            }

            let toggleRange = (attributed.string as NSString).range(of: toggleText)
            attributed.addAttributes(toggleAttributes, range: toggleRange)
        }

        label.numberOfLines = isExpanded || !needsToggle ? 0 : collapsedLines
        label.lineBreakMode = .byWordWrapping
        label.attributedText = attributed
        label.invalidateIntrinsicContentSize()
        label.superview?.invalidateIntrinsicContentSize()
        label.superview?.setNeedsLayout()

        return needsToggle
    }

    static func shouldShowToggle(
        for text: String,
        label: UILabel,
        widthFallback: CGFloat
    ) -> Bool {
        shouldShowToggle(
            for: clean(text),
            width: resolvedWidth(for: label, fallback: widthFallback)
        )
    }

    static func toggleRange(in label: UILabel, isExpanded: Bool) -> NSRange {
        guard let text = label.attributedText?.string else {
            return NSRange(location: NSNotFound, length: 0)
        }

        return (text as NSString).range(of: isExpanded ? "View Less" : "View More")
    }

    static func collapsedHeight() -> CGFloat {
        ceil(bodyFont.lineHeight * CGFloat(collapsedLines)) + 6
    }

    private static var bodyAttributes: [NSAttributedString.Key: Any] {
        [
            .font: bodyFont,
            .foregroundColor: bodyColor
        ]
    }

    private static var toggleAttributes: [NSAttributedString.Key: Any] {
        [
            .font: toggleFont,
            .foregroundColor: toggleColor
        ]
    }

    private static func resolvedWidth(for label: UILabel, fallback: CGFloat) -> CGFloat {
        label.bounds.width > 0 ? label.bounds.width : max(fallback, 240)
    }

    private static func shouldShowToggle(for text: String, width: CGFloat) -> Bool {
        textHeight(for: text, width: width) > collapsedHeight()
    }

    private static func collapsedPreview(
        from text: String,
        width: CGFloat,
        toggleText: String
    ) -> String {
        guard textHeight(for: "\(text) \(toggleText)", width: width) > collapsedHeight() else {
            return text
        }

        var low = 0
        var high = text.count
        var best = ""

        while low <= high {
            let mid = (low + high) / 2
            let endIndex = text.index(text.startIndex, offsetBy: mid)
            let candidate = String(text[..<endIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let display = "\(candidate)... \(toggleText)"

            if textHeight(for: display, width: width) <= collapsedHeight() {
                best = candidate
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return best.isEmpty ? "..." : "\(best)..."
    }

    private static func textHeight(for text: String, width: CGFloat) -> CGFloat {
        (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: bodyFont],
            context: nil
        ).height
    }

    private static func normalizedExpandedAttributedText(
        _ attributedText: NSAttributedString
    ) -> NSMutableAttributedString {
        let attributed = NSMutableAttributedString(attributedString: attributedText)
        let fullRange = NSRange(location: 0, length: attributed.length)

        attributed.addAttributes(bodyAttributes, range: fullRange)
        attributed.enumerateAttribute(
            .link,
            in: fullRange,
            options: []
        ) { value, range, _ in
            if value != nil {
                attributed.addAttributes([
                    .font: toggleFont,
                    .foregroundColor: toggleColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: range)
            }
        }

        return attributed
    }
}
