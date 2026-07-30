//
//  PremiumTableSeatingVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 26/06/26.
//

import UIKit

final class PremiumTableSeatingVC: UIViewController {

    // MARK: - Input

    var seatingArea: SeatingArea?
    var event: Event?
    var promotionLinkId = ""
    var promotionLinkUniqueCode = ""

    /// Called when user taps Checkout
    var onCheckout: ((_ guestCount: Int, _ seatingArea: SeatingArea, _ event: Event) -> Void)?
    var onInquiry: ((_ seatingArea: SeatingArea) -> Void)?

    // MARK: - State

    private var currentGuestCount: Int = 1
    private var isExpanded = false
    private var availableTimeSlots: [TableTimeSlot] = []
    private var selectedTimeSlot: TableTimeSlot?
    private var selectedTimeIndex = 0

    // MARK: - UI

    private let scrollView        = UIScrollView()
    private let contentView       = UIView()

    private let titleRow          = UIView()
    private let titleCenterStack  = UIStackView()
    private let titleIcon         = UIImageView()
    private let titleLabel        = UILabel()

    private let tagsRow           = UIView()
    private let guestTagView      = PremiumTagPillView()
    private let timeTagView       = PremiumTagPillView()

    private let divider           = UIView()

    private let highlightLabel    = UILabel()
    private let descLabel         = UILabel()

    private let guestRow          = PremiumStepperRow()
    private let arrivalTimeView   = PremiumArrivalTimeView()
    private let priceCard         = PremiumPriceCard()
    private let spendAgreementView = PremiumSpendAgreementView()

    private let bottomBar         = UIView()
    private let bottomCheckoutCard = UIView()
    private let bottomPriceLabel  = UILabel()
    private let bottomSubLabel    = UILabel()
    private let inquiryBtn        = UIButton(type: .system)
    private let checkoutBtn       = UIButton(type: .system)
    private let checkoutLoader    = UIActivityIndicatorView(style: .medium)
    
    private let backBtn = AppIconButton()

    private var priceTopToArrivalConstraint: NSLayoutConstraint?
    private var priceTopToGuestConstraint: NSLayoutConstraint?
    private var priceCardHeightConstraint: NSLayoutConstraint?
    private var spendTopToPriceConstraint: NSLayoutConstraint?
    private var spendAgreementHeightConstraint: NSLayoutConstraint?
    private var contentBottomToPriceConstraint: NSLayoutConstraint?
    private var contentBottomToSpendConstraint: NSLayoutConstraint?
    private var bottomBarHeightConstraint: NSLayoutConstraint?
    private var inquiryButtonHeightConstraint: NSLayoutConstraint?
    private var checkoutTopToInquiryConstraint: NSLayoutConstraint?
    private var checkoutTopToSeparatorConstraint: NSLayoutConstraint?
    private var lastDepositProcessingFees: Double = 0
    private var currentSpendAgreementItems: [SpendLineItem] = []
    private let tableService = TableService()
    private var appliedPremiumGradientBounds: CGRect = .zero

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#070808")
        setupUI()
        configureData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyPremiumBackgroundIfNeeded()
        bottomCheckoutCard.layer.cornerRadius = 30
        bottomCheckoutCard.layer.masksToBounds = true
        checkoutBtn.layer.cornerRadius = 24
        checkoutBtn.layer.masksToBounds = true
        inquiryBtn.layer.cornerRadius = 26
        inquiryBtn.layer.masksToBounds = true
        updateArrivalTimeHeight()
    }
}

// MARK: - Setup

private extension PremiumTableSeatingVC {

    func setupUI() {
        setupScroll()
        setupTitle()
        setupTags()
        setupDivider()
        setupDescriptions()
        setupGuestRow()
        setupArrivalTimeView()
        setupPriceCard()
        setupSpendAgreementView()
        setupBottomBar()
        setupConstraints()
    }

