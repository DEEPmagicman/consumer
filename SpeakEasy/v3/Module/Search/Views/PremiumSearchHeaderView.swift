//
//  PremiumSearchHeaderViewDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 16/06/26.
//

import UIKit
import SDWebImage

protocol PremiumSearchHeaderViewDelegate: AnyObject {
    func premiumSearchHeaderDidTapProfile(_ view: PremiumSearchHeaderView)
    func premiumSearchHeaderDidTapMap(_ view: PremiumSearchHeaderView)
    func premiumSearchHeaderDidTapSearch(_ view: PremiumSearchHeaderView)
    func premiumSearchHeaderDidTapClear(_ view: PremiumSearchHeaderView)
}

final class PremiumSearchHeaderView: UIView {
    
    weak var delegate: PremiumSearchHeaderViewDelegate?
    
    // MARK: Profile
    
    private let avatarGlassView = LiquidGlassBackgroundView(
        cornerRadius: 16,
        fillColor: AppColor.primaryWhiteColor.withAlphaComponent(0.10),
        borderColor: AppColor.primaryWhiteColor.withAlphaComponent(0.18),
        borderWidth: 0.8
    )
    
    private let imageView = UIImageView()
    private let firstNameLetter = UILabel()
    private let signInIconView = UIImageView()
    
    private let profileButton = UIButton(type: .system)
    
    // MARK: Search
    
    let searchView = PremiumSearchBarView()
    
    // MARK: Map
    
    private let mapButton = UIButton(type: .system)
    
    private let mapGlassView = LiquidGlassBackgroundView(
        cornerRadius: 18,
        fillColor: AppColor.primaryWhiteColor.withAlphaComponent(0.08),
        borderColor: AppColor.primaryWhiteColor.withAlphaComponent(0.18),
        borderWidth: 0.8
    )
    
    private var currentVC = UIViewController()
    
    // MARK: Init
    
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
        
