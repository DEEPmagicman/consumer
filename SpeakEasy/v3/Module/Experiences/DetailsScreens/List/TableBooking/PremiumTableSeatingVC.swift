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

    /// Called when user taps Checkout
    var onCheckout: ((_ guestCount: Int, _ seatingArea: SeatingArea, _ event: Event) -> Void)?

    // MARK: - State

    private var currentGuestCount: Int = 1
    private var isExpanded = false

    // MARK: - UI

    private let scrollView        = UIScrollView()
    private let contentView       = UIView()

    private let titleRow          = UIView()
    private let titleIcon         = UIImageView()
    private let titleLabel        = UILabel()

    private let tagsRow           = UIView()
    private let guestTagView      = PremiumTagPillView()
    private let timeTagView       = PremiumTagPillView()

    private let divider           = UIView()

    private let highlightLabel    = UILabel()
    private let descLabel         = UILabel()

    private let guestRow          = PremiumStepperRow()
    private let priceCard         = PremiumPriceCard()

    private let bottomBar         = UIView()
    private let bottomPriceLabel  = UILabel()
    private let bottomSubLabel    = UILabel()
    private let checkoutBtn       = UIButton(type: .system)
    
    private let backBtn = AppIconButton()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        setupUI()
        configureData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        checkoutBtn.layer.cornerRadius = checkoutBtn.bounds.height / 2
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
        setupPriceCard()
        setupBottomBar()
        setupConstraints()
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
        // ✦ sparkle icon
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 16
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
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleRow.translatesAutoresizingMaskIntoConstraints = false
        titleRow.addSubview(backBtn)
        titleRow.addSubview(titleIcon)
        titleRow.addSubview(titleLabel)
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
            icon:  UIImage(resource: .guestIcon).withRenderingMode(.alwaysTemplate),
            title: "Guests"
        )
        guestRow.onValueChanged = { [weak self] val in
            self?.currentGuestCount = val
            self?.updatePricing()
        }
        contentView.addSubview(guestRow)
    }

    func setupPriceCard() {
        priceCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(priceCard)
    }

    func setupBottomBar() {
        bottomBar.backgroundColor = UIColor(hex: "#111111")
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        // Thin top separator
        let sep = UIView()
        sep.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        sep.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(sep)

        bottomPriceLabel.font      = Constant.Font.geistMedium(size: 18)
        bottomPriceLabel.textColor = .white
        bottomPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        bottomSubLabel.text      = "deposit incl. fees"
        bottomSubLabel.font      = Constant.Font.geistRegular(size: 12)
        bottomSubLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        bottomSubLabel.translatesAutoresizingMaskIntoConstraints = false

        let labelStack = UIStackView(arrangedSubviews: [bottomPriceLabel, bottomSubLabel])
        labelStack.axis    = .vertical
        labelStack.spacing = 2
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        checkoutBtn.setTitle("Checkout", for: .normal)
        checkoutBtn.setTitleColor(.black, for: .normal)
        checkoutBtn.titleLabel?.font = Constant.Font.geistMedium(size: 16)
        checkoutBtn.backgroundColor  = UIColor(hex: "#E8A030")
        checkoutBtn.translatesAutoresizingMaskIntoConstraints = false
        checkoutBtn.addTarget(self, action: #selector(onCheckoutTapped), for: .touchUpInside)

        bottomBar.addSubview(labelStack)
        bottomBar.addSubview(checkoutBtn)
        view.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            sep.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            labelStack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            labelStack.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),

            checkoutBtn.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            checkoutBtn.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            checkoutBtn.widthAnchor.constraint(equalToConstant: 130),
            checkoutBtn.heightAnchor.constraint(equalToConstant: 50)
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

            // Icon
            titleIcon.centerYAnchor.constraint(equalTo: titleRow.centerYAnchor),
            titleIcon.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -8),
            titleIcon.widthAnchor.constraint(equalToConstant: 18),
            titleIcon.heightAnchor.constraint(equalToConstant: 18),

            // Center Title
            titleLabel.centerXAnchor.constraint(equalTo: titleRow.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleRow.centerYAnchor),

            // MARK: Bottom Bar
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 90),

            // MARK: Scroll
            scrollView.topAnchor.constraint(equalTo: titleRow.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // MARK: Tags
            tagsRow.topAnchor.constraint(equalTo: contentView.topAnchor),
            tagsRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tagsRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tagsRow.heightAnchor.constraint(equalToConstant: 28),

            guestTagView.leadingAnchor.constraint(equalTo: tagsRow.leadingAnchor),
            guestTagView.centerYAnchor.constraint(equalTo: tagsRow.centerYAnchor),

            timeTagView.leadingAnchor.constraint(equalTo: guestTagView.trailingAnchor, constant: 8),
            timeTagView.centerYAnchor.constraint(equalTo: tagsRow.centerYAnchor),

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

            // Price
            priceCard.topAnchor.constraint(equalTo: guestRow.bottomAnchor, constant: 10),
            priceCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            priceCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            priceCard.heightAnchor.constraint(equalToConstant: 72),

            // Content Bottom
            priceCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
}

