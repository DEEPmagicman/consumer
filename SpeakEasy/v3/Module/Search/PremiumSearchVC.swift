//
//  PremiumSearchVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 16/06/26.
//

import UIKit

final class PremiumSearchVC: UIViewController {

    private let headerView = PremiumSearchHeaderView()
    private let contentView = UIView()
    private var searchResults: [PremiumExperienceItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        headerView.reloadUser()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    private func setupUI() {
        setupHeader()
        setupContent()
        setupConstraints()
    }

    private func setupHeader() {

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.delegate = self
        view.addSubview(headerView)
    }

    private func setupContent() {

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear

        view.addSubview(contentView)

        // Temporary empty state
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Search results will appear here."
        label.textColor = .white.withAlphaComponent(0.65)
        label.font = Constant.Font.geistMedium(size: 16)

        contentView.addSubview(label)

        NSLayoutConstraint.activate([

            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    // MARK: Constraints

    private func setupConstraints() {

        NSLayoutConstraint.activate([

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 40),

            contentView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension PremiumSearchVC: PremiumSearchHeaderViewDelegate {
    func premiumSearchHeaderDidTapProfile(_ view: PremiumSearchHeaderView) {
        if UserDefault.shared.isLoggedIn == true {
            Navigate.to.profileMenuVC(self)
        } else {
            Navigate.to.openPhoneLoginPopup(self)
        }
    }
    
    func premiumSearchHeaderDidTapMap(_ view: PremiumSearchHeaderView) {
        Navigate.to.gotoMapVC(self)
    }
    
    func premiumSearchHeaderDidTapSearch(_ view: PremiumSearchHeaderView) {
        
    }
    
    func premiumSearchHeaderDidTapClear(_ view: PremiumSearchHeaderView) {
        
    }
}
