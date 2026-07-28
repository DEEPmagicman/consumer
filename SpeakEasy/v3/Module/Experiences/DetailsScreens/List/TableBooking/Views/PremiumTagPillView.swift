//
//  PremiumTagPillView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 26/06/26.
//

import UIKit

private enum PremiumTableCornerRadius {
    static let card: CGFloat = 14
    static let field: CGFloat = 9
}

// MARK: - PremiumTagPillView
/// Small pill with icon + text  e.g. "10-14 guests"

final class PremiumTagPillView: UIView {

    private let glassView = LiquidGlassBackgroundView(
        cornerRadius: 14,
        fillColor: UIColor.white.withAlphaComponent(0.05),
        borderColor: UIColor.white.withAlphaComponent(0.10),
        borderWidth: 0.8
    )
    private let iconView  = UIImageView()
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear
        clipsToBounds = false

        glassView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassView)

        iconView.tintColor      = .white
        iconView.contentMode    = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        textLabel.font      = Constant.Font.geistMedium(size: 10)
        textLabel.textColor = .white
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(textLabel)

        NSLayoutConstraint.activate([
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 12),
            iconView.heightAnchor.constraint(equalToConstant: 12),

            textLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    func configure(icon: String, text: String) {
        iconView.image = UIImage(named: icon)
        textLabel.text = text
    }

    func configure(style: PremiumInfoPillView.Style, text: String) {
        textLabel.text = text
        switch style {
        case .guests:
            iconView.image = UIImage(resource: .guestIcon).withRenderingMode(.alwaysTemplate)
        case .time:
            iconView.image = UIImage(resource: .clockIcon).withRenderingMode(.alwaysTemplate)
        }
    }
}

// MARK: - PremiumStepperRow
/// Dark card row with icon, title, and −/count/+ stepper on right

final class PremiumStepperRow: UIView {

    var onValueChanged: ((Int) -> Void)?

    private var minValue = 1
    private var maxValue = 100
    private var count    = 1

    private let cardView   = GradientBorderCardView()
    private let iconView   = UIImageView()
    private let titleLabel = UILabel()
    private let minusBtn   = UIButton(type: .system)
    private let countLabel = UILabel()
    private let plusBtn    = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.glassCornerRadius = PremiumTableCornerRadius.card
    }

    func configure(icon: UIImage?, title: String) {
        iconView.image = icon
        titleLabel.text = title
    }

    func setValue(_ val: Int, min: Int, max: Int) {
        minValue   = min
        maxValue   = max
        count      = val
        countLabel.text = "\(count)"
        updateButtons()
    }

    private func setup() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.fillColor = UIColor.white.withAlphaComponent(0.06).cgColor
        cardView.showsBlur = true
        cardView.blurAlpha = 0.4
        cardView.thinBorder = true
        addSubview(cardView)

        iconView.tintColor   = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconView)

        titleLabel.font      = Constant.Font.geistRegular(size: 16)
        titleLabel.textColor = UIColor.white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        func configureStepperButton(_ button: UIButton, title: String, imageName: String, action: Selector) {
            button.setTitle(nil, for: .normal)
            if let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate) {
                button.setImage(image, for: .normal)
                button.tintColor = .white
            } else {
                button.setTitle(title, for: .normal)
                button.setTitleColor(.white, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .light)
            }
            button.backgroundColor = UIColor.black.withAlphaComponent(0.24)
            button.layer.cornerRadius = 7
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.withAlphaComponent(0.09).cgColor
            button.clipsToBounds = true
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: action, for: .touchUpInside)
        }

        configureStepperButton(minusBtn, title: "−", imageName: "minusIcon", action: #selector(onMinus))
        configureStepperButton(plusBtn, title: "+", imageName: "pluseIcon", action: #selector(onPlus))

        countLabel.font          = Constant.Font.geistMedium(size: 17)
        countLabel.textColor     = .white
        countLabel.textAlignment = .center
        countLabel.text          = "\(count)"
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        [minusBtn, countLabel, plusBtn].forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            plusBtn.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            plusBtn.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            plusBtn.widthAnchor.constraint(equalToConstant: 32),
            plusBtn.heightAnchor.constraint(equalToConstant: 32),

            countLabel.trailingAnchor.constraint(equalTo: plusBtn.leadingAnchor, constant: -4),
            countLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 32),

            minusBtn.trailingAnchor.constraint(equalTo: countLabel.leadingAnchor, constant: -4),
            minusBtn.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            minusBtn.widthAnchor.constraint(equalToConstant: 32),
            minusBtn.heightAnchor.constraint(equalToConstant: 32)
        ])

        updateButtons()
    }

    private func updateButtons() {
        minusBtn.isEnabled = count > minValue
        plusBtn.isEnabled = count < maxValue
        minusBtn.alpha = minusBtn.isEnabled ? 1 : 0.45
        plusBtn.alpha = plusBtn.isEnabled ? 1 : 0.45
    }

    @objc private func onMinus() {
        guard count > minValue else { return }
        count -= 1
        AppHaptic.stepperChanged()
        countLabel.text = "\(count)"
        updateButtons()
        onValueChanged?(count)
    }

    @objc private func onPlus() {
        guard count < maxValue else { return }
        count += 1
        AppHaptic.stepperChanged()
        countLabel.text = "\(count)"
        updateButtons()
        onValueChanged?(count)
    }
}

// MARK: - PremiumArrivalTimeOption

struct PremiumArrivalTimeOption {
    let id: String?
    let title: String
}

// MARK: - PremiumArrivalTimeView

final class PremiumArrivalTimeView: UIView {

    var onSelectionChanged: ((Int) -> Void)?

    private let cardView = GradientBorderCardView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let selectedTimeView = UIView()
    private let selectedTimeLabel = UILabel()
    private let availableLabel = UILabel()
    private let chipsStack = UIStackView()

    private var options: [PremiumArrivalTimeOption] = []
    private var selectedIndex = 0
    private var accentColor = UIColor(hex: "#A64BA0")
    private var lastLayoutWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.glassCornerRadius = PremiumTableCornerRadius.card

