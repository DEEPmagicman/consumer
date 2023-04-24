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
    @IBOutlet weak var editEmailLbl: UILabel!
    
    var email = ""
    var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.delegate = self
        self.showBtn.isSelected = true
        self.passwordTextField.isSecureTextEntry = true
        self.showBtn.setTitle("Show", for: .normal)
        
        self.continueBtn.isUserInteractionEnabled = false
        self.continueBtn.alpha = 0.5

    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickShowPassWord(_ sender: Any) {
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
        self.onBoardingDelegate.editUserProfileApi(email: self.email, password: passwordTextField.text ?? "") { isSuccess,errorMsg  in
            if isSuccess {
                UserDefault.shared.user?.email = self.email
                Navigate.to.dateOfBirthVc(self)
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
    
}

extension CreatePasswordViewController: UITextFieldDelegate {
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
