//
//  VerificationCodeViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit
import OTPFieldView
import SwiftUI

final class VerificationCodeViewController: UIViewController {

    @IBOutlet weak var phoneNumLbl: UILabel!
    @IBOutlet weak var otpFieldView: OTPFieldView!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var timerLbl: UILabel!
    @IBOutlet weak var resendBtn: UIButton!
    
    var otpText = ""
    var currectOtp: String?
    var otpRef = ""
    var phoneNum = ""
    var countryCode = ""
    var isFromLogin = false
    var isFromSettings = false
    var isForEmail = false
    private var onBoardingDelegate = OnBoardingPresenter()
    private var settingDelegate = SettingPresenter()
    private var timer = Timer()
    private var count = 60
    private var lastCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        otpFieldView.delegate = self
        setOtpView()
        
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
        let time = secondsToHoursMinutesSeconds(seconds: count)
        timerLbl.text = makeTimeString(minutes: time.0, seconds: time.1)
        startTimer()
        resendBtn.alpha = 0.5
        resendBtn.isUserInteractionEnabled = false
        #if DEBUG
        print("*-*\(currectOtp)")
        Alert.showAlertSheet(style: .alert, title: "Otp", message: "\(currectOtp ?? "")")
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        phoneNumLbl.text = "\(countryCode) \(phoneNum)"
    }
    
    private func setOtpView() {
        otpFieldView.fieldsCount = 6
        otpFieldView.fieldBorderWidth = 1
        otpFieldView.defaultBorderColor = .white
        otpFieldView.cursorColor = Constant.Color.purpleColor
        otpFieldView.filledBorderColor = Constant.Color.purpleColor
        otpFieldView.displayType = .underlinedBottom
        otpFieldView.fieldSize = 50
        otpFieldView.separatorSpace = 9
        otpFieldView.shouldAllowIntermediateEditing = false
        otpFieldView.initializeUI()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.count = self.count - 1
            if self.count <= 0 {
                timer.invalidate()
                self.resendBtn.alpha = 1
                self.resendBtn.isUserInteractionEnabled = true
            }
            let time = self.secondsToHoursMinutesSeconds(seconds: self.count)
            let timeString = self.makeTimeString(minutes: time.0, seconds: time.1)
            if self.count <= 0 {
                self.timerLbl.text = ""
            } else {
                self.timerLbl.text = timeString
            }
        }
    }
    
    func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int) {
        return (((seconds % 3600) / 60),((seconds % 3600) % 60))
    }
    
    func makeTimeString(minutes: Int, seconds : Int) -> String {
        "in \(String(format: "%02d", seconds))s"
    }
    
    @IBAction func onClickEdit(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        if otpText == "" {
            showAlert(with: "", message: "Please Enter Otp")
        } else {
            otpVerification()
        }
    }
    
    @IBAction func onClickDidNotGetCode(_ sender: Any) {
        count = 60
        startTimer()
        resendBtn.alpha = 0.5
        resendBtn.isUserInteractionEnabled = false
        if isFromLogin {
            self.onBoardingDelegate.loginResendOtpApi(otpref: self.otpRef) { [weak self] otp, otpRef, isSuccess,errorMsg  in
                guard let self = self else {
                    Loader.hide()
                    return
                }
                if isSuccess {
                    self.otpRef = otpRef
                    self.currectOtp = otp
                    print("*-*\(self.currectOtp)")
                } else {
                    if errorMsg != nil {
                        Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                    } else {
                        Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                    }
                }
                Loader.hide()
            }
        } else {
            if isFromSettings {
                if isForEmail {
                    self.settingDelegate.changeEmailPhoneResendOtpApi(otpref: self.otpRef) { [weak self] otp, otpRef, isSuccess, errMsg in
                        guard let self = self else {
                            Loader.hide()
                            return
                        }
                        if isSuccess {
                            self.otpRef = otpRef
                            self.currectOtp = otp
                            print("*-*\(self.currectOtp)")
                        } else {
                            if errMsg != nil {
                                Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                            } else {
                                Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                            }
                        }
                        Loader.hide()
                    }
                } else {
                    self.settingDelegate.changeEmailPhoneResendOtpApi(otpref: self.otpRef,isForPhone: true) { [weak self] otp, otpRef, isSuccess, errMsg in
                        guard let self = self else {
                            Loader.hide()
                            return
                        }
                        if isSuccess {
                            self.otpRef = otpRef
                            self.currectOtp = otp
                            print("*-*\(self.currectOtp)")
                        } else {
                            if errMsg != nil {
                                Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                            } else {
                                Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                            }
                        }
                        Loader.hide()
                    }
                }
            } else {
                self.onBoardingDelegate.signUpResendOtpApi(otpref: self.otpRef) { [weak self] otp, otpRef, isSuccess,errorMsg  in
                    guard let self = self else {
                        Loader.hide()
                        return
                    }
                    if isSuccess {
                        self.otpRef = otpRef
                        self.currectOtp = otp
                        print("*-*\(self.currectOtp)")
                    } else {
                        if errorMsg != nil {
                            Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                        } else {
                            Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                        }
                    }
                    Loader.hide()
                }
            }
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private func otpVerification() {
        if isFromLogin {
            self.onBoardingDelegate.loginOtpVerifyApi(otp: Int(otpText) ?? 0, otpRef: self.otpRef) { [weak self] isSuccess, errorMsg  in
                guard let self = self else {
                    Loader.hide()
                    return
                }
                if isSuccess {
                    Loader.hide()
                    if UserDefault.shared.user?.isProfileCompleted == true {
                        AppDelegate.shared.changeRootViewController()
                    } else {
                        Navigate.to.connectAccountVc(self)
                    }
                } else {
                    if errorMsg != nil {
                        Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                    } else {
                        Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                    }
                    Loader.hide()
                }
            }
            print("*-*login")
        } else {
            if isFromSettings {
                if isForEmail {
                    self.settingDelegate.changeEmailPhoneVerifyApi(otp: Int(otpText) ?? 0, otpRef: self.otpRef) { [weak self] isSuccess, errMsg in
                        guard let self = self else {
                            Loader.hide()
                            return
                        }
                        if isSuccess {
                            for controller in self.navigationController!.viewControllers{
                                if controller.isKind(of: PersonalInformationViewController.self) {
                                    self.navigationController?.popToViewController(controller, animated: true) }
                            }

                        } else {
                            if errMsg != nil {
                                Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                            } else {
                                Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                            }
                        }
                        Loader.hide()
                    }
                    print("*-*email")
                } else {
//                    if let pInfoVC = navigationController?.viewControllers.first(where: { ($0 as? PersonalInformationViewController) != nil}) {
//                          self.navigationController?.popToViewController(pInfoVC, animated: false)
//                        }
                    self.settingDelegate.changeEmailPhoneVerifyApi(otp: Int(otpText) ?? 0, otpRef: self.otpRef, isForPhone: true) { [weak self] isSuccess, errMsg in
                        guard let self = self else {
                            Loader.hide()
                            return
                        }
                        if isSuccess {
                            for controller in self.navigationController!.viewControllers{
                                if controller.isKind(of: PersonalInformationViewController.self) {
                                    self.navigationController?.popToViewController(controller, animated: true) }
                            }

                        } else {
                            if errMsg != nil {
                                Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                            } else {
                                Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                            }
                        }
                        Loader.hide()
                    }
                    print("*-*settingPhone")
                }
            } else {
                self.onBoardingDelegate.signUpOtpVerifyApi(otp: Int(otpText) ?? 0, otpRef: self.otpRef) { [weak self] isSuccess, errorMsg  in
                    guard let self = self else {
                        Loader.hide()
                        return
                    }
                    if isSuccess {
                        Navigate.to.connectAccountVc(self)
                        Loader.hide()
                    } else {
                        if errorMsg != nil {
                            Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                        } else {
                            Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                        }
                        Loader.hide()
                    }
                }
               print("*-*signup")
            }
        }
    }
}

extension VerificationCodeViewController: OTPFieldViewDelegate {
    func shouldBecomeFirstResponderForOTP(otpTextFieldIndex index: Int) -> Bool {
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
        return true
    }
    
    func enteredOTP(otp: String) {
        otpText = otp
        continueBtn.isUserInteractionEnabled = true
        continueBtn.alpha = 1.0
    }
    
    func hasEnteredAllOTP(hasEnteredAll: Bool) -> Bool {
        if hasEnteredAll {
            otpVerification()
        }
        return true
    }
}