        let width = bounds.width
        guard abs(width - lastLayoutWidth) > 0.5 else { return }
        lastLayoutWidth = width
        rebuildChips(maxContentWidth: max(0, width - 32))
    }

    override var intrinsicContentSize: CGSize {
        let fallbackWidth = UIScreen.main.bounds.width - 40
        let width = bounds.width > 0 ? bounds.width : fallbackWidth
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: preferredHeight(for: width)
        )
    }

    func configure(
        options: [PremiumArrivalTimeOption],
        selectedIndex: Int,
        accentColor: UIColor?
    ) {
        self.options = options
        self.selectedIndex = min(max(selectedIndex, 0), max(options.count - 1, 0))
        if let accentColor {
            self.accentColor = accentColor
        }
        selectedTimeLabel.text = options.indices.contains(self.selectedIndex)
            ? options[self.selectedIndex].title
            : ""
        availableLabel.isHidden = options.isEmpty
        chipsStack.isHidden = options.isEmpty
        rebuildChips(maxContentWidth: max(0, bounds.width - 32))
        invalidateIntrinsicContentSize()
    }

    func preferredHeight(for width: CGFloat) -> CGFloat {
        guard !options.isEmpty else { return 0 }

        let contentWidth = max(0, width - 32)
        let rows = makeChipRows(maxContentWidth: contentWidth).count
        let chipHeight: CGFloat = 32
        let rowSpacing: CGFloat = 8
        let chipsHeight = CGFloat(rows) * chipHeight + CGFloat(max(rows - 1, 0)) * rowSpacing

        return 56 + 12 + 18 + 10 + chipsHeight + 16
    }

    private func setup() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.fillColor = UIColor.white.withAlphaComponent(0.06).cgColor
        cardView.showsBlur = true
        cardView.blurAlpha = 0.4
        cardView.thinBorder = true
        addSubview(cardView)

        iconView.image = UIImage(resource: .icClock1).withRenderingMode(.alwaysTemplate)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconView)

        titleLabel.text = "Arrival Time"
        titleLabel.font = Constant.Font.geistRegular(size: 16)
        titleLabel.textColor = UIColor.white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        selectedTimeView.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        selectedTimeView.layer.cornerRadius = PremiumTableCornerRadius.field
        selectedTimeView.layer.borderWidth = 1
        selectedTimeView.layer.borderColor = UIColor.white.withAlphaComponent(0.09).cgColor
        selectedTimeView.clipsToBounds = true
        selectedTimeView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(selectedTimeView)

        selectedTimeLabel.font = Constant.Font.geistRegular(size: 16)
        selectedTimeLabel.textColor = .white
        selectedTimeLabel.textAlignment = .center
        selectedTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedTimeView.addSubview(selectedTimeLabel)

        availableLabel.text = "Available times"
        availableLabel.font = Constant.Font.geistMedium(size: 14)
        availableLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        availableLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(availableLabel)

        chipsStack.axis = .vertical
        chipsStack.spacing = 8
        chipsStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(chipsStack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

            selectedTimeView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            selectedTimeView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            selectedTimeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 104),
            selectedTimeView.heightAnchor.constraint(equalToConstant: 36),
            selectedTimeView.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),

            selectedTimeLabel.leadingAnchor.constraint(equalTo: selectedTimeView.leadingAnchor, constant: 12),
            selectedTimeLabel.trailingAnchor.constraint(equalTo: selectedTimeView.trailingAnchor, constant: -12),
            selectedTimeLabel.centerYAnchor.constraint(equalTo: selectedTimeView.centerYAnchor),

            availableLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 68),
            availableLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            availableLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            chipsStack.topAnchor.constraint(equalTo: availableLabel.bottomAnchor, constant: 10),
            chipsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            chipsStack.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -16),
            chipsStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }

    private func rebuildChips(maxContentWidth: CGFloat) {
        chipsStack.arrangedSubviews.forEach {
            chipsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard maxContentWidth > 0, !options.isEmpty else { return }

        let rows = makeChipRows(maxContentWidth: maxContentWidth)
        rows.forEach { rowItems in
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.alignment = .fill
            row.distribution = .fill
            row.translatesAutoresizingMaskIntoConstraints = false

            rowItems.forEach { item in
                let button = makeChipButton(index: item.index, title: item.title)
                button.widthAnchor.constraint(equalToConstant: item.width).isActive = true
                button.heightAnchor.constraint(equalToConstant: 32).isActive = true
                row.addArrangedSubview(button)
            }

            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            row.addArrangedSubview(spacer)

            chipsStack.addArrangedSubview(row)
        }

        invalidateIntrinsicContentSize()
    }

    private func makeChipRows(maxContentWidth: CGFloat) -> [[(index: Int, title: String, width: CGFloat)]] {
        var rows: [[(index: Int, title: String, width: CGFloat)]] = []
        var currentRow: [(index: Int, title: String, width: CGFloat)] = []
        var currentWidth: CGFloat = 0
        let spacing: CGFloat = 8

        for (index, option) in options.enumerated() {
            let textWidth = option.title.size(
                withAttributes: [.font: Constant.Font.geistRegular(size: 14)]
            ).width
            let columnCount: CGFloat = maxContentWidth >= 300 ? 3 : 2
            let columnWidth = floor((maxContentWidth - spacing * (columnCount - 1)) / columnCount)
            let width = min(max(textWidth + 24, columnWidth), maxContentWidth)
            let nextWidth = currentRow.isEmpty ? width : currentWidth + spacing + width

            if nextWidth > maxContentWidth, !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [(index: index, title: option.title, width: width)]
                currentWidth = width
            } else {
                currentRow.append((index: index, title: option.title, width: width))
                currentWidth = nextWidth
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private func makeChipButton(index: Int, title: String) -> UIButton {
        let button = UIButton(type: .system)
        let isSelected = index == selectedIndex
        button.tag = index
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = Constant.Font.geistMedium(size: 14)
        button.setTitleColor(isSelected ? accentColor.suitableTextColor() : UIColor(hex: "#121212"), for: .normal)
        button.backgroundColor = isSelected ? accentColor : UIColor(hex: "#E3E3E7")
        button.layer.cornerRadius = PremiumTableCornerRadius.field
        button.layer.borderWidth = isSelected ? 0 : 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.09).cgColor
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(onChipTap(_:)), for: .touchUpInside)
        return button
    }

    @objc private func onChipTap(_ sender: UIButton) {
        guard options.indices.contains(sender.tag) else { return }
        AppHaptic.selectionChanged()
        selectedIndex = sender.tag
        selectedTimeLabel.text = options[selectedIndex].title
        rebuildChips(maxContentWidth: max(0, bounds.width - 32))
        onSelectionChanged?(selectedIndex)
    }
}

