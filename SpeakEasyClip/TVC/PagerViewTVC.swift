//
//  PagerViewTVC.swift
//  SpeakEasyClip
//
//  Created by MAC on 05/03/24.
//

import UIKit
import FSPagerView

class PagerViewTVC: FSPagerViewCell {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var ticketsTableView: UITableView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var ticketCodeView: UIView!
    @IBOutlet weak var backupCode: UILabel!
    @IBOutlet weak var bookingDateTime: UILabel!
    
    var uniqueTickets = [CoverTicket]()
    var addOnsBookingHasItem = [UpSellTicket]()
    
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

extension PagerViewTVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uniqueTickets.count != 0 ? uniqueTickets.count : addOnsBookingHasItem.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        cell.contentView.backgroundColor = .clear
        if uniqueTickets.count != 0 {
            cell.titleLbl.text = uniqueTickets[indexPath.row].customName ?? "" == "" ? uniqueTickets[indexPath.row].name : uniqueTickets[indexPath.row].customName
            cell.subTitleLbl.text = uniqueTickets[indexPath.row].description
            cell.quantityLbl.text = "\(uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
        } else {
            cell.subTitleLbl.text = addOnsBookingHasItem[indexPath.row].addOns?.description
            cell.titleLbl.text = addOnsBookingHasItem[indexPath.row].addOns?.name
            cell.quantityLbl.text = "\(addOnsBookingHasItem[indexPath.row].selectedQuantity ?? 0)x"
        }
        cell.selectionStyle = .none
        
        return cell
    }
}
