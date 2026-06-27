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

    // MARK: - Private

    private var booking: SeatingAreaBookingResponse?
    private var currentBookingId     = ""
    private var paymentIntentSecret  = ""
    private var paymentId            = ""
    private var paymentSheet: PaymentSheet?
    private var isPaymentInitiated   = false
    private var isFreeBooking        = false
    private var isPromoApplied       = false
    private var appliedPromo         = ""
    private var feesAndTaxes: [FeeDisplayItem] = []
    private var checkoutItems: [TableBookingCheckoutItem] = []
    private var timerSeconds         = 600  // 10 min
    private var timer: Timer?

    private var currency: String {
        event?.venue?.venueSettings?.currencySymbol ?? "$"
    }

    // MARK: - UI

    private let scrollView      = UIScrollView()
    private let contentView     = UIView()

    // Header
    private let eventTitleLabel = UILabel()
    private let venueLabel      = UILabel()
    private let dateLabel       = UILabel()

    private let headerDivider   = UIView()

    // Table seating title
    private let seatingTitleRow = UIView()
    private let seatingIcon     = UIImageView()
    private let seatingLabel    = UILabel()

    // Guest + time info tags
    private let tagsRow         = UIView()
    private let guestTag        = PremiumTagPillView()

    // Shimmer
    private let shimmerContainer = UIView()
    private let shimmerStack     = UIStackView()

    // Guest row (display only — no +/-)
    private let guestDisplayRow = PremiumInfoRow()

    // Spend agreement (collapsible)
    private let spendCard       = PremiumSpendAgreementView()

    // Payment method
    private let paymentRow      = PremiumInfoRow()

    // Promo code
    private let promoRow        = PremiumPromoRow()

    // Terms checkboxes
    private let termsCheckbox   = PremiumCheckboxView()
    private let marketingCheck  = PremiumCheckboxView()

    // Timer
    private let timerBanner     = PremiumTimerBannerView()

    // Bottom bar
    private let bottomBar       = UIView()
    private let bottomPrice     = UILabel()
    private let bottomSub       = UILabel()
    private let buyBtn          = UIButton(type: .system)

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
        timer?.invalidate()
        BookingQueueSocketManager.shared.disconnect()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        buyBtn.layer.cornerRadius = buyBtn.bounds.height / 2
    }
}

// MARK: - Setup

private extension PremiumTableCheckoutVC {

    func setupUI() {
        setupScroll()
        setupHeader()
        setupSeatingTitle()
        setupTags()
        setupShimmer()
        setupGuestDisplay()
        setupSpendCard()
        setupPaymentRow()
        setupPromoRow()
        setupCheckboxes()
        setupTimerBanner()
        setupBottomBar()
        setupConstraints()
        showShimmer(true)
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
        seatingIcon.image          = UIImage(systemName: "sparkles")
        seatingIcon.tintColor      = UIColor(hex: "#C9922B")
        seatingIcon.contentMode    = .scaleAspectFit
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
        tagsRow.addSubview(guestTag)
        contentView.addSubview(tagsRow)
    }

    func setupShimmer() {
        shimmerContainer.translatesAutoresizingMaskIntoConstraints = false
        shimmerContainer.backgroundColor = .clear
        contentView.addSubview(shimmerContainer)

        shimmerStack.axis    = .vertical
        shimmerStack.spacing = 10
        shimmerStack.translatesAutoresizingMaskIntoConstraints = false
        shimmerContainer.addSubview(shimmerStack)

        func block(h: CGFloat, w: CGFloat? = nil) -> ShimmerViewV3 {
            let v = ShimmerViewV3()
            v.cornerRadius = 10
            v.translatesAutoresizingMaskIntoConstraints = false
            v.heightAnchor.constraint(equalToConstant: h).isActive = true
            if let w { v.widthAnchor.constraint(equalToConstant: w).isActive = true }
            return v
        }

        [block(h: 56), block(h: 72), block(h: 56), block(h: 56), block(h: 44, w: 200)].forEach {
            shimmerStack.addArrangedSubview($0)
            $0.startShimmer()
        }

        NSLayoutConstraint.activate([
            shimmerStack.topAnchor.constraint(equalTo: shimmerContainer.topAnchor),
            shimmerStack.leadingAnchor.constraint(equalTo: shimmerContainer.leadingAnchor),
            shimmerStack.trailingAnchor.constraint(equalTo: shimmerContainer.trailingAnchor),
            shimmerStack.bottomAnchor.constraint(equalTo: shimmerContainer.bottomAnchor)
        ])
    }