// MARK: - PremiumPriceCard
/// Dark card showing "$1000 minimum" on left, "$1,048.00 deposit incl. fees" on right

enum TableBookingMoneyFormatter {

    static func amount(_ value: Double, symbol: String, position: String?, wholeNumber: Bool = false) -> String {
        let absoluteValue = abs(value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = wholeNumber ? 0 : 2
        formatter.maximumFractionDigits = wholeNumber ? 0 : 2

        let formattedAmount = formatter.string(from: NSNumber(value: absoluteValue)) ?? "\(absoluteValue)"
        let normalizedPosition = position?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if normalizedPosition == "right" || normalizedPosition == "suffix" || normalizedPosition == "after" {
            return "\(formattedAmount)\(symbol)"
        }

        return "\(symbol)\(formattedAmount)"
    }
}

final class PremiumPriceCard: UIView {

    private let card       = GradientBorderCardView()
    private let minLabel   = UILabel()
    private let minSub     = UILabel()
    private let depLabel   = UILabel()
    private let depSub     = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        card.glassCornerRadius = PremiumTableCornerRadius.card
    }

    func configure(minimum: Double, deposit: Double, currency: String = "$", currencyPosition: String? = "") {
        minLabel.text = TableBookingMoneyFormatter.amount(minimum, symbol: currency, position: currencyPosition, wholeNumber: true)
        depLabel.text = TableBookingMoneyFormatter.amount(deposit, symbol: currency, position: currencyPosition)
    }

    private func setup() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = UIColor.white.withAlphaComponent(0.06).cgColor
        card.showsBlur = true
        card.blurAlpha = 0.4
        card.thinBorder = true
        addSubview(card)

        minLabel.font      = Constant.Font.geistMedium(size: 20)
        minLabel.textColor = .white
        minLabel.translatesAutoresizingMaskIntoConstraints = false

        minSub.text      = "minimum"
        minSub.font      = Constant.Font.geistRegular(size: 11)
        minSub.textColor = UIColor.white.withAlphaComponent(0.5)
        minSub.translatesAutoresizingMaskIntoConstraints = false

        depLabel.font          = Constant.Font.geistMedium(size: 20)
        depLabel.textColor     = .white
        depLabel.textAlignment = .right
        depLabel.translatesAutoresizingMaskIntoConstraints = false

        depSub.text          = "deposit incl. fees"
        depSub.font          = Constant.Font.geistRegular(size: 11)
        depSub.textColor     = UIColor.white.withAlphaComponent(0.5)
        depSub.textAlignment = .right
        depSub.translatesAutoresizingMaskIntoConstraints = false

        [minLabel, minSub, depLabel, depSub].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),

            minLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            minLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            minSub.topAnchor.constraint(equalTo: minLabel.bottomAnchor, constant: 2),
            minSub.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            depLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            depLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            depSub.topAnchor.constraint(equalTo: depLabel.bottomAnchor, constant: 2),
            depSub.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
    }
}

// MARK: - PremiumInfoRow
/// Single-line dark card row: icon | title on left, value on right, chevron

final class PremiumInfoRow: UIView {

    private let card       = GradientBorderCardView()
    private let iconView   = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        card.glassCornerRadius = PremiumTableCornerRadius.card
    }

    func configure(icon: UIImage?, title: String, value: String) {
        iconView.image  = icon?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = title
        valueLabel.text = value
    }

    private func setup() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = UIColor.white.withAlphaComponent(0.06).cgColor
        card.showsBlur = true
        card.blurAlpha = 0.4
        card.thinBorder = true
        addSubview(card)

        iconView.tintColor   = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconView)

        titleLabel.font      = Constant.Font.geistRegular(size: 16)
        titleLabel.textColor = UIColor.white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        valueLabel.font          = Constant.Font.geistMedium(size: 15)
        valueLabel.textColor     = .white
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            valueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
    }
}

// MARK: - PremiumNoteInputView

final class PremiumNoteInputView: UIView {

    var onHeightChanged: ((CGFloat) -> Void)?

    var preferredHeight: CGFloat {
        isExpanded ? 124 : 56
    }

    var noteText: String {
        let value = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return value == placeholder ? "" : value
    }

    private let card       = GradientBorderCardView()
    private let iconView   = UIImageView()
    private let titleLabel = UILabel()
    private let textView   = UITextView()
    private let placeholder = "Add a note (optional)"
    private var isExpanded = false
    private var textTopConstraint: NSLayoutConstraint?
    private var textBottomConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        card.glassCornerRadius = PremiumTableCornerRadius.card
    }

    private func setup() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = UIColor.white.withAlphaComponent(0.06).cgColor
        card.showsBlur = true
        card.blurAlpha = 0.4
        card.thinBorder = true
        addSubview(card)

        iconView.image = UIImage(systemName: "plus")
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconView)

        titleLabel.text = "Add a note"
        titleLabel.font = Constant.Font.geistRegular(size: 15)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        textView.text = placeholder
        textView.delegate = self
        textView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        textView.textColor = UIColor.white.withAlphaComponent(0.45)
        textView.tintColor = .white
        textView.font = Constant.Font.geistRegular(size: 13)
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.layer.cornerRadius = PremiumTableCornerRadius.field
        textView.layer.borderWidth = 0.8
        textView.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        textView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onNoteTap(_:)))
        tap.cancelsTouchesInView = false
        card.addGestureRecognizer(tap)

        let textTop = textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12)
        let textBottom = textView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        textTopConstraint = textTop
        textBottomConstraint = textBottom

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            textTop,
            textView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            textBottom
        ])

        setExpanded(false, animated: false)
    }

    func setExpanded(_ expanded: Bool, animated: Bool) {
        isExpanded = expanded
        textView.isHidden = !expanded
        textTopConstraint?.isActive = expanded
        textBottomConstraint?.isActive = expanded
        iconView.transform = expanded ? CGAffineTransform(rotationAngle: .pi / 4) : .identity
        onHeightChanged?(preferredHeight)
        self.superview?.layoutIfNeeded()
        if expanded {
            textView.becomeFirstResponder()
        } else {
            textView.resignFirstResponder()
        }
    }

    @objc private func onNoteTap(_ gesture: UITapGestureRecognizer) {
        if isExpanded, textView.frame.contains(gesture.location(in: card)) {
            return
        }
        setExpanded(!isExpanded, animated: false)
    }
}

// MARK: - PremiumAgreementView

final class PremiumAgreementView: UIView {

