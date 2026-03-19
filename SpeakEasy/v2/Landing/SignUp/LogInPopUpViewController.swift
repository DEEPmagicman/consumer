//
//  LogInPopUpViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 28/02/26.
//

    import UIKit
    import MHLoadingButton

    final class LogInPopUpViewController: UIViewController {

        @IBOutlet weak var continueBtn: LoadingButton!
        @IBOutlet weak var phoneNumTextField: PhoneNumberTextField!
        @IBOutlet weak var termsAndPrivacyLbl: UILabel!
        
        var isFromLogin = true
        var isFromSettings = false

        private var onBoardingPresenter = OnBoardingPresenter()
        private var settingPresenter = SettingPresenter()

        private let phoneNumberUtility = PhoneNumberUtility()
        private var phoneNumber: PhoneNumber?
        var onContinueToVerify: ((_ otp: String?, _ otpRef: String?, _ phone: String, _ countryCode: String, _ isFromLogin: Bool, _ isFromSettings: Bool) -> Void)?

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            setupTermsLabel()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            phoneNumTextField.flagButton.titleLabel?.font = Constant.Font.interRegular(size: 14)
        }

        private func setupUI() {
            phoneNumTextField.delegate = self
            
            continueBtn.bgColor = .white
            continueBtn.indicator = MaterialLoadingIndicator(color: .white)
            setContinueEnabled(false)
            
            phoneNumTextField.withDefaultPickerUI = true
            phoneNumTextField.defaultRegion = "US"
            phoneNumTextField.withPrefix = false
            phoneNumTextField.withFlag = true
            phoneNumTextField.withExamplePlaceholder = true
            
            // ✅ MATCH FONT
            phoneNumTextField.font = Constant.Font.interRegular(size: 14)
            phoneNumTextField.flagButton.titleLabel?.font = Constant.Font.interRegular(size: 14)
            phoneNumTextField.flagButton.setTitleColor(.white, for: .normal)
            
            CountryCodePicker.alwaysShowsSearchBar = true
            CountryCodePicker.forceModalPresentation = true
            
            var options = CountryCodePickerOptions()
            options.backgroundColor = Constant.Color.backgroundColor
            options.textLabelFont = Constant.Font.interRegular(size: 14)
            options.textLabelColor = Constant.Color.textLabelColor
            options.detailTextLabelFont = Constant.Font.interRegular(size: 14)
            phoneNumTextField.withDefaultPickerUIOptions = options
        }
        
        private func setupTermsLabel() {

            let fullText = """
            By continuing you agree to the Terms of Service and Privacy Policy. We'll text you a verification code and event updates if you opt in. Msg & data rates may apply. Reply STOP to opt out or HELP for support.
            """

            let attributedString = NSMutableAttributedString(
                string: fullText,
                attributes: [
                    .font: Constant.Font.interRegular(size: 12),
                    .foregroundColor: UIColor.white
                ]
            )

            let termsRange = (fullText as NSString).range(of: "Terms of Service")
            let privacyRange = (fullText as NSString).range(of: "Privacy Policy")

            let highlightAttributes: [NSAttributedString.Key: Any] = [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: Constant.Font.interRegular(size: 12),
                .foregroundColor: UIColor.white
            ]

            attributedString.addAttributes(highlightAttributes, range: termsRange)
            attributedString.addAttributes(highlightAttributes, range: privacyRange)

            termsAndPrivacyLbl.attributedText = attributedString
            termsAndPrivacyLbl.numberOfLines = 0
            termsAndPrivacyLbl.isUserInteractionEnabled = true

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickInfoLabel(_:)))
            termsAndPrivacyLbl.addGestureRecognizer(tapGesture)
        }

        private func setContinueEnabled(_ enabled: Bool) {
            continueBtn.isUserInteractionEnabled = enabled
            continueBtn.alpha = enabled ? 1.0 : 0.5
        }

        private func extractedCountryCode() -> String {
            // same logic you had: read from flag button label and keep ASCII characters
            let raw = phoneNumTextField?.flagButton.titleLabel?.text?
                .components(separatedBy: .whitespaces)
                .joined()
                .filter { $0.isASCII }

            return raw ?? "+1"
        }
        
        @objc private func onClickInfoLabel(_ sender: UITapGestureRecognizer) {

            guard let text = termsAndPrivacyLbl.text else { return }

            let termsRange = (text as NSString).range(of: "Terms of Service")
            let privacyRange = (text as NSString).range(of: "Privacy Policy")

            if sender.didTapAttributedTextInLabel(label: termsAndPrivacyLbl, inRange: termsRange) {
                Navigate.externalURL(APIBuilder.termsConsumerURL)
            }

            if sender.didTapAttributedTextInLabel(label: termsAndPrivacyLbl, inRange: privacyRange) {
                Navigate.externalURL(APIBuilder.privacyConsumerURL)
            }
        }

        // MARK: - Actions
        @IBAction func onClickBack(_ sender: Any) {
            self.dismiss(animated: true)
        }

        @IBAction func onClickContinue(_ sender: Any) {
            let phoneNum = self.phoneNumber?.nationalNumber ?? 0
            let countryCode = extractedCountryCode()

            continueBtn.showLoader(userInteraction: false)

            if isFromLogin {
                onBoardingPresenter.loginWithPhoneApi(phonenum: "\(phoneNum)", code: countryCode) { [weak self] otp, otpRef, isSuccess, errorMsg in
                    guard let self else { return }
                    self.continueBtn.hideLoader()

                    if isSuccess {
                        let phone = self.phoneNumTextField.text ?? ""
                        self.dismiss(animated: true) { [weak self] in
                            guard let self else { return }
                            self.onContinueToVerify?(otp, otpRef, phone, countryCode, self.isFromLogin, self.isFromSettings)
                        }
                    } else if errorMsg == Constant.String.internetNotConnect {
                        self.view.endEditing(true)
                    } else {
                        Alert.showAlertSheet(style: .alert,
                                             title: errorMsg ?? Constant.String.somethingWrong,
                                             message: "")
                    }
                }
                return
            }

            if isFromSettings {
                settingPresenter.changePhoneNumberApi(phone: "\(phoneNum)", code: countryCode) { [weak self] otp, otpRef, isSuccess, errMsg in
                    guard let self else { return }
                    self.continueBtn.hideLoader()

                    if isSuccess {
                        
                        let phone = self.phoneNumTextField.text ?? ""
                        self.dismiss(animated: true) { [weak self] in
                            guard let self else { return }
                            self.onContinueToVerify?(otp, otpRef, phone, countryCode, self.isFromLogin, self.isFromSettings)
                        }
                    } else if errMsg == Constant.String.internetNotConnect {
                        self.view.endEditing(true)
                    } else {
                        Alert.showAlertSheet(style: .alert,
                                             title: errMsg ?? Constant.String.somethingWrong,
                                             message: "")
                    }
                }
            } else {
                onBoardingPresenter.signUpWithPhoneApi(phonenum: "\(phoneNum)", code: countryCode) { [weak self] otp, otpRef, isSuccess, errorMsg in
                    guard let self else { return }
                    self.continueBtn.hideLoader()

                    if isSuccess {
                        UserDefault.shared.user?.phone = "\(phoneNum)"
                        
                        let phone = self.phoneNumTextField.text ?? ""
                        self.dismiss(animated: true) { [weak self] in
                            guard let self else { return }
                            self.onContinueToVerify?(otp, otpRef, phone, countryCode, self.isFromLogin, self.isFromSettings)
                        }
                        
    //                    self.dismiss(animated: true) { [weak self] in
    //                        guard let self = self,
    //                              let presenterVC = self.presentingViewController ?? self.navigationController?.presentingViewController else { return }
    //
    //                        Navigate.to.enterVerificationCodeVc(
    //                            presenterVC,
    //                            isFromLogin: true,
    //                            otp: otp,
    //                            otpRef: otpRef,
    //                            phoneNum: self.phoneNumTextField.text ?? "",
    //                            countryCode: countryCode
    //                        )
    //                    }
                        
                    } else if errorMsg == Constant.String.internetNotConnect {
                        self.view.endEditing(true)
                    } else {
                        if errorMsg == "Entered phone number already exists in system." {
                            self.isFromLogin = true
                            self.onClickContinue(0)
                        } else {
                            Alert.showAlertSheet(style: .alert,
                                                 title: errorMsg ?? Constant.String.somethingWrong,
                                                 message: "")
                        }
                    }
                }
            }
        }
    }

    extension LogInPopUpViewController: UITextFieldDelegate {

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            true
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            do {
                let parsed = try phoneNumberUtility.parse(
                    phoneNumTextField.text ?? "",
                    withRegion: phoneNumTextField.defaultRegion
                )
                self.phoneNumber = parsed
                setContinueEnabled(true)
            } catch {
                setContinueEnabled(false)
            }
        }
    }
