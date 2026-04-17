//
//  VerifyNumberViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 28/02/26.
//

import UIKit
import OTPFieldView
import MHLoadingButton

final class VerifyNumberViewController: UIViewController {

    @IBOutlet weak var phoneNumLbl: UILabel!
    @IBOutlet weak var otpFieldView: OTPFieldView!
    @IBOutlet weak var continueBtn: LoadingButton!
    @IBOutlet weak var timerLbl: UILabel!
    @IBOutlet weak var resendBtn: LoadingButton!

    var otpText = ""
    var currectOtp: String?
    var otpRef = ""
    var phoneNum = ""
    var countryCode = ""

    var isFromLogin = false
    var isFromSettings = false
    var isForEmail = false
    var onOtpSuccess: (() -> Void)?

    private var onBoardingDelegate = OnBoardingPresenter()
    private var settingDelegate = SettingPresenter()

    private var timer = Timer()
    private var count = 60

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        otpFieldView.delegate = self
        setOtpView()

        // Buttons setup
        continueBtn.bgColor = .white
        continueBtn.indicator = MaterialLoadingIndicator(color: .black)

        resendBtn.bgColor = .clear
        resendBtn.indicator = MaterialLoadingIndicator(color: .white)

        setContinueEnabled(false)
        setResendEnabled(false)

