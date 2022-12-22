//
//  AddEmailViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import UIKit

final class AddEmailViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var radioBtn: UIButton!
    @IBOutlet weak var continueBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.radioBtn.isSelected = false
        emailTextField.delegate = self
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5
    }
    
    @IBAction func onClickRedioBtn(_ sender: Any) {
        if self.radioBtn.isSelected {
            self.radioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
            self.radioBtn.isSelected = false
        } else {
            self.radioBtn.setImage(Constant.Icon.radioClick, for: .normal)
            self.radioBtn.isSelected = true
        }
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        Navigate.to.createPasswordVc(self)
    }
}

extension AddEmailViewController: UITextFieldDelegate {
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
