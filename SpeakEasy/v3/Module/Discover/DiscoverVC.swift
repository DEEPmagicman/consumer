//
//  DiscoverVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 22/12/25.
//

import UIKit
import Combine

final class DiscoverVC: UIViewController {

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
    private var viewControllers = [UIViewController]()
    private var cancellables = Set<AnyCancellable>()
    var startDate: String?
    var endDate: String?
    private var shimmerDidFinish = false
    private var filterCity: String?
    private var appliedGradientBounds: CGRect = .zero
    private var didApplyInitialHeaderOffset = false
    private var activeScrollableHeader: DiscoverHeaderScrollable?
    private weak var activeHeaderScrollView: UIScrollView?

    private let shimmerView = HomeSkeletonView()
    private let discoverHeaderContentInset: CGFloat = 100

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

        filterCity = UserDefault.shared.filterCity
        if UserDefault.shared.isPrimaryCity(filterCity) {
            filterCity = nil
            UserDefault.shared.filterCity = nil
        }
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
//        landingHeaderView.delegate = self
        landingHeaderView.setMapHidden(false)
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
        segmentTopConstraint.constant -= discoverHeaderContentInset
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
        dateLbl.setContentHuggingPriority(.required, for: .horizontal)
        dateLbl.setContentCompressionResistancePriority(.required, for: .horizontal)

        let widthConstraint = dateView.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.priority = .required
        widthConstraint.isActive = true
        dateChipWidthConstraint = widthConstraint
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

        let startDate = self.startDate?.convertDateFormat(
            from: .YYYYMMDD,
            to: .MMMD
        )

        let endDate = self.endDate?.convertDateFormat(
            from: .YYYYMMDD,
            to: .MMMD
        )

        let dateText = (self.endDate ?? "").isEmpty
        ? "\(startDate ?? "")"
        : "\(startDate ?? "") - \(endDate ?? "")"

        self.dateLbl.text = self.isDateSelected
        ? dateText
        : "All Dates"

        UIView.performWithoutAnimation {

            if self.isDateSelected {

                // MARK: Selected State

                self.dateView.alpha = 1
                self.dateView.layer.opacity = 1
                self.dateView.isOpaque = true
                dateView.overrideBackgroundColor = .white
                self.dateView.borderWidth = 0

                self.dateLbl.textColor = .black
                self.calendarIcon.tintColor = .black
            } else {

                // MARK: Default State

                self.dateView.alpha = 1
                self.dateView.layer.opacity = 1
                self.dateView.isOpaque = false
                self.dateLbl.textColor = .white
                self.calendarIcon.tintColor = .white
                dateView.overrideBackgroundColor = nil
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
        if isDateSelected {
            isDateSelected = false
        } else {
            Navigate.to.dateRangeSelectionVC(self)
        }

    }

    @IBAction func onClickDateCross(_ sender: Any) {
        showSegmentView(0)
        isDateSelected.toggle()
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

        let totalTopInset = discoverHeaderContentInset + scrollable.discoverHeaderAdditionalTopInset
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
            discoverHeaderContentInset + view.safeAreaInsets.top
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
            baseTopInset: discoverHeaderContentInset
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

    private func applyCityFilter(
        _ city: String?,
        showsLoading: Bool = true
    ) {
        let trimmedCity = city?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        filterCity = trimmedCity?.isEmpty == false &&
            !UserDefault.shared.isPrimaryCity(trimmedCity)
            ? trimmedCity
            : nil

        UserDefault.shared.filterCity = filterCity

        selectedLocationName.text = resolvedCity()
        updateCityCloseButton()

        if let discoverAllVC = children.first(where: {
            $0 is DiscoverAllVC
        }) as? DiscoverAllVC {

            discoverAllVC.reloadCityData(
                city: resolvedCity(),
                showsLoading: showsLoading
            )
        }

        if let discoverDateFilterVC = children.first(where: {
            $0 is DiscoverDateFilterVC
        }) as? DiscoverDateFilterVC,
           isDateSelected {

            discoverDateFilterVC.updateFilterDates(
                selectedDateRangeDisplayDates(),
                apiDates: selectedDateRangeAPIDates(),
                city: resolvedCity()
            )
        }
    }

    private func updateCityCloseButton() {
        let hasTemporaryCity = filterCity?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

        cityClosebtn.isHidden = !hasTemporaryCity
        cityCloseContainer?.isHidden = !hasTemporaryCity
        cityCloseContainerConstraints.forEach {
            $0.isActive = hasTemporaryCity
        }
        cityLabelTrailingConstraint?.isActive = !hasTemporaryCity
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
        let hasTemporaryCity = filterCity?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let font = selectedLocationName.font ?? Constant.Font.geistRegular(size: 12)
        let textWidth = ceil((city as NSString).size(withAttributes: [.font: font]).width)
        let closeWidth: CGFloat = hasTemporaryCity ? 20 : 0
        let width = 12 + 12 + 4 + textWidth + closeWidth + 12

        cityChipWidthConstraint?.constant = min(max(width, 76), 220)
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
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "All Dates"
        let font = dateLbl.font ?? Constant.Font.geistMedium(size: 12)
        let textWidth = ceil((text as NSString).size(withAttributes: [.font: font]).width)
        let width = 12 + 12 + 6 + textWidth + 12

        dateChipWidthConstraint?.constant = min(max(width, 88), 240)
    }

    private func bindSelectedCity() {
        UserDefault.shared.localCityPublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let hasTemporaryCity =
                    self.filterCity?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty == false

                guard !hasTemporaryCity else { return }

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
        switch segue.destination {
        case is DiscoverAllVC:
            print("DiscoverAllVC prepared")
        case is DiscoverDateFilterVC:
            print("DiscoverDateFilterVC prepared")
        default:
            break
        }
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
        if let vc = children.first(where: { $0 is DiscoverDateFilterVC }) as? DiscoverDateFilterVC {
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
        let today            = calendar.startOfDay(for: Constant.venueTodayDate().dateFormatter() ?? Date())
        var current          = max(calendar.startOfDay(for: start), today)
        let rangeEnd         = calendar.startOfDay(for: end)

        while current <= rangeEnd {
            dates.append(outputFormatter.string(from: current))
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
}
