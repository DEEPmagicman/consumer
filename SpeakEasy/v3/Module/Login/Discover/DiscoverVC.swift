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
    @IBOutlet var dateCrossView: UIView!
    @IBOutlet var dateView: UIView!
    @IBOutlet weak var selectedLocationName: UILabel!
    @IBOutlet var bgView: UIView!
    
    private var viewControllers = [UIViewController]()
    private var cancellables = Set<AnyCancellable>()
    var startDate: String?
    var endDate: String?
    private var shimmerDidFinish = false

    // MARK: - Skeleton
    // Lives here in the PARENT so it covers the full screen (including
    // nav-bar area) while child DiscoverAllVC loads its APIs.
    private let shimmerView = HomeSkeletonView()

    private var isDateSelected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                let startDate = self.startDate?.convertDateFormat(from: .YYYYMMDD, to: .MMMD)
                let endDate   = self.endDate?.convertDateFormat(from: .YYYYMMDD, to: .MMMD)
                let date      = (self.endDate ?? "").isEmpty
                    ? "\(startDate ?? "")"
                    : "\(startDate ?? "") - \(endDate ?? "")"
                self.dateLbl.text         = self.isDateSelected ? date : "All Dates"
                self.dateView.borderWidth = self.isDateSelected ? 2 : 0
                self.dateView.borderColor = UIColor(hex: "#69DC82")
                self.dateCrossView.isHidden = !self.isDateSelected
                self.showSegmentView(self.isDateSelected ? 1 : 0)
            }
        }
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        isDateSelected = false

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

    // MARK: - Actions

    @IBAction func onClickCity(_ sender: Any) {
        Navigate.to.selectLocationVC(self)
    }
    
    @IBAction func onClickDate(_ sender: Any) {
        Navigate.to.dateRangeSelectionVC(self)
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
        let city = UserDefault.shared.localCity
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return city.isEmpty ? "New York" : city
    }

    private func bindSelectedCity() {
        UserDefault.shared.localCityPublisher
            .removeDuplicates()
            .map { _ in self.resolvedCity() }
            .receive(on: RunLoop.main)
            .sink { [weak self] city in
                self?.selectedLocationName.text = city
            }
            .store(in: &cancellables)
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
            vc.selectedDates = datesBetween(
                startDate: self.startDate ?? "",
                endDate: self.endDate   ?? self.startDate ?? ""
            )
            vc.dateCollectionView.reloadData()
            vc.collectionView.reloadData()
        }
    }
    
    func datesBetween(startDate: String, endDate: String) -> [String] {
        let inputFormatter        = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale     = Locale(identifier: "en_US_POSIX")
        inputFormatter.timeZone   = Constant.venueTimeZone ?? .current

        let outputFormatter        = DateFormatter()
        outputFormatter.dateFormat = "MMM dd"
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
