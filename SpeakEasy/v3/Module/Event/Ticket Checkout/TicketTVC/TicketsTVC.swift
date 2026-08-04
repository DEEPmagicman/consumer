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
    @IBOutlet weak var rsvpBtn: LoadingButton!

    // MARK: - Event Ticket Callbacks

    var onPlusTap: ((EventTicket) -> Void)?
    var onMinusTap: ((EventTicket) -> Void)?
    var onRSVPTap: ((EventTicket, TicketsTVC) -> Void)?
    var onDescriptionToggle: (() -> Void)?
    var isFromGroupTicket: Bool = false

    // MARK: - Cover Ticket Callbacks

    private var onCoverPlusTap: (() -> Void)?
    private var onCoverMinusTap: (() -> Void)?

    // MARK: - Private State

    private var currentTicket: EventTicket?
    private let descriptionPreviewLimitLines = 2
    private let collapsedDescriptionVisibleLines = 3
    private var isDescriptionExpanded = false
    private var currentDescriptionText = ""
    private var lastDescriptionMeasurementWidth: CGFloat = 0
    private var lastDescriptionMeasurementText = ""
    private var needsDescriptionMeasurement = false
    private var cachedDescriptionNeedsToggle = false
    private var isLinkDisabled = false
    private var isCoverTicketMode = false
    private var backgroundOverrideColor: UIColor?
    private let ticketBackgroundGradientLayer = CAGradientLayer()
    private let descriptionFadeMaskLayer = CAGradientLayer()

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        bgView.layer.cornerRadius = 20
        bgView.layer.cornerCurve = .continuous
        bgView.clipsToBounds = true
        setupTicketBackgroundGradient()
        configureDescriptionTypography()
        rsvpBtn.indicator = MaterialLoadingIndicator(color: .white)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateTicketBackgroundGradientFrame()
        updateDescriptionToggleVisibilityIfNeeded()
        updateDescriptionFadeMaskFrame()
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
        currentDescriptionText = ""
        lastDescriptionMeasurementWidth = 0
        lastDescriptionMeasurementText = ""
        needsDescriptionMeasurement = false
        cachedDescriptionNeedsToggle = false
        isLinkDisabled = false
        isCoverTicketMode = false
        isFromGroupTicket = false
        backgroundOverrideColor = nil

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
        configureRSVPButtonStyle()
        rsvpBtn.hideLoader()
        rsvpBtnView.isHidden = true
        rsvpBtnView.alpha = 1.0
        inclFeesLbl.isHidden = true
        ticketLeftLbl.isHidden = true
        soldOutView.isHidden = true
        comingSoonView.isHidden = true
        comingSoonView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        comingSoonView.layer.cornerRadius = 18
        comingSoonView.layer.borderWidth = 1
        comingSoonView.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        configureComingSoonLabel()
        contentView.alpha = 1.0

        discriptionLbl.text = nil
        discriptionLbl.numberOfLines = collapsedDescriptionVisibleLines
        discriptionLbl.lineBreakMode = .byTruncatingTail
        discriptionLbl.layer.mask = nil
        discriptionLbl.isHidden = true

        viewMoreBtnView.isHidden = true
        viewMoreBtn.setTitle("View more", for: .normal)

        bgView.layer.cornerRadius = 20
        bgView.layer.cornerCurve = .continuous
        bgView.clipsToBounds = true
        updateTicketBackgroundGradientFrame()
        topConstraint.constant = 12
        topSapraterView.isHidden = true
    }

    private func setupTicketBackgroundGradient() {
        if let backgroundOverrideColor {
            ticketBackgroundGradientLayer.removeFromSuperlayer()
            bgView.backgroundColor = backgroundOverrideColor
            return
        }

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

    private func configureDescriptionTypography() {
        discriptionLbl.font = Constant.Font.geistRegular(size: 12)
        discriptionLbl.textColor = UIColor(hex: "#D2D5DB")

        viewMoreBtn.titleLabel?.font = Constant.Font.geistMedium(size: 12)
        viewMoreBtn.setTitleColor(UIColor(hex: "#D2D5DB"), for: .normal)
        viewMoreBtn.contentHorizontalAlignment = .leading
        viewMoreBtn.contentEdgeInsets = .zero

        descriptionFadeMaskLayer.startPoint = CGPoint(x: 0.5, y: 0)
        descriptionFadeMaskLayer.endPoint = CGPoint(x: 0.5, y: 1)
        descriptionFadeMaskLayer.colors = [
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.black.withAlphaComponent(0).cgColor
        ]
        descriptionFadeMaskLayer.locations = [0, 0.72, 1]
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
        currentDescriptionText = trimmed
        lastDescriptionMeasurementWidth = 0
        lastDescriptionMeasurementText = ""
        needsDescriptionMeasurement = !trimmed.isEmpty
        cachedDescriptionNeedsToggle = false

        guard !trimmed.isEmpty else {
            discriptionLbl.isHidden = true
            viewMoreBtnView.isHidden = true
            return
        }

        discriptionLbl.isHidden = false
        discriptionLbl.text = trimmed
        applyDescriptionExpansionState()
        viewMoreBtnView.isHidden = true
        setNeedsLayout()
        updateDescriptionToggleVisibilityIfNeeded(force: true)
    }

    private func applyDescriptionExpansionState() {
        discriptionLbl.numberOfLines = isDescriptionExpanded
            ? 0
            : collapsedDescriptionVisibleLines
        discriptionLbl.lineBreakMode = isDescriptionExpanded ? .byWordWrapping : .byTruncatingTail
        viewMoreBtn.setTitle(isDescriptionExpanded ? "View less" : "View more", for: .normal)
        updateDescriptionFadeMask()
    }

    private func updateDescriptionToggleVisibilityIfNeeded(force: Bool = false) {
        guard !currentDescriptionText.isEmpty, !discriptionLbl.isHidden else { return }

        let width = discriptionLbl.bounds.width
        guard width > 1 else {
            needsDescriptionMeasurement = true
            return
        }

        if !force,
           !needsDescriptionMeasurement,
           abs(width - lastDescriptionMeasurementWidth) < 0.5,
           lastDescriptionMeasurementText == currentDescriptionText {
            return
        }

        let needsToggle = descriptionNeedsToggle(
            text: currentDescriptionText,
            width: width
        )

        cachedDescriptionNeedsToggle = needsToggle
        needsDescriptionMeasurement = false
        lastDescriptionMeasurementWidth = width
        lastDescriptionMeasurementText = currentDescriptionText

        viewMoreBtnView.isHidden = !needsToggle
        if needsToggle {
            applyDescriptionExpansionState()
        } else {
            discriptionLbl.numberOfLines = 0
            discriptionLbl.lineBreakMode = .byWordWrapping
            viewMoreBtn.setTitle("View more", for: .normal)
            updateDescriptionFadeMask()
        }
    }

    private func updateDescriptionFadeMask() {
        let shouldFade =
            cachedDescriptionNeedsToggle &&
            !isDescriptionExpanded &&
            !discriptionLbl.isHidden

        guard shouldFade else {
            discriptionLbl.layer.mask = nil
            return
        }

        if discriptionLbl.layer.mask !== descriptionFadeMaskLayer {
            discriptionLbl.layer.mask = descriptionFadeMaskLayer
        }
        updateDescriptionFadeMaskFrame()
    }

    private func updateDescriptionFadeMaskFrame() {
        guard discriptionLbl.layer.mask === descriptionFadeMaskLayer else { return }
        descriptionFadeMaskLayer.frame = discriptionLbl.bounds
    }

    func removeDescriptionToggleControlAnimations() {
        [
            priceLbl,
            inclFeesLbl,
            ticketLeftLbl,
            quantityLbl,
            minusView,
            plusView,
            rsvpBtnView,
            soldOutView,
            comingSoonView
        ].forEach {
            removeAnimationsRecursively(from: $0)
        }
        removeAnimationsRecursively(from: bgView)
    }

    private func removeAnimationsRecursively(from view: UIView?) {
        guard let view else { return }
        view.layer.removeAllAnimations()
        view.subviews.forEach {
            removeAnimationsRecursively(from: $0)
        }
    }

    private func descriptionNeedsToggle(
        text: String,
        width: CGFloat
    ) -> Bool {
        let font = discriptionLbl.font ?? Constant.Font.geistRegular(size: 13)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let rect = (text as NSString).boundingRect(
            with: CGSize(
                width: width,
                height: .greatestFiniteMagnitude
            ),
            options: [
                .usesLineFragmentOrigin,
                .usesFontLeading
            ],
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ],
            context: nil
        )

        let previewLimitHeight = ceil(
            font.lineHeight * CGFloat(descriptionPreviewLimitLines)
        )
        return ceil(rect.height) > previewLimitHeight + 0.5
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
        backgroundColor: UIColor? = nil,
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
        self.backgroundOverrideColor = backgroundColor

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
        comingSoonView.isHidden = false
        configureComingSoonLabel()
        quantityLbl.isHidden = true
        minusView.isHidden = true
        plusView.isHidden = true
        rsvpBtnView.isHidden = true
    }

    private func configureComingSoonLabel() {
        guard let label = comingSoonView.subviews.compactMap({ $0 as? UILabel }).first else {
            return
        }

        label.text = "Coming soon"
        label.font = Constant.Font.geistRegular(size: 13)
        label.textColor = UIColor.white.withAlphaComponent(0.92)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
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
            configureRSVPButtonStyle()
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
            ticketLeftLbl.text = "Only \(remaining) Left"
            ticketLeftLbl.textColor = UIColor(hex: Event.normalizedHexColor(whiteLabelColor))
        } else {
            ticketLeftLbl.isHidden = true
        }
    }

    func hideMinusView() {
        minusView.isHidden = true
        quantityLbl.isHidden = true
    }

    private func configureRSVPButtonStyle() {
        rsvpBtn.setTitle("RSVP", for: .normal)
        rsvpBtn.setTitle("RSVP", for: .highlighted)
        rsvpBtn.setTitle("RSVP", for: .disabled)
        rsvpBtn.setTitleColor(.white, for: .normal)
        rsvpBtn.setTitleColor(.white, for: .highlighted)
        rsvpBtn.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .disabled)
        rsvpBtn.titleLabel?.font = Constant.Font.geistRegular(size: 16)
        rsvpBtn.adjustsImageWhenHighlighted = false
        rsvpBtn.alpha = 1
    }
    
    func showRSVPLoader() {
        rsvpBtn.showLoader(userInteraction: false)
    }

    func hideRSVPLoader() {
        rsvpBtn.hideLoader()
    }


    // MARK: - IBActions

    @IBAction func onClickMinusBtn(_ sender: Any) {
        if isCoverTicketMode {
            AppHaptic.stepperChanged()
            onCoverMinusTap?()
            return
        }
        guard !isLinkDisabled else { return }
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        AppHaptic.stepperChanged()
        onMinusTap?(ticket)
    }

    @IBAction func onClickPlusBtn(_ sender: Any) {
        if isCoverTicketMode {
            AppHaptic.stepperChanged()
            onCoverPlusTap?()
            return
        }
        guard !isLinkDisabled else { return }
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        AppHaptic.stepperChanged()
        onPlusTap?(ticket)
    }

    @IBAction func onClickRSVPBtn(_ sender: Any) {
        if isCoverTicketMode {
            // FREE cover ticket — treat as plus tap
            AppHaptic.primaryAction()
            onCoverPlusTap?()
            return
        }
        guard !isLinkDisabled else { return }
        guard let ticket = currentTicket else { return }
        guard !isSoldOut(ticket) else { return }
        AppHaptic.primaryAction()
        onRSVPTap?(ticket, self)
    }

    @IBAction func onClickViewMoreBtn(_ sender: Any) {
        guard cachedDescriptionNeedsToggle || !viewMoreBtnView.isHidden else { return }
        AppHaptic.selectionChanged()
        isDescriptionExpanded.toggle()
        removeDescriptionToggleControlAnimations()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        UIView.performWithoutAnimation {
            applyDescriptionExpansionState()
            layoutIfNeeded()
        }
        CATransaction.commit()
        removeDescriptionToggleControlAnimations()
        onDescriptionToggle?()
    }
}
