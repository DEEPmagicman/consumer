//
//  AccountInfoVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 19/05/26.
//

import UIKit

final class AccountInfoVC: UIViewController {

    private let backBtn = AppIconButton()
    private let titleLabel = UILabel()

    private let emailBox = FloatingInputView(title: "Email address")
    private let phoneBox = FloatingInputView(title: "Phone number")
    private let saveBtn = PrimaryButton()

    private let settingsService = SettingsService()

    private var originalEmail = ""
    private var originalPhone = ""
    private var pendingPhone = ""
    private var pendingCountryCode = "+1"
    private var isPhoneVerified = false
    
    private var pendingEmail = ""
    private let profileService = ProfileService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismiss()
        loadUserData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    private func setupUI() {
        setupNav()
        setupBoxes()
        setupButton()
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

        titleLabel.text = "Account Info"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }

    private func setupBoxes() {
        emailBox.textField.keyboardType = .emailAddress
        emailBox.textField.autocapitalizationType = .none
        emailBox.textField.autocorrectionType = .no
        emailBox.textField.isUserInteractionEnabled = true
        emailBox.textField.returnKeyType = .done
        emailBox.textField.delegate = self

        phoneBox.textField.keyboardType = .phonePad
        phoneBox.textField.isUserInteractionEnabled = false

        phoneBox.addTarget(self, action: #selector(onClickPhone), for: .touchUpInside)

        emailBox.textField.addTarget(
            self,
            action: #selector(emailDidChange),
            for: .editingChanged
        )
        
        view.addSubview(emailBox)
        view.addSubview(phoneBox)
    }

    @objc private func emailDidChange() {
        emailBox.clearError()
        updateSaveButtonState()
    }
    
    private func setupButton() {
        saveBtn.configure(title: "Save Changes", fontSize: 18, cornerRadius: 16)
           saveBtn.addTarget(self, action: #selector(onClickSave), for: .touchUpInside)

           view.addSubview(saveBtn)

           updateSaveButtonState()
    }

    private func updateSaveButtonState() {

        let currentEmail = emailBox.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let hasChanges =
            currentEmail != originalEmail
        
        saveBtn.isUserInteractionEnabled = hasChanges

        UIView.animate(withDuration: 0.2) {
            self.saveBtn.alpha = hasChanges ? 1.0 : 0.45
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.widthAnchor.constraint(equalToConstant: 40),
            backBtn.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            emailBox.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 52),
            emailBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            emailBox.heightAnchor.constraint(equalToConstant: 82),

            phoneBox.topAnchor.constraint(equalTo: emailBox.bottomAnchor, constant: 8),
            phoneBox.leadingAnchor.constraint(equalTo: emailBox.leadingAnchor),
            phoneBox.trailingAnchor.constraint(equalTo: emailBox.trailingAnchor),
            phoneBox.heightAnchor.constraint(equalToConstant: 82),

            saveBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            saveBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            saveBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            saveBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func loadUserData() {
        let user = UserDefault.shared.user

        originalEmail = user?.email.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        emailBox.text = originalEmail.isEmpty ? nil : originalEmail

        let code = storedCountryCode()
        let phone = storedPhoneNumber()

        originalPhone = formattedPhoneDisplay(code: code, phone: phone)
        phoneBox.text = originalPhone.isEmpty ? nil : originalPhone

        pendingCountryCode = code
        pendingPhone = phone
    }

    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func onClickEmail() {
        // Navigate.to.loginWithEmailVc(self, isFromSettings: true)
    }

    @objc private func onClickPhone() {
        let vc = AuthPhoneOTPVC()
        vc.flowMode = .changePhone
        vc.initialPhone = storedPhoneNumber()
        vc.initialCountryCode = storedCountryCode()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve

        vc.onPhoneChanged = { [weak self] phone, countryCode in
            guard let self else { return }

            let code = countryCode.hasPrefix("+") ? countryCode : "+\(countryCode)"
            let displayPhone = self.formattedPhoneDisplay(code: code, phone: phone)

            self.pendingPhone = phone
            self.pendingCountryCode = code
            self.isPhoneVerified = true
            self.phoneBox.text = displayPhone

            UserDefault.shared.user?.phone = phone
            UserDefault.shared.user?.code = code
        }

        present(vc, animated: true)
    }

    @objc private func onClickSave() {
        view.endEditing(true)

        guard validateForm() else { return }

        let newEmail = emailBox.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let emailChanged = newEmail != originalEmail
        let phoneChanged = (phoneBox.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") != originalPhone

        if phoneChanged && !isPhoneVerified {
            showError(phoneBox, message: "Please verify your new phone number.")
            return
        }

        if !emailChanged && !phoneChanged {
            navigationController?.popViewController(animated: true)
            return
        }

        if emailChanged {
            self.saveBtn.startLoading()
            presentConfirmEmail(newEmail)
            return
        }

        navigationController?.popViewController(animated: true)
    }
    
    private func presentConfirmEmail(_ email: String) {
        pendingEmail = email

        let vc = ConfirmContactVC()
        vc.type = .email
        vc.displayText = email
        vc.delegate = self
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve

        present(vc, animated: true)
    }
    
    private func updateEmail(_ email: String) {
        saveBtn.startLoading()

        settingsService.requestEmailChangeOTP(email: email) { [weak self] otp, otpRef, isSuccess, errMsg in
            guard let self else { return }

            self.saveBtn.stopLoading()

            if isSuccess {
                self.openEmailOTP(email: email, otp: otp, otpRef: otpRef)
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }
    
    private func openEmailOTP(email: String, otp: String?, otpRef: String?) {
        let vc = AuthPhoneOTPVC()
        vc.flowMode = .changeEmail
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve

        vc.onEmailChanged = { [weak self] email in
            guard let self else { return }
            UserDefault.shared.user?.email = email
            self.originalEmail = email
            self.emailBox.text = email
            self.updateSaveButtonState()
            self.navigationController?.popViewController(animated: true)
        }

        present(vc, animated: true) {
            vc.startEmailOTP(email: email, otp: otp, otpRef: otpRef)
        }
    }
    
    private func validateForm() -> Bool {
        clearValidationUI()

        let email = emailBox.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = phoneBox.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if email.isEmpty {
            showError(emailBox, message: "Please add your email address.")
            return false
        }

        if !isValidEmail(email) {
            showError(emailBox, message: "Please enter a valid email address.")
            return false
        }

        if phone.isEmpty {
            showError(phoneBox, message: "Please add your phone number.")
            return false
        }

        return true
    }

    private func clearValidationUI() {
        emailBox.clearError()
        phoneBox.clearError()
    }

    private func showError(_ view: FloatingInputView, message: String) {
        view.showError()
        AppHaptic.error()

        Alert.showAlertSheet(
            style: .alert,
            title: message,
            message: ""
        )
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditing() {
        view.endEditing(true)
    }
    
    private func storedCountryCode() -> String {
        let rawCode = UserDefault.shared.user?.code ?? "+1"
        return rawCode.hasPrefix("+") ? rawCode : "+\(rawCode)"
    }

    private func storedPhoneNumber() -> String {
        UserDefault.shared.user?.phone.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func formattedPhoneDisplay(code: String, phone: String) -> String {
        let cleanPhone = phone
            .replacingOccurrences(of: code, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanPhone.isEmpty else { return "" }

        return "\(code) \(cleanPhone)"
    }
    
    @objc private func saveEmail() {
        view.endEditing(true)
    
        var isProfileCompleted = UserDefault.shared.user?.isProfileCompleted ?? false
        if !isProfileCompleted && UserDefault.shared.user?.firstName != nil && UserDefault.shared.user?.firstName != "" {
            isProfileCompleted = true
            UserDefault.shared.user?.isProfileCompleted = true
        }
        
        profileService.updateProfile(
            email: self.emailBox.text ?? "",
            isProfileCompleted: isProfileCompleted
        ) { [weak self] isSuccess, errorMsg in
            guard let self else { return }

            self.saveBtn.stopLoading()

            if isSuccess {
                if UserDefault.shared.user?.firstName != nil && UserDefault.shared.user?.firstName != "" {
                    UserDefault.shared.user?.isProfileCompleted = true
                }
                UserDefault.shared.user?.email = self.emailBox.text ?? ""
                self.originalEmail = self.emailBox.text ?? ""
                self.updateSaveButtonState()
                self.navigationController?.popViewController(animated: true)
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errorMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }
}

extension AccountInfoVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        emailBox.clearError()
    }
}

extension AccountInfoVC: ConfirmContactVCDelegate {
    func confirmContactVCDidConfirm(_ vc: ConfirmContactVC) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.saveEmail()
//            self.updateEmail(self.pendingEmail)
        }
    }

    func confirmContactVCDidGoBack(_ vc: ConfirmContactVC) {
        vc.dismiss(animated: true)
        self.saveBtn.stopLoading()
    }
}
