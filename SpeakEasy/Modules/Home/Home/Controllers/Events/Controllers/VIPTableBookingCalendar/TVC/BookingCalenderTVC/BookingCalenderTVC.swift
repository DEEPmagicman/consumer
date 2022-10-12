//
//  BookingCalenderTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/6/22.
//

import UIKit
import FSCalendar

class BookingCalenderTVC: UITableViewCell {

    @IBOutlet weak var calender: FSCalendar!
    
    var selectedDate: Date?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setCalendarUI()
    }
    
}
extension BookingCalenderTVC {
    private func setCalendarUI(){
        self.calender.register(DIYCalendarCell.self, forCellReuseIdentifier: "cell")
        self.calender.appearance.headerDateFormat = "MMMM yyyy"
        self.calender.appearance.headerTitleColor = .white
        self.calender.appearance.headerTitleFont = UIFont.init(name: "Poppins-Medium", size: 19)
        let weekDaysView = WeekDays.instanceFromNib() as! WeekDays
        let calendarWeekdayViewFrame = self.calender.calendarWeekdayView.frame
        weekDaysView.frame = calendarWeekdayViewFrame
        self.calender.calendarWeekdayView.addSubview(weekDaysView)
        
        let todaysDay = Date().dayOfTheWeek()
        
        if todaysDay == "Thursday" || todaysDay == "Friday" || todaysDay == "Saturday" {
            self.selectedDate = Date()
            self.calender.select(Date())
        }
        
        self.calender.dataSource = self
        self.calender.delegate = self
        self.calender.reloadData()
    }
}
//MARK: - FSCalendarDelegate
extension BookingCalenderTVC: FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance {
    func minimumDate(for calendar: FSCalendar) -> Date {
        return Date()
    }
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        let day = date.dayOfTheWeek()
        if day == "Thursday" || day == "Friday" || day == "Saturday" {
            return true
        }
        return false
    }
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        let day = date.dayOfTheWeek()
        if day == "Thursday" || day == "Friday" || day == "Saturday" {
            if date >= Date() || date < calendar.currentPage.endOfMonth() {
                return .white
            }
            else {
                return .lightGray
            }
        }
        return .lightGray
    }
}

extension Date {
    func dayOfTheWeek() -> String? {
        let weekdays = [
            "Sunday",
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday"
        ]

        let calendar: NSCalendar = NSCalendar.current as NSCalendar
        let components: NSDateComponents = calendar.components(.weekday, from: self as Date) as NSDateComponents
        return weekdays[components.weekday - 1]
    }
}
