//
//  CreatePasswordViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/12/22.
//

import UIKit

final class CreatePasswordViewController: UIViewController {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var showBtn: UIButton!
    @IBOutlet weak var continueBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showBtn.isSelected = true
        self.passwordTextField.isSecureTextEntry = true

    }
    
    @IBAction func onClickShowPassWord(_ sender: Any) {
        if self.showBtn.isSelected {
            self.showBtn.isSelected = false
            self.passwordTextField.isSecureTextEntry = false
        } else {
            self.showBtn.isSelected = true
            self.passwordTextField.isSecureTextEntry = true
        }
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        Navigate.to.dateOfBirthVc(self)
    }
    
}
