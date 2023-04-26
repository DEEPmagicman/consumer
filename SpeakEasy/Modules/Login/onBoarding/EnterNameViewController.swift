//
//  EnterNameViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import UIKit

final class EnterNameViewController: UIViewController {

    @IBOutlet private weak var firstNameTextField: UITextField!
    @IBOutlet private weak var lastNameTextField: UITextField!
    @IBOutlet private weak var nikNameTextField: UITextField!
    @IBOutlet private weak var DOBTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var ContinueBtn: UIButton!
    @IBOutlet private weak var firstNameAndLastNameInfo: UILabel!
    
    private let presenter = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstNameAndLastNameInfo.highlightBold(["Why?"], size: 15, textColor: Constant.Color.purpleColor)
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        DOBTextField.delegate = self
        emailTextField.delegate = self
        firstNameTextField.text = UserDefault.shared.user?.firstName
        lastNameTextField.text = UserDefault.shared.user?.lastName
        nikNameTextField.text = UserDefault.shared.user?.nickName
        DOBTextField.text = UserDefault.shared.user?.dateOfBirth
        emailTextField.text = UserDefault.shared.user?.additionalEmail ?? UserDefault.shared.user?.email
        ContinueBtn.isUserInteractionEnabled = false
        ContinueBtn.alpha = 0.5
        textFieldDidChangeSelection(firstNameTextField)
    }
    
    @IBAction private func onClickDOB(_ sender: Any) {
        Navigate.to.presentDateSelectionBottomSheet(self, date: DOBTextField.text?.toDate(withFormat: .YYYYMMDD))
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
        // TODO: add additional email field in API
        presenter.editUserProfileApi(fName: firstNameTextField.text ?? "", lName: lastNameTextField.text ?? "", nickName: nikNameTextField.text ?? "", dob: DOBTextField.text, additionalEmail: emailTextField.text ?? "") { [weak self] isSuccess,errorMsg  in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                UserDefault.shared.user?.firstName = self.firstNameTextField.text ?? ""
                UserDefault.shared.user?.lastName = self.lastNameTextField.text ?? ""
                UserDefault.shared.user?.nickName = self.nikNameTextField.text ?? ""
                UserDefault.shared.user?.dateOfBirth = self.DOBTextField.text ?? ""
                UserDefault.shared.user?.additionalEmail = self.emailTextField.text ?? ""
                Navigate.to.selectGenderVc(self)
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
        if firstNameTextField.text != "" && lastNameTextField.text != "" && DOBTextField.text != "" && emailTextField.text != "" && emailTextField.text?.isValidEmail == true {
            ContinueBtn.isUserInteractionEnabled = true
            ContinueBtn.alpha = 1.0
        } else {
            ContinueBtn.isUserInteractionEnabled = false
            ContinueBtn.alpha = 0.5
        }
    }
}

extension EnterNameViewController: DateSelectionDelegate {
    func selectedDate(date: Date) {
        DOBTextField.text = date.string(format: .YYYYMMDD)
    }
}
