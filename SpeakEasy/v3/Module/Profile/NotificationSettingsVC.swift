//
//  NotificationSettingsVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//

import UIKit

final class NotificationSettingsVC: UIViewController {

    private let backBtn = AppIconButton()
    private let titleLabel = UILabel()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let mainStack = UIStackView()

    private var sections: [NotificationSettingSection] = [
        NotificationSettingSection(
            title: "How should we notify you?",
            items: [
                NotificationSettingItem(title: "Push notifications", isOn: true),
                NotificationSettingItem(title: "Email notifications", isOn: true)
            ]
        ),
        NotificationSettingSection(
            title: "What would you like updates on?",
            items: [
                NotificationSettingItem(title: "Events", isOn: true),
                NotificationSettingItem(title: "Venues", isOn: true),
                NotificationSettingItem(title: "Creators", isOn: true),
                NotificationSettingItem(title: "Premium experiences", isOn: false),
                NotificationSettingItem(title: "Artists", isOn: false),
                NotificationSettingItem(title: "Promotions", isOn: false)
            ]
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        buildSections()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    private func setupUI() {
        setupNav()
        setupScroll()
        setupConstraints()
    }

    private func setupNav() {
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 14
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)

        titleLabel.text = "Notification settings"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }

    private func setupScroll() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.alignment = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.widthAnchor.constraint(equalToConstant: 40),
            backBtn.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            scrollView.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 40),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func buildSections() {
        mainStack.arrangedSubviews.forEach {
            mainStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for sectionIndex in sections.indices {
            let sectionView = NotificationSettingsSectionView(section: sections[sectionIndex])
            sectionView.onToggle = { [weak self] itemIndex, isOn in
                self?.sections[sectionIndex].items[itemIndex].isOn = isOn

                // API payload point:
                // self?.updateNotificationSetting(sectionIndex: sectionIndex, itemIndex: itemIndex, isOn: isOn)
            }

            mainStack.addArrangedSubview(sectionView)
        }
    }

    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }
}

struct NotificationSettingSection {
    let title: String
    var items: [NotificationSettingItem]
}

struct NotificationSettingItem {
    let title: String
    var isOn: Bool
}
