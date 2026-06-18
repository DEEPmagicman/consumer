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
    @IBOutlet weak var selectedLocationName: UILabel!
    @IBOutlet var bgView: UIView!
    @IBOutlet weak var calendarIcon: UIImageView!
    @IBOutlet weak var cityClosebtn: UIButton!

    private weak var cityChipView: UIView?
    private weak var cityCloseContainer: UIView?
    private var cityCloseContainerConstraints = [NSLayoutConstraint]()
    private var cityLabelTrailingConstraint: NSLayoutConstraint?
    private var cityChipWidthConstraint: NSLayoutConstraint?
    private var viewControllers = [UIViewController]()
    private var cancellables = Set<AnyCancellable>()
    var startDate: String?
    var endDate: String?
    private var shimmerDidFinish = false
    private var filterCity: String?

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

        filterCity = UserDefault.shared.filterCity
        if filterCity?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .caseInsensitiveCompare(UserDefault.shared.localCity) == .orderedSame {
            filterCity = nil
            UserDefault.shared.filterCity = nil
        }
        setupLandingHeader()
        setupCityChipLayout()
        setupSkeletonView()
        showSkeletonScreen()

        showSegmentView(0)
        bindSelectedCity()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !shimmerDidFinish,
           !shimmerView.isHidden {
            shimmerView.startShimmer()
        }
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
    }

    func showSkeletonScreen() {
        shimmerDidFinish = false
        shimmerView.isHidden = false
        landingHeaderView.isHidden = true
        view.bringSubviewToFront(shimmerView)
        shimmerView.startShimmer()
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

    private func applyCityFilter(_ city: String?) {
        let trimmedCity = city?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        filterCity = trimmedCity?.isEmpty == false
            ? trimmedCity
            : nil

        UserDefault.shared.filterCity = filterCity

        selectedLocationName.text = resolvedCity()
        updateCityCloseButton()

        if let discoverAllVC = children.first(where: {
            $0 is DiscoverAllVC
        }) as? DiscoverAllVC {

            discoverAllVC.reloadCityData(city: resolvedCity())
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

                self.applyCityFilter(nil)
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

        let outputFormatter        = DateFormatter()
        outputFormatter.dateFormat = outputFormat
        outputFormatter.locale     = Locale(identifier: "en_US_POSIX")

        guard
            let start = inputFormatter.date(from: startDate),
            let end   = inputFormatter.date(from: endDate)
        else { return [] }

        var dates: [String] = []
        var current          = start
        let calendar         = Calendar.current

        while current <= end {
            dates.append(outputFormatter.string(from: current))
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
}
