//
//  EnterPhoneNumberViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit
import FlagPhoneNumber

final class EnterPhoneNumberViewController: UIViewController {
    
    @IBOutlet weak var countryCodeTextField: FPNTextField!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var phoneNumTextField: UITextField!
    @IBOutlet weak var bgImg: UIImageView!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var contrySelectionView: UIView!    
    @IBOutlet weak var errorTextLbl: UILabel!

    var isFromLogin = false
    private var onBoardingDelegate = OnBoardingPresenter()
    private var settingDelegate = SettingPresenter()
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
        
        let items = [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.save, target: self, action: nil),
            UIBarButtonItem(title: "Item 1", style: .plain, target: self, action: nil),
            UIBarButtonItem(title: "Item 2", style: .plain, target: self, action: nil)
        ]
        countryCodeTextField.textFieldInputAccessoryView = getCustomTextFieldInputAccessoryView(with: items)
        
        listController.showCountryPhoneCode = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickCountrySelect))
        contrySelectionView.addGestureRecognizer(tap)
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bgImg.isHidden = isFromSettings
    }
    
    private func getCustomTextFieldInputAccessoryView(with items: [UIBarButtonItem]) -> UIToolbar {
        let toolbar: UIToolbar = UIToolbar()
        
        toolbar.barStyle = UIBarStyle.default
        toolbar.items = items
        toolbar.sizeToFit()
        
        return toolbar
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
        if isFromLogin {
            self.onBoardingDelegate.loginWithPhoneApi(phonenum: phoneNum ?? "", code: countryCode) { [weak self] otp, otpRef, isSuccess,errorMsg  in
                guard let self = self else {
                    Loader.hide()
                    return
                }
                if isSuccess {
                    Navigate.to.enterVerificationCodeVc(self, isFromLogin: true, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "")
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
        } else {
            if isFromSettings {
                self.settingDelegate.changePhoneNumberApi(phone: phoneNum ?? "", code: countryCode) { [weak self] otp, otpRef, isSuccess, errMsg in
                    guard let self = self else {
                        Loader.hide()
                        return
                    }
                    if isSuccess {
                        Navigate.to.enterVerificationCodeVc(self, isFromSettings: self.isFromSettings, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "")
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
                self.onBoardingDelegate.signUpWithPhoneApi(phonenum: phoneNum ?? "", code: countryCode) { [weak self] otp, otpRef, isSuccess,errorMsg  in
                    guard let self = self else {
                        Loader.hide()
                        return
                    }
                    if isSuccess {
                        UserDefault.shared.user?.phone = phoneNum ?? ""
                        Navigate.to.enterVerificationCodeVc(self, otp: otp, otpRef: otpRef, phoneNum: self.phoneNumTextField.text ?? "")
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
