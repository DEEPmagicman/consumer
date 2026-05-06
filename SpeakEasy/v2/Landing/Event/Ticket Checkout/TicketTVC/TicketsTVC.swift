//
//  TicketsTVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 06/02/26.
//

import UIKit
import MHLoadingButton

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
//    @IBOutlet weak var rsvpBtn: LoadingButton!
    @IBOutlet weak var soldOutView: UIView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var discriptionLbl: UILabel!
    @IBOutlet weak var viewMoreBtnView: UIView!
    @IBOutlet weak var viewMoreBtn: UIButton!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var comingSoonView: UIView!
    @IBOutlet weak var topSapraterView: UIView!
    @IBOutlet weak var shimmerView: ShimmerView!
    @IBOutlet weak var rsvpBtn: UIButton!
    
    var onPlusTap: ((EventTicket) -> Void)?
    var onMinusTap: ((EventTicket) -> Void)?
    var onRSVPTap: ((EventTicket) -> Void)?
    var onDescriptionToggle: (() -> Void)?
    var isFromGroupTicket: Bool = false

    private var currentTicket: EventTicket?
    private let collapsedLines = 3
    private var isDescriptionExpanded = false
    private var isLinkDisabled = false

    override func prepareForReuse() {
        super.prepareForReuse()
        currentTicket = nil
        onPlusTap = nil
        onMinusTap = nil
        onRSVPTap = nil
        onDescriptionToggle = nil
        isDescriptionExpanded = false
        isLinkDisabled = false
        shimmerView.stopAnimating()
        shimmerView.isHidden = true
        resetUI()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(false, animated: false)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: false)
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
        minusBtn.isEnabled = true
        minusView.alpha = 1.0
        rsvpBtn.isEnabled = true
        rsvpBtnView.isHidden = true
        rsvpBtnView.alpha = 1.0
        inclFeesLbl.isHidden = true
        ticketLeftLbl.isHidden = true
        soldOutView.isHidden = true
        contentView.alpha = 1.0

        discriptionLbl.text = nil
        discriptionLbl.numberOfLines = collapsedLines
        discriptionLbl.isHidden = true

        viewMoreBtnView.isHidden = true
        viewMoreBtn.setTitle("View More", for: .normal)

        bgView.layer.borderWidth = 0
        bgView.layer.borderColor = UIColor.clear.cgColor
        
        if isFromGroupTicket {
            bgView.layer.cornerRadius = 0
            topConstraint.constant = 0
            topSapraterView.isHidden = false
        } else {
            bgView.layer.cornerRadius = 10
            topConstraint.constant = 12
            topSapraterView.isHidden = true
        }
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
        remainingQuantity(for: ticket) <= 0
    }

    private func applySoldOutUI(ticket: EventTicket) {
        let attributedText = NSAttributedString(
            string: ticket.tierName,
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

    private func applyComingSoonUI() {
        quantityLbl.isHidden = false
        quantityLbl.text = "Coming soon"
        minusView.isHidden = true
        plusView.isHidden = true
        rsvpBtnView.isHidden = true
    }
    
    func showShimmer() {
        shimmerView.isHidden = false
        bgView.isHidden = true
        shimmerView.startAnimating()
    }
    
    func hideShimmer() {
        shimmerView.stopAnimating()
        shimmerView.isHidden = true
        bgView.isHidden = false
    }

    private func setupDescription(_ text: String?) {
        let descriptionText = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !descriptionText.isEmpty else {
            discriptionLbl.isHidden = true
            viewMoreBtnView.isHidden = true
            return
        }

        discriptionLbl.isHidden = false
        discriptionLbl.text = descriptionText
        discriptionLbl.numberOfLines = isDescriptionExpanded ? 0 : collapsedLines
        viewMoreBtn.setTitle(isDescriptionExpanded ? "View Less" : "View More", for: .normal)

        layoutIfNeeded()

        let fullHeight = discriptionLbl.sizeThatFits(
            CGSize(width: discriptionLbl.frame.width, height: .greatestFiniteMagnitude)
        ).height

        let collapsedHeight = discriptionLbl.font.lineHeight * CGFloat(collapsedLines)

        if fullHeight > collapsedHeight {
            viewMoreBtnView.isHidden = false
        } else {
            viewMoreBtnView.isHidden = true
            discriptionLbl.numberOfLines = 0
        }
    }

    private func applyNormalUI(
        ticket: EventTicket,
        currency: String,
        whiteLabelColor: String?,
        shouldShowLeftLabel: Bool
    ) {
        titleLbl.attributedText = nil
        titleLbl.text = ticket.tierName

        let price = ticket.price ?? 0
        setupDescription(ticket.tierDescription)

        if price == 0 {
            priceLbl.text = "FREE"
            rsvpBtnView.isHidden = false
            plusView.isHidden = true
//            rsvpBtn.indicator = MaterialLoadingIndicator(color: .white)
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
        eventTicketSetting: EventTicketSettings?,
        isDescriptionExpanded: Bool = false,
        isLinkDisabled: Bool = false
    ) {
        self.currentTicket = ticket
        self.isDescriptionExpanded = isDescriptionExpanded
        self.isLinkDisabled = isLinkDisabled
        resetUI()

        let isSelected = (ticket.selectedTicketCount ?? 0) > 0
        bgView.layer.borderWidth = (isSelected && !isFromGroupTicket && !isLinkDisabled) ? 1 : 0
        if let hex = whiteLabelColor {
            bgView.layer.borderColor = UIColor(hex: hex).cgColor
        } else {
            bgView.layer.borderColor = UIColor.white.cgColor
        }
        
        if isSoldOut(ticket) {
            applySoldOutUI(ticket: ticket)
            setupDescription(ticket.tierDescription)
            return
        }

        applyNormalUI(
            ticket: ticket,
            currency: currency,
            whiteLabelColor: whiteLabelColor,
            shouldShowLeftLabel: !(eventTicketSetting?.hideLowInventory ?? true)
        )

        if isLinkDisabled {
            applyComingSoonUI()
        }
    }

    func hideMinusView() {
        minusView.isHidden = true
        quantityLbl.isHidden = true
    }

    @IBAction func onClickMinusBtn(_ sender: Any) {
        guard !isLinkDisabled else { return }
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        onMinusTap?(ticket)
    }

    @IBAction func onClickPlusBtn(_ sender: Any) {
        guard !isLinkDisabled else { return }
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        onPlusTap?(ticket)
    }

    @IBAction func onClickRSVPBtn(_ sender: Any) {
        guard !isLinkDisabled else { return }
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        onRSVPTap?(ticket)
    }

    @IBAction func onClickViewMoreBtn(_ sender: Any) {
        isDescriptionExpanded.toggle()
        discriptionLbl.numberOfLines = isDescriptionExpanded ? 0 : collapsedLines
        viewMoreBtn.setTitle(isDescriptionExpanded ? "View Less" : "View More", for: .normal)
        onDescriptionToggle?()
    }
}

//import UIKit
//
//final class TicketShimmerView: UIView {
//
//    private let titleLine    = ShimmerView2()
//    private let priceLine    = ShimmerView2()
//    private let feesLine     = ShimmerView2()
//    private let bottomLabel  = ShimmerView2()
//
//    private var didSetup = false
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        guard !didSetup, bounds.width > 0 else { return }
//        didSetup = true
//        setupUI()
//    }
//
//    private func setupUI() {
//        backgroundColor = UIColor(white: 0.13, alpha: 1)
//        layer.cornerRadius = 10
//        clipsToBounds = true
//
//        let W    = bounds.width
//        let H    = bounds.height
//        let pad: CGFloat = 14
//
//        let titleW: CGFloat = W * 0.45
//        let titleH: CGFloat = 15
//        titleLine.frame = CGRect(x: pad, y: pad, width: titleW, height: titleH)
//        titleLine.layer.cornerRadius = 6
//        titleLine.clipsToBounds = true
//
//        let priceW: CGFloat = 70
//        let priceH: CGFloat = 15
//        priceLine.frame = CGRect(
//            x: W - pad - priceW,
//            y: pad,
//            width: priceW,
//            height: priceH
//        )
//        priceLine.layer.cornerRadius = 6
//        priceLine.clipsToBounds = true
//
//        // ── RIGHT BELOW PRICE: "(Incl. $5.02 in fees)" ──
//        let feesW: CGFloat = 110
//        let feesH: CGFloat = 11
//        feesLine.frame = CGRect(
//            x: W - pad - feesW,
//            y: pad + priceH + 6,
//            width: feesW,
//            height: feesH
//        )
//        feesLine.layer.cornerRadius = 5
//        feesLine.clipsToBounds = true
//
//        // ── BOTTOM RIGHT: "Only X left" label ──
//        let botW: CGFloat = 90
//        let botH: CGFloat = 11
//        bottomLabel.frame = CGRect(
//            x: W - pad - botW,
//            y: H - pad - botH,
//            width: botW,
//            height: botH
//        )
//        bottomLabel.layer.cornerRadius = 5
//        bottomLabel.clipsToBounds = true
//
//        [titleLine, priceLine, feesLine, bottomLabel].forEach { addSubview($0) }
//    }
//
//    // MARK: - Control
//
//    func startAnimating() {
//        isHidden = false
//        [titleLine, priceLine, feesLine, bottomLabel].forEach { $0.startAnimating() }
//    }
//
//    func stopAnimating() {
//        [titleLine, priceLine, feesLine, bottomLabel].forEach { $0.stopAnimating() }
//        isHidden = true
//    }
//}
