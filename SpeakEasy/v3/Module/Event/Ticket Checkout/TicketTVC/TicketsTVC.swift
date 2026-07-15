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

    // MARK: - Event Ticket Callbacks

    var onPlusTap: ((EventTicket) -> Void)?
    var onMinusTap: ((EventTicket) -> Void)?
    var onRSVPTap: ((EventTicket) -> Void)?
    var onDescriptionToggle: (() -> Void)?
    var isFromGroupTicket: Bool = false

    // MARK: - Cover Ticket Callbacks

    private var onCoverPlusTap: (() -> Void)?
    private var onCoverMinusTap: (() -> Void)?

    // MARK: - Private State

    private var currentTicket: EventTicket?
    private let collapsedLines = 3
    private var isDescriptionExpanded = false
    private var isLinkDisabled = false
    private var isCoverTicketMode = false
    private let ticketBackgroundGradientLayer = CAGradientLayer()

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        setupTicketBackgroundGradient()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateTicketBackgroundGradientFrame()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        releaseResourcesForReuse()
        resetUI()
    }

    deinit {
        releaseResourcesForReuse()
        ticketBackgroundGradientLayer.removeFromSuperlayer()
    }

    private func releaseResourcesForReuse() {

        currentTicket = nil

        onPlusTap = nil
        onMinusTap = nil
        onRSVPTap = nil
        onDescriptionToggle = nil

        onCoverPlusTap = nil
        onCoverMinusTap = nil

        isDescriptionExpanded = false
        isLinkDisabled = false
        isCoverTicketMode = false
        isFromGroupTicket = false

        shimmerView.stopAnimating()
        shimmerView.isHidden = true
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(false, animated: false)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: false)
    }

    // MARK: - Reset

    private func resetUI() {
        setupTicketBackgroundGradient()

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

        bgView.layer.cornerRadius = 10
        updateTicketBackgroundGradientFrame()
        topConstraint.constant = 12
        topSapraterView.isHidden = true
    }

    private func setupTicketBackgroundGradient() {
        bgView.backgroundColor = .clear

        ticketBackgroundGradientLayer.colors = [
            UIColor(hex: "#282828", alpha: 0.37).cgColor,
            UIColor(hex: "#000000", alpha: 0.25).cgColor
        ]
        ticketBackgroundGradientLayer.locations = [0, 1]
        ticketBackgroundGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        ticketBackgroundGradientLayer.endPoint = CGPoint(x: 1, y: 1)

        if ticketBackgroundGradientLayer.superlayer == nil {
            bgView.layer.insertSublayer(ticketBackgroundGradientLayer, at: 0)
        }

        updateTicketBackgroundGradientFrame()
    }

    private func updateTicketBackgroundGradientFrame() {
        ticketBackgroundGradientLayer.frame = bgView.bounds
        ticketBackgroundGradientLayer.cornerRadius = bgView.layer.cornerRadius
    }

    func applyGroupTicketSpacing(isFirst: Bool) {
        isFromGroupTicket = true
        topConstraint.constant = isFirst ? 0 : 12
        topSapraterView.isHidden = true
    }

    // MARK: - Shimmer

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

    // MARK: - Shared Description Setup

    private func setupDescription(_ text: String?) {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !trimmed.isEmpty else {
            discriptionLbl.isHidden = true
            viewMoreBtnView.isHidden = true
            return
        }

        discriptionLbl.isHidden = false
        discriptionLbl.text = trimmed
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

    // MARK: - Cover Ticket Configure

    func configure(
        coverTicketName: String,
        description: String?,
        price: Double,
        extraFees: Double?,
        selectedCount: Int,
        currency: String,
        currencyPosition: String?,
        whiteLabelColor: String?,
        isDescriptionExpanded: Bool,
        onPlus: (() -> Void)?,
        onMinus: (() -> Void)?
    ) {
        // Mark as cover ticket mode
        isCoverTicketMode = true

        // Clear event ticket state
        currentTicket = nil
        onPlusTap = nil
        onMinusTap = nil
        onRSVPTap = nil

        // Store cover ticket closures
        onCoverPlusTap = onPlus
        onCoverMinusTap = onMinus
        self.isDescriptionExpanded = isDescriptionExpanded

        resetUI()

        // Title
        titleLbl.text = coverTicketName

        // Price + selection UI
        if price == 0 {
            priceLbl.text = "FREE"
        } else {
            priceLbl.text = CurrencyFormatter.amount(price, symbol: currency, position: currencyPosition)
        }

        rsvpBtnView.isHidden = true
        plusView.isHidden = false
        plusBtn.isHidden = false

        if selectedCount > 0 {
            quantityLbl.isHidden = false
            quantityLbl.text = "\(selectedCount)"
            minusView.isHidden = false
        }

        // Extra fees
        let fee = extraFees ?? 0
        if fee > 0 {
            inclFeesLbl.isHidden = false
            inclFeesLbl.text = "Incl. \(CurrencyFormatter.amount(fee, symbol: currency, position: currencyPosition)) in fees"
        } else {
            inclFeesLbl.isHidden = true
        }

        // Cover tickets never show sold out or tickets left
        soldOutView.isHidden = true
        ticketLeftLbl.isHidden = true
        setupTicketBackgroundGradient()

        // Description
        setupDescription(description)
    }

    // MARK: - Event Ticket Configure

    func configure(
        ticket: EventTicket,
        currency: String,
        currencyPosition: String?,
        whiteLabelColor: String?,
        eventTicketSetting: EventTicketSettings?,
        isDescriptionExpanded: Bool = false,
        isLinkDisabled: Bool = false
    ) {
        // Mark as event ticket mode
        isCoverTicketMode = false

        // Clear cover ticket state
        onCoverPlusTap = nil
        onCoverMinusTap = nil

        self.currentTicket = ticket
        self.isDescriptionExpanded = isDescriptionExpanded
        self.isLinkDisabled = isLinkDisabled

        resetUI()

        if isSoldOut(ticket) {
            applySoldOutUI(ticket: ticket)
            setupDescription(ticket.tierDescription)
            return
        }

        applyNormalUI(
            ticket: ticket,
            currency: currency,
            currencyPosition: currencyPosition,
            whiteLabelColor: whiteLabelColor,
            shouldShowLeftLabel: !(eventTicketSetting?.hideLowInventory ?? true)
        )

        if isLinkDisabled {
            applyComingSoonUI()
        }
    }

    // MARK: - Event Ticket Private UI

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
        quantityLbl.font = Constant.Font.geistRegular(size: 12)
        minusView.isHidden = true
        plusView.isHidden = true
        rsvpBtnView.isHidden = true
    }

    private func applyNormalUI(
        ticket: EventTicket,
        currency: String,
        currencyPosition: String?,
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
        } else {
            priceLbl.text = CurrencyFormatter.amount(Double(price), symbol: currency, position: currencyPosition)
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
            inclFeesLbl.text = "Incl. \(CurrencyFormatter.amount(fee, symbol: currency, position: currencyPosition)) in fees"
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

    func hideMinusView() {
        minusView.isHidden = true
        quantityLbl.isHidden = true
    }

    // MARK: - IBActions

    @IBAction func onClickMinusBtn(_ sender: Any) {
        if isCoverTicketMode {
            onCoverMinusTap?()
            return
        }
        guard !isLinkDisabled else { return }
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        onMinusTap?(ticket)
    }

    @IBAction func onClickPlusBtn(_ sender: Any) {
        if isCoverTicketMode {
            onCoverPlusTap?()
            return
        }
        guard !isLinkDisabled else { return }
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        onPlusTap?(ticket)
    }

    @IBAction func onClickRSVPBtn(_ sender: Any) {
        if isCoverTicketMode {
            // FREE cover ticket — treat as plus tap
            onCoverPlusTap?()
            return
        }
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
