//
//  PersonalInformationViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit
import DropDown

class PersonalInformationViewController: UIViewController {

    @IBOutlet weak var firstName: SkyFloatingLabelTextField!
    @IBOutlet weak var lastName: SkyFloatingLabelTextField!
    @IBOutlet weak var nickName: SkyFloatingLabelTextField!
    @IBOutlet weak var gender: SkyFloatingLabelTextField!
    @IBOutlet weak var genderBtn: UIButton!
    @IBOutlet weak var dateOfBirthLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var phoneNumberLbl: UILabel!
    
    let genderDropDown = DropDown()
    var editInfoDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textFieldSetUP(firstName)
        textFieldSetUP(lastName)
        textFieldSetUP(nickName)
        textFieldSetUP(gender)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firstName.text = UserDefault.shared.user?.firstName ?? "Tamas"
        lastName.text = UserDefault.shared.user?.lastName ?? "An"
        nickName.text = UserDefault.shared.user?.nickName ?? "Tomi"
        gender.text = UserDefault.shared.user?.gender ?? "MALE"
        dateOfBirthLbl.text = UserDefault.shared.user?.dateOfBirth.convertDateFormat(from: .YYYYMMDD, to: .MMMMDDYYYY)
        emailLbl.text = UserDefault.shared.user?.email
        phoneNumberLbl.text = UserDefault.shared.user?.phone
    }

    private func textFieldSetUP(_ textField: SkyFloatingLabelTextField) {
        textField.placeholderFont = Fonts.poppinsRegular(15)
        textField.titleFormatter = { $0 }
    }

    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickSave(_ sender: Any) {
        self.editInfoDelegate.editUserProfileApi(fName: firstName.text ?? "", lName: lastName.text ?? "", nickName: nickName.text ?? "",gender: self.gender.text) { isSuccess,errorMsg  in
            Loader.hide()
            if isSuccess {
                UserDefault.shared.user?.firstName = self.firstName.text ?? ""
                UserDefault.shared.user?.lastName = self.lastName.text ?? ""
                UserDefault.shared.user?.nickName = self.nickName.text ?? ""
                UserDefault.shared.user?.gender = self.gender.text ?? ""
                Navigate.to.back(self)
            } else {
                if errorMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
    
    @IBAction func onClickEmail(_ sender: Any) {
        Navigate.to.loginWithEmailVc(self, isFromSettings: true)
    }
        
    @IBAction func onClickPhoneNumber(_ sender: Any) {
        Navigate.to.enterPhoneNumVc(self, isFromSettings: true)
     }
           
    @IBAction func onClickPassword(_ sender: Any) {
        Navigate.to.resetPasswordVc(self)
    }
    
    @IBAction func onClickGenderDropdown(_ sender: Any) {
        genderSelectionDropDown()
        genderDropDown.show()
    }
    
    private func genderSelectionDropDown() {
        genderDropDown.anchorView = genderBtn
        genderDropDown.bottomOffset = CGPoint(x: genderBtn.bounds.width - 189, y: genderBtn.bounds.height - 6)
        genderDropDown.cellHeight = 37
        genderDropDown.selectionBackgroundColor = .clear
        genderDropDown.selectedTextColor = .white
        genderDropDown.textColor = .white
        genderDropDown.shadowRadius = 2
        genderDropDown.shadowOpacity = 0.7
        genderDropDown.shadowColor = .black
        genderDropDown.backgroundColor = Constant.Color.code2Fcolor
        genderDropDown.textFont = Fonts.poppinsRegular(15)
        genderDropDown.dataSource = Constant.String.genderList
        genderDropDown.width = 200
        genderDropDown.selectionAction = { [weak self] (index, item) in
            self?.gender.text = item
        }
    }
}