    func applyPremiumBackgroundIfNeeded() {
        guard appliedPremiumGradientBounds != view.bounds else { return }
        appliedPremiumGradientBounds = view.bounds
        view.applyPremiumScreenBgGradient()
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
    
    func setupTitle() {
        backBtn.iconTypeValue = AppIconType.close.rawValue
        backBtn.iconSize = 14
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onBackTap), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        
        titleIcon.image = UIImage(resource: .premiumExpStartIcon)
        titleIcon.contentMode = .scaleAspectFit
        titleIcon.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Table seating"
        titleLabel.font = Constant.Font.geistMedium(size: 16)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleRow.translatesAutoresizingMaskIntoConstraints = false
        titleCenterStack.axis = .horizontal
        titleCenterStack.alignment = .center
        titleCenterStack.spacing = 8
        titleCenterStack.translatesAutoresizingMaskIntoConstraints = false
        titleCenterStack.addArrangedSubview(titleIcon)
        titleCenterStack.addArrangedSubview(titleLabel)

        titleRow.addSubview(backBtn)
        titleRow.addSubview(titleCenterStack)
        view.addSubview(titleRow)
    }

    func setupTags() {
        tagsRow.translatesAutoresizingMaskIntoConstraints = false
        guestTagView.translatesAutoresizingMaskIntoConstraints = false
        timeTagView.translatesAutoresizingMaskIntoConstraints = false
        tagsRow.addSubview(guestTagView)
        tagsRow.addSubview(timeTagView)
        contentView.addSubview(tagsRow)
    }

    func setupDivider() {
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        divider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(divider)
    }

