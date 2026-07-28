//
//  NotificationPermissionVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 13/05/26.
//

import UIKit
import UserNotifications

final class NotificationPermissionVC: UIViewController, UNUserNotificationCenterDelegate {

    private let iconImageView = UIImageView()
    private var titleLabel = UILabel()
    private var subtitleLabel = UILabel()
    private let enableBtn = PrimaryButton()
    private let skipBtn = PrimaryButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    private func setupUI() {

        iconImageView.image = UIImage(resource: .notificationBell)
        iconImageView.tintColor = AppColor.primaryWhiteColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconImageView)

        titleLabel = Utility.main.makeLabel(
            "Stay Connected\nto Every Moment.",
            size: 32
        )

        subtitleLabel = Utility.main.makeLabel(
            "Stay updated on the events, partners,\nreservations, and live experiences\nhappening around you.",
            font: Constant.Font.geistRegular(size: 12)
        )

        subtitleLabel.textColor = AuthTheme.subtitleGrayColor
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        enableBtn.configure(
            title: "Enable push notifications",
            fontSize: 18,
            cornerRadius: 18
        )

        enableBtn.addTarget(
            self,
            action: #selector(onClickTurnOnNotification),
            for: .touchUpInside
        )

        view.addSubview(enableBtn)

        skipBtn.configure(
            title: "Not now",
            fontSize: 18,
            cornerRadius: 18
        )

        skipBtn.bgColor = AuthTheme.fieldBackground

        skipBtn.setTitleColor(
            AppColor.primaryWhiteColor,
            for: .normal
        )

        skipBtn.addTarget(
            self,
            action: #selector(onClickSkip),
            for: .touchUpInside
        )

        view.addSubview(skipBtn)

        NSLayoutConstraint.activate([

            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -140),
            iconImageView.widthAnchor.constraint(equalToConstant: 65),
            iconImageView.heightAnchor.constraint(equalToConstant: 65),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 26),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            enableBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            enableBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            enableBtn.bottomAnchor.constraint(equalTo: skipBtn.topAnchor, constant: -10),
            enableBtn.heightAnchor.constraint(equalToConstant: 50),

            skipBtn.leadingAnchor.constraint(equalTo: enableBtn.leadingAnchor),
            skipBtn.trailingAnchor.constraint(equalTo: enableBtn.trailingAnchor),
            skipBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22),
            skipBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func onClickTurnOnNotification() {
        allowNotification()
    }

    private func allowNotification() {
        enableBtn.showLoader(userInteraction: false)

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                DispatchQueue.main.async {
                    guard let self else { return }

                    switch settings.authorizationStatus {
                    case .notDetermined:
                        self.requestSystemNotificationPermission()
                    case .denied:
                        self.enableBtn.hideLoader()
                        self.presentNotificationSettingsPrompt()
                    default:
                        UIApplication.shared.registerForRemoteNotifications()
                        self.finishNotificationPermissionFlow()
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

            enableBtn.hideLoader()
            AppDelegate.shared.setRootVC()
        }
    }

    @available(iOS 10.0, *)
    private func requestSystemNotificationPermission() {
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]

        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { [weak self] isAllowed, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.enableBtn.hideLoader()

                if isAllowed {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.finishNotificationPermissionFlow()
                } else {
                    self.presentNotificationSettingsPrompt()
                }
            }
        }
    }

    private func finishNotificationPermissionFlow() {
        enableBtn.hideLoader()
        Navigate.to.setLocationVc(self)
        AppDelegate.shared.setRootVC()
    }

    private func presentNotificationSettingsPrompt() {
        let alert = UIAlertController(
            title: "Turn on notifications",
            message: "Notifications are turned off in Settings. Open Settings to enable push notifications for SpeakEasy.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Not now", style: .cancel) { _ in
            AppDelegate.shared.setRootVC()
        })
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        })

        present(alert, animated: true)
    }

    @objc private func onClickSkip() {
        AppDelegate.shared.setRootVC()
    }
}