        avatarGlassView.layer.cornerRadius = avatarGlassView.bounds.height / 2
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        firstNameLetter.layer.cornerRadius = firstNameLetter.bounds.height / 2
    }
    
    // MARK: Setup
    
    private func setup() {
        
        translatesAutoresizingMaskIntoConstraints = false

        avatarGlassView.translatesAutoresizingMaskIntoConstraints = false
        avatarGlassView.clipsToBounds = true
        addSubview(avatarGlassView)
        
        signInIconView.translatesAutoresizingMaskIntoConstraints = false
        signInIconView.image = UIImage(resource: .profileIcon)
        signInIconView.tintColor = .white
        signInIconView.contentMode = .scaleAspectFit
        avatarGlassView.addSubview(signInIconView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        avatarGlassView.addSubview(imageView)
        
        firstNameLetter.translatesAutoresizingMaskIntoConstraints = false
        firstNameLetter.textAlignment = .center
        firstNameLetter.font = Constant.Font.interRegular(size: 16)
        firstNameLetter.textColor = .white
        firstNameLetter.clipsToBounds = true
        avatarGlassView.addSubview(firstNameLetter)
        
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.backgroundColor = .clear
        profileButton.addTarget(
            self,
            action: #selector(onProfile),
            for: .touchUpInside
        )
        
        addSubview(profileButton)
        
        searchView.translatesAutoresizingMaskIntoConstraints = false
        
        searchView.onTap = { [weak self] in
            guard let self else { return }
            self.delegate?.premiumSearchHeaderDidTapSearch(self)
        }
        
        searchView.onClear = { [weak self] in
            guard let self else { return }
            self.delegate?.premiumSearchHeaderDidTapClear(self)
        }
        
        addSubview(searchView)
        
        mapButton.translatesAutoresizingMaskIntoConstraints = false
        mapButton.backgroundColor = .clear
        mapButton.addTarget(
            self,
            action: #selector(onMap),
            for: .touchUpInside
        )
        
        addSubview(mapButton)
        
        mapGlassView.translatesAutoresizingMaskIntoConstraints = false
        mapGlassView.isUserInteractionEnabled = false
        mapButton.insertSubview(mapGlassView, at: 0)
        
        let mapIcon = UIImageView()
        mapIcon.translatesAutoresizingMaskIntoConstraints = false
        mapIcon.image = UIImage(resource: .mapIcon)
        mapIcon.tintColor = .white
        mapIcon.contentMode = .scaleAspectFit
        
        mapButton.addSubview(mapIcon)
        
        NSLayoutConstraint.activate([
            
            heightAnchor.constraint(equalToConstant: 40),
            
            avatarGlassView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarGlassView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarGlassView.widthAnchor.constraint(equalToConstant: 32),
            avatarGlassView.heightAnchor.constraint(equalToConstant: 32),
            
            signInIconView.centerXAnchor.constraint(equalTo: avatarGlassView.centerXAnchor),
            signInIconView.centerYAnchor.constraint(equalTo: avatarGlassView.centerYAnchor),
            signInIconView.widthAnchor.constraint(equalTo: avatarGlassView.widthAnchor),
            signInIconView.heightAnchor.constraint(equalTo: avatarGlassView.heightAnchor),
            
            imageView.topAnchor.constraint(equalTo: avatarGlassView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: avatarGlassView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: avatarGlassView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: avatarGlassView.bottomAnchor),
            
            firstNameLetter.topAnchor.constraint(equalTo: avatarGlassView.topAnchor),
            firstNameLetter.leadingAnchor.constraint(equalTo: avatarGlassView.leadingAnchor),
            firstNameLetter.trailingAnchor.constraint(equalTo: avatarGlassView.trailingAnchor),
            firstNameLetter.bottomAnchor.constraint(equalTo: avatarGlassView.bottomAnchor),
            
            profileButton.leadingAnchor.constraint(equalTo: avatarGlassView.leadingAnchor),
            profileButton.topAnchor.constraint(equalTo: topAnchor),
            profileButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            mapButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            mapButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            mapButton.widthAnchor.constraint(equalToConstant: 36),
            mapButton.heightAnchor.constraint(equalToConstant: 36),
            
            mapGlassView.leadingAnchor.constraint(equalTo: mapButton.leadingAnchor),
            mapGlassView.trailingAnchor.constraint(equalTo: mapButton.trailingAnchor),
            mapGlassView.topAnchor.constraint(equalTo: mapButton.topAnchor),
            mapGlassView.bottomAnchor.constraint(equalTo: mapButton.bottomAnchor),
            
            mapIcon.centerXAnchor.constraint(equalTo: mapButton.centerXAnchor),
            mapIcon.centerYAnchor.constraint(equalTo: mapButton.centerYAnchor),
            mapIcon.widthAnchor.constraint(equalToConstant: 14),
            mapIcon.heightAnchor.constraint(equalToConstant: 14),
            
            searchView.leadingAnchor.constraint(equalTo: avatarGlassView.trailingAnchor, constant: 16),
            searchView.trailingAnchor.constraint(equalTo: mapButton.leadingAnchor, constant: -16),
            searchView.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchView.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        if Utility.main.topViewController()?.navigationController?.navigationController == nil {
            currentVC = Utility.main.topViewController() ?? UIViewController()
        } else {
            currentVC = Utility.main.topViewController()?.navigationController ?? UIViewController()
        }
    }
    
    // MARK: - Actions

    @objc
    private func onProfile() {
        delegate?.premiumSearchHeaderDidTapProfile(self)
    }

    @objc
    private func onMap() {
        delegate?.premiumSearchHeaderDidTapMap(self)
    }

    // MARK: - Helpers

    func showSignInState() {

        imageView.isHidden = true
        firstNameLetter.isHidden = true
        signInIconView.isHidden = false
    }

    func showProfilePlaceholder(letter: String) {

        imageView.image = UIImage(resource: .signInBgIcon)
        imageView.isHidden = false

        firstNameLetter.text = letter.uppercased()
        firstNameLetter.isHidden = false

        signInIconView.isHidden = true
    }

    func updateProfileImage(url: String?) {

        guard
            let url,
            !url.isEmpty
        else {
            return
        }

        imageView.sd_setImage(
            with: URL(string: url),
            placeholderImage: UIImage(resource: .profileIcon)
        )

        imageView.isHidden = false
        firstNameLetter.isHidden = true
        signInIconView.isHidden = true
    }

    func setMapHidden(_ hidden: Bool) {
        mapButton.isHidden = hidden
    }

    func setProfileHidden(_ hidden: Bool) {
        avatarGlassView.isHidden = hidden
        profileButton.isHidden = hidden
    }

    func focusSearch() {
        searchView.focus()
    }

    func resignSearch() {
        searchView.resign()
    }
    
    func reloadUser() {
        
        guard let user = UserDefault.shared.user else {
            
            imageView.isHidden = true
            firstNameLetter.isHidden = true
            signInIconView.isHidden = false
            
            return
        }
        
        signInIconView.isHidden = true
        
        let imageUrl = user.image.key
        let firstLetter = user.firstName.first ?? Character("P")
        
        if !imageUrl.isEmpty {
            
            imageView.isHidden = false
            firstNameLetter.isHidden = true
            
            imageView.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(resource: .profileIcon)
            )
            
        } else {
            
            imageView.isHidden = false
            imageView.image = UIImage(resource: .signInBgIcon)
            
            firstNameLetter.isHidden = false
            firstNameLetter.text = String(firstLetter).uppercased()
        }
    }
}
