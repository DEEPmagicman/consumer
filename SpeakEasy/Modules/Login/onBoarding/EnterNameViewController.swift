//
//  EnterNameViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import UIKit

final class EnterNameViewController: UIViewController {

    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var nikNameTextField: UITextField!
    @IBOutlet weak var ContinueBtn: UIButton!
    @IBOutlet weak var firstNameAndLastNameInfo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        firstNameAndLastNameInfo.highlightBold(["Why?"], size: 15, textColor: Constant.Color.primaryColor)
        firstNameTextField.delegate = self
        nikNameTextField.delegate = self
        self.ContinueBtn.isUserInteractionEnabled = false
        self.ContinueBtn.alpha = 0.5
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        let name = "Legal name: \(firstNameTextField.text ?? "") \nNickname: \(nikNameTextField.text ?? "")"
        Navigate.to.presentConfirmPopUp(self,text1: Constant.String.confirmInfo,text2: name,text3: Constant.String.nameNote)
    }

}

extension EnterNameViewController: ConfirmPopUpDelegate {
    func cancelDetail() {
    
    }
    
    func confirmDetail() {
        Navigate.to.connectAccountVc(self)
    }
    
}

extension EnterNameViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if firstNameTextField.text != "" && nikNameTextField.text != "" {
            self.ContinueBtn.isUserInteractionEnabled = true
            self.ContinueBtn.alpha = 1.0
        }else {
            self.ContinueBtn.isUserInteractionEnabled = false
            self.ContinueBtn.alpha = 0.5
        }
    }
}
