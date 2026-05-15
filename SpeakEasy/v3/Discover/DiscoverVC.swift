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
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Pin shimmer full-screen on top of everything
        view.addSubview(shimmerView)
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shimmerView.topAnchor.constraint(equalTo: view.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        showSegmentView(0)
        bindSelectedCity()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !shimmerDidFinish {
            shimmerView.startShimmer()
        }
    }

    func hideSkeletonScreen() {
        shimmerDidFinish = true
        shimmerView.stopShimmer()
        shimmerView.isHidden = true
    }

    func showSkeletonScreen() {
        shimmerDidFinish = false
        shimmerView.isHidden = false
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
        vc.selectedFilterCity = self.filterCity
        vc.initialFilterCity = self.filterCity

        vc.onSelectFilterCity = { [weak self] city in

            guard let self else { return }

            self.filterCity = city

            self.selectedLocationName.text =
            self.resolvedCity()

            if let discoverAllVC = self.children.first(where: {
                $0 is DiscoverAllVC
            }) as? DiscoverAllVC {

                discoverAllVC.reloadCityData(city: city ?? "")
            }
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

        return UserDefault.shared.localCity
    }
    private func bindSelectedCity() {
//        UserDefault.shared.localCityPublisher
//            .removeDuplicates()
//            .map { _ in self.resolvedCity() }
//            .receive(on: RunLoop.main)
//            .sink { [weak self] city in
//                self?.selectedLocationName.text = city
//            }
//            .store(in: &cancellables)
        
        self.selectedLocationName.text = self.resolvedCity()
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
        if startDate != endDate { self.endDate = endDate }
        isDateSelected = true
        if let vc = children.first(where: { $0 is DiscoverDateFilterVC }) as? DiscoverDateFilterVC {
            vc.selectedDates = datesBetween(
                startDate: self.startDate ?? "",
                endDate:   self.endDate   ?? ""
            )
            vc.dateCollectionView.reloadData()
            vc.collectionView.reloadData()
        }
    }
    
    func datesBetween(startDate: String, endDate: String) -> [String] {
        let inputFormatter        = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale     = Locale(identifier: "en_US_POSIX")

        let outputFormatter        = DateFormatter()
        outputFormatter.dateFormat = "MMM dd"
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
