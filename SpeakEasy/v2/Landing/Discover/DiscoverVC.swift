//
//  DiscoverVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 22/12/25.
//

import UIKit

final class DiscoverVC: UIViewController {
    
    @IBOutlet var segmentViewContainer: [UIView]!
    @IBOutlet var dateLbl: UILabel!
    @IBOutlet var dateCrossView: UIView!
    @IBOutlet var dateView: UIView!
    
    private var viewControllers = [UIViewController]()
    var startDate: String?
    var endDate: String?
    private var isDateSelected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                let startDate = self.startDate?.convertDateFormat(from: .YYYYMMDD, to: .MMMD)
                let endDate = self.endDate?.convertDateFormat(from: .YYYYMMDD, to: .MMMD)
                let date = self.endDate ?? "" == "" ? "\(startDate ?? "")" : "\(startDate ?? "") - \(endDate ?? "")"
                self.dateLbl.text = self.isDateSelected ? date : "All Dates"
                self.dateView.borderWidth = self.isDateSelected ? 2 : 0
                self.dateView.borderColor = UIColor(hex: "#69DC82")
                self.dateCrossView.isHidden = !self.isDateSelected
                if self.isDateSelected {
                    self.showSegmentView(1)
                } else {
                    self.showSegmentView(0)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isDateSelected = false
        showSegmentView(0)
    }
    
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
    
    private func showSegmentView(_ index: Int) {
        segmentViewContainer.enumerated().forEach { enumeratedIndex, _ in
            segmentViewContainer[enumeratedIndex].isHidden = enumeratedIndex != index
            segmentViewContainer[enumeratedIndex].endEditing(enumeratedIndex != index)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        viewControllers.append(segue.destination)
        switch segue.destination {
        case is DiscoverAllVC:
            if segue.destination is DiscoverAllVC {
                print("BoxOfficeOverviewVC")
            }
        case is DiscoverDateFilterVC:
            if segue.destination is DiscoverDateFilterVC {
                print("BoxOfficeOverviewVC")
            }
        default:
            break
        }
    }
}

extension DiscoverVC: SelectedDateDelegate {
    func selectedDateRange(startDate: String?, endDate: String?) {
        self.startDate = startDate
        if startDate != endDate {
            self.endDate = endDate
        }
        isDateSelected = true
        if let vc = self.children.first(where: { $0.isKind(of: DiscoverDateFilterVC.self)}) as? DiscoverDateFilterVC {
            vc.selectedDates = datesBetween(startDate: self.startDate ?? "", endDate: self.endDate ?? "")
            vc.dateCollectionView.reloadData()
            vc.collectionView.reloadData()
        }
    }
    
    func datesBetween(startDate: String, endDate: String) -> [String] {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM dd"
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")

        guard
            let start = inputFormatter.date(from: startDate),
            let end = inputFormatter.date(from: endDate)
        else {
            return []
        }

        var dates: [String] = []
        var currentDate = start
        let calendar = Calendar.current

        while currentDate <= end {
            dates.append(outputFormatter.string(from: currentDate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
}
