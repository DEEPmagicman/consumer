import UIKit
import MHLoadingButton

final class InstagramUsernamePopupVC: UIViewController, UITextFieldDelegate {

    var onSkipTap: (() -> Void)?
    var onSubmitUsername: ((InstagramProfile?) -> Void)?

    private let dimmedView = UIView()
    private let popupView = GradientBorderCardView()
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()

    private let inputContainerView = UIView()
    private let instagramImageView = UIImageView()
    private let usernameTextField = UITextField()

    private let buttonStackView = UIStackView()
    private let skipButton = UIButton(type: .system)
    private let continueButton = LoadingButton()
    
    private var profileService = ProfileService()

    private var isRequestInProgress = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateContinueButtonState()
        animateIn()
    }

    deinit {
        onSkipTap = nil
        onSubmitUsername = nil
        usernameTextField.delegate = nil
        usernameTextField.removeTarget(nil, action: nil, for: .allEvents)
        skipButton.removeTarget(nil, action: nil, for: .allEvents)
        continueButton.removeTarget(nil, action: nil, for: .allEvents)
        closeButton.removeTarget(nil, action: nil, for: .allEvents)
        dimmedView.gestureRecognizers?.forEach {
            dimmedView.removeGestureRecognizer($0)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        popupView.layer.cornerRadius = 34
        popupView.clipsToBounds = true

        inputContainerView.layer.cornerRadius = 8
        inputContainerView.clipsToBounds = true

        skipButton.layer.cornerRadius = skipButton.bounds.height / 2
        skipButton.clipsToBounds = true

        continueButton.layer.cornerRadius = continueButton.bounds.height / 2
        continueButton.clipsToBounds = true
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
        popupView.backgroundColor =  UIColor(hex: "#171717")
        view.addSubview(popupView)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = .white
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)
        popupView.addSubview(closeButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Let's get your Instagram profile picture!"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistBold(size: 20)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        popupView.addSubview(titleLabel)

        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.backgroundColor = .clear
        inputContainerView.layer.borderWidth = 1
        inputContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        popupView.addSubview(inputContainerView)

        instagramImageView.translatesAutoresizingMaskIntoConstraints = false
        instagramImageView.contentMode = .scaleAspectFit
        instagramImageView.tintColor = .white
        instagramImageView.image = UIImage(named: "ic-Insta") ?? UIImage(systemName: "camera")
        inputContainerView.addSubview(instagramImageView)

        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        usernameTextField.delegate = self
        usernameTextField.textColor = .white
        usernameTextField.tintColor = .white
        usernameTextField.backgroundColor = .clear
        usernameTextField.borderStyle = .none
        usernameTextField.font =  Constant.Font.geistRegular(size: 16)
        usernameTextField.attributedPlaceholder = NSAttributedString(
            string: "Instagram Username",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.75),
                .font: Constant.Font.geistRegular(size: 12)
            ]
        )
        usernameTextField.autocorrectionType = .no
        usernameTextField.autocapitalizationType = .none
        usernameTextField.returnKeyType = .done
        inputContainerView.addSubview(usernameTextField)

        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .vertical
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .fill
        buttonStackView.spacing = 16
        popupView.addSubview(buttonStackView)

        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle("SKIP", for: .normal)
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.titleLabel?.font = Constant.Font.geistSemiBold(size: 16)
        skipButton.backgroundColor = .clear
        skipButton.layer.borderWidth = 1
        skipButton.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        NSLayoutConstraint.activate([
            skipButton.heightAnchor.constraint(equalToConstant: 42)
        ])

        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("CONTINUE")
        continueButton.setTitleColor(.black, for: .normal)
        continueButton.titleLabel?.font = Constant.Font.geistSemiBold(size: 12)
        continueButton.backgroundColor = UIColor.white
//        continueButton.cornerRadius = 22
        continueButton.indicator.color = UIColor.black
        NSLayoutConstraint.activate([
            continueButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        buttonStackView.addArrangedSubview(skipButton)
        buttonStackView.addArrangedSubview(continueButton)

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
            titleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 36),
            titleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -36),

            inputContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            inputContainerView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            inputContainerView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -16),
            inputContainerView.heightAnchor.constraint(equalToConstant: 44),

            instagramImageView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            instagramImageView.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            instagramImageView.widthAnchor.constraint(equalToConstant: 20),
            instagramImageView.heightAnchor.constraint(equalToConstant: 20),

            usernameTextField.leadingAnchor.constraint(equalTo: instagramImageView.trailingAnchor, constant: 10),
            usernameTextField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -14),
            usernameTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            usernameTextField.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor),

            buttonStackView.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 24),
            buttonStackView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -22)
        ])
    }

    private func setupActions() {
        skipButton.addTarget(self, action: #selector(handleSkipTap), for: .touchUpInside)
        continueButton.addTarget(self,
                                 action: #selector(handleContinueTap),
                                 for: UIControl.Event.touchUpInside)
        usernameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    @objc private func textFieldDidChange() {
        updateContinueButtonState()
    }

    private func updateContinueButtonState() {
        continueButton.indicator = MaterialLoadingIndicator(color: .black)

        let hasUsername = !cleanedUsername().isEmpty

        UIView.animate(withDuration: 0.2) {
            self.continueButton.isHidden = !hasUsername
            self.view.layoutIfNeeded()
        }
    }

    private func setLoading(_ loading: Bool) {
        isRequestInProgress = loading

        closeButton.isUserInteractionEnabled = !loading
        dimmedView.isUserInteractionEnabled = !loading
        skipButton.isUserInteractionEnabled = !loading
        usernameTextField.isUserInteractionEnabled = !loading

        continueButton.isUserInteractionEnabled = !loading

        if loading {
            continueButton.showLoader(userInteraction: false)
        } else {
            continueButton.hideLoader()
            continueButton.alpha = 1.0
            continueButton.backgroundColor = .white
            continueButton.setTitleColor(.black, for: .normal)
        }
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
        guard !isRequestInProgress else { return }
        animateOut { [weak self] in
            self?.dismiss(animated: false)
        }
    }

    @objc private func handleSkipTap() {
        guard !isRequestInProgress else { return }
        onSkipTap?()
        dismissPopup()
    }

    @objc private func handleContinueTap() {
        submitInstagramUsername()
    }

    private func submitInstagramUsername() {
        guard !isRequestInProgress else { return }

        let username = cleanedUsername()
        guard !username.isEmpty else { return }

        setLoading(true)

        profileService.fetchInstagramProfile(instagramUserId: username) { [weak self] isSuccess, _, profileData in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.setLoading(false)

                if isSuccess {
                    self.updateUserProfile(instagramUserId: username)
                    self.animateOut { [weak self] in
                               guard let self = self else { return }
                               self.dismiss(animated: false) {
                                   self.onSubmitUsername?(profileData)
                               }
                           }
                } else {
                    Alert.showToast("Instagram ID not found. Please enter a valid ID.")

                }
            }
        }
    }
    
    private func updateUserProfile(instagramUserId: String) {
        profileService.updateProfile(instagramUserId: instagramUserId) { [weak self] isSuccess, _ in
            DispatchQueue.main.async {
                if isSuccess {
                    if var user = UserDefault.shared.user {
                        user.instagramUserId = instagramUserId
                        UserDefault.shared.user = user
                    }

                }
            }
        }
    }

    private func cleanedUsername() -> String {
        usernameTextField.text?
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let username = cleanedUsername()
        if !username.isEmpty {
            submitInstagramUsername()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
