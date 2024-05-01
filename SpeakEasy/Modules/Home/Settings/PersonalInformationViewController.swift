//
//  PersonalInformationViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit
//import DropDown

final class PersonalInformationViewController: UIViewController {

    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var dateOfBirthTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var phoneNumberTF: UITextField!
    @IBOutlet weak var femaleBtn: UIButton!
    @IBOutlet weak var maleBtn: UIButton!
    @IBOutlet weak var otherBtn: UIButton!
    
    private var presenter = OnBoardingPresenter()
    var gender = ""
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firstNameTF.text = UserDefault.shared.user?.firstName
        lastNameTF.text = UserDefault.shared.user?.lastName
        dateOfBirthTF.text = UserDefault.shared.user?.dateOfBirth ?? "" == "" ? "Select date of birth" : UserDefault.shared.user?.dateOfBirth.convertDateFormat(from: .YYYYMMDD, to: .MMMMDDYYYY, isUTC: false)
        emailTF.text = UserDefault.shared.user?.email
        phoneNumberTF.text = UserDefault.shared.user?.phone
        
        maleBtn.setTitleColor(.white, for: .selected)
        femaleBtn.setTitleColor(.white, for: .selected)
        otherBtn.setTitleColor(.white, for: .selected)
        if let userGender = UserDefault.shared.user?.gender.capitalized, userGender == "Male" {
            maleBtn.isSelected = true
            gender = userGender.uppercased()
        } else {
            femaleBtn.isSelected = UserDefault.shared.user?.gender.capitalized == "Female" ? true : false
            gender = UserDefault.shared.user?.gender.capitalized == "Female" ? "Female".uppercased() : "Male".uppercased()
            otherBtn.isSelected = UserDefault.shared.user?.gender.capitalized == "Other" ? true : false
        }
        setGenderViewUI()
    }

    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickSave(_ sender: Any) {
        var date = dateOfBirthTF.text?.convertDateFormat(from: .MMMMDDYYYY, to: .YYYYMMDD, isUTC: false) ?? ""
        if date == "No date Found" { date = "" }
        presenter.editUserProfileApi(fName: firstNameTF.text ?? "", lName: lastNameTF.text ?? "", nickName: "", dob: date, gender: gender) { [weak self] isSuccess,errorMsg  in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                UserDefault.shared.user?.firstName = self.firstNameTF.text ?? ""
                UserDefault.shared.user?.lastName = self.lastNameTF.text ?? ""
                UserDefault.shared.user?.dateOfBirth = date
                UserDefault.shared.user?.gender = self.gender
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
    
    @IBAction func onClickGenderSelect(_ sender: UIButton) {
        femaleBtn.isSelected = sender.tag == 0 ? true : false
        maleBtn.isSelected = sender.tag == 1 ? true : false
        otherBtn.isSelected = sender.tag == 2 ? true : false
        setGenderViewUI()
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
    }
    
}

extension PersonalInformationViewController: DateSelectionDelegate {
    func selectedDate(date: Date) {
        dateOfBirthTF.text = date.string(format: .MMMMDDYYYY, isUTC: false)
    }
}
