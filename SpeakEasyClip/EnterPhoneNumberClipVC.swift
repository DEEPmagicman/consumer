//
//  EnterPhoneNumberClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 25/01/23.
//

import UIKit
import FlagPhoneNumber

final class EnterPhoneNumberClipVC: UIViewController {
    
    @IBOutlet weak var countryCodeTextField: FPNTextField!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var phoneNumTextField: UITextField!
    @IBOutlet weak var countrySelectionView: UIView!
    @IBOutlet weak var continueBtnBottom: NSLayoutConstraint!
    
    private var checkFPNField = FPNTextField()
    private var countryCode = ""
    private var listController: FPNCountryListViewController = FPNCountryListViewController(style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        countryCodeTextField.textColor = .white
        
        phoneNumTextField.delegate = self
        checkFPNField.delegate = self
        
        countryCodeTextField.delegate = self
        countryCodeTextField.setFlag(countryCode: .IN)
        countryCode = "+91"
        
        listController.setup(repository: countryCodeTextField.countryRepository)
        listController.didSelect = { [weak self] country in
            self?.countryCodeTextField.setFlag(countryCode: country.code)
        }
        
        countryCodeTextField.flagButtonSize = CGSize(width: 44, height: 44)
        countryCodeTextField.flagButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        countryCodeTextField.displayMode = .list
        
        
        let items = [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.save, target: self, action: nil),
            UIBarButtonItem(title: "Item 1", style: .plain, target: self, action: nil),
            UIBarButtonItem(title: "Item 2", style: .plain, target: self, action: nil)
        ]
        countryCodeTextField.textFieldInputAccessoryView = getCustomTextFieldInputAccessoryView(with: items)
        
        listController.showCountryPhoneCode = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickCountrySelect))
        countrySelectionView.addGestureRecognizer(tap)
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        let keyboardSize = (notification.userInfo?  [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardHeight = keyboardSize?.height ?? 336
        if #available(iOS 11.0, *) {
            continueBtnBottom.constant = keyboardHeight - view.safeAreaInsets.bottom + 10
        } else {
            continueBtnBottom.constant = view.safeAreaInsets.bottom + 10
        }
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        continueBtnBottom.constant =  77
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func getCustomTextFieldInputAccessoryView(with items: [UIBarButtonItem]) -> UIToolbar {
        let toolbar: UIToolbar = UIToolbar()
        
        toolbar.barStyle = UIBarStyle.default
        toolbar.items = items
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    @objc private func onClickCountrySelect() {
        fpnDisplayCountryList()
    }
    
    @objc private func dismissCountries() {
        listController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func onClickContinue(_ sender: Any) {
        phoneNumTextField.resignFirstResponder()
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "CheckOutClipVC")) as? CheckOutClipVC {
            vc.phoneNo = phoneNumTextField.text?.replacingOccurrences(of: " ", with: "") ?? ""
            vc.totalTicket = 3
            vc.ticketPrice = 90
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension EnterPhoneNumberClipVC: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        checkFPNField.text = textField.text
        checkFPNField.sendActions(for: .editingChanged)
        phoneNumTextField.delegate = nil
        phoneNumTextField.text = checkFPNField.text
        phoneNumTextField.delegate = self
    }
}

extension EnterPhoneNumberClipVC: FPNTextFieldDelegate {
    
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
