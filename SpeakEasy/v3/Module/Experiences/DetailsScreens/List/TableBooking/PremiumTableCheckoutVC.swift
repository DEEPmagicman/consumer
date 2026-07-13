//
//  PremiumTableCheckoutVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 26/06/26.
//

import UIKit
import StripeApplePay
import StripePaymentSheet
import PassKit

final class PremiumTableCheckoutVC: UIViewController {

    // MARK: - Input

    var queueId: String?
    var event: Event?
    var seatingAreas: [SeatingArea] = []
    var guestCount: Int = 0
    var selectedTimeSlot: TableTimeSlot?
    var selectedTimeText: String?
    var initialBooking: SeatingAreaBookingResponse?
    var promotionLinkId = ""
    var promotionLinkUniqueCode = ""

    // MARK: - Private

    private var booking: SeatingAreaBookingResponse?
    private var currentBookingId     = ""
    private var paymentIntentSecret  = ""
    private var ephemeralKey         = ""
    private var paymentId            = ""
    private var paymentSheet: PaymentSheet?
    private var isPaymentInitiated   = false
    private var isCancellingBooking  = false
    private var didCancelBooking      = false
    private var didFinishBooking      = false
    private var isFreeBooking        = false
    private var isPromoApplied       = false
    private var appliedPromo         = ""
    private var feesAndTaxes: [FeeDisplayItem] = []
    private var checkoutItems: [TableBookingCheckoutItem] = []
    private var backendSpendAgreementItems: [SpendLineItem] = []
    private var timerSeconds         = 300
    private var timer: Timer?
    private let tableService         = TableService()

    private var currency: String {
        event?.venue?.venueSettings?.currencySymbol ?? "$"
    }
    
    private var currencyPosition: String? {
        event?.venue?.venueSettings?.currencyPosition
    }

    // MARK: - UI

    private let scrollView       = UIScrollView()
    private let contentView      = UIView()

    // Header
    private let eventTitleLabel  = UILabel()
    private let eventTitleMarqueeLabel = PremiumMarqueeLabel()
    private let venueLabel       = UILabel()
    private let dateLabel        = UILabel()
    private let headerDivider    = UIView()

    // Table seating title
    private let seatingTitleRow  = UIView()
    private let seatingIcon      = UIImageView()
    private let seatingLabel     = UILabel()

    // Guest + time info tags
    private let tagsRow          = UIView()
    private let guestTag         = PremiumTagPillView()
    private let timeTag          = PremiumTagPillView()

    // Guest row
    private let guestDisplayRow  = PremiumInfoRow()

    // Note
    private let noteRow          = PremiumNoteInputView()

    // Spend agreement
    private let spendCard        = PremiumSpendAgreementView()
    private let depositBreakdownCard = PremiumSpendAgreementView()
    private let summaryPriceCard = PremiumPriceCard()
    private let priceLoadingView = PremiumTableCheckoutPriceLoadingView()
    private var noteHeightConstraint: NSLayoutConstraint?
    private var spendHeightConstraint: NSLayoutConstraint?
    private var depositBreakdownHeightConstraint: NSLayoutConstraint?
    private var priceLoadingHeightConstraint: NSLayoutConstraint?
    private var paymentTopToLoadingConstraint: NSLayoutConstraint?
    private var paymentTopToSpendConstraint: NSLayoutConstraint?
    private var paymentTopToDepositConstraint: NSLayoutConstraint?
    private var paymentTopToSummaryConstraint: NSLayoutConstraint?
    private var promoTopToLoadingConstraint: NSLayoutConstraint?
    private var promoTopToSpendConstraint: NSLayoutConstraint?
    private var promoTopToDepositConstraint: NSLayoutConstraint?
    private var promoTopToSummaryConstraint: NSLayoutConstraint?
    private var paymentHeightConstraint: NSLayoutConstraint?
    private var promoHeightConstraint: NSLayoutConstraint?
    private var checkoutPolicyHeightConstraint: NSLayoutConstraint?
    private var termsHeightConstraint: NSLayoutConstraint?
    private var venueMessageHeightConstraint: NSLayoutConstraint?
    private var emailMessageHeightConstraint: NSLayoutConstraint?
    private var termsTopToPolicyConstraint: NSLayoutConstraint?
    private var termsTopToPromoConstraint: NSLayoutConstraint?

    // Payment method
    private let paymentRow       = PremiumInfoRow()

    // Promo code
    private let promoRow         = PremiumPromoRow()

    // Agreement rows
    private let checkoutPolicyView  = PremiumAgreementView()
    private let termsAgreementView  = PremiumAgreementView()
    private let venueMessageView    = PremiumAgreementView()
    private let emailMessageView    = PremiumAgreementView()

    // Timer
    private let timerBanner      = PremiumTimerBannerView()

    // Bottom bar
    private let bottomBar        = UIView()
    private let bottomContainer  = UIView()
    private let bottomPrice      = UILabel()
    private let bottomSub        = UILabel()
    private let buyBtn           = UIButton(type: .system)
    private let buyLoader        = UIActivityIndicatorView(style: .medium)

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#111111")
        navigationItem.title = ""
        primeBooking(initialBooking)
        setupUI()
        setupSocket()
        startTimer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let isClosing = isMovingFromParent
            || isBeingDismissed
            || navigationController?.isBeingDismissed == true
        if isClosing || didFinishBooking {
            timer?.invalidate()
            BookingQueueSocketManager.shared.disconnect()
        }
        if isClosing, !didFinishBooking, !isPaymentInitiated {
            cancelCurrentBooking(returnToPrevious: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomContainer.layer.cornerRadius = 30
        buyBtn.layer.cornerRadius = buyBtn.bounds.height / 2
        updateAgreementHeights(animated: false)
    }
}

// MARK: - Setup

private extension PremiumTableCheckoutVC {

    func layoutCheckoutContent(animated: Bool) {
        guard animated else {
            view.layoutIfNeeded()
            return
        }

        view.setNeedsLayout()
        UIView.animate(
            withDuration: 0.24,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: {
                self.view.layoutIfNeeded()
            }
        )
    }

    func setupUI() {
        setupScroll()
        setupHeader()
        setupSeatingTitle()
        setupTags()
        setupGuestDisplay()
        setupNoteRow()
        setupSpendCard()
        setupDepositBreakdownCard()
        setupSummaryPriceCard()
        setupPriceLoadingView()
        setupPaymentRow()
        setupPromoRow()
        setupCheckboxes()
        setupTimerBanner()
        setupBottomBar()
        setupConstraints()
        showInitialContent()
    }

    func setupScroll() {
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }

    func setupHeader() {
        eventTitleLabel.font      = Constant.Font.geistMedium(size: 24)
        eventTitleLabel.textColor = .white
        eventTitleLabel.numberOfLines = 0
        eventTitleLabel.textAlignment = .left
        eventTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventTitleLabel)
        eventTitleMarqueeLabel.textAlignment = .left
        eventTitleMarqueeLabel.install(over: eventTitleLabel, in: contentView, height: 30, horizontalInset: 20)

        venueLabel.font      = Constant.Font.geistMedium(size: 12)
        venueLabel.textColor = UIColor.white
        venueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(venueLabel)

        dateLabel.font      = Constant.Font.geistMedium(size: 12)
        dateLabel.textColor = UIColor(hex: event?.whiteLabelColor ?? "#E8A030")
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)

