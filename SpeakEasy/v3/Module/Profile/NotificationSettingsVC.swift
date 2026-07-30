//
//  NotificationSettingsVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//

import UIKit
import UserNotifications

final class NotificationSettingsVC: UIViewController {

    private let backBtn = AppIconButton()
    private let titleLabel = UILabel()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let mainStack = UIStackView()

    private var shouldEnablePushAfterSettings = false

    private var sections: [NotificationSettingSection] = [
        NotificationSettingSection(
            title: "How should we notify you?",
            items: [
                NotificationSettingItem(
                    title: "Push notifications",
                    type: .push,
                    isOn: UserDefault.shared.isNotificationOn
                )
            ]
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        buildSections()
        setupAppLifecycleObserver()
        refreshPushNotificationState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshPushNotificationState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    private func setupAppLifecycleObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
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

        titleLabel.text = "Notification Settings"
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
                guard let self else { return }
                let item = self.sections[sectionIndex].items[itemIndex]

                switch item.type {
                case .push:
                    self.updatePushNotification(isOn: isOn)
                }
            }

            mainStack.addArrangedSubview(sectionView)
        }
    }

    private func refreshPushNotificationState() {
        guard #available(iOS 10.0, *) else {
            updatePushState(UserDefault.shared.isNotificationOn, rebuild: true)
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            var isSystemEnabled = settings.authorizationStatus == .authorized
            if #available(iOS 12.0, *) {
                isSystemEnabled = isSystemEnabled || settings.authorizationStatus == .provisional
            }

            DispatchQueue.main.async {
                guard let self else { return }
                let shouldTurnOn = self.shouldEnablePushAfterSettings
                    ? isSystemEnabled
                    : isSystemEnabled && UserDefault.shared.isNotificationOn

                self.shouldEnablePushAfterSettings = false
                if shouldTurnOn {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self.updatePushState(shouldTurnOn, rebuild: true)
            }
        }
    }

    private func updatePushNotification(isOn: Bool) {
        if isOn {
            requestPushNotificationPermission()
        } else {
            UIApplication.shared.unregisterForRemoteNotifications()
            updatePushState(false, rebuild: false)
        }
    }

    private func requestPushNotificationPermission() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                DispatchQueue.main.async {
                    guard let self else { return }

                    switch settings.authorizationStatus {
                    case .notDetermined:
                        self.requestSystemPushNotificationPermission()
                    case .denied:
                        self.updatePushState(false, rebuild: true)
                        self.presentNotificationSettingsPrompt()
                    default:
                        UIApplication.shared.registerForRemoteNotifications()
                        self.updatePushState(true, rebuild: true)
                    }
                }
            }
        } else {
            let settings = UIUserNotificationSettings(
                types: [.alert, .badge, .sound],
                categories: nil
            )
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.application?.registerUserNotificationSettings(settings)
            }
            updatePushState(true, rebuild: false)
        }
    }

    @available(iOS 10.0, *)
    private func requestSystemPushNotificationPermission() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { [weak self] isAllowed, _ in
            DispatchQueue.main.async {
                if isAllowed {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self?.updatePushState(isAllowed, rebuild: true)
            }
        }
    }

    private func presentNotificationSettingsPrompt() {
        let alert = UIAlertController(
            title: "Turn on notifications",
            message: "Notifications are turned off in Settings. Open Settings to enable push notifications for SpeakEasy.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { [weak self] _ in
            self?.shouldEnablePushAfterSettings = true
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        })

        present(alert, animated: true)
    }

    private func updatePushState(_ isOn: Bool, rebuild: Bool) {
        UserDefault.shared.isNotificationOn = isOn

        for sectionIndex in sections.indices {
            for itemIndex in sections[sectionIndex].items.indices
            where sections[sectionIndex].items[itemIndex].type == .push {
                sections[sectionIndex].items[itemIndex].isOn = isOn
            }
        }

        if rebuild {
            buildSections()
        }
    }

    @objc private func onAppDidBecomeActive() {
        refreshPushNotificationState()
    }

    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }
}

extension NotificationSettingsVC: UNUserNotificationCenterDelegate { }

struct NotificationSettingSection {
    let title: String
    var items: [NotificationSettingItem]
}

struct NotificationSettingItem {
    let title: String
    let type: NotificationSettingType
    var isOn: Bool
}

enum NotificationSettingType {
    case push
}
