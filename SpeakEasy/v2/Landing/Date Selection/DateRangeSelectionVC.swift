//
//  DateRangeSelectionVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit
import FSCalendar

final class DateRangeSelectionVC: UIViewController {
    
    @IBOutlet weak var calendarView: CustomCalendar!
    @IBOutlet weak var dateRangeLbl: UILabel!
    @IBOutlet weak var doneBtn: UIButton!
    
    var startDate: Date?
    var endDate: Date?
    weak var dateDelegate: SelectedDateDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calendarView.layer.cornerRadius = 24
        setCalendarUI()
        calendarView.allowsMultipleSelection = true
    }
    
    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
        setCalendarUI()
            DispatchQueue.main.async {
                let today = Constant.venueTodayDate().dateFormatter() ?? Date()
                self.calendarView.setCurrentPage(today, animated: false)
            }
        }
    
    private func setCalendarUI() {
        calendarView.appearance.headerDateFormat = "MMMM yyyy"
        calendarView.appearance.headerTitleColor = .white
        calendarView.appearance.headerTitleFont = UIFont.init(name: "Poppins-Medium", size: 13)
        calendarView.appearance.caseOptions = FSCalendarCaseOptions.weekdayUsesUpperCase
        calendarView.placeholderType = .none
//        calendarView.currentPage = Constant.venueTodayDate().dateFormatter() ?? Date()
        calendarView.appearance.headerMinimumDissolvedAlpha = 0
        calendarView.appearance.todayColor = .clear
        calendarView.appearance.selectionColor = UIColor(red: 0, green: 0.478, blue: 1, alpha: 1)
        calendarView.appearance.weekdayTextColor = UIColor(red: 0.353, green: 0.353, blue: 0.369, alpha: 1)
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.reloadData()
    }
    
    @IBAction func onClickDismiss(_ sender: Any) {
        if endDate == nil && startDate != nil {
            endDate = startDate
        }
        self.dateDelegate?.selectedDateRange(startDate: startDate?.toString(dateFormat: .YYYYMMDD, timeZone: Constant.venueTimeZone) ?? Constant.venueTodayDate(), endDate: endDate?.toString(dateFormat: .YYYYMMDD, timeZone: Constant.venueTimeZone) ?? Constant.venueTodayDate())
        dismiss(animated: true, completion: nil)
    }
}

extension DateRangeSelectionVC: FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance {
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        return UIColor(red: 0, green: 0.478, blue: 1, alpha: 1)
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        if let startDate = startDate, let endDate = endDate {
            if date >= startDate && date <= endDate {
                return .clear
            }
        }
        return nil
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        if startDate == nil {
            startDate = date
            calendar.select(date)
        } else if endDate == nil {
            if date < startDate! {
                endDate = startDate
                startDate = date
            } else {
                endDate = date
            }
            selectDates(from: startDate!, to: endDate!, calendar: calendar)
        } else {
            if date < startDate! {
                startDate = date
            } else {
                endDate = date
            }
            selectDates(from: startDate!, to: endDate!, calendar: calendar)
        }
//        dateRangeLbl.text = startDate == endDate || endDate == nil ? "\(startDate?.toString(dateFormat: .ddMMMyyyy) ?? "")" : "\(startDate?.toString(dateFormat: .ddMMMyyyy) ?? "") - \(endDate?.toString(dateFormat: .ddMMMyyyy) ?? "")"
    }
    
    func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
        for date in calendar.selectedDates {
            calendar.deselect(date)
        }
        if let fromDate = startDate, date < fromDate {
            startDate = date
        } else {
            endDate = date
        }
//        dateRangeLbl.text = startDate == endDate || endDate == nil ? "\(startDate?.toString(dateFormat: .ddMMMyyyy) ?? "")" : "\(startDate?.toString(dateFormat: .ddMMMyyyy) ?? "") - \(endDate?.toString(dateFormat: .ddMMMyyyy) ?? "")"
        selectDates(from: startDate!, to: endDate!, calendar: calendar)
    }
}
extension DateRangeSelectionVC {
    func datesRange(from: Date, to: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = from
        while currentDate <= to {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
    
    func selectDates(from startDate: Date, to endDate: Date, calendar: FSCalendar) {
        for date in datesRange(from: startDate, to: endDate) {
            calendar.select(date)
        }
    }
}

protocol SelectedDateDelegate: AnyObject {
    func selectedDateRange(startDate: String?, endDate: String?)
}

extension SelectedDateDelegate {
    func selectedDateRange(startDate: String?, endDate: String?) { }
}