        headerDivider.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        headerDivider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerDivider)
    }

    func setupSeatingTitle() {
        seatingIcon.image       = UIImage(systemName: "sparkles")
        seatingIcon.tintColor   = UIColor(hex: "#C9922B")
        seatingIcon.contentMode = .scaleAspectFit
        seatingIcon.translatesAutoresizingMaskIntoConstraints = false

        seatingLabel.text      = "Table seating"
        seatingLabel.font      = Constant.Font.geistMedium(size: 20)
        seatingLabel.textColor = .white
        seatingLabel.translatesAutoresizingMaskIntoConstraints = false

        seatingTitleRow.translatesAutoresizingMaskIntoConstraints = false
        seatingTitleRow.addSubview(seatingIcon)
        seatingTitleRow.addSubview(seatingLabel)
        contentView.addSubview(seatingTitleRow)
    }

    func setupTags() {
        tagsRow.translatesAutoresizingMaskIntoConstraints = false
        guestTag.translatesAutoresizingMaskIntoConstraints = false
        timeTag.translatesAutoresizingMaskIntoConstraints = false
        timeTag.isHidden = true
        tagsRow.addSubview(guestTag)
        tagsRow.addSubview(timeTag)
        contentView.addSubview(tagsRow)
    }

    func setupGuestDisplay() {
        guestDisplayRow.translatesAutoresizingMaskIntoConstraints = false
        guestDisplayRow.isHidden = true
        contentView.addSubview(guestDisplayRow)
    }

    func setupNoteRow() {
        noteRow.translatesAutoresizingMaskIntoConstraints = false
        noteRow.isHidden = true
        noteRow.onHeightChanged = { [weak self] height in
            self?.noteHeightConstraint?.constant = height
            self?.view.layoutIfNeeded()
        }
        contentView.addSubview(noteRow)
    }

    func setupSpendCard() {
        spendCard.translatesAutoresizingMaskIntoConstraints = false
        spendCard.isHidden = true
        spendCard.onHeightChanged = { [weak self] height, animated in
            self?.spendHeightConstraint?.constant = height
            self?.layoutCheckoutContent(animated: animated)
        }
        contentView.addSubview(spendCard)
    }

    func setupDepositBreakdownCard() {
        depositBreakdownCard.translatesAutoresizingMaskIntoConstraints = false
        depositBreakdownCard.isHidden = true
        depositBreakdownCard.onHeightChanged = { [weak self] height, animated in
            self?.depositBreakdownHeightConstraint?.constant = height
            self?.layoutCheckoutContent(animated: animated)
        }
        contentView.addSubview(depositBreakdownCard)
    }

    func setupSummaryPriceCard() {
        summaryPriceCard.translatesAutoresizingMaskIntoConstraints = false
        summaryPriceCard.isHidden = true
        contentView.addSubview(summaryPriceCard)
    }

    func setupPriceLoadingView() {
        priceLoadingView.translatesAutoresizingMaskIntoConstraints = false
        priceLoadingView.isHidden = true
        contentView.addSubview(priceLoadingView)
    }

    func setupPaymentRow() {
        paymentRow.translatesAutoresizingMaskIntoConstraints = false
        paymentRow.isHidden = true
        contentView.addSubview(paymentRow)
    }

    func setupPromoRow() {
        promoRow.translatesAutoresizingMaskIntoConstraints = false
        promoRow.isHidden = true
        promoRow.onSubmit = { [weak self] code in self?.applyPromo(code) }
        promoRow.onRemove = { [weak self] in self?.removePromo() }
        promoRow.onHeightChanged = { [weak self] height in
            self?.promoHeightConstraint?.constant = height
            self?.view.layoutIfNeeded()
        }
        contentView.addSubview(promoRow)
    }

    func setupCheckboxes() {
        checkoutPolicyView.titleText = nil
        checkoutPolicyView.showsCheckbox = false
        checkoutPolicyView.isChecked = true
        checkoutPolicyView.translatesAutoresizingMaskIntoConstraints = false
        checkoutPolicyView.isHidden = true
        checkoutPolicyView.onHeightChanged = { [weak self] _, animated in
            self?.updateAgreementHeights(animated: animated)
        }
        contentView.addSubview(checkoutPolicyView)

        termsAgreementView.titleText = nil
        termsAgreementView.showsCheckbox = true
        termsAgreementView.isChecked = true
        termsAgreementView.translatesAutoresizingMaskIntoConstraints = false
        termsAgreementView.isHidden = true
        termsAgreementView.onHeightChanged = { [weak self] _, animated in
            self?.updateAgreementHeights(animated: animated)
        }
        contentView.addSubview(termsAgreementView)

        venueMessageView.titleText = nil
        venueMessageView.showsCheckbox = true
        venueMessageView.isChecked = true
        venueMessageView.translatesAutoresizingMaskIntoConstraints = false
        venueMessageView.isHidden = true
        venueMessageView.onHeightChanged = { [weak self] _, animated in
            self?.updateAgreementHeights(animated: animated)
        }
        contentView.addSubview(venueMessageView)

        emailMessageView.titleText = nil
        emailMessageView.showsCheckbox = true
        emailMessageView.isChecked = true
        emailMessageView.translatesAutoresizingMaskIntoConstraints = false
        emailMessageView.isHidden = true
        emailMessageView.onHeightChanged = { [weak self] _, animated in
            self?.updateAgreementHeights(animated: animated)
        }
        contentView.addSubview(emailMessageView)
    }

    func setupTimerBanner() {
        timerBanner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerBanner)
    }

    func setupBottomBar() {
        bottomBar.backgroundColor = UIColor(hex: "#111111")
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        let sep = UIView()
        sep.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        sep.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(sep)

        bottomContainer.backgroundColor = .white
        bottomContainer.layer.cornerRadius = 30
        bottomContainer.layer.cornerCurve = .continuous
        bottomContainer.clipsToBounds = true
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false

        bottomPrice.font      = Constant.Font.geistMedium(size: 18)
        bottomPrice.textColor = UIColor(hex: "#121212")
        bottomPrice.translatesAutoresizingMaskIntoConstraints = false

        bottomSub.text      = "deposit incl. fees"
        bottomSub.font      = Constant.Font.geistMedium(size: 12)
        bottomSub.textColor = UIColor(hex: "#737373")
        bottomSub.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [bottomPrice, bottomSub])
        stack.axis    = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        buyBtn.setTitle("Buy now", for: .normal)
        buyBtn.setTitleColor(UIColor(hex: "#121212"), for: .normal)
        buyBtn.titleLabel?.font        = Constant.Font.geistMedium(size: 16)
        buyBtn.backgroundColor         = UIColor(hex: "#D99935")
        buyBtn.translatesAutoresizingMaskIntoConstraints = false
        buyBtn.addTarget(self, action: #selector(onBuyTapped), for: .touchUpInside)
        buyBtn.isUserInteractionEnabled = false
        buyBtn.alpha = 0.5

        buyLoader.color = UIColor(hex: "#121212")
        buyLoader.hidesWhenStopped = true
        buyLoader.translatesAutoresizingMaskIntoConstraints = false

        bottomContainer.addSubview(stack)
        bottomContainer.addSubview(buyBtn)
        buyBtn.addSubview(buyLoader)
        bottomBar.addSubview(bottomContainer)
        view.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 0),
            sep.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            sep.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            bottomContainer.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            bottomContainer.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            bottomContainer.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 22),
            bottomContainer.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -20),

            stack.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 20),
            stack.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor),

            buyBtn.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -8),
            buyBtn.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor),
            buyBtn.widthAnchor.constraint(equalToConstant: 128),
            buyBtn.heightAnchor.constraint(equalToConstant: 48),

            buyLoader.centerXAnchor.constraint(equalTo: buyBtn.centerXAnchor),
            buyLoader.centerYAnchor.constraint(equalTo: buyBtn.centerYAnchor)
        ])
    }

}

// MARK: - Constraints

private extension PremiumTableCheckoutVC {