    enum Style {
        case plain
        case darkCard
        case whiteCard
    }

    var onHeightChanged: ((CGFloat, Bool) -> Void)?

    var preferredHeight: CGFloat {
        calculatedHeight()
    }

    var isChecked: Bool = true {
        didSet { updateCheckbox() }
    }

    var showsCheckbox: Bool = true {
        didSet { updateCheckboxVisibility() }
    }

    var bodyText: String = "" {
        didSet {
            isExpanded = false
            updateText()
        }
    }

    var bodyAttributedText: NSAttributedString? {
        didSet {
            updateText()
        }
    }

    var titleText: String? {
        didSet {
            titleLabel.text = titleText
            titleLabel.isHidden = (titleText ?? "").isEmpty
            titleTopConstraint?.isActive = !(titleText ?? "").isEmpty
            bodyTopToTitleConstraint?.isActive = !(titleText ?? "").isEmpty
            bodyTopToContainerConstraint?.isActive = (titleText ?? "").isEmpty
            updateText()
        }
    }

    var onToggle: ((Bool) -> Void)?
    var style: Style = .plain {
        didSet {
            applyStyle()
            updateText()
        }
    }
    var preservesLinks = false {
        didSet { updateText() }
    }

    private let checkButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let toggleButton = UIButton(type: .system)
    private let collapsedLines = AgreementTextFormatter.collapsedLines
    private var isExpanded = false
    private var lastReportedHeight: CGFloat = 0
    private var lastLaidOutBodyWidth: CGFloat = 0
    private var titleTopConstraint: NSLayoutConstraint?
    private var bodyTopToTitleConstraint: NSLayoutConstraint?
    private var bodyTopToContainerConstraint: NSLayoutConstraint?
    private var titleLeadingToCheckboxConstraint: NSLayoutConstraint?
    private var titleLeadingToContainerConstraint: NSLayoutConstraint?
    private var toggleTopConstraint: NSLayoutConstraint?
    private var toggleHeightConstraint: NSLayoutConstraint?
    private var checkLeadingConstraint: NSLayoutConstraint?
    private var checkTopConstraint: NSLayoutConstraint?
    private var titleTrailingConstraint: NSLayoutConstraint?
    private var bodyTrailingConstraint: NSLayoutConstraint?
    private var toggleTrailingConstraint: NSLayoutConstraint?
    private var toggleBottomConstraint: NSLayoutConstraint?
    private var contentInsets: UIEdgeInsets {
        switch style {
        case .plain:
            return .zero
        case .darkCard:
            return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        case .whiteCard:
            return UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        }
    }
    private var bodyColor: UIColor {
        switch style {
        case .whiteCard:
            return .black
        case .plain, .darkCard:
            return UIColor.white.withAlphaComponent(0.82)
        }
    }
    private var toggleColor: UIColor {
        switch style {
        case .whiteCard:
            return .black
        case .plain, .darkCard:
            return UIColor.white
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard abs(bodyLabel.bounds.width - lastLaidOutBodyWidth) > 0.5 else { return }
        lastLaidOutBodyWidth = bodyLabel.bounds.width
        updateText()
    }

    private func setup() {
        backgroundColor = .clear
        layer.cornerCurve = .continuous

        checkButton.tintColor = .white
        checkButton.imageView?.tintColor = .white
        checkButton.translatesAutoresizingMaskIntoConstraints = false
        checkButton.addTarget(self, action: #selector(onCheckTap), for: .touchUpInside)
        addSubview(checkButton)

        titleLabel.font = Constant.Font.geistMedium(size: 12)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        AgreementTextFormatter.configure(bodyLabel)
        bodyLabel.isUserInteractionEnabled = true
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bodyLabel)

        let bodyTap = UITapGestureRecognizer(target: self, action: #selector(onBodyTap(_:)))
        bodyLabel.addGestureRecognizer(bodyTap)

        toggleButton.contentHorizontalAlignment = .leading
        toggleButton.setTitleColor(.white, for: .normal)
        toggleButton.titleLabel?.font = Constant.Font.geistSemiBold(size: 10)
        toggleButton.isHidden = true
        toggleButton.isUserInteractionEnabled = false
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.addTarget(self, action: #selector(onToggleTap), for: .touchUpInside)
        addSubview(toggleButton)

        let titleTop = titleLabel.topAnchor.constraint(equalTo: topAnchor)
        let bodyToTitle = bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6)
        let bodyToContainer = bodyLabel.topAnchor.constraint(equalTo: topAnchor)
        titleTopConstraint = titleTop
        bodyTopToTitleConstraint = bodyToTitle
        bodyTopToContainerConstraint = bodyToContainer
        let toggleTop = toggleButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 0)
        let toggleHeight = toggleButton.heightAnchor.constraint(equalToConstant: 0)
        toggleTopConstraint = toggleTop
        toggleHeightConstraint = toggleHeight

        let titleToCheckbox = titleLabel.leadingAnchor.constraint(equalTo: checkButton.trailingAnchor, constant: 8)
        let titleToContainer = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        titleLeadingToCheckboxConstraint = titleToCheckbox
        titleLeadingToContainerConstraint = titleToContainer
        let checkLeading = checkButton.leadingAnchor.constraint(equalTo: leadingAnchor)
        let checkTop = checkButton.topAnchor.constraint(equalTo: topAnchor)
        let titleTrailing = titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        let bodyTrailing = bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        let toggleTrailing = toggleButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        let toggleBottom = toggleButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        checkLeadingConstraint = checkLeading
        checkTopConstraint = checkTop
        titleTrailingConstraint = titleTrailing
        bodyTrailingConstraint = bodyTrailing
        toggleTrailingConstraint = toggleTrailing
        toggleBottomConstraint = toggleBottom

        NSLayoutConstraint.activate([
            checkLeading,
            checkTop,
            checkButton.widthAnchor.constraint(equalToConstant: 24),
            checkButton.heightAnchor.constraint(equalToConstant: 24),

            titleToCheckbox,
            titleTrailing,
            titleTop,

            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyTrailing,
            bodyToTitle,
            toggleButton.leadingAnchor.constraint(equalTo: bodyLabel.leadingAnchor),
            toggleTrailing,
            toggleTop,
            toggleHeight,
            toggleBottom
        ])

        applyStyle()
        updateCheckbox()
        updateCheckboxVisibility()
    }

    private func updateCheckbox() {
        let image = (isChecked ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon)?
            .withRenderingMode(.alwaysTemplate)
        checkButton.setImage(image, for: .normal)
        let tint: UIColor = style == .whiteCard ? UIColor(hex: "#444444") : .white
        checkButton.tintColor = tint
        checkButton.imageView?.tintColor = tint
    }

    private func applyStyle() {
        switch style {
        case .plain:
            backgroundColor = .clear
            layer.cornerRadius = 0
            titleLabel.textColor = .white
        case .darkCard:
            backgroundColor = UIColor(hex: "#272727", alpha: 0.5)
            layer.cornerRadius = 8
            titleLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        case .whiteCard:
            backgroundColor = .white
            layer.cornerRadius = 6
            titleLabel.textColor = .black
        }
        toggleButton.setTitleColor(toggleColor, for: .normal)
        checkLeadingConstraint?.constant = contentInsets.left
        checkTopConstraint?.constant = contentInsets.top
        titleTopConstraint?.constant = contentInsets.top
        bodyTopToContainerConstraint?.constant = contentInsets.top
        titleLeadingToContainerConstraint?.constant = contentInsets.left
        titleTrailingConstraint?.constant = -contentInsets.right
        bodyTrailingConstraint?.constant = -contentInsets.right
        toggleTrailingConstraint?.constant = -contentInsets.right
        toggleBottomConstraint?.constant = -contentInsets.bottom
        updateCheckbox()
        invalidateIntrinsicContentSize()
        reportHeightIfNeeded()
    }

    private func updateCheckboxVisibility() {
        checkButton.isHidden = !showsCheckbox
        checkButton.isUserInteractionEnabled = showsCheckbox
        titleLeadingToCheckboxConstraint?.isActive = showsCheckbox
        titleLeadingToContainerConstraint?.isActive = !showsCheckbox
        setNeedsLayout()
        reportHeightIfNeeded()
    }

    private func updateText() {
        guard !bodyText.isEmpty else {
            bodyLabel.attributedText = nil
            bodyLabel.text = ""
            bodyLabel.numberOfLines = 0
            updateToggleButton(isVisible: false, title: nil)
            reportHeightIfNeeded(animated: false)
            return
        }

        _ = AgreementTextFormatter.apply(
            to: bodyLabel,
            text: bodyText,
            isExpanded: isExpanded,
            widthFallback: bodyWidthFallback(),
            allowsViewMore: !showsCheckbox,
            expandedAttributedText: bodyAttributedText,
            preservesLinks: preservesLinks || style != .plain
        )
        applyTextColor()
        updateToggleButton(isVisible: false, title: nil)
        invalidateIntrinsicContentSize()
        reportHeightIfNeeded(animated: false)
        superview?.setNeedsLayout()
    }

    private func updateToggleButton(isVisible: Bool, title: String?) {
        toggleButton.isHidden = true
        toggleButton.setTitle(title, for: .normal)
        toggleTopConstraint?.constant = 0
        toggleHeightConstraint?.constant = 0
    }

    private func reportHeightIfNeeded(animated: Bool = false) {
        let height = preferredHeight
        guard abs(height - lastReportedHeight) > 0.5 else { return }
        lastReportedHeight = height
        onHeightChanged?(height, animated)
    }

    private func calculatedHeight() -> CGFloat {
        let title = titleText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let body = bodyLabel.attributedText?.string.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? bodyText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty || !body.isEmpty else { return 0 }

        let width = bodyLabel.bounds.width > 0
            ? bodyLabel.bounds.width
            : bodyWidthFallback()

        var height = contentInsets.top + contentInsets.bottom
        if !title.isEmpty {
            height += ceil(Constant.Font.geistMedium(size: 12).lineHeight)
        }

        if !body.isEmpty {
            if !title.isEmpty { height += 6 }
            let bodyFont = Constant.Font.geistRegular(size: 10)
            let needsToggle = shouldShowToggle()
            let bodyHeight = bodyLabel.attributedText?.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).height ?? (body as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: bodyFont],
                context: nil
            ).height
            height += ((isExpanded || !needsToggle) ? ceil(bodyHeight) : collapsedHeight(for: bodyFont)) + 6
        }

