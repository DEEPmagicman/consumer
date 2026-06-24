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

        // Minus
        minusButton.setTitle("−", for: .normal)
        minusButton.setTitleColor(.white, for: .normal)
        minusButton.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .disabled)
        minusButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .light)
        minusButton.translatesAutoresizingMaskIntoConstraints = false
        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)

        // Plus
        plusButton.setTitle("+", for: .normal)
        plusButton.setTitleColor(.white, for: .normal)
        plusButton.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .disabled)
        plusButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .light)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
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
            minusButton.widthAnchor.constraint(equalToConstant: 44),
            minusButton.heightAnchor.constraint(equalToConstant: 44),

            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 40),

            plusButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            plusButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 44),
            plusButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        updateButtons()
    }

    private func updateButtons() {
        minusButton.isEnabled = count > 0
        plusButton.isEnabled  = count < maxCount
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
