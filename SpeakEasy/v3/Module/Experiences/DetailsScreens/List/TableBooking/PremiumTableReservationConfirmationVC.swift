//
//  PremiumTableReservationConfirmationVC.swift
//  SpeakEasy-Consumer
//
//  Created by Codex on 29/06/26.
//

import UIKit
import SDWebImage

final class PremiumTableReservationConfirmationVC: UIViewController {

    // MARK: - Input

    var reservationUniqueId: String?
    var tableBookingId: String?
    var reservation: Reservation?
    var sourceBooking: Booking?
    var event: Event?

    // MARK: - Private

    private let tableService = TableService()
    private var isLoading = false
    private var isFeesExpanded = true
    private var feeDetailRows: [ReservationOrderRow] = []

    private var displayEvent: Event? {
        reservation?.event ?? sourceBooking?.event ?? event
    }

    private var currency: String {
        displayEvent?.venue?.venueSettings?.currencySymbol
            ?? reservation?.venue?.venueSettings?.currencySymbol
            ?? sourceBooking?.venueObject?.venueSettings?.currencySymbol
            ?? "$"
    }
    
    private var currencyPosition: String? {
        displayEvent?.venue?.venueSettings?.currencyPosition
            ?? reservation?.venue?.venueSettings?.currencyPosition
            ?? sourceBooking?.venueObject?.venueSettings?.currencyPosition
            ?? "$"
    }

    private var priceBreakdown: PriceBreakdown? {
        reservation?.tableBooking?.tableBookingPriceBreakdown
            ?? sourceBooking?.tableBooking?.tableBookingPriceBreakdown
    }

    private var spendAgreement: PriceBreakdown? {
        reservation?.tableBooking?.spendAgreement
            ?? sourceBooking?.tableBooking?.spendAgreement
    }

    private var isSpendAgreementEnabled: Bool {
        reservation?.event?.venue?.venueSettings?.isEnabledSpendAgreement == true
            || reservation?.venue?.venueSettings?.isEnabledSpendAgreement == true
            || sourceBooking?.event?.venue?.venueSettings?.isEnabledSpendAgreement == true
            || sourceBooking?.venueObject?.venueSettings?.isEnabledSpendAgreement == true
            || event?.venue?.venueSettings?.isEnabledSpendAgreement == true
    }

    // MARK: - UI

    private let backgroundImageView = UIImageView()
    private let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let closeButton = AppIconButton()
    private let eventImageView = UIImageView()
    private let infoCard = ReservationGlassCardView(cornerRadius: 19)
    private let orderCard = ReservationGlassCardView(cornerRadius: 22)
    private let eventsDetailsRow = ReservationActionRow(title: "Events details")
    private let supportRow = ReservationActionRow(title: "Support")
    private let loader = UIActivityIndicatorView(style: .medium)

    private let tableNameLabel = UILabel()
    private let minimumLabel = UILabel()
    private let guestTagView = PremiumTagPillView()
    private let timeTagView = PremiumTagPillView()
    private let confirmationTitleLabel = UILabel()
    private let confirmationNumberLabel = UILabel()
    private let copyButton = UIButton(type: .system)

    private let orderTitleLabel = UILabel()
    private let orderChevron = UIImageView()
    private let orderStack = UIStackView()
    private let orderDividerTop = UIView()

    private var guestTagTrailingToTimeConstraint: NSLayoutConstraint?
    private var guestTagTrailingToCardConstraint: NSLayoutConstraint?

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        configure()
        fetchReservationIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        eventImageView.layer.cornerRadius = 8
    }
}

// MARK: - Setup

private extension PremiumTableReservationConfirmationVC {

    func setupUI() {
        setupBackground()
        setupScroll()
        setupCloseButton()
        setupEventImage()
        setupInfoCard()
        setupOrderCard()
        setupActionRows()
        setupLoader()
        setupConstraints()
    }

