//
//  VerifyNumberVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 12/05/26.
//

import UIKit
import OTPFieldView
import MHLoadingButton

final class VerifyNumberVC: BaseAuthViewController {

    private let phoneNumLbl = UILabel()
    private let otpFieldView = OTPFieldView()
    private let continueBtn = LoadingButton()
    private let timerLbl = UILabel()
    private let resendBtn = LoadingButton()
    private let backBtn = LoadingButton()

    var otpText = ""
    var currectOtp: String?
    var otpRef = ""
    var phoneNum = ""
    var countryCode = ""

    var isFromLogin = false
    var isFromSettings = false
    var isForEmail = false
    var onOtpSuccess: (() -> Void)?

    private let authService = AuthService()
    private let settingsService = SettingsService()

    private var timer = Timer()
    private var count = 60
    private var isVerifyingOtp = false
    private var isResendingOtp = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setOtpView()
        setButton(continueBtn, enabled: false)
        setResendEnabled(false)

        let time = secondsToHoursMinutesSeconds(seconds: count)
        timerLbl.text = makeTimeString(minutes: time.0, seconds: time.1)
        startTimer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        phoneNumLbl.text = "Enter the 6 digits code sent to \(countryCode)...\(phoneNum.suffix(2))"
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }

    deinit {
        timer.invalidate()
    }

    private func setupUI() {
        let titleLabel = makeTitleLabel("Verification code")

        phoneNumLbl.textColor = AuthTheme.subtitle
        phoneNumLbl.font = Constant.Font.interRegular(size: 13)
        phoneNumLbl.textAlignment = .center
        phoneNumLbl.numberOfLines = 0

        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(phoneNumLbl)
        contentStack.addArrangedSubview(makeSpacer(18))

        otpFieldView.translatesAutoresizingMaskIntoConstraints = false
        otpFieldView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        contentStack.addArrangedSubview(otpFieldView)

        resendBtn.setTitle("Resend Code", for: .normal)
        resendBtn.setTitleColor(AuthTheme.link, for: .normal)
        resendBtn.titleLabel?.font = Constant.Font.interRegular(size: 14)
        resendBtn.bgColor = .clear
        resendBtn.indicator = MaterialLoadingIndicator(color: AuthTheme.link)
        resendBtn.addTarget(self, action: #selector(onClickDidNotGetCode), for: .touchUpInside)
        resendBtn.heightAnchor.constraint(equalToConstant: 32).isActive = true
        contentStack.addArrangedSubview(resendBtn)

        timerLbl.textColor = AuthTheme.subtitle
        timerLbl.font = Constant.Font.interRegular(size: 12)
        timerLbl.textAlignment = .center
        contentStack.addArrangedSubview(timerLbl)

        stylePrimaryButton(continueBtn, title: "Continue")
        continueBtn.addTarget(self, action: #selector(onClickContinue), for: .touchUpInside)
        contentStack.addArrangedSubview(continueBtn)

        backBtn.setTitle("Back", for: .normal)
        backBtn.setTitleColor(AuthTheme.title, for: .normal)
        backBtn.titleLabel?.font = Constant.Font.interSemiBold(size: 16)
        backBtn.bgColor = .clear
        backBtn.layer.cornerRadius = 16
        backBtn.layer.borderWidth = 1
        backBtn.layer.borderColor = AuthTheme.border.cgColor
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.heightAnchor.constraint(equalToConstant: 54).isActive = true
        contentStack.addArrangedSubview(backBtn)
    }

    private func setOtpView() {
        otpFieldView.delegate = self
        otpFieldView.fieldsCount = 6
        otpFieldView.fieldBorderWidth = 0
        otpFieldView.defaultBackgroundColor = AuthTheme.fieldBackground
        otpFieldView.filledBackgroundColor = AuthTheme.fieldBackground
        otpFieldView.defaultBorderColor = .clear
        otpFieldView.filledBorderColor = .clear
        otpFieldView.cursorColor = AuthTheme.link
        otpFieldView.displayType = .roundedCorner
        otpFieldView.fieldSize = 58
        otpFieldView.separatorSpace = 7
        otpFieldView.shouldAllowIntermediateEditing = false
        otpFieldView.initializeUI()

        DispatchQueue.main.async {
            self.otpFieldView.subviews.forEach { view in
                if let textField = view as? UITextField {
                    textField.textColor = AuthTheme.title
                    textField.font = Constant.Font.interRegular(size: 30)
                    textField.backgroundColor = AuthTheme.fieldBackground
                    textField.layer.cornerRadius = 12
                    textField.clipsToBounds = true
                    textField.keyboardType = .numberPad
                }
            }
        }
    }

    private func setResendEnabled(_ enabled: Bool) {
        resendBtn.isEnabled = enabled
        resendBtn.isUserInteractionEnabled = enabled
        resendBtn.alpha = enabled ? 1.0 : 0.5
    }

    private func startTimer() {
        timer.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }

            self.count -= 1

            if self.count <= 0 {
                timer.invalidate()
                self.timerLbl.text = ""
                self.setResendEnabled(true)
                return
            }

            let time = self.secondsToHoursMinutesSeconds(seconds: self.count)
            self.timerLbl.text = self.makeTimeString(minutes: time.0, seconds: time.1)
        }

        RunLoop.main.add(timer, forMode: .common)
    }

    private func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int) {
        (((seconds % 3600) / 60), ((seconds % 3600) % 60))
    }

    private func makeTimeString(minutes: Int, seconds: Int) -> String {
        "in \(String(format: "%02d", seconds))s"
    }

    @objc private func onClickContinue() {
        if otpText.isEmpty {
            showAlert(with: "", message: "Please Enter Otp")
        } else {
            otpVerification()
        }
    }

    @objc private func onClickDidNotGetCode() {
        guard count <= 0 else { return }
        guard !isResendingOtp else { return }

        isResendingOtp = true
        setResendEnabled(false)
        resendBtn.showLoader(userInteraction: false)

        let finishResend: (String?, String, Bool, String?) -> Void = { [weak self] otp, otpRef, isSuccess, errorMsg in
            guard let self else { return }
            self.hideResendButtonLoader()

            if isSuccess {
                self.otpRef = otpRef
                self.currectOtp = otp
                self.resetResendTimerAfterSuccess()
            } else {
                self.setResendEnabled(true)
                Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
            }
        }

        if isFromLogin {
            authService.resendLoginOTP(otpRef: otpRef) { otp, otpRef, isSuccess, errorMsg in
                finishResend(otp, otpRef, isSuccess, errorMsg)
            }
        } else {
            if isFromSettings {
                if isForEmail {
                    settingsService.resendPhoneOrEmailOTP(otpRef: otpRef) { otp, otpRef, isSuccess, errMsg in
                        finishResend(otp, otpRef, isSuccess, errMsg)
                    }
                } else {
                    settingsService.resendPhoneOrEmailOTP(otpRef: otpRef, isPhone: true) { otp, otpRef, isSuccess, errMsg in
                        finishResend(otp, otpRef, isSuccess, errMsg)
                    }
                }
            } else {
                authService.resendSignupOTP(otpRef: otpRef) { otp, otpRef, isSuccess, errorMsg in
                    finishResend(otp, otpRef, isSuccess, errorMsg)
                }
            }
        }
    }

    @objc private func onClickBack() {
        dismiss(animated: true)
    }

    private func hideResendButtonLoader() {
        resendBtn.hideLoader { [weak self] in
            self?.isResendingOtp = false
        }
    }

    private func resetResendTimerAfterSuccess() {
        count = 60
        setResendEnabled(false)
        let time = secondsToHoursMinutesSeconds(seconds: count)
        timerLbl.text = makeTimeString(minutes: time.0, seconds: time.1)
        startTimer()
    }

    private func resetAfterFailedOtp() {
        otpText = ""
        isVerifyingOtp = false
        setButton(continueBtn, enabled: false)
        otpFieldView.initializeUI()
        setOtpView()
    }

    private func otpVerification() {
        guard !isVerifyingOtp else { return }
        guard otpText.count == 6 else { return }

        isVerifyingOtp = true
        continueBtn.showLoader(userInteraction: false)

        if isFromLogin {
            authService.verifyLoginOTP(otp: otpText, otpRef: otpRef) { [weak self] isSuccess, errorMsg in
                guard let self else { return }
                self.continueBtn.hideLoader()
                self.isVerifyingOtp = false

                if isSuccess {
                    self.dismiss(animated: true) { [weak self] in
                        self?.onOtpSuccess?()
                    }
                } else {
                    Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
                    self.resetAfterFailedOtp()
                }
            }
            return
        }

        if isFromSettings {
            if isForEmail {
                settingsService.verifyPhoneOrEmailOTP(otp: otpText, otpRef: otpRef) { [weak self] isSuccess, errMsg in
                    guard let self else { return }
                    self.continueBtn.hideLoader()
                    self.isVerifyingOtp = false

                    if isSuccess {
                        self.popToPersonalInfo()
                    } else {
                        Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                        self.resetAfterFailedOtp()
                    }
                }
            } else {
                settingsService.verifyPhoneOrEmailOTP(otp: otpText, otpRef: otpRef, isPhone: true) { [weak self] isSuccess, errMsg in
                    guard let self else { return }
                    self.continueBtn.hideLoader()
                    self.isVerifyingOtp = false

                    if isSuccess {
                        self.popToPersonalInfo()
                    } else {
                        Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                        self.resetAfterFailedOtp()
                    }
                }
            }
            return
        }

        authService.verifySignupOTP(otp: otpText, otpRef: otpRef) { [weak self] isSuccess, errorMsg in
            guard let self else { return }
            self.continueBtn.hideLoader()
            self.isVerifyingOtp = false

            if isSuccess {
                Navigate.to.enterNameVc(self)
            } else {
                Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
                self.resetAfterFailedOtp()
            }
        }
    }

    private func popToPersonalInfo() {
        for controller in navigationController?.viewControllers ?? [] {
            if controller.isKind(of: PersonalInformationViewController.self) {
                navigationController?.popToViewController(controller, animated: true)
                break
            }
        }
    }
}

extension VerifyNumberVC: OTPFieldViewDelegate {

    func shouldBecomeFirstResponderForOTP(otpTextFieldIndex index: Int) -> Bool {
        setButton(continueBtn, enabled: false)
        return true
    }

    func enteredOTP(otp: String) {
        otpText = otp
        setButton(continueBtn, enabled: otp.count == 6)
    }

    func hasEnteredAllOTP(hasEnteredAll: Bool) -> Bool {
        if hasEnteredAll {
            otpVerification()
        }
        return true
    }
}
