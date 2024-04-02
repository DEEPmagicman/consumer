//
//  DateSelectionBottomSheet.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/04/23.
//

import UIKit

protocol DateSelectionDelegate: AnyObject {
    func selectedDate(date: Date)
    func checkInStatusChange()
}

extension DateSelectionDelegate {
    func selectedDate(date: Date) {}
    func checkInStatusChange() {}
}

final class DateSelectionBottomSheet: UIViewController {
    
    @IBOutlet weak var datePickerView: UIDatePicker!
    @IBOutlet weak var bottomLbl: UILabel!
    
    weak var delegate: DateSelectionDelegate?
    var date: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        setDatePicker()
    }
    
    private func setDatePicker() {
        datePickerView.datePickerMode = .date
        datePickerView.preferredDatePickerStyle = .wheels
        let maxDate = Date()
        datePickerView.maximumDate = maxDate
        if let date = date {
            datePickerView.date = date
        }
        bottomLbl.text = "Age \(datePickerView.date.age)"
    }
    
    @IBAction func datePickerValueChange(_ sender: Any) {
        bottomLbl.text = "Age \(datePickerView.date.age)"
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        delegate?.selectedDate(date: datePickerView.date)
        dismiss(animated: true)
    }
}