    func setupConstraints() {
        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([

            // Scroll
            scrollView.topAnchor.constraint(equalTo: safe.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: timerBanner.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Header
            eventTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            eventTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            venueLabel.topAnchor.constraint(equalTo: eventTitleLabel.bottomAnchor, constant: 4),
            venueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            dateLabel.topAnchor.constraint(equalTo: venueLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            headerDivider.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            headerDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            headerDivider.heightAnchor.constraint(equalToConstant: 0.5),

            // Seating title row
            seatingTitleRow.topAnchor.constraint(equalTo: headerDivider.bottomAnchor, constant: 16),
            seatingTitleRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            seatingTitleRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            seatingIcon.leadingAnchor.constraint(equalTo: seatingTitleRow.leadingAnchor),
            seatingIcon.centerYAnchor.constraint(equalTo: seatingTitleRow.centerYAnchor),
            seatingIcon.widthAnchor.constraint(equalToConstant: 20),
            seatingIcon.heightAnchor.constraint(equalToConstant: 20),
            seatingIcon.topAnchor.constraint(equalTo: seatingTitleRow.topAnchor),
            seatingIcon.bottomAnchor.constraint(equalTo: seatingTitleRow.bottomAnchor),

            seatingLabel.leadingAnchor.constraint(equalTo: seatingIcon.trailingAnchor, constant: 8),
            seatingLabel.centerYAnchor.constraint(equalTo: seatingTitleRow.centerYAnchor),

            // Tags
            tagsRow.topAnchor.constraint(equalTo: seatingTitleRow.bottomAnchor, constant: 10),
            tagsRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tagsRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tagsRow.heightAnchor.constraint(equalToConstant: 28),

            guestTag.leadingAnchor.constraint(equalTo: tagsRow.leadingAnchor),
            guestTag.centerYAnchor.constraint(equalTo: tagsRow.centerYAnchor),

            timeTag.leadingAnchor.constraint(equalTo: guestTag.trailingAnchor, constant: 8),
            timeTag.centerYAnchor.constraint(equalTo: tagsRow.centerYAnchor),
            timeTag.trailingAnchor.constraint(lessThanOrEqualTo: tagsRow.trailingAnchor),

            // Guest display
            guestDisplayRow.topAnchor.constraint(equalTo: tagsRow.bottomAnchor, constant: 16),
            guestDisplayRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            guestDisplayRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            guestDisplayRow.heightAnchor.constraint(equalToConstant: 56),

            // Note
            noteRow.topAnchor.constraint(equalTo: guestDisplayRow.bottomAnchor, constant: 10),
            noteRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            noteRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Deposit breakdown
            depositBreakdownCard.topAnchor.constraint(equalTo: noteRow.bottomAnchor, constant: 10),
            depositBreakdownCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            depositBreakdownCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Spend card
            spendCard.topAnchor.constraint(equalTo: depositBreakdownCard.bottomAnchor, constant: 10),
            spendCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            spendCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Summary price card
            summaryPriceCard.topAnchor.constraint(equalTo: noteRow.bottomAnchor, constant: 10),
            summaryPriceCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            summaryPriceCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            summaryPriceCard.heightAnchor.constraint(equalToConstant: 72),

            // Price loading
            priceLoadingView.topAnchor.constraint(equalTo: noteRow.bottomAnchor, constant: 10),
            priceLoadingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            priceLoadingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Payment
            paymentRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            paymentRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Promo
            promoRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            promoRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Checkout policy
            checkoutPolicyView.topAnchor.constraint(equalTo: promoRow.bottomAnchor, constant: 10),
            checkoutPolicyView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            checkoutPolicyView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Terms
            termsAgreementView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            termsAgreementView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Venue message
            venueMessageView.topAnchor.constraint(equalTo: termsAgreementView.bottomAnchor, constant: 10),
            venueMessageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            venueMessageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Email message
            emailMessageView.topAnchor.constraint(equalTo: venueMessageView.bottomAnchor, constant: 10),
            emailMessageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailMessageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            emailMessageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            // Timer banner
            timerBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timerBanner.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            timerBanner.heightAnchor.constraint(equalToConstant: 36),

            // Bottom bar
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 106)
        ])

        paymentTopToSpendConstraint   = paymentRow.topAnchor.constraint(equalTo: spendCard.bottomAnchor, constant: 8)
        paymentTopToDepositConstraint = paymentRow.topAnchor.constraint(equalTo: depositBreakdownCard.bottomAnchor, constant: 8)
        paymentTopToSummaryConstraint = paymentRow.topAnchor.constraint(equalTo: summaryPriceCard.bottomAnchor, constant: 8)
        paymentTopToLoadingConstraint = paymentRow.topAnchor.constraint(equalTo: priceLoadingView.bottomAnchor, constant: 8)
        paymentTopToLoadingConstraint?.isActive = true

        promoTopToSpendConstraint = promoRow.topAnchor.constraint(equalTo: spendCard.bottomAnchor, constant: 10)
        promoTopToDepositConstraint = promoRow.topAnchor.constraint(equalTo: depositBreakdownCard.bottomAnchor, constant: 10)
        promoTopToSummaryConstraint = promoRow.topAnchor.constraint(equalTo: summaryPriceCard.bottomAnchor, constant: 10)
        promoTopToLoadingConstraint = promoRow.topAnchor.constraint(equalTo: priceLoadingView.bottomAnchor, constant: 10)
        promoTopToLoadingConstraint?.isActive = true

        noteHeightConstraint = noteRow.heightAnchor.constraint(equalToConstant: noteRow.preferredHeight)
        noteHeightConstraint?.isActive = true

        spendHeightConstraint = spendCard.heightAnchor.constraint(equalToConstant: 0)
        spendHeightConstraint?.isActive = true

        depositBreakdownHeightConstraint = depositBreakdownCard.heightAnchor.constraint(equalToConstant: 0)
        depositBreakdownHeightConstraint?.isActive = true

        priceLoadingHeightConstraint = priceLoadingView.heightAnchor.constraint(equalToConstant: priceLoadingView.preferredHeight)
        priceLoadingHeightConstraint?.isActive = true

        paymentHeightConstraint = paymentRow.heightAnchor.constraint(equalToConstant: 0)
        paymentHeightConstraint?.isActive = true

        promoHeightConstraint = promoRow.heightAnchor.constraint(equalToConstant: promoRow.preferredHeight)
        promoHeightConstraint?.isActive = true

        termsTopToPolicyConstraint = termsAgreementView.topAnchor.constraint(equalTo: checkoutPolicyView.bottomAnchor, constant: 10)
        termsTopToPromoConstraint = termsAgreementView.topAnchor.constraint(equalTo: promoRow.bottomAnchor, constant: 10)
        termsTopToPromoConstraint?.isActive = true

        checkoutPolicyHeightConstraint = checkoutPolicyView.heightAnchor.constraint(equalToConstant: 0)
        checkoutPolicyHeightConstraint?.isActive = true

        termsHeightConstraint = termsAgreementView.heightAnchor.constraint(equalToConstant: 0)
        termsHeightConstraint?.isActive = true

        venueMessageHeightConstraint = venueMessageView.heightAnchor.constraint(equalToConstant: 0)
        venueMessageHeightConstraint?.isActive = true

        emailMessageHeightConstraint = emailMessageView.heightAnchor.constraint(equalToConstant: 0)
        emailMessageHeightConstraint?.isActive = true
    }
}

// MARK: - Configure from API

private extension PremiumTableCheckoutVC {

