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
    @IBOutlet weak var guestName: UILabel!
    @IBOutlet weak var openTabBtnHeight: NSLayoutConstraint!
    @IBOutlet weak var openTabBtn: UIButton!
    
    var uniqueTickets = [CoverTicket]()
    var addOnsBookingHasItem = [UpSellTicket]()
    var booking: Booking?
    var addOnsBooking: AddOnsBooking?
    var barTabBooking: BarTabBooking?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if VenueImageManager.shared.customQRData != nil && VenueImageManager.shared.isEnableCoverTicketViewSettings == true {
            bgView.backgroundColor = UIColor(hex: VenueImageManager.shared.customQRData?.cardCustomColor ?? "")
        }
        ticketsTableView.delegate = self
        ticketsTableView.dataSource = self
        ticketsTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(qrImageTapped))
        containerView.addGestureRecognizer(tapGesture)
        super.contentView.layer.shadowColor = UIColor.clear.cgColor
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
        cell.checkInProgress.layer.cornerRadius = 5
        if uniqueTickets.count != 0 {
            cell.titleLbl.text = uniqueTickets[indexPath.row].customName ?? "" == "" ? uniqueTickets[indexPath.row].displayName : uniqueTickets[indexPath.row].displayCustomName
            cell.subTitleLbl.text = uniqueTickets[indexPath.row].displayDescription
            cell.quantityLbl.text = "\(uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
            if let barBooking = barTabBooking {
                cell.checkInProgressBarView.isHidden = false
                let checkInCount = barBooking.uniqueTickets[indexPath.row].checkedInQuantity ?? 0
                cell.checkInCount.text = "\(checkInCount)/\(barBooking.uniqueTickets[indexPath.row].selectedQuantity ?? 0)"
                cell.checkInProgress.setProgress(Float(checkInCount) / Float(barBooking.uniqueTickets[indexPath.row].selectedQuantity ?? 0), animated: false)
            } else {
                if let index = booking?.uniqueTickets.firstIndex(where: {$0.ticketId == uniqueTickets[indexPath.row].id }) {
                    cell.checkInProgressBarView.isHidden = false
                    let checkInCount = booking?.uniqueTickets[index].checkedInQuantity ?? 0
                    cell.checkInCount.text = "\(checkInCount)/\(booking?.uniqueTickets[index].selectedQuantity ?? 0)"
                    cell.checkInProgress.setProgress(Float(checkInCount) / Float(booking?.uniqueTickets[index].selectedQuantity ?? 0), animated: false)
                } else {
                    cell.checkInProgressBarView.isHidden = true
                }
            }
        } else {
            cell.subTitleLbl.text = addOnsBookingHasItem[indexPath.row].addOns?.description
            cell.titleLbl.text = addOnsBookingHasItem[indexPath.row].addOns?.name
            cell.quantityLbl.text = "\(addOnsBookingHasItem[indexPath.row].selectedQuantity ?? 0)x"
            
            if let index = addOnsBooking?.uniqueTickets.firstIndex(where: {$0.addOnsId == addOnsBookingHasItem[indexPath.row].addOnsId }) {
                cell.checkInProgressBarView.isHidden = false
                let checkInCount = addOnsBooking?.uniqueTickets[index].checkedInQuantity ?? 0
                cell.checkInCount.text = "\(checkInCount)/\(addOnsBooking?.uniqueTickets[index].selectedQuantity ?? 0)"
                cell.checkInProgress.setProgress(Float(checkInCount) / Float(addOnsBooking?.uniqueTickets[index].selectedQuantity ?? 0), animated: false)
            } else {
                cell.checkInProgressBarView.isHidden = true
            }
        }
        if VenueImageManager.shared.customQRData != nil && VenueImageManager.shared.isEnableCoverTicketViewSettings == true {
            cell.titleLbl.textColor = UIColor(hex: VenueImageManager.shared.customQRData?.fontColorB ?? "")
            cell.subTitleLbl.textColor = UIColor(hex: VenueImageManager.shared.customQRData?.fontColorB ?? "")
            cell.quantityLbl.textColor = UIColor(hex: VenueImageManager.shared.customQRData?.fontColorB ?? "")
        }
        cell.selectionStyle = .none
        return cell
    }
}
