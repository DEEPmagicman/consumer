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
    
    var isFromLogin = false
    private var onBoardingDelegate = OnBoardingPresenter()
    var contryCode = ""
    var isFromSettings = false
    
    private var checkFPNField = FPNTextField()
    var listController: FPNCountryListViewController = FPNCountryListViewController(style: .grouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneNumTextField.delegate = self
        checkFPNField.delegate = self
        
        countryCodeTextField.delegate = self
        countryCodeTextField.setFlag(countryCode: .IN)
        self.contryCode = "+91"
        
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
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFromSettings {
            bgImg.isHidden = true
            backBtn.setImage(UIImage(named: "ic-close"), for: .normal)
        } else {
            bgImg.isHidden = false
            backBtn.setImage(UIImage(named: "BackArrow"), for: .normal)
        }
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
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
            let phoneNum = phoneNumTextField.text?.replacingOccurrences(of: " ", with: "")
        if isFromLogin {
            self.onBoardingDelegate.loginWithPhoneApi(phonenum: phoneNum ?? "", code: self.contryCode) { otp, otpRef, isSuccess,errorMsg  in
                if isSuccess {
                    Navigate.to.enterVerificationCodeVc(self,isFromLogin: true, otp: otp, otpRef: otpRef,phoneNum: self.phoneNumTextField.text ?? "")
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
                Navigate.to.enterVerificationCodeVc(self, isFromSettings: isFromSettings,phoneNum: self.phoneNumTextField.text ?? "")
            } else {
                self.onBoardingDelegate.signUpWithPhoneApi(phonenum: phoneNum ?? "", code: self.contryCode) { otp, otpRef, isSuccess,errorMsg  in
                    if isSuccess {
                        UserDefault.shared.user?.phone = phoneNum ?? ""
                        Navigate.to.enterVerificationCodeVc(self, otp: otp, otpRef: otpRef,phoneNum: self.phoneNumTextField.text ?? "")
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
            self.contryCode = dialCode
        }
    }
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        if textField == countryCodeTextField {
            phoneNumTextField.placeholder = countryCodeTextField.placeholder
            countryCodeTextField.placeholder = ""
            countryCodeTextField.text = ""
        } else if textField == checkFPNField {
            if isValid {
                print("valid")
                self.continueBtn.isUserInteractionEnabled = true
                self.continueBtn.alpha = 1
                //      textField.getFormattedPhoneNumber(format: .E164),       // Output "+33600000001"
                //      textField.getFormattedPhoneNumber(format: .International),  // Output "+33 6 00 00 00 01"
                //      textField.getFormattedPhoneNumber(format: .National),       // Output "06 00 00 00 01"
                //      textField.getFormattedPhoneNumber(format: .RFC3966),      // Output "tel:+33-6-00-00-00-01"
                textField.getRawPhoneNumber()                               // Output "600000001"
            } else {
                print("not")
                self.continueBtn.isUserInteractionEnabled = false
                self.continueBtn.alpha = 0.5
            }
        }
    }
}