        return max(contentInsets.top + contentInsets.bottom + 24, height)
    }

    private func applyTextColor() {
        guard let attributedText = bodyLabel.attributedText else {
            bodyLabel.textColor = bodyColor
            return
        }
        let mutable = NSMutableAttributedString(attributedString: attributedText)
        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.addAttribute(.foregroundColor, value: bodyColor, range: fullRange)
        mutable.enumerateAttribute(.link, in: fullRange, options: []) { value, range, _ in
            if value != nil {
                mutable.addAttributes([
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: range)
            }
        }
        bodyLabel.attributedText = mutable
    }

    private func shouldShowToggle() -> Bool {
        AgreementTextFormatter.shouldShowToggle(
            for: bodyText,
            label: bodyLabel,
            widthFallback: bodyWidthFallback()
        )
    }

    private func bodyWidthFallback() -> CGFloat {
        let availableWidth = bounds.width > 0
            ? bounds.width
            : UIScreen.main.bounds.width - 40
        let checkboxWidth: CGFloat = showsCheckbox ? 32 : 0
        return max(availableWidth - contentInsets.left - contentInsets.right - checkboxWidth, 220)
    }

    private func collapsedPreview() -> String {
        let width = bodyLabel.bounds.width > 0 ? bodyLabel.bounds.width : max(UIScreen.main.bounds.width - 64, 240)
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

        guard height(for: bodyText) > maxHeight else {
            return bodyText
        }

        var low = 0
        var high = bodyText.count
        var best = ""

        while low <= high {
            let mid = (low + high) / 2
            let endIndex = bodyText.index(bodyText.startIndex, offsetBy: mid)
            let candidate = String(bodyText[..<endIndex])
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

    @objc private func onCheckTap() {
        isChecked.toggle()
        AppHaptic.selectionChanged()
        onToggle?(isChecked)
    }

    @objc private func onBodyTap(_ gesture: UITapGestureRecognizer) {
        if openLinkIfNeeded(from: gesture) {
            return
        }
        guard shouldShowToggle() else { return }
        toggleExpansion()
    }

    @objc private func onToggleTap() {
        guard shouldShowToggle() else { return }
        toggleExpansion()
    }

    private func toggleExpansion() {
        isExpanded.toggle()
        AppHaptic.selectionChanged()
        UIView.performWithoutAnimation {
            updateText()
            layoutIfNeeded()
            superview?.layoutIfNeeded()
        }
    }

    private func openLinkIfNeeded(from gesture: UITapGestureRecognizer) -> Bool {
        guard let attributedText = bodyLabel.attributedText else { return false }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bodyLabel.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = bodyLabel.lineBreakMode
        textContainer.maximumNumberOfLines = bodyLabel.numberOfLines
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let index = layoutManager.characterIndex(
            for: gesture.location(in: bodyLabel),
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        guard index < attributedText.length else { return false }

        let attrs = attributedText.attributes(at: index, effectiveRange: nil)
        if let url = attrs[.link] as? URL {
            UIApplication.shared.open(url)
            return true
        }
        if let value = attrs[.link] as? String,
           let url = URL(string: value) {
            UIApplication.shared.open(url)
            return true
        }
        return false
    }
}

extension PremiumNoteInputView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholder {
            textView.text = ""
            textView.textColor = .white
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.white.withAlphaComponent(0.45)
        }
    }
}

// MARK: - SpendLineItem model

struct SpendLineItem {
    let title: String
    let amount: Double
    let isBold: Bool
}

// MARK: - PremiumSpendAgreementView
/// Collapsible "Spend Agreement" card with line items from API

final class PremiumSpendAgreementView: UIView {

    var onHeightChanged: ((CGFloat, Bool) -> Void)?

    var preferredHeight: CGFloat {
        guard itemCount > 0 else { return 0 }
        guard isExpanded else { return 52 }
        let rowsHeight = CGFloat(itemCount * 20)
        let spacingHeight = CGFloat(max(itemCount - 1, 0) * 10)
        return 52 + 0.5 + 14 + rowsHeight + spacingHeight + 14
    }

    private let card        = GradientBorderCardView()
    private let headerView  = UIView()
    private let headerLabel = UILabel()
    private let chevron     = UIImageView()
    private let stackView   = UIStackView()
    private let divider     = UIView()

    private var isExpanded  = false
    private var currency    = "$"
    private var currencyPosition: String? = ""
    private var itemCount   = 0
    private var stackTopConstraint: NSLayoutConstraint?
    private var stackBottomConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        card.glassCornerRadius = PremiumTableCornerRadius.card
    }

    func configure(
        currency: String,
        currencyPosition: String?,
        title: String = "Spend Agreement",
        items: [SpendLineItem],
        expanded: Bool = false
    ) {
        self.currency = currency
        self.currencyPosition = currencyPosition
        headerLabel.text = title
        itemCount = items.count
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        items.forEach { item in
            let row = makeRow(title: item.title, amount: item.amount, bold: item.isBold)
            stackView.addArrangedSubview(row)
        }
        isHidden = items.isEmpty
        setExpanded(expanded, animated: false)
    }

    private func setup() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = UIColor.white.withAlphaComponent(0.06).cgColor
        card.showsBlur = true
        card.blurAlpha = 0.4
        card.thinBorder = true
        addSubview(card)

        // Header
        headerLabel.text      = "Spend Agreement"
        headerLabel.font      = Constant.Font.geistMedium(size: 15)
        headerLabel.textColor = .white
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        chevron.image          = UIImage(named: "arrowTopIcon")?.withRenderingMode(.alwaysTemplate)
        chevron.tintColor      = UIColor.white.withAlphaComponent(0.65)
        chevron.contentMode    = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerLabel)
        headerView.addSubview(chevron)
        card.addSubview(headerView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleExpand))
        headerView.addGestureRecognizer(tap)

        // Divider
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.isHidden = true
        card.addSubview(divider)

        // Stack
        stackView.axis    = .vertical
        stackView.spacing = 10
        stackView.isHidden = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stackView)

        let stackTop = stackView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14)
        let stackBottom = stackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        stackTopConstraint = stackTop
        stackBottomConstraint = stackBottom

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),

            headerView.topAnchor.constraint(equalTo: card.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 9),
            chevron.heightAnchor.constraint(equalToConstant: 6),

            divider.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            stackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
    }

    private func makeRow(title: String, amount: Double, bold: Bool) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let t = UILabel()
        t.text      = title
        t.font      = bold ? Constant.Font.geistMedium(size: 14) : Constant.Font.geistRegular(size: 14)
        let isDiscount = amount < 0
        t.textColor = isDiscount ? .systemGreen : .white
        t.translatesAutoresizingMaskIntoConstraints = false

        let v = UILabel()
        let formatted = amount == 0 && title.lowercased().contains("balance")
            ? TableBookingMoneyFormatter.amount(0, symbol: currency, position: currencyPosition)
            : (amount < 0
               ? "-\(TableBookingMoneyFormatter.amount(amount, symbol: currency, position: currencyPosition))"
               : TableBookingMoneyFormatter.amount(amount, symbol: currency, position: currencyPosition))
        v.text          = formatted
        v.font          = bold ? Constant.Font.geistMedium(size: 14) : Constant.Font.geistRegular(size: 14)
        v.textColor     = isDiscount ? .systemGreen : .white
        v.textAlignment = .right
        v.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(t)
        row.addSubview(v)

        NSLayoutConstraint.activate([
            t.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            t.topAnchor.constraint(equalTo: row.topAnchor),
            t.bottomAnchor.constraint(equalTo: row.bottomAnchor),

            v.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            v.topAnchor.constraint(equalTo: row.topAnchor),
            v.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            v.heightAnchor.constraint(equalToConstant: 20)
        ])
        return row
    }

    @objc private func toggleExpand() {
        AppHaptic.selectionChanged()
        setExpanded(!isExpanded, animated: true)
    }

    private func setExpanded(_ expanded: Bool, animated: Bool) {
        isExpanded = expanded
        let rotate: CGFloat = expanded ? 0 : .pi

        if expanded {
            divider.isHidden = false
            stackView.isHidden = false
            divider.alpha = animated ? 0 : 1
            stackView.alpha = animated ? 0 : 1
        }

        stackTopConstraint?.isActive = expanded
        stackBottomConstraint?.isActive = expanded
        onHeightChanged?(preferredHeight, animated)

        let updates = {
            self.divider.alpha = expanded ? 1 : 0
            self.stackView.alpha = expanded ? 1 : 0
            self.chevron.transform = CGAffineTransform(rotationAngle: rotate)
        }

        let completion: (Bool) -> Void = { _ in
            self.divider.isHidden = !expanded
            self.stackView.isHidden = !expanded
            self.divider.alpha = 1
            self.stackView.alpha = 1
        }

        guard animated else {
            updates()
            completion(true)
            return
        }

        UIView.animate(
            withDuration: 0.24,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: updates,
            completion: completion
        )
    }
}

