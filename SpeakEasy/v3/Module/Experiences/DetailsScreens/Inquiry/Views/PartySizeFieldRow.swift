//
//  PartySizeFieldRow.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 24/06/26.
//

import UIKit

final class PartySizeFieldRow: UIView {

    private let cardView   = GradientBorderCardView()
    private let iconView   = UIImageView()
    private let titleLabel = UILabel()
    private let totalLabel = UILabel()
    private let stepper    = PartySizePickerView()
    private let genderStackView = UIStackView()
    private let menStepper = GenderPartySizeStepperView(title: "Men")
    private let womenStepper = GenderPartySizeStepperView(title: "Women")

    var onValueChanged: ((Int) -> Void)?
    var onGenderValueChanged: ((_ men: Int, _ women: Int) -> Void)?

    private var heightConstraint: NSLayoutConstraint?
    private var titleCenterYConstraint: NSLayoutConstraint?
    private var titleTopConstraint: NSLayoutConstraint?
    private var genderConstraints: [NSLayoutConstraint] = []
    private var maxCount: Int = 100
    private var menCount = 0
    private var womenCount = 0
    private(set) var showsGenderCounts = false

    var currentValue: Int {
        showsGenderCounts ? menCount + womenCount : stepper.count
    }

    var isRequired: Bool = false {
        didSet {
            updateTitle()
        }
    }

    var viewCornerRadius: CGFloat = 14 {
        didSet {
            cardView.glassCornerRadius = viewCornerRadius
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.glassCornerRadius = viewCornerRadius
    }

    func configure(max: Int, showsGenderCounts: Bool = false) {
        self.maxCount = max
        self.showsGenderCounts = showsGenderCounts
        menCount = 0
        womenCount = 0
        stepper.configure(current: 0, max: max)
        updateMode()
        updateGenderSteppers()
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: 52)
        heightConstraint?.isActive = true

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.fillColor = UIColor.white.withAlphaComponent(0.05).cgColor
        cardView.showsBlur = true
        cardView.blurAlpha = 0.55
        cardView.thinBorder = true
        addSubview(cardView)

        iconView.tintColor              = .white
        iconView.contentMode            = .scaleAspectFit
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        iconView.image = UIImage(resource: .guestIcon)
            .withConfiguration(config)
            .withRenderingMode(.alwaysTemplate)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconView)

        titleLabel.font      = Constant.Font.geistRegular(size: 14)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        updateTitle()

        totalLabel.text = "0"
        totalLabel.font = Constant.Font.geistMedium(size: 18)
        totalLabel.textColor = .white
        totalLabel.textAlignment = .right
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(totalLabel)

        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.onValueChanged = { [weak self] val in
            self?.onValueChanged?(val)
        }
        cardView.addSubview(stepper)

        genderStackView.axis = .horizontal
        genderStackView.spacing = 10
        genderStackView.distribution = .fillEqually
        genderStackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(genderStackView)
        genderStackView.addArrangedSubview(menStepper)
        genderStackView.addArrangedSubview(womenStepper)

        menStepper.onValueChanged = { [weak self] value in
            guard let self else { return }
            self.menCount = value
            self.genderValueChanged()
        }
        womenStepper.onValueChanged = { [weak self] value in
            guard let self else { return }
            self.womenCount = value
            self.genderValueChanged()
        }

        titleCenterYConstraint = titleLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18)
        titleTopConstraint?.isActive = false
        titleCenterYConstraint?.isActive = true
        genderConstraints = [
            genderStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            genderStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            genderStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            genderStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            genderStackView.heightAnchor.constraint(equalToConstant: 70)
        ]

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: totalLabel.leadingAnchor, constant: -12),

            totalLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            totalLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            stepper.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            stepper.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            stepper.heightAnchor.constraint(equalToConstant: 44)
        ])

        updateMode()
    }

    private func updateTitle() {
        let title = "Party size"
        guard isRequired else {
            titleLabel.text = title
            return
        }

        let text = "\(title)*"
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: Constant.Font.geistRegular(size: 14),
                .foregroundColor: UIColor.white.withAlphaComponent(0.95)
            ]
        )
        attributed.addAttribute(
            .foregroundColor,
            value: UIColor.white.withAlphaComponent(0.95),
            range: NSRange(location: text.count - 1, length: 1)
        )
        titleLabel.attributedText = attributed
    }

    private func updateMode() {
        heightConstraint?.constant = showsGenderCounts ? 154 : 52
        titleCenterYConstraint?.isActive = !showsGenderCounts
        titleTopConstraint?.isActive = showsGenderCounts
        genderConstraints.forEach { $0.isActive = showsGenderCounts }
        stepper.isHidden = showsGenderCounts
        genderStackView.isHidden = !showsGenderCounts
        totalLabel.isHidden = !showsGenderCounts
        totalLabel.text = "\(currentValue)"
    }

    private func updateGenderSteppers() {
        menStepper.configure(current: menCount, max: max(0, maxCount - womenCount))
        womenStepper.configure(current: womenCount, max: max(0, maxCount - menCount))
        totalLabel.text = "\(currentValue)"
    }

    private func genderValueChanged() {
        AppHaptic.stepperChanged()
        updateGenderSteppers()
        onValueChanged?(currentValue)
        onGenderValueChanged?(menCount, womenCount)
    }
}

private final class GenderPartySizeStepperView: UIView {

    var onValueChanged: ((Int) -> Void)?

    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)
    private let countLabel = UILabel()
    private let titleLabel = UILabel()
    private var count = 0
    private var maxCount = 100

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(current: Int, max: Int) {
        count = current
        maxCount = max
        countLabel.text = "\(count)"
        updateButtons()
    }

    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.05)
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor

        configureStepperButton(minusButton, title: "−", imageName: "minusIcon")
        configureStepperButton(plusButton, title: "+", imageName: "pluseIcon")
        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)

        countLabel.text = "0"
        countLabel.font = Constant.Font.geistMedium(size: 18)
        countLabel.textColor = .white
        countLabel.textAlignment = .center
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = Constant.Font.geistRegular(size: 12)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(minusButton)
        addSubview(plusButton)
        addSubview(countLabel)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            minusButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            minusButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 32),
            minusButton.heightAnchor.constraint(equalToConstant: 32),

            plusButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            plusButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 32),
            plusButton.heightAnchor.constraint(equalToConstant: 32),

            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 3)
        ])

        updateButtons()
    }

    private func configureStepperButton(_ button: UIButton, title: String, imageName: String) {
        if let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate) {
            button.setImage(image, for: .normal)
            button.tintColor = .white
        } else {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .light)
        }
        button.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .disabled)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        button.layer.cornerRadius = 7
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
    }

    private func updateButtons() {
        minusButton.isEnabled = count > 0
        plusButton.isEnabled = count < maxCount
        minusButton.alpha = minusButton.isEnabled ? 1 : 0.45
        plusButton.alpha = plusButton.isEnabled ? 1 : 0.45
    }

    @objc private func minusTapped() {
        guard count > 0 else { return }
        count -= 1
        countLabel.text = "\(count)"
        updateButtons()
        onValueChanged?(count)
    }

    @objc private func plusTapped() {
        guard count < maxCount else { return }
        count += 1
        countLabel.text = "\(count)"
        updateButtons()
        onValueChanged?(count)
    }
}
