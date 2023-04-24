//
//  EnterEmailPassViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 13/12/22.
//

import UIKit

class EnterEmailPassViewController: UIViewController {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var showBtn: UIButton!
    @IBOutlet weak var continueBtn: UIButton!
    
    private let onBoardingDelegate = OnBoardingPresenter()
    var email = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showBtn.isSelected = true
        self.passwordTextField.isSecureTextEntry = true
        self.showBtn.setTitle("Show", for: .normal)
        self.passwordTextField.delegate = self
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5

    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickShow(_ sender: Any) {
        if self.showBtn.isSelected {
            self.showBtn.isSelected = false
            self.passwordTextField.isSecureTextEntry = false
            self.showBtn.setTitle("Hide", for: .normal)
        } else {
            self.showBtn.isSelected = true
            self.passwordTextField.isSecureTextEntry = true
            self.showBtn.setTitle("Show", for: .normal)
        }
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        self.onBoardingDelegate.loginWithEmailApi(email: self.email, password: passwordTextField.text ?? "") { isSuccess,errorMsg  in
            if isSuccess {
                AppDelegate.shared.changeRootViewController()
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
    
    @IBAction func onClickForgotPassword(_ sender: Any) {
        Navigate.to.resetPasswordVc(self)
    }
}

extension EnterEmailPassViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if passwordTextField.text?.count ?? 0 >= 6 {
            self.continueBtn.isUserInteractionEnabled = true
            self.continueBtn.alpha = 1.0
        } else {
            self.continueBtn.isUserInteractionEnabled = false
            self.continueBtn.alpha = 0.5
        }
    }
}

