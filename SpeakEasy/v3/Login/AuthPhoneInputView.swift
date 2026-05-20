//
//  AuthPhoneInputViewDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 12/05/26.
//


import UIKit
import MHLoadingButton

protocol AuthPhoneInputViewDelegate: AnyObject {
    func authPhoneInputViewDidTapContinue(_ view: AuthPhoneInputView)
    func authPhoneInputView(_ view: AuthPhoneInputView, didChangeValidPhone isValid: Bool)
}

final class AuthPhoneInputView: UIView {

    weak var delegate: AuthPhoneInputViewDelegate?

    let continueBtn = LoadingButton()
    let phoneNumTextField = PhoneNumberTextField()

    private let termsAndPrivacyLbl = UILabel()
    private let phoneContainer = UIView()
    private let countryContainer = UIView()
    private let phoneNumberUtility = PhoneNumberUtility()

    private(set) var phoneNumber: PhoneNumber?

    private var termsRange: NSRange = .init(location: 0, length: 0)
    private var privacyRange: NSRange = .init(location: 0, length: 0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupTermsLabel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupTermsLabel()
    }

    func phoneText() -> String {
        phoneNumTextField.text ?? ""
    }

    func phoneNationalNumber() -> String {
        "\(phoneNumber?.nationalNumber ?? 0)"
    }

    func countryCode() -> String {
        let raw = phoneNumTextField.flagButton.titleLabel?.text?
            .components(separatedBy: .whitespaces)
            .joined()
            .filter { $0.isASCII }

        return raw ?? "+1"
    }

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let titleLabel = Utility.main.makeLabel("Continue with phone number")
        let subtitleLabel = Utility.main.makeLabel("Enter your phone number\nWe’ll send you a verification code", font: Constant.Font.geistRegular(size: 14))

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.addArrangedSubview(makeSpacer(12))

        setupPhoneInput()
        stack.addArrangedSubview(phoneContainer)

        Utility.main.stylePrimaryButton(continueBtn, title: "Continue")
        continueBtn.addTarget(self, action: #selector(onClickContinue), for: .touchUpInside)
        Utility.main.setButton(continueBtn, enabled: false)
        stack.addArrangedSubview(continueBtn)

        stack.addArrangedSubview(makeSpacer(16))
        stack.addArrangedSubview(termsAndPrivacyLbl)

        setupPhoneTextField()
    }

    func configureForChangePhone(phone: String, countryCode: String) {
        continueBtn.setTitle("Confirm", for: .normal)

        let code = countryCode.hasPrefix("+") ? countryCode : "+\(countryCode)"
        let cleanPhone = phone
            .replacingOccurrences(of: code, with: "")
            .filter { $0.isNumber }

        if let region = phoneNumTextField.utility.mainCountry(forCode: UInt64(code.replacingOccurrences(of: "+", with: "")) ?? 1) {
            phoneNumTextField.defaultRegion = region
        }

        phoneNumTextField.text = cleanPhone
        phoneNumTextField.updateFlag(code: code)

        do {
            let parsed = try phoneNumberUtility.parse(
                cleanPhone,
                withRegion: phoneNumTextField.defaultRegion
            )

            phoneNumber = parsed
            Utility.main.setButton(continueBtn, enabled: true)
            delegate?.authPhoneInputView(self, didChangeValidPhone: true)
        } catch {
            phoneNumber = nil
            Utility.main.setButton(continueBtn, enabled: false)
            delegate?.authPhoneInputView(self, didChangeValidPhone: false)
        }
    }
    
    private func setupPhoneInput() {
        phoneContainer.translatesAutoresizingMaskIntoConstraints = false
        phoneContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true

        countryContainer.backgroundColor = AuthTheme.fieldBackground
        countryContainer.layer.cornerRadius = 14
        countryContainer.layer.cornerCurve = .continuous
        countryContainer.layer.borderWidth = 1
        countryContainer.layer.borderColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08).cgColor
        countryContainer.clipsToBounds = true
        countryContainer.translatesAutoresizingMaskIntoConstraints = false

