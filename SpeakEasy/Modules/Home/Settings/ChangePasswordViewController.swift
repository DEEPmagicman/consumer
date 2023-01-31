//
//  ChangePasswordViewController.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 31/01/23.
//

import UIKit

class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var oldPasswordTextfield: UITextField!
    @IBOutlet weak var newPassTextField: UITextField!
    @IBOutlet weak var confirmPassTextField: UITextField!
    @IBOutlet weak var show1Btn: UIButton!
    @IBOutlet weak var show2Btn: UIButton!
    @IBOutlet weak var show3Btn: UIButton!
    @IBOutlet weak var continueBtn: UIButton!
    
    var settingDelegate = SettingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.oldPasswordTextfield.delegate = self
        self.newPassTextField.delegate = self
        self.confirmPassTextField.delegate = self

        self.show1Btn.isSelected = true
        self.oldPasswordTextfield.isSecureTextEntry = true
        self.show1Btn.setTitle("Show", for: .normal)
        self.show2Btn.isSelected = true
        self.show2Btn.setTitle("Show", for: .normal)
        self.show3Btn.isSelected = true
        self.show3Btn.setTitle("Show", for: .normal)
        self.newPassTextField.isSecureTextEntry = true
        self.confirmPassTextField.isSecureTextEntry = true
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickContinue(_ sender: UIButton) {
        self.settingDelegate.changePasswordApi(oldPass: self.oldPasswordTextfield.text ?? "", newPass: self.newPassTextField.text ?? "", confirmPass: self.confirmPassTextField.text ?? "") { isSuccess, errorMsg in
            if isSuccess {
                self.navigationController?.popViewController(animated: true)
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
    
    @IBAction func onClickShowBtn(_ sender: UIButton) {
        if sender.isSelected {
            sender.isSelected = false
            sender.setTitle("Hide", for: .normal)
            if sender.tag == 1 {
                self.oldPasswordTextfield.isSecureTextEntry = false
            } else if sender.tag == 2 {
                self.newPassTextField.isSecureTextEntry = false
            } else if sender.tag == 3 {
                self.confirmPassTextField.isSecureTextEntry = false
            }
        } else {
            sender.isSelected = true
            sender.setTitle("Show", for: .normal)
            if sender.tag == 1 {
                self.oldPasswordTextfield.isSecureTextEntry = true
            } else if sender.tag == 2 {
                self.newPassTextField.isSecureTextEntry = true
            } else if sender.tag == 3 {
                self.confirmPassTextField.isSecureTextEntry = true
            }
        }
    }
}

extension ChangePasswordViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if self.oldPasswordTextfield.text?.count ?? 0 >= 6 && self.newPassTextField.text?.count ?? 0 >= 6 && self.confirmPassTextField.text?.count ?? 0 >= 6 {
            self.continueBtn.isUserInteractionEnabled = true
            self.continueBtn.alpha = 1
        } else {
            self.continueBtn.isUserInteractionEnabled = false
            self.continueBtn.alpha = 0.5
        }
    }
}