    func configureHeader() {
        eventTitleMarqueeLabel.setText(event?.title)
        venueLabel.text      = event?.venue?.name.uppercased()
        let tz   = event?.venue?.useTimezone ?? ""
        let date = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, customTimeZone: tz) ?? ""
        let time = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: tz) ?? ""
        dateLabel.text      = date.isEmpty ? "" : "\(date) at \(time)"
        dateLabel.textColor = UIColor(hex: event?.whiteLabelColor ?? "#E8A030")
        buyBtn.backgroundColor = UIColor(hex: "#D99935")
        seatingLabel.text = seatingAreas.first?.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? seatingAreas.first?.name
            : "Table seating"
        configureAgreementText()
        configureSummaryPrice(total: nil)
    }

    func configureGuest() {
        let guestText = guestCount == 1 ? "1 guest" : "\(guestCount) guests"
        guestTag.configure(icon: "guestIcon", text: guestText)
        let timeText = selectedTimeText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? selectedTimeText
            : formattedTime(selectedTimeSlot?.startTime)
        if let timeText, !timeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            selectedTimeText = timeText
            timeTag.configure(style: .time, text: timeText)
            timeTag.isHidden = false
        } else {
            timeTag.isHidden = true
        }
        guestDisplayRow.configure(
            icon:  UIImage(named: "guestIcon"),
            title: "Guests",
            value: "\(guestCount)"
        )
    }

    func configureAfterBooking(_ b: SeatingAreaBookingResponse) {
        configureSelectedTableData(from: b)
        configureSummaryPrice(total: nil)
        if !paymentIntentSecret.isEmpty {
            setupStripe(secret: paymentIntentSecret, ephemeralKey: ephemeralKey)
        }

        let spendAgreement = b.content?.tableBooking?.spendAgreement
        guard let breakdown = b.content?.tableBooking?.tableBookingPriceBreakdown else {
            configureSpendAgreementCard(spendAgreement, depositBreakdown: nil)
            updatePriceSectionVisibility(hasDepositBreakdown: false)
            showContent()
            return
        }
        configureDepositBreakdown(breakdown)
        configureSpendAgreementCard(spendAgreement, depositBreakdown: breakdown)
        updateBottomPrice(breakdown.total ?? 0)
        showContent()
    }

    func configureDepositBreakdown(_ bd: PriceBreakdown) {
        let base     = bd.base     ?? 0
        let total    = bd.total    ?? 0
        let discount = bd.discount ?? 0
        let customFees = bd.tableBookingPriceBreakdownHasCustomFees ?? []

        var items: [SpendLineItem] = []
        items.append(.init(title: "Deposit", amount: base, isBold: false))

        if let gratuity = bd.gratuity, gratuity > 0 {
            items.append(.init(title: bd.gratuityName ?? "Gratuity", amount: gratuity, isBold: false))
        }
        if let tax = bd.salesTax, tax > 0 {
            items.append(.init(title: bd.salesTaxName ?? "Tax", amount: tax, isBold: false))
        }
        customFees.forEach {
            if let fee = $0.fee, fee > 0 {
                items.append(.init(title: $0.name ?? "Fee", amount: fee, isBold: false))
            }
        }
        let proc = (bd.seFees ?? 0) + (bd.stripeFees ?? 0)
        if proc > 0 {
            items.append(.init(title: "Processing Fee", amount: proc, isBold: false))
        }
        if discount > 0 {
            items.append(.init(title: "Discount", amount: -discount, isBold: false))
        }
        items.append(.init(title: "Deposit Total", amount: total, isBold: true))

        depositBreakdownCard.configure(currency: currency, currencyPosition: currencyPosition, title: "Deposit Breakdown", items: items, expanded: true)
        configureSummaryPrice(total: total)
        updatePriceSectionVisibility(hasDepositBreakdown: true)
        isFreeBooking = total <= 0
    }

    func configureSpendAgreementCard(
        _ breakdown: PriceBreakdown?,
        depositBreakdown: PriceBreakdown? = nil
    ) {
        if let breakdown {
            let items = spendAgreementItems(from: breakdown)
            if !items.isEmpty {
                backendSpendAgreementItems = items
                spendCard.configure(currency: currency, currencyPosition: currencyPosition, title: "Spend Agreement", items: items, expanded: true)
                spendCard.isHidden = false
                spendHeightConstraint?.constant = spendCard.preferredHeight
                updatePriceSectionVisibility(hasDepositBreakdown: !depositBreakdownCard.isHidden)
                return
            }
        }

        let fallbackItems = localSpendAgreementItems(depositBreakdown: depositBreakdown)
        guard !fallbackItems.isEmpty else {
            backendSpendAgreementItems = []
            spendCard.isHidden = true
            spendHeightConstraint?.constant = 0
            return
        }

        backendSpendAgreementItems = fallbackItems
        spendCard.configure(currency: currency, currencyPosition: currencyPosition, title: "Spend Agreement", items: fallbackItems, expanded: true)
        spendCard.isHidden = false
        spendHeightConstraint?.constant = spendCard.preferredHeight
        updatePriceSectionVisibility(hasDepositBreakdown: !depositBreakdownCard.isHidden)
    }

    func spendAgreementItems(from bd: PriceBreakdown) -> [SpendLineItem] {
        var items: [SpendLineItem] = []
        if let base = bd.base {
            items.append(.init(title: "Subtotal", amount: base, isBold: false))
        }
        if let gratuity = bd.gratuity, gratuity > 0 {
            items.append(.init(title: bd.gratuityName ?? "Gratuity", amount: gratuity, isBold: false))
        }
        if let tax = bd.salesTax, tax > 0 {
            items.append(.init(title: bd.salesTaxName ?? "Sales Tax", amount: tax, isBold: false))
        }
        (bd.tableBookingPriceBreakdownHasCustomFees ?? bd.customFees ?? []).forEach {
            if let fee = $0.fee, fee > 0 {
                items.append(.init(title: $0.name ?? "Fee", amount: fee, isBold: false))
            }
        }
        if let total = bd.total {
            items.append(.init(title: "Total", amount: total, isBold: true))
        }
        if let balance = bd.balanceDueAtVenue {
            items.append(.init(title: "Balance Due at Venue", amount: balance, isBold: true))
        }
        return items
    }

    func configurePaymentRow() {
        paymentRow.isHidden = true
        paymentHeightConstraint?.constant = 0
    }

    func extractLast4() -> String {
        booking?.content?.tableBooking?.paymentId?.suffix(4).description ?? "••••"
    }

    func updateBottomPrice(_ total: Double) {
        bottomPrice.text = total <= 0
            ? "Free"
            :  CurrencyFormatter.amount(total, symbol: currency, position: currencyPosition)
    }

    func showInitialContent() {
        configureHeader()
        configureGuest()

        if let booking,
           booking.status.lowercased() == "payment" ||
           booking.content?.tableBooking?.tableBookingPriceBreakdown != nil ||
           booking.content?.tableBooking?.spendAgreement != nil {
            configureAfterBooking(booking)
            return
        }

        setPriceLoadingVisible(true)
        guestDisplayRow.isHidden = false
        noteRow.isHidden         = false
        summaryPriceCard.isHidden = true
        spendCard.isHidden = true
        spendHeightConstraint?.constant = 0
        depositBreakdownCard.isHidden = true
        depositBreakdownHeightConstraint?.constant = 0
        paymentRow.isHidden      = true
        paymentHeightConstraint?.constant = 0
        promoRow.isHidden        = true
        promoHeightConstraint?.constant = 0
        checkoutPolicyView.isHidden = checkoutPolicyView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        termsAgreementView.isHidden = termsAgreementView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        venueMessageView.isHidden   = venueMessageView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        emailMessageView.isHidden   = emailMessageView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        updateAgreementHeights(animated: false)

        buyBtn.alpha = 0.5
        buyBtn.isUserInteractionEnabled = false
        view.layoutIfNeeded()
    }

    func showContent() {
        setPriceLoadingVisible(false)
        guestDisplayRow.isHidden = false
        noteRow.isHidden         = false
        paymentRow.isHidden      = true
        paymentHeightConstraint?.constant = 0
        promoRow.isHidden        = false
        promoHeightConstraint?.constant = promoRow.preferredHeight
        checkoutPolicyView.isHidden = checkoutPolicyView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        termsAgreementView.isHidden = termsAgreementView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        venueMessageView.isHidden   = venueMessageView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        emailMessageView.isHidden   = emailMessageView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        updateAgreementHeights(animated: false)

        buyBtn.alpha = 1
        buyBtn.isUserInteractionEnabled = true
        view.layoutIfNeeded()
    }

    func setPriceLoadingVisible(_ visible: Bool) {
        priceLoadingView.isHidden = !visible
        priceLoadingHeightConstraint?.constant = visible ? priceLoadingView.preferredHeight : 0

        paymentTopToLoadingConstraint?.isActive = visible
        promoTopToLoadingConstraint?.isActive = visible

        if visible {
            paymentTopToSpendConstraint?.isActive = false
            paymentTopToDepositConstraint?.isActive = false
            paymentTopToSummaryConstraint?.isActive = false
            promoTopToSpendConstraint?.isActive = false
            promoTopToDepositConstraint?.isActive = false
            promoTopToSummaryConstraint?.isActive = false
            priceLoadingView.startShimmer()
        } else {
            priceLoadingView.stopShimmer()
        }
    }

    func configureSelectedTableData(from booking: SeatingAreaBookingResponse) {
        checkoutItems.removeAll()

        for bookingItem in booking.items {
            guard let area = seatingAreas.first(where: { $0.id == bookingItem.seatingAreaId }) else { continue }
            let timeText = formattedTime(bookingItem.timeSlot?.startTime)
            let item = TableBookingCheckoutItem(
                id:       area.id ?? "",
                name:     area.name ?? "",
                guests:   bookingItem.guests,
                minimum:  bookingItem.calculatedMinimum ?? 0,
                deposit:  bookingItem.calculatedDeposit ?? 0,
                timeSlot: timeText.isEmpty ? nil : timeText
            )
            checkoutItems.append(item)
        }

        if let item = checkoutItems.first {
            guestDisplayRow.configure(
                icon:  UIImage(named: "guestIcon"),
                title: "Guests",
                value: "\(item.guests)"
            )
            guestTag.configure(icon: "guestIcon", text: item.guests == 1 ? "1 guest" : "\(item.guests) guests")

            if selectedTimeText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false,
               let timeSlot = item.timeSlot {
                selectedTimeText = timeSlot
                timeTag.configure(style: .time, text: timeSlot)
                timeTag.isHidden = false
            }
        }
    }

    func configureSummaryPrice(total: Double?) {
        let item = checkoutItems.first
        let area = seatingAreas.first

        let itemMinimum = item?.minimum
        let slotMinimum = selectedTimeSlot?.minimum
        let areaMinimum = area?.minimum
        let minimum = itemMinimum ?? slotMinimum ?? areaMinimum ?? 0

        let itemDeposit = item?.deposit
        let slotDeposit = selectedTimeSlot?.depositWithFees ?? selectedTimeSlot?.deposit
        let areaDeposit = area?.depositWithFees ?? area?.deposit
        let deposit = total ?? itemDeposit ?? slotDeposit ?? areaDeposit ?? 0

        summaryPriceCard.configure(
            minimum: minimum,
            deposit: deposit,
            currency: currency,
            currencyPosition: currencyPosition
        )

        updateBottomPrice(deposit)

        if spendCard.isHidden {
            updatePriceSectionVisibility(hasDepositBreakdown: false)
        }
    }

    func updatePriceSectionVisibility(hasDepositBreakdown: Bool) {
        setPriceLoadingVisible(false)

        let hasSpendAgreement = !backendSpendAgreementItems.isEmpty

        spendCard.isHidden = !hasSpendAgreement
        spendHeightConstraint?.constant = hasSpendAgreement ? spendCard.preferredHeight : 0

        depositBreakdownCard.isHidden = !hasDepositBreakdown
        depositBreakdownHeightConstraint?.constant = hasDepositBreakdown ? depositBreakdownCard.preferredHeight : 0

        summaryPriceCard.isHidden = hasSpendAgreement || hasDepositBreakdown

        paymentTopToDepositConstraint?.isActive = hasDepositBreakdown
        paymentTopToSpendConstraint?.isActive   = !hasDepositBreakdown && hasSpendAgreement
        paymentTopToSummaryConstraint?.isActive = !hasDepositBreakdown && !hasSpendAgreement

        promoTopToSpendConstraint?.isActive = hasSpendAgreement
        promoTopToDepositConstraint?.isActive = hasDepositBreakdown && !hasSpendAgreement
        promoTopToSummaryConstraint?.isActive = !hasDepositBreakdown && !hasSpendAgreement
    }

    func configureAgreementText() {

        let settings = event?.venue?.venueSettings

        let importantInformation = ""
        checkoutPolicyView.titleText = nil
        checkoutPolicyView.showsCheckbox = false
        checkoutPolicyView.bodyText = importantInformation
        checkoutPolicyView.bodyAttributedText = nil
        checkoutPolicyView.isChecked = true
        checkoutPolicyView.isHidden = true

        let terms = cleanAgreementText(settings?.tableBookingTermsAndCondition ?? "")

        termsAgreementView.titleText = terms.isEmpty ? nil : "Terms & Conditions"
        termsAgreementView.showsCheckbox = true
        termsAgreementView.bodyText = terms
        termsAgreementView.bodyAttributedText = formattedAgreementHTML(
            settings?.tableBookingTermsAndCondition ?? ""
        )
        termsAgreementView.isChecked = true
        termsAgreementView.isHidden = terms.isEmpty

        let venueName = event?.venue?.name ?? "the venue"
        let fallbackPolicy =
            "I agree to receive marketing related text messages from \(venueName). Msg & data rates may apply. Reply STOP to opt out or HELP for support."
        var policy = cleanAgreementText(settings?.policyText ?? fallbackPolicy)
        if settings?.optedPolicy == true, policy.isEmpty {
            policy = cleanAgreementText(fallbackPolicy)
        }
        venueMessageView.titleText = nil
        venueMessageView.showsCheckbox = true
        venueMessageView.bodyText = settings?.optedPolicy == true ? policy : ""
        venueMessageView.bodyAttributedText = settings?.optedPolicy == true
            ? formattedAgreementHTML(settings?.policyText ?? fallbackPolicy)
            : nil
        venueMessageView.isChecked = true
        venueMessageView.isHidden = settings?.optedPolicy != true || policy.isEmpty

        let fallbackEmailPolicy =
            "I agree to receive marketing related email messages from \(venueName)."
        var emailPolicy = cleanAgreementText(settings?.emailPolicyText ?? fallbackEmailPolicy)
        if settings?.optedEmailPolicy == true, emailPolicy.isEmpty {
            emailPolicy = cleanAgreementText(fallbackEmailPolicy)
        }
        emailMessageView.titleText = nil
        emailMessageView.showsCheckbox = true
        emailMessageView.bodyText = settings?.optedEmailPolicy == true ? emailPolicy : ""
        emailMessageView.bodyAttributedText = settings?.optedEmailPolicy == true
            ? formattedAgreementHTML(settings?.emailPolicyText ?? fallbackEmailPolicy)
            : nil
        emailMessageView.isChecked = true
        emailMessageView.isHidden = settings?.optedEmailPolicy != true || emailPolicy.isEmpty
        updateAgreementHeights(animated: false)
    }

    func updateAgreementHeights(animated: Bool) {
        let checkoutPolicyVisible = !checkoutPolicyView.isHidden
            && !checkoutPolicyView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let termsVisible = !termsAgreementView.isHidden
            && !termsAgreementView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let venueVisible = !venueMessageView.isHidden
            && !venueMessageView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let emailVisible = !emailMessageView.isHidden
            && !emailMessageView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let checkoutPolicyHeight = checkoutPolicyVisible ? checkoutPolicyView.preferredHeight : 0
        let termsHeight = termsVisible ? termsAgreementView.preferredHeight : 0
        let venueHeight = venueVisible ? venueMessageView.preferredHeight : 0
        let emailHeight = emailVisible ? emailMessageView.preferredHeight : 0

        termsTopToPolicyConstraint?.isActive = checkoutPolicyVisible
        termsTopToPromoConstraint?.isActive = !checkoutPolicyVisible

        let hasChanged = abs((checkoutPolicyHeightConstraint?.constant ?? 0) - checkoutPolicyHeight) > 0.5
            || abs((termsHeightConstraint?.constant ?? 0) - termsHeight) > 0.5
            || abs((venueMessageHeightConstraint?.constant ?? 0) - venueHeight) > 0.5
            || abs((emailMessageHeightConstraint?.constant ?? 0) - emailHeight) > 0.5
        guard hasChanged else { return }

        checkoutPolicyHeightConstraint?.constant = checkoutPolicyHeight
        termsHeightConstraint?.constant = termsHeight
        venueMessageHeightConstraint?.constant = venueHeight
        emailMessageHeightConstraint?.constant = emailHeight

        layoutCheckoutContent(animated: animated)
    }

    func cleanAgreementText(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
              ) else {
            return text
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return attributed.string
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func formattedAgreementHTML(_ html: String) -> NSAttributedString? {
        guard let attributed = html.htmlToAttributedString else { return nil }
        let mutable = NSMutableAttributedString(attributedString: attributed)
        mutable.trimTrailingWhitespaceAndNewlines()
        guard mutable.length > 0 else { return nil }

        mutable.addAttributes([
            .font: Constant.Font.geistRegular(size: 12),
            .foregroundColor: UIColor.white.withAlphaComponent(0.88)
        ], range: NSRange(location: 0, length: mutable.length))

        mutable.enumerateAttribute(
            .link,
            in: NSRange(location: 0, length: mutable.length),
            options: []
        ) { value, range, _ in
            if value != nil {
                mutable.addAttributes([
                    .font: Constant.Font.geistMedium(size: 12),
                    .foregroundColor: UIColor.white,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: range)
            }
        }
        return mutable
    }

    func formattedTime(_ value: String?) -> String {
        guard
            let value,
            let date = value.dateFormatter(
                formate: .yyyyMMddTHHmmssSSSz,
                isTimeZoneChanged: true,
                isUTC: false
            )
        else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = DateFormat.hmma.rawValue
        formatter.timeZone   = TimeZone(
            identifier: event?.venue?.useTimezone ?? event?.venue?.timezone ?? ""
        ) ?? .current
        return formatter.string(from: date)
    }
}

// MARK: - Timer

private extension PremiumTableCheckoutVC {

    func startTimer() {
        timerBanner.update(seconds: timerSeconds)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.timerSeconds -= 1
            self.timerBanner.update(seconds: self.timerSeconds)
            if self.timerSeconds <= 0 {
                self.timer?.invalidate()
                self.handleTimeout()
            }
        }
    }

    func handleTimeout() {
        cancelCurrentBooking(returnToPrevious: false) { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(
                title:          "Session Expired",
                message:        "Your reservation time has expired. Please try again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: false)
            })
            self.present(alert, animated: true)
        }
    }

    func primeBooking(_ booking: SeatingAreaBookingResponse?) {
        guard let booking else { return }
        self.booking = booking
        if let tableBookingId = booking.content?.tableBooking?.id,
           !tableBookingId.isEmpty {

            currentBookingId = tableBookingId
        }
    }

    var activeTableBookingId: String {
        if !currentBookingId.isEmpty { return currentBookingId }
        if let tableBookingId = booking?.content?.tableBooking?.id,
           !tableBookingId.isEmpty {
            return tableBookingId
        }
        return ""
    }

    func cancelCurrentBooking(
        returnToPrevious: Bool,
        completion: (() -> Void)? = nil
    ) {
        guard !isCancellingBooking, !didFinishBooking, !didCancelBooking else {
            completion?()
            return
        }

        guard let eventId = event?.id,
              !eventId.isEmpty,
              let queueId,
              !queueId.isEmpty,
              !activeTableBookingId.isEmpty else {

            completion?()
            if returnToPrevious {
                navigationController?.popViewController(animated: false)
            }
            return
        }

        isCancellingBooking = true
        didCancelBooking = true

        tableService.cancelTableBookingQueue(
            eventId: eventId,
            queueId: queueId,
            tableBookingId: activeTableBookingId,
            venueId: event?.venue?.id
        ) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isCancellingBooking = false
                completion?()
                if returnToPrevious {
                    self.navigationController?.popViewController(animated: false)
                }
            }
        }
    }
}

