//
//  DateRangeSelectionVC.swift
//  SpeakEasy-Consumer
//

//
//  DateRangeSelectionVC.swift
//  SpeakEasy-Consumer
//

import UIKit

final class DateRangeSelectionVC: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var calendarView: CustomCalendar!
    @IBOutlet weak var todayBtnWidth:    NSLayoutConstraint!
    @IBOutlet weak var tomorrowBtnWidth: NSLayoutConstraint!
    @IBOutlet weak var thisWeekBtnWidth: NSLayoutConstraint!
    @IBOutlet weak var bgView: UIView!
    // MARK: - Public

    var initialStartDate: Date?
    var initialEndDate:   Date?
    weak var dateDelegate: SelectedDateDelegate?

    // MARK: - Private

    private var startDate: Date?
    private var endDate:   Date?
    private var didScrollInitially = false

    private var venueCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone   = Constant.venueTimeZone ?? .current
        c.firstWeekday = 1
        return c
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCalendar()
        applyInitialSelection()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didScrollInitially else { return }
        didScrollInitially = true
        DispatchQueue.main.async { [weak self] in
            self?.calendarView.scrollToSelectedOrToday(animated: false)
        }
        updateButtonWidths()
        self.bgView.applyScreenBgGradient(direction: .bottomToTop)
    }

    // MARK: - Setup

    private func setupCalendar() {
        calendarView.backgroundColor = .clear
        calendarView.onDateRangeChanged = { [weak self] startDate, endDate in
            guard let self else { return }
            self.startDate = startDate
            self.endDate   = endDate
        }
    }

    private func applyInitialSelection() {
        if let s = initialStartDate {
            startDate = s
            endDate   = initialEndDate
            calendarView.setSelectedRange(start: s, end: initialEndDate)
        }
    }

    private func updateButtonWidths() {
        let sidePadding: CGFloat  = 20
        let spacing: CGFloat      = 8
        let buttonCount: CGFloat  = 3
        let totalSpacing          = sidePadding * 2 + spacing * (buttonCount - 1)
        let buttonWidth           = (view.bounds.width - totalSpacing) / buttonCount

        todayBtnWidth.constant    = buttonWidth
        tomorrowBtnWidth.constant = buttonWidth
        thisWeekBtnWidth.constant = buttonWidth
        view.layoutIfNeeded()
    }

    // MARK: - Core apply logic (shared by both Apply and Dismiss)

    /// Sends the selected range to the delegate and dismisses the sheet.
    /// Called from both the Apply button and the plain dismiss/close button.
    private func applyAndDismiss() {
        let today = venueCalendar.startOfDay(for: Constant.venueTodayDate().dateFormatter() ?? Date())
        let selectedStart = startDate.map { venueCalendar.startOfDay(for: $0) }
        let selectedEnd = (endDate ?? startDate).map { venueCalendar.startOfDay(for: $0) }

        let finalStart = selectedStart.map { max($0, today) }
        let normalizedEnd = selectedEnd.map { max($0, today) }
        let finalEnd: Date?
        if let finalStart, let normalizedEnd, normalizedEnd < finalStart {
            finalEnd = finalStart
        } else {
            finalEnd = normalizedEnd
        }

        let tz = Constant.venueTimeZone

        let startString = finalStart?.toString(
            dateFormat: .YYYYMMDD,
            timeZone: tz
        ) ?? Constant.venueTodayDate()

        let endString = finalEnd?.toString(
            dateFormat: .YYYYMMDD,
            timeZone: tz
        ) ?? Constant.venueTodayDate()

        dateDelegate?.selectedDateRange(startDate: startString, endDate: endString)
        dismiss(animated: true)
    }

    @IBAction func onClickApplyBtn(_ sender: Any) {
        AppHaptic.success()
        applyAndDismiss()
    }

    @IBAction func onClickClose(_ sender: Any) {
        AppHaptic.navigation()
        dismiss(animated: true)
    }

    @IBAction func onClickDismiss(_ sender: Any) {
        AppHaptic.success()
        applyAndDismiss()
    }

    @IBAction func onTapToday(_ sender: Any) {
        AppHaptic.selectionChanged()
        calendarView.selectToday()
    }

    @IBAction func onTapTomorrow(_ sender: Any) {
        AppHaptic.selectionChanged()
        calendarView.selectTomorrow()
    }

    @IBAction func onTapThisWeek(_ sender: Any) {
        AppHaptic.selectionChanged()
        calendarView.selectThisWeek()
    }
}

// MARK: - SelectedDateDelegate

protocol SelectedDateDelegate: AnyObject {
    func selectedDateRange(startDate: String?, endDate: String?)
}

extension SelectedDateDelegate {
    func selectedDateRange(startDate: String?, endDate: String?) { }
}
