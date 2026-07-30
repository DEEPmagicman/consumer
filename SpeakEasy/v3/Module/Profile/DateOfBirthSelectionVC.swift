//
//  DateOfBirthSelectionVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 20/07/26.
//

import UIKit

final class DateOfBirthSelectionVC: UIViewController {

    weak var delegate: DateSelectionDelegate?

    private let backBtn = AppIconButton()
    private let titleLabel = UILabel()
    private let ageNumberContainer = UIView()
    private let ageNumberLabel = UILabel()
    private let ageTextLabel = UILabel()
    private let pickerContainer = UIView()
    private let selectedRowView = UIView()
    private let pickerView = UIPickerView()
    private let saveBtn = PrimaryButton()

    private let calendar = Calendar.current
    private let months = Calendar.current.monthSymbols
    private let minimumYear = 1900
    private let maximumDate = Calendar.current.date(
        byAdding: .year,
        value: -18,
        to: Date()
    ) ?? Date()

    private var years: [Int] {
        let maximumYear = calendar.component(.year, from: maximumDate)
        return Array(minimumYear...maximumYear)
    }

    private var selectedMonth: Int
    private var selectedDay: Int
    private var selectedYear: Int

    init(date: Date?) {
        let latestEligibleDate = Calendar.current.date(
            byAdding: .year,
            value: -18,
            to: Date()
        ) ?? Date()
        let initialDate = min(date ?? latestEligibleDate, latestEligibleDate)
        selectedMonth = Calendar.current.component(.month, from: initialDate)
        selectedDay = Calendar.current.component(.day, from: initialDate)
        selectedYear = Calendar.current.component(.year, from: initialDate)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        let latestEligibleDate = Calendar.current.date(
            byAdding: .year,
            value: -18,
            to: Date()
        ) ?? Date()
        selectedMonth = Calendar.current.component(.month, from: latestEligibleDate)
        selectedDay = Calendar.current.component(.day, from: latestEligibleDate)
        selectedYear = Calendar.current.component(.year, from: latestEligibleDate)
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        selectInitialRows()
        updateAge()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
        hidePickerSelectionIndicator()
    }

    private func setupUI() {
        setupNav()
        setupAgeView()
        setupPicker()
        setupSaveButton()
        setupConstraints()
    }

    private func setupNav() {
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 14
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)