private struct PremiumCheckoutSpendFee {
    let name: String
    let amount: Double
    let isTaxable: Bool
}

private struct PremiumCheckoutSpendFeeResult {
    let amountChargedToConsumer: Double
    let totalProcessingFees: Double
    let salesTax: Double
}

private struct PremiumCheckoutSpendSettings {
    let isProcessingFeePassToCustomer: Bool
    let isProcessingFeeTaxable: Bool
    let isEnableSalesTax: Bool
    let salesTaxName: String?
    let salesTax: Double
    let customFees: [TableSettingCustomFee]
    let isEnableGratuity: Bool
    let gratuityFeeType: String?
    let gratuityFeeName: String?
    let gratuityFee: Double
    let isGratuityTaxable: Bool
    let stripePerc: Double
    let stripeFlat: Double
    let speakeasyFeeFlat: Double?
    let speakeasyFeePerc: Double?

    init(_ settings: SpendAgreementSettings) {
        isProcessingFeePassToCustomer = settings.isProcessingFeePassToCustomer == true
        isProcessingFeeTaxable = settings.isProcessingFeeTaxable == true
        isEnableSalesTax = settings.isEnableSalesTax == true
        salesTaxName = settings.salesTaxName
        salesTax = settings.salesTax ?? 0
        customFees = settings.customFees ?? []
        isEnableGratuity = settings.isEnableGratuity == true
        gratuityFeeType = settings.gratuityFeeType
        gratuityFeeName = settings.gratuityFeeName
        gratuityFee = settings.gratuityFee ?? 0
        isGratuityTaxable = settings.isGratuityTaxable == true
        stripePerc = settings.stripePerc ?? 0.029
        stripeFlat = settings.stripeFlat ?? 30
        speakeasyFeeFlat = settings.speakeasyFeeFlat
        speakeasyFeePerc = settings.speakeasyFeePerc
    }
}

