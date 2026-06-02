//
//  LogoutConfirmationBottomSheetDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//

import UIKit

final class LogoutConfirmationBottomSheetVC: UIViewController {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let sheetView = UIView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let cancelBtn = PrimaryButton()
    private let logoutBtn = PrimaryButton()

    private let authService = AuthService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sheetView.applyScreenBgGradient(direction: .bottomToTop)
    }

    private func setupUI() {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve

        view.backgroundColor = AppColor.primaryColor.withAlphaComponent(0.15)

        blurView.alpha = 0
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)

        let outsideTap = UITapGestureRecognizer(target: self, action: #selector(onClickCancel))
        blurView.addGestureRecognizer(outsideTap)
        blurView.isUserInteractionEnabled = true

        sheetView.layer.cornerRadius = 28
        sheetView.layer.cornerCurve = .continuous
        sheetView.clipsToBounds = true
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)

        titleLabel.text = "Log out of Speakeasy?"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(titleLabel)

        subtitleLabel.text = "Are you sure you want to log out?"
        subtitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.45)
        subtitleLabel.font = Constant.Font.geistRegular(size: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(subtitleLabel)

        cancelBtn.configure(title: "Cancel", fontSize: 17, cornerRadius: 16)
        cancelBtn.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08)
        cancelBtn.setTitleColor(AppColor.primaryWhiteColor, for: .normal)
        cancelBtn.addTarget(self, action: #selector(onClickCancel), for: .touchUpInside)
        sheetView.addSubview(cancelBtn)

        logoutBtn.configure(title: "Log out", fontSize: 17, cornerRadius: 16)
        logoutBtn.addTarget(self, action: #selector(onClickLogout), for: .touchUpInside)
        sheetView.addSubview(logoutBtn)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sheetView.heightAnchor.constraint(equalToConstant: 390),

            titleLabel.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 42),
            titleLabel.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            subtitleLabel.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),

            cancelBtn.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            cancelBtn.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),
            cancelBtn.bottomAnchor.constraint(equalTo: logoutBtn.topAnchor, constant: -12),
            cancelBtn.heightAnchor.constraint(equalToConstant: 50),

            logoutBtn.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            logoutBtn.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),
            logoutBtn.bottomAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            logoutBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func animateIn() {
        sheetView.transform = CGAffineTransform(translationX: 0, y: 390)

        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
            self.blurView.alpha = 1
            self.sheetView.transform = .identity
        }
    }

    private func dismissSheet(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseIn]) {
            self.blurView.alpha = 0
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: 390)
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    @objc private func onClickCancel() {
        dismissSheet()
    }

    @objc private func onClickLogout() {
        logoutBtn.startLoading()
        UserDefault.shared.emptyData()
        AppDelegate.shared.changeRootViewController()
        authService.logout { _, _ in }
        logoutBtn.stopLoading()
        dismissSheet()
    }
}
