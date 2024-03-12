//
//  CustomPagerViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Sanjay on 29/02/24.
//

import UIKit
import FSPagerView

class CustomPagerViewCell: FSPagerViewCell {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var ticketsTableView: UITableView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var ticketCodeView: UIView!
    @IBOutlet weak var backupCode: UILabel!
    @IBOutlet weak var bookingDateTime: UILabel!
    
    var booking: Booking?
    var addOnsBooking: AddOnsBooking?
    
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
        return booking != nil ? booking?.uniqueTickets.count ?? 0 : addOnsBooking?.uniqueTickets.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        cell.contentView.backgroundColor = .clear
        if booking != nil {
            cell.subTitleLbl.text = booking?.ticketDetails?.first(where: { $0.ticketId == booking?.uniqueTickets[indexPath.row].ticketId })?.ticketDescription
            cell.titleLbl.text = booking?.uniqueTickets[indexPath.row].ticketCustomName ?? "" == "" ? booking?.uniqueTickets[indexPath.row].ticketName : booking?.uniqueTickets[indexPath.row].ticketCustomName
            
            cell.quantityLbl.text = "\(booking?.uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
        } else {
            cell.subTitleLbl.text = addOnsBooking?.uniqueTickets[indexPath.row].addons.description ?? ""
            cell.titleLbl.text = addOnsBooking?.uniqueTickets[indexPath.row].addons.name ?? ""
            cell.quantityLbl.text = "\(addOnsBooking?.uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
        }
        cell.selectionStyle = .none
        
        return cell
    }
}