private extension PremiumTableCheckoutVC {

    func localSpendAgreementItems(depositBreakdown: PriceBreakdown?) -> [SpendLineItem] {
        guard event?.venue?.venueSettings?.isEnabledSpendAgreement == true,
              let spendSettings = event?.venue?.venueSettings?.spendAgreementSettings else {
            return []
        }

        let subtotal = checkoutItems.first?.minimum ?? seatingAreas.first.map { activeMinimum(for: $0) } ?? 0
        guard subtotal > 0 else { return [] }

        let settings = PremiumCheckoutSpendSettings(spendSettings)
        let customFeesWithGratuity = calculateSpendCustomFees(
            for: subtotal,
            settings: settings,
            includeGratuity: true
        )
        let customFeesWithoutGratuity = calculateSpendCustomFees(
            for: subtotal,
            settings: settings,
            includeGratuity: false
        )
        let seFees = calculateSpendSEFees(for: subtotal, settings: settings)
        let feeResult = calculateSpendBookingFees(
            amountTransferToSE: seFees,
            amountTransferToVenue: subtotal,
            customFees: customFeesWithGratuity,
            settings: settings
        )
        let gratuity = calculateSpendGratuity(for: subtotal, settings: settings)
        let balanceDue = max(0, feeResult.amountChargedToConsumer - depositCredit(from: depositBreakdown))

        var items: [SpendLineItem] = [
            .init(title: "Subtotal", amount: subtotal, isBold: false)
        ]

        if settings.isEnableGratuity, gratuity > 0 {
            items.append(.init(title: settings.gratuityFeeName ?? "Gratuity Fee", amount: gratuity, isBold: false))
        }
        if settings.isEnableSalesTax, feeResult.salesTax > 0 {
            items.append(.init(title: settings.salesTaxName ?? "Sales Tax", amount: feeResult.salesTax, isBold: false))
        }
        if settings.isProcessingFeePassToCustomer, feeResult.totalProcessingFees > 0 {
            items.append(.init(title: "Processing Fee", amount: feeResult.totalProcessingFees, isBold: false))
        }
        customFeesWithoutGratuity
            .filter { $0.amount > 0 }
            .forEach { items.append(.init(title: $0.name, amount: $0.amount, isBold: false)) }

        items.append(.init(title: "Total", amount: feeResult.amountChargedToConsumer, isBold: true))
        items.append(.init(title: "Balance Due at Venue", amount: balanceDue, isBold: true))
        return items
    }

    func activeMinimum(for area: SeatingArea) -> Double {
        let guests = checkoutItems.first?.guests ?? guestCount
        let defaultGuests = area.defaultGuest ?? 0
        let extraGuests = max(0, guests - defaultGuests)

        if area.bookingType == .timeWise {
            let base = selectedTimeSlot?.minimum ?? area.minimum ?? 0
            let extraCharge = selectedTimeSlot?.extraPersonCharge ?? area.extraPersonCharge ?? 0
            return base + Double(extraGuests) * extraCharge
        }

        return (area.minimum ?? 0) + Double(extraGuests) * (area.extraPersonCharge ?? 0)
    }

