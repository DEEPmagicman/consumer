//
//  DateSelectionBottomSheet.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/04/23.
//

import UIKit

protocol DateSelectionDelegate: AnyObject {
    func selectedDate(date: Date)
}

final class DateSelectionBottomSheet: UIViewController {
    
    @IBOutlet weak var datePickerView: UIDatePicker!
    @IBOutlet weak var bottomLbl: UILabel!
    
    weak var delegate: DateSelectionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setDatePicker()
    }
    
    private func setDatePicker() {
        datePickerView.datePickerMode = .date
        datePickerView.preferredDatePickerStyle = .wheels
        let maxDate = Calendar.current.date(byAdding: .year, value: -21, to: Date())
        datePickerView.maximumDate = maxDate
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
