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
    @IBOutlet weak var soldOutView: UIView!
//    @IBOutlet weak var discriptionLbl: UILabel!
    
    var onPlusTap: ((EventTicket) -> Void)?
    var onMinusTap: ((EventTicket) -> Void)?
    var onRSVPTap: ((EventTicket) -> Void)?
    private var currentTicket: EventTicket?

    override func prepareForReuse() {
        super.prepareForReuse()
        currentTicket = nil
        onPlusTap = nil
        onMinusTap = nil
        onRSVPTap = nil

        resetUI()
    }

    private func resetUI() {
        titleLbl.attributedText = nil
        titleLbl.text = nil
        titleLbl.isHidden = false
        priceLbl.isHidden = false
        quantityLbl.isHidden = true
        minusView.isHidden = true
        plusView.isHidden = false
        plusBtn.isHidden = false
        plusBtn.isEnabled = true
        plusView.alpha = 1.0
        rsvpBtnView.isHidden = true
        inclFeesLbl.isHidden = true
        ticketLeftLbl.isHidden = true
        soldOutView.isHidden = true
    }

    private func remainingQuantity(for ticket: EventTicket) -> Int {
        if let remaining = ticket.remainingQuantity {
            return remaining
        }
        let issued = ticket.issuedUnits ?? 0
        let sold = ticket.soldUnits ?? 0
        return max(issued - sold, 0)
    }

    private func isSoldOut(_ ticket: EventTicket) -> Bool {
        return remainingQuantity(for: ticket) <= 0
    }

    private func applySoldOutUI(ticket: EventTicket) {
        let text = ticket.tierName

        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.white
            ]
        )

        titleLbl.attributedText = attributedText

        soldOutView.isHidden = false
        priceLbl.isHidden = true
        quantityLbl.isHidden = true
        minusView.isHidden = true
        plusView.isHidden = true
        rsvpBtnView.isHidden = true
        inclFeesLbl.isHidden = true
        ticketLeftLbl.isHidden = true
    }

    private func applyNormalUI(
        ticket: EventTicket,
        currency: String,
        whiteLabelColor: String?,
        shouldShowLeftLabel: Bool
    ) {
        titleLbl.text = ticket.tierName
        let price = ticket.price ?? 0

        if price == 0 {
            priceLbl.text = "FREE"
            rsvpBtnView.isHidden = false
            plusView.isHidden = true
        } else {
            priceLbl.text = "\(currency)\(Double(price).decimalFormat(true))"
            rsvpBtnView.isHidden = true
            plusBtn.isHidden = false
            plusView.isHidden = false

            if let count = ticket.selectedTicketCount, count > 0 {
                quantityLbl.isHidden = false
                quantityLbl.text = "\(count)"
                minusView.isHidden = false
            }
        }

        let fee = ticket.extraFees ?? 0
        if fee > 0 {
            inclFeesLbl.isHidden = false
            inclFeesLbl.text = "(Incl. \(currency)\(fee.decimalFormat(true)) in fees)"
        } else {
            inclFeesLbl.isHidden = true
        }

        let remaining = remainingQuantity(for: ticket)

        if shouldShowLeftLabel && remaining > 0 && remaining < 20 {

            ticketLeftLbl.isHidden = false
            ticketLeftLbl.text = "Only \(remaining) left"

            if let hex = whiteLabelColor {
                ticketLeftLbl.textColor = UIColor(hex: hex)
            }

        } else {
            ticketLeftLbl.isHidden = true
        }
    }

    func configure(
        ticket: EventTicket,
        currency: String,
        whiteLabelColor: String?,
        eventTicketSetting: EventTicketSettings?
    ) {
        self.currentTicket = ticket
        resetUI()

        let soldOut = isSoldOut(ticket)
        if soldOut {
            applySoldOutUI(
                ticket: ticket
            )
        } else {
            applyNormalUI(
                ticket: ticket,
                currency: currency,
                whiteLabelColor: whiteLabelColor,
                shouldShowLeftLabel: !(eventTicketSetting?.hideLowInventory ?? true)
            )
        }
    }

    func hideMinusView() {
        minusView.isHidden = true
        quantityLbl.isHidden = true
    }

    @IBAction func onClickMinusBtn(_ sender: Any) {
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        onMinusTap?(ticket)
    }

    @IBAction func onClickPlusBtn(_ sender: Any) {
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        onPlusTap?(ticket)
    }

    @IBAction func onClickRSVPBtn(_ sender: Any) {
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        onRSVPTap?(ticket)
    }
}