        titleLabel.text = "Your Date of Birth"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 21)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }

    private func setupAgeView() {
        ageNumberContainer.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08)
        ageNumberContainer.layer.cornerRadius = 13
        ageNumberContainer.layer.cornerCurve = .continuous
        ageNumberContainer.clipsToBounds = true
        ageNumberContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ageNumberContainer)

        ageNumberLabel.textColor = AppColor.primaryWhiteColor
        ageNumberLabel.font = Constant.Font.geistRegular(size: 34)
        ageNumberLabel.textAlignment = .center
        ageNumberLabel.adjustsFontSizeToFitWidth = true
        ageNumberLabel.minimumScaleFactor = 0.75
        ageNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        ageNumberContainer.addSubview(ageNumberLabel)

        ageTextLabel.text = "years old"
        ageTextLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.9)
        ageTextLabel.font = Constant.Font.geistRegular(size: 18)
        ageTextLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ageTextLabel)
    }

    private func setupPicker() {
        pickerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerContainer)

        selectedRowView.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08)
        selectedRowView.layer.cornerRadius = 26
        selectedRowView.layer.cornerCurve = .continuous
        selectedRowView.clipsToBounds = true
        selectedRowView.translatesAutoresizingMaskIntoConstraints = false
        pickerContainer.addSubview(selectedRowView)

        pickerView.backgroundColor = .clear
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerContainer.addSubview(pickerView)
    }

    private func setupSaveButton() {
        saveBtn.configure(title: "Save", fontSize: 18, cornerRadius: 16)
        saveBtn.addTarget(self, action: #selector(onClickSave), for: .touchUpInside)
        view.addSubview(saveBtn)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.widthAnchor.constraint(equalToConstant: 40),
            backBtn.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            ageNumberContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 54),
            ageNumberContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -28),
            ageNumberContainer.widthAnchor.constraint(equalToConstant: 60),
            ageNumberContainer.heightAnchor.constraint(equalToConstant: 54),

            ageNumberLabel.leadingAnchor.constraint(equalTo: ageNumberContainer.leadingAnchor, constant: 6),
            ageNumberLabel.trailingAnchor.constraint(equalTo: ageNumberContainer.trailingAnchor, constant: -6),
            ageNumberLabel.centerYAnchor.constraint(equalTo: ageNumberContainer.centerYAnchor),

            ageTextLabel.leadingAnchor.constraint(equalTo: ageNumberContainer.trailingAnchor, constant: 13),
            ageTextLabel.centerYAnchor.constraint(equalTo: ageNumberContainer.centerYAnchor),

            pickerContainer.topAnchor.constraint(equalTo: ageNumberContainer.bottomAnchor, constant: 64),
            pickerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 54),
            pickerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -54),
            pickerContainer.heightAnchor.constraint(equalToConstant: 440),

            selectedRowView.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor, constant: -10),
            selectedRowView.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor, constant: 10),
            selectedRowView.centerYAnchor.constraint(equalTo: pickerContainer.centerYAnchor),
            selectedRowView.heightAnchor.constraint(equalToConstant: 74),

            pickerView.topAnchor.constraint(equalTo: pickerContainer.topAnchor),
            pickerView.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: pickerContainer.bottomAnchor),

            saveBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            saveBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            saveBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            saveBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func selectInitialRows() {
        pickerView.selectRow(selectedMonth - 1, inComponent: 0, animated: false)
        pickerView.selectRow(selectedDay - 1, inComponent: 1, animated: false)

        if let yearIndex = years.firstIndex(of: selectedYear) {
            pickerView.selectRow(yearIndex, inComponent: 2, animated: false)
        }
    }

    private func selectedDate() -> Date {
        let day = min(selectedDay, daysInSelectedMonth())
        var components = DateComponents()
        components.calendar = calendar
        components.year = selectedYear
        components.month = selectedMonth
        components.day = day
        return min(calendar.date(from: components) ?? maximumDate, maximumDate)
    }

    private func daysInSelectedMonth() -> Int {
        var components = DateComponents()
        components.calendar = calendar
        components.year = selectedYear
        components.month = selectedMonth

        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 31
        }

        return range.count
    }

    private func clampUnderageDateIfNeeded() {
        let date = selectedDate()
        guard date == maximumDate else {
            selectedDay = min(selectedDay, daysInSelectedMonth())
            return
        }

        selectedMonth = calendar.component(.month, from: maximumDate)
        selectedDay = calendar.component(.day, from: maximumDate)
        selectedYear = calendar.component(.year, from: maximumDate)
        selectInitialRows()
    }

    private func updateAge() {
        let age = calendar.dateComponents([.year], from: selectedDate(), to: Date()).year ?? 0
        ageNumberLabel.text = "\(max(age, 18))"
    }

    private func reloadPickerAfterSelection() {
        clampUnderageDateIfNeeded()
        pickerView.reloadAllComponents()
        selectInitialRows()
        updateAge()
    }

    private func hidePickerSelectionIndicator() {
        pickerView.subviews.forEach { subview in
            if subview.bounds.height <= 1 {
                subview.backgroundColor = .clear
                subview.alpha = 0
                return
            }

            if isNativeSelectionBackdrop(subview) {
                subview.backgroundColor = .clear
                subview.alpha = 0
            } else {
                clearPickerSubviewBackgrounds(in: subview)
            }
        }
    }

    private func isNativeSelectionBackdrop(_ view: UIView) -> Bool {
        let isWide = view.bounds.width >= pickerView.bounds.width * 0.65
        let isRowHeight = view.bounds.height >= 40 && view.bounds.height <= 100
        let isNearCenter = abs(view.center.y - pickerView.bounds.midY) <= 70
        return isWide && isRowHeight && isNearCenter && !view.containsPickerLabel
    }

    private func clearPickerSubviewBackgrounds(in view: UIView) {
        guard !(view is UILabel) else { return }
        view.backgroundColor = .clear
        view.subviews.forEach { clearPickerSubviewBackgrounds(in: $0) }
    }

    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func onClickSave() {
        AppHaptic.selectionChanged()
        delegate?.selectedDate(date: selectedDate())
        navigationController?.popViewController(animated: true)
    }
}

extension DateOfBirthSelectionVC: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return months.count
        case 1:
            return daysInSelectedMonth()
        default:
            return years.count
        }
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch component {
        case 0:
            return pickerView.bounds.width * 0.48
        case 1:
            return pickerView.bounds.width * 0.17
        default:
            return pickerView.bounds.width * 0.30
        }
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 84
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        AppHaptic.selectionChanged()

        switch component {
        case 0:
            selectedMonth = row + 1
        case 1:
            selectedDay = row + 1
        default:
            selectedYear = years[row]
        }

        reloadPickerAfterSelection()
    }

    func pickerView(
        _ pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusing view: UIView?
    ) -> UIView {
        let label = (view as? PickerColumnLabel) ?? PickerColumnLabel()
        label.textInsets = UIEdgeInsets(
            top: 0,
            left: component == 0 ? 8 : 0,
            bottom: 0,
            right: component == 2 ? 8 : 0
        )
        label.textAlignment = component == 0 ? .left : .center
        label.font = Constant.Font.geistMedium(size: 22)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.82
        label.lineBreakMode = .byClipping

        let isSelected: Bool
        switch component {
        case 0:
            label.text = months[row]
            isSelected = row == selectedMonth - 1
        case 1:
            label.text = "\(row + 1)"
            isSelected = row == selectedDay - 1
        default:
            label.text = "\(years[row])"
            isSelected = years[row] == selectedYear
        }

        label.textColor = AppColor.primaryWhiteColor.withAlphaComponent(isSelected ? 1 : 0.42)
        return label
    }
}

private final class PickerColumnLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}

private extension UIView {
    var containsPickerLabel: Bool {
        if self is PickerColumnLabel || self is UILabel {
            return true
        }

        return subviews.contains { $0.containsPickerLabel }
    }
}
