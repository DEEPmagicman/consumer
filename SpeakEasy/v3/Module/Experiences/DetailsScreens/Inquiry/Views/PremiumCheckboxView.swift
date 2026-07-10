//
//  PremiumCheckboxView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 24/06/26.
//

import UIKit

final class PremiumCheckboxView: UIView {

    var isChecked: Bool = false {
        didSet { updateAppearance() }
    }

    var supportsExpansion: Bool = false {
        didSet { updateLabelText() }
    }

    var onToggle: ((Bool) -> Void)?
    var onExpansionChanged: (() -> Void)?

    private let box   = UIView()
    private let tick  = UIImageView()
    private let label = UILabel()
    private let collapsedLines = 3
    private var isExpanded = false

    var labelText: String = "" {
        didSet {
            isExpanded = false
            updateLabelText()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        // Box
        box.backgroundColor     = .clear
        box.translatesAutoresizingMaskIntoConstraints = false
        box.isUserInteractionEnabled = true

        // Tick
        tick.image              = Constant.Icon.uncheckedIcon?.withRenderingMode(.alwaysOriginal)
        tick.tintColor          = nil
        tick.contentMode        = .scaleAspectFit
        tick.translatesAutoresizingMaskIntoConstraints = false
        tick.isUserInteractionEnabled = true

        // Label
        label.numberOfLines     = 0
        label.font              = Constant.Font.geistRegular(size: 10)
        label.textColor         = UIColor.white.withAlphaComponent(0.9)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true

        addSubview(box)
        box.addSubview(tick)
        addSubview(label)

        NSLayoutConstraint.activate([
            box.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            box.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            box.widthAnchor.constraint(equalToConstant: 18),
            box.heightAnchor.constraint(equalToConstant: 18),

            tick.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            tick.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            tick.widthAnchor.constraint(equalToConstant: 18),
            tick.heightAnchor.constraint(equalToConstant: 18),

            label.leadingAnchor.constraint(equalTo: box.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let boxTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        box.addGestureRecognizer(boxTap)

        let tickTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tick.addGestureRecognizer(tickTap)

        let labelTap = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap))
        label.addGestureRecognizer(labelTap)
    }

    private func updateAppearance() {
        tick.image = (isChecked ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon)?
            .withRenderingMode(.alwaysOriginal)
    }

    private func updateLabelText() {
        guard supportsExpansion, shouldShowToggle else {
            label.attributedText = nil
            label.text = labelText
            label.numberOfLines = 0
            return
        }

        let toggleText = isExpanded ? "View Less" : "View More"
        let bodyText = isExpanded ? labelText : collapsedPreview(from: labelText, toggleText: toggleText)
        let displayText = "\(bodyText) \(toggleText)"
        let attributed = NSMutableAttributedString(
            string: displayText,
            attributes: [
                .font: Constant.Font.geistRegular(size: 10),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
        )
        let range = (displayText as NSString).range(of: toggleText)
        attributed.addAttributes([
            .font: Constant.Font.geistMedium(size: 10),
            .foregroundColor: UIColor.lightGray
        ], range: range)

        label.numberOfLines = isExpanded ? 0 : collapsedLines
        label.attributedText = attributed
        label.invalidateIntrinsicContentSize()
        invalidateIntrinsicContentSize()
    }

    private var shouldShowToggle: Bool {
        labelText.count > 120
    }

    private func collapsedPreview(from text: String, toggleText: String) -> String {
        guard text.count > 120 else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: min(115, text.count))
        return String(text[..<endIndex])
            .trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    @objc private func handleTap() {
        isChecked.toggle()
        onToggle?(isChecked)
    }

    @objc private func handleLabelTap() {
        guard supportsExpansion, shouldShowToggle else {
            handleTap()
            return
        }

        isExpanded.toggle()
        updateLabelText()
        onExpansionChanged?()
    }
}
