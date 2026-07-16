//
//  PartySizePickerView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 24/06/26.
//

import UIKit

final class PartySizePickerView: UIView {

    var onValueChanged: ((Int) -> Void)?

    private let minusButton = UIButton(type: .system)
    private let plusButton  = UIButton(type: .system)
    private let countLabel  = UILabel()

    private(set) var count: Int = 0
    private var maxCount: Int = 100

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(current: Int, max: Int) {
        maxCount = max
        count    = current
        countLabel.text = "\(count)"
        updateButtons()
    }

    private func setup() {
        backgroundColor = .clear

        configureStepperButton(minusButton, title: "−", imageName: "minusIcon")
        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)

        configureStepperButton(plusButton, title: "+", imageName: "pluseIcon")
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)

        // Count
        countLabel.text = "\(count)"
        countLabel.textColor = .white
        countLabel.font = Constant.Font.geistMedium(size: 18)
        countLabel.textAlignment = .center
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(minusButton)
        addSubview(countLabel)
        addSubview(plusButton)

        NSLayoutConstraint.activate([
            minusButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            minusButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 32),
            minusButton.heightAnchor.constraint(equalToConstant: 32),

            countLabel.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor, constant: 9),
            countLabel.trailingAnchor.constraint(equalTo: plusButton.leadingAnchor, constant: -9),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            plusButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            plusButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 32),
            plusButton.heightAnchor.constraint(equalToConstant: 32)
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
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.09).cgColor
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
    }

    private func updateButtons() {
        minusButton.isEnabled = count > 0
        plusButton.isEnabled  = count < maxCount
        minusButton.alpha = minusButton.isEnabled ? 1 : 0.45
        plusButton.alpha = plusButton.isEnabled ? 1 : 0.45
    }

    @objc private func minusTapped() {
        guard count > 0 else { return }
        count -= 1
        AppHaptic.stepperChanged()
        countLabel.text = "\(count)"
        updateButtons()
        onValueChanged?(count)
    }

    @objc private func plusTapped() {
        guard count < maxCount else { return }
        count += 1
        AppHaptic.stepperChanged()
        countLabel.text = "\(count)"
        updateButtons()
        onValueChanged?(count)
    }
}
