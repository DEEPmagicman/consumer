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
        backBtn.iconSize = 20
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)

        titleLabel.text = "Account info"
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

        view.addSubview(emailBox)
        view.addSubview(phoneBox)
    }

    private func setupButton() {
        saveBtn.configure(title: "Save changes", fontSize: 18, cornerRadius: 16)
        saveBtn.addTarget(self, action: #selector(onClickSave), for: .touchUpInside)
        view.addSubview(saveBtn)
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

        let email = user?.email.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        emailBox.text = email.isEmpty ? nil : email

        let phone = user?.phone.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        phoneBox.text = phone.isEmpty ? nil : phone
    }

    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func onClickEmail() {
        // Navigate.to.loginWithEmailVc(self, isFromSettings: true)
    }

    @objc private func onClickPhone() {
        Navigate.to.openPhoneLoginPopup(self)
    }

    @objc private func onClickSave() {
        guard validateForm() else { return }

        navigationController?.popViewController(animated: true)
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

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
