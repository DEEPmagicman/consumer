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
        Navigate.to.presentLocationUpdatePopup(
            from: self,
            title: "You're updating your preferred location to Chicago?",
            subtitle: "Premium bookings, priority reservations, and high-demand experiences all in one place."
        ) {
            // handle confirm
        }
//        calendarView.selectToday()
//        updateDateLabel()
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
import SwiftUI

enum AppIconType: String {
    case back
    case close
    case seeAll

    var image: UIImage? {
        switch self {
        case .back:   return UIImage(named: "backButtonIcon")
        case .close:  return UIImage(named: "closeMarkIcon")
        case .seeAll: return UIImage(named: "seeAllButtonIcon")
        }
    }

    var buttonSize: CGFloat {
        switch self {
        case .back:   return 50
        case .close:  return 40
        case .seeAll: return 34
        }
    }
}

// MARK: - SwiftUI Glass Button

private struct GlassButtonView: View {
    let iconType: AppIconType
    let iconSize: CGFloat
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                Image(uiImage: iconType.image ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
            }
            .frame(width: iconType.buttonSize, height: iconType.buttonSize)
            .glassEffect(.regular.interactive(), in: .circle)
        } else {
            // Fallback on earlier versions
        }
    }
}

// MARK: - UIKit AppIconButton

@IBDesignable
final class AppIconButton: UIButton {

    @IBInspectable var iconTypeValue: String = AppIconType.back.rawValue {
        didSet { updateGlass() }
    }

    @IBInspectable var iconSize: CGFloat = 12 {
        didSet { updateGlass() }
    }

    private var iconType: AppIconType {
        AppIconType(rawValue: iconTypeValue) ?? .back
    }

    private var widthConstraintRef: NSLayoutConstraint?
    private var heightConstraintRef: NSLayoutConstraint?
    private var hostingController: UIHostingController<GlassButtonView>?

    // MARK: Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupGlass()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        // IB fallback — glass APIs not available at design time
        backgroundColor = .white.withAlphaComponent(0.2)
        layer.cornerRadius = iconType.buttonSize / 2
        clipsToBounds = true
        setButtonSize(iconType.buttonSize)
        setIcon(iconType.image, size: iconSize)
    }

    // MARK: Setup

    private func setupGlass() {
        // Hide the UIButton's own chrome — SwiftUI renders everything
        backgroundColor = .clear
        setImage(nil, for: .normal)
        setTitle(nil, for: .normal)

        setButtonSize(iconType.buttonSize)
        embedGlassView()
    }

    private func embedGlassView() {
        // Remove old hosting controller if re-embedding
        hostingController?.view.removeFromSuperview()

        let glassView = GlassButtonView(
            iconType: iconType,
            iconSize: iconSize
        ) { [weak self] in
            self?.sendActions(for: .touchUpInside)
        }

        let hc = UIHostingController(rootView: glassView)
        hc.view.backgroundColor = .clear
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hc.view.isUserInteractionEnabled = true
        addSubview(hc.view)

        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingController = hc
    }

    private func updateGlass() {
        setButtonSize(iconType.buttonSize)
        embedGlassView()
    }

    // MARK: Size (unchanged from your original)

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

        widthConstraintRef?.constant  = size
        heightConstraintRef?.constant = size
    }

    // MARK: IB fallback helpers (only used in prepareForInterfaceBuilder)

    private func setIcon(_ image: UIImage?, size: CGFloat) {
        guard let image else { setImage(nil, for: .normal); return }
        let resized = resizeImage(image, targetSize: CGSize(width: size, height: size))
        setImage(resized.withRenderingMode(.alwaysOriginal), for: .normal)
        imageView?.contentMode         = .center
        contentHorizontalAlignment     = .center
        contentVerticalAlignment       = .center
        imageEdgeInsets                = .zero
        contentEdgeInsets              = .zero
    }

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: targetSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}



@available(iOS 26.0, *)
private struct LiquidGlassSurface: View {
    let cornerRadius: CGFloat
    let tintColor: Color  // ✅ added
    let fillColor: Color = Color.white.opacity(0.04)

    var body: some View {
        Rectangle()
            .foregroundStyle(fillColor)
            .glassEffect(.regular.interactive(), in: .capsule)
            .cornerRadius(cornerRadius)
    }
}