    func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.image = UIImage(resource: .premiumExpBg)
        backgroundImageView.alpha = 1
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)

        backgroundBlurView.alpha = 0.16
        backgroundBlurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundBlurView)
    }

    func setupScroll() {
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }

    func setupCloseButton() {
        closeButton.iconTypeValue = AppIconType.close.rawValue
        closeButton.iconSize = 14
        closeButton.buttonSize = 40
        closeButton.iconTintColor = .white
        closeButton.addTarget(self, action: #selector(onCloseTap), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
    }

    func setupEventImage() {
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.clipsToBounds = true
        eventImageView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        eventImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventImageView)
    }

    func setupInfoCard() {
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoCard)

        tableNameLabel.font = Constant.Font.geistMedium(size: 16)
        tableNameLabel.textColor = .white
        tableNameLabel.numberOfLines = 1
        tableNameLabel.translatesAutoresizingMaskIntoConstraints = false

        minimumLabel.font = Constant.Font.geistRegular(size: 10)
        minimumLabel.textColor = .white
        minimumLabel.translatesAutoresizingMaskIntoConstraints = false

        guestTagView.translatesAutoresizingMaskIntoConstraints = false
        timeTagView.translatesAutoresizingMaskIntoConstraints = false

        confirmationTitleLabel.text = "Confirmation number"
        confirmationTitleLabel.font = Constant.Font.geistMedium(size: 16)
        confirmationTitleLabel.textColor = .white
        confirmationTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        confirmationNumberLabel.font = Constant.Font.geistRegular(size: 14)
        confirmationNumberLabel.textColor = .white
        confirmationNumberLabel.adjustsFontSizeToFitWidth = true
        confirmationNumberLabel.minimumScaleFactor = 0.72
        confirmationNumberLabel.translatesAutoresizingMaskIntoConstraints = false

        configureCopyButton()

        infoCard.addSubview(tableNameLabel)
        infoCard.addSubview(minimumLabel)
        infoCard.addSubview(guestTagView)
        infoCard.addSubview(timeTagView)
        infoCard.addSubview(confirmationTitleLabel)
        infoCard.addSubview(confirmationNumberLabel)
        infoCard.addSubview(copyButton)
    }

    func configureCopyButton() {
        copyButton.setTitle("Copy", for: .normal)
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.titleLabel?.font = Constant.Font.geistMedium(size: 8)
        copyButton.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        copyButton.layer.cornerRadius = 12
        copyButton.layer.borderWidth = 1
        copyButton.layer.borderColor = UIColor.white.withAlphaComponent(0.09).cgColor
        copyButton.clipsToBounds = true
        copyButton.tintColor = .white
        copyButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        copyButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 3)
        copyButton.setImage(UIImage(named: "copyIcon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        copyButton.imageView?.contentMode = .scaleAspectFit
        copyButton.addTarget(self, action: #selector(onCopyTap), for: .touchUpInside)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupOrderCard() {
        orderCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(orderCard)

        orderTitleLabel.text = "Your order"
        orderTitleLabel.font = Constant.Font.geistRegular(size: 16)
        orderTitleLabel.textColor = .white
        orderTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        orderChevron.image = UIImage(named: "arrowTopIcon")?.withRenderingMode(.alwaysTemplate)
        orderChevron.tintColor = UIColor.white.withAlphaComponent(0.65)
        orderChevron.contentMode = .scaleAspectFit
        orderChevron.translatesAutoresizingMaskIntoConstraints = false

        orderStack.axis = .vertical
        orderStack.spacing = 13
        orderStack.translatesAutoresizingMaskIntoConstraints = false

        orderDividerTop.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        orderDividerTop.translatesAutoresizingMaskIntoConstraints = false

        orderCard.addSubview(orderTitleLabel)
        orderCard.addSubview(orderChevron)
        orderCard.addSubview(orderDividerTop)
        orderCard.addSubview(orderStack)
    }

    func setupActionRows() {
        [eventsDetailsRow, supportRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        eventsDetailsRow.addTarget(self, action: #selector(onEventDetailsTap), for: .touchUpInside)
        supportRow.addTarget(self, action: #selector(onSupportTap), for: .touchUpInside)
    }

    func setupLoader() {
        loader.color = .white
        loader.hidesWhenStopped = true
        loader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loader)
    }
}

// MARK: - Constraints

private extension PremiumTableReservationConfirmationVC {

    func setupConstraints() {
        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backgroundBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: 11),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 11),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            eventImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            eventImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventImageView.widthAnchor.constraint(equalToConstant: 135),
            eventImageView.heightAnchor.constraint(equalToConstant: 135),

            infoCard.topAnchor.constraint(equalTo: eventImageView.bottomAnchor, constant: 13),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            infoCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 126),

            tableNameLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 13),
            tableNameLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 22),
            tableNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: guestTagView.leadingAnchor, constant: -10),

            minimumLabel.topAnchor.constraint(equalTo: tableNameLabel.bottomAnchor, constant: 2),
            minimumLabel.leadingAnchor.constraint(equalTo: tableNameLabel.leadingAnchor),
            minimumLabel.trailingAnchor.constraint(lessThanOrEqualTo: infoCard.trailingAnchor, constant: -22),

            guestTagView.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 18),

            timeTagView.topAnchor.constraint(equalTo: guestTagView.topAnchor),
            timeTagView.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),

            confirmationTitleLabel.topAnchor.constraint(equalTo: minimumLabel.bottomAnchor, constant: 15),
            confirmationTitleLabel.leadingAnchor.constraint(equalTo: tableNameLabel.leadingAnchor),
            confirmationTitleLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -22),

            confirmationNumberLabel.topAnchor.constraint(equalTo: confirmationTitleLabel.bottomAnchor, constant: 9),
            confirmationNumberLabel.leadingAnchor.constraint(equalTo: tableNameLabel.leadingAnchor),
            confirmationNumberLabel.trailingAnchor.constraint(lessThanOrEqualTo: copyButton.leadingAnchor, constant: -8),
            confirmationNumberLabel.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -20),

            copyButton.centerYAnchor.constraint(equalTo: confirmationNumberLabel.centerYAnchor),
            copyButton.heightAnchor.constraint(equalToConstant: 24),
            copyButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 58),
            copyButton.leadingAnchor.constraint(equalTo: confirmationNumberLabel.trailingAnchor, constant: 11),
            copyButton.trailingAnchor.constraint(lessThanOrEqualTo: infoCard.trailingAnchor, constant: -22),

            orderCard.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 8),
            orderCard.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            orderCard.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),

            orderTitleLabel.topAnchor.constraint(equalTo: orderCard.topAnchor, constant: 23),
            orderTitleLabel.leadingAnchor.constraint(equalTo: orderCard.leadingAnchor, constant: 22),

            orderChevron.centerYAnchor.constraint(equalTo: orderTitleLabel.centerYAnchor),
            orderChevron.trailingAnchor.constraint(equalTo: orderCard.trailingAnchor, constant: -22),
            orderChevron.widthAnchor.constraint(equalToConstant: 9),
            orderChevron.heightAnchor.constraint(equalToConstant: 6),

            orderDividerTop.topAnchor.constraint(equalTo: orderTitleLabel.bottomAnchor, constant: 14),
            orderDividerTop.leadingAnchor.constraint(equalTo: orderCard.leadingAnchor, constant: 22),
            orderDividerTop.trailingAnchor.constraint(equalTo: orderCard.trailingAnchor, constant: -22),
            orderDividerTop.heightAnchor.constraint(equalToConstant: 0.5),

            orderStack.topAnchor.constraint(equalTo: orderDividerTop.bottomAnchor, constant: 16),
            orderStack.leadingAnchor.constraint(equalTo: orderCard.leadingAnchor, constant: 22),
            orderStack.trailingAnchor.constraint(equalTo: orderCard.trailingAnchor, constant: -22),
            orderStack.bottomAnchor.constraint(equalTo: orderCard.bottomAnchor, constant: -22),

            eventsDetailsRow.topAnchor.constraint(equalTo: orderCard.bottomAnchor, constant: 12),
            eventsDetailsRow.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            eventsDetailsRow.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            eventsDetailsRow.heightAnchor.constraint(equalToConstant: 50),

            supportRow.topAnchor.constraint(equalTo: eventsDetailsRow.bottomAnchor, constant: 10),
            supportRow.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            supportRow.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            supportRow.heightAnchor.constraint(equalToConstant: 50),
            supportRow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -48),

            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        guestTagTrailingToTimeConstraint = guestTagView.trailingAnchor.constraint(equalTo: timeTagView.leadingAnchor, constant: -3)
        guestTagTrailingToCardConstraint = guestTagView.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16)
        guestTagTrailingToTimeConstraint?.isActive = true
    }
}