final class PremiumPromoRow: UIView {

    var onSubmit: ((String) -> Void)?
    var onRemove: (() -> Void)?
    var onHeightChanged: ((CGFloat) -> Void)?

    var preferredHeight: CGFloat {
        if isApplied { return 44 }
        return isExpanded ? 126 : 60
    }

    private let card              = UIView()
    private let titleRow          = UIView()
    private let titleTapButton    = UIButton(type: .system)
    private let promoLabel        = UILabel()
    private let actionButton      = UIButton(type: .system)
    private let inputRow          = UIView()
    private let textFieldWrapper  = UIView()
    private let textField         = UITextField()
    private let applyButton       = UIButton(type: .system)
    private let applyLoader       = UIActivityIndicatorView(style: .medium)
    private let removeRow         = UIView()
    private let appliedFieldWrap  = UIView()
    private let appliedCode       = UITextField()
    private let removeButton      = UIButton(type: .system)
    private let removeLoader      = UIActivityIndicatorView(style: .medium)

    private var isApplied = false
    private var isExpanded = false
    private var isSubmitting = false
    private var isRemoving = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    func setApplied(
        _ applied: Bool,
        code: String? = nil,
        discount: Double = 0,
        currency: String = "$",
        currencyPosition: String? = ""
    ) {
        isApplied = applied
        isExpanded = applied ? false : isExpanded
        if let code {
            textField.text = code
            appliedCode.text = code
        }
        if !applied {
            textField.text = ""
            appliedCode.text = ""
        }
        updateState(animated: false)
    }