    func setupGuestDisplay() {
        guestDisplayRow.translatesAutoresizingMaskIntoConstraints = false
        guestDisplayRow.isHidden = true
        contentView.addSubview(guestDisplayRow)
    }

    func setupSpendCard() {
        spendCard.translatesAutoresizingMaskIntoConstraints = false
        spendCard.isHidden = true
        contentView.addSubview(spendCard)
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
        contentView.addSubview(promoRow)
    }

    func setupCheckboxes() {
        termsCheckbox.labelText = "Terms & Conditions"
        termsCheckbox.translatesAutoresizingMaskIntoConstraints = false
        termsCheckbox.isHidden = true
        contentView.addSubview(termsCheckbox)

        marketingCheck.labelText = "I agree to receive marketing related text messages from E11EVEN. Msg & data rates may apply. Reply STOP to opt out or HELP for support."
        marketingCheck.translatesAutoresizingMaskIntoConstraints = false
        marketingCheck.isHidden = true
        contentView.addSubview(marketingCheck)
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

        bottomPrice.font      = Constant.Font.geistMedium(size: 18)
        bottomPrice.textColor = .white
        bottomPrice.translatesAutoresizingMaskIntoConstraints = false

        bottomSub.text      = "deposit incl. fees"
        bottomSub.font      = Constant.Font.geistRegular(size: 12)
        bottomSub.textColor = UIColor.white.withAlphaComponent(0.55)
        bottomSub.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [bottomPrice, bottomSub])
        stack.axis    = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        buyBtn.setTitle("Buy tickets", for: .normal)
        buyBtn.setTitleColor(.black, for: .normal)
        buyBtn.titleLabel?.font = Constant.Font.geistMedium(size: 16)
        buyBtn.backgroundColor  = UIColor(hex: event?.whiteLabelColor ?? "#E8A030")
        buyBtn.translatesAutoresizingMaskIntoConstraints = false
        buyBtn.addTarget(self, action: #selector(onBuyTapped), for: .touchUpInside)
        buyBtn.isUserInteractionEnabled = false
        buyBtn.alpha = 0.5

        bottomBar.addSubview(stack)
        bottomBar.addSubview(buyBtn)
        view.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            sep.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            stack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            stack.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),

            buyBtn.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            buyBtn.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            buyBtn.widthAnchor.constraint(equalToConstant: 140),
            buyBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}

// MARK: - Constraints

private extension PremiumTableCheckoutVC {

    func setupConstraints() {
        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([

            scrollView.topAnchor.constraint(equalTo: safe.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: timerBanner.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

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

            // Shimmer
            shimmerContainer.topAnchor.constraint(equalTo: tagsRow.bottomAnchor, constant: 16),
            shimmerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            shimmerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Guest display
            guestDisplayRow.topAnchor.constraint(equalTo: tagsRow.bottomAnchor, constant: 16),
            guestDisplayRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            guestDisplayRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            guestDisplayRow.heightAnchor.constraint(equalToConstant: 56),

            // Spend card
            spendCard.topAnchor.constraint(equalTo: guestDisplayRow.bottomAnchor, constant: 10),
            spendCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            spendCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Payment
            paymentRow.topAnchor.constraint(equalTo: spendCard.bottomAnchor, constant: 10),
            paymentRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            paymentRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            paymentRow.heightAnchor.constraint(equalToConstant: 56),

            // Promo
            promoRow.topAnchor.constraint(equalTo: paymentRow.bottomAnchor, constant: 10),
            promoRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            promoRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            promoRow.heightAnchor.constraint(equalToConstant: 56),

            // Terms
            termsCheckbox.topAnchor.constraint(equalTo: promoRow.bottomAnchor, constant: 20),
            termsCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            termsCheckbox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            marketingCheck.topAnchor.constraint(equalTo: termsCheckbox.bottomAnchor, constant: 14),
            marketingCheck.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            marketingCheck.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            marketingCheck.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -120),

            // Timer banner sits above bottom bar
            timerBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timerBanner.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            timerBanner.heightAnchor.constraint(equalToConstant: 36),

            // Bottom bar
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 90)
        ])