    func depositCredit(from breakdown: PriceBreakdown?) -> Double {
        let breakdownTotal = breakdown?.total
        let checkoutDeposit = checkoutItems.first?.deposit
        let slotDeposit = selectedTimeSlot?.depositWithFees
        let seatingDeposit = seatingAreas.first?.depositWithFees

        let backendTotal = breakdownTotal
            ?? checkoutDeposit
            ?? slotDeposit
            ?? seatingDeposit
            ?? 0

        let salesTax = breakdown?.salesTax ?? 0
        let seFees = breakdown?.seFees ?? 0
        let stripeFees = breakdown?.stripeFees ?? 0
        let processingFees = seFees + stripeFees

        let tableBookingSettings = event?.venue?.venueSettings?.tableBookingSettings
        let shouldRemoveProcessingFees =
            tableBookingSettings?.isProcessingFeePassToCustomer ?? false

        let deposit = backendTotal
            - salesTax
            - (shouldRemoveProcessingFees ? processingFees : 0)

        return max(0, deposit)
    }

    func calculateSpendSEFees(for amount: Double, settings: PremiumCheckoutSpendSettings) -> Double {
        var seFees = 0.0
        if let percentage = settings.speakeasyFeePerc {
            seFees = amount * percentage * 100
        }
        if let flat = settings.speakeasyFeeFlat {
            seFees += amount <= 10 ? amount * 0.1 * flat : flat
        }
        return seFees
    }

    func calculateSpendCustomFees(
        for amount: Double,
        settings: PremiumCheckoutSpendSettings,
        includeGratuity: Bool
    ) -> [PremiumCheckoutSpendFee] {
        var fees: [PremiumCheckoutSpendFee] = []
        settings.customFees.forEach { customFee in
            guard customFee.isEnableCustomFee == true else { return }
            let feeAmount = customFee.customFeeType?.uppercased() == "FLAT"
                ? (customFee.customFee ?? 0)
                : amount * (customFee.customFee ?? 0) / 100
            fees.append(
                .init(
                    name: customFee.customFeeName ?? "Fee",
                    amount: feeAmount,
                    isTaxable: customFee.isCustomFeeTaxable == true
                )
            )
        }
        if includeGratuity, settings.isEnableGratuity {
            fees.append(
                .init(
                    name: settings.gratuityFeeName ?? "Gratuity Fee",
                    amount: calculateSpendGratuity(for: amount, settings: settings),
                    isTaxable: settings.isGratuityTaxable
                )
            )
        }
        return fees
    }

    func calculateSpendGratuity(for amount: Double, settings: PremiumCheckoutSpendSettings) -> Double {
        guard settings.isEnableGratuity else { return 0 }
        if settings.gratuityFeeType?.uppercased() == "FLAT" {
            return settings.gratuityFee
        }
        return amount * settings.gratuityFee / 100
    }

    func calculateSpendBookingFees(
        amountTransferToSE: Double,
        amountTransferToVenue: Double,
        customFees: [PremiumCheckoutSpendFee],
        settings: PremiumCheckoutSpendSettings
    ) -> PremiumCheckoutSpendFeeResult {
        let stripePerc = settings.stripePerc
        let stripeFlat = settings.stripeFlat / 100
        let speakeasyFee = amountTransferToSE / 100
        let taxRate = settings.isEnableSalesTax ? settings.salesTax / 100 : 0
        let taxableFees = customFees.filter(\.isTaxable).reduce(0) { $0 + $1.amount }
        let nonTaxableFees = customFees.filter { !$0.isTaxable }.reduce(0) { $0 + $1.amount }

        func rounded2(_ value: Double) -> Double {
            (value * 100).rounded() / 100
        }

        let stripeFee: Double
        let salesTax: Double
        let totalProcessingFees: Double

        if settings.isProcessingFeePassToCustomer {
            if settings.isProcessingFeeTaxable {
                stripeFee = rounded2(
                    (
                        stripePerc * (
                            (1 + taxRate) * (amountTransferToVenue + speakeasyFee + taxableFees)
                            + nonTaxableFees
                        )
                        + stripeFlat
                    )
                    / (1 - (1 + taxRate) * stripePerc)
                )
                totalProcessingFees = rounded2(speakeasyFee + stripeFee)
                salesTax = rounded2((amountTransferToVenue + taxableFees + totalProcessingFees) * taxRate)
            } else {
                stripeFee = rounded2(
                    (
                        stripePerc * (
                            (amountTransferToVenue + taxableFees) * (1 + taxRate)
                            + nonTaxableFees
                            + speakeasyFee
                        )
                        + stripeFlat
                    )
                    / (1 - stripePerc)
                )
                totalProcessingFees = rounded2(speakeasyFee + stripeFee)
                salesTax = rounded2((amountTransferToVenue + taxableFees) * taxRate)
            }
        } else {
            stripeFee = rounded2(
                stripePerc * ((amountTransferToVenue + taxableFees) * (1 + taxRate) + nonTaxableFees)
                + stripeFlat
            )
            totalProcessingFees = rounded2(speakeasyFee + stripeFee)
            salesTax = rounded2((amountTransferToVenue + taxableFees) * taxRate)
        }

        let roundedProcessingCents = (totalProcessingFees * 100).rounded()
        let roundedSalesTaxCents = (salesTax * 100).rounded()
        let amountCharged = rounded2(
            amountTransferToVenue
            + (settings.isProcessingFeePassToCustomer ? roundedProcessingCents / 100 : 0)
            + taxableFees
            + nonTaxableFees
            + salesTax
        )
        let amountChargedCents = (amountCharged * 100).rounded()

        return .init(
            amountChargedToConsumer: amountChargedCents / 100,
            totalProcessingFees: roundedProcessingCents / 100,
            salesTax: roundedSalesTaxCents / 100
        )
    }
}

// MARK: - Socket

private extension PremiumTableCheckoutVC {

    func setupSocket() {
        BookingQueueSocketManager.shared.delegate = self
        if let q = queueId {
            BookingQueueSocketManager.shared.connect(
                queueId: q,
                venueId: event?.venue?.id
            )
        }
    }
}

extension PremiumTableCheckoutVC: BookingQueueSocketDelegate {

    func didUpdateQueue(seatingAreaBooking: SeatingAreaBookingResponse?) {
        guard let b = seatingAreaBooking else { return }
        DispatchQueue.main.async {
            switch b.status.lowercased() {
            case "queued":
                self.booking = b

            case "payment":
                self.booking             = b
                self.currentBookingId    = b.content?.tableBooking?.id ?? b.id
                self.paymentIntentSecret = b.content?.clientSecret ?? ""
                self.ephemeralKey        = b.content?.ephemeralKey ?? ""
                self.paymentId           = b.content?.tableBooking?.paymentId ?? ""
                self.configureAfterBooking(b)

            case "failed":
                self.updatePriceSectionVisibility(hasDepositBreakdown: false)
                self.buyBtn.alpha = 0.5
                self.buyBtn.isUserInteractionEnabled = false
                Alert.showToast(b.message ?? "Booking failed")

            default:
                break
            }
        }
    }
}

private final class PremiumTableCheckoutPriceLoadingView: UIView {

    let preferredHeight: CGFloat = 282

    private let card = GradientBorderCardView()
    private let titleLabel = UILabel()
    private let rowsStack = UIStackView()
    private let shimmerRows = [
        PremiumTableCheckoutPriceShimmerRow(titleWidthMultiplier: 0.40, amountWidthMultiplier: 0.20),
        PremiumTableCheckoutPriceShimmerRow(titleWidthMultiplier: 0.52, amountWidthMultiplier: 0.24),
        PremiumTableCheckoutPriceShimmerRow(titleWidthMultiplier: 0.34, amountWidthMultiplier: 0.22),
        PremiumTableCheckoutPriceShimmerRow(titleWidthMultiplier: 0.42, amountWidthMultiplier: 0.20),
        PremiumTableCheckoutPriceShimmerRow(titleWidthMultiplier: 0.48, amountWidthMultiplier: 0.24),
        PremiumTableCheckoutPriceShimmerRow(titleWidthMultiplier: 0.38, amountWidthMultiplier: 0.28)
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        card.glassCornerRadius = 18
    }

    func startShimmer() {
        shimmerRows.forEach { $0.startShimmer() }
    }

    func stopShimmer() {
        shimmerRows.forEach { $0.stopShimmer() }
    }

    private func setup() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.fillColor = UIColor.white.withAlphaComponent(0.06).cgColor
        card.showsBlur = true
        card.blurAlpha = 0.4
        card.thinBorder = true
        addSubview(card)

