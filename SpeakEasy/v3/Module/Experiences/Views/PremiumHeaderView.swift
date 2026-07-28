//
//  PremiumHeaderView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 15/06/26.
//

import UIKit
import SDWebImage

protocol PremiumHeaderViewDelegate: AnyObject {
    func premiumHeaderDidTapProfile(_ view: PremiumHeaderView)
    func premiumHeaderDidTapLocation(_ view: PremiumHeaderView)
    func premiumHeaderDidTapHelp(_ view: PremiumHeaderView)
}

final class PremiumHeaderView: UIView {
    
    weak var delegate: PremiumHeaderViewDelegate?
    
    // MARK: - Profile
    
    private let avatarGlassView = UIView()
    
    private let imageView = UIImageView()
    private let firstNameLetter = UILabel()
    private let signInIconView = UIImageView()
    private let profileButton = UIButton(type: .system)
    
    // MARK: - Location
    
    private let locationView = PremiumLocationView()
    
    private let locationGlassView = LiquidGlassBackgroundView(
        cornerRadius: 16,
        fillColor: AppColor.primaryWhiteColor.withAlphaComponent(0.08),
        borderColor: AppColor.primaryWhiteColor.withAlphaComponent(0.18),
        borderWidth: 0.8
    )
    
    // MARK: - Help
    
    private let helpButton = UIButton(type: .system)
    
    private let helpGlassView = LiquidGlassBackgroundView(
        cornerRadius: 18,
        fillColor: AppColor.primaryWhiteColor.withAlphaComponent(0.05),
        borderColor: AppColor.primaryWhiteColor.withAlphaComponent(0.18),
        borderWidth: 0.8
    )
    
    private var currentVC = UIViewController()
    
    // MARK: -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
        
        configure(city: UserDefault.shared.activeCity)
        reloadUser()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
        
