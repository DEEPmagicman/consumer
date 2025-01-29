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
    let phoneNumberUtility = PhoneNumberUtility()
    var phoneNumber: PhoneNumber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneNumTextField.delegate = self
        continueBtn.bgColor = Constant.Color.primaryBlue ?? .clear
        continueBtn.indicator = MaterialLoadingIndicator(color: .white)
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
        
        phoneNumTextField.withDefaultPickerUI = true
        phoneNumTextField.defaultRegion = "US"
        phoneNumTextField.withPrefix = true
        phoneNumTextField.withFlag = true
        phoneNumTextField.withExamplePlaceholder = true
        
        CountryCodePicker.alwaysShowsSearchBar = true
        CountryCodePicker.forceModalPresentation = true
        var options = CountryCodePickerOptions()
        options.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.00)
        options.textLabelFont = Constant.Font.poppinsRegular(size: 15)
        options.textLabelColor = UIColor(red: 0.63, green: 0.63, blue: 0.63, alpha: 1.00)
        options.detailTextLabelFont = Constant.Font.poppinsRegular(size: 15)
        phoneNumTextField.withDefaultPickerUIOptions = options
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        let phoneNum = self.phoneNumber?.nationalNumber ?? 0
        continueBtn.showLoader(userInteraction: false)
//        self.view.isUserInteractionEnabled = false
        if isFromLogin {
            onBoardingPresenter.loginWithPhoneApi(phonenum: "\(phoneNum)", code: "+\(self.phoneNumber?.countryCode ?? 1)") { [weak self] otp, otpRef, isSuccess, errorMsg in
                guard let self = self else { return }
                
                continueBtn.hideLoader()
//                self.view.isUserInteractionEnabled = true
                if isSuccess {
                    Navigate.to.enterVerificationCodeVc(self, isFromLogin: true, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "")
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
                settingPresenter.changePhoneNumberApi(phone: "\(phoneNum)", code: "+\(self.phoneNumber?.countryCode ?? 1)") { [weak self] otp, otpRef, isSuccess, errMsg in
                    guard let self = self else { return }
                    
                    continueBtn.hideLoader()
                    if isSuccess {
                        Navigate.to.enterVerificationCodeVc(self, isFromSettings: self.isFromSettings, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "")
                    } else if errMsg == Constant.String.internetNotConnect {
                        self.view.endEditing(true)
//                        self.view.isUserInteractionEnabled = true
                    } else {
//                        self.view.isUserInteractionEnabled = true
                        Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                    }
                }
            } else {
                onBoardingPresenter.signUpWithPhoneApi(phonenum: "\(phoneNum)", code: "+\(self.phoneNumber?.countryCode ?? 1)") { [weak self] otp, otpRef, isSuccess, errorMsg  in
                    guard let self = self else { return }
                    
                    continueBtn.hideLoader()
                    if isSuccess {
                        UserDefault.shared.user?.phone = "\(phoneNum)"
                        Navigate.to.enterVerificationCodeVc(self, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "")
                    } else if errorMsg == Constant.String.internetNotConnect {
//                        self.view.isUserInteractionEnabled = true
                        self.view.endEditing(true)
                    } else {
//                        self.view.isUserInteractionEnabled = true
                        if errorMsg == "Entered phone number already exist in system." {
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
        let currentText = textField.text ?? ""
        guard let textRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)
        if currentText == "+" && string.isEmpty {
            return false
        }
        if !updatedText.hasPrefix("+") {
            textField.text = "+" + updatedText.replacingOccurrences(of: "+", with: "")
            return false
        }
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        do {
            let phoneNumber = try phoneNumberUtility.parse(phoneNumTextField.text ?? "")
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
