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

    // MARK: - Private

    private var booking: SeatingAreaBookingResponse?
    private var currentBookingId     = ""
    private var paymentIntentSecret  = ""
    private var ephemeralKey         = ""
    private var paymentId            = ""
    private var paymentSheet: PaymentSheet?
    private var isPaymentInitiated   = false
    private var isCancellingBooking  = false
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
    private var noteHeightConstraint: NSLayoutConstraint?
    private var spendHeightConstraint: NSLayoutConstraint?
    private var depositBreakdownHeightConstraint: NSLayoutConstraint?
    private var paymentTopToSpendConstraint: NSLayoutConstraint?
    private var paymentTopToDepositConstraint: NSLayoutConstraint?
    private var paymentTopToSummaryConstraint: NSLayoutConstraint?
    private var promoTopToSpendConstraint: NSLayoutConstraint?
    private var promoTopToDepositConstraint: NSLayoutConstraint?
    private var promoTopToSummaryConstraint: NSLayoutConstraint?
    private var paymentHeightConstraint: NSLayoutConstraint?
    private var promoHeightConstraint: NSLayoutConstraint?
    private var termsHeightConstraint: NSLayoutConstraint?
    private var venueMessageHeightConstraint: NSLayoutConstraint?

    // Payment method
    private let paymentRow       = PremiumInfoRow()

    // Promo code
    private let promoRow         = PremiumPromoRow()

    // Agreement rows
    private let termsAgreementView  = PremiumAgreementView()
    private let venueMessageView    = PremiumAgreementView()

    // Timer
    private let timerBanner      = PremiumTimerBannerView()

    // Loading overlay
    private let loadingOverlay   = UIView()
    private let loadingStack     = UIStackView()

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
        setupPaymentRow()
        setupPromoRow()
        setupCheckboxes()
        setupTimerBanner()
        setupBottomBar()
        setupLoadingOverlay()
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
        eventTitleLabel.font      = Constant.Font.geistMedium(size: 22)
        eventTitleLabel.textColor = .white
        eventTitleLabel.numberOfLines = 0
        eventTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventTitleLabel)
        eventTitleMarqueeLabel.install(over: eventTitleLabel, in: contentView, height: 30, horizontalInset: 20)

        venueLabel.font      = Constant.Font.geistMedium(size: 12)
        venueLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        venueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(venueLabel)

        dateLabel.font      = Constant.Font.geistRegular(size: 12)
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
        spendCard.onHeightChanged = { [weak self] height in
            self?.spendHeightConstraint?.constant = height
            self?.view.layoutIfNeeded()
        }
        contentView.addSubview(spendCard)
    }

    func setupDepositBreakdownCard() {
        depositBreakdownCard.translatesAutoresizingMaskIntoConstraints = false
        depositBreakdownCard.isHidden = true
        depositBreakdownCard.onHeightChanged = { [weak self] height in
            self?.depositBreakdownHeightConstraint?.constant = height
            self?.view.layoutIfNeeded()
        }
        contentView.addSubview(depositBreakdownCard)
    }

    func setupSummaryPriceCard() {
        summaryPriceCard.translatesAutoresizingMaskIntoConstraints = false
        summaryPriceCard.isHidden = true
        contentView.addSubview(summaryPriceCard)
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
        termsAgreementView.titleText = "Terms & Conditions"
        termsAgreementView.isChecked = true
        termsAgreementView.translatesAutoresizingMaskIntoConstraints = false
        termsAgreementView.isHidden = true
        termsAgreementView.onHeightChanged = { [weak self] _ in
            self?.updateAgreementHeights(animated: false)
        }
        contentView.addSubview(termsAgreementView)

        venueMessageView.titleText = nil
        venueMessageView.isChecked = true
        venueMessageView.translatesAutoresizingMaskIntoConstraints = false
        venueMessageView.isHidden = true
        venueMessageView.onHeightChanged = { [weak self] _ in
            self?.updateAgreementHeights(animated: false)
        }
        contentView.addSubview(venueMessageView)
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

        buyBtn.setTitle("Buy tickets", for: .normal)
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

    func setupLoadingOverlay() {
        loadingOverlay.backgroundColor = UIColor(hex: "#111111")
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingOverlay)

        loadingStack.axis = .vertical
        loadingStack.spacing = 14
        loadingStack.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(loadingStack)

        func block(_ height: CGFloat, width: CGFloat? = nil, radius: CGFloat = 16) -> ShimmerViewV3 {
            let shimmer = ShimmerViewV3()
            shimmer.cornerRadius = radius
            shimmer.translatesAutoresizingMaskIntoConstraints = false
            shimmer.heightAnchor.constraint(equalToConstant: height).isActive = true
            if let width {
                shimmer.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            shimmer.startShimmer()
            return shimmer
        }

        let header = UIStackView(arrangedSubviews: [
            block(24, width: 220, radius: 12),
            block(16, width: 140, radius: 8),
            block(16, width: 190, radius: 8)
        ])
        header.axis = .vertical
        header.alignment = .center
        header.spacing = 10

        loadingStack.addArrangedSubview(header)
        loadingStack.addArrangedSubview(block(58, radius: 18))
        loadingStack.addArrangedSubview(block(178, radius: 18))
        loadingStack.addArrangedSubview(block(72, radius: 18))
        loadingStack.addArrangedSubview(block(50, radius: 14))

        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            loadingStack.topAnchor.constraint(equalTo: loadingOverlay.safeAreaLayoutGuide.topAnchor, constant: 84),
            loadingStack.leadingAnchor.constraint(equalTo: loadingOverlay.leadingAnchor, constant: 20),
            loadingStack.trailingAnchor.constraint(equalTo: loadingOverlay.trailingAnchor, constant: -20)
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

            dateLabel.topAnchor.constraint(equalTo: venueLabel.bottomAnchor, constant: 2),
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

            // Payment
            paymentRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            paymentRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Promo
            promoRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            promoRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Terms
            termsAgreementView.topAnchor.constraint(equalTo: promoRow.bottomAnchor, constant: 12),
            termsAgreementView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            termsAgreementView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Venue message
            venueMessageView.topAnchor.constraint(equalTo: termsAgreementView.bottomAnchor, constant: 14),
            venueMessageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            venueMessageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            venueMessageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

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
        paymentTopToSummaryConstraint?.isActive = true

        promoTopToSpendConstraint = promoRow.topAnchor.constraint(equalTo: spendCard.bottomAnchor, constant: 10)
        promoTopToDepositConstraint = promoRow.topAnchor.constraint(equalTo: depositBreakdownCard.bottomAnchor, constant: 10)
        promoTopToSummaryConstraint = promoRow.topAnchor.constraint(equalTo: summaryPriceCard.bottomAnchor, constant: 10)
        promoTopToSummaryConstraint?.isActive = true

        noteHeightConstraint = noteRow.heightAnchor.constraint(equalToConstant: noteRow.preferredHeight)
        noteHeightConstraint?.isActive = true

        spendHeightConstraint = spendCard.heightAnchor.constraint(equalToConstant: 0)
        spendHeightConstraint?.isActive = true

        depositBreakdownHeightConstraint = depositBreakdownCard.heightAnchor.constraint(equalToConstant: 0)
        depositBreakdownHeightConstraint?.isActive = true

        paymentHeightConstraint = paymentRow.heightAnchor.constraint(equalToConstant: 0)
        paymentHeightConstraint?.isActive = true

        promoHeightConstraint = promoRow.heightAnchor.constraint(equalToConstant: promoRow.preferredHeight)
        promoHeightConstraint?.isActive = true

        termsHeightConstraint = termsAgreementView.heightAnchor.constraint(equalToConstant: 0)
        termsHeightConstraint?.isActive = true

        venueMessageHeightConstraint = venueMessageView.heightAnchor.constraint(equalToConstant: 0)
        venueMessageHeightConstraint?.isActive = true
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
        guestTag.configure(icon: "person.2", text: guestText)
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
            icon:  UIImage(systemName: "person.2"),
            title: "Guests",
            value: "\(guestCount)"
        )
    }

    func configureAfterBooking(_ b: SeatingAreaBookingResponse) {
        configureSelectedTableData(from: b)
        configureSummaryPrice(total: nil)
        configureSpendAgreementCard(b.content?.tableBooking?.spendAgreement)
        if !paymentIntentSecret.isEmpty {
            setupStripe(secret: paymentIntentSecret, ephemeralKey: ephemeralKey)
        }

        guard let breakdown = b.content?.tableBooking?.tableBookingPriceBreakdown else {
            updatePriceSectionVisibility(hasDepositBreakdown: false)
            showContent()
            return
        }
        configureDepositBreakdown(breakdown)
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

        depositBreakdownCard.configure(currency: currency, title: "Deposit Breakdown", items: items, expanded: true)
        configureSummaryPrice(total: total)
        updatePriceSectionVisibility(hasDepositBreakdown: true)
        isFreeBooking = total <= 0
    }

    func configureSpendAgreementCard(_ breakdown: PriceBreakdown?) {
        guard let breakdown else {
            backendSpendAgreementItems = []
            spendCard.isHidden = true
            spendHeightConstraint?.constant = 0
            return
        }

        let items = spendAgreementItems(from: breakdown)
        guard !items.isEmpty else {
            backendSpendAgreementItems = []
            spendCard.isHidden = true
            spendHeightConstraint?.constant = 0
            return
        }

        backendSpendAgreementItems = items
        spendCard.configure(currency: currency, title: "Spend Agreement", items: items, expanded: true)
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
            : "\(currency)\(String(format: "%.2f", total))"
    }

    func showInitialContent() {
        setLoadingOverlayVisible(true)
        guestDisplayRow.isHidden = true
        noteRow.isHidden         = true
        summaryPriceCard.isHidden = true
        spendCard.isHidden = true
        spendHeightConstraint?.constant = 0
        depositBreakdownCard.isHidden = true
        depositBreakdownHeightConstraint?.constant = 0
        paymentRow.isHidden      = true
        paymentHeightConstraint?.constant = 0
        promoRow.isHidden        = true
        promoHeightConstraint?.constant = 0
        termsAgreementView.isHidden = termsAgreementView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        venueMessageView.isHidden   = venueMessageView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        updateAgreementHeights(animated: false)

        buyBtn.alpha = 0.5
        buyBtn.isUserInteractionEnabled = false
        view.layoutIfNeeded()
    }

    func showContent() {
        setLoadingOverlayVisible(false)
        guestDisplayRow.isHidden = false
        noteRow.isHidden         = false
        paymentRow.isHidden      = true
        paymentHeightConstraint?.constant = 0
        promoRow.isHidden        = false
        promoHeightConstraint?.constant = promoRow.preferredHeight
        termsAgreementView.isHidden = termsAgreementView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        venueMessageView.isHidden   = venueMessageView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        updateAgreementHeights(animated: false)

        buyBtn.alpha = 1
        buyBtn.isUserInteractionEnabled = true
        view.layoutIfNeeded()
    }

    func setLoadingOverlayVisible(_ visible: Bool) {
        loadingOverlay.isHidden = !visible
        if visible {
            startShimmerViews(in: loadingOverlay)
        } else {
            loadingOverlay.layer.removeAllAnimations()
        }
    }

    func startShimmerViews(in view: UIView) {
        if let shimmer = view as? ShimmerViewV3 {
            shimmer.startShimmer()
        }
        view.subviews.forEach { startShimmerViews(in: $0) }
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
                icon:  UIImage(systemName: "person.2"),
                title: "Guests",
                value: "\(item.guests)"
            )
            guestTag.configure(icon: "person.2", text: item.guests == 1 ? "1 guest" : "\(item.guests) guests")

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
            currency: currency
        )

        updateBottomPrice(deposit)

        if spendCard.isHidden {
            updatePriceSectionVisibility(hasDepositBreakdown: false)
        }
    }

    func updatePriceSectionVisibility(hasDepositBreakdown: Bool) {
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

        var terms = cleanAgreementText(
            settings?.tableBookingTermsAndCondition ??
            settings?.emailPolicyText ??
            ""
        )
        if terms.isEmpty {
            terms = "I agree to the Terms & Conditions."
        }

        termsAgreementView.titleText = "Terms & Conditions"
        termsAgreementView.bodyText = terms
        termsAgreementView.bodyAttributedText = formattedAgreementHTML(
            settings?.tableBookingTermsAndCondition ?? settings?.emailPolicyText ?? ""
        )
        termsAgreementView.isChecked = false
        termsAgreementView.isHidden = false

        var policy = cleanAgreementText(settings?.tableBookingImportantInformation ?? "")
        if settings?.optedPolicy == true, policy.isEmpty {
            let venueName = event?.venue?.name ?? "the venue"
            policy = cleanAgreementText(settings?.policyText ?? "")
            if policy.isEmpty {
                policy = "I agree to receive marketing related messages from \(venueName) via SMS and email."
            }
        }
        venueMessageView.titleText = nil
        venueMessageView.bodyText = settings?.optedPolicy == true ? policy : ""
        venueMessageView.bodyAttributedText = settings?.optedPolicy == true
            ? formattedAgreementHTML(settings?.tableBookingImportantInformation ?? settings?.policyText ?? "")
            : nil
        venueMessageView.isChecked = false
        venueMessageView.isHidden = settings?.optedPolicy != true || policy.isEmpty
        updateAgreementHeights(animated: false)
    }

    func updateAgreementHeights(animated: Bool) {
        let termsVisible = !termsAgreementView.isHidden
            && !termsAgreementView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let venueVisible = !venueMessageView.isHidden
            && !venueMessageView.bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let termsHeight = termsVisible ? termsAgreementView.preferredHeight : 0
        let venueHeight = venueVisible ? venueMessageView.preferredHeight : 0
        let hasChanged = abs((termsHeightConstraint?.constant ?? 0) - termsHeight) > 0.5
            || abs((venueMessageHeightConstraint?.constant ?? 0) - venueHeight) > 0.5
        guard hasChanged else { return }

        termsHeightConstraint?.constant = termsHeight
        venueMessageHeightConstraint?.constant = venueHeight

        self.view.layoutIfNeeded()
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

    var activeBookingId: String {
        if !currentBookingId.isEmpty { return currentBookingId }
        if let tableBookingId = booking?.content?.tableBooking?.id,
           !tableBookingId.isEmpty {
            return tableBookingId
        }
        return booking?.id ?? ""
    }

    func cancelCurrentBooking(
        returnToPrevious: Bool,
        completion: (() -> Void)? = nil
    ) {
        guard !isCancellingBooking, !didFinishBooking else {
            completion?()
            return
        }
        let bookingId = activeBookingId
        guard !bookingId.isEmpty else {
            completion?()
            if returnToPrevious {
                navigationController?.popViewController(animated: false)
            }
            return
        }

        isCancellingBooking = true
        tableService.cancelTableBooking(
            bookingId: bookingId,
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

// MARK: - Socket

private extension PremiumTableCheckoutVC {

    func setupSocket() {
        configureHeader()
        configureGuest()
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
                self.setLoadingOverlayVisible(false)
                self.buyBtn.alpha = 0.5
                self.buyBtn.isUserInteractionEnabled = false
                Alert.showToast(b.message ?? "Booking failed")

            default:
                break
            }
        }
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
                        currency: self.currency
                    )
                    self.configureDepositBreakdown(data)
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
            venueId:        venueId
        ) { [weak self] success, message, response in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isPaymentInitiated = false
                self.setBuyLoading(false)
                if success {
                    self.didFinishBooking = true
                    self.timer?.invalidate()
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
        buyBtn.setTitle(isLoading ? nil : "Buy tickets", for: .normal)
        isLoading ? buyLoader.startAnimating() : buyLoader.stopAnimating()
    }
}
