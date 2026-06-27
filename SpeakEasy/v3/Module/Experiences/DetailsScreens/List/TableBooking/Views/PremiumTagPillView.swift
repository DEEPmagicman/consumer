//
//  PremiumTagPillView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 26/06/26.
//

import UIKit

// MARK: - PremiumTagPillView
/// Small pill with icon + text  e.g. "10-14 guests"

final class PremiumTagPillView: UIView {

    private let iconView  = UIImageView()
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = UIColor.white.withAlphaComponent(0.08)
        layer.cornerRadius = 14
        clipsToBounds = true

        iconView.tintColor      = UIColor.white.withAlphaComponent(0.65)
        iconView.contentMode    = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        textLabel.font      = Constant.Font.geistRegular(size: 12)
        textLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(textLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 13),
            iconView.heightAnchor.constraint(equalToConstant: 13),

            textLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    func configure(icon: String, text: String) {
        iconView.image = UIImage(systemName: icon)
        textLabel.text = text
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
        cardView.glassCornerRadius = 14
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

        titleLabel.font      = Constant.Font.geistRegular(size: 15)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        // Stepper
        func makeBtn(_ title: String, action: Selector) -> UIButton {
            let b = UIButton(type: .system)
            b.setTitle(title, for: .normal)
            b.setTitleColor(.white, for: .normal)
            b.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .disabled)
            b.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .light)
            b.translatesAutoresizingMaskIntoConstraints = false
            b.addTarget(self, action: action, for: .touchUpInside)
            return b
        }

        let minus = makeBtn("−", action: #selector(onMinus))
        let plus  = makeBtn("+", action: #selector(onPlus))

        countLabel.font          = Constant.Font.geistMedium(size: 17)
        countLabel.textColor     = .white
        countLabel.textAlignment = .center
        countLabel.text          = "\(count)"
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        [minus, countLabel, plus].forEach { cardView.addSubview($0) }

        self.minusBtn.isEnabled = false

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

            plus.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            plus.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            plus.widthAnchor.constraint(equalToConstant: 36),
            plus.heightAnchor.constraint(equalToConstant: 44),

            countLabel.trailingAnchor.constraint(equalTo: plus.leadingAnchor, constant: -4),
            countLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 32),

            minus.trailingAnchor.constraint(equalTo: countLabel.leadingAnchor, constant: -4),
            minus.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            minus.widthAnchor.constraint(equalToConstant: 36),
            minus.heightAnchor.constraint(equalToConstant: 44)
        ])

        // store refs
        cardView.addSubview(minus)
        cardView.addSubview(plus)
    }

    private func updateButtons() {
        // We stored minus/plus locally — find them by tag
    }

    @objc private func onMinus() {
        guard count > minValue else { return }
        count -= 1
        countLabel.text = "\(count)"
        onValueChanged?(count)
    }

    @objc private func onPlus() {
        guard count < maxValue else { return }
        count += 1
        countLabel.text = "\(count)"
        onValueChanged?(count)
    }
}

// MARK: - PremiumPriceCard
/// Dark card showing "$1000 minimum" on left, "$1,048.00 deposit incl. fees" on right

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
        card.glassCornerRadius = 14
    }

    func configure(minimum: Double, deposit: Double) {
        minLabel.text = "$\(Int(minimum))"
        depLabel.text = "$\(String(format: "%.2f", deposit))"
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
        card.glassCornerRadius = 14
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
        addSubview(card)

        iconView.tintColor   = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconView)

        titleLabel.font      = Constant.Font.geistRegular(size: 15)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
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

// MARK: - SpendLineItem model

struct SpendLineItem {
    let title:  String
    let amount: Double
    let isBold: Bool
}

// MARK: - PremiumSpendAgreementView
/// Collapsible "Spend Agreement" card with line items from API

final class PremiumSpendAgreementView: UIView {

    private let card        = GradientBorderCardView()
    private let headerView  = UIView()
    private let headerLabel = UILabel()
    private let chevron     = UIImageView()
    private let stackView   = UIStackView()
    private let divider     = UIView()

