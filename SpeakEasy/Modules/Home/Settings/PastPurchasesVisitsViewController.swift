//
//  PastPurchases&VisitsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit

class PastPurchasesVisitsViewController: UIViewController {

    @IBOutlet weak var pastPurchasesTableView: UITableView!
    
    var arrBookings = [
                       BookingsDataSet(brand: UIImage(named: "ic-tao"), bookingName: "TAO Chicago", performerCover: UIImage(named: "ic-artist"), isTicket: true, date: "Thursday, June 30", status: .PurchaseConfirmed),
                       BookingsDataSet(brand: UIImage(named: "ic-tao"), bookingName: "TAO Chicago", performerCover: UIImage(named: "ic-await-approval-bg"), isTicket: false, date: "Sunday, August 7", status: .AwaitingApproval),
                       BookingsDataSet(brand: UIImage(named: "ic-tao"), bookingName: "TAO Chicago", performerCover: UIImage(named: "ic-artist"), isTicket: true, date: "Thursday, June 30", status: .PurchaseConfirmed),
                       BookingsDataSet(brand: UIImage(named: "ic-tao"), bookingName: "TAO Chicago", performerCover: UIImage(named: "ic-await-approval-bg"), isTicket: false, date: "Sunday, August 7", status: .AwaitingVenueApproval)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pastPurchasesTableView.delegate = self
        pastPurchasesTableView.dataSource = self
        pastPurchasesTableView.register(UINib(nibName: "BookingsTVC", bundle: nil), forCellReuseIdentifier: "BookingsTVC")
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
}

extension PastPurchasesVisitsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrBookings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.pastPurchasesTableView.dequeueReusableCell(withIdentifier: "BookingsTVC") as! BookingsTVC
        cell.selectionStyle = .none
        cell.btnBookingInvites.tag = indexPath.row

        let data = self.arrBookings[indexPath.row]
        cell.setData(data: data, isFromSettings: true)
        
        if data.status == .AwaitingVenueApproval {
            cell.btnBookingInvites.addTarget(self, action: #selector(onBtnPendingBookingAwait(_:)), for: .touchUpInside)
        }else if data.status == .PurchaseConfirmed {
            cell.btnBookingInvites.addTarget(self, action: #selector(onBtnConfirmBooking(_:)), for: .touchUpInside)
        } else{
            cell.btnBookingInvites.addTarget(self, action: #selector(onBtnBookingInvites(_:)), for: .touchUpInside)
        }
        
        return cell
    }
    
    @objc func onBtnConfirmBooking(_ sender: UIButton) {
        let data = self.arrBookings[sender.tag]
        Navigate.to.ticketConfirmation(self, data: data, isFromSettings: true)
    }
    @objc func onBtnBookingInvites(_ sender: UIButton) {
        let data = self.arrBookings[sender.tag]
        if data.status == .AwaitingApproval {
            Navigate.to.bookingInvite(self, booking: data, isFromSettings: true)
        }
    }
    @objc func onBtnPendingBookingAwait(_ sender: UIButton) {
        let data = self.arrBookings[sender.tag]
        Navigate.to.pendingBookingAwait(self, data: data)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = self.pastPurchasesTableView else {return}
        
        let visibleCells = tableView.visibleCells

        if visibleCells.count == 0 {
            return
        }

        guard let topCell = visibleCells.first else {
            return
        }

        for cell in visibleCells {
            cell.contentView.alpha = 0.9
        }

        let cellHeight = topCell.frame.size.height - 1
        let tableViewTopPosition = tableView.frame.origin.y
        
        let topCellPositionInTableView = tableView.rectForRow(at: tableView.indexPath(for: topCell)!)

        let topCellPosition = tableView.convert(topCellPositionInTableView, to: tableView.superview).origin.y

        let modifier: CGFloat = 1.5
        let topCellOpacity = 1.5 - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier

        topCell.contentView.alpha = topCellOpacity
    }

}