// MARK: - Configure

private extension PremiumTableReservationConfirmationVC {

    func configure() {
        configureImages()
        configureInfo()
        configureOrder()
    }

    func configureImages() {
        let key = displayEvent?.flyer?.key ?? ""
        let url = URL(string: key.imageURL)
        eventImageView.sd_setImage(with: url, placeholderImage: Constant.Icon.uploadImage)
    }

    func configureInfo() {

        // Table Name
        let reservationSeatingArea = reservation?.seatingArea
        let bookingSeatingArea = sourceBooking?.seatingArea

        let tableName = (reservationSeatingArea ?? bookingSeatingArea)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        tableNameLabel.text = (tableName?.isEmpty == false)
            ? tableName
            : "Table seating"

        // Minimum Spend
        let reservationMinimum = reservation?.minimum
        let bookingMinimum = sourceBooking?.minimum
        let slotMinimum = reservation?.timeSlot?.minimum
        let baseMinimum = priceBreakdown?.base

        
        let minimum = reservationMinimum
            ?? bookingMinimum
            ?? slotMinimum
            ?? baseMinimum
            ?? 0

        minimumLabel.text = "\(formatMoney(minimum)) spend minimum"

        // Guests
        let reservationGuests = reservation?.guestsTotal
        let bookingGuests = sourceBooking?.guestsTotal
        let reservationGuestTotal = reservation?.guests?.total
        let bookingGuestTotal = sourceBooking?.guests?.total

        let guests = reservationGuests
            ?? bookingGuests
            ?? reservationGuestTotal
            ?? bookingGuestTotal
            ?? 0

        let guestText: String
        if guests <= 1 {
            guestText = "\(max(guests, 1)) guest"
        } else {
            guestText = "\(guests) guests"
        }

        guestTagView.configure(style: .guests, text: guestText)

        // Time
        let startTime = reservation?.timeSlot?.startTime
        let reservationTime = reservation?.time
        let bookingTime = sourceBooking?.time

        let timeText = formattedTime(
            startTime
            ?? reservationTime
            ?? bookingTime
        )

        let hasTime = !timeText.isEmpty

        timeTagView.isHidden = !hasTime
        guestTagTrailingToTimeConstraint?.isActive = hasTime
        guestTagTrailingToCardConstraint?.isActive = !hasTime

        if hasTime {
            timeTagView.configure(style: .time, text: timeText)
        }

        // Confirmation Number
        let confirmationNumber = reservation?.uniqueId
            ?? reservationUniqueId
            ?? sourceBooking?.uniqueId
            ?? "-"

        confirmationNumberLabel.text = confirmationNumber

        copyButton.setTitle("Copy", for: .normal)
    }

