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
    
    private let onBoardingDelegate = OnBoardingPresenter()
    var email = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showBtn.isSelected = true
        self.passwordTextField.isSecureTextEntry = true

    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickShow(_ sender: Any) {
        if self.showBtn.isSelected {
            self.showBtn.isSelected = false
            self.passwordTextField.isSecureTextEntry = false
        } else {
            self.showBtn.isSelected = true
            self.passwordTextField.isSecureTextEntry = true
        }
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        self.onBoardingDelegate.loginWithEmailApi(email: self.email, password: passwordTextField.text ?? "") { isSuccess in
            if isSuccess {
                
            } else {
                
            }
        }
    }
    
    @IBAction func onClickForgotPassword(_ sender: Any) {
        Navigate.to.resetPasswordVc(self)
    }
}
