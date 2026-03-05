//
//  TableBookingListVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 05/01/26.
//

import UIKit

class TableBookingListVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var seatingAreas: [SeatingArea] = []
    var event: Event?
    var skip: Int = 0
    var hasMore: Bool = true
    var isLoading: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        fetchSeatingAreas()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TableListTVC.nib, forCellReuseIdentifier: TableListTVC.identifier)
    }
    
    private func fetchSeatingAreas() {
        
        guard !isLoading, hasMore else { return }
        
        isLoading = true
        
        TablePresenter.getSeatingAreas(
            eventId: event?.id ?? "",
            skip: skip
        ) { [weak self] isSuccess, errMsg, list, apiHasMore in
            
            guard let self = self else { return }
            
            self.isLoading = false
            
            if isSuccess {
                
                self.seatingAreas.append(contentsOf: list)
                self.hasMore = apiHasMore
                self.skip += list.count
                
                self.tableView.reloadData()
            } else {
                print(errMsg ?? "Error fetching seating areas")
            }
        }
    }

}

extension TableBookingListVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return seatingAreas.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: TableListTVC = tableView.dequeue(
            withIdentifier: TableListTVC.identifier,
            for: indexPath
        )
        
        cell.selectionStyle = .none
        
        let item = seatingAreas[indexPath.row]
        
        cell.onBookTap = { [weak self] in
            guard let self = self else { return }
            
            let selectedItem = self.seatingAreas[indexPath.row]
            
            if selectedItem.hideCheckout == true {
                print("Inquire tapped for:", selectedItem.name ?? "")
            } else {
                Navigate.to.tableSeatingVC(self, seatingArea: selectedItem)
            }
        }

        cell.tableName.text = item.name
        cell.tableDescriptionLbl.text = item.highlight?.isEmpty == false
            ? item.highlight
            : item.description
        
        if item.hidePricing == true {
            cell.totalAmount.text = ""
            cell.secondAmountLbl.text = ""
        } else {
            if item.bookingType == .timeWise {
                
                if let slot = item.timeSlots?.first {
                    
                    if let deposit = slot.deposit {
                        cell.totalAmount.text = "$\(String(format: "%.2f", deposit))"
                    }
                    
                    if let minimum = slot.minimum {
                        cell.secondAmountLbl.text = "$\(minimum) min."
                    }
                }
            } else {
                if let deposit = item.depositWithFees {
                    cell.totalAmount.text = "$\(String(format: "%.2f", deposit))"
                } else if let deposit = item.deposit {
                    cell.totalAmount.text = "$\(String(format: "%.2f", deposit))"
                }
                
                if let minimum = item.minimum {
                    cell.secondAmountLbl.text = "$\(minimum) min."
                }
            }
            
        }
        
        let minGuest = item.defaultGuest ?? 0
        let maxGuest = item.maxGuest ?? 0

        let guestsText: String = {
            if minGuest > 0 && maxGuest > 0 {
                return minGuest == maxGuest
                ? "\(minGuest) Guests"
                : "\(minGuest) to \(maxGuest) Guests"
            } else if maxGuest > 0 {
                return "\(maxGuest) Guests"
            } else {
                return "Guests"
            }
        }()

        
        if let slot = item.timeSlots?.first,
           let start = slot.startTime,
           let startDate = start.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: false) {
            
            let startTime = startDate.string(format: .hmma, isUTC: false)
            
            var endTime = ""
            
            if let end = slot.endTime,
               let endDate = end.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: false) {
                
                endTime = endDate.string(format: .hmma, isUTC: false)
            }
            
            let finalTime = endTime.isEmpty ? startTime : "\(startTime) - \(endTime)"
            
            cell.tableDetailLbl.attributedText = cell.buildGuestsTimeText(
                guests: guestsText,
                time: finalTime
            )
        } else {
            cell.tableDetailLbl.attributedText = cell.buildGuestsTimeText(
                guests: guestsText,
                time: ""
            )
        }
        
        cell.bookBtn.isHidden = false
        cell.bookBtn.setTitle(item.hideCheckout == true ? "Inquire" : "Book", for: .normal)
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        
        if indexPath.row == seatingAreas.count - 1 {
            fetchSeatingAreas()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
            let selectedItem = self.seatingAreas[indexPath.row]
            
            if selectedItem.hideCheckout == true {
                print("Inquire tapped for:", selectedItem.name ?? "")
            } else {
                Navigate.to.tableSeatingVC(self, seatingArea: selectedItem)
            }
    }
}
