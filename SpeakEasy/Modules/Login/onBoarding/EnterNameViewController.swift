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
    
    var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        firstNameAndLastNameInfo.highlightBold(["Why?"], size: 15, textColor: Constant.Color.purpleColor)
        firstNameTextField.delegate = self
        nikNameTextField.delegate = self
        lastNameTextField.delegate = self
        ContinueBtn.isUserInteractionEnabled = false
        ContinueBtn.alpha = 0.5
    }
    
    @IBAction private func onClickContinue(_ sender: Any) {
        let name = "Legal name: \(firstNameTextField.text ?? "") \(lastNameTextField.text ?? "") \nNickname: \(nikNameTextField.text ?? "")"
        Navigate.to.presentConfirmPopUp(self, text1: Constant.String.confirmInfo, text2: name, text3: Constant.String.nameNote)
    }
}

extension EnterNameViewController: ConfirmPopUpDelegate {
    func cancelDetail() {
    }
    
    func confirmDetail() {
        self.onBoardingDelegate.editUserProfileApi(fName: firstNameTextField.text ?? "", lName: lastNameTextField.text ?? "", nickName: nikNameTextField.text ?? "") { isSuccess,errorMsg  in
            Loader.hide()
            if isSuccess {
                UserDefault.shared.user?.firstName = self.firstNameTextField.text ?? ""
                UserDefault.shared.user?.lastName = self.lastNameTextField.text ?? ""
                UserDefault.shared.user?.nickName = self.nikNameTextField.text ?? ""
                Navigate.to.selectGenderVc(self)
//                Navigate.to.connectAccountVc(self)
            } else {
                if errorMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
}

extension EnterNameViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if firstNameTextField.text != "" && lastNameTextField.text != "" {
            self.ContinueBtn.isUserInteractionEnabled = true
            self.ContinueBtn.alpha = 1.0
        } else {
            self.ContinueBtn.isUserInteractionEnabled = false
            self.ContinueBtn.alpha = 0.5
        }
    }
}
