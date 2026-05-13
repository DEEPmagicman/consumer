//
//  AuthPhoneOTPVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 12/05/26.
//

import UIKit
import MHLoadingButton

final class AuthPhoneOTPVC: BaseAuthViewController {

    private let phoneView = AuthPhoneInputView()
    private let otpView = AuthOTPInputView()

    var isFromLogin = true
    var isFromSettings = false
    var isForEmail = false
    var onOtpSuccess: (() -> Void)?

    private var onBoardingPresenter = OnBoardingPresenter()
    private var settingPresenter = SettingPresenter()

    private var currectOtp: String?
    private var otpRef = ""
    private var phoneNum = ""
    private var countryCode = ""

    private var timer = Timer()
    private var count = 60
    private var isVerifyingOtp = false
    private var isShowingOTP = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildViews()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }

    deinit {
        timer.invalidate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isShowingOTP {
            phoneView.focusPhoneField()
        }
    }
        
    private func setupChildViews() {
        phoneView.delegate = self
        otpView.delegate = self

        contentStack.addArrangedSubview(phoneView)
        contentStack.addArrangedSubview(otpView)

        otpView.isHidden = true
    }

    private func flipToOTP() {
        guard !isShowingOTP else { return }
        isShowingOTP = true

        view.endEditing(true)
        
        UIView.performWithoutAnimation {
            self.view.layoutIfNeeded()
        }
        
        otpView.configure(phone: phoneNum, countryCode: countryCode)
        otpView.resetOTP()
        resetTimer()
        
        otpView.alpha = 0
        otpView.isHidden = false
        
        UIView.transition(
            with: cardView,
            duration: 0.55,
            options: [.transitionFlipFromRight, .showHideTransitionViews, .curveEaseInOut, .allowAnimatedContent]
        ) {
            self.phoneView.alpha = 0
            self.otpView.alpha = 1
            
            self.phoneView.isHidden = true
            self.cardView.layoutIfNeeded()
            self.otpView.layoutIfNeeded()
        }
       
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.otpView.focusFirstField()
        }
    }
    
    private func flipToPhone() {
        guard isShowingOTP else { return }
        isShowingOTP = false

        timer.invalidate()
        view.endEditing(true)
        UIView.performWithoutAnimation {
            self.view.layoutIfNeeded()
        }
        
        phoneView.layoutIfNeeded()
        phoneView.alpha = 0
        phoneView.isHidden = false
        
        UIView.transition(
            with: cardView,
            duration: 0.55,
            options: [.transitionFlipFromLeft, .showHideTransitionViews, .curveEaseInOut, .allowAnimatedContent]
        ) {
            self.otpView.alpha = 0
            self.phoneView.alpha = 1
            
            self.otpView.isHidden = true
            self.cardView.layoutIfNeeded()
        } completion: { _ in
            self.phoneView.focusPhoneField()
        }
    }
    
    private func resetTimer() {
        count = 60
        otpView.setResendEnabled(false)

        let time = secondsToHoursMinutesSeconds(seconds: count)
        otpView.updateTimer(makeTimeString(minutes: time.0, seconds: time.1))

        startTimer()
    }

    private func startTimer() {
        timer.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }

            self.count -= 1

            if self.count <= 0 {
                timer.invalidate()
                self.otpView.updateTimer("")
                self.otpView.setResendEnabled(true)
                return
            }

            let time = self.secondsToHoursMinutesSeconds(seconds: self.count)
            self.otpView.updateTimer(self.makeTimeString(minutes: time.0, seconds: time.1))
        }

        RunLoop.main.add(timer, forMode: .common)
    }

    private func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int) {
        (((seconds % 3600) / 60), ((seconds % 3600) % 60))
    }

    private func makeTimeString(minutes: Int, seconds: Int) -> String {
        "in \(String(format: "%02d", seconds))s"
    }

    private func handlePhoneSuccess(otp: String?, otpRef: String?) {
        self.currectOtp = otp
        self.otpRef = otpRef ?? ""
        self.phoneNum = phoneView.phoneText()
        self.countryCode = phoneView.countryCode()
        flipToOTP()
    }

    private func resetAfterFailedOtp() {
        isVerifyingOtp = false
        otpView.resetOTP()
    }

    private func verifyOtp(_ otp: String) {
        guard !isVerifyingOtp else { return }
        guard otp.count == 6 else { return }

        isVerifyingOtp = true
        otpView.continueBtn.showLoader(userInteraction: false)

        if isFromLogin {
            onBoardingPresenter.loginOtpVerifyApi(otp: Int(otp) ?? 0, otpRef: otpRef) { [weak self] isSuccess, errorMsg in
                guard let self else { return }
                self.otpView.continueBtn.hideLoader()
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
                settingPresenter.changeEmailPhoneVerifyApi(otp: Int(otp) ?? 0, otpRef: otpRef) { [weak self] isSuccess, errMsg in
                    guard let self else { return }
                    self.otpView.continueBtn.hideLoader()
                    self.isVerifyingOtp = false

                    if isSuccess {
                        self.dismiss(animated: true)
                    } else {
                        Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                        self.resetAfterFailedOtp()
                    }
                }
            } else {
                settingPresenter.changeEmailPhoneVerifyApi(otp: Int(otp) ?? 0, otpRef: otpRef, isForPhone: true) { [weak self] isSuccess, errMsg in
                    guard let self else { return }
                    self.otpView.continueBtn.hideLoader()
                    self.isVerifyingOtp = false

                    if isSuccess {
                        self.dismiss(animated: true)
                    } else {
                        Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                        self.resetAfterFailedOtp()
                    }
                }
            }
            return
        }

        onBoardingPresenter.signUpOtpVerifyApi(otp: Int(otp) ?? 0, otpRef: otpRef) { [weak self] isSuccess, errorMsg in
            guard let self else { return }
            self.otpView.continueBtn.hideLoader()
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
    }
}

