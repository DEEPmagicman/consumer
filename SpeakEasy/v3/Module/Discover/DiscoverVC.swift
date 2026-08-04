//
//  DiscoverVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 22/12/25.
//

import UIKit
import Combine

final class DiscoverVC: UIViewController {

    private enum Layout {
        static let discoverHeaderContentInset: CGFloat = 100
        static let cityChipMinWidth: CGFloat = 76
        static let cityChipMaxWidth: CGFloat = 220
        static let dateChipMinWidth: CGFloat = 88
        static let dateChipMaxWidth: CGFloat = 240
        static let chipHorizontalPadding: CGFloat = 12
        static let chipIconWidth: CGFloat = 12
        static let chipIconSpacing: CGFloat = 6
        static let cityIconSpacing: CGFloat = 4
        static let cityCloseWidth: CGFloat = 20
        static let dateCloseSpacing: CGFloat = 6
    }

    @IBOutlet var segmentViewContainer: [UIView]!
    @IBOutlet var dateLbl: UILabel!
    @IBOutlet var dateView: LiquidGlassBackgroundView!
    @IBOutlet private weak var filtersScrollView: UIScrollView!
    @IBOutlet private weak var segmentTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectedLocationName: UILabel!
    @IBOutlet var bgView: UIView!
    @IBOutlet weak var calendarIcon: UIImageView!
    @IBOutlet weak var cityClosebtn: UIButton!

