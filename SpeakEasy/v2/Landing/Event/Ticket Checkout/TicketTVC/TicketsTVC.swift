//
//  TicketsTVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 06/02/26.
//

import UIKit

class TicketsTVC: UITableViewCell {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var quantityLbl: UILabel!
    @IBOutlet weak var minusBtn: UIButton!
    @IBOutlet weak var plusBtn: UIButton!
    @IBOutlet weak var minusView: UIView!
    @IBOutlet weak var plusView: UIView!
    @IBOutlet weak var ticketLeftLbl: UILabel!
    @IBOutlet weak var rsvpBtnView: UIView!
    @IBOutlet weak var inclFeesLbl: UILabel!
    @IBOutlet weak var rsvpBtn: UIButton!
    
    var onPlusTap: ((EventTicket) -> Void)?
    var onMinusTap: ((EventTicket) -> Void)?
    var onRSVPTap: ((EventTicket) -> Void)?
    private var currentTicket: EventTicket?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
          super.prepareForReuse()
          currentTicket = nil
          onPlusTap = nil
          onMinusTap = nil
          onRSVPTap = nil
        quantityLbl.isHidden = true
        minusView.isHidden = true
        rsvpBtnView.isHidden = true
        plusView.isHidden = false
        plusBtn.isEnabled = true
        plusView.alpha = 1.0
        inclFeesLbl.isHidden = true
        ticketLeftLbl.isHidden = true

      }

    func configure(ticket: EventTicket, currency: String, whiteLabelColor: String?) {
        self.currentTicket = ticket
        titleLbl.text = ticket.tierName
        
        let lowestPrice = ticket.price ?? 0
        
        if lowestPrice == 0 {
            priceLbl.text = "FREE"
            self.rsvpBtnView.isHidden = false
            self.plusView.isHidden = true
        } else {
            priceLbl.text = "\(currency)\(Double(lowestPrice).decimalFormat(true))"
            self.rsvpBtnView.isHidden = true
            
            self.plusBtn.isHidden = false
            self.plusView.isHidden = false
            if let remaining = ticket.remainingQuantity, let selectedTicket = ticket.selectedTicketCount, remaining <= selectedTicket {
                plusView.isHidden = false
            }
            if let count  = ticket.selectedTicketCount, count != 0 {
                quantityLbl.isHidden = false
                quantityLbl.text = "\(count)"
                minusView.isHidden = false
            }
        }
        
        let fee = ticket.extraFees ?? 0
        let symbol = currency

        if fee > 0 {
            inclFeesLbl.isHidden = false
            inclFeesLbl.text = "(Incl. \(symbol)\(fee.decimalFormat(true)) in fees)"
        } else {
            inclFeesLbl.isHidden = true
        }
        
        if let remaining = ticket.remainingQuantity {

            ticketLeftLbl.isHidden = false
            if remaining == 0 {
                ticketLeftLbl.text = "Sold Out"
            } else {
                ticketLeftLbl.text = "Only \(remaining) left"
            }
            
            if let hex = whiteLabelColor {
                  let color = UIColor(hex: hex)
                ticketLeftLbl.textColor = color
            }

        } else {
            ticketLeftLbl.isHidden = true
        }

    }
    
    func showMinusView(ticket: EventTicket) {
//        self.minusView.isHidden = ticket.quantity < 0
//        self.quantityLbl.isHidden = ticket.quantity < 0
    }
    
    func hideMinusView() {
        self.minusView.isHidden = true
        self.quantityLbl.isHidden = true
    }
    
    @IBAction func onClickMinusBtn(_ sender: Any) {
        guard let t = currentTicket else { return }
             onMinusTap?(t)
        
    }
    
    @IBAction func onClickPlusBtn(_ sender: Any) {
        guard let t = currentTicket else { return }
           onPlusTap?(t)
    }
    
    @IBAction func onClickRSVPBtn(_ sender: Any) {
        guard let t = currentTicket else { return }
           onRSVPTap?(t)
    }
}