    func setupDescriptions() {
        highlightLabel.font      = Constant.Font.geistMedium(size: 14)
        highlightLabel.textColor = .white
        highlightLabel.numberOfLines = 0
        highlightLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(highlightLabel)

        descLabel.font      = Constant.Font.geistRegular(size: 12)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descLabel)

    }

    func setupGuestRow() {
        guestRow.translatesAutoresizingMaskIntoConstraints = false
        guestRow.configure(
            icon: UIImage(resource: .guestIcon).withRenderingMode(.alwaysTemplate),
            title: "Guests"
        )
        guestRow.onValueChanged = { [weak self] val in
            self?.currentGuestCount = val
            self?.updatePricing()
        }
        contentView.addSubview(guestRow)
    }

    func setupArrivalTimeView() {
        arrivalTimeView.translatesAutoresizingMaskIntoConstraints = false
        arrivalTimeView.isHidden = true
        arrivalTimeView.onSelectionChanged = { [weak self] index in
            guard let self else { return }
            self.selectedTimeIndex = index
            self.selectedTimeSlot = self.availableTimeSlots.indices.contains(index)
                ? self.availableTimeSlots[index]
                : nil
            self.updatePricing()
        }
        contentView.addSubview(arrivalTimeView)
    }

    func setupPriceCard() {
        priceCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(priceCard)
    }

    func setupSpendAgreementView() {
        spendAgreementView.translatesAutoresizingMaskIntoConstraints = false
        spendAgreementView.isHidden = true
        spendAgreementView.onHeightChanged = { [weak self] height, animated in
            self?.spendAgreementHeightConstraint?.constant = height
            guard animated else {
                self?.view.layoutIfNeeded()
                return
            }

            UIView.animate(
                withDuration: 0.24,
                delay: 0,
                options: [.curveEaseInOut, .allowUserInteraction],
                animations: {
                    self?.view.layoutIfNeeded()
                }
            )
        }
        contentView.addSubview(spendAgreementView)
    }

    func setupBottomBar() {
        bottomBar.backgroundColor = UIColor(hex: "#070808")
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        let sep = UIView()
        sep.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        sep.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(sep)

        bottomCheckoutCard.backgroundColor = .white
        bottomCheckoutCard.layer.cornerRadius = 30
        bottomCheckoutCard.layer.cornerCurve = .continuous
        bottomCheckoutCard.layer.masksToBounds = true
        bottomCheckoutCard.clipsToBounds = true
        bottomCheckoutCard.translatesAutoresizingMaskIntoConstraints = false

        bottomPriceLabel.font      = Constant.Font.geistMedium(size: 18)
        bottomPriceLabel.textColor = UIColor(hex: "#121212")
        bottomPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        bottomSubLabel.text      = "deposit incl. fees"
        bottomSubLabel.font      = Constant.Font.geistMedium(size: 12)
        bottomSubLabel.textColor = UIColor(hex: "#737373")
        bottomSubLabel.translatesAutoresizingMaskIntoConstraints = false

        let labelStack = UIStackView(arrangedSubviews: [bottomPriceLabel, bottomSubLabel])
        labelStack.axis    = .vertical
        labelStack.spacing = 2
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        let checkoutButtonColor = UIColor(hex: "#D99935")
        let checkoutTextColor = checkoutButtonColor.suitableTextColor()

        checkoutBtn.setTitle("Checkout", for: .normal)
        checkoutBtn.setTitleColor(checkoutTextColor, for: .normal)
        checkoutBtn.setTitleColor(checkoutTextColor.withAlphaComponent(0.75), for: .highlighted)
        checkoutBtn.tintColor = checkoutTextColor
        checkoutBtn.titleLabel?.font = Constant.Font.geistMedium(size: 16)
        checkoutBtn.backgroundColor  = checkoutButtonColor
        checkoutBtn.layer.cornerRadius = 24
        checkoutBtn.layer.cornerCurve = .continuous
        checkoutBtn.layer.masksToBounds = true
        checkoutBtn.clipsToBounds = true
        checkoutBtn.translatesAutoresizingMaskIntoConstraints = false
        checkoutBtn.addTarget(self, action: #selector(onCheckoutTapped), for: .touchUpInside)

        inquiryBtn.setTitle("INQUIRE", for: .normal)
        inquiryBtn.setTitleColor(.white, for: .normal)
        inquiryBtn.titleLabel?.font = Constant.Font.geistMedium(size: 15)
        inquiryBtn.backgroundColor = .clear
        inquiryBtn.layer.cornerRadius = 26
        inquiryBtn.layer.cornerCurve = .continuous
        inquiryBtn.layer.borderWidth = 1
        inquiryBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.95).cgColor
        inquiryBtn.layer.masksToBounds = true
        inquiryBtn.clipsToBounds = true
        inquiryBtn.translatesAutoresizingMaskIntoConstraints = false
        inquiryBtn.addTarget(self, action: #selector(onInquiryTapped), for: .touchUpInside)

        checkoutLoader.color = checkoutTextColor
        checkoutLoader.hidesWhenStopped = true
        checkoutLoader.translatesAutoresizingMaskIntoConstraints = false

        bottomBar.addSubview(inquiryBtn)
        bottomCheckoutCard.addSubview(labelStack)
        bottomCheckoutCard.addSubview(checkoutBtn)
        checkoutBtn.addSubview(checkoutLoader)
        bottomBar.addSubview(bottomCheckoutCard)
        view.addSubview(bottomBar)

        let inquiryHeight = inquiryBtn.heightAnchor.constraint(equalToConstant: 0)
        let checkoutTopToInquiry = bottomCheckoutCard.topAnchor.constraint(equalTo: inquiryBtn.bottomAnchor, constant: 12)
        let checkoutTopToSep = bottomCheckoutCard.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 22)
        self.inquiryButtonHeightConstraint = inquiryHeight
        self.checkoutTopToInquiryConstraint = checkoutTopToInquiry
        self.checkoutTopToSeparatorConstraint = checkoutTopToSep

        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 22),
            sep.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            sep.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            inquiryBtn.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 22),
            inquiryBtn.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            inquiryBtn.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            inquiryHeight,

            checkoutTopToSep,
            bottomCheckoutCard.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            bottomCheckoutCard.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            bottomCheckoutCard.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -20),

            labelStack.leadingAnchor.constraint(equalTo: bottomCheckoutCard.leadingAnchor, constant: 20),
            labelStack.centerYAnchor.constraint(equalTo: bottomCheckoutCard.centerYAnchor),
            labelStack.trailingAnchor.constraint(lessThanOrEqualTo: checkoutBtn.leadingAnchor, constant: -12),

            checkoutBtn.trailingAnchor.constraint(equalTo: bottomCheckoutCard.trailingAnchor, constant: -8),
            checkoutBtn.centerYAnchor.constraint(equalTo: bottomCheckoutCard.centerYAnchor),
            checkoutBtn.widthAnchor.constraint(equalToConstant: 109),
            checkoutBtn.heightAnchor.constraint(equalToConstant: 48),

            checkoutLoader.centerXAnchor.constraint(equalTo: checkoutBtn.centerXAnchor),
            checkoutLoader.centerYAnchor.constraint(equalTo: checkoutBtn.centerYAnchor)
        ])
    }
    
    @objc
    private func onOutsideTap() {
        self.dismiss(animated: true)
    }
    
    @objc
    private func onBackTap() {
        self.dismiss(animated: false)
    }
}

