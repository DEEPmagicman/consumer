//
//  EnterPhoneNumberViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit
import FlagPhoneNumber
import MHLoadingButton

final class EnterPhoneNumberViewController: UIViewController {
    
    @IBOutlet weak var countryCodeTextField: FPNTextField!
    @IBOutlet weak var continueBtn: LoadingButton!
    @IBOutlet weak var phoneNumTextField: UITextField!
    @IBOutlet weak var contrySelectionView: UIView!    

    var isFromLogin = false
    private var onBoardingPresenter = OnBoardingPresenter()
    private var settingPresenter = SettingPresenter()
    var countryCode = ""
    var isFromSettings = false
    
    private var checkFPNField = FPNTextField()
    var listController: FPNCountryListViewController = FPNCountryListViewController(style: .grouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneNumTextField.delegate = self
        checkFPNField.delegate = self
        
        countryCodeTextField.delegate = self
        countryCodeTextField.setFlag(countryCode: .US)
        countryCode = "+1"
        
        listController.setup(repository: countryCodeTextField.countryRepository)
        listController.didSelect = { [weak self] country in
            self?.countryCodeTextField.setFlag(countryCode: country.code)
        }
        
        countryCodeTextField.flagButtonSize = CGSize(width: 44, height: 44)
        countryCodeTextField.flagButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        countryCodeTextField.displayMode = .list // .picker by default
        
        listController.showCountryPhoneCode = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickCountrySelect))
        contrySelectionView.addGestureRecognizer(tap)
        continueBtn.bgColor = Constant.Color.primaryBlue ?? .clear
        continueBtn.indicator = MaterialLoadingIndicator(color: .white)
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
    }
    
    @objc func dismissCountries() {
        listController.dismiss(animated: true, completion: nil)
    }
    
    @objc func onClickCountrySelect() {
        fpnDisplayCountryList()
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        let phoneNum = phoneNumTextField.text?.replacingOccurrences(of: " ", with: "")
        continueBtn.showLoader(userInteraction: false)
        if isFromLogin {
            onBoardingPresenter.loginWithPhoneApi(phonenum: phoneNum ?? "", code: countryCode) { [weak self] otp, otpRef, isSuccess, errorMsg in
                guard let self = self else { return }
                
                continueBtn.hideLoader()
                if isSuccess {
                    Navigate.to.enterVerificationCodeVc(self, isFromLogin: true, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "", countryCode: self.countryCode)
                } else if errorMsg == Constant.String.internetNotConnect {
                    self.view.endEditing(true)
                } else {
                    Alert.showAlertSheet(style: .alert, title: errorMsg ?? Constant.String.somethingWrong, message: "")
                }
            }
        } else {
            if isFromSettings {
                settingPresenter.changePhoneNumberApi(phone: phoneNum ?? "", code: countryCode) { [weak self] otp, otpRef, isSuccess, errMsg in
                    guard let self = self else { return }
                    
                    continueBtn.hideLoader()
                    if isSuccess {
                        Navigate.to.enterVerificationCodeVc(self, isFromSettings: self.isFromSettings, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "", countryCode: self.countryCode)
                    } else if errMsg == Constant.String.internetNotConnect {
                        self.view.endEditing(true)
                    } else {
                        Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                    }
                }
            } else {
                onBoardingPresenter.signUpWithPhoneApi(phonenum: phoneNum ?? "", code: countryCode) { [weak self] otp, otpRef, isSuccess, errorMsg  in
                    guard let self = self else { return }
                    
                    continueBtn.hideLoader()
                    if isSuccess {
                        UserDefault.shared.user?.phone = phoneNum ?? ""
                        Navigate.to.enterVerificationCodeVc(self, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "", countryCode: self.countryCode)
                    } else if errorMsg == Constant.String.internetNotConnect {
                        self.view.endEditing(true)
                    } else {
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
    func textFieldDidChangeSelection(_ textField: UITextField) {
        checkFPNField.text = textField.text
        checkFPNField.sendActions(for: .editingChanged)
        phoneNumTextField.delegate = nil
        if textField.text?.contains("+") == true && checkFPNField.text?.contains("+") == false {
            checkFPNField.sendActions(for: .editingChanged)
        }
        phoneNumTextField.text = checkFPNField.text
        phoneNumTextField.delegate = self
    }
}

extension EnterPhoneNumberViewController: FPNTextFieldDelegate {
    
    func fpnDisplayCountryList() {
        
        let navigationViewController = UINavigationController(rootViewController: listController)
        
        listController.title = "Countries"
        listController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissCountries))
        
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
        if let countryCode = FPNCountryCode(rawValue: code) {
            if countryCode == checkFPNField.selectedCountry?.code { return }
            checkFPNField.delegate = nil
            checkFPNField.setFlag(countryCode: countryCode)
            checkFPNField.delegate = self
            checkFPNField.sendActions(for: .editingChanged)
            phoneNumTextField.delegate = nil
            phoneNumTextField.text = checkFPNField.text
            phoneNumTextField.delegate = self
            self.countryCode = dialCode
        }
    }
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        if textField == countryCodeTextField {
            phoneNumTextField.placeholder = countryCodeTextField.placeholder
            countryCodeTextField.placeholder = ""
            countryCodeTextField.text = ""
        } else if textField == checkFPNField {
            if isValid {
                continueBtn.isUserInteractionEnabled = true
                continueBtn.alpha = 1
            } else {
                continueBtn.isUserInteractionEnabled = false
                continueBtn.alpha = 0.5
            }
        }
    }
}
