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
    @IBOutlet weak var upsellQRBgView: UIView!
    
    var uniqueTickets = [CoverTicket]()
    var addOnsBookingHasItem = [UpSellTicket]()
    var booking: Booking?
    var addOnsBooking: AddOnsBooking?
    var barTabBooking: BarTabBooking?
    var qrBorderColorHex: String?
    
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        upsellQRBgView.layer.borderWidth = 0
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
        let shouldShowBorder = ticketCodeView.isHidden == false
        
        UIView.transition(with: containerView, duration: 1, options: .transitionFlipFromRight, animations: { [weak self] in
            guard let self = self else { return }
            
            self.ticketCodeView.isHidden.toggle()
            self.qrImage.isHidden.toggle()
            
            if !shouldShowBorder {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.upsellQRBgView.layer.borderWidth = 0
                CATransaction.commit()
            }
            
        }) { [weak self] _ in
            guard let self = self else { return }
            
            if self.ticketCodeView.isHidden {
                self.upsellQRBgView.layer.borderWidth = 0
                UIView.animate(withDuration: 0.01, delay: 0, options: .curveEaseOut) {
                    self.upsellQRBgView.layer.borderWidth = 8
                }
            }
        }
    }
    
}

extension PagerViewTVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let barBooking = barTabBooking {
            return barBooking.uniqueTickets.count
        }
        return uniqueTickets.count != 0 ? uniqueTickets.count : addOnsBookingHasItem.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        cell.contentView.backgroundColor = .clear
        cell.checkInProgress.layer.cornerRadius = 8
        if uniqueTickets.count != 0 {
            if let barBooking = barTabBooking {
                if let color = qrBorderColorHex {
                    upsellQRBgView.layer.borderColor =  UIColor(hex: color).cgColor
                    upsellQRBgView.layer.borderWidth = 8
                } else {
                    upsellQRBgView.layer.borderColor = UIColor.clear.cgColor
                }
             
                cell.titleLbl.text = barBooking.uniqueTickets[indexPath.row].coverTicket?.customName ?? "" == "" ? barBooking.uniqueTickets[indexPath.row].coverTicket?.displayName : barBooking.uniqueTickets[indexPath.row].coverTicket?.displayCustomName
                cell.subTitleLbl.text = barBooking.uniqueTickets[indexPath.row].coverTicket?.displayDescription
                cell.quantityLbl.text = "\(barBooking.uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
                
                cell.checkInProgressBarView.isHidden = false
                let checkInCount = barBooking.uniqueTickets[indexPath.row].checkedInQuantity ?? 0
                cell.checkInCount.text = "\(checkInCount)/\(barBooking.uniqueTickets[indexPath.row].selectedQuantity ?? 0)"
                cell.checkInProgress.setProgress(Float(checkInCount) / Float(barBooking.uniqueTickets[indexPath.row].selectedQuantity ?? 0), animated: false)
            } else {
               
                if let color = qrBorderColorHex {
                    upsellQRBgView.layer.borderColor =  UIColor(hex: color).cgColor
                    upsellQRBgView.layer.borderWidth = 8
                } else {
                    upsellQRBgView.layer.borderColor = UIColor.clear.cgColor
                }
              
                
                cell.titleLbl.text = uniqueTickets[indexPath.row].customName ?? "" == "" ? uniqueTickets[indexPath.row].displayName : uniqueTickets[indexPath.row].displayCustomName
                cell.subTitleLbl.text = uniqueTickets[indexPath.row].displayDescription
                cell.quantityLbl.text = "\(uniqueTickets[indexPath.row].selectedQuantity ?? 0)x"
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
            upsellQRBgView.layer.borderColor = UIColor(hex: "#F1CE72").cgColor
            upsellQRBgView.layer.borderWidth = 8
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