// MARK: - Constraints

private extension PremiumTableSeatingVC {

    func setupConstraints() {

        let safe = view.safeAreaLayoutGuide
        let bottomHeight = bottomBar.heightAnchor.constraint(equalToConstant: 128)
        let priceTopToArrival = priceCard.topAnchor.constraint(equalTo: arrivalTimeView.bottomAnchor, constant: 10)
        let priceTopToGuest = priceCard.topAnchor.constraint(equalTo: guestRow.bottomAnchor, constant: 10)
        let spendTopToPrice = spendAgreementView.topAnchor.constraint(equalTo: priceCard.bottomAnchor, constant: 10)
        let bottomToPrice = priceCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        let bottomToSpend = spendAgreementView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        let priceCardHeight = priceCard.heightAnchor.constraint(equalToConstant: 68)
        priceTopToGuest.isActive = false
        bottomToSpend.isActive = false
        self.priceTopToArrivalConstraint = priceTopToArrival
        self.priceTopToGuestConstraint = priceTopToGuest
        self.spendTopToPriceConstraint = spendTopToPrice
        self.contentBottomToPriceConstraint = bottomToPrice
        self.contentBottomToSpendConstraint = bottomToSpend
        self.bottomBarHeightConstraint = bottomHeight
        
        NSLayoutConstraint.activate([

            // MARK: Header
            titleRow.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleRow.heightAnchor.constraint(equalToConstant: 30),

            // Back Button
            backBtn.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor),
            backBtn.centerYAnchor.constraint(equalTo: titleRow.centerYAnchor),
            backBtn.widthAnchor.constraint(equalToConstant: 40),
            backBtn.heightAnchor.constraint(equalToConstant: 40),

            // Center title group
            titleCenterStack.centerXAnchor.constraint(equalTo: titleRow.centerXAnchor),
            titleCenterStack.centerYAnchor.constraint(equalTo: titleRow.centerYAnchor),
            titleCenterStack.leadingAnchor.constraint(greaterThanOrEqualTo: backBtn.trailingAnchor, constant: 8),
            titleCenterStack.trailingAnchor.constraint(lessThanOrEqualTo: titleRow.trailingAnchor, constant: -8),

            titleIcon.widthAnchor.constraint(equalToConstant: 18),
            titleIcon.heightAnchor.constraint(equalToConstant: 18),

            // MARK: Bottom Bar
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomHeight,

            // MARK: Scroll
            scrollView.topAnchor.constraint(equalTo: titleRow.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // MARK: Tags
            tagsRow.topAnchor.constraint(equalTo: contentView.topAnchor),
            tagsRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tagsRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tagsRow.heightAnchor.constraint(equalToConstant: 28),

            guestTagView.leadingAnchor.constraint(equalTo: tagsRow.leadingAnchor),
            guestTagView.centerYAnchor.constraint(equalTo: tagsRow.centerYAnchor),

            timeTagView.leadingAnchor.constraint(equalTo: guestTagView.trailingAnchor, constant: 8),
            timeTagView.centerYAnchor.constraint(equalTo: tagsRow.centerYAnchor),
            timeTagView.trailingAnchor.constraint(lessThanOrEqualTo: tagsRow.trailingAnchor),

            // Divider
            divider.topAnchor.constraint(equalTo: tagsRow.bottomAnchor, constant: 14),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            // Highlight
            highlightLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14),
            highlightLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            highlightLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Description
            descLabel.topAnchor.constraint(equalTo: highlightLabel.bottomAnchor, constant: 6),
            descLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Guest
            guestRow.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 16),
            guestRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            guestRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            guestRow.heightAnchor.constraint(equalToConstant: 56),

            // Arrival Time
            arrivalTimeView.topAnchor.constraint(equalTo: guestRow.bottomAnchor, constant: 10),
            arrivalTimeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            arrivalTimeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Price
            priceTopToArrival,
            priceCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            priceCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            priceCardHeight,

            // Spend agreement
            spendTopToPrice,
            spendAgreementView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            spendAgreementView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Content Bottom
            bottomToPrice,
            bottomToSpend
        ])

        spendAgreementHeightConstraint = spendAgreementView.heightAnchor.constraint(equalToConstant: 0)
        spendAgreementHeightConstraint?.isActive = true
        priceCardHeightConstraint = priceCardHeight
    }
}

