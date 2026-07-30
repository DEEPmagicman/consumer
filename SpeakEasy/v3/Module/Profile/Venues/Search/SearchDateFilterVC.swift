//
//  SearchDateFilterVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 03/06/26.
//

import UIKit

final class SearchDateFilterVC: BaseSearchSheetVC {

    var fromDate: Date?
    var toDate: Date?

    var onApply: ((_ fromDate: Date?, _ toDate: Date?) -> Void)?

    private let applyBtn = UIButton(type: .system)
    private let fromRow = DateRowView(title: "From")
    private let toRow = DateRowView(title: "To")

    private let datePicker = UIDatePicker()
    private var activeRow: DateRowView?

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Search by Date"
        closeBtn.iconTypeValue = AppIconType.close.rawValue
        closeBtn.iconSize = 14
        closeBtn.buttonSize = 40
        closeBtn.iconTintColor = .white

        setupApply()
        setupRows()
        setupPicker()
        reloadDates()
    }

    private func setupApply() {
        applyBtn.setTitle("Apply", for: .normal)
        applyBtn.setTitleColor(.black, for: .normal)
        applyBtn.titleLabel?.font = Constant.Font.geistMedium(size: 12)
        applyBtn.backgroundColor = .white
        applyBtn.layer.cornerRadius = 17
        applyBtn.addTarget(self, action: #selector(onClickApply), for: .touchUpInside)
        applyBtn.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(applyBtn)

        NSLayoutConstraint.activate([
            applyBtn.centerYAnchor.constraint(equalTo: closeBtn.centerYAnchor),
            applyBtn.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -20),
            applyBtn.widthAnchor.constraint(equalToConstant: 68),
            applyBtn.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    private func setupRows() {
        fromRow.addTarget(self, action: #selector(onClickFrom), for: .touchUpInside)
        toRow.addTarget(self, action: #selector(onClickTo), for: .touchUpInside)

        sheetView.addSubview(fromRow)
        sheetView.addSubview(toRow)

        NSLayoutConstraint.activate([
            fromRow.topAnchor.constraint(equalTo: closeBtn.bottomAnchor, constant: 20),
            fromRow.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 20),
            fromRow.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -20),
            fromRow.heightAnchor.constraint(equalToConstant: 74),

            toRow.topAnchor.constraint(equalTo: fromRow.bottomAnchor, constant: 10),
            toRow.leadingAnchor.constraint(equalTo: fromRow.leadingAnchor),
            toRow.trailingAnchor.constraint(equalTo: fromRow.trailingAnchor),
            toRow.heightAnchor.constraint(equalToConstant: 74)
        ])
    }

    private func setupPicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.tintColor = .white
        datePicker.addTarget(self, action: #selector(onDateChanged), for: .valueChanged)
        datePicker.isHidden = true
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(datePicker)

        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: toRow.bottomAnchor, constant: 20),
            datePicker.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 20),
            datePicker.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -20)
        ])
    }

    private func reloadDates() {
        fromRow.value = fromDate?.dateFilterDisplay() ?? "Add Date"
        toRow.value = toDate?.dateFilterDisplay() ?? "Add Date"
    }

    @objc private func onClickFrom() {
        activeRow = fromRow
        datePicker.date = fromDate ?? Date()
        datePicker.isHidden = false
    }

    @objc private func onClickTo() {
        activeRow = toRow
        datePicker.date = toDate ?? Date()
        datePicker.isHidden = false
    }

    @objc private func onDateChanged() {
        if activeRow === fromRow {
            fromDate = datePicker.date
        } else {
            toDate = datePicker.date
        }

        reloadDates()
    }

    @objc private func onClickApply() {
        if let fromDate, let toDate, fromDate > toDate {
            Alert.showAlertSheet(style: .alert, title: "From date cannot be after To date.", message: "")
            return
        }

        dismiss(animated: true) {
            self.onApply?(self.fromDate, self.toDate)
        }
    }
}