        configure(city: UserDefault.shared.activeCity)
        reloadUser()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        avatarGlassView.layer.cornerRadius = avatarGlassView.bounds.height / 2
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        firstNameLetter.layer.cornerRadius = firstNameLetter.bounds.height / 2
        applyHelpButtonShape()
    }
    
    // MARK: -
    
    private func setup() {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        // MARK: Avatar
        
        avatarGlassView.translatesAutoresizingMaskIntoConstraints = false
        avatarGlassView.clipsToBounds = true
        addSubview(avatarGlassView)
        
        signInIconView.image = UIImage(resource: .profileIcon)
        signInIconView.tintColor = .white
        signInIconView.contentMode = .scaleAspectFit
        signInIconView.translatesAutoresizingMaskIntoConstraints = false
        avatarGlassView.addSubview(signInIconView)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        avatarGlassView.addSubview(imageView)
        
        firstNameLetter.textAlignment = .center
        firstNameLetter.textColor = .white
        firstNameLetter.font = Constant.Font.interRegular(size: 16)
        firstNameLetter.translatesAutoresizingMaskIntoConstraints = false
        firstNameLetter.clipsToBounds = true
        avatarGlassView.addSubview(firstNameLetter)
        
        profileButton.backgroundColor = .clear
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.addTarget(self, action: #selector(onProfile), for: .touchUpInside)
        addSubview(profileButton)
        
        // MARK: Location
        
        locationView.addTarget(
            self,
            action: #selector(onLocation),
            for: .touchUpInside
        )
        addSubview(locationView)
        
        // MARK: Help
        
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        helpButton.backgroundColor = .clear
        helpButton.layer.cornerCurve = .continuous
        helpButton.setTitle("?", for: .normal)
        helpButton.setTitleColor(.white, for: .normal)
        helpButton.titleLabel?.font = Constant.Font.geistMedium(size: 14)
        
        helpButton.addTarget(
            self,
            action: #selector(onHelp),
            for: .touchUpInside
        )
        
        addSubview(helpButton)
        
        helpGlassView.translatesAutoresizingMaskIntoConstraints = false
        helpGlassView.isUserInteractionEnabled = false
        helpButton.insertSubview(helpGlassView, at: 0)
        applyHelpButtonShape()
        
        setupConstraints()
        
        if Utility.main.topViewController()?.navigationController?.navigationController == nil {
            currentVC = Utility.main.topViewController() ?? UIViewController()
        } else {
            currentVC = Utility.main.topViewController()?.navigationController ?? UIViewController()
        }
    }
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            
            heightAnchor.constraint(equalToConstant: 40),
            
            avatarGlassView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarGlassView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarGlassView.widthAnchor.constraint(equalToConstant: 36),
            avatarGlassView.heightAnchor.constraint(equalToConstant: 36),
            
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
            profileButton.trailingAnchor.constraint(equalTo: locationView.leadingAnchor),
            profileButton.topAnchor.constraint(equalTo: topAnchor),
            profileButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            helpButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            helpButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            helpButton.widthAnchor.constraint(equalToConstant: 36),
            helpButton.heightAnchor.constraint(equalToConstant: 36),
            
            helpGlassView.topAnchor.constraint(equalTo: helpButton.topAnchor),
            helpGlassView.leadingAnchor.constraint(equalTo: helpButton.leadingAnchor),
            helpGlassView.trailingAnchor.constraint(equalTo: helpButton.trailingAnchor),
            helpGlassView.bottomAnchor.constraint(equalTo: helpButton.bottomAnchor),
            
            locationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            locationView.centerYAnchor.constraint(equalTo: centerYAnchor),
            locationView.heightAnchor.constraint(equalToConstant: 36),
            locationView.leadingAnchor.constraint(greaterThanOrEqualTo: avatarGlassView.trailingAnchor, constant: 16),

            locationView.trailingAnchor.constraint(
                lessThanOrEqualTo: helpButton.leadingAnchor,
                constant: -16
            )
        ])
    }
    
    // MARK: - Public
    
    func configure(city: String) {
        locationView.configure(city: city)
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
    
    // MARK: - Actions
    
    @objc
    private func onProfile() {
        AppHaptic.navigation()
        delegate?.premiumHeaderDidTapProfile(self)
    }
    
    @objc
    private func onLocation() {
        AppHaptic.selectionChanged()
        delegate?.premiumHeaderDidTapLocation(self)
    }
    
    @objc
    private func onHelp() {
        AppHaptic.navigation()
        delegate?.premiumHeaderDidTapHelp(self)
    }
    
    // MARK: - Helpers
    
    func setProfileGlassHidden(_ hidden: Bool) {
        avatarGlassView.isHidden = hidden
    }
    
    func setHelpHidden(_ hidden: Bool) {
        helpButton.isHidden = hidden
    }
    
    func setLocationHidden(_ hidden: Bool) {
        locationView.isHidden = hidden
    }
    
    func updateLocation(_ city: String) {
        configure(city: city)
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
    
    func showProfilePlaceholder(letter: String) {
        
        imageView.image = UIImage(resource: .signInBgIcon)
        imageView.isHidden = false
        
        firstNameLetter.text = letter.uppercased()
        firstNameLetter.isHidden = false
        
        signInIconView.isHidden = true
    }
    
    func showSignInState() {
        
        imageView.isHidden = true
        firstNameLetter.isHidden = true
        signInIconView.isHidden = false
    }

    private func applyHelpButtonShape() {
        let radius = helpButton.bounds.height > 0 ? helpButton.bounds.height / 2 : 18
        helpButton.layer.cornerRadius = radius
        helpGlassView.glassCornerRadius = radius
        helpGlassView.layer.cornerRadius = radius
    }
}

final class PremiumLocationView: UIControl {

    let glassView = LiquidGlassBackgroundView(
        cornerRadius: 18,
        fillColor: UIColor.white.withAlphaComponent(0.05),
        borderColor: UIColor.white.withAlphaComponent(0.18),
        borderWidth: 0.8
    )

    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {

        translatesAutoresizingMaskIntoConstraints = false

        addSubview(glassView)

        glassView.translatesAutoresizingMaskIntoConstraints = false
        glassView.isUserInteractionEnabled = false

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.isUserInteractionEnabled = false
        iconView.image = UIImage(resource: .locationIcon)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isUserInteractionEnabled = false
        titleLabel.font = Constant.Font.geistMedium(size: 14)
        titleLabel.textColor = .white.withAlphaComponent(0.9)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([

            heightAnchor.constraint(equalToConstant: 36),

            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 12),
            iconView.heightAnchor.constraint(equalToConstant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(city: String) {
        titleLabel.text = city
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        superview?.setNeedsLayout()
    }

    override var intrinsicContentSize: CGSize {
        let textWidth = ceil(titleLabel.intrinsicContentSize.width)
        let width = 10 + 12 + 6 + textWidth + 10
        return CGSize(width: min(max(width, 76), 190), height: 36)
    }
}