        // Timer label initial
        let time = secondsToHoursMinutesSeconds(seconds: count)
        timerLbl.text = makeTimeString(minutes: time.0, seconds: time.1)
        startTimer()

//        if Utility.isDebug {
//            Alert.showAlertSheet(style: .alert, title: "Otp", message: "\(currectOtp ?? "")")
//        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        phoneNumLbl.text = "\(countryCode) \(phoneNum)"
    }

    deinit {
        timer.invalidate()
    }

    // MARK: - UI Helpers
    private func setOtpView() {
        otpFieldView.fieldsCount = 6
        otpFieldView.fieldBorderWidth = 1
        otpFieldView.defaultBorderColor = UIColor(hex: "#737373")
        otpFieldView.cursorColor = Constant.Color.purpleColor
        otpFieldView.filledBorderColor = .white
        otpFieldView.displayType = .roundedCorner
        otpFieldView.fieldSize = 50
        otpFieldView.separatorSpace = 5
        otpFieldView.shouldAllowIntermediateEditing = false
        otpFieldView.initializeUI()
//        for (index, subview) in otpFieldView.subviews.enumerated() {
//            if let textField = subview as? UITextField {
//
//                textField.layer.masksToBounds = true
//
//                if index == 0 {
//                    // First box → round left corners
//                    textField.layer.cornerRadius = 8
//                    textField.layer.maskedCorners = [
//                        .layerMinXMinYCorner,
//                        .layerMinXMaxYCorner
//                    ]
//                }
//                else if index == otpFieldView.fieldsCount - 1 {
//                    // Last box → round right corners
//                    textField.layer.cornerRadius = 8
//                    textField.layer.maskedCorners = [
//                        .layerMaxXMinYCorner,
//                        .layerMaxXMaxYCorner
//                    ]
//                }
//                else {
//                    // Middle boxes → no radius
//                    textField.layer.cornerRadius = 0
//                }
//            }
//        }
    }

    private func setContinueEnabled(_ enabled: Bool) {
        continueBtn.isUserInteractionEnabled = enabled
        continueBtn.alpha = enabled ? 1.0 : 0.5
    }

    private func setResendEnabled(_ enabled: Bool) {
        resendBtn.isUserInteractionEnabled = enabled
        resendBtn.alpha = enabled ? 1.0 : 0.5
    }

    // MARK: - Timer
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
    }

    private func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int) {
        return (((seconds % 3600) / 60), ((seconds % 3600) % 60))
    }

    private func makeTimeString(minutes: Int, seconds: Int) -> String {
        "in \(String(format: "%02d", seconds))s"
    }

    // MARK: - Actions
    @IBAction func onClickEdit(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func onClickContinue(_ sender: Any) {
        if otpText.isEmpty {
            showAlert(with: "", message: "Please Enter Otp")
        } else {
            otpVerification()
        }
    }

    @IBAction func onClickDidNotGetCode(_ sender: Any) {
        // reset timer & UI
        count = 60
        setResendEnabled(false)
        startTimer()

        resendBtn.showLoader(userInteraction: false)

        if isFromLogin {
            onBoardingDelegate.loginResendOtpApi(otpref: otpRef) { [weak self] otp, otpRef, isSuccess, errorMsg in
                guard let self else { return }
                self.hideResendButtonLoader()

                if isSuccess {
                    self.otpRef = otpRef
                    self.currectOtp = otp
                } else {
                    Alert.showAlertSheet(style: .alert,
                                         title: errorMsg ?? Constant.String.somethingWrong,
                                         message: "")
                }
            }
        } else {
            if isFromSettings {
                // Settings: email or phone
                if isForEmail {
                    settingDelegate.changeEmailPhoneResendOtpApi(otpref: otpRef) { [weak self] otp, otpRef, isSuccess, errMsg in
                        guard let self else { return }
                        self.hideResendButtonLoader()

                        if isSuccess {
                            self.otpRef = otpRef
                            self.currectOtp = otp
                        } else {
                            Alert.showAlertSheet(style: .alert,
                                                 title: errMsg ?? Constant.String.somethingWrong,
                                                 message: "")
                        }
                    }
                } else {
                    settingDelegate.changeEmailPhoneResendOtpApi(otpref: otpRef, isForPhone: true) { [weak self] otp, otpRef, isSuccess, errMsg in
                        guard let self else { return }
                        self.hideResendButtonLoader()

                        if isSuccess {
                            self.otpRef = otpRef
                            self.currectOtp = otp
                        } else {
                            Alert.showAlertSheet(style: .alert,
                                                 title: errMsg ?? Constant.String.somethingWrong,
                                                 message: "")
                        }
                    }
                }
            } else {
                // Signup resend
                onBoardingDelegate.signUpResendOtpApi(otpref: otpRef) { [weak self] otp, otpRef, isSuccess, errorMsg in
                    guard let self else { return }
                    self.hideResendButtonLoader()

                    if isSuccess {
                        self.otpRef = otpRef
                        self.currectOtp = otp
                    } else {
                        Alert.showAlertSheet(style: .alert,
                                             title: errorMsg ?? Constant.String.somethingWrong,
                                             message: "")
                    }
                }
            }
        }
    }

    @IBAction func onClickBack(_ sender: Any) {
        self.dismiss(animated: false)
    }

    // MARK: - Loader helper
    private func hideResendButtonLoader() {
        resendBtn.hideLoader { [weak self] in
            self?.resendBtn.isUserInteractionEnabled = false
        }
    }

    // MARK: - Verify OTP
    private func otpVerification() {
        continueBtn.showLoader(userInteraction: false)

        if isFromLogin {
            onBoardingDelegate.loginOtpVerifyApi(otp: Int(otpText) ?? 0, otpRef: otpRef) { [weak self] isSuccess, errorMsg in
                guard let self else { return }
                self.continueBtn.hideLoader()

                if isSuccess {
                    self.dismiss(animated: true) { [weak self] in
                            self?.onOtpSuccess?()
                        }
//                    if UserDefault.shared.user?.isProfileCompleted == true {
//                        AppDelegate.gotoTab
//                    } else {
//                        Navigate.to.enterNameVc(self)
//                    }
                } else {
                    Alert.showAlertSheet(style: .alert,
                                         title: errorMsg ?? Constant.String.somethingWrong,
                                         message: "")
                    self.otpFieldView.initializeUI()
                }
            }
            return
        }

        if isFromSettings {
            if isForEmail {
                settingDelegate.changeEmailPhoneVerifyApi(otp: Int(otpText) ?? 0, otpRef: otpRef) { [weak self] isSuccess, errMsg in
                    guard let self else { return }
                    self.continueBtn.hideLoader()

                    if isSuccess {
                        for controller in self.navigationController?.viewControllers ?? [] {
                            if controller.isKind(of: PersonalInformationViewController.self) {
                                self.navigationController?.popToViewController(controller, animated: true)
                                break
                            }
                        }
                    } else {
                        Alert.showAlertSheet(style: .alert,
                                             title: errMsg ?? Constant.String.somethingWrong,
                                             message: "")
                        self.otpFieldView.initializeUI()
                    }
                }
            } else {
                settingDelegate.changeEmailPhoneVerifyApi(otp: Int(otpText) ?? 0, otpRef: otpRef, isForPhone: true) { [weak self] isSuccess, errMsg in
                    guard let self else { return }
                    self.continueBtn.hideLoader()

                    if isSuccess {
                        for controller in self.navigationController?.viewControllers ?? [] {
                            if controller.isKind(of: PersonalInformationViewController.self) {
                                self.navigationController?.popToViewController(controller, animated: true)
                                break
                            }
                        }
                    } else {
                        Alert.showAlertSheet(style: .alert,
                                             title: errMsg ?? Constant.String.somethingWrong,
                                             message: "")
                        self.otpFieldView.initializeUI()
                    }
                }
            }
            return
        }

        // Signup verify
        onBoardingDelegate.signUpOtpVerifyApi(otp: Int(otpText) ?? 0, otpRef: otpRef) { [weak self] isSuccess, errorMsg in
            guard let self else { return }
            self.continueBtn.hideLoader()

            if isSuccess {
                Navigate.to.enterNameVc(self)
            } else {
                Alert.showAlertSheet(style: .alert,
                                     title: errorMsg ?? Constant.String.somethingWrong,
                                     message: "")
                self.otpFieldView.initializeUI()
            }
        }
    }
}

// MARK: - OTPFieldViewDelegate
extension VerifyNumberViewController: OTPFieldViewDelegate {

    func shouldBecomeFirstResponderForOTP(otpTextFieldIndex index: Int) -> Bool {
        // When user starts typing again, disable continue until we have OTP
        setContinueEnabled(false)
        return true
    }

    func enteredOTP(otp: String) {
        otpText = otp
        setContinueEnabled(true)
    }

    func hasEnteredAllOTP(hasEnteredAll: Bool) -> Bool {
        if hasEnteredAll {
            otpVerification()
        }
        return true
    }
}
