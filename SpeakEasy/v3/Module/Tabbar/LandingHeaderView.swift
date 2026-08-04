//
//  LandingHeaderViewDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 22/05/26.
//

import UIKit
import SDWebImage

protocol LandingHeaderViewDelegate: AnyObject {
    func landingHeaderDidTapProfile(_ view: LandingHeaderView)
    func landingHeaderDidTapMap(_ view: LandingHeaderView)
}

final class LandingHeaderView: UIView {

    weak var delegate: LandingHeaderViewDelegate?
    var onCalendarTap: (() -> Void)?

    private let avatarContainer = UIView()
    private let imageView = UIImageView()
    private let firstNameLetter = UILabel()
    private let signInIconView = UIImageView()
    private let titleLabel = UILabel()

    private let mapButton = AppIconButton()
    private let calendarButton = AppIconButton()
    private let profileButton = UIButton(type: .system)

    private var currentVC = UIViewController()
    private var titleToMapTrailingConstraint: NSLayoutConstraint?
    private var titleToCalendarTrailingConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        observeProfileUpdate()
        reloadUser()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        observeProfileUpdate()
        reloadUser()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarContainer.layer.cornerRadius = avatarContainer.bounds.height / 2
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        firstNameLetter.layer.cornerRadius = firstNameLetter.bounds.height / 2
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        avatarContainer.clipsToBounds = true
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarContainer)

        signInIconView.image = UIImage(resource: .profileIcon)
        signInIconView.contentMode = .scaleAspectFit
        signInIconView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(signInIconView)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(imageView)

        firstNameLetter.textColor = AppColor.primaryWhiteColor
        firstNameLetter.textAlignment = .center
        firstNameLetter.font = Constant.Font.interRegular(size: 16)
        firstNameLetter.clipsToBounds = true
        firstNameLetter.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(firstNameLetter)

        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        profileButton.backgroundColor = .clear
        profileButton.addTarget(self, action: #selector(onProfile), for: .touchUpInside)
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileButton)

        mapButton.backgroundColor = .clear
        mapButton.addTarget(self, action: #selector(onClickMap), for: .touchUpInside)
        mapButton.translatesAutoresizingMaskIntoConstraints = false
        
        mapButton.buttonSize = 36
        mapButton.iconSize = 13
        mapButton.iconTypeValue = "map"
        addSubview(mapButton)

        calendarButton.backgroundColor = .clear
        calendarButton.addTarget(self, action: #selector(onClickCalendar), for: .touchUpInside)
        calendarButton.translatesAutoresizingMaskIntoConstraints = false
        calendarButton.buttonSize = 36
        calendarButton.iconSize = 13
        calendarButton.iconTintColor = .white
        calendarButton.iconTypeValue = AppIconType.calendar.rawValue
        calendarButton.isHidden = true
        addSubview(calendarButton)

        titleToMapTrailingConstraint = titleLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: mapButton.leadingAnchor,
            constant: -12
        )
        titleToCalendarTrailingConstraint = titleLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: calendarButton.leadingAnchor,
            constant: -12
        )
        titleToMapTrailingConstraint?.isActive = true
        titleToCalendarTrailingConstraint?.isActive = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40),

            avatarContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: 36),
            avatarContainer.heightAnchor.constraint(equalToConstant: 36),

            signInIconView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            signInIconView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            signInIconView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            signInIconView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),

            firstNameLetter.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            firstNameLetter.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            firstNameLetter.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            firstNameLetter.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),

            profileButton.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            profileButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            profileButton.topAnchor.constraint(equalTo: topAnchor),
            profileButton.bottomAnchor.constraint(equalTo: bottomAnchor),

            mapButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13),
            mapButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            mapButton.widthAnchor.constraint(equalToConstant: 32),
            mapButton.heightAnchor.constraint(equalToConstant: 32),

            calendarButton.trailingAnchor.constraint(equalTo: mapButton.leadingAnchor, constant: -12),
            calendarButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            calendarButton.widthAnchor.constraint(equalToConstant: 32),
            calendarButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        if Utility.main.topViewController()?.navigationController?.navigationController == nil {
            currentVC = Utility.main.topViewController() ?? UIViewController()
        } else {
            currentVC = Utility.main.topViewController()?.navigationController ?? UIViewController()
        }
    }

    func setMapHidden(_ hidden: Bool) {
        mapButton.isHidden = hidden
    }

    func setCalendarHidden(_ hidden: Bool) {
        calendarButton.isHidden = hidden
        titleToMapTrailingConstraint?.isActive = hidden
        titleToCalendarTrailingConstraint?.isActive = !hidden
    }

    func setCalendarSelected(_ selected: Bool) {
        calendarButton.buttonFillColor = selected ? .white : nil
        calendarButton.iconTintColor = selected ? .black : .white
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
        if let payload = notification.object as? UserProfileUpdatePayload {
            applyProfileUpdate(payload)
        } else {
            reloadUser()
        }
    }

    private func applyProfileUpdate(_ payload: UserProfileUpdatePayload) {
        let firstName = payload.firstName ?? UserDefault.shared.user?.firstName ?? ""
        titleLabel.text = firstName.isEmpty ? "Profile" : firstName

        if let imageUrl = payload.imageUrl, !imageUrl.isEmpty {
            imageView.isHidden = false
            firstNameLetter.isHidden = true
            signInIconView.isHidden = true
            imageView.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(resource: .profileIcon),
                options: [.refreshCached]
            )
            return
        }

        reloadUser()
    }

    func reloadUser() {
        guard let user = UserDefault.shared.user else {
            imageView.isHidden = true
            firstNameLetter.isHidden = true
            signInIconView.isHidden = false
            titleLabel.text = "Sign In"
            return
        }

        signInIconView.isHidden = true
        titleLabel.text = user.firstName.isEmpty ? "Profile" : user.firstName

        let imageUrl = user.image.key
        let firstLetter = user.firstName.first ?? Character("P")

        if !imageUrl.isEmpty {
            imageView.isHidden = false
            firstNameLetter.isHidden = true
            imageView.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(resource: .profileIcon),
                options: [.refreshCached]
            )
        } else {
            imageView.isHidden = false
            imageView.image = UIImage(resource: .signInBgIcon)
            firstNameLetter.isHidden = false
            firstNameLetter.text = String(firstLetter).uppercased()
        }
    }

    @objc private func onProfile() {
        AppHaptic.navigation()
        LoginRequiredCoordinator.perform(from: currentVC) { [weak self] in
            guard let self else { return }
            Navigate.to.profileMenuVC(self.currentVC)
        }
//        delegate?.landingHeaderDidTapProfile(self)
    }

    @objc private func onClickMap() {
        AppHaptic.navigation()
        Navigate.to.gotoMapVC(currentVC)
//        delegate?.landingHeaderDidTapMap(self)
    }

    @objc private func onClickCalendar() {
        AppHaptic.navigation()
        onCalendarTap?()
    }
}
