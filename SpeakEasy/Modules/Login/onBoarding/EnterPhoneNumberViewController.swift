//
//  EnterPhoneNumberViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit
import FlagPhoneNumber

class EnterPhoneNumberViewController: UIViewController {
    
    @IBOutlet weak var countryCodeTextField: FPNTextField!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var phoneNumTextField: UITextField!
    
    private var checkFPNField = FPNTextField()
    var listController: FPNCountryListViewController = FPNCountryListViewController(style: .grouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneNumTextField.delegate = self
        checkFPNField.delegate = self
        
        countryCodeTextField.delegate = self
        countryCodeTextField.setFlag(countryCode: .IN)
        
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
        Navigate.to.enterVerificationCodeVc(self)
    }
}

extension EnterPhoneNumberViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        checkFPNField.text = textField.text
        checkFPNField.sendActions(for: .editingChanged)
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
        }
    }
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        phoneNumTextField.placeholder = countryCodeTextField.placeholder
        countryCodeTextField.placeholder = ""
        countryCodeTextField.text = ""
        if textField == checkFPNField {
            if isValid {
                print("valid")
//                self.continueBtn.isUserInteractionEnabled = true
//                self.continueBtn.alpha = 1
                //      textField.getFormattedPhoneNumber(format: .E164),       // Output "+33600000001"
                //      textField.getFormattedPhoneNumber(format: .International),  // Output "+33 6 00 00 00 01"
                //      textField.getFormattedPhoneNumber(format: .National),       // Output "06 00 00 00 01"
                //      textField.getFormattedPhoneNumber(format: .RFC3966),      // Output "tel:+33-6-00-00-00-01"
                textField.getRawPhoneNumber()                               // Output "600000001"
            } else {
                print("not")
//                self.continueBtn.isUserInteractionEnabled = false
//                self.continueBtn.alpha = 0.5
            }
        }
    }
}
