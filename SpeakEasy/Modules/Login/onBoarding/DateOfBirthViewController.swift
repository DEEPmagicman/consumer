//
//  DateOfBirthViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/12/22.
//

import UIKit

final class DateOfBirthViewController: UIViewController {

    @IBOutlet weak var why21Lbl: UILabel!
    @IBOutlet weak var datePickerView: UIDatePicker!
    @IBOutlet weak var ageLbl: UILabel!
    @IBOutlet weak var continueBtn: UIButton!
    
    var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDatePicker()
//        why21Lbl.highlightBold(["Why?"], size: 15, textColor: Constant.Color.primaryColor)
    }
    
    private func setDatePicker() {
        datePickerView.datePickerMode = .date
        datePickerView.preferredDatePickerStyle = .wheels
        let maxDate = Calendar.current.date(byAdding: .year, value: -21, to: Date())
        datePickerView.maximumDate = maxDate
        ageLbl.text = "Age \(datePickerView.date.age)"
    }
    
    @IBAction func datePickerValueChange(_ sender: Any) {
        ageLbl.text = "Age \(datePickerView.date.age)"
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        let birthdate = "\(datePickerView.date.age) years old \nBorn \(datePickerView.date.string())"
        let dob = datePickerView.date.string(format: .YYYYMMDD)
        self.onBoardingDelegate.editUserProfileApi(dob: dob) { [weak self] isSuccess, errorMsg  in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                UserDefault.shared.user?.dateOfBirth = dob
                Navigate.to.SetProfilePicVc(self)
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