        // Shimmer bottom — allow dynamic height
        shimmerContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -120).isActive = true
    }
}

// MARK: - Configure from API

private extension PremiumTableCheckoutVC {

    func configureHeader() {
        eventTitleLabel.text = event?.title
        venueLabel.text      = event?.venue?.name.uppercased()
        let tz = event?.venue?.useTimezone ?? ""
        let date = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, customTimeZone: tz) ?? ""
        let time = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: tz) ?? ""
        dateLabel.text       = date.isEmpty ? "" : "\(date) at \(time)"
        dateLabel.textColor  = UIColor(hex: event?.whiteLabelColor ?? "#E8A030")
        buyBtn.backgroundColor = UIColor(hex: event?.whiteLabelColor ?? "#E8A030")
    }

    func configureGuest() {
        let guestText = guestCount == 1 ? "1 guest" : "\(guestCount) guests"
        guestTag.configure(icon: "person.2", text: guestText)
        guestDisplayRow.configure(
            icon:    UIImage(systemName: "person.2"),
            title:   "Guests",
            value:   "\(guestCount)"
        )
    }

    func configureAfterBooking(_ b: SeatingAreaBookingResponse) {
        guard let breakdown = b.content?.tableBooking?.tableBookingPriceBreakdown else {
            showContent()
            return
        }
        configureSpend(breakdown)
        configurePaymentRow()
        updateBottomPrice(breakdown.total ?? 0)

        if !paymentIntentSecret.isEmpty {
            setupStripe(secret: paymentIntentSecret)
        }
        showContent()
    }

    func configureSpend(_ bd: PriceBreakdown) {
        let base     = bd.base     ?? 0
        let total    = bd.total    ?? 0
        let discount = bd.discount ?? 0

        var items: [SpendLineItem] = []
        items.append(.init(title: "Subtotal", amount: base, isBold: false))

        if let gratuity = bd.gratuity, gratuity > 0 {
            items.append(.init(title: bd.gratuityName ?? "Gratuity", amount: gratuity, isBold: false))
        }
        if let tax = bd.salesTax, tax > 0 {
            items.append(.init(title: bd.salesTaxName ?? "Tax", amount: tax, isBold: false))
        }
        bd.tableBookingPriceBreakdownHasCustomFees?.forEach {
            if let fee = $0.fee, fee > 0 {
                items.append(.init(title: $0.name ?? "Fee", amount: fee, isBold: false))
            }
        }
        if let proc = bd.seFees.flatMap({ s in bd.stripeFees.map { s + $0 } }), proc > 0 {
            items.append(.init(title: "Processing Fee", amount: proc, isBold: false))
        }
        if discount > 0 {
            items.append(.init(title: "Discount", amount: -discount, isBold: false))
        }
        items.append(.init(title: "Total", amount: total, isBold: true))
        items.append(.init(title: "Balance Due at Venue", amount: 0, isBold: true))

        spendCard.configure(currency: currency, items: items)
        isFreeBooking = total <= 0
    }

    func configurePaymentRow() {
        // Check Apple Pay availability
        if PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: [.visa, .masterCard, .amex]
        ) {
            paymentRow.configure(
                icon:  UIImage(named: "ApplePayIcon") ?? UIImage(systemName: "applelogo")!,
                title: "Apple Pay",
                value: "▶"
            )
        } else {
            paymentRow.configure(
                icon:  UIImage(systemName: "creditcard")!,
                title: "Card ending \(extractLast4())",
                value: "▶"
            )
        }
    }

    func extractLast4() -> String {
        // Stripe payment method last4 if available
        return booking?.content?.tableBooking?.paymentId?.suffix(4).description ?? "••••"
    }

    func updateBottomPrice(_ total: Double) {
        bottomPrice.text = total <= 0
            ? "Free"
            : "\(currency)\(String(format: "%.2f", total))"
    }

    func showContent() {
        showShimmer(false)
        guestDisplayRow.isHidden = false
        spendCard.isHidden       = false
        paymentRow.isHidden      = false
        promoRow.isHidden        = false
        termsCheckbox.isHidden   = false
        marketingCheck.isHidden  = false

        UIView.animate(withDuration: 0.2) {
            self.buyBtn.alpha = 1
            self.buyBtn.isUserInteractionEnabled = true
        }
    }

    func showShimmer(_ show: Bool) {
        shimmerContainer.isHidden = !show
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
        let alert = UIAlertController(
            title:   "Session Expired",
            message: "Your reservation time has expired. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - Socket

private extension PremiumTableCheckoutVC {

    func setupSocket() {
        configureHeader()
        configureGuest()
        BookingQueueSocketManager.shared.delegate = self
        if let q = queueId {
            BookingQueueSocketManager.shared.connect(queueId: q)
        }
    }
}

extension PremiumTableCheckoutVC: BookingQueueSocketDelegate {

    func didUpdateQueue(seatingAreaBooking: SeatingAreaBookingResponse?) {
        guard let b = seatingAreaBooking else { return }
        DispatchQueue.main.async {
            switch b.status.lowercased() {
            case "payment":
                self.booking             = b
                self.currentBookingId    = b.content?.tableBooking?.id ?? ""
                self.paymentIntentSecret = b.content?.clientSecret ?? ""
                self.paymentId           = b.content?.tableBooking?.paymentId ?? ""
                self.configureAfterBooking(b)
            case "failed":
                self.showShimmer(false)
                Alert.showToast(b.message ?? "Booking failed")
            default: break
            }
        }
    }
}

// MARK: - Stripe

private extension PremiumTableCheckoutVC {

    func setupStripe(secret: String) {
        STPAPIClient.shared.publishableKey = Stripe.publishableKey
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName   = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"
        config.allowsDelayedPaymentMethods = true
        config.applePay = .init(merchantId: "merchant.com.speakeasy", merchantCountryCode: "US")
        paymentSheet = PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
    }
}

// MARK: - Promo

private extension PremiumTableCheckoutVC {

    func applyPromo(_ code: String) {
        guard let eventId = event?.id,
              let venueId = event?.venue?.id,
              let bookingId = booking?.content?.tableBooking?.id else { return }

        TablePresenter.applyCode(
            eventId: eventId,
            tableBookingId: bookingId,
            code: code,
            venueId: venueId
        ) { [weak self] success, message, data in
            DispatchQueue.main.async {
                guard let self else { return }
                if success, let data {
                    self.isPromoApplied = true
                    self.appliedPromo   = code
                    self.promoRow.setApplied(true)
                    self.configureSpend(data)
                    self.updateBottomPrice(data.total ?? 0)
                    Alert.showToast("Promo code applied")
                } else {
                    Alert.showToast(message ?? "Invalid promo code")
                }
            }
        }
    }

    func removePromo() {
        guard let eventId = event?.id,
              let venueId = event?.venue?.id,
              let bookingId = booking?.content?.tableBooking?.id else { return }

        TablePresenter.removeCode(
            eventId: eventId,
            tableBookingId: bookingId,
            venueId: venueId
        ) { [weak self] success, message, data in
            DispatchQueue.main.async {
                guard let self else { return }
                if success, let data {
                    self.isPromoApplied = false
                    self.appliedPromo   = ""
                    self.promoRow.setApplied(false)
                    self.configureSpend(data)
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
        isPaymentInitiated = true

        if isFreeBooking {
            isPaymentInitiated = false
            confirmAndFinish()
            return
        }

        guard let ps = paymentSheet else {
            isPaymentInitiated = false
            Alert.showToast("Payment not ready")
            return
        }

        ps.present(from: self) { [weak self] result in
            guard let self else { return }
            switch result {
            case .completed:
                self.isPaymentInitiated = false
                self.confirmAndFinish()
            case .canceled:
                self.isPaymentInitiated = false
            case .failed:
                self.isPaymentInitiated = false
            }
        }
    }

    func confirmAndFinish() {
        guard let eventId = event?.id,
              let queueId,
              let venueId = event?.venue?.id else { return }

        let notes = ""

        TablePresenter.confirmSeatingAreaBooking(
            eventId:          eventId,
            queueId:          queueId,
            tableBookingId:   currentBookingId,
            consumerUserId:   UserDefault.shared.user?.id ?? "",
            optedPolicy:      termsCheckbox.isChecked,
            notes:            notes,
            venueId:          venueId
        ) { [weak self] success, message, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.timer?.invalidate()
                    let alert = UIAlertController(
                        title:   "Booking Confirmed",
                        message: "Your table has been reserved.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                } else {
                    Alert.showToast(message ?? Constant.String.somethingWrong)
                }
            }
        }
    }
}
