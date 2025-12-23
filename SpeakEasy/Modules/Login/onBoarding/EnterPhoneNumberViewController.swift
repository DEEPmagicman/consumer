//
//  EnterPhoneNumberViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit
import MHLoadingButton

final class EnterPhoneNumberViewController: UIViewController {
    
    @IBOutlet weak var continueBtn: LoadingButton!
    @IBOutlet weak var phoneNumTextField: PhoneNumberTextField!

    var isFromLogin = false
    private var onBoardingPresenter = OnBoardingPresenter()
    private var settingPresenter = SettingPresenter()
    var isFromSettings = false
    private let phoneNumberUtility = PhoneNumberUtility()
    private var phoneNumber: PhoneNumber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneNumTextField.delegate = self
        continueBtn.bgColor = Constant.Color.primaryBlue ?? .clear
        continueBtn.indicator = MaterialLoadingIndicator(color: .white)
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
        
        phoneNumTextField.withDefaultPickerUI = true
        phoneNumTextField.defaultRegion = "US"
        phoneNumTextField.withPrefix = false
        phoneNumTextField.withFlag = true
        phoneNumTextField.withExamplePlaceholder = true
        
        CountryCodePicker.alwaysShowsSearchBar = true
        CountryCodePicker.forceModalPresentation = true
        var options = CountryCodePickerOptions()
        options.backgroundColor = Constant.Color.backgroundColor
        options.textLabelFont = Constant.Font.poppinsRegular(size: 15)
        options.textLabelColor = Constant.Color.textLabelColor
        options.detailTextLabelFont = Constant.Font.poppinsRegular(size: 15)
        phoneNumTextField.withDefaultPickerUIOptions = options
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        let phoneNum = self.phoneNumber?.nationalNumber ?? 0
        let countryCode = phoneNumTextField?.flagButton.titleLabel?.text?.components(separatedBy: .whitespaces).joined().filter { $0.isASCII }
        continueBtn.showLoader(userInteraction: false)
//        self.view.isUserInteractionEnabled = false
        if isFromLogin {
            onBoardingPresenter.loginWithPhoneApi(phonenum: "\(phoneNum)", code: countryCode ?? "+1") { [weak self] otp, otpRef, isSuccess, errorMsg in
                guard let self = self else { return }
                
                continueBtn.hideLoader()
//                self.view.isUserInteractionEnabled = true
                if isSuccess {
                    Navigate.to.enterVerificationCodeVc(self, isFromLogin: true, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "", countryCode: countryCode ?? "+1")
                } else if errorMsg == Constant.String.internetNotConnect {
                    self.view.endEditing(true)
//                    self.view.isUserInteractionEnabled = true
                } else {
//                    self.view.isUserInteractionEnabled = true
                    Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
                }
            }
        } else {
            if isFromSettings {
                settingPresenter.changePhoneNumberApi(phone: "\(phoneNum)", code: countryCode ?? "+1") { [weak self] otp, otpRef, isSuccess, errMsg in
                    guard let self = self else { return }
                    
                    continueBtn.hideLoader()
                    if isSuccess {
                        Navigate.to.enterVerificationCodeVc(self, isFromSettings: self.isFromSettings, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "", countryCode: countryCode ?? "+1")
                    } else if errMsg == Constant.String.internetNotConnect {
                        self.view.endEditing(true)
//                        self.view.isUserInteractionEnabled = true
                    } else {
//                        self.view.isUserInteractionEnabled = true
                        Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                    }
                }
            } else {
                onBoardingPresenter.signUpWithPhoneApi(phonenum: "\(phoneNum)", code: countryCode ?? "+1") { [weak self] otp, otpRef, isSuccess, errorMsg  in
                    guard let self = self else { return }
                    
                    continueBtn.hideLoader()
                    if isSuccess {
                        UserDefault.shared.user?.phone = "\(phoneNum)"
                        Navigate.to.enterVerificationCodeVc(self, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "", countryCode: countryCode ?? "+1")
                    } else if errorMsg == Constant.String.internetNotConnect {
//                        self.view.isUserInteractionEnabled = true
                        self.view.endEditing(true)
                    } else {
//                        self.view.isUserInteractionEnabled = true
                        if errorMsg == "Entered phone number already exists in system." {
                            self.isFromLogin = true
                            self.onClickContinue(0)
                        } else {
                            Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
                        }
                    }
                }
            }
        }
    }
}

extension EnterPhoneNumberViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        do {
            let phoneNumber = try phoneNumberUtility.parse(phoneNumTextField.text ?? "", withRegion: phoneNumTextField.defaultRegion)
            self.phoneNumber = phoneNumber
            continueBtn.isUserInteractionEnabled = true
            continueBtn.alpha = 1
        }
        catch {
            continueBtn.isUserInteractionEnabled = false
            continueBtn.alpha = 0.5
        }
    }
}