// MARK: - Configure

private extension PremiumTableSeatingVC {

    func configureData() {
        guard let area = seatingArea else { return }

        updateInquiryButtonState(for: area)

        let areaName = area.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        titleLabel.text = areaName?.isEmpty == false ? areaName : "Table seating"

        // Guest tag
        let minG = area.defaultGuest ?? 0
        let maxG = area.maxGuest ?? 0
        let guestText = minG > 0 && maxG > 0
            ? (minG == maxG ? "\(minG) guests" : "\(minG)-\(maxG) guests")
            : "\(maxG) guests"
        guestTagView.configure(style: .guests, text: guestText)

        configureTimeSlots(for: area)

        if let timeText = timeTagText(for: area), !timeText.isEmpty {
            timeTagView.isHidden = false
            timeTagView.configure(style: .time, text: timeText)
        } else {
            timeTagView.isHidden = true
        }

        let highlight = area.highlight?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        highlightLabel.text = highlight
        highlightLabel.isHidden = highlight.isEmpty

        let description = area.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        descLabel.text = description
        descLabel.isHidden = description.isEmpty

        // Guest stepper
        let minGuest = max(area.defaultGuest ?? 1, 1)
        let maxGuest = max(area.maxGuest ?? minGuest, minGuest)
        currentGuestCount = minGuest
        guestRow.setValue(currentGuestCount, min: minGuest, max: maxGuest)

        updatePricing()
    }

    func updateInquiryButtonState(for area: SeatingArea) {
        let showsInquiry = area.inquiryEnabled == true
        let hidesCheckout = area.hideCheckout == true
        inquiryBtn.isHidden = !showsInquiry
        bottomCheckoutCard.isHidden = hidesCheckout
        inquiryButtonHeightConstraint?.constant = showsInquiry ? 52 : 0
        bottomBarHeightConstraint?.constant = showsInquiry && !hidesCheckout ? 192 : 128
        checkoutTopToSeparatorConstraint?.isActive = !showsInquiry || hidesCheckout
        checkoutTopToInquiryConstraint?.isActive = showsInquiry && !hidesCheckout
    }

    func updatePricing() {
        let minVal = activeMinimum()
        let deposit = calculateDeposit()
        let currency = event?.venue?.venueSettings?.currencySymbol ?? "$"
        let currencyPosition = event?.venue?.venueSettings?.currencyPosition ?? "$"
        let hidePricing = seatingArea?.hidePricing == true
        priceCard.isHidden = hidePricing
        priceCardHeightConstraint?.constant = hidePricing ? 0 : 68
        bottomPriceLabel.isHidden = hidePricing
        bottomSubLabel.isHidden = hidePricing
        if !hidePricing {
            priceCard.configure(minimum: minVal, deposit: deposit, currency: currency, currencyPosition: currencyPosition)
        }
        bottomPriceLabel.text = CurrencyFormatter.amount(deposit, symbol: currency, position: currencyPosition)
        configureSpendAgreement(minimum: minVal, deposit: deposit)
    }

    func activeMinimum() -> Double {
        guard let area = seatingArea else { return 0 }
        let defaultGuests = area.defaultGuest ?? 0
        let extraGuests = max(0, currentGuestCount - defaultGuests)

        if area.bookingType == .timeWise {
            let base = selectedTimeSlot?.minimum ?? area.minimum ?? 0
            let extraCharge = selectedTimeSlot?.extraPersonCharge ?? area.extraPersonCharge ?? 0
            return base + Double(extraGuests) * extraCharge
        }

        return (area.minimum ?? 0) + Double(extraGuests) * (area.extraPersonCharge ?? 0)
    }