    private weak var cityChipView: UIView?
    private weak var cityCloseContainer: UIView?
    private var cityCloseContainerConstraints = [NSLayoutConstraint]()
    private var cityLabelTrailingConstraint: NSLayoutConstraint?
    private var cityChipWidthConstraint: NSLayoutConstraint?
    private var dateChipWidthConstraint: NSLayoutConstraint?
    private var dateLabelDefaultTrailingConstraints = [NSLayoutConstraint]()
    private let dateCloseButton = UIButton(type: .system)
    private var viewControllers = [UIViewController]()
    private var cancellables = Set<AnyCancellable>()
    var startDate: String?
    var endDate: String?
    private var venueCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Constant.venueTimeZone ?? .current
        return calendar
    }
    private var shimmerDidFinish = false
    private var filterCity: String?
    private var appliedGradientBounds: CGRect = .zero
    private var didApplyInitialHeaderOffset = false
    private var activeScrollableHeader: DiscoverHeaderScrollable?
    private weak var activeHeaderScrollView: UIScrollView?

    private let shimmerView = HomeSkeletonView()

    private var isDateSelected: Bool = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateDateSelectionUI()
            }
        }
    }

    private let landingHeaderView = LandingHeaderView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        filterCity = normalizedFilterCity(UserDefault.shared.filterCity)
        UserDefault.shared.filterCity = filterCity
        setupLandingHeader()
        setupScrollableHeader()
        setupCityChipLayout()
        setupDateChipLayout()
        setupSkeletonView()
        showSkeletonScreen()

        showSegmentView(0)
        bindSelectedCity()
        refreshDateChipLayout()
        view.backgroundColor = .black
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if appliedGradientBounds != view.bounds {
            appliedGradientBounds = view.bounds
            view.applyScreenBgGradient()
        }
        if !shimmerDidFinish,
           !shimmerView.isHidden {
            shimmerView.startShimmer()
        }
        configureActiveScrollableHeader()
    }

    private func setupLandingHeader() {
        landingHeaderView.setMapHidden(false)
        landingHeaderView.setCalendarHidden(false)
        landingHeaderView.setCalendarSelected(false)
        landingHeaderView.onCalendarTap = { [weak self] in
            self?.presentDateRangeSelection()
        }
        landingHeaderView.translatesAutoresizingMaskIntoConstraints = false
        landingHeaderView.isHidden = true
        view.addSubview(landingHeaderView)

        NSLayoutConstraint.activate([
            landingHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            landingHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            landingHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            landingHeaderView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupScrollableHeader() {
        filtersScrollView.clipsToBounds = false
        filtersScrollView.showsVerticalScrollIndicator = false
        segmentTopConstraint.constant -= Layout.discoverHeaderContentInset
    }

    private func setupCityChipLayout() {
        guard let chipView = selectedLocationName.superview else { return }

        cityChipView = chipView
        cityCloseContainer = cityClosebtn.superview

        if let cityCloseContainer {
            cityCloseContainerConstraints = chipView.constraints.filter {
                ($0.firstItem as? UIView) === cityCloseContainer
                || ($0.secondItem as? UIView) === cityCloseContainer
            }
        }

        let trailingConstraint = selectedLocationName.trailingAnchor.constraint(
            equalTo: chipView.trailingAnchor,
            constant: -12
        )
        trailingConstraint.isActive = false
        cityLabelTrailingConstraint = trailingConstraint

        let widthConstraint = chipView.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.priority = .required
        widthConstraint.isActive = true
        cityChipWidthConstraint = widthConstraint
    }

    private func setupDateChipLayout() {
        dateView.isHidden = true
        calendarIcon.image = UIImage(named: "discoverCaledarIcon") ?? UIImage(named: "calendarIcon")
        calendarIcon.tintColor = .white
        configureDateCloseButton()
        dateLbl.setContentHuggingPriority(.required, for: .horizontal)
        dateLbl.setContentCompressionResistancePriority(.required, for: .horizontal)

        let widthConstraint = dateView.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.priority = .required
        widthConstraint.isActive = true
        dateChipWidthConstraint = widthConstraint
    }

    private func configureDateCloseButton() {
        guard let contentView = dateLbl.superview,
              dateCloseButton.superview == nil else {
            return
        }

        dateLabelDefaultTrailingConstraints = contentView.constraints.filter {
            ($0.secondItem as? UIView) === dateLbl
            && $0.firstAttribute == .trailing
            && $0.secondAttribute == .trailing
        }
        dateLabelDefaultTrailingConstraints.forEach {
            $0.isActive = false
        }

        dateCloseButton.setImage(UIImage(named: "closeIcon"), for: .normal)
        dateCloseButton.tintColor = .white
        dateCloseButton.backgroundColor = .clear
        dateCloseButton.translatesAutoresizingMaskIntoConstraints = false
        dateCloseButton.addTarget(
            self,
            action: #selector(onClickDateCross(_:)),
            for: .touchUpInside
        )
        contentView.addSubview(dateCloseButton)

        NSLayoutConstraint.activate([
            dateCloseButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            dateCloseButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateCloseButton.widthAnchor.constraint(equalToConstant: 16),
            dateCloseButton.heightAnchor.constraint(equalToConstant: 16),
            dateLbl.trailingAnchor.constraint(
                lessThanOrEqualTo: dateCloseButton.leadingAnchor,
                constant: -Layout.dateCloseSpacing
            )
        ])
    }

    private func setupSkeletonView() {
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        shimmerView.isHidden = true
        view.addSubview(shimmerView)

        NSLayoutConstraint.activate([
            shimmerView.topAnchor.constraint(equalTo: view.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func hideSkeletonScreen() {
        shimmerDidFinish = true
        shimmerView.stopShimmer()
        landingHeaderView.isHidden = false
        shimmerView.isHidden = true
        bringScrollableHeaderToFront()
    }

    func showSkeletonScreen() {
        shimmerDidFinish = false
        shimmerView.isHidden = false
        landingHeaderView.isHidden = true
        view.bringSubviewToFront(shimmerView)
        shimmerView.startShimmer()
    }

    func refreshLocationFromDefaults() {
        applyCityFilter(
            UserDefault.shared.filterCity,
            showsLoading: false
        )
    }

    private func updateDateSelectionUI() {

        let dateText = selectedDateDisplayText(
            startDate: startDate,
            endDate: endDate
        )

        self.dateLbl.text = self.isDateSelected
        ? dateText
        : ""
        self.dateView.isHidden = !self.isDateSelected
        self.dateCloseButton.isHidden = !self.isDateSelected
        self.landingHeaderView.setCalendarSelected(self.isDateSelected)

        UIView.performWithoutAnimation {

            if self.isDateSelected {

                // MARK: Selected State

                self.dateView.alpha = 1
                self.dateView.layer.opacity = 1
                self.dateView.isOpaque = false
                self.dateView.overrideBackgroundColor = nil
                self.dateView.borderWidth = 0

                self.dateLbl.textColor = .white
                self.calendarIcon.tintColor = .white
                self.dateCloseButton.tintColor = .white
            } else {

                // MARK: Default State

                self.dateView.alpha = 1
                self.dateView.layer.opacity = 1
                self.dateView.isOpaque = false
                self.dateLbl.textColor = .white
                self.calendarIcon.tintColor = .white
                self.dateCloseButton.tintColor = .white
                self.dateView.overrideBackgroundColor = nil
            }
        }

        self.refreshDateChipLayout()
        self.showSegmentView(self.isDateSelected ? 1 : 0)
    }

    // MARK: - Actions

    @IBAction func onClickCity(_ sender: Any) {

        let vc = Navigate.to.selectLocationVC(self)
        vc.selectedFilterCity = UserDefault.shared.filterCity
        vc.initialFilterCity = UserDefault.shared.filterCity

        vc.onSelectFilterCity = { [weak self] city in

            guard let self else { return }

            self.applyCityFilter(city)
        }
    }

    @IBAction func onClickDate(_ sender: Any) {
        presentDateRangeSelection()
    }

    @IBAction func onClickDateCross(_ sender: Any) {
        startDate = nil
        endDate = nil
        showSegmentView(0)
        isDateSelected = false
    }

    @IBAction func onClickCityCloseBtn(_ sender: Any) {
        applyCityFilter(nil)
    }

    // MARK: - Helpers

    private func showSegmentView(_ index: Int) {
        segmentViewContainer.enumerated().forEach { i, _ in
            segmentViewContainer[i].isHidden   = i != index
            segmentViewContainer[i].endEditing(i != index)
        }
        configureActiveScrollableHeader()
    }

    private func bringScrollableHeaderToFront() {
        view.bringSubviewToFront(filtersScrollView)
        view.bringSubviewToFront(landingHeaderView)
        if !shimmerView.isHidden {
            view.bringSubviewToFront(shimmerView)
        }
    }

    private func configureActiveScrollableHeader() {
        guard isViewLoaded else { return }

        let activeChild = children.first { child in
            guard let childView = child.viewIfLoaded else {
                return false
            }

            return segmentViewContainer.contains { container in
                !container.isHidden && childView.isDescendant(of: container)
            }
        }

        guard let scrollable = activeChild as? DiscoverHeaderScrollable,
              let scrollView = scrollable.discoverHeaderScrollView
        else {
            return
        }

        activeScrollableHeader = scrollable
        activeHeaderScrollView = scrollView

        let totalTopInset = Layout.discoverHeaderContentInset + scrollable.discoverHeaderAdditionalTopInset
        applyTopInset(totalTopInset, to: scrollView)
        updateScrollableHeader(for: scrollView)
        bringScrollableHeaderToFront()
    }

    private func applyTopInset(
        _ topInset: CGFloat,
        to scrollView: UIScrollView
    ) {
        let oldAdjustedTop = scrollView.adjustedContentInset.top
        let normalizedOffset = scrollView.contentOffset.y + oldAdjustedTop

        guard abs(scrollView.contentInset.top - topInset) > 0.5 ||
                !didApplyInitialHeaderOffset
        else {
            return
        }

        scrollView.contentInset.top = topInset
        scrollView.scrollIndicatorInsets.top = topInset
        scrollView.verticalScrollIndicatorInsets.top = topInset

        let newAdjustedTop = scrollView.adjustedContentInset.top
        if !didApplyInitialHeaderOffset || normalizedOffset <= 0 {
            scrollView.setContentOffset(
                CGPoint(x: scrollView.contentOffset.x, y: -newAdjustedTop),
                animated: false
            )
            didApplyInitialHeaderOffset = true
        } else {
            scrollView.setContentOffset(
                CGPoint(x: scrollView.contentOffset.x, y: normalizedOffset - newAdjustedTop),
                animated: false
            )
        }
    }

    private func updateScrollableHeader(for scrollView: UIScrollView) {
        guard scrollView === activeHeaderScrollView else { return }

        let offset = max(
            0,
            scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        )
        let collapseOffset = min(
            offset,
            Layout.discoverHeaderContentInset + view.safeAreaInsets.top
        )

        landingHeaderView.transform = CGAffineTransform(
            translationX: 0,
            y: -collapseOffset
        )
        filtersScrollView.transform = CGAffineTransform(
            translationX: 0,
            y: -collapseOffset
        )
        updateScrollableHeaderAlpha(offset: offset)
        activeScrollableHeader?.discoverHeaderDidUpdate(
            collapseOffset: offset,
            baseTopInset: Layout.discoverHeaderContentInset
        )
    }

    private func updateScrollableHeaderAlpha(offset: CGFloat) {
        let profileFadeProgress = min(max((offset - 4) / 18, 0), 1)
        let chipSafeAreaCrossingOffset: CGFloat = 60
        let chipFadeProgress = min(
            max((offset - (chipSafeAreaCrossingOffset - 14)) / 18, 0),
            1
        )

        let profileAlpha = 1 - easeOut(profileFadeProgress)
        let chipAlpha = 1 - easeOut(chipFadeProgress)

        landingHeaderView.alpha = profileAlpha
        filtersScrollView.alpha = chipAlpha
        landingHeaderView.isUserInteractionEnabled = profileAlpha > 0.08
        filtersScrollView.isUserInteractionEnabled = chipAlpha > 0.08
    }

    private func easeOut(_ value: CGFloat) -> CGFloat {
        let value = min(max(value, 0), 1)
        let remaining = 1 - value
        return 1 - (remaining * remaining)
    }

    private func resolvedCity() -> String {

        let city = filterCity?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let city,
           !city.isEmpty {

            return city
        }

        return UserDefault.shared.activeCity
    }

    private var hasTemporaryCityFilter: Bool {
        filterCity?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty == false
    }

    private func normalizedFilterCity(_ city: String?) -> String? {
        let trimmedCity = city?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let trimmedCity,
              !trimmedCity.isEmpty,
              !UserDefault.shared.isPrimaryCity(trimmedCity)
        else {
            return nil
        }

        return trimmedCity
    }

    private func selectedDateDisplayText(
        startDate: String?,
        endDate: String?
    ) -> String {
        let startDate = startDate?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let endDate = endDate?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !startDate.isEmpty else {
            return ""
        }

        guard let start = dateFromAPIDate(startDate) else {
            return endDate.isEmpty ? startDate : "\(startDate) to \(endDate)"
        }

        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "en_US_POSIX")
        displayFormatter.timeZone = Constant.venueTimeZone ?? .current
        displayFormatter.dateFormat = "MMM d"

        guard !endDate.isEmpty,
              let end = dateFromAPIDate(endDate),
              !venueCalendar.isDate(start, inSameDayAs: end) else {
            return displayFormatter.string(from: start)
        }

        return "\(displayFormatter.string(from: start))- \(displayFormatter.string(from: end))"
    }

    private func dateFromAPIDate(_ value: String?) -> Date? {
        guard let value = value?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Constant.venueTimeZone ?? .current
        formatter.dateFormat = DateFormat.YYYYMMDD.rawValue
        return formatter.date(from: value)
    }

    private func presentDateRangeSelection() {
        Navigate.to.dateRangeSelectionVC(
            self,
            initialStartDate: dateFromAPIDate(startDate),
            initialEndDate: dateFromAPIDate(endDate ?? startDate)
        )
    }

    private func applyCityFilter(
        _ city: String?,
        showsLoading: Bool = true
    ) {
        filterCity = normalizedFilterCity(city)

        UserDefault.shared.filterCity = filterCity

        selectedLocationName.text = resolvedCity()
        updateCityCloseButton()

        if let discoverAllVC = childViewController(ofType: DiscoverAllVC.self) {

            discoverAllVC.reloadCityData(
                city: resolvedCity(),
                showsLoading: showsLoading
            )
        }

        if let discoverDateFilterVC = childViewController(ofType: DiscoverDateFilterVC.self),
           isDateSelected {

            discoverDateFilterVC.updateFilterDates(
                selectedDateRangeDisplayDates(),
                apiDates: selectedDateRangeAPIDates(),
                city: resolvedCity()
            )
        }
    }

    private func updateCityCloseButton() {
        cityClosebtn.isHidden = !hasTemporaryCityFilter
        cityCloseContainer?.isHidden = !hasTemporaryCityFilter
        cityCloseContainerConstraints.forEach {
            $0.isActive = hasTemporaryCityFilter
        }
        cityLabelTrailingConstraint?.isActive = !hasTemporaryCityFilter
        refreshCityChipLayout()
    }

    private func refreshCityChipLayout() {
        updateCityChipWidth()
        selectedLocationName.invalidateIntrinsicContentSize()
        selectedLocationName.superview?.invalidateIntrinsicContentSize()
        selectedLocationName.superview?.setNeedsLayout()
        selectedLocationName.superview?.superview?.setNeedsLayout()
        selectedLocationName.superview?.superview?.superview?.setNeedsLayout()

        UIView.performWithoutAnimation {
            view.layoutIfNeeded()
        }
    }

    private func updateCityChipWidth() {
        let city = selectedLocationName.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let font = selectedLocationName.font ?? Constant.Font.geistRegular(size: 12)
        let textWidth = ceil((city as NSString).size(withAttributes: [.font: font]).width)
        let closeWidth: CGFloat = hasTemporaryCityFilter ? Layout.cityCloseWidth : 0
        let width =
        (Layout.chipHorizontalPadding * 2) +
        Layout.chipIconWidth +
        Layout.cityIconSpacing +
        textWidth +
        closeWidth

        cityChipWidthConstraint?.constant = min(
            max(width, Layout.cityChipMinWidth),
            Layout.cityChipMaxWidth
        )
    }

    private func refreshDateChipLayout() {
        updateDateChipWidth()
        dateLbl.invalidateIntrinsicContentSize()
        dateView.invalidateIntrinsicContentSize()
        dateView.superview?.setNeedsLayout()
        dateView.superview?.superview?.setNeedsLayout()
        dateView.superview?.superview?.superview?.setNeedsLayout()

        UIView.performWithoutAnimation {
            view.layoutIfNeeded()
        }
    }

    private func updateDateChipWidth() {
        let text = dateLbl.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let font = dateLbl.font ?? Constant.Font.geistMedium(size: 12)
        let textWidth = ceil((text as NSString).size(withAttributes: [.font: font]).width)
        let width =
        (Layout.chipHorizontalPadding * 2) +
        Layout.chipIconWidth +
        Layout.chipIconSpacing +
        textWidth +
        Layout.dateCloseSpacing +
        Layout.cityCloseWidth

        dateChipWidthConstraint?.constant = min(
            max(width, Layout.dateChipMinWidth),
            Layout.dateChipMaxWidth
        )
    }

    private func bindSelectedCity() {
        UserDefault.shared.localCityPublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }

                guard !self.hasTemporaryCityFilter else { return }

                self.applyCityFilter(
                    nil,
                    showsLoading: false
                )
            }
            .store(in: &cancellables)

        selectedLocationName.text = resolvedCity()
        updateCityCloseButton()
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        viewControllers.append(segue.destination)
    }

    private func childViewController<T: UIViewController>(
        ofType type: T.Type
    ) -> T? {
        children.first { $0 is T } as? T
    }
}

extension DiscoverVC {
    func discoverHeaderScrollViewDidScroll(_ scrollView: UIScrollView) {
        updateScrollableHeader(for: scrollView)
    }
}

protocol DiscoverHeaderScrollable: AnyObject {
    var discoverHeaderScrollView: UIScrollView? { get }
    var discoverHeaderAdditionalTopInset: CGFloat { get }
    func discoverHeaderDidUpdate(
        collapseOffset: CGFloat,
        baseTopInset: CGFloat
    )
}

extension DiscoverHeaderScrollable {
    var discoverHeaderAdditionalTopInset: CGFloat { 0 }

    func discoverHeaderDidUpdate(
        collapseOffset: CGFloat,
        baseTopInset: CGFloat
    ) {}
}

// MARK: - SelectedDateDelegate

extension DiscoverVC: SelectedDateDelegate {

    func selectedDateRange(startDate: String?, endDate: String?) {
        self.startDate = startDate
        self.endDate = startDate != endDate ? endDate : nil
        isDateSelected = true
        if let vc = childViewController(ofType: DiscoverDateFilterVC.self) {
            vc.updateFilterDates(
                selectedDateRangeDisplayDates(),
                apiDates: selectedDateRangeAPIDates(),
                city: resolvedCity()
            )
        }
    }

    private func selectedDateRangeDisplayDates() -> [String] {
        datesBetween(
            startDate: self.startDate ?? "",
            endDate: self.endDate ?? self.startDate ?? ""
        )
    }

    private func selectedDateRangeAPIDates() -> [String] {
        datesBetween(
            startDate: self.startDate ?? "",
            endDate: self.endDate ?? self.startDate ?? "",
            outputFormat: "yyyy-MM-dd"
        )
    }

    func datesBetween(
        startDate: String,
        endDate: String,
        outputFormat: String = "MMM dd"
    ) -> [String] {
        let inputFormatter        = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale     = Locale(identifier: "en_US_POSIX")
        inputFormatter.timeZone   = Constant.venueTimeZone ?? .current

        let outputFormatter        = DateFormatter()
        outputFormatter.dateFormat = outputFormat
        outputFormatter.locale     = Locale(identifier: "en_US_POSIX")
        outputFormatter.timeZone   = Constant.venueTimeZone ?? .current

        guard
            let start = inputFormatter.date(from: startDate),
            let end   = inputFormatter.date(from: endDate)
        else { return [] }

        var dates: [String] = []
        var calendar         = Calendar(identifier: .gregorian)
        calendar.timeZone    = Constant.venueTimeZone ?? .current
        let today            = calendar.startOfDay(
            for: Constant.venueTodayDate().dateFormatter(formate: .YYYYMMDD) ?? Date()
        )
        var current          = max(calendar.startOfDay(for: start), today)
        let rangeEnd         = calendar.startOfDay(for: end)

        while current <= rangeEnd {
            dates.append(outputFormatter.string(from: current))
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
}
