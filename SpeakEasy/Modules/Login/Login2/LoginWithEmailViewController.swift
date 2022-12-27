//
//  LoginWithEmailViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 13/12/22.
//

import UIKit

class LoginWithEmailViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var bgImg: UIImageView!
    @IBOutlet weak var emailTopTitle: UILabel!
    @IBOutlet weak var backBtn: UIButton!
    
    var isFromSettings = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isFromSettings {
            emailTopTitle.text = "Update Email"
            backBtn.setImage(UIImage(named: "ic-close"), for: .normal)
        } else {
            emailTopTitle.text = "Enter your email"
            backBtn.setImage(UIImage(named: "BackArrow"), for: .normal)
        }
        
        bgImg.isHidden = isFromSettings
    }

    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        if isFromSettings {
            Navigate.to.enterVerificationCodeVc(self, isFromSettings: true, isForEmail: true)
        } else {
            Navigate.to.enterEmailPassVc(self,email: emailTextField.text ?? "")
        }
    }
    
}

extension LoginWithEmailViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if emailTextField.text?.isValidEmail == true {
            self.continueBtn.isUserInteractionEnabled = true
            self.continueBtn.alpha = 1.0
        } else {
            self.continueBtn.isUserInteractionEnabled = false
            self.continueBtn.alpha = 0.5
        }
    }
}