    func calculateDeposit() -> Double {
        guard let area = seatingArea else { return 0 }
        lastDepositProcessingFees = 0

        let minValue = activeMinimum()
        let baseDepositValue: Double
        let depositType: String

        if area.bookingType == .timeWise {
            baseDepositValue = selectedTimeSlot?.deposit ?? area.deposit ?? 0
            depositType = selectedTimeSlot?.depositType ?? area.depositType ?? "FLAT"
        } else {
            baseDepositValue = area.deposit ?? 0
            depositType = area.depositType ?? "FLAT"
        }

        var baseDeposit = baseDepositValue

        if depositType.uppercased() == "PERCENTAGE" {
            baseDeposit = (minValue * baseDeposit) / 100
        }

        guard let tableSettings = event?.venue?.venueSettings?.tableBookingSettings else {
            return baseDeposit
        }

        let settings = PremiumTableFeeSettings(tableSettings)
        let seFees = calculateSEFees(for: baseDeposit, settings: settings)
        let customFees = calculateCustomFees(for: baseDeposit, settings: settings, includeGratuity: false)
        let feeResult = calculateBookingFees(
            amountTransferToSE: seFees,
            amountTransferToVenue: baseDeposit,
            customFees: customFees,
            settings: settings
        )

        lastDepositProcessingFees = feeResult.totalProcessingFees

        return max(0, feeResult.amountChargedToConsumer - feeResult.salesTax)
    }

    func configureSpendAgreement(minimum: Double, deposit: Double) {
        let venueSettings = event?.venue?.venueSettings
        guard venueSettings?.isEnabledSpendAgreement == true,
              let spendSettings = venueSettings?.spendAgreementSettings else {
            currentSpendAgreementItems = []
            spendAgreementView.isHidden = true
            spendAgreementHeightConstraint?.constant = 0
            contentBottomToPriceConstraint?.isActive = true
            contentBottomToSpendConstraint?.isActive = false
            return
        }

        let settings = PremiumTableFeeSettings(spendSettings)
        let customFeesWithGratuity = calculateCustomFees(for: minimum, settings: settings, includeGratuity: true)
        let customFeesWithoutGratuity = calculateCustomFees(for: minimum, settings: settings, includeGratuity: false)
        let seFees = calculateSEFees(for: minimum, settings: settings)
        let feeResult = calculateBookingFees(
            amountTransferToSE: seFees,
            amountTransferToVenue: minimum,
            customFees: customFeesWithGratuity,
            settings: settings
        )
        let gratuity = calculateGratuityFees(for: minimum, settings: settings)
        let processingFees = feeResult.totalProcessingFees
        let total = feeResult.amountChargedToConsumer
        let depositCredit = max(
            0,
            deposit - (
                event?.venue?.venueSettings?.tableBookingSettings?.isProcessingFeePassToCustomer == true
                ? lastDepositProcessingFees
                : 0
            )
        )
        let balanceDue = max(0, total - depositCredit)

        var items: [SpendLineItem] = [
            .init(title: "Subtotal", amount: minimum, isBold: false)
        ]

        if settings.isEnableGratuity, gratuity > 0 {
            items.append(.init(title: settings.gratuityFeeName ?? "Gratuity", amount: gratuity, isBold: false))
        }
        if settings.isEnableSalesTax, feeResult.salesTax > 0 {
            items.append(.init(title: settings.salesTaxName ?? "Tax", amount: feeResult.salesTax, isBold: false))
        }
        if settings.isProcessingFeePassToCustomer, processingFees > 0 {
            items.append(.init(title: "Processing Fee", amount: processingFees, isBold: false))
        }
        customFeesWithoutGratuity
            .filter { $0.amount > 0 }
            .forEach { items.append(.init(title: $0.name, amount: $0.amount, isBold: false)) }
        items.append(.init(title: "Total", amount: total, isBold: true))
        items.append(.init(title: "Balance Due at Partner", amount: balanceDue, isBold: true))

        currentSpendAgreementItems = items
        spendAgreementView.configure(currency: event?.venue?.venueSettings?.currencySymbol ?? "$", currencyPosition: event?.venue?.venueSettings?.currencyPosition, items: items, expanded: true)
        spendAgreementView.isHidden = false
        spendAgreementHeightConstraint?.constant = spendAgreementView.preferredHeight
        contentBottomToPriceConstraint?.isActive = false
        contentBottomToSpendConstraint?.isActive = true
    }

