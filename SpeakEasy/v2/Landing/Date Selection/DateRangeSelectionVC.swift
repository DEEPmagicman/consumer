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
    @IBOutlet weak var dateRangeLbl: UILabel?
    @IBOutlet weak var todayBtnWidth:    NSLayoutConstraint!
    @IBOutlet weak var tomorrowBtnWidth: NSLayoutConstraint!
    @IBOutlet weak var thisWeekBtnWidth: NSLayoutConstraint!

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
    }

    // MARK: - Setup

    private func setupCalendar() {
        calendarView.backgroundColor = .clear
        calendarView.onDateRangeChanged = { [weak self] startDate, endDate in
            guard let self else { return }
            self.startDate = startDate
            self.endDate   = endDate
            self.updateDateLabel()
        }
    }

    private func applyInitialSelection() {
        if let s = initialStartDate {
            startDate = s
            endDate   = initialEndDate
            calendarView.setSelectedRange(start: s, end: initialEndDate)
        }
        updateDateLabel()
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
        let finalStart = startDate
        let finalEnd   = endDate ?? startDate   // single-day tap → start == end

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
        applyAndDismiss()
    }

    @IBAction func onClickClose(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func onClickDismiss(_ sender: Any) {
        applyAndDismiss()
    }

    @IBAction func onTapToday(_ sender: Any) {
        calendarView.selectToday()
        updateDateLabel()
    }

    @IBAction func onTapTomorrow(_ sender: Any) {
        calendarView.selectTomorrow()
        updateDateLabel()
    }

    @IBAction func onTapThisWeek(_ sender: Any) {
        calendarView.selectThisWeek()
        updateDateLabel()
    }

    // MARK: - Label

    private func updateDateLabel() {
        guard let label = dateRangeLbl else { return }

        guard let s = startDate else {
            label.text = nil
            return
        }

        let fmt        = DateFormatter()
        fmt.calendar   = venueCalendar
        fmt.timeZone   = Constant.venueTimeZone ?? .current
        fmt.dateFormat = "MMM d"

        if let e = endDate, !venueCalendar.isDate(s, inSameDayAs: e) {
            label.text = "\(fmt.string(from: s)) - \(fmt.string(from: e))"
        } else {
            label.text = fmt.string(from: s)
        }
    }
}

// MARK: - SelectedDateDelegate

protocol SelectedDateDelegate: AnyObject {
    func selectedDateRange(startDate: String?, endDate: String?)
}

extension SelectedDateDelegate {
    func selectedDateRange(startDate: String?, endDate: String?) { }
}


import UIKit

enum AppIconType: String {
    case back
    case close
    case seeAll

    var image: UIImage? {
        switch self {
        case .back:
            return UIImage(named: "backButtonIcon")
        case .close:
            return UIImage(named: "closeMarkIcon")
        case .seeAll:
            return UIImage(named: "seeAllButtonIcon")
        }
    }

    var buttonSize: CGFloat {
        switch self {
        case .back:
            return 50
        case .close:
            return 40
        case .seeAll:
            return 34
        }
    }
}

@IBDesignable
final class AppIconButton: UIButton {

    @IBInspectable var iconTypeValue: String = AppIconType.back.rawValue {
        didSet {
            applyStyle()
        }
    }

    @IBInspectable var iconSize: CGFloat = 12 {
        didSet {
            applyStyle()
        }
    }

    private var iconType: AppIconType {
        AppIconType(rawValue: iconTypeValue) ?? .back
    }

    private var widthConstraintRef: NSLayoutConstraint?
    private var heightConstraintRef: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyle()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        applyStyle()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    private func applyStyle() {
        backgroundColor = AppColor.buttonBackGroundColor
        tintColor = AppColor.primaryWhiteColor
        clipsToBounds = true

        setButtonSize(iconType.buttonSize)
        setIcon(iconType.image, size: iconSize)
    }

    private func setButtonSize(_ size: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false

        if widthConstraintRef == nil {
            widthConstraintRef = widthAnchor.constraint(equalToConstant: size)
            widthConstraintRef?.isActive = true
        }

        if heightConstraintRef == nil {
            heightConstraintRef = heightAnchor.constraint(equalToConstant: size)
            heightConstraintRef?.isActive = true
        }

        widthConstraintRef?.constant = size
        heightConstraintRef?.constant = size
    }

    private func setIcon(_ image: UIImage?, size: CGFloat) {
        guard let image else {
            setImage(nil, for: .normal)
            return
        }

        let resizedImage = resizeImage(image, targetSize: CGSize(width: size, height: size))
        setImage(resizedImage.withRenderingMode(.alwaysOriginal), for: .normal)

        imageView?.contentMode = .center
        contentHorizontalAlignment = .center
        contentVerticalAlignment = .center
        imageEdgeInsets = .zero
        contentEdgeInsets = .zero
    }

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
