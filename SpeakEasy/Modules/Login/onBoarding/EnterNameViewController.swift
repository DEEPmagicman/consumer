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
    @IBOutlet private weak var DOBTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var ContinueBtn: UIButton!
    @IBOutlet private weak var firstNameAndLastNameInfo: UILabel!
    @IBOutlet weak var femaleBtn: UIButton!
    @IBOutlet weak var maleBtn: UIButton!
    @IBOutlet weak var otherBtn: UIButton!
    
    private let presenter = OnBoardingPresenter()
    var gender = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        DOBTextField.delegate = self
        emailTextField.delegate = self
        firstNameTextField.text = UserDefault.shared.user?.firstName
        lastNameTextField.text = UserDefault.shared.user?.lastName
        DOBTextField.text = UserDefault.shared.user?.dateOfBirth
        if let userGender = UserDefault.shared.user?.gender.capitalized {
            gender = userGender.uppercased()
        }
        maleBtn.setTitleColor(.white, for: .selected)
        femaleBtn.setTitleColor(.white, for: .selected)
        otherBtn.setTitleColor(.white, for: .selected)
        setGenderViewUI()
        continueBtnValidation(isValid: validateFields)
        emailTextField.isUserInteractionEnabled = UserDefault.shared.user?.email ?? "" != "" ? false : true
        emailTextField.alpha = UserDefault.shared.user?.email ?? "" != "" ? 0.7 : 1
        firstNameTextField.isUserInteractionEnabled = UserDefault.shared.user?.firstName ?? "" != "" ? false : true
        firstNameTextField.alpha = UserDefault.shared.user?.firstName ?? "" != "" ? 0.7 : 1
        lastNameTextField.isUserInteractionEnabled = UserDefault.shared.user?.lastName ?? "" != "" ? false : true
        lastNameTextField.alpha = UserDefault.shared.user?.lastName ?? "" != "" ? 0.7 : 1
        
        emailTextField.text = UserDefault.shared.user?.email
        ContinueBtn.isUserInteractionEnabled = false
        ContinueBtn.alpha = 0.5
        textFieldDidChangeSelection(firstNameTextField)
    }
    
    @IBAction private func onClickDOB(_ sender: Any) {
        Navigate.to.presentDateSelectionBottomSheet(self, date: DOBTextField.text?.toDate(withFormat: .YYYYMMDD, isUTC: false))
    }

    @IBAction private func onClickContinue(_ sender: Any) {
        let name = "Legal name: \(firstNameTextField.text ?? "") \(lastNameTextField.text ?? "")"
        Navigate.to.presentConfirmPopUp(self, text1: Constant.String.confirmInfo, text2: name, text3: Constant.String.nameNote)
    }
    
    private func setGenderViewUI() {
        femaleBtn.backgroundColor = .clear
        maleBtn.backgroundColor = .clear
        otherBtn.backgroundColor = .clear
        if femaleBtn.isSelected {
            femaleBtn.backgroundColor = .black
            gender = "FEMALE"
        }
        if maleBtn.isSelected {
            maleBtn.backgroundColor = .black
            gender = "MALE"
        }
        if otherBtn.isSelected {
            otherBtn.backgroundColor = .black
            gender = "OTHER"
        }
        continueBtnValidation(isValid: validateFields)
    }
    
    @IBAction func onClickGenderSelect(_ sender: UIButton) {
        femaleBtn.isSelected = sender.tag == 0 ? true : false
        maleBtn.isSelected = sender.tag == 1 ? true : false
        otherBtn.isSelected = sender.tag == 2 ? true : false
        setGenderViewUI()
    }
    
    private func continueBtnValidation(isValid: Bool) {
        ContinueBtn.isUserInteractionEnabled = isValid ? true : false
        ContinueBtn.alpha = isValid ? 1 : 0.5
    }
    
    private var validateFields: Bool {
        if firstNameTextField.text ?? "" == "" {
            return false
        }
        if lastNameTextField.text ?? "" == "" {
            return false
        }
        if emailTextField.text ?? "" == "" {
            return false
        } else {
            if emailTextField.text?.isValidEmail == false {
                return false
            }
        }
        if !maleBtn.isSelected && !femaleBtn.isSelected && !otherBtn.isSelected {
            return false
        }
        return true
    }
}

extension EnterNameViewController: ConfirmPopUpDelegate {
    func cancelDetail() {
    }
    
    func confirmDetail() {
        presenter.editUserProfileApi(fName: firstNameTextField.text ?? "", lName: lastNameTextField.text ?? "", nickName: "", email: emailTextField.text ?? "", dob: DOBTextField.text, gender: gender) { [weak self] isSuccess,errorMsg  in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                UserDefault.shared.user?.firstName = self.firstNameTextField.text ?? ""
                UserDefault.shared.user?.lastName = self.lastNameTextField.text ?? ""
                UserDefault.shared.user?.dateOfBirth = self.DOBTextField.text ?? ""
                UserDefault.shared.user?.email = self.emailTextField.text ?? ""
                UserDefault.shared.user?.gender = self.gender
                Navigate.to.SetProfilePicVc(self)
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
        continueBtnValidation(isValid: validateFields)
    }
}

extension EnterNameViewController: DateSelectionDelegate {
    func selectedDate(date: Date) {
        DOBTextField.text = date.string(format: .YYYYMMDD, isUTC: false)
        textFieldDidChangeSelection(emailTextField)
    }
}
