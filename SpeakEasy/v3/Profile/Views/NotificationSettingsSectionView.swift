//
//  NotificationSettingsSectionView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//


import UIKit

final class NotificationSettingsSectionView: UIView {

    var onToggle: ((_ index: Int, _ isOn: Bool) -> Void)?

    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    private var switches: [UISwitch] = []

    init(section: NotificationSettingSection) {
        super.init(frame: .zero)
        setup(section: section)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup(section: NotificationSettingSection) {
        backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.05)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = section.title
        titleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.35)
        titleLabel.font = Constant.Font.geistRegular(size: 15)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        for (index, item) in section.items.enumerated() {
            let row = makeRow(title: item.title, isOn: item.isOn, index: index)
            stackView.addArrangedSubview(row)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    private func makeRow(title: String, isOn: Bool, index: Int) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.textColor = AppColor.primaryWhiteColor
        label.font = Constant.Font.geistRegular(size: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(label)

        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.tag = index
        toggle.onTintColor = AppColor.primaryWhiteColor
        toggle.thumbTintColor = AppColor.primaryColor
        toggle.tintColor = AppColor.primaryWhiteColor.withAlphaComponent(0.25)
        toggle.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.25)
        toggle.layer.cornerRadius = 16
        toggle.addTarget(self, action: #selector(onSwitchChanged(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(toggle)

        switches.append(toggle)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 30),

            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    @objc private func onSwitchChanged(_ sender: UISwitch) {
        onToggle?(sender.tag, sender.isOn)
    }
}