final class LiquidGlassBackgroundView: UIView {

    var fillColor: UIColor = UIColor(white: 1, alpha: 0.04) { didSet { apply() } }

    private var hostingController: UIHostingController<AnyView>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        apply()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        apply()
    }

    convenience init(
        cornerRadius: CGFloat = 12,
        fillColor: UIColor = UIColor(white: 1, alpha: 0.04),
        borderColor: UIColor? = nil,
        borderWidth: CGFloat = 0.75,
        tintColor: UIColor = .clear  // ✅ added
    ) {
        self.init(frame: .zero)
        self.cornerRadius = cornerRadius
        self.fillColor    = fillColor
        self.borderColor  = borderColor
        self.borderWidth  = borderWidth
        self.tintColor    = tintColor  // ✅ added
        apply()
    }

    private func apply() {
        if #available(iOS 26.0, *) {
            applyGlass()
        } else {
            applyFallback()
        }
    }

    @available(iOS 26.0, *)
    private func applyGlass() {
        hostingController?.view.removeFromSuperview()
        backgroundColor   = .clear  // ✅ was fillColor, glass handles its own bg
        layer.borderWidth = 0

        let surface = LiquidGlassSurface(
            cornerRadius: cornerRadius,
            tintColor: Color(tintColor)
        )
        let hc = UIHostingController(rootView: AnyView(surface))
        hc.view.backgroundColor          = .clear
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hc.view.isUserInteractionEnabled = false
        insertSubview(hc.view, at: 0)

        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingController = hc
    }

    private func applyFallback() {
        hostingController?.view.removeFromSuperview()
        hostingController    = nil
        backgroundColor      = fillColor
        layer.cornerRadius   = cornerRadius
        layer.cornerCurve    = .continuous
        clipsToBounds        = true
        layer.borderColor    = borderColor?.cgColor
        layer.borderWidth    = borderColor != nil ? borderWidth : 0
    }
}


import UIKit

final class LocationUpdatePopupView: UIView {

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "primaryLocationPopupIcon")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = AppColor.primaryWhiteColor
        l.font = Constant.Font.geistRegular(size: 24)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.6)
        l.font = Constant.Font.geistRegular(size: 12)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let confirmButton = PrimaryButton()
    private let cardView = GradientBorderCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)

        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, subtitleLabel, confirmButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(20, after: iconImageView)
        stack.setCustomSpacing(12, after: titleLabel)
        stack.setCustomSpacing(24, after: subtitleLabel)
        cardView.addSubview(stack)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconImageView.widthAnchor.constraint(equalToConstant: 31),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            confirmButton.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            confirmButton.trailingAnchor.constraint(equalTo: stack.trailingAnchor),

            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 32),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24)
        ])
    }

    func configure(
        title: String,
        subtitle: String,
        confirmTitle: String = "Confirm",
        onConfirm: @escaping () -> Void
    ) {
        titleLabel.text    = title
        subtitleLabel.text = subtitle
        confirmButton.configure(title: confirmTitle, cornerRadius: 16)
        confirmButton.addAction(UIAction { _ in onConfirm() }, for: .touchUpInside)
    }
}

final class LocationUpdatePopupViewController: UIViewController {

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = .black.withAlphaComponent(0.6)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let popup = LocationUpdatePopupView()

    var titleText: String = ""
    var subtitleText: String = ""
    var confirmTitle: String = "Confirm"
    var onConfirm: (() -> Void)?

    static func show(
        from presenter: UIViewController,
        title: String,
        subtitle: String,
        confirmTitle: String = "Confirm",
        onConfirm: @escaping () -> Void
    ) {
        let vc = LocationUpdatePopupViewController()
        vc.titleText    = title
        vc.subtitleText = subtitle
        vc.confirmTitle = confirmTitle
        vc.onConfirm    = onConfirm
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle   = .crossDissolve
        presenter.present(vc, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        view.addSubview(dimView)
        view.addSubview(popup)

        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            popup.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            popup.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            popup.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        dimView.addGestureRecognizer(tap)

        popup.configure(
            title: titleText,
            subtitle: subtitleText,
            confirmTitle: confirmTitle
        ) { [weak self] in
            self?.dismiss(animated: true) { self?.onConfirm?() }
        }
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}
