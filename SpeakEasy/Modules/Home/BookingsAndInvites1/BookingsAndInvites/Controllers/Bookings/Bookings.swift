//
//  Bookings.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 30/08/2022.
//

import UIKit

class Bookings: BaseController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var arrBookings = [
                       BookingsDataSet(brand: UIImage(named: "ic-tao"), bookingName: "TAO Chicago", performerCover: UIImage(named: "ic-artist"), isTicket: true, date: "Thursday, June 30", status: .PurchaseConfirmed),
                       BookingsDataSet(brand: UIImage(named: "ic-prism"), bookingName: "PRYSM Chicago", performerCover: UIImage(named: "ic-await-approval-bg"), isTicket: false, date: "Sunday, August 7", status: .AwaitingApproval),
                       BookingsDataSet(brand: UIImage(named: "ic-tao"), bookingName: "TAO Chicago", performerCover: UIImage(named: "ic-artist"), isTicket: true, date: "Thursday, June 30", status: .PurchaseConfirmed),
                       BookingsDataSet(brand: UIImage(named: "ic-prism"), bookingName: "PRYSM Chicago", performerCover: UIImage(named: "ic-await-approval-bg"), isTicket: false, date: "Sunday, August 7", status: .AwaitingVenueApproval)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.tableView.register(UINib(nibName: "BookingsTVC", bundle: nil), forCellReuseIdentifier: "BookingsTVC")
        
    }
    
}


//MARK: TableView
extension Bookings: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrBookings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "BookingsTVC") as! BookingsTVC
        cell.btnBookingInvites.tag = indexPath.row
        cell.btnBookingInvites.addTarget(self, action: #selector(self.onBtnBooking(_:)), for: .touchUpInside)
        
        let data = self.arrBookings[indexPath.row]
        cell.setData(data: data)
        return cell
    }
    
    @objc func onBtnBooking(_ sender: UIButton) {
        let data = self.arrBookings[sender.tag]
        
        switch sender.tag {
        case 0,2:
            super.pushToTicketConfirmation(data: data)
        case 1:
            super.pushToBookingInvite(booking: data)
        case 3:
            super.pushToPendingBookingAwait(data: data)
        default:
            break
        }
    }
    @objc func onBtnConfirmBooking(_ sender: UIButton) {
        let data = self.arrBookings[sender.tag]
        super.pushToTicketConfirmation(data: data)
    }
    @objc func onBtnBookingInvites(_ sender: UIButton) {
        let data = self.arrBookings[sender.tag]
        if data.status == .AwaitingApproval {
            super.pushToBookingInvite(booking: data)
        }
    }
    @objc func onBtnPendingBookingAwait(_ sender: UIButton) {
        let data = self.arrBookings[sender.tag]
        super.pushToPendingBookingAwait(data: data)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = self.tableView else {return}
        
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

/*
 
 
 if data.status == .AwaitingVenueApproval {
     cell.btnBookingInvites.addTarget(self, action: #selector(onBtnPendingBookingAwait(_:)), for: .touchUpInside)
 }else if data.status == .PurchaseConfirmed {
     cell.btnBookingInvites.addTarget(self, action: #selector(onBtnConfirmBooking(_:)), for: .touchUpInside)
 } else{
     cell.btnBookingInvites.addTarget(self, action: #selector(onBtnBookingInvites(_:)), for: .touchUpInside)
 }
 */