    private func setup() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        card.layer.cornerRadius = PremiumTableCornerRadius.card
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(hex: "#FFFFFF", alpha: 0.12).cgColor
        addSubview(card)

        titleRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleRow)

        titleTapButton.backgroundColor = .clear
        titleTapButton.translatesAutoresizingMaskIntoConstraints = false
        titleTapButton.addTarget(self, action: #selector(onActionTap), for: .touchUpInside)
        titleRow.addSubview(titleTapButton)

        promoLabel.text = "I have a promo code"
        promoLabel.font = Constant.Font.geistRegular(size: 16)
        promoLabel.textColor = .white
        promoLabel.translatesAutoresizingMaskIntoConstraints = false
        titleRow.addSubview(promoLabel)

        actionButton.setImage(UIImage(named: "plusIcon"), for: .normal)
        actionButton.tintColor = .white
        actionButton.isUserInteractionEnabled = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        titleRow.addSubview(actionButton)

        inputRow.translatesAutoresizingMaskIntoConstraints = false
        inputRow.isHidden = true
        card.addSubview(inputRow)

        configureFieldWrapper(textFieldWrapper)
        inputRow.addSubview(textFieldWrapper)
        configurePromoField(textField, placeholder: "Add code", enabled: true)
        textFieldWrapper.addSubview(textField)

        applyButton.setTitle("Apply", for: .normal)
        applyButton.setTitleColor(.black, for: .normal)
        applyButton.titleLabel?.font = Constant.Font.geistMedium(size: 12)
        applyButton.backgroundColor = .white
        applyButton.layer.cornerRadius = PremiumTableCornerRadius.field
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.addTarget(self, action: #selector(onApplyTap), for: .touchUpInside)
        inputRow.addSubview(applyButton)

        applyLoader.color = .black
        applyLoader.hidesWhenStopped = true
        applyLoader.translatesAutoresizingMaskIntoConstraints = false
        applyButton.addSubview(applyLoader)

        removeRow.translatesAutoresizingMaskIntoConstraints = false
        removeRow.isHidden = true
        card.addSubview(removeRow)

        configureFieldWrapper(appliedFieldWrap)
        removeRow.addSubview(appliedFieldWrap)
        configurePromoField(appliedCode, placeholder: "", enabled: false)
        appliedFieldWrap.addSubview(appliedCode)

        removeButton.setTitle("Remove", for: .normal)
        removeButton.setTitleColor(.black, for: .normal)
        removeButton.titleLabel?.font = Constant.Font.geistMedium(size: 12)
        removeButton.backgroundColor = .white
        removeButton.layer.cornerRadius = PremiumTableCornerRadius.field
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.addTarget(self, action: #selector(onRemoveTap), for: .touchUpInside)
        removeRow.addSubview(removeButton)

        removeLoader.color = .black
        removeLoader.hidesWhenStopped = true
        removeLoader.translatesAutoresizingMaskIntoConstraints = false
        removeButton.addSubview(removeLoader)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),

            titleRow.topAnchor.constraint(equalTo: card.topAnchor),
            titleRow.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            titleRow.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            titleRow.heightAnchor.constraint(equalToConstant: 60),

            titleTapButton.topAnchor.constraint(equalTo: titleRow.topAnchor),
            titleTapButton.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor),
            titleTapButton.trailingAnchor.constraint(equalTo: titleRow.trailingAnchor),
            titleTapButton.bottomAnchor.constraint(equalTo: titleRow.bottomAnchor),

            promoLabel.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor, constant: 20),
            promoLabel.centerYAnchor.constraint(equalTo: titleRow.centerYAnchor),
            promoLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -16),

            actionButton.trailingAnchor.constraint(equalTo: titleRow.trailingAnchor, constant: -23),
            actionButton.centerYAnchor.constraint(equalTo: titleRow.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 21),
            actionButton.heightAnchor.constraint(equalToConstant: 21),

            inputRow.topAnchor.constraint(equalTo: titleRow.bottomAnchor),
            inputRow.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            inputRow.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            inputRow.heightAnchor.constraint(equalToConstant: 66),

            textFieldWrapper.leadingAnchor.constraint(equalTo: inputRow.leadingAnchor, constant: 19),
            textFieldWrapper.topAnchor.constraint(equalTo: inputRow.topAnchor),
            textFieldWrapper.heightAnchor.constraint(equalToConstant: 44),

            textField.leadingAnchor.constraint(equalTo: textFieldWrapper.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: textFieldWrapper.trailingAnchor),
            textField.topAnchor.constraint(equalTo: textFieldWrapper.topAnchor),
            textField.bottomAnchor.constraint(equalTo: textFieldWrapper.bottomAnchor),

            applyButton.leadingAnchor.constraint(equalTo: textFieldWrapper.trailingAnchor, constant: 12),
            applyButton.trailingAnchor.constraint(equalTo: inputRow.trailingAnchor, constant: -21),
            applyButton.centerYAnchor.constraint(equalTo: textFieldWrapper.centerYAnchor),
            applyButton.widthAnchor.constraint(equalToConstant: 73),
            applyButton.heightAnchor.constraint(equalToConstant: 38),

            applyLoader.centerXAnchor.constraint(equalTo: applyButton.centerXAnchor),
            applyLoader.centerYAnchor.constraint(equalTo: applyButton.centerYAnchor),

            removeRow.topAnchor.constraint(equalTo: card.topAnchor),
            removeRow.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            removeRow.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            removeRow.heightAnchor.constraint(equalToConstant: 44),

            appliedFieldWrap.leadingAnchor.constraint(equalTo: removeRow.leadingAnchor),
            appliedFieldWrap.topAnchor.constraint(equalTo: removeRow.topAnchor),
            appliedFieldWrap.bottomAnchor.constraint(equalTo: removeRow.bottomAnchor),

            appliedCode.leadingAnchor.constraint(equalTo: appliedFieldWrap.leadingAnchor, constant: 16),
            appliedCode.trailingAnchor.constraint(equalTo: appliedFieldWrap.trailingAnchor),
            appliedCode.topAnchor.constraint(equalTo: appliedFieldWrap.topAnchor),
            appliedCode.bottomAnchor.constraint(equalTo: appliedFieldWrap.bottomAnchor),

            removeButton.leadingAnchor.constraint(equalTo: appliedFieldWrap.trailingAnchor, constant: 12),
            removeButton.trailingAnchor.constraint(equalTo: removeRow.trailingAnchor),
            removeButton.centerYAnchor.constraint(equalTo: appliedFieldWrap.centerYAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 73),
            removeButton.heightAnchor.constraint(equalToConstant: 38),

            removeLoader.centerXAnchor.constraint(equalTo: removeButton.centerXAnchor),
            removeLoader.centerYAnchor.constraint(equalTo: removeButton.centerYAnchor)
        ])
    }

    private func configureFieldWrapper(_ view: UIView) {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        view.layer.cornerRadius = PremiumTableCornerRadius.field
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configurePromoField(_ field: UITextField, placeholder: String, enabled: Bool) {
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.28),
                .font: Constant.Font.geistRegular(size: 12)
            ]
        )
        field.font = Constant.Font.geistRegular(size: 12)
        field.textColor = .white
        field.backgroundColor = .clear
        field.borderStyle = .none
        field.returnKeyType = .done
        field.isUserInteractionEnabled = enabled
        field.alpha = enabled ? 1 : 0.5
        field.translatesAutoresizingMaskIntoConstraints = false
        field.delegate = self
    }

    @objc private func onActionTap() {
        guard !isSubmitting else { return }
        guard !isApplied else { return }

        AppHaptic.selectionChanged()
        isExpanded.toggle()
        updateState(animated: false)
    }

    @objc private func onApplyTap() {
        guard !isSubmitting else { return }
        AppHaptic.primaryAction()
        submitCurrentCode()
    }

    @objc private func onRemoveTap() {
        guard !isSubmitting else { return }
        AppHaptic.destructive()
        isRemoving = true
        onRemove?()
    }

    func setSubmitting(_ submitting: Bool) {
        isSubmitting = submitting
        applyButton.isEnabled = !submitting
        removeButton.isEnabled = !submitting
        titleTapButton.isEnabled = !submitting
        textField.isUserInteractionEnabled = !submitting && !isApplied
        appliedCode.isUserInteractionEnabled = false
        if submitting, isRemoving {
            removeButton.setTitle(nil, for: .normal)
            removeLoader.startAnimating()
        } else {
            removeButton.setTitle("Remove", for: .normal)
            removeLoader.stopAnimating()
        }
        if submitting, !isRemoving {
            applyButton.setTitle(nil, for: .normal)
            applyLoader.startAnimating()
        } else {
            applyButton.setTitle("Apply", for: .normal)
            applyLoader.stopAnimating()
        }
        applyButton.alpha = submitting ? 0.85 : 1
        removeButton.alpha = submitting ? 0.85 : 1
        actionButton.alpha = submitting ? 0.45 : 1
        if !submitting {
            isRemoving = false
        }
    }

    private func submitCurrentCode() {
        let code = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        onSubmit?(code)
        textField.resignFirstResponder()
    }

    private func updateState(animated: Bool) {
        titleRow.isHidden = isApplied
        inputRow.isHidden = !isExpanded || isApplied
        removeRow.isHidden = !isApplied
        actionButton.setImage(
            UIImage(named: isExpanded ? "minusPromoIcon" : "plusIcon"),
            for: .normal
        )
        onHeightChanged?(preferredHeight)
        textField.isUserInteractionEnabled = !isSubmitting && !isApplied
        appliedCode.isUserInteractionEnabled = false
        updatePromoBorderState()

        let updates = {
            _ = self.superview?.layoutIfNeeded()
        }
        updates()

        if isExpanded && !isApplied {
            textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
    }

    private func updatePromoBorderState() {
        card.layer.borderWidth = isApplied ? 0 : 1
        card.layer.borderColor = UIColor(hex: "#FFFFFF", alpha: 0.12).cgColor
        card.backgroundColor = isApplied
            ? .clear
            : UIColor.white.withAlphaComponent(0.06)

        textFieldWrapper.layer.borderWidth = isApplied ? 0 : 1
        appliedFieldWrap.layer.borderWidth = isApplied ? 0 : 1
    }
}

extension PremiumPromoRow: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitCurrentCode()
        return true
    }
}

// MARK: - PremiumTimerBannerView
/// Thin banner "Session expires in MM:SS"

final class PremiumTimerBannerView: UIView {

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "#1A1A1A")
        label.font          = Constant.Font.geistRegular(size: 12)
        label.textColor     = UIColor.white.withAlphaComponent(0.65)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func update(seconds: Int) {
        let m = seconds / 60
        let s = seconds % 60
        let color = seconds <= 60
            ? UIColor(hex: "#E84040")
            : UIColor.white.withAlphaComponent(0.65)
        label.textColor = color
        label.text = String(format: "Session expires in %02d:%02d", m, s)
    }
}
