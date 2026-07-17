//
//  InstagramProfileFoundPopupVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 25/03/26.
//

import Foundation
import UIKit
import SDWebImage

final class InstagramProfileFoundPopupVC: UIViewController {

    var imageURL: String?
    var instaProfileData: InstagramProfile?
    var onUploadOwnTap: (() -> Void)?
    var onUseThisPictureTap: (() -> Void)?

    private let dimmedView = UIView()
    private let popupView = GradientBorderCardView()
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let profileImageView = UIImageView()
    private let subtitleLabel = UILabel()
    private let buttonStackView = UIStackView()
    private let uploadOwnButton = UIButton(type: .system)
    private let useThisPictureButton = UIButton(type: .system)
    
    private var profileService = ProfileService()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
        animateIn()
    }

    deinit {
        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.image = nil
        instaProfileData = nil
        onUploadOwnTap = nil
        onUseThisPictureTap = nil
        uploadOwnButton.removeTarget(nil, action: nil, for: .allEvents)
        useThisPictureButton.removeTarget(nil, action: nil, for: .allEvents)
        closeButton.removeTarget(nil, action: nil, for: .allEvents)
        dimmedView.gestureRecognizers?.forEach {
            dimmedView.removeGestureRecognizer($0)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        popupView.layer.cornerRadius = 34
        popupView.clipsToBounds = true

        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
        profileImageView.clipsToBounds = true

        uploadOwnButton.layer.cornerRadius = uploadOwnButton.bounds.height / 2
        uploadOwnButton.clipsToBounds = true

        useThisPictureButton.layer.cornerRadius = useThisPictureButton.bounds.height / 2
        useThisPictureButton.clipsToBounds = true
    }

    private func setupUI() {
        view.backgroundColor = .clear

        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        dimmedView.alpha = 0
        view.addSubview(dimmedView)

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        dimmedView.addGestureRecognizer(dismissTap)

        popupView.translatesAutoresizingMaskIntoConstraints = false
        popupView.backgroundColor = UIColor(hex: "#171717")
        view.addSubview(popupView)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = .white
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.addTarget(self, action: #selector(dismissPopup), for: UIControl.Event.touchUpInside)
        popupView.addSubview(closeButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "We found your Instagram profile picture!"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistBold(size: 20)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        popupView.addSubview(titleLabel)

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = UIColor(hex: "#C9CDD7")
        popupView.addSubview(profileImageView)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Would you like to use this as your profile picture?"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        subtitleLabel.font = Constant.Font.geistRegular(size: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        popupView.addSubview(subtitleLabel)

        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .vertical
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .fill
        buttonStackView.spacing = 16
        popupView.addSubview(buttonStackView)

        uploadOwnButton.translatesAutoresizingMaskIntoConstraints = false
        uploadOwnButton.setTitle("NO, I'LL UPLOAD MY OWN", for: .normal)
        uploadOwnButton.setTitleColor(.white, for: .normal)
        uploadOwnButton.titleLabel?.font = Constant.Font.geistSemiBold(size: 14)
        uploadOwnButton.backgroundColor = .clear
        uploadOwnButton.layer.borderWidth = 1
        uploadOwnButton.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        uploadOwnButton.addTarget(self, action: #selector(handleUploadOwnTap), for: UIControl.Event.touchUpInside)
        NSLayoutConstraint.activate([
            uploadOwnButton.heightAnchor.constraint(equalToConstant: 42)
        ])

        useThisPictureButton.translatesAutoresizingMaskIntoConstraints = false
        useThisPictureButton.setTitle("YES, USE THIS PICTURE", for: .normal)
        useThisPictureButton.setTitleColor(.black, for: .normal)
        useThisPictureButton.titleLabel?.font = Constant.Font.geistSemiBold(size: 14)
        useThisPictureButton.backgroundColor = .white
        useThisPictureButton.addTarget(self, action: #selector(handleUseThisPictureTap), for: UIControl.Event.touchUpInside)
        NSLayoutConstraint.activate([
            useThisPictureButton.heightAnchor.constraint(equalToConstant: 42)
        ])

        buttonStackView.addArrangedSubview(uploadOwnButton)
        buttonStackView.addArrangedSubview(useThisPictureButton)

        NSLayoutConstraint.activate([
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            popupView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            popupView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            closeButton.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 14),
            closeButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -14),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 58),
            titleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -28),

            profileImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            profileImageView.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 150),
            profileImageView.heightAnchor.constraint(equalToConstant: 150),

            subtitleLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 24),
            subtitleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 28),
            subtitleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -28),

            buttonStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            buttonStackView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -26)
        ])
    }

    private func setupData() {
        guard let imageURL,
              !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: imageURL) else {
            return
        }

        profileImageView.sd_setImage(
            with: url,
            placeholderImage: UIImage(systemName: "person.crop.circle.fill")
        )
    }

    private func animateIn() {
        popupView.transform = CGAffineTransform(translationX: 0, y: 24).scaledBy(x: 0.98, y: 0.98)
        popupView.alpha = 0

        UIView.animate(withDuration: 0.25) {
            self.dimmedView.alpha = 1
            self.popupView.alpha = 1
            self.popupView.transform = .identity
        }
    }

    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.dimmedView.alpha = 0
            self.popupView.alpha = 0
            self.popupView.transform = CGAffineTransform(translationX: 0, y: 16).scaledBy(x: 0.98, y: 0.98)
        }) { _ in
            completion?()
        }
    }

    @objc private func dismissPopup() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
        }
    }

    @objc private func handleUploadOwnTap() {
        onUploadOwnTap?()
        dismissPopup()
    }

    @objc private func handleUseThisPictureTap() {
        let imgDetail = ImageDetail(key: self.instaProfileData?.profilePictureKey ?? "", name: self.instaProfileData?.profilePictureFilename ?? "", description: "profile picture")
        
        self.profileService.updateProfile(image: imgDetail) { [weak self] isSuccess, errorMsg  in
            guard let self = self else { return }
            self.view.isUserInteractionEnabled = true
            
            if isSuccess {
                UserDefault.shared.user?.image = imgDetail
            } else {
                if errorMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
        }
        
        dismissPopup()
    }
}
