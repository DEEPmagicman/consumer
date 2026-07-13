//
//  SavedVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class SavedVC: UIViewController {

    private let backBtn = AppIconButton()
    private let titleLabel = UILabel()

    private let savedGridVC = SavedGridVC()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    private func setupUI() {
        setupNav()
        setupChild()
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

        titleLabel.text = "Saved"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 22)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }

    private func setupChild() {
        savedGridVC.onBrowseEvents = { [weak self] in
            self?.openDiscover()
        }

        addChild(savedGridVC)
        savedGridVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(savedGridVC.view)
        savedGridVC.didMove(toParent: self)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),

            savedGridVC.view.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            savedGridVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            savedGridVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            savedGridVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }

    private func openDiscover() {
        if let landingVC = presentingLandingVC() {
            landingVC.showDiscoverTab()
            navigationController?.dismiss(animated: true)
            return
        }

        NotificationCenter.default.post(name: .openDiscoverTab, object: nil)

        if let navigationController {
            navigationController.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func presentingLandingVC() -> NewLandingVC? {
        func landingVC(in hierarchy: UIViewController?) -> NewLandingVC? {
            var current = hierarchy

            while let viewController = current {
                if let landingVC = viewController as? NewLandingVC {
                    return landingVC
                }

                current = viewController.parent
            }

            return nil
        }

        var controller: UIViewController? =
            navigationController?.presentingViewController ??
            presentingViewController

        while let current = controller {
            if let landingVC = landingVC(in: current) {
                return landingVC
            }

            controller = current.presentingViewController
        }

        return nil
    }
}