// MARK: - Configure

private extension PremiumTableSeatingVC {

    func configureData() {
        guard let area = seatingArea else { return }

        // Guest tag
        let minG = area.defaultGuest ?? 0
        let maxG = area.maxGuest ?? 0
        let guestText = minG > 0 && maxG > 0
            ? (minG == maxG ? "\(minG) guests" : "\(minG)-\(maxG) guests")
            : "\(maxG) guests"
        guestTagView.configure(icon: "person.2", text: guestText)

        // Time tag — from event time range
        let tz = event?.venue?.useTimezone ?? TimeZone.current.identifier
        if let start = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: tz),
           let end   = event?.endDateTime?.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: tz) {
            timeTagView.configure(icon: "clock", text: "\(start) - \(end)")
        }

        // Descriptions
        highlightLabel.text = "Table seating accommodates \(guestText). "
        highlightLabel.isHidden = (highlightLabel.text ?? "").isEmpty

        descLabel.text = "Ticket price doesn’t count towards in-venue spend. All seating is first come, first served. Package price increases for each additional guest. Please arrive within 15 minutes of selected time."

        // Guest stepper
        currentGuestCount = area.defaultGuest ?? 1
        guestRow.setValue(currentGuestCount, min: area.defaultGuest ?? 1, max: area.maxGuest ?? 100)

        updatePricing()
    }

    func updatePricing() {
        let minVal  = Double(seatingArea?.minimum ?? 0)
        let deposit = calculateDeposit()
        priceCard.configure(minimum: minVal, deposit: deposit)
        bottomPriceLabel.text = "$\(String(format: "%.2f", deposit))"
    }

    func calculateDeposit() -> Double {
        guard let area = seatingArea else { return 0 }
        let fees = event?.venue?.venueSettings?.tableBookingSettings

        var minValue    = Double(area.minimum ?? 0)
        var baseDeposit = Double(area.deposit ?? 0)
        var depositType = area.depositType ?? "FLAT"

        if depositType.uppercased() == "PERCENTAGE" {
            baseDeposit = (minValue * baseDeposit) / 100
        }

        // Apply fees
        guard let fees else { return baseDeposit }
        var taxable    = 0.0
        var nonTaxable = 0.0

        fees.customFees?.forEach { fee in
            guard fee.isEnableCustomFee == true else { return }
            let val: Double = fee.customFeeType?.uppercased() == "FLAT"
                ? (fee.customFee ?? 0)
                : baseDeposit * (fee.customFee ?? 0) / 100
            if fee.isCustomFeeTaxable == true { taxable += val } else { nonTaxable += val }
        }

        var tax = 0.0
        if fees.isEnableSalesTax == true {
            tax = (baseDeposit + taxable) * ((fees.salesTax ?? 0) / 100)
        }

        return baseDeposit + taxable + nonTaxable + tax - tax
    }
}

// MARK: - Actions

private extension PremiumTableSeatingVC {

    @objc func toggleDesc() {
        isExpanded.toggle()
        descLabel.numberOfLines = 0
        UIView.animate(withDuration: 0.22) { self.view.layoutIfNeeded() }
    }

    @objc func onCheckoutTapped() {
        guard let area = seatingArea, let event else { return }

        guard UserDefault.shared.isLoggedIn ?? false else {
            Navigate.to.openPhoneLoginPopup(self)
            return
        }

        let uuid    = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let queueId = "TABLE_BOOKING_QUEUE_\(uuid)"

        checkoutBtn.isUserInteractionEnabled = false
        checkoutBtn.alpha = 0.6

        TablePresenter.createSeatingAreaBooking(
            eventId:      event.id ?? "",
            seatingAreaId: area.id ?? "",
            timeSlotId:   area.bookingType == .default ? nil : nil,
            venueId:      event.venue?.id ?? "",
            guests:       currentGuestCount,
            queueId:      queueId
        ) { [weak self] success, message, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.checkoutBtn.isUserInteractionEnabled = true
                self.checkoutBtn.alpha = 1
                if success {
                    let vc = PremiumTableCheckoutVC()
                    vc.queueId       = queueId
                    vc.event         = event
                    vc.seatingAreas  = [area]
                    vc.guestCount    = self.currentGuestCount
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    Alert.showToast(message ?? Constant.String.somethingWrong)
                }
            }
        }
    }
}
