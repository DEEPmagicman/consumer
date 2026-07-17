//
//  CustomCalendar.swift
//  SpeakEasy-Consumer
//

import UIKit
import HorizonCalendar

private enum CalendarUI {
    static let monthFont = AppFont.font(.geist, weight: .regular, size: 18)
    static let weekFont = AppFont.font(.geist, weight: .regular, size: 16)
    static let dayFont = AppFont.font(.geist, weight: .regular, size: 16)

    static let selectedCircleSize: CGFloat = 48
    static let rangeHeight: CGFloat = 40
    static let rangeCornerRadius: CGFloat = 20
}

final class CustomCalendar: UIView {

    // MARK: - Public

    var startDate: Date?
    var endDate: Date?

    var onDateRangeChanged: ((_ startDate: Date?, _ endDate: Date?) -> Void)?

    // MARK: - Private

    private var calendarView: CalendarView?
    private let weekdayStackView = UIStackView()
    
    private lazy var venueCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Constant.venueTimeZone ?? .current
        calendar.firstWeekday = 1
        return calendar
    }()

    private var visibleStartDate: Date {
        let today = venueToday()
        let monthStart = startOfMonth(for: today)
        return monthStart
    }

    private var visibleEndDate: Date {
        let today = venueToday()
        let monthStart = startOfMonth(for: today)
        let futureMonth = venueCalendar.date(byAdding: .month, value: 24, to: monthStart) ?? monthStart
        return endOfMonth(for: futureMonth)
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCalendar()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCalendar()
    }

    // MARK: - Setup

    private func setupCalendar() {
        backgroundColor = .clear

        setupWeekdayRow()

        let view = CalendarView(initialContent: makeContent())
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.daySelectionHandler = { [weak self] day in
            guard let self else { return }
            guard let date = self.venueCalendar.date(from: day.components) else { return }
            self.handleDateSelection(date)
        }

        addSubview(view)
        calendarView = view

        NSLayoutConstraint.activate([
            weekdayStackView.topAnchor.constraint(equalTo: topAnchor),
            weekdayStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            weekdayStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            weekdayStackView.heightAnchor.constraint(equalToConstant: 32),

            view.topAnchor.constraint(equalTo: weekdayStackView.bottomAnchor, constant: 8),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupWeekdayRow() {
        weekdayStackView.axis = .horizontal
        weekdayStackView.distribution = .fillEqually
        weekdayStackView.alignment = .center
        weekdayStackView.spacing = 0
        weekdayStackView.backgroundColor = .clear
        weekdayStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(weekdayStackView)

        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        weekdays.forEach { title in
            let label = UILabel()
            label.text = title
            label.textAlignment = .center
            label.textColor = .white
            label.font = AppFont.font(.geist, weight: .regular, size: 16)
            weekdayStackView.addArrangedSubview(label)
        }
    }
    
    // MARK: - Public Methods

    func reload() {
        calendarView?.setContent(makeContent())
    }

    func setSelectedRange(start: Date?, end: Date?) {
        if let start {
            startDate = max(venueCalendar.startOfDay(for: start), venueToday())
        } else {
            startDate = nil
        }

        if let end {
            endDate = max(venueCalendar.startOfDay(for: end), venueToday())
        } else {
            endDate = nil
        }

        if let startDate, let endDate, startDate > endDate {
            self.endDate = startDate
        }

        onDateRangeChanged?(startDate, endDate)
        reload()
    }

    func scrollToVenueToday(animated: Bool = false) {
        let today = venueToday()

        DispatchQueue.main.async { [weak self] in
            self?.calendarView?.scroll(
                toMonthContaining: today,
                scrollPosition: .centered,
                animated: animated
            )
        }
    }

    func scrollToSelectedOrToday(animated: Bool = false) {
        let targetDate = startDate ?? venueToday()

        DispatchQueue.main.async { [weak self] in
            self?.calendarView?.scroll(
                toMonthContaining: targetDate,
                scrollPosition: .centered,
                animated: animated
            )
        }
    }

    func selectToday() {
        let today = venueToday()
        setSelectedRange(start: today, end: today)
        scrollToSelectedOrToday(animated: true)
    }

    func selectTomorrow() {
        let today = venueToday()
        let tomorrow = venueCalendar.date(byAdding: .day, value: 1, to: today) ?? today

        setSelectedRange(start: tomorrow, end: tomorrow)
        scrollToSelectedOrToday(animated: true)
    }

    func selectThisWeek() {
        let start = venueToday()
        let end = venueCalendar.date(byAdding: .day, value: 6, to: start) ?? start

        setSelectedRange(start: start, end: end)
        scrollToSelectedOrToday(animated: true)
    }

    // MARK: - Content

    private func makeContent() -> CalendarViewContent {
        let selectedStartDate = startDate
        let selectedEndDate = endDate

        var selectedDateRanges = Set<ClosedRange<Date>>()

        if let start = selectedStartDate,
           let end = selectedEndDate,
           !venueCalendar.isDate(start, inSameDayAs: end) {
            selectedDateRanges.insert(start...end)
        }

        return CalendarViewContent(
            calendar: venueCalendar,
            visibleDateRange: visibleStartDate...visibleEndDate,
            monthsLayout: .vertical(options: VerticalMonthsLayoutOptions())
        )
        .interMonthSpacing(32)
        .verticalDayMargin(10)
        .horizontalDayMargin(4)
        .dayOfWeekItemProvider { _, _ in
            EmptyWeekdayItem.calendarItemModel(
                invariantViewProperties: .init(),
                content: .init()
            )
        }
        .monthHeaderItemProvider { [weak self] month in
            let title = self?.monthTitle(month) ?? ""

            return CalendarTextViewRepresentable.calendarItemModel(
                invariantViewProperties: .init(
                    font: CalendarUI.monthFont,
                    textColor: .white,
                    textAlignment: .left
                ),
                content: .init(text: title)
            )
        }
        .dayRangeItemProvider(for: selectedDateRanges) { context in
            CalendarRangeViewRepresentable.calendarItemModel(
                invariantViewProperties: .init(
                    color: UIColor.white.withAlphaComponent(0.28)
                ),
                content: .init(
                    framesOfDaysToHighlight: context.daysAndFrames.map { $0.frame }
                )
            )
        }
        .dayItemProvider { [weak self] day in
            guard let self else {
                return CalendarDayViewRepresentable.calendarItemModel(
                    invariantViewProperties: .init(),
                    content: .init(
                        dayText: "\(day.day)",
                        isSelected: false,
                        isEnabled: false
                    )
                )
            }

            let date = self.venueCalendar.date(from: day.components)
            let isPast = date.map { self.isPastDate($0) } ?? false

            let isStart = self.isSameDay(date, selectedStartDate)
            let isEnd = self.isSameDay(date, selectedEndDate)
            let isSingleSelected = isStart && selectedEndDate == nil
            let isSelected = isStart || isEnd || isSingleSelected

            return CalendarDayViewRepresentable.calendarItemModel(
                invariantViewProperties: .init(),
                content: .init(
                    dayText: "\(day.day)",
                    isSelected: isSelected,
                    isEnabled: !isPast
                )
            )
        }
    }

    // MARK: - Selection Logic

    private func handleDateSelection(_ date: Date) {
        let selectedDate = venueCalendar.startOfDay(for: date)
        guard !isPastDate(selectedDate) else { return }

        if startDate == nil {
            startDate = selectedDate
            endDate = nil
        } else if endDate == nil {
            if selectedDate < startDate! {
                endDate = startDate
                startDate = selectedDate
            } else if venueCalendar.isDate(selectedDate, inSameDayAs: startDate!) {
                endDate = selectedDate
            } else {
                endDate = selectedDate
            }
        } else {
            startDate = selectedDate
            endDate = nil
        }

        onDateRangeChanged?(startDate, endDate)
        reload()
    }

    // MARK: - Helpers

    private func venueToday() -> Date {
        venueCalendar.startOfDay(for: Constant.venueTodayDate().dateFormatter() ?? Date())
    }

    private func isPastDate(_ date: Date) -> Bool {
        venueCalendar.startOfDay(for: date) < venueToday()
    }

    private func startOfMonth(for date: Date) -> Date {
        let components = venueCalendar.dateComponents([.year, .month], from: date)
        return venueCalendar.date(from: components) ?? date
    }

    private func endOfMonth(for date: Date) -> Date {
        let monthStart = startOfMonth(for: date)
        let nextMonth = venueCalendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
        return venueCalendar.date(byAdding: .day, value: -1, to: nextMonth) ?? date
    }

    private func isSameDay(_ lhs: Date?, _ rhs: Date?) -> Bool {
        guard let lhs, let rhs else { return false }
        return venueCalendar.isDate(lhs, inSameDayAs: rhs)
    }

    private func weekdayTitle(index: Int) -> String {
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index]
    }
    
    private func monthTitle(_ month: MonthComponents) -> String {
        let date = venueCalendar.date(
            from: DateComponents(
                calendar: venueCalendar,
                timeZone: venueCalendar.timeZone,
                era: month.era,
                year: month.year,
                month: month.month,
                day: 1
            )
        ) ?? Date()

        let formatter = DateFormatter()
        formatter.calendar = venueCalendar
        formatter.timeZone = venueCalendar.timeZone
        formatter.dateFormat = "MMMM yyyy"

        return formatter.string(from: date)
    }
}

// MARK: - Text Item

struct CalendarTextViewRepresentable: CalendarItemViewRepresentable {

    struct InvariantViewProperties: Hashable {
        let font: UIFont
        let textColor: UIColor
        let textAlignment: NSTextAlignment
    }

    struct Content: Equatable {
        let text: String
    }

    static func makeView(
        withInvariantViewProperties invariantViewProperties: InvariantViewProperties
    ) -> UILabel {
        let label = UILabel()
        label.font = invariantViewProperties.font
        label.textColor = invariantViewProperties.textColor
        label.textAlignment = invariantViewProperties.textAlignment
        label.backgroundColor = .clear
        return label
    }

    static func setContent(_ content: Content, on view: UILabel) {
        view.text = content.text
    }
}

// MARK: - Day Item

struct CalendarWeekdayItem: CalendarItemViewRepresentable {
 
    struct InvariantViewProperties: Hashable {}
 
    struct Content: Equatable {
        let title: String
    }
 
    static func makeView(withInvariantViewProperties _: InvariantViewProperties) -> UILabel {
        let label = UILabel()
        label.font          = CalendarUI.weekFont
        label.textColor     = UIColor(red: 0.353, green: 0.353, blue: 0.369, alpha: 1)
        label.textAlignment = .center
        label.backgroundColor = .clear
        return label
    }
 
    static func setContent(_ content: Content, on view: UILabel) {
        view.text = content.title
    }
}
 
final class CalendarDayCircleView: UIView {

    let circleView = UIView()
    let dayLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        circleView.backgroundColor = .white
        circleView.layer.cornerRadius = CalendarUI.selectedCircleSize / 2
        circleView.clipsToBounds = true
        circleView.isHidden = true

        dayLabel.textAlignment = .center
        dayLabel.font = CalendarUI.dayFont
        dayLabel.textColor = .white

        addSubview(circleView)
        addSubview(dayLabel)

        circleView.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: CalendarUI.selectedCircleSize),
            circleView.heightAnchor.constraint(equalToConstant: CalendarUI.selectedCircleSize),

            dayLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

final class ZeroHeightWeekdayView: UIView {

    override var intrinsicContentSize: CGSize {
        return .zero
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return .zero
    }
}

struct EmptyWeekdayItem: CalendarItemViewRepresentable {

    struct InvariantViewProperties: Hashable { }
    struct Content: Equatable { }

    static func makeView(
        withInvariantViewProperties invariantViewProperties: InvariantViewProperties
    ) -> ZeroHeightWeekdayView {
        let view = ZeroHeightWeekdayView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    static func setContent(_ content: Content, on view: ZeroHeightWeekdayView) { }
}
struct CalendarDayViewRepresentable: CalendarItemViewRepresentable {

    struct InvariantViewProperties: Hashable { }

    struct Content: Equatable {
        let dayText: String
        let isSelected: Bool
        let isEnabled: Bool
    }

    static func makeView(
        withInvariantViewProperties invariantViewProperties: InvariantViewProperties
    ) -> CalendarDayCircleView {
        CalendarDayCircleView()
    }

    static func setContent(_ content: Content, on view: CalendarDayCircleView) {
        view.dayLabel.text = content.dayText
        view.dayLabel.font = CalendarUI.dayFont
        view.circleView.isHidden = !content.isSelected
        if content.isSelected {
            view.dayLabel.textColor = .black
        } else {
            view.dayLabel.textColor = content.isEnabled
                ? .white
                : UIColor.white.withAlphaComponent(0.28)
        }
    }
}

// MARK: - Range Item

final class CalendarRangeIndicatorView: UIView {

    var color: UIColor = .clear

    var framesOfDaysToHighlight: [CGRect] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    override func draw(_ rect: CGRect) {
        guard !framesOfDaysToHighlight.isEmpty else { return }

        color.setFill()

        var dayRowFrames = [CGRect]()
        var currentMinY: CGFloat?

        for dayFrame in framesOfDaysToHighlight {
            if dayFrame.minY != currentMinY {
                currentMinY = dayFrame.minY
                dayRowFrames.append(dayFrame)
            } else {
                let lastIndex = dayRowFrames.count - 1
                dayRowFrames[lastIndex] = dayRowFrames[lastIndex].union(dayFrame)
            }
        }

        for rowFrame in dayRowFrames {
            let roundedRect = CGRect(
                x: rowFrame.minX,
                y: rowFrame.midY - (CalendarUI.rangeHeight / 2),
                width: rowFrame.width,
                height: CalendarUI.rangeHeight
            )

            let path = UIBezierPath(
                roundedRect: roundedRect,
                cornerRadius: CalendarUI.rangeCornerRadius
            )

            path.fill()
        }
    }
}

struct CalendarRangeViewRepresentable: CalendarItemViewRepresentable {

    struct InvariantViewProperties: Hashable {
        let color: UIColor
    }

    struct Content: Equatable {
        let framesOfDaysToHighlight: [CGRect]
    }

    static func makeView(
        withInvariantViewProperties invariantViewProperties: InvariantViewProperties
    ) -> CalendarRangeIndicatorView {
        let view = CalendarRangeIndicatorView()
        view.color = invariantViewProperties.color
        return view
    }

    static func setContent(_ content: Content, on view: CalendarRangeIndicatorView) {
        view.framesOfDaysToHighlight = content.framesOfDaysToHighlight
    }
}