    func configureOrder() {
        orderStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let deposit = priceBreakdown?.base
            ?? reservation?.timeSlot?.deposit
            ?? 0
        let service = priceBreakdown?.gratuity ?? 0
        let processingFees = (priceBreakdown?.seFees ?? 0) + (priceBreakdown?.stripeFees ?? 0)
        let customFees = priceBreakdownCustomFees()
        let tax = priceBreakdown?.salesTax ?? 0
        let discount = priceBreakdown?.discount ?? 0
        let feesTotal = processingFees + customFees.reduce(0) { $0 + $1.amount } + tax
        let total = priceBreakdown?.total ?? max(0, deposit + service + feesTotal - discount)
        feeDetailRows = []

        orderStack.addArrangedSubview(ReservationOrderRow(
            title: "Table Minimum Deposit",
            amount: formatMoney(deposit),
            titleFont: Constant.Font.geistMedium(size: 14),
            amountFont: Constant.Font.geistRegular(size: 14)
        ))

        if service > 0 {
            orderStack.addArrangedSubview(ReservationOrderRow(
                title: priceBreakdown?.gratuityName?.isEmpty == false ? priceBreakdown!.gratuityName! : "Service",
                amount: formatMoney(service),
                titleFont: Constant.Font.geistRegular(size: 14),
                amountFont: Constant.Font.geistRegular(size: 14)
            ))
        }

        if feesTotal > 0 {
            let feesRow = ReservationOrderRow(
                title: "Fees",
                amount: formatMoney(feesTotal),
                titleFont: Constant.Font.geistRegular(size: 14),
                amountFont: Constant.Font.geistRegular(size: 14),
                showsChevron: true
            )
            feesRow.setChevronExpanded(isFeesExpanded)
            let feesTap = UITapGestureRecognizer(target: self, action: #selector(onFeesTap))
            feesRow.addGestureRecognizer(feesTap)
            feesRow.isUserInteractionEnabled = true
            orderStack.addArrangedSubview(feesRow)

            if processingFees > 0 {
                let row = ReservationOrderRow(
                    title: "Processing Fee",
                    amount: formatMoney(processingFees),
                    titleFont: Constant.Font.geistRegular(size: 14),
                    amountFont: Constant.Font.geistRegular(size: 14),
                    titleColor: UIColor.white.withAlphaComponent(0.75),
                    amountColor: UIColor.white.withAlphaComponent(0.75),
                    leftInset: 18
                )
                row.isHidden = !isFeesExpanded
                feeDetailRows.append(row)
                orderStack.addArrangedSubview(row)
            }

            customFees.forEach { fee in
                let row = ReservationOrderRow(
                    title: fee.title,
                    amount: formatMoney(fee.amount),
                    titleFont: Constant.Font.geistRegular(size: 14),
                    amountFont: Constant.Font.geistRegular(size: 14),
                    titleColor: UIColor.white.withAlphaComponent(0.75),
                    amountColor: UIColor.white.withAlphaComponent(0.75),
                    leftInset: 18
                )
                row.isHidden = !isFeesExpanded
                feeDetailRows.append(row)
                orderStack.addArrangedSubview(row)
            }

            if tax > 0 {
                let row = ReservationOrderRow(
                    title: priceBreakdown?.salesTaxName?.isEmpty == false ? priceBreakdown!.salesTaxName! : "Tax",
                    amount: formatMoney(tax),
                    titleFont: Constant.Font.geistRegular(size: 14),
                    amountFont: Constant.Font.geistRegular(size: 14),
                    titleColor: UIColor.white.withAlphaComponent(0.75),
                    amountColor: UIColor.white.withAlphaComponent(0.75),
                    leftInset: 18
                )
                row.isHidden = !isFeesExpanded
                feeDetailRows.append(row)
                orderStack.addArrangedSubview(row)
            }
        }

        if discount > 0 {
            orderStack.addArrangedSubview(ReservationOrderRow(
                title: "Discount",
                amount: formatMoney(-discount),
                titleFont: Constant.Font.geistRegular(size: 14),
                amountFont: Constant.Font.geistRegular(size: 14)
            ))
        }

        let separator = makeOrderSeparator()
        let totalRow = ReservationOrderRow(
            title: "Total",
            subtitle: "Tax included",
            amount: formatMoney(total),
            titleFont: Constant.Font.geistMedium(size: 16),
            amountFont: Constant.Font.geistMedium(size: 16)
        )
        orderStack.addArrangedSubview(separator)
        orderStack.addArrangedSubview(totalRow)
        orderStack.setCustomSpacing(14, after: separator)

        guard let spendAgreement, shouldShowSpendAgreement(spendAgreement) else { return }

        orderStack.setCustomSpacing(20, after: totalRow)
        orderStack.addArrangedSubview(ReservationOrderRow(
            title: "Spend Agreement",
            amount: nil,
            titleFont: Constant.Font.geistMedium(size: 14),
            amountFont: Constant.Font.geistRegular(size: 12)
        ))

        spendAgreementRows(spendAgreement).forEach {
            orderStack.addArrangedSubview($0)
        }
    }

    func makeOrderSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return view
    }

