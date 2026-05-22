//
//  NotificationSettingsSectionView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//

import UIKit

final class NotificationSettingsSectionView: UIView {

    // MARK: - Callback

    var onToggle: ((_ index: Int, _ isOn: Bool) -> Void)?

    // MARK: - UI
    private let titleLabel = UILabel()
    private let stackView = UIStackView()

    // MARK: - Init
    init(section: NotificationSettingSection) {
        super.init(frame: .zero)
        setup(section: section)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Setup
    private func setup(section: NotificationSettingSection) {

        backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.05)

        layer.cornerRadius = 16
        layer.cornerCurve = .continuous

        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        // Title
        titleLabel.text = section.title
        titleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.35)
        titleLabel.font = Constant.Font.geistRegular(size: 15)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)

        // Stack
        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        // Rows
        for (index, item) in section.items.enumerated() {

            let row = makeRow(
                title: item.title,
                isOn: item.isOn,
                index: index
            )

            stackView.addArrangedSubview(row)
        }

        NSLayoutConstraint.activate([

            titleLabel.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 16
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 24
            ),

            titleLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -24
            ),

            stackView.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 28
            ),

            stackView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 24
            ),

            stackView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -24
            ),

            stackView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -24
            )
        ])
    }

    // MARK: - Row
    private func makeRow(
        title: String,
        isOn: Bool,
        index: Int
    ) -> UIView {

        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        // Label

        let label = UILabel()

        label.text = title
        label.textColor = AppColor.primaryWhiteColor
        label.font = Constant.Font.geistRegular(size: 17)

        label.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(label)

        // Toggle
        let toggle = makeToggle(
            isOn: isOn,
            index: index
        )

        row.addSubview(toggle)

        NSLayoutConstraint.activate([

            row.heightAnchor.constraint(
                equalToConstant: 30
            ),

            label.leadingAnchor.constraint(
                equalTo: row.leadingAnchor
            ),

            label.centerYAnchor.constraint(
                equalTo: row.centerYAnchor
            ),

            toggle.trailingAnchor.constraint(
                equalTo: row.trailingAnchor
            ),

            toggle.centerYAnchor.constraint(
                equalTo: row.centerYAnchor
            )
        ])
        row.isUserInteractionEnabled = true
        return row
    }

    // MARK: - Toggle Factory
    private func makeToggle(
        isOn: Bool,
        index: Int
    ) -> UIControl {

        // OLD SWITCH
        if true {

            let toggle = LegacySwitchControl()

            toggle.isOn = isOn
            toggle.tag = index

            toggle.addTarget(
                self,
                action: #selector(onLegacySwitchChanged(_:)),
                for: .valueChanged
            )

            return toggle
        }

        // SYSTEM SWITCH
        else {

            let toggle = UISwitch()

            toggle.isOn = isOn
            toggle.tag = index

            toggle.translatesAutoresizingMaskIntoConstraints = false

            toggle.addTarget(
                self,
                action: #selector(onSystemSwitchChanged(_:)),
                for: .valueChanged
            )

            return toggle
        }
    }

    // MARK: - Actions
    @objc
    private func onLegacySwitchChanged(
        _ sender: LegacySwitchControl
    ) {

        onToggle?(sender.tag, sender.isOn)
    }

    @objc
    private func onSystemSwitchChanged(
        _ sender: UISwitch
    ) {

        onToggle?(sender.tag, sender.isOn)
    }
}