    func configureTimeSlots(for area: SeatingArea) {
        guard area.bookingType == .timeWise else {
            availableTimeSlots = []
            selectedTimeIndex = 0
            selectedTimeSlot = nil
            arrivalTimeView.isHidden = true
            priceTopToGuestConstraint?.isActive = true
            priceTopToArrivalConstraint?.isActive = false
            return
        }

        let slots = sortedBookableTimeSlots(for: area)

        let slotOptions = slots.compactMap { slot -> (slot: TableTimeSlot, option: PremiumArrivalTimeOption)? in
            let title = formattedTime(slot.startTime)
            guard !title.isEmpty else { return nil }
            return (slot, PremiumArrivalTimeOption(id: slot.id, title: title))
        }

        availableTimeSlots = slotOptions.map(\.slot)
        selectedTimeIndex = 0
        selectedTimeSlot = availableTimeSlots.first

        let options = slotOptions.map(\.option)

        let hasOptions = !options.isEmpty
        arrivalTimeView.isHidden = !hasOptions
        priceTopToGuestConstraint?.isActive = !hasOptions
        priceTopToArrivalConstraint?.isActive = hasOptions

        arrivalTimeView.configure(
            options: options,
            selectedIndex: selectedTimeIndex,
            accentColor: arrivalTimeAccentColor()
        )
    }

    func updateArrivalTimeHeight() {
        guard !arrivalTimeView.isHidden else { return }
        let width = arrivalTimeView.bounds.width
        guard width > 0 else { return }
        arrivalTimeView.invalidateIntrinsicContentSize()
    }

    func timeTagText(for area: SeatingArea) -> String? {
        guard area.bookingType == .timeWise else { return nil }
        guard !availableTimeSlots.isEmpty else { return nil }
        return availableTimeRangeText()
    }

    func availableTimeRangeText() -> String? {
        guard let first = availableTimeSlots.first else { return nil }
        let startText = formattedTime(first.startTime)
        guard let last = availableTimeSlots.last else { return startText }
        let endText = formattedTime(last.startTime)

        if startText.isEmpty { return nil }
        if endText.isEmpty || startText == endText { return startText }
        return "\(startText) - \(endText)"
    }

    func sortedBookableTimeSlots(for area: SeatingArea) -> [TableTimeSlot] {
        TableTimeSlot.sortedByBusinessStart(
            (area.timeSlots ?? []).filter { $0.isBookable },
            timezone: venueTimezoneIdentifier(),
            businessStartTime: event?.venue?.businessStartTime
        )
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
        formatter.timeZone = TimeZone(
            identifier: venueTimezoneIdentifier()
        ) ?? .current
        return formatter.string(from: date)
    }

    func venueTimezoneIdentifier() -> String {
        if let timezone = event?.venue?.timezone?.trimmingCharacters(in: .whitespacesAndNewlines),
           !timezone.isEmpty {
            return timezone
        }

        let useTimezone = event?.venue?.useTimezone.trimmingCharacters(in: .whitespacesAndNewlines)
        if let useTimezone, !useTimezone.isEmpty {
            return useTimezone
        }

        return TimeZone.current.identifier
    }

    func arrivalTimeAccentColor() -> UIColor {
        UIColor(hex: "#D99935")
    }
}

// MARK: - Actions

private extension PremiumTableSeatingVC {

    @objc func toggleDesc() {
        AppHaptic.selectionChanged()
        isExpanded.toggle()
        descLabel.numberOfLines = 0
        UIView.animate(withDuration: 0.22) { self.view.layoutIfNeeded() }
    }

    @objc func onCheckoutTapped() {
        guard let area = seatingArea, let event else { return }

        guard LoginRequiredCoordinator.isAuthenticated else {
            AppHaptic.warning()
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                self?.onCheckoutTapped()
            }
            return
        }

        AppHaptic.primaryAction()
        let uuid    = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let queueId = "TABLE_BOOKING_QUEUE_\(uuid)"

        setCheckoutLoading(true)

