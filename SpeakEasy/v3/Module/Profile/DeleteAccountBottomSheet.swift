//
//  DeleteAccountBottomSheetDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//

import UIKit

final class DeleteAccountBottomSheetVC: UIViewController {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let sheetView = UIView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let contactBtn = UIButton(type: .system)
    private let cancelBtn = PrimaryButton()
    private let deleteBtn = PrimaryButton()

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

        sheetView.layer.cornerRadius = 28
        sheetView.layer.cornerCurve = .continuous
        sheetView.clipsToBounds = true
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)

        titleLabel.text = "Delete Account?"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 22)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(titleLabel)

        subtitleLabel.text =
        """
        We are sad to see you leave.

        Before you decide to delete your account, please consider reaching out at contact@speakeasygo.com to talk to us about how we can improve.
        """

        subtitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.55)
        subtitleLabel.font = Constant.Font.geistRegular(size: 15)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(subtitleLabel)

        contactBtn.setTitle("Contact Us", for: .normal)
        contactBtn.setTitleColor(.systemBlue, for: .normal)
        contactBtn.titleLabel?.font = Constant.Font.geistMedium(size: 15)
        contactBtn.translatesAutoresizingMaskIntoConstraints = false
        contactBtn.addTarget(self, action: #selector(onClickContactUs), for: .touchUpInside)
        sheetView.addSubview(contactBtn)

        cancelBtn.configure(title: "Cancel", fontSize: 17, cornerRadius: 16)
        cancelBtn.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08)
        cancelBtn.setTitleColor(AppColor.primaryWhiteColor, for: .normal)
        cancelBtn.addTarget(self, action: #selector(onClickCancel), for: .touchUpInside)
        sheetView.addSubview(cancelBtn)

        deleteBtn.configure(title: "Delete account", fontSize: 17, cornerRadius: 16)
        deleteBtn.backgroundColor = UIColor.systemRed.withAlphaComponent(0.95)
        deleteBtn.setTitleColor(.white, for: .normal)
        deleteBtn.addTarget(self, action: #selector(onClickDelete), for: .touchUpInside)
        sheetView.addSubview(deleteBtn)

        NSLayoutConstraint.activate([

            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sheetView.heightAnchor.constraint(equalToConstant: 460),

            titleLabel.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 36),
            titleLabel.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            subtitleLabel.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),

            contactBtn.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
            contactBtn.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),

            cancelBtn.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            cancelBtn.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),
            cancelBtn.bottomAnchor.constraint(equalTo: deleteBtn.topAnchor, constant: -12),
            cancelBtn.heightAnchor.constraint(equalToConstant: 50),

            deleteBtn.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 24),
            deleteBtn.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -24),
            deleteBtn.bottomAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            deleteBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func animateIn() {
        sheetView.transform = CGAffineTransform(translationX: 0, y: 500)

        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
            self.blurView.alpha = 1
            self.sheetView.transform = .identity
        }
    }

    private func dismissSheet(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseIn]) {
            self.blurView.alpha = 0
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: 500)
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    @objc private func onClickContactUs() {
        AppHaptic.navigation()
        Navigate.externalURL(APIBuilder.supportURL)
    }
    
    @objc private func onClickCancel() {
        AppHaptic.navigation()
        dismissSheet()
    }
    
    @objc private func onClickDelete() {
        AppHaptic.destructive()
        deleteBtn.startLoading()
        authService.deleteAccount { isSuccess, errorMsg in
            self.deleteBtn.stopLoading()
            if isSuccess {
                AppHaptic.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.dismissSheet()
                    UserDefault.shared.emptyData()
                    AppDelegate.shared.changeRootViewController()
                }
            } else {
                AppHaptic.error()
                Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
}
