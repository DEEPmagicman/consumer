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
    private let toggleButton = UIButton(type: .system)
    private let collapsedLines = AgreementTextFormatter.collapsedLines
    private var isExpanded = false
    private var lastLaidOutLabelWidth: CGFloat = 0
    private var toggleTopConstraint: NSLayoutConstraint?
    private var toggleHeightConstraint: NSLayoutConstraint?

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

    override func layoutSubviews() {
        super.layoutSubviews()
        guard abs(label.bounds.width - lastLaidOutLabelWidth) > 0.5 else { return }
        lastLaidOutLabelWidth = label.bounds.width
        updateLabelText()
    }

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
        AgreementTextFormatter.configure(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true

        toggleButton.contentHorizontalAlignment = .leading
        toggleButton.setTitleColor(.white, for: .normal)
        toggleButton.titleLabel?.font = Constant.Font.geistSemiBold(size: 10)
        toggleButton.isHidden = true
        toggleButton.isUserInteractionEnabled = false
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.addTarget(self, action: #selector(handleExpansionTap), for: .touchUpInside)

        addSubview(box)
        box.addSubview(tick)
        addSubview(label)
        addSubview(toggleButton)

        let toggleTop = toggleButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0)
        let toggleHeight = toggleButton.heightAnchor.constraint(equalToConstant: 0)
        toggleTopConstraint = toggleTop
        toggleHeightConstraint = toggleHeight

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
            toggleButton.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            toggleButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            toggleTop,
            toggleHeight,
            toggleButton.bottomAnchor.constraint(equalTo: bottomAnchor)
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
            updateToggleButton(isVisible: false, title: nil)
            return
        }

        _ = AgreementTextFormatter.apply(
            to: label,
            text: labelText,
            isExpanded: isExpanded,
            widthFallback: UIScreen.main.bounds.width - 64
        )
        updateToggleButton(isVisible: false, title: nil)
        label.invalidateIntrinsicContentSize()
        invalidateIntrinsicContentSize()
    }

    private func updateToggleButton(isVisible: Bool, title: String?) {
        toggleButton.isHidden = true
        toggleButton.setTitle(title, for: .normal)
        toggleTopConstraint?.constant = 0
        toggleHeightConstraint?.constant = 0
    }

    private var shouldShowToggle: Bool {
        AgreementTextFormatter.shouldShowToggle(
            for: labelText,
            label: label,
            widthFallback: UIScreen.main.bounds.width - 64
        )
    }

    private func collapsedPreview(from text: String) -> String {
        let cleanText = text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let width = label.bounds.width > 0
            ? label.bounds.width
            : max(UIScreen.main.bounds.width - 64, 240)
        let font = Constant.Font.geistRegular(size: 10)
        let maxHeight = ceil(font.lineHeight * CGFloat(collapsedLines))

        func height(for value: String) -> CGFloat {
            (value as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).height
        }

        guard height(for: cleanText) > maxHeight else {
            return cleanText
        }

        var low = 0
        var high = cleanText.count
        var best = ""

        while low <= high {
            let mid = (low + high) / 2
            let endIndex = cleanText.index(cleanText.startIndex, offsetBy: mid)
            let candidate = String(cleanText[..<endIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let display = "\(candidate)..."

            if height(for: display) <= maxHeight {
                best = candidate
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return best.isEmpty ? "..." : "\(best)..."
    }

    private func collapsedHeight(for font: UIFont) -> CGFloat {
        AgreementTextFormatter.collapsedHeight()
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

        handleExpansionTap()
    }

    @objc private func handleExpansionTap() {
        isExpanded.toggle()
        UIView.performWithoutAnimation {
            updateLabelText()
            layoutIfNeeded()
            superview?.layoutIfNeeded()
            onExpansionChanged?()
        }
    }
}