    private var isExpanded  = false
    private var currency    = "$"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        card.glassCornerRadius = 14
    }

    func configure(currency: String, items: [SpendLineItem]) {
        self.currency = currency
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        items.forEach { item in
            let row = makeRow(title: item.title, amount: item.amount, bold: item.isBold)
            stackView.addArrangedSubview(row)
        }
        setExpanded(false, animated: false)
    }

    private func setup() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = UIColor.white.withAlphaComponent(0.06).cgColor
        card.showsBlur = true
        card.blurAlpha = 0.4
        addSubview(card)

        // Header
        headerLabel.text      = "Spend Agreement"
        headerLabel.font      = Constant.Font.geistMedium(size: 15)
        headerLabel.textColor = .white
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        chevron.image          = UIImage(systemName: "chevron.down")
        chevron.tintColor      = .white
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
            chevron.widthAnchor.constraint(equalToConstant: 18),
            chevron.heightAnchor.constraint(equalToConstant: 18),

            divider.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            stackView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14),
            stackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }

    private func makeRow(title: String, amount: Double, bold: Bool) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let t = UILabel()
        t.text      = title
        t.font      = bold ? Constant.Font.geistMedium(size: 14) : Constant.Font.geistRegular(size: 14)
        t.textColor = .white
        t.translatesAutoresizingMaskIntoConstraints = false

        let v = UILabel()
        let formatted = amount == 0 && title.lowercased().contains("balance")
            ? "\(currency)0.00"
            : (amount < 0
               ? "-\(currency)\(String(format: "%.2f", abs(amount)))"
               : "\(currency)\(String(format: "%.2f", amount))")
        v.text          = formatted
        v.font          = bold ? Constant.Font.geistMedium(size: 14) : Constant.Font.geistRegular(size: 14)
        v.textColor     = .white
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
        setExpanded(!isExpanded, animated: true)
    }

    private func setExpanded(_ expanded: Bool, animated: Bool) {
        isExpanded = expanded
        let rotate: CGFloat = expanded ? .pi : 0

        let update = {
            self.divider.isHidden   = !expanded
            self.stackView.isHidden = !expanded
            self.chevron.transform  = CGAffineTransform(rotationAngle: rotate)
            self.superview?.layoutIfNeeded()
        }

        animated
            ? UIView.animate(withDuration: 0.25, animations: update)
            : update()
    }
}

// MARK: - PremiumPromoRow
/// "I have a promo code" row with + icon, expands to text field when tapped

final class PremiumPromoRow: UIView {

    var onSubmit: ((String) -> Void)?
    var onRemove: (() -> Void)?

    private let card         = GradientBorderCardView()
    private let promoLabel   = UILabel()
    private let actionIcon   = UIImageView()
    private let textField    = UITextField()
    private var isApplied    = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        card.glassCornerRadius = 14
    }

    func setApplied(_ applied: Bool) {
        isApplied = applied
        promoLabel.text = applied ? "Promo applied ✓" : "I have a promo code"
        actionIcon.image = UIImage(systemName: applied ? "trash" : "plus.circle")
        textField.isHidden = true
        textField.text = ""
    }

    private func setup() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = UIColor.white.withAlphaComponent(0.06).cgColor
        card.showsBlur = true
        card.blurAlpha = 0.4
        addSubview(card)

        promoLabel.text      = "I have a promo code"
        promoLabel.font      = Constant.Font.geistRegular(size: 15)
        promoLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        promoLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(promoLabel)

        actionIcon.image       = UIImage(systemName: "plus.circle")
        actionIcon.tintColor   = .white
        actionIcon.contentMode = .scaleAspectFit
        actionIcon.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(actionIcon)

        textField.placeholder   = "Enter promo code"
        textField.font          = Constant.Font.geistRegular(size: 15)
        textField.textColor     = .white
        textField.backgroundColor = .clear
        textField.borderStyle   = .none
        textField.returnKeyType = .done
        textField.isHidden      = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate      = self
        card.addSubview(textField)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),

            promoLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            promoLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            actionIcon.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            actionIcon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            actionIcon.widthAnchor.constraint(equalToConstant: 22),
            actionIcon.heightAnchor.constraint(equalToConstant: 22),

            textField.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: actionIcon.leadingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        card.addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        if isApplied {
            onRemove?()
        } else {
            promoLabel.isHidden = true
            textField.isHidden  = false
            textField.becomeFirstResponder()
        }
    }
}

extension PremiumPromoRow: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let code = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !code.isEmpty { onSubmit?(code) }
        textField.resignFirstResponder()
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
