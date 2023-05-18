//
//  PersonalInformationViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit
import DropDown

final class PersonalInformationViewController: UIViewController {

    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var nickNameTF: UITextField!
    @IBOutlet weak var genderTF: UITextField!
    @IBOutlet weak var dateOfBirthTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var phoneNumberTF: UITextField!
    @IBOutlet weak var genderBtn: UIButton!
    
    private let genderDropDown = DropDown()
    private var presenter = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firstNameTF.text = UserDefault.shared.user?.firstName
        lastNameTF.text = UserDefault.shared.user?.lastName
        nickNameTF.text = UserDefault.shared.user?.nickName
        genderTF.text = UserDefault.shared.user?.gender.capitalized
        dateOfBirthTF.text = UserDefault.shared.user?.dateOfBirth.convertDateFormat(from: .YYYYMMDD, to: .MMMMDDYYYY, isUTC: false)
        if (UserDefault.shared.user?.email ?? "") == "" {
            emailTF.text =  UserDefault.shared.user?.additionalEmail
        } else {
            emailTF.text = UserDefault.shared.user?.email
        }
        phoneNumberTF.text = UserDefault.shared.user?.phone
    }

    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickSave(_ sender: Any) {
        guard let date = dateOfBirthTF.text?.convertDateFormat(from: .MMMMDDYYYY, to: .YYYYMMDD, isUTC: false) else {
            Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
            return
        }
        presenter.editUserProfileApi(fName: firstNameTF.text ?? "", lName: lastNameTF.text ?? "", nickName: nickNameTF.text ?? "", dob: date, gender: genderTF.text?.uppercased()) { [weak self] isSuccess,errorMsg  in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                UserDefault.shared.user?.firstName = self.firstNameTF.text ?? ""
                UserDefault.shared.user?.lastName = self.lastNameTF.text ?? ""
                UserDefault.shared.user?.nickName = self.nickNameTF.text ?? ""
                UserDefault.shared.user?.dateOfBirth = date
                UserDefault.shared.user?.gender = self.genderTF.text ?? ""
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
    
    @IBAction func onClickDOB(_ sender: Any) {
        Navigate.to.presentDateSelectionBottomSheet(self, date: dateOfBirthTF.text?.toDate(withFormat: .MMMMDDYYYY, isUTC: false))
    }
    
    @IBAction func onClickEmail(_ sender: Any) {
        Navigate.to.loginWithEmailVc(self, isFromSettings: true)
    }
        
    @IBAction func onClickPhoneNumber(_ sender: Any) {
        Navigate.to.enterPhoneNumVc(self, isFromSettings: true)
     }
    
    @IBAction func onClickGenderDropdown(_ sender: Any) {
        genderSelectionDropDown()
        genderDropDown.show()
    }
    
    private func genderSelectionDropDown() {
        genderDropDown.anchorView = genderBtn
        genderDropDown.bottomOffset = CGPoint(x: -8, y: genderBtn.bounds.height + 7)
        genderDropDown.cellHeight = 40
        genderDropDown.selectionBackgroundColor = .clear
        genderDropDown.selectedTextColor = .white
        genderDropDown.textColor = .white
        genderDropDown.shadowRadius = 2
        genderDropDown.shadowOpacity = 0.7
        genderDropDown.shadowColor = .black
        genderDropDown.backgroundColor = Constant.Color.code2Fcolor
        genderDropDown.textFont = Fonts.poppinsRegular(15)
        genderDropDown.dataSource = Constant.String.genderList
        genderDropDown.width = genderBtn.bounds.width + 20
        genderDropDown.cellNib = CustomDropDownCell.nib
        genderDropDown.selectionAction = { [weak self] (index, item) in
            self?.genderTF.text = item
        }
        genderDropDown.customCellConfiguration = {(index: Index, item: String, cell: DropDownCell) in
        guard let cell = cell as? CustomDropDownCell else { return }
            cell.optionLabel.textAlignment = .left
            cell.separatorView.isHidden = index == Constant.String.genderList.count - 1
        }
    }
}

extension PersonalInformationViewController: DateSelectionDelegate {
    func selectedDate(date: Date) {
        dateOfBirthTF.text = date.string(format: .MMMMDDYYYY, isUTC: false)
    }
}