    func priceBreakdownCustomFees() -> [(title: String, amount: Double)] {
        let fees = priceBreakdown?.tableBookingPriceBreakdownHasCustomFees?.isEmpty == false
            ? priceBreakdown?.tableBookingPriceBreakdownHasCustomFees
            : priceBreakdown?.customFees
        return (fees ?? []).compactMap { fee in
            let amount = fee.fee ?? fee.customFee ?? 0
            guard amount > 0 else { return nil }
            return (fee.name ?? fee.customFeeName ?? "Fee", amount)
        }
    }

    func spendAgreementRows(_ spendAgreement: PriceBreakdown) -> [ReservationOrderRow] {
        var rows: [ReservationOrderRow] = []
        rows.append(
            ReservationOrderRow(
                title: "Subtotal",
                amount: formatMoney(spendAgreement.base ?? 0),
                titleFont: Constant.Font.geistRegular(size: 14),
                amountFont: Constant.Font.geistRegular(size: 12)
            )
        )
        rows.append(
            ReservationOrderRow(
                title: "Total",
                amount: formatMoney(spendAgreement.total ?? 0),
                titleFont: Constant.Font.geistMedium(size: 14),
                amountFont: Constant.Font.geistMedium(size: 14)
            )
        )
        rows.append(
            ReservationOrderRow(
                title: "Balance Due at Venue",
                amount: formatMoney(spendAgreement.balanceDueAtVenue ?? 0),
                titleFont: Constant.Font.geistMedium(size: 14),
                amountFont: Constant.Font.geistMedium(size: 14)
            )
        )

        return rows
    }

