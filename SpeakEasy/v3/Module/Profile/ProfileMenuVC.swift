//
//  ProfileVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 19/05/26.
//

import UIKit
import SDWebImage

final class ProfileMenuVC: UIViewController {

    private let backBtn = AppIconButton()
    private let avatarContainer = UIView()
    private let imageView = UIImageView()
    private let firstNameLetter = UILabel()
    private var nameLabel = UILabel()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let topActionsCard = ProfileCardView()
    private let profileCard = ProfileCardView()
    private let settingsCard = ProfileCardView()
    private let logoutCard = ProfileCardView()
    private var versionLabel = UILabel()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let darkBlurOverlay = UIView()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupUserData()
        observeProfileUpdate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient(colorAlpha: 0.30)
        avatarContainer.layer.cornerRadius = avatarContainer.bounds.height / 2
        imageView.layer.cornerRadius = imageView.bounds.height / 2
    }
    
    private func observeProfileUpdate() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onProfileUpdated(_:)),
            name: .userProfileDidUpdate,
            object: nil
        )
    }

    @objc private func onProfileUpdated(_ notification: Notification) {
        setupUserData()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear

        blurView.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blurView.alpha = 1
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView, at: 0)

        darkBlurOverlay.backgroundColor = UIColor(hex: "#191919").withAlphaComponent(0.75)
        darkBlurOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(darkBlurOverlay, aboveSubview: blurView)
        
        setupBackButton()
        setupAvatar()
        setupScroll()
        setupTopActions()
        setupMenuCards()
        setupConstraints()
    }

    private func setupBackButton() {
        backBtn.iconTypeValue = AppIconType.close.rawValue
        backBtn.iconSize = 14
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)
    }

    private func setupAvatar() {
        
        avatarContainer.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        avatarContainer.clipsToBounds = true
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarContainer)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(imageView)

        firstNameLetter.textColor = .white
        firstNameLetter.font = Constant.Font.geistMedium(size: 40)
        firstNameLetter.textAlignment = .center
        firstNameLetter.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(firstNameLetter)

        nameLabel = Utility.main.makeLabel("", font: Constant.Font.geistMedium(size: 22))
        view.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),

            firstNameLetter.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            firstNameLetter.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor)
        ])
    }

    private func setupScroll() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.bounces = false
        scrollView.isScrollEnabled = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)

        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }

    private func setupTopActions() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 0
        stack.backgroundColor = .clear
        stack.translatesAutoresizingMaskIntoConstraints = false
        topActionsCard.addSubview(stack)

        stack.addArrangedSubview(makeTopAction(title: "My orders", icon: UIImage(resource: .myOrderIc), tag: 0))
        stack.addArrangedSubview(makeTopAction(title: "Saved", icon: UIImage(resource: .savedIc), tag: 1))
        stack.addArrangedSubview(makeTopAction(title: "Favorites", icon: UIImage(resource: .venuesIc), tag: 2))

        contentView.addSubview(topActionsCard)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topActionsCard.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: topActionsCard.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: topActionsCard.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: topActionsCard.bottomAnchor, constant: -26)
        ])
    }

    private func setupMenuCards() {
        contentView.addSubview(profileCard)
        contentView.addSubview(settingsCard)
        contentView.addSubview(logoutCard)

        addRows(
            to: profileCard,
            rows: [
                ProfileMenuRow(title: "Profile", icon: UIImage(resource: .profileIc), action: #selector(onClickProfile)),
                ProfileMenuRow(title: "Account info", icon: UIImage(resource: .accountInfoIC), action: #selector(onClickAccountInfo))
            ]
        )

        addRows(
            to: settingsCard,
            rows: [
                ProfileMenuRow(title: "Help", icon: UIImage(resource: .helpIc), action: #selector(onClickHelp)),
                ProfileMenuRow(title: "Notification settings", icon: UIImage(resource: .notificationIc), action: #selector(onClickNotificationSettings))
            ]
        )

        addRows(
            to: logoutCard,
            rows: [
                ProfileMenuRow(title: "Log out", icon: UIImage(resource: .logOutIc), action: #selector(onClickLogOut)),
                ProfileMenuRow(title: "Delete Account", icon: UIImage(systemName: "trash"), action: #selector(onClickDelete))
            ]
        )

        let versionLabelText = "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")"
        versionLabel = Utility.main.makeLabel(versionLabelText, font: Constant.Font.geistRegular(size: 12))
        contentView.addSubview(versionLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            darkBlurOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            darkBlurOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            darkBlurOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            darkBlurOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.widthAnchor.constraint(equalToConstant: 40),
            backBtn.heightAnchor.constraint(equalToConstant: 40),

            avatarContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            avatarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: 100),
            avatarContainer.heightAnchor.constraint(equalToConstant: 100),

            nameLabel.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            scrollView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 32),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            topActionsCard.topAnchor.constraint(equalTo: contentView.topAnchor),
            topActionsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            topActionsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            topActionsCard.heightAnchor.constraint(equalToConstant: 120),

            profileCard.topAnchor.constraint(equalTo: topActionsCard.bottomAnchor, constant: 10),
            profileCard.leadingAnchor.constraint(equalTo: topActionsCard.leadingAnchor),
            profileCard.trailingAnchor.constraint(equalTo: topActionsCard.trailingAnchor),
            profileCard.heightAnchor.constraint(equalToConstant: 114),

            settingsCard.topAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: 10),
            settingsCard.leadingAnchor.constraint(equalTo: topActionsCard.leadingAnchor),
            settingsCard.trailingAnchor.constraint(equalTo: topActionsCard.trailingAnchor),
            settingsCard.heightAnchor.constraint(equalToConstant: 114),

            logoutCard.topAnchor.constraint(equalTo: settingsCard.bottomAnchor, constant: 10),
            logoutCard.leadingAnchor.constraint(equalTo: topActionsCard.leadingAnchor),
            logoutCard.trailingAnchor.constraint(equalTo: topActionsCard.trailingAnchor),
            logoutCard.heightAnchor.constraint(equalToConstant: 114),

            versionLabel.topAnchor.constraint(equalTo: logoutCard.bottomAnchor, constant: 44),
            versionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            versionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func makeTopAction(title: String, icon: UIImage?, tag: Int) -> UIControl {
        let control = UIControl()
        control.tag = tag
        control.heightAnchor.constraint(equalToConstant: 60).isActive = true
        control.addTarget(self, action: #selector(topActionTapped(_:)), for: .touchUpInside)
        
        let imageView = UIImageView(image: icon)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(imageView)

        let label = Utility.main.makeLabel(title, font: Constant.Font.geistRegular(size: 15))
        control.addSubview(label)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: control.topAnchor, constant: 0),
            imageView.centerXAnchor.constraint(equalTo: control.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            label.centerXAnchor.constraint(equalTo: control.centerXAnchor)
        ])

        return control
    }
    
    @objc private func topActionTapped(_ sender: UIControl) {
        switch sender.tag {
        case 0:
            Navigate.to.myOrdersVC(self)

        case 1:
            Navigate.to.savedVC(self)

        case 2:
            Navigate.to.venuesVC(self)

        default:
            break
        }
    }

    private func addRows(to card: UIView, rows: [ProfileMenuRow]) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])

        for (index, row) in rows.enumerated() {
            let rowView = makeMenuRow(row)
            stack.addArrangedSubview(rowView)

            if index < rows.count - 1 {
                let line = UIView()
                line.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08)
                line.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stack.addArrangedSubview(line)
            }
        }
    }

    private func makeMenuRow(_ row: ProfileMenuRow) -> UIControl {
        let control = UIControl()
        control.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let iconView = UIImageView(image: row.icon)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(iconView)

        let label = Utility.main.makeLabel(row.title, textAlignment: .left, font: Constant.Font.geistRegular(size: 16))
        control.addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: control.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: control.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: control.trailingAnchor)
        ])
        
        if let action = row.action {
            control.addTarget(self, action: action, for: .touchUpInside)
        }

        return control
    }

    private func setupUserData() {
        guard let user = UserDefault.shared.user else {
            imageView.isHidden = true
            firstNameLetter.isHidden = false
            nameLabel.text = "Sign in"
            firstNameLetter.text = "P"
            return
        }

        let imageUrl = user.image.key
        let firstLetter = user.firstName.first ?? Character("P")

        nameLabel.text = "\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespaces)

        if !imageUrl.isEmpty {
            imageView.isHidden = false
            firstNameLetter.isHidden = true

            imageView.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(resource: .profileBgPlaceholder)
            )
        } else {
            imageView.isHidden = false
            if let _ = user.firstName.first {
                imageView.image = UIImage(resource: .profileBg)
                firstNameLetter.isHidden = false
            } else {
                imageView.image = UIImage(resource: .profileBgPlaceholder)
                firstNameLetter.isHidden = true
            }
            firstNameLetter.text = String(firstLetter).uppercased()
        }
    }

    @objc private func onClickBack() {
        popProfileMenuVC(self)
    }
    
    func popProfileMenuVC(_ sender: UIViewController) {
        guard let navigation = sender.navigationController else { return }

           let transition = CATransition()
           transition.duration = 0.35
           transition.type = .reveal
           transition.subtype = .fromBottom
           transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

           navigation.view.layer.add(transition, forKey: nil)
           navigation.popViewController(animated: false)
    }
    
    @objc private func onClickProfile() {
        Navigate.to.editProfileVC(self)
    }

    @objc private func onClickAccountInfo() {
        Navigate.to.accountInfoVC(self)
    }
    
    @objc private func onClickDelete() {
        Navigate.to.deleteAccountBottomSheet(self)
    }
    
    @objc private func onClickHelp() {
        Navigate.externalURL(APIBuilder.supportURL)
    }
    
    @objc private func onClickNotificationSettings() {
        Navigate.to.notificationSettingsVC(self)
    }
    
    @objc private func onClickLogOut() {
        Navigate.to.logoutConfirmationBottomSheet(self)
    }
}

private struct ProfileMenuRow {
    let title: String
    let icon: UIImage?
    let action: Selector?
}

final class ProfileCardView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor(hex: "#9B9B9B").withAlphaComponent(0.12)
        layer.cornerRadius = 21
        layer.cornerCurve = .continuous
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
    }
}