extension AuthPhoneOTPVC: AuthPhoneInputViewDelegate {

    func authPhoneInputView(_ view: AuthPhoneInputView, didChangeValidPhone isValid: Bool) {}

    func authPhoneInputViewDidTapContinue(_ view: AuthPhoneInputView) {
        let phone = view.phoneNationalNumber()
        let code = view.countryCode()

        phoneView.continueBtn.showLoader(userInteraction: false)

        if isFromLogin {
            onBoardingPresenter.loginWithPhoneApi(phonenum: phone, code: code) { [weak self] otp, otpRef, isSuccess, errorMsg in
                guard let self else { return }
                self.phoneView.continueBtn.hideLoader()

                if isSuccess {
                    self.handlePhoneSuccess(otp: otp, otpRef: otpRef)
                } else if errorMsg == Constant.String.internetNotConnect {
                    self.view.endEditing(true)
                } else {
                    Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
                }
            }
            return
        }

        if isFromSettings {
            settingPresenter.changePhoneNumberApi(phone: phone, code: code) { [weak self] otp, otpRef, isSuccess, errMsg in
                guard let self else { return }
                self.phoneView.continueBtn.hideLoader()

                if isSuccess {
                    self.handlePhoneSuccess(otp: otp, otpRef: otpRef)
                } else if errMsg == Constant.String.internetNotConnect {
                    self.view.endEditing(true)
                } else {
                    Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                }
            }
        } else {
            onBoardingPresenter.signUpWithPhoneApi(phonenum: phone, code: code) { [weak self] otp, otpRef, isSuccess, errorMsg in
                guard let self else { return }
                self.phoneView.continueBtn.hideLoader()

                if isSuccess {
                    UserDefault.shared.user?.phone = phone
                    self.handlePhoneSuccess(otp: otp, otpRef: otpRef)
                } else if errorMsg == Constant.String.internetNotConnect {
                    self.view.endEditing(true)
                } else {
                    if errorMsg == "Entered phone number already exists in system." {
                        self.isFromLogin = true
                        self.authPhoneInputViewDidTapContinue(view)
                    } else {
                        Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
                    }
                }
            }
        }
    }
}

extension AuthPhoneOTPVC: AuthOTPInputViewDelegate {

    func authOTPInputViewDidTapContinue(_ view: AuthOTPInputView, otp: String) {
        verifyOtp(otp)
    }

    func authOTPInputViewDidTapBack(_ view: AuthOTPInputView) {
        flipToPhone()
    }

    func authOTPInputViewDidTapResend(_ view: AuthOTPInputView) {
        count = 60
        otpView.setResendEnabled(false)
        startTimer()

        otpView.resendBtn.showLoader(userInteraction: false)

        if isFromLogin {
            onBoardingPresenter.loginResendOtpApi(otpref: otpRef) { [weak self] otp, otpRef, isSuccess, errorMsg in
                guard let self else { return }
                self.otpView.resendBtn.hideLoader()

                if isSuccess {
                    self.otpRef = otpRef
                    self.currectOtp = otp
                } else {
                    Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
                }
            }
        } else {
            onBoardingPresenter.signUpResendOtpApi(otpref: otpRef) { [weak self] otp, otpRef, isSuccess, errorMsg in
                guard let self else { return }
                self.otpView.resendBtn.hideLoader()

                if isSuccess {
                    self.otpRef = otpRef
                    self.currectOtp = otp
                } else {
                    Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
}