        tableService.createSeatingAreaBooking(
            eventId: event.id,
            seatingAreaId: area.id ?? "",
            timeSlotId: selectedTimeSlot?.id,
            venueId: event.venue?.id ?? "",
            guests: currentGuestCount,
            queueId: queueId,
            consumerUserId: UserDefault.shared.user?.id ?? "",
            stripeCustomerId: UserDefault.shared.user?.stripeCusId ?? "",
            mininumSpend: activeMinimum(),
            promotionLinkId: promotionLinkId,
            promotionLinkUniqueCode: promotionLinkUniqueCode
        ) { [weak self] success, message, response in
            guard let self else { return }
            DispatchQueue.main.async {
                self.setCheckoutLoading(false)
                if success {
                    AppHaptic.success()
                    let vc = PremiumTableCheckoutVC()
                    vc.queueId       = queueId
                    vc.event         = event
                    vc.seatingAreas  = [area]
                    vc.guestCount    = self.currentGuestCount
                    vc.selectedTimeSlot = self.selectedTimeSlot
                    vc.selectedTimeText = self.selectedTimeSlot.map { self.formattedTime($0.startTime) }
                    vc.initialBooking = response
                    vc.promotionLinkId = self.promotionLinkId
                    vc.promotionLinkUniqueCode = self.promotionLinkUniqueCode
                    self.navigationController?.pushViewController(vc, animated: false)
                } else {
                    AppHaptic.error()
                    Alert.showToast(message ?? Constant.String.somethingWrong)
                }
            }
        }
    }

    @objc func onInquiryTapped() {
        guard let area = seatingArea else { return }
        AppHaptic.primaryAction()
        let onInquiry = onInquiry
        dismiss(animated: true) {
            onInquiry?(area)
        }
    }

    func setCheckoutLoading(_ isLoading: Bool) {
        checkoutBtn.isUserInteractionEnabled = !isLoading
        checkoutBtn.setTitle(isLoading ? nil : "Checkout", for: .normal)
        isLoading ? checkoutLoader.startAnimating() : checkoutLoader.stopAnimating()
    }
}

private struct PremiumCalculatedCustomFee {
    let name: String
    let amount: Double
    let isTaxable: Bool
}

private struct PremiumTableFeeResult {
    let amountChargedToConsumer: Double
    let totalProcessingFees: Double
    let salesTax: Double
}

private struct PremiumTableFeeSettings {
    let isProcessingFeePassToCustomer: Bool
    let isProcessingFeeTaxable: Bool
    let isEnableSalesTax: Bool
    let salesTaxName: String?
    let salesTax: Double
    let isEnableCustomFee: Bool
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

    init(_ settings: TableBookingSettings) {
        isProcessingFeePassToCustomer = settings.isProcessingFeePassToCustomer == true
        isProcessingFeeTaxable = settings.isProcessingFeeTaxable == true
        isEnableSalesTax = settings.isEnableSalesTax == true
        salesTaxName = settings.salesTaxName
        salesTax = settings.salesTax ?? 0
        isEnableCustomFee = settings.isEnableCustomFee == true
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

    init(_ settings: SpendAgreementSettings) {
        isProcessingFeePassToCustomer = settings.isProcessingFeePassToCustomer == true
        isProcessingFeeTaxable = settings.isProcessingFeeTaxable == true
        isEnableSalesTax = settings.isEnableSalesTax == true
        salesTaxName = settings.salesTaxName
        salesTax = settings.salesTax ?? 0
        isEnableCustomFee = settings.isEnableCustomFee == true
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

private extension PremiumTableSeatingVC {
    func calculateSEFees(for amount: Double, settings: PremiumTableFeeSettings) -> Double {
        var seFees = 0.0
        if let percentage = settings.speakeasyFeePerc {
            seFees = amount * percentage * 100
        }
        if let flat = settings.speakeasyFeeFlat {
            seFees += amount <= 10 ? amount * 0.1 * flat : flat
        }
        return seFees
    }

    func calculateGratuityFees(for amount: Double, settings: PremiumTableFeeSettings) -> Double {
        guard settings.isEnableGratuity else { return 0 }
        if settings.gratuityFeeType?.uppercased() == "FLAT" {
            return settings.gratuityFee
        }
        return amount * settings.gratuityFee / 100
    }

    func calculateCustomFees(
        for amount: Double,
        settings: PremiumTableFeeSettings,
        includeGratuity: Bool
    ) -> [PremiumCalculatedCustomFee] {
        var fees: [PremiumCalculatedCustomFee] = []
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
                    name: settings.gratuityFeeName ?? "Gratuity",
                    amount: calculateGratuityFees(for: amount, settings: settings),
                    isTaxable: settings.isGratuityTaxable
                )
            )
        }
        return fees
    }

    func calculateBookingFees(
        amountTransferToSE: Double,
        amountTransferToVenue: Double,
        customFees: [PremiumCalculatedCustomFee],
        settings: PremiumTableFeeSettings
    ) -> PremiumTableFeeResult {
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
