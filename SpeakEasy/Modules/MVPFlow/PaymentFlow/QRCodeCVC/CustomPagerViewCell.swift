//
//  CustomPagerViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Sanjay on 29/02/24.
//

import UIKit
import FSPagerView

final class CustomPagerViewCell: FSPagerViewCell {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var ticketsTableView: UITableView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var ticketCodeView: UIView!
    @IBOutlet weak var backupCode: UILabel!
    @IBOutlet weak var bookingDateTime: UILabel!
    @IBOutlet weak var guestNameLbl: UILabel!
    @IBOutlet weak var openTabBtnHeight: NSLayoutConstraint!
    
    var booking: Booking?
    var addOnsBooking: AddOnsBooking?
    var barTabBooking: BarTabBooking?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        ticketsTableView.delegate = self
        ticketsTableView.dataSource = self
        ticketsTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(qrImageTapped))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    
    @objc func qrImageTapped() {
        containerView.isUserInteractionEnabled = false
        flipView()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.flipView()
            self.containerView.isUserInteractionEnabled = true
        }
    }
    
    private func flipView() {
        UIView.transition(with: containerView, duration: 1, options: .transitionFlipFromRight, animations: {[weak self] in
            guard let self = self else { return }
            self.ticketCodeView.isHidden = !self.ticketCodeView.isHidden
            self.qrImage.isHidden = !self.qrImage.isHidden
        })
    }
}

extension CustomPagerViewCell: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let barTabBooking = barTabBooking {
            return barTabBooking.uniqueTickets.count
        } else {
            return booking != nil ? booking?.uniqueTickets.count ?? 0 : addOnsBooking?.uniqueTickets.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        cell.contentView.backgroundColor = .clear
        cell.checkInProgressBarView.isHidden = false
        cell.checkInProgress.cornerRadius = 5
        if let barTabBooking = barTabBooking {
            
            cell.subTitleLbl.text =  barTabBooking.uniqueTickets[indexPath.row].coverTicket?.description
            cell.titleLbl.text = barTabBooking.uniqueTickets[indexPath.row].coverTicket?.customName ?? "" == "" ? barTabBooking.uniqueTickets[indexPath.row].coverTicket?.name : barTabBooking.uniqueTickets[indexPath.row].coverTicket?.customName
            
            cell.quantityLbl.text = "\(barTabBooking.uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
            let checkInCount = barTabBooking.uniqueTickets[indexPath.row].checkedInQuantity ?? 0
            cell.checkInCount.text = "\(checkInCount)/\(barTabBooking.uniqueTickets[indexPath.row].selectedQuantity ?? 0)"
            cell.checkInProgress.setProgress(Float(checkInCount) / Float(barTabBooking.uniqueTickets[indexPath.row].selectedQuantity ?? 0), animated: false)
            
        } else if booking != nil {
            cell.subTitleLbl.text = booking?.ticketDetails?.first(where: { $0.ticketId == booking?.uniqueTickets[indexPath.row].ticketId })?.ticketDescription
            cell.titleLbl.text = booking?.uniqueTickets[indexPath.row].ticketCustomName ?? "" == "" ? booking?.uniqueTickets[indexPath.row].ticketName : booking?.uniqueTickets[indexPath.row].ticketCustomName
            
            cell.quantityLbl.text = "\(booking?.uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
            
            let checkInCount = booking?.uniqueTickets[indexPath.row].checkedInQuantity ?? 0
            cell.checkInCount.text = "\(checkInCount)/\(booking?.uniqueTickets[indexPath.row].selectedQuantity ?? 0)"
            cell.checkInProgress.setProgress(Float(checkInCount) / Float(booking?.uniqueTickets[indexPath.row].selectedQuantity ?? 0), animated: false)
        } else {
            cell.subTitleLbl.text = addOnsBooking?.uniqueTickets[indexPath.row].addOns.description ?? ""
            cell.titleLbl.text = addOnsBooking?.uniqueTickets[indexPath.row].addOns.name ?? ""
            cell.quantityLbl.text = "\(addOnsBooking?.uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
            let checkInCount = addOnsBooking?.uniqueTickets[indexPath.row].checkedInQuantity ?? 0
            cell.checkInCount.text = "\(checkInCount)/\(addOnsBooking?.uniqueTickets[indexPath.row].selectedQuantity ?? 0)"
            cell.checkInProgress.setProgress(Float(checkInCount) / Float(addOnsBooking?.uniqueTickets[indexPath.row].selectedQuantity ?? 0), animated: false)
        }
        cell.selectionStyle = .none
        
        return cell
    }
}