        titleLabel.text = "Deposit Breakdown"
        titleLabel.font = Constant.Font.geistMedium(size: 15)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        rowsStack.axis = .vertical
        rowsStack.spacing = 14
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rowsStack)

        shimmerRows.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            rowsStack.addArrangedSubview($0)
            $0.heightAnchor.constraint(equalToConstant: 18).isActive = true
        }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -16),

            rowsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            rowsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            rowsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            rowsStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -18)
        ])
    }
}

private final class PremiumTableCheckoutPriceShimmerRow: UIView {

    private let titleLine = ShimmerViewV3()
    private let amountLine = ShimmerViewV3()
    private let titleWidthMultiplier: CGFloat
    private let amountWidthMultiplier: CGFloat

    init(titleWidthMultiplier: CGFloat, amountWidthMultiplier: CGFloat) {
        self.titleWidthMultiplier = titleWidthMultiplier
        self.amountWidthMultiplier = amountWidthMultiplier
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func startShimmer() {
        titleLine.startShimmer()
        amountLine.startShimmer()
    }

    func stopShimmer() {
        titleLine.stopShimmer()
        amountLine.stopShimmer()
    }

    private func setup() {
        [titleLine, amountLine].forEach {
            $0.cornerRadius = 6
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLine.widthAnchor.constraint(equalTo: widthAnchor, multiplier: titleWidthMultiplier),
            titleLine.heightAnchor.constraint(equalToConstant: 12),

            amountLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            amountLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            amountLine.widthAnchor.constraint(equalTo: widthAnchor, multiplier: amountWidthMultiplier),
            amountLine.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
}

// MARK: - Stripe

private extension PremiumTableCheckoutVC {

    func setupStripe(secret: String, ephemeralKey: String) {
        STPAPIClient.shared.publishableKey = Stripe.publishableKey
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName         = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"
        if !ephemeralKey.isEmpty,
           let customerId = UserDefault.shared.user?.stripeCusId,
           !customerId.isEmpty {
            config.customer = .init(
                id: customerId,
                ephemeralKeySecret: ephemeralKey
            )
        }
        config.savePaymentMethodOptInBehavior = .automatic
        config.allowsDelayedPaymentMethods = true
        paymentSheet = PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
    }
}

// MARK: - Promo

private extension PremiumTableCheckoutVC {

    func applyPromo(_ code: String) {
        guard let eventId   = event?.id,
              let venueId   = event?.venue?.id,
              let bookingId = booking?.content?.tableBooking?.id ?? (currentBookingId.isEmpty ? nil : currentBookingId) else {
            Alert.showToast("Booking details not found")
            return
        }

        promoRow.setSubmitting(true)
        tableService.applyPromoCode(
            eventId:        eventId,
            tableBookingId: bookingId,
            code:           code,
            venueId:        venueId
        ) { [weak self] success, message, data in
            DispatchQueue.main.async {
                guard let self else { return }
                self.promoRow.setSubmitting(false)
                if success, let data {
                    self.isPromoApplied = true
                    self.appliedPromo   = code
                    self.promoRow.setApplied(
                        true,
                        code: code,
                        discount: data.discount ?? 0,
                        currency: self.currency,
                        currencyPosition: self.currencyPosition
                    )
                    self.configureDepositBreakdown(data)
                    self.configureSpendAgreementCard(
                        self.booking?.content?.tableBooking?.spendAgreement,
                        depositBreakdown: data
                    )
                    self.updateBottomPrice(data.total ?? 0)
                    Alert.showToast("Promo code applied")
                } else {
                    self.promoRow.setApplied(false)
                    Alert.showToast(message ?? "Invalid promo code")
                }
            }
        }
    }

    func removePromo() {
        guard let eventId   = event?.id,
              let venueId   = event?.venue?.id,
              let bookingId = booking?.content?.tableBooking?.id ?? (currentBookingId.isEmpty ? nil : currentBookingId) else {
            Alert.showToast("Booking details not found")
            return
        }

        promoRow.setSubmitting(true)
        tableService.removePromoCode(
            eventId:        eventId,
            tableBookingId: bookingId,
            venueId:        venueId
        ) { [weak self] success, message, data in
            DispatchQueue.main.async {
                guard let self else { return }
                self.promoRow.setSubmitting(false)
                if success, let data {
                    self.isPromoApplied = false
                    self.appliedPromo   = ""
                    self.promoRow.setApplied(false)
                    self.configureDepositBreakdown(data)
                    self.configureSpendAgreementCard(
                        self.booking?.content?.tableBooking?.spendAgreement,
                        depositBreakdown: data
                    )
                    self.updateBottomPrice(data.total ?? 0)
                    Alert.showToast("Promo removed")
                } else {
                    Alert.showToast(message ?? "Failed to remove promo")
                }
            }
        }
    }
}

// MARK: - Purchase

private extension PremiumTableCheckoutVC {

    @objc func onBuyTapped() {
        guard !isPaymentInitiated else { return }

        guard termsAgreementView.isChecked || termsAgreementView.isHidden else {
            Alert.showToast("Please accept the terms and conditions")
            return
        }

        if !venueMessageView.isHidden && !venueMessageView.isChecked {
            Alert.showToast("Please accept the venue message")
            return
        }

        if !emailMessageView.isHidden && !emailMessageView.isChecked {
            Alert.showToast("Please accept the email policy")
            return
        }

        isPaymentInitiated = true
        setBuyLoading(true)

        if isFreeBooking {
            confirmAndFinish()
            return
        }

        guard let ps = paymentSheet else {
            isPaymentInitiated = false
            setBuyLoading(false)
            Alert.showToast("Payment not ready")
            return
        }

        ps.present(from: self) { [weak self] result in
            guard let self else { return }
            switch result {
            case .completed:
                self.confirmAndFinish()
            case .canceled:
                self.isPaymentInitiated = false
                self.setBuyLoading(false)
                Alert.showToast("Payment canceled.")
                self.cancelCurrentBooking(returnToPrevious: true)
            case .failed:
                self.isPaymentInitiated = false
                self.setBuyLoading(false)
                Alert.showToast("Payment failed.")
            }
        }
    }

    func confirmAndFinish() {
        guard let eventId = event?.id,
              let queueId,
              let venueId = event?.venue?.id,
              !currentBookingId.isEmpty else {
            isPaymentInitiated = false
            setBuyLoading(false)
            Alert.showToast("Booking details not found")
            return
        }

        let notes = noteRow.noteText

        tableService.confirmTableBooking(
            eventId:        eventId,
            queueId:        queueId,
            tableBookingId: currentBookingId,
            consumerUserId: UserDefault.shared.user?.id ?? "",
            optedPolicy:    venueMessageView.isHidden ? termsAgreementView.isChecked : venueMessageView.isChecked,
            notes:          notes,
            venueId:        venueId,
            promotionLinkId: promotionLinkId,
            promotionLinkUniqueCode: promotionLinkUniqueCode
        ) { [weak self] success, message, response in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isPaymentInitiated = false
                self.setBuyLoading(false)
                if success {
                    self.didFinishBooking = true
                    self.timer?.invalidate()
                    NotificationCenter.default.postOrdersRefresh(.tables)
                    self.showReservationConfirmation(response?.reservations.first)
                } else {
                    Alert.showToast(message ?? Constant.String.somethingWrong)
                }
            }
        }
    }

    func showReservationConfirmation(_ reservation: Reservation?) {
        let vc = PremiumTableReservationConfirmationVC()
        vc.reservation = reservation
        vc.reservationUniqueId = reservation?.uniqueId
        vc.tableBookingId = reservation?.tableBookingId ?? currentBookingId
        vc.event = event

        if let navigationController {
            navigationController.setViewControllers([vc], animated: false)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.navigationBar.isHidden = true
            presentPremium(nav)
        }
    }

    func setBuyLoading(_ isLoading: Bool) {
        buyBtn.isUserInteractionEnabled = !isLoading
        buyBtn.setTitle(isLoading ? nil : "Buy now", for: .normal)
        isLoading ? buyLoader.startAnimating() : buyLoader.stopAnimating()
    }
}
