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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDatePicker()
        why21Lbl.highlightBold(["Why?"], size: 15, textColor: Constant.Color.primaryColor)
    }
    
    private func setDatePicker() {
        
        datePickerView.datePickerMode = .date
        datePickerView.preferredDatePickerStyle = .wheels
        ageLbl.text = "Age\(datePickerView.date.age)"
    }
    
    @IBAction func datePickerValueChange(_ sender: Any) {
        ageLbl.text = "Age\(datePickerView.date.age)"
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        let birthdate = "\(datePickerView.date.age) years old \nBorn \(datePickerView.date.string(format: .MMMDDYYYY))"
        Navigate.to.presentConfirmPopUp(self, text1: Constant.String.confirmBirthDate, text2: birthdate, text3: Constant.String.over21Info)
    }
    

}


extension DateOfBirthViewController: ConfirmPopUpDelegate {
    func cancelDetail() {
        
    }
    
    func confirmDetail() {
        Navigate.to.selectGenderVc(self)
    }
    
}
