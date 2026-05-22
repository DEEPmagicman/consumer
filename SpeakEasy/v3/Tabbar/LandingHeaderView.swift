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

    private let avatarContainer = UIView()
    private let imageView = UIImageView()
    private let firstNameLetter = UILabel()
    private let signInIconView = UIImageView()
    private let titleLabel = UILabel()

    private let mapButtonContainer = LiquidGlassBackgroundView()
    private let mapButton = UIButton(type: .system)
    private let profileButton = UIButton(type: .system)

    private var currentVC = UIViewController()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        reloadUser()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        reloadUser()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarContainer.layer.cornerRadius = avatarContainer.bounds.height / 2
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        firstNameLetter.layer.cornerRadius = firstNameLetter.bounds.height / 2
        mapButtonContainer.layer.cornerRadius = mapButtonContainer.bounds.height / 2
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

        mapButtonContainer.cornerRadius = 16
        mapButtonContainer.borderWidth = 0.5
        mapButtonContainer.overrideBackgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08)
        mapButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mapButtonContainer)

        let mapIcon = UIImageView(image: UIImage(named: "mapIcon"))
        mapIcon.tintColor = AppColor.primaryWhiteColor
        mapIcon.contentMode = .scaleAspectFit
        mapIcon.translatesAutoresizingMaskIntoConstraints = false
        mapButtonContainer.addSubview(mapIcon)

        mapButton.addTarget(self, action: #selector(onMap), for: .touchUpInside)
        mapButton.translatesAutoresizingMaskIntoConstraints = false
        mapButtonContainer.addSubview(mapButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40),

            avatarContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: 30),
            avatarContainer.heightAnchor.constraint(equalToConstant: 30),

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
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: mapButtonContainer.leadingAnchor, constant: -12),

            profileButton.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            profileButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            profileButton.topAnchor.constraint(equalTo: topAnchor),
            profileButton.bottomAnchor.constraint(equalTo: bottomAnchor),

            mapButtonContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mapButtonContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            mapButtonContainer.widthAnchor.constraint(equalToConstant: 32),
            mapButtonContainer.heightAnchor.constraint(equalToConstant: 32),

            mapIcon.centerXAnchor.constraint(equalTo: mapButtonContainer.centerXAnchor),
            mapIcon.centerYAnchor.constraint(equalTo: mapButtonContainer.centerYAnchor),
            mapIcon.widthAnchor.constraint(equalToConstant: 13),
            mapIcon.heightAnchor.constraint(equalToConstant: 13),

            mapButton.topAnchor.constraint(equalTo: mapButtonContainer.topAnchor),
            mapButton.leadingAnchor.constraint(equalTo: mapButtonContainer.leadingAnchor),
            mapButton.trailingAnchor.constraint(equalTo: mapButtonContainer.trailingAnchor),
            mapButton.bottomAnchor.constraint(equalTo: mapButtonContainer.bottomAnchor)
        ])
        
        if Utility.main.topViewController()?.navigationController?.navigationController == nil {
            currentVC = Utility.main.topViewController() ?? UIViewController()
        } else {
            currentVC = Utility.main.topViewController()?.navigationController ?? UIViewController()
        }
    }

    func setMapHidden(_ hidden: Bool) {
        mapButtonContainer.isHidden = hidden
    }

    func reloadUser() {
        guard let user = UserDefault.shared.user else {
            imageView.isHidden = true
            firstNameLetter.isHidden = true
            signInIconView.isHidden = false
            titleLabel.text = "Sign in"
            return
        }

        signInIconView.isHidden = true
        titleLabel.text = user.firstName.isEmpty ? "Profile" : user.firstName

        let imageUrl = user.image.key
        let firstLetter = user.firstName.first ?? Character("P")

        if !imageUrl.isEmpty {
            imageView.isHidden = false
            firstNameLetter.isHidden = true
            imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: UIImage(resource: .profileIcon))
        } else {
            imageView.isHidden = false
            imageView.image = UIImage(resource: .signInBgIcon)
            firstNameLetter.isHidden = false
            firstNameLetter.text = String(firstLetter).uppercased()
        }
    }

    @objc private func onProfile() {
        if UserDefault.shared.isLoggedIn == true {
            Navigate.to.profileMenuVC(currentVC)
        } else {
            Navigate.to.openPhoneLoginPopup(currentVC)
        }
//        delegate?.landingHeaderDidTapProfile(self)
    }

    @objc private func onMap() {
        Navigate.to.gotoMapVC(currentVC)
//        delegate?.landingHeaderDidTapMap(self)
    }
}
