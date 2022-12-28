//
//  ResetPasswordViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 13/12/22.
//

import UIKit

class ResetPasswordViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var resendLinkBtn: UIButton!
    
    var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        self.resendLinkBtn.isUserInteractionEnabled = false
        self.resendLinkBtn.alpha = 0.5

    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickSendResetLink(_ sender: Any) {
        self.onBoardingDelegate.forgotPasswordApi(email: self.emailTextField.text ?? "") { isSuccess in
            if isSuccess {
                let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                    UIAlertAction in
                    for controller in self.navigationController!.viewControllers{
                        if controller.isKind(of: LoginWithEmailViewController.self) {
                            self.navigationController?.popToViewController(controller, animated: true) }
                    }
                }
                Alert.showAlertSheet(style: .alert, title: "link send successFully", message: "",actions: [okAction])
            } else {
                Alert.showAlertSheet(style: .alert, title: "link not send", message: "")
            }
            Loader.hide()
        }
    }
    
}

extension ResetPasswordViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if self.emailTextField.text?.isValidEmail == true {
            self.resendLinkBtn.isUserInteractionEnabled = true
            self.resendLinkBtn.alpha = 1
        } else {
            self.resendLinkBtn.isUserInteractionEnabled = false
            self.resendLinkBtn.alpha = 0.5
        }
    }
}