    func shouldShowSpendAgreement(_ spendAgreement: PriceBreakdown) -> Bool {
        if isSpendAgreementEnabled { return true }
        return spendAgreement.base != nil
            || spendAgreement.total != nil
            || spendAgreement.balanceDueAtVenue != nil
            || spendAgreement.gratuity != nil
            || spendAgreement.salesTax != nil
            || spendAgreement.customFees?.isEmpty == false
            || spendAgreement.tableBookingPriceBreakdownHasCustomFees?.isEmpty == false
    }

    func fetchReservationIfNeeded() {
        guard let uniqueId = reservationUniqueId ?? reservation?.uniqueId ?? sourceBooking?.uniqueId,
              !uniqueId.isEmpty,
              !isLoading else { return }

        isLoading = true
        loader.startAnimating()

        tableService.fetchConsumerReservation(uniqueId: uniqueId) { [weak self] success, message, reservation in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.loader.stopAnimating()
                if success, let reservation {
                    self.reservation = reservation
                    self.reservationUniqueId = reservation.uniqueId
                    self.sourceBooking = nil
                    self.configure()
                } else if self.reservation == nil {
                    Alert.showToast(message ?? Constant.String.somethingWrong)
                }
            }
        }
    }
}

// MARK: - Actions

private extension PremiumTableReservationConfirmationVC {

    @objc func onCloseTap() {
        if let navigationController,
           navigationController.viewControllers.first !== self {
            navigationController.popViewController(animated: true)
        } else {
            dismissPremium()
        }
    }

    @objc func onCopyTap() {
        let text = confirmationNumberLabel.text ?? ""
        guard !text.isEmpty, text != "-" else { return }
        UIPasteboard.general.string = text
        copyButton.setTitle("Copied", for: .normal)
        Alert.showToast("Copied")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            self?.copyButton.setTitle("Copy", for: .normal)
        }
    }

    @objc func onFeesTap() {
        isFeesExpanded.toggle()
        feeDetailRows.forEach { $0.isHidden = !isFeesExpanded }
        if let feesRow = orderStack.arrangedSubviews.compactMap({ $0 as? ReservationOrderRow }).first(where: { $0.rowTitle == "Fees" }) {
            feesRow.setChevronExpanded(isFeesExpanded)
        }
    }

    @objc func onEventDetailsTap() {
        guard let event = displayEvent else { return }
        Navigate.eventDetailsVC(self, event: event)
    }

    @objc func onSupportTap() {
        Navigate.externalURL(APIBuilder.supportURL)
    }
}

// MARK: - Formatting

private extension PremiumTableReservationConfirmationVC {

    func formatMoney(_ value: Double) -> String {
        let absoluteValue = abs(value)
        let prefix = value < 0 ? "-" : ""
        return "\(prefix)\(CurrencyFormatter.amount(absoluteValue, symbol: currency, position: currencyPosition))"
    }

    func formattedTime(_ value: String?) -> String {
        guard let value,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: value) ?? {
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            return fallback.date(from: value)
        }()

        guard let date else { return "" }

        let display = DateFormatter()
        display.dateFormat = DateFormat.hmma.rawValue
        display.timeZone = TimeZone(
            identifier: displayEvent?.venue?.useTimezone
                ?? displayEvent?.venue?.timezone
                ?? reservation?.venue?.useTimezone
                ?? reservation?.venue?.timezone
                ?? sourceBooking?.venueObject?.useTimezone
                ?? sourceBooking?.venueObject?.timezone
                ?? ""
        ) ?? .current
        return display.string(from: date)
    }
}

// MARK: - Supporting Views