        phoneNumTextField.delegate = self
        phoneNumTextField.backgroundColor = AuthTheme.fieldBackground
        phoneNumTextField.textColor = AuthTheme.fieldText
        phoneNumTextField.tintColor = .systemBlue
        phoneNumTextField.layer.cornerRadius = 14
        phoneNumTextField.layer.cornerCurve = .continuous
        phoneNumTextField.layer.borderWidth = 1
        phoneNumTextField.layer.borderColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08).cgColor
        phoneNumTextField.clipsToBounds = true
        phoneNumTextField.translatesAutoresizingMaskIntoConstraints = false

        phoneContainer.addSubview(countryContainer)
        phoneContainer.addSubview(phoneNumTextField)

        NSLayoutConstraint.activate([
            countryContainer.leadingAnchor.constraint(equalTo: phoneContainer.leadingAnchor),
            countryContainer.topAnchor.constraint(equalTo: phoneContainer.topAnchor),
            countryContainer.bottomAnchor.constraint(equalTo: phoneContainer.bottomAnchor),
            countryContainer.widthAnchor.constraint(equalToConstant: 80),

            phoneNumTextField.leadingAnchor.constraint(equalTo: countryContainer.trailingAnchor, constant: 8),
            phoneNumTextField.trailingAnchor.constraint(equalTo: phoneContainer.trailingAnchor),
            phoneNumTextField.topAnchor.constraint(equalTo: phoneContainer.topAnchor),
            phoneNumTextField.bottomAnchor.constraint(equalTo: phoneContainer.bottomAnchor)
        ])
    }

    private func setupPhoneTextField() {
        phoneNumTextField.withDefaultPickerUI = true
        phoneNumTextField.defaultRegion = "US"
        phoneNumTextField.withPrefix = false
        phoneNumTextField.withFlag = true
        phoneNumTextField.withExamplePlaceholder = true

        phoneNumTextField.font = Constant.Font.geistRegular(size: 18)
        phoneNumTextField.flagButton.titleLabel?.font = Constant.Font.geistRegular(size: 16)
        phoneNumTextField.flagButton.setTitleColor(AuthTheme.fieldText, for: .normal)

        phoneNumTextField.attributedPlaceholder = NSAttributedString(
            string: "000-00-0000",
            attributes: [
                .foregroundColor: AuthTheme.placeholder,
                .font: Constant.Font.geistRegular(size: 18)
            ]
        )

        var options = CountryCodePickerOptions()
        options.backgroundColor = AppColor.primaryColor
        options.textLabelFont = Constant.Font.geistRegular(size: 14)
        options.textLabelColor = AuthTheme.title
        options.detailTextLabelFont = Constant.Font.geistRegular(size: 14)

        CountryCodePicker.alwaysShowsSearchBar = true
        CountryCodePicker.forceModalPresentation = true
        phoneNumTextField.withDefaultPickerUIOptions = options

        phoneNumTextField.flagButton.removeFromSuperview()
        countryContainer.addSubview(phoneNumTextField.flagButton)

        phoneNumTextField.flagButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            phoneNumTextField.flagButton.leadingAnchor.constraint(equalTo: countryContainer.leadingAnchor, constant: 8),
            phoneNumTextField.flagButton.trailingAnchor.constraint(equalTo: countryContainer.trailingAnchor, constant: -8),
            phoneNumTextField.flagButton.centerYAnchor.constraint(equalTo: countryContainer.centerYAnchor),
            phoneNumTextField.flagButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        phoneNumTextField.leftView = paddingView
        phoneNumTextField.leftViewMode = .always
    }

    private func setupTermsLabel() {
        let fullText = """
        By continuing you agree to the Terms of Service and Privacy Policy. We'll text you a verification code and event updates if you opt in. Msg & data rates may apply. Reply STOP to opt out or HELP for support.
        """

        let attributedString = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: Constant.Font.geistRegular(size: 10),
                .foregroundColor: AppColor.primaryWhiteColor.withAlphaComponent(0.65)
            ]
        )

        termsRange = (fullText as NSString).range(of: "Terms of Service")
        privacyRange = (fullText as NSString).range(of: "Privacy Policy")

        let highlightAttributes: [NSAttributedString.Key: Any] = [
            .font: Constant.Font.interRegular(size: 10),
            .foregroundColor: AppColor.primaryWhiteColor.withAlphaComponent(0.65)
        ]

        attributedString.addAttributes(highlightAttributes, range: termsRange)
        attributedString.addAttributes(highlightAttributes, range: privacyRange)

        termsAndPrivacyLbl.attributedText = attributedString
        termsAndPrivacyLbl.numberOfLines = 0
        termsAndPrivacyLbl.textAlignment = .center
        termsAndPrivacyLbl.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickInfoLabel(_:)))
        termsAndPrivacyLbl.addGestureRecognizer(tapGesture)
    }
    
    @objc private func onClickInfoLabel(_ sender: UITapGestureRecognizer) {
        
        guard let attributedText = termsAndPrivacyLbl.attributedText else { return }
        
        if sender.didTapAttributedTextInLabel(label: termsAndPrivacyLbl, inRange: termsRange) {
            Navigate.externalURL(APIBuilder.termsConsumerURL)
            return
        }
        
        if sender.didTapAttributedTextInLabel(label: termsAndPrivacyLbl, inRange: privacyRange) {
            Navigate.externalURL(APIBuilder.privacyConsumerURL)
        }
    }
    
    func focusPhoneField() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.phoneNumTextField.becomeFirstResponder()
        }
    }

    @objc private func onClickContinue() {
        delegate?.authPhoneInputViewDidTapContinue(self)
    }

    private func makeSpacer(_ height: CGFloat) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }
}

extension AuthPhoneInputView: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        do {
            let parsed = try phoneNumberUtility.parse(
                phoneNumTextField.text ?? "",
                withRegion: phoneNumTextField.defaultRegion
            )
            phoneNumber = parsed
            Utility.main.setButton(continueBtn, enabled: true)
            delegate?.authPhoneInputView(self, didChangeValidPhone: true)
        } catch {
            phoneNumber = nil
            Utility.main.setButton(continueBtn, enabled: false)
            delegate?.authPhoneInputView(self, didChangeValidPhone: false)
        }
    }
}