private final class ReservationGlassCardView: UIView {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let fillView = UIView()
    private let cornerRadiusValue: CGFloat

    init(cornerRadius: CGFloat) {
        cornerRadiusValue = cornerRadius
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        [self, blurView, fillView].forEach {
            $0.layer.cornerRadius = cornerRadiusValue
            $0.layer.cornerCurve = .continuous
        }
    }

    private func setup() {
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor

        blurView.alpha = 0.85
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)

        fillView.backgroundColor = UIColor.black.withAlphaComponent(0.40)
        fillView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fillView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            fillView.topAnchor.constraint(equalTo: topAnchor),
            fillView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fillView.trailingAnchor.constraint(equalTo: trailingAnchor),
            fillView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

private final class ReservationOrderRow: UIView {

    private(set) var rowTitle = ""
    private weak var chevron: UIImageView?

    init(
        title: String,
        subtitle: String? = nil,
        amount: String?,
        titleFont: UIFont,
        amountFont: UIFont,
        titleColor: UIColor = .white,
        amountColor: UIColor = .white,
        leftInset: CGFloat = 0,
        showsChevron: Bool = false
    ) {
        super.init(frame: .zero)
        setup(
            title: title,
            subtitle: subtitle,
            amount: amount,
            titleFont: titleFont,
            amountFont: amountFont,
            titleColor: titleColor,
            amountColor: amountColor,
            leftInset: leftInset,
            showsChevron: showsChevron
        )
    }

    required init?(coder: NSCoder) { fatalError() }

    func setChevronExpanded(_ isExpanded: Bool) {
        chevron?.transform = isExpanded ? .identity : CGAffineTransform(rotationAngle: .pi)
    }

    private func setup(
        title: String,
        subtitle: String?,
        amount: String?,
        titleFont: UIFont,
        amountFont: UIFont,
        titleColor: UIColor,
        amountColor: UIColor,
        leftInset: CGFloat,
        showsChevron: Bool
    ) {
        rowTitle = title

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        titleLabel.numberOfLines = 1

        let titleLineStack = UIStackView(arrangedSubviews: [titleLabel])
        titleLineStack.axis = .horizontal
        titleLineStack.alignment = .center
        titleLineStack.spacing = 7

        if showsChevron {
            let chevron = UIImageView(image: UIImage(named: "arrowTopIcon")?.withRenderingMode(.alwaysTemplate))
            chevron.tintColor = .white
            chevron.contentMode = .scaleAspectFit
            chevron.translatesAutoresizingMaskIntoConstraints = false
            chevron.widthAnchor.constraint(equalToConstant: 9).isActive = true
            chevron.heightAnchor.constraint(equalToConstant: 6).isActive = true
            titleLineStack.addArrangedSubview(chevron)
            self.chevron = chevron
        }

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = Constant.Font.geistRegular(size: 10)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.52)
        subtitleLabel.isHidden = subtitle?.isEmpty != false

        let textStack = UIStackView(arrangedSubviews: [titleLineStack, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let amountLabel = UILabel()
        amountLabel.text = amount
        amountLabel.font = amountFont
        amountLabel.textColor = amountColor
        amountLabel.textAlignment = .right
        amountLabel.isHidden = amount == nil
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(textStack)
        addSubview(amountLabel)

        var constraints = [
            textStack.topAnchor.constraint(equalTo: topAnchor),
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftInset),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        if amount == nil {
            constraints.append(textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor))
        } else {
            constraints.append(contentsOf: [
                textStack.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -12),
                amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                amountLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor),
                amountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 70)
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }
}

private final class ReservationActionRow: UIControl {

    private let card = ReservationGlassCardView(cornerRadius: 13)
    private let titleLabel = UILabel()
    private let chevron = UIImageView()

    init(title: String) {
        super.init(frame: .zero)
        setup(title: title)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup(title: String) {
        card.isUserInteractionEnabled = false
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        titleLabel.text = title
        titleLabel.font = Constant.Font.geistRegular(size: 16)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        chevron.image = UIImage(named: "arrowTopIcon")?.withRenderingMode(.alwaysTemplate)
        chevron.tintColor = UIColor.white.withAlphaComponent(0.65)
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(chevron)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 9),
            chevron.heightAnchor.constraint(equalToConstant: 7)
        ])
    }
}
