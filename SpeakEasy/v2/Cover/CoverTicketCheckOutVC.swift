//
//  CoverTicketCheckOutVC.swift
//  SpeakEasy-Consumer
//

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet
import MHLoadingButton
import SDWebImage

final class CoverTicketCheckOutVC: UIViewController, ApplePayContextDelegate {

    // MARK: - Outlets - TableViews
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!

    @IBOutlet weak var coverTicketFeesAndTaxTableView: UITableView!
    @IBOutlet weak var coverTicketFeesAndTaxTableViewHeight: NSLayoutConstraint!

    @IBOutlet weak var upsellTicketTableView: UITableView!
    @IBOutlet weak var upsellTicketTableViewHeight: NSLayoutConstraint!

    @IBOutlet weak var upsellTicketFeesAndTaxTableView: UITableView!
    @IBOutlet weak var upsellTicketFeesAndTaxTableViewHeight: NSLayoutConstraint!

    @IBOutlet weak var coverTicketParentView: UIView!
    @IBOutlet weak var upsellTicketParentView: UIView!

    // MARK: - Outlets
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var imageParentView: TicketCardView!
    @IBOutlet weak var checkOutBtnView: CheckoutBarView!
    @IBOutlet weak var privacyPolicyLbl: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var termsAndConditions: UIView!
    @IBOutlet weak var venueMessageView: UIView!
    @IBOutlet weak var termsAndConditionsLbl: UILabel!
    @IBOutlet weak var venueMessageLbl: UILabel!
    @IBOutlet weak var termsAndConditionsBtn: UIButton!
    @IBOutlet weak var venueMessageBtn: UIButton!
    @IBOutlet weak var backgroundContainerView: UIView!
    @IBOutlet weak var paymentTypeView: UIView!
    @IBOutlet weak var paymentTypeName: UILabel!
    @IBOutlet weak var paymentCardImage: UIImageView!

    // MARK: - Data
    var selectedCoverTickets: [CoverTicket] = []
    var selectedAddOnsItems: [UpSellTicket] = []
    var venue: ClipVenue?
    var totalPrice: Double = 0
    var bookingType: TicketPriceType = .FREE
    weak var updateDelegate: UpdateDetailDelegate?

    // MARK: - Payment
    private var paymentSheet: PaymentSheet?
    private var paymentIntent: String = ""
    private var paymentHistoryId: String = ""
    private var ephemeralKey: String = ""
    private var paymentDetail: PaymentDetail?
    private var addOnsPaymentDetail: PaymentDetail?
    var bookingId: String = ""
    private var addOnsBookingId: String?

    // MARK: - State
    private var isPromoCodeApplied = false
    private var appliedPromoCode = ""
    private var isFreeTicket = false
    private var isPaymentInitiated = false
    private var isFromApplePay = false
    
    private var isTermsAccepted = false
    private var isVenueMessageAccepted = false
    private var isTermsExpanded = false
    private let collapsedLines = 2
    private var hasLaidOutTerms = false
    private var fullTermsText = ""

    // Both must flip true before checkout button enables
    private var isBookingLoaded = false {
        didSet { updateCheckoutButtonState() }
    }
    private var isPaymentIntentLoaded = false {
        didSet { updateCheckoutButtonState() }
    }

    private var feesAndTaxes: [FeeDisplayItem] = []
    private var upsellFeesAndTaxes: [FeeDisplayItem] = []
    private let posterHeaderView = EventPosterHeaderView()

    private var countdownTimer: Timer?
    private var remainingSeconds: Int = 10 * 60
    private var enterBgDate = Date()

    // Track KVO registration to avoid double-remove crash in deinit
    private var kvoRegistered = false

    private var currency: String {
        venue?.venueSettings?.currencySymbol ?? "$"
    }

    private var isApplePayNotSupported: Bool {
        !PKPaymentAuthorizationViewController.canMakePayments()
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableViews()
        setupHeaderData()
        setupPosterBackground()
        setupNotifications()
        setupCheckoutBar()

        if !selectedCoverTickets.isEmpty && bookingType != .FREE {
            createBooking()
        } else {
            isBookingLoaded = true
            getAddOnsPaymentIntent(bookingId: "")
        }
        setupTermsText()

        fullTermsText = venue?.venueSettings?.policyText ?? ""
//        venueMessageLbl.text = venue?.ven
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !hasLaidOutTerms,
              termsAndConditionsLbl.frame.width > 0 else { return }

        hasLaidOutTerms = true
        updateTermsLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.addTarget(
            self, action: #selector(handleBackSwipe)
        )
        imageParentView.playEntryAnimation()
        WebSocketWrapper.shared.delegate.append(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.removeTarget(
            self, action: #selector(handleBackSwipe)
        )
        WebSocketWrapper.shared.delegate.removeAll(where: { $0 as? NSObject == self })
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        countdownTimer?.invalidate()

        guard kvoRegistered else { return }
        tableView?.removeObserver(self, forKeyPath: "contentSize")
        coverTicketFeesAndTaxTableView?.removeObserver(self, forKeyPath: "contentSize")
        upsellTicketTableView?.removeObserver(self, forKeyPath: "contentSize")
        upsellTicketFeesAndTaxTableView?.removeObserver(self, forKeyPath: "contentSize")
    }

    // MARK: - Setup
    private func setupTableViews() {
        tableView.register(OrderItemTableViewCell.nib,
                           forCellReuseIdentifier: OrderItemTableViewCell.identifier)
        upsellTicketTableView.register(OrderItemTableViewCell.nib,
                                       forCellReuseIdentifier: OrderItemTableViewCell.identifier)
        coverTicketFeesAndTaxTableView.register(TicketItemTableViewCell.nib,
                                                forCellReuseIdentifier: TicketItemTableViewCell.identifier)
        upsellTicketFeesAndTaxTableView.register(TicketItemTableViewCell.nib,
                                                 forCellReuseIdentifier: TicketItemTableViewCell.identifier)

        [tableView, coverTicketFeesAndTaxTableView,
         upsellTicketTableView, upsellTicketFeesAndTaxTableView].forEach {
            $0?.delegate = self
            $0?.dataSource = self
            $0?.isScrollEnabled = false
            $0?.separatorStyle = .none
            $0?.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        }
        kvoRegistered = true
    }

    private func setupPosterBackground() {
        bgView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: bgView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: bgView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: bgView.bottomAnchor)
        ])
        let imageUrlString = "\(SharedURL.amazonStorage)\(venue?.venueAttachment?.first?.key ?? "")"
        posterHeaderView.loadImage(from: imageUrlString)
    }

    private func setupHeaderData() {
        venueLogoImg.sd_setImage(
            with: URL(string: (venue?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        let imageUrlString = "\(SharedURL.amazonStorage)\(venue?.venueAttachment?.first?.key ?? "")"
        if let url = URL(string: imageUrlString) {
            SDWebImageManager.shared.loadImage(with: url, options: .highPriority, progress: nil) {
                [weak self] image, _, _, _, _, _ in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.imageParentView.setImage(image ?? UIImage(named: "newSpeakeasy"))
                }
            }
        } else {
            imageParentView.setImage(named: "newSpeakeasy")
        }

        venueName.text = venue?.name ?? ""
        termsAndConditionsLbl.text = "I agree to receive marketing related text messages from \(venue?.name ?? ""). Msg & data rates may apply. Reply STOP to opt out or HELP for support."

        // Set initial state — hidden sections start invisible and collapsed
        // Animation happens later in animateContentIn() after data loads
        coverTicketParentView.alpha = 0
        coverTicketParentView.isHidden = selectedCoverTickets.isEmpty

        upsellTicketParentView.alpha = 0
        upsellTicketParentView.isHidden = selectedAddOnsItems.isEmpty

        // If data is already present (navigating back), show immediately
        if !selectedCoverTickets.isEmpty {
            coverTicketParentView.alpha = 1
        }
        if !selectedAddOnsItems.isEmpty {
            upsellTicketParentView.alpha = 1
        }
    }

    private func setupCheckoutBar() {
        checkOutBtnView.delegate = self
        setCheckoutButton(enabled: false, animated: false)
        checkOutBtnView.setButtonTitle(
            bookingType == .FREE || totalPrice <= 0 ? "Confirm Free Booking" : "Pay Now"
        )
    }

    private func setupNotifications() {
        let pairs: [(Notification.Name, Selector)] = [
            (UIApplication.didEnterBackgroundNotification,  #selector(enterBackGround)),
            (UIApplication.willEnterForegroundNotification, #selector(exitBackGround)),
            (UIApplication.willResignActiveNotification,    #selector(enterBackGround)),
            (UIApplication.didBecomeActiveNotification,     #selector(exitBackGround))
        ]
        pairs.forEach {
            NotificationCenter.default.addObserver(self, selector: $0.1, name: $0.0, object: nil)
        }
    }
    
    private func updateTermsCheckboxUI() {
        let image = isTermsAccepted ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon
        termsAndConditionsBtn.setImage(image, for: .normal)
    }

    private func updateVenueCheckboxUI() {
        let image = isVenueMessageAccepted ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon
        venueMessageBtn.setImage(image, for: .normal)
    }
    
    private func setupTermsText() {
        termsAndConditionsLbl.font = Constant.Font.geistMedium(size: 12)
        termsAndConditionsLbl.textColor = .white
        termsAndConditionsLbl.isUserInteractionEnabled = true

        venueMessageLbl.font = Constant.Font.geistMedium(size: 12)

        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(onTapTermsLabel)
        )
        termsAndConditionsLbl.addGestureRecognizer(tap)

        updateTermsCheckboxUI()
        updateVenueCheckboxUI()
    }
    
    private func updateTermsLabel() {

        guard !fullTermsText.isEmpty else {
            termsAndConditionsLbl.text = ""
            return
        }

        let toggleText = isTermsExpanded ? "View Less" : "View More"

        let displayText = isTermsExpanded
        ? "\(fullTermsText) \(toggleText)"
        : "\(fullTermsText)... \(toggleText)"

        let attributed = NSMutableAttributedString(
            string: displayText,
            attributes: [
                .font: Constant.Font.geistMedium(size: 12),
                .foregroundColor: UIColor.white
            ]
        )

        let toggleRange = (displayText as NSString).range(of: toggleText)

        attributed.addAttributes([
            .font: Constant.Font.geistMedium(size: 10),
            .foregroundColor: UIColor.lightGray
        ], range: toggleRange)

        termsAndConditionsLbl.numberOfLines = isTermsExpanded ? 0 : collapsedLines
        termsAndConditionsLbl.attributedText = attributed
    }

    // MARK: - KVO
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "contentSize", let table = object as? UITableView else { return }

        // Must update constraint on main thread; no animation — layout pass handles it
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch table {
            case self.tableView:
                self.tableViewHeight.constant = table.contentSize.height
            case self.coverTicketFeesAndTaxTableView:
                self.coverTicketFeesAndTaxTableViewHeight.constant = table.contentSize.height
            case self.upsellTicketTableView:
                self.upsellTicketTableViewHeight.constant = table.contentSize.height
            case self.upsellTicketFeesAndTaxTableView:
                self.upsellTicketFeesAndTaxTableViewHeight.constant = table.contentSize.height
            default:
                break
            }
        }
    }
    
    @objc
    private func onTapTermsLabel(_ gesture: UITapGestureRecognizer) {

        guard let text = termsAndConditionsLbl.attributedText?.string else {
            return
        }

        let targetText = isTermsExpanded ? "View Less" : "View More"

        let range = (text as NSString).range(of: targetText)

        guard gesture.didTapAttributedTextInLabel(
            label: termsAndConditionsLbl,
            inRange: range
        ) else {
            return
        }

        isTermsExpanded.toggle()
        updateTermsLabel()

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Actions
    @IBAction func onClickBackBtn(_ sender: Any) {
        cancelBooking()
    }
    
    @IBAction func onClickTermsBtn(_ sender: UIButton) {
        isTermsAccepted.toggle()
        updateTermsCheckboxUI()
    }

    @IBAction func onClickVenueMessageBtn(_ sender: UIButton) {
        isVenueMessageAccepted.toggle()
        updateVenueCheckboxUI()
    }

    @objc private func handleBackSwipe() {
        navigationController?.interactivePopGestureRecognizer?.removeTarget(
            self, action: #selector(handleBackSwipe)
        )
        cancelBooking()
    }

    func onClickContinueToCheckout() {
        guard !isPaymentInitiated else { return }
        if termsAndConditions.isHidden == false && !isTermsAccepted {
            Alert.showToast("Please accept Terms & Conditions")
            return
        }

        if venueMessageView.isHidden == false && !isVenueMessageAccepted {
            Alert.showToast("Please accept Venue Message")
            return
        }
        isPaymentInitiated = true

        if isFreeTicket || bookingType == .FREE || totalPrice <= 0 {
            isPaymentInitiated = false
            checkOutBtnView.showLoader()
            createFreeBookingIfNeeded()
            return
        }

        guard let paymentSheet else {
            isPaymentInitiated = false
            Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
            return
        }

        paymentSheet.present(from: self) { [weak self] result in
            guard let self else { return }
            self.isPaymentInitiated = false
            switch result {
            case .completed:
                self.checkOutBtnView.showLoader()
                self.handleSuccessfulCardPayment()
            case .canceled:
                break
            case .failed:
                Alert.showAlertSheet(style: .alert, title: "Payment failed", message: "")
            }
        }
    }
}

// MARK: - Checkout Button State
extension CoverTicketCheckOutVC {

    /// Only called via didSet — single place that drives enabled/disabled.
    private func updateCheckoutButtonState() {
        let ready = isBookingLoaded && isPaymentIntentLoaded
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.setCheckoutButton(enabled: ready, animated: true)
            self.refreshCheckoutBarSummary()
        }
    }

    private func setCheckoutButton(enabled: Bool, animated: Bool) {
        checkOutBtnView.isUserInteractionEnabled = enabled
        let targetAlpha: CGFloat = enabled ? 1.0 : 0.5
        guard animated else {
            checkOutBtnView.alpha = targetAlpha
            return
        }
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.checkOutBtnView.alpha = targetAlpha
        }
    }

    /// Pushes correct totals + fee summary into CheckoutBarView.
    private func refreshCheckoutBarSummary() {
        let coverTotal  = paymentDetail?.total ?? 0
        let upsellTotal = addOnsPaymentDetail?.total ?? 0
        let grandTotal  = coverTotal + upsellTotal

        let coverCount  = selectedCoverTickets.reduce(0) { $0 + ($1.selectedQuantity ?? 0) }
        let upsellCount = selectedAddOnsItems.reduce(0)  { $0 + ($1.selectedQuantity ?? 0) }
        let totalCount  = coverCount + upsellCount

        let totalFees = feesAboveSubtotal(from: paymentDetail)
                      + feesAboveSubtotal(from: addOnsPaymentDetail)

        checkOutBtnView.updateSummary(
            currency: currency,
            count: totalCount,
            subtotal: grandTotal,
            fees: totalFees
        )

        let isFree = grandTotal <= 0 || bookingType == .FREE
        checkOutBtnView.setButtonTitle(
            isFree ? "Confirm Free Booking" : "Pay \(currency)\(grandTotal.decimalFormat(true))"
        )
    }

    /// Sum of all fees/tax above the subtotal for one PaymentDetail.
    private func feesAboveSubtotal(from detail: PaymentDetail?) -> Double {
        guard let detail, detail.subTotal != detail.total else { return 0 }
        var fees: Double = 0
        if let customFees = detail.customFees, !customFees.isEmpty {
            fees += customFees.reduce(0) { $0 + ($1.fee ?? 0) }
        } else {
            fees += detail.customFee
        }
        fees += detail.salesTax ?? 0
        fees += detail.processingFee
        return fees
    }
}

// MARK: - API Calls
extension CoverTicketCheckOutVC {

    private func createBooking() {
        let tickets: [[String: Any]] = selectedCoverTickets.map {
            ["ticketId": $0.id, "ticketQuantity": $0.selectedQuantity ?? 0]
        }
        PaymentPresenter.createCoverBooking(coverTickets: tickets, venueId: venue?.id ?? "") {
            [weak self] isSuccess, errMsg, id, _ in
            guard let self else { return }
            if isSuccess, let id {
                self.bookingId = id
                self.isBookingLoaded = true
                self.fetchPaymentIntentAndSetup(
                    promoCode: self.isPromoCodeApplied ? self.appliedPromoCode : ""
                )
            } else {
                self.isBookingLoaded = true
                self.isPaymentIntentLoaded = true
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    private func fetchPaymentIntentAndSetup(promoCode: String) {
        let tickets: [[String: Any]] = selectedCoverTickets.map {
            ["ticketId": $0.id, "quantity": $0.selectedQuantity ?? 0]
        }
        PaymentPresenter.getPaymentIntent(
            bookingId: bookingId,
            selectedTickets: tickets,
            promoCode: promoCode,
            type: .appClip
        ) { [weak self] isSuccess, errMsg, clientSecret, paymentHistoryId, ephemeralKey, paymentDetail, isFreeTicket in
            guard let self else { return }
            if isSuccess, let clientSecret {
                self.isFreeTicket = isFreeTicket
                self.paymentIntent = clientSecret
                self.paymentHistoryId = paymentHistoryId
                self.ephemeralKey = ephemeralKey
                self.paymentDetail = paymentDetail

                if self.selectedAddOnsItems.isEmpty {
                    self.setupStripePaymentSheet()
                    self.updateUIWithPaymentDetail()
                    self.isPaymentIntentLoaded = true
                } else {
                    self.getAddOnsPaymentIntent(bookingId: self.bookingId)
                }
            } else {
                self.isPaymentIntentLoaded = true
                if self.isPromoCodeApplied { self.isPromoCodeApplied = false }
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    private func getAddOnsPaymentIntent(bookingId: String) {
        let addOnsItems: [[String: Any]] = selectedAddOnsItems.map {
            ["id": $0.id, "addOnsId": $0.addOns?.id ?? "", "quantity": $0.selectedQuantity ?? 0]
        }
        PaymentPresenter.addOnsPaymentIntent(
            bookingId: bookingId,
            venueId: venue?.id ?? "",
            addOnsItems: addOnsItems
        ) { [weak self] isSuccess, errMsg, clientSecret, ephemeralKey, paymentDetail, bookingId in
            guard let self else { return }
            if isSuccess {
                self.addOnsPaymentDetail = paymentDetail
                self.addOnsBookingId = bookingId
                if self.selectedCoverTickets.isEmpty {
                    self.paymentIntent = clientSecret ?? ""
                    self.ephemeralKey = ephemeralKey
                }
                self.setupStripePaymentSheet()
                self.updateUIWithPaymentDetail()
                self.isBookingLoaded = true
                self.isPaymentIntentLoaded = true
            } else {
                self.isBookingLoaded = true
                self.isPaymentIntentLoaded = true
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    private func cancelBooking() {
        countdownTimer?.invalidate()
        guard !bookingId.isEmpty else {
            navigationController?.popToRootViewController(animated: false)
            return
        }
        PaymentPresenter.cancelBooking(bookingId: bookingId) { [weak self] _, _ in
            self?.navigationController?.popToRootViewController(animated: false)
        }
    }
}

// MARK: - Stripe Setup
extension CoverTicketCheckOutVC {

    private func setupStripePaymentSheet() {
        STPAPIClient.shared.publishableKey = Stripe.publishableKey

        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"
        configuration.customer = .init(
            id: UserDefault.shared.user?.stripeCusId ?? "",
            ephemeralKeySecret: ephemeralKey
        )
        configuration.savePaymentMethodOptInBehavior = .automatic
        configuration.allowsDelayedPaymentMethods = true
        configuration.applePay = .init(
            merchantId: "merchant.com.speakeasy",
            merchantCountryCode: "US"
        )
        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: paymentIntent,
            configuration: configuration
        )
    }
}

// MARK: - UI Update
extension CoverTicketCheckOutVC {

    private func updateUIWithPaymentDetail() {
        let newFees       = buildFeesArray(from: paymentDetail)
        let newUpsellFees = buildFeesArray(from: addOnsPaymentDetail)

        let coverTotal  = paymentDetail?.total ?? 0
        let upsellTotal = addOnsPaymentDetail?.total ?? 0

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.feesAndTaxes       = newFees
            self.upsellFeesAndTaxes = newUpsellFees
            self.totalPrice         = coverTotal + upsellTotal
            self.isFreeTicket       = self.totalPrice <= 0

            // Reload first so KVO fires and constraints get correct heights
            self.tableView.reloadData()
            self.coverTicketFeesAndTaxTableView.reloadData()
            self.upsellTicketTableView.reloadData()
            self.upsellTicketFeesAndTaxTableView.reloadData()

            // Then animate the sections in — slight delay lets layout settle first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.animateSectionsIn()
            }
        }
    }

    /// Smooth spring reveal for cover + upsell sections.
    /// Handles four cases:
    ///   - Section was already visible → no-op
    ///   - Section needs to appear     → fade + slide up into place
    ///   - Section needs to disappear  → fade + slide down, then hide
    ///   - Section stays hidden        → no-op
    private func animateSectionsIn() {
        let showCover  = !selectedCoverTickets.isEmpty
        let showUpsell = !selectedAddOnsItems.isEmpty

        // Prepare views that will appear: un-hide them at alpha 0 so layout includes their height
        if showCover && coverTicketParentView.isHidden {
            coverTicketParentView.isHidden = false
            coverTicketParentView.alpha = 0
            coverTicketParentView.transform = CGAffineTransform(translationX: 0, y: 16)
        }
        if showUpsell && upsellTicketParentView.isHidden {
            upsellTicketParentView.isHidden = false
            upsellTicketParentView.alpha = 0
            upsellTicketParentView.transform = CGAffineTransform(translationX: 0, y: 16)
        }

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            // Appear
            if showCover {
                self.coverTicketParentView.alpha = 1
                self.coverTicketParentView.transform = .identity
            }
            if showUpsell {
                self.upsellTicketParentView.alpha = 1
                self.upsellTicketParentView.transform = .identity
            }

            // Disappear
            if !showCover {
                self.coverTicketParentView.alpha = 0
                self.coverTicketParentView.transform = CGAffineTransform(translationX: 0, y: 8)
            }
            if !showUpsell {
                self.upsellTicketParentView.alpha = 0
                self.upsellTicketParentView.transform = CGAffineTransform(translationX: 0, y: 8)
            }

            self.view.layoutIfNeeded()

        } completion: { _ in
            // Collapse hidden sections so they don't occupy layout space
            if !showCover {
                self.coverTicketParentView.isHidden = true
                self.coverTicketParentView.transform = .identity
            }
            if !showUpsell {
                self.upsellTicketParentView.isHidden = true
                self.upsellTicketParentView.transform = .identity
            }
        }
    }

    // MARK: - Fee array builder
    private func buildFeesArray(from detail: PaymentDetail?) -> [FeeDisplayItem] {
        guard let detail else { return [] }

        let subTotal = detail.subTotal
        let total    = detail.total

        // No breakdown needed when subtotal equals total
        guard subTotal != total else {
            return [FeeDisplayItem(title: "Total", amount: total)]
        }

        var items: [FeeDisplayItem] = []

        if subTotal > 0 {
            items.append(FeeDisplayItem(title: "Subtotal", amount: subTotal))
        }

        if let customFees = detail.customFees, !customFees.isEmpty {
            customFees.forEach {
                items.append(FeeDisplayItem(title: $0.name, amount: $0.fee ?? 0))
            }
        } else if detail.customFee > 0 {
            items.append(FeeDisplayItem(
                title: detail.customFeeName ?? "Custom Fee",
                amount: detail.customFee
            ))
        }

        if let salesTax = detail.salesTax, salesTax > 0 {
            items.append(FeeDisplayItem(
                title: detail.salesTaxName ?? "Sales Tax",
                amount: salesTax
            ))
        }

        if detail.processingFee > 0 {
            items.append(FeeDisplayItem(title: "Processing Fee", amount: detail.processingFee))
        }

        items.append(FeeDisplayItem(title: "Total", amount: total))
        return items
    }
}

// MARK: - Payment Completion Flow
extension CoverTicketCheckOutVC {

    private func handleSuccessfulCardPayment() {
        if bookingType == .FREE {
            createFreeBooking {
                self.addOnsPaymentSuccess {
                    self.finishAndNavigate(isAddOnsAvailable: true, isOnlyAddOn: false)
                }
            }
            return
        }

        if selectedCoverTickets.isEmpty && !selectedAddOnsItems.isEmpty {
            addOnsPaymentSuccess {
                self.finishAndNavigate(isAddOnsAvailable: true, isOnlyAddOn: true)
            }
            return
        }

        paymentStatus(optedPolicy: venue?.venueSettings?.optedPolicy == true ? true : nil) {
            if self.selectedAddOnsItems.isEmpty {
                self.finishAndNavigate(isAddOnsAvailable: false, isOnlyAddOn: false)
            } else {
                self.addOnsPaymentSuccess {
                    self.finishAndNavigate(isAddOnsAvailable: true, isOnlyAddOn: false)
                }
            }
        }
    }

    private func createFreeBookingIfNeeded() {
        if selectedCoverTickets.isEmpty && !selectedAddOnsItems.isEmpty {
            addOnsPaymentSuccess {
                self.finishAndNavigate(isAddOnsAvailable: true, isOnlyAddOn: true)
            }
            return
        }
        createFreeBooking {
            if self.selectedAddOnsItems.isEmpty {
                self.finishAndNavigate(isAddOnsAvailable: false, isOnlyAddOn: false)
            } else {
                self.addOnsPaymentSuccess {
                    self.finishAndNavigate(isAddOnsAvailable: true, isOnlyAddOn: false)
                }
            }
        }
    }

    /// Single navigation call site — removes all duplicated Navigate.to.scanQR blocks.
    private func finishAndNavigate(isAddOnsAvailable: Bool, isOnlyAddOn: Bool) {
        checkOutBtnView.hideLoader()
        countdownTimer?.invalidate()
        Navigate.to.scanQR(
            self,
            isAddOnsAvailable: isAddOnsAvailable,
            bookingId: bookingId,
            isOnlyAddOnAvailable: isOnlyAddOn,
            venueId: venue?.id ?? "",
            addOnsBookingId: addOnsBookingId ?? "",
            venueName: venue?.name ?? ""
        )
    }

    private func paymentStatus(optedPolicy: Bool? = nil, completion: @escaping () -> Void) {
        Loader.show()
        PaymentPresenter.successPayment(
            paymentHistoryId: paymentHistoryId,
            bookingId: bookingId,
            optedPolicy: optedPolicy
        ) { [weak self] isSuccess, errMsg in
            Loader.hide()
            if isSuccess {
                completion()
            } else {
                self?.checkOutBtnView.hideLoader()
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    private func addOnsPaymentSuccess(completion: @escaping () -> Void) {
        let mainBookingId = bookingType == .FREE ? bookingId : ""
        PaymentPresenter.successAddOnsPayment(
            bookingId: addOnsBookingId ?? "",
            mainBookingId: mainBookingId
        ) { [weak self] isSuccess, errMsg in
            if isSuccess {
                completion()
            } else {
                self?.checkOutBtnView.hideLoader()
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    private func createFreeBooking(completion: @escaping () -> Void) {
        let tickets: [[String: Any]] = selectedCoverTickets.map {
            ["ticketId": $0.id, "ticketQuantity": $0.selectedQuantity ?? 0]
        }
        PaymentPresenter.createCoverFreeBooking(coverTickets: tickets, venueId: venue?.id ?? "") {
            [weak self] isSuccess, errMsg, id, _ in
            guard let self else { return }
            if isSuccess, let id {
                self.bookingId = id
                completion()
            } else {
                self.checkOutBtnView.hideLoader()
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
}

// MARK: - Apple Pay
extension CoverTicketCheckOutVC {

    private func applePayButtonTapped() {
        isFromApplePay = true

        guard StripeAPI.deviceSupportsApplePay() else {
            alertForWallet()
            return
        }

        isPaymentInitiated = true

        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: "merchant.com.speakeasy",
            country: "US",
            currency: venue?.venueSettings?.currencyCode?.uppercased() ?? "USD"
        )
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: "Speakeasy Bookings Inc. (VIA Speakeasy Go!)",
                amount: NSDecimalNumber(value: totalPrice)
            )
        ]
        paymentRequest.requiredBillingContactFields = []

        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            applePayContext.presentApplePay()
        } else {
            Alert.showToast("Problem with your Apple Pay")
        }
    }

    private func alertForWallet() {
        let title   = isApplePayNotSupported ? Constant.String.notSupported    : Constant.String.addCardToApplePay
        let message = isApplePayNotSupported ? Constant.String.applePayNotSupported : Constant.String.addCardToYourApplePayWallet

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.isFromApplePay = true
            self?.isPaymentInitiated = false
        })
        alert.addAction(UIAlertAction(title: "Add Card", style: .default) { _ in
            if let url = URL(string: "wallet://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
        present(alert, animated: true)
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    ) {
        completion(paymentIntent, nil)
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPApplePayContext.PaymentStatus,
        error: Error?
    ) {
        isPaymentInitiated = false
        switch status {
        case .success:
            checkOutBtnView.showLoader()
            handleSuccessfulCardPayment()
        case .error:
            isFromApplePay = true
            Alert.showAlertSheet(style: .alert, title: "Payment failed", message: "")
        case .userCancellation:
            isFromApplePay = true
        }
    }
}

// MARK: - Countdown Timer
extension CoverTicketCheckOutVC {

    private func startCountdown() {
        updateTimerLabel()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            self.remainingSeconds -= 1
            if self.remainingSeconds <= 0 {
                timer.invalidate()
                self.timerExpired()
            } else {
                self.updateTimerLabel()
            }
        }
    }

    private func updateTimerLabel() {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        _ = "\(String(format: "%01d", m)):\(String(format: "%02d", s))"
    }

    private func timerExpired() {
        let ok = UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
            guard let self else { return }
            self.countdownTimer?.invalidate()
            self.cancelBooking()
            self.updateDelegate?.update()
            self.navigationController?.popViewController(animated: true)
        }
        Alert.showAlertSheet(
            style: .alert,
            title: "Sorry, your ticket reservation has expired, please try again",
            message: "",
            actions: [ok]
        )
    }

    @objc private func enterBackGround() {
        enterBgDate = Date()
    }

    @objc private func exitBackGround() {
        guard !isFromApplePay else {
            isFromApplePay = false
            return
        }
        let elapsed = Date().timeIntervalSince(enterBgDate)
        remainingSeconds = max(0, remainingSeconds - Int(elapsed))
        updateTimerLabel()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension CoverTicketCheckOutVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case self.tableView:                    return selectedCoverTickets.count
        case coverTicketFeesAndTaxTableView:    return feesAndTaxes.count
        case upsellTicketTableView:             return selectedAddOnsItems.count
        case upsellTicketFeesAndTaxTableView:   return upsellFeesAndTaxes.count
        default:                                return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case self.tableView:
            return makeCoverTicketCell(for: indexPath, in: tableView)
        case coverTicketFeesAndTaxTableView:
            return makeFeesCell(item: feesAndTaxes[indexPath.row], in: tableView, at: indexPath)
        case upsellTicketTableView:
            return makeUpsellTicketCell(for: indexPath, in: tableView)
        case upsellTicketFeesAndTaxTableView:
            return makeFeesCell(item: upsellFeesAndTaxes[indexPath.row], in: tableView, at: indexPath)
        default:
            return UITableViewCell()
        }
    }

    private func makeCoverTicketCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OrderItemTableViewCell.identifier, for: indexPath
        ) as? OrderItemTableViewCell else { return UITableViewCell() }

        let ticket   = selectedCoverTickets[indexPath.row]
        let quantity = ticket.selectedQuantity ?? 0
        let total    = Double(quantity) * ticket.price

        cell.selectionStyle           = .none
        cell.totalTicketCountLbl.text = "\(quantity)x"
        cell.ticketNameLbl.text       = ticket.customName?.isEmpty == false ? ticket.customName : ticket.name
        cell.priceLbl.text            = total <= 0 ? "Free" : "\(currency)\(total.decimalFormat(true))"
        cell.extraFeesLbl.text        = ""
        return cell
    }

    private func makeUpsellTicketCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OrderItemTableViewCell.identifier, for: indexPath
        ) as? OrderItemTableViewCell else { return UITableViewCell() }

        let item     = selectedAddOnsItems[indexPath.row]
        let quantity = item.selectedQuantity ?? 0
        let total    = Double(quantity) * item.calculatedNetPrice

        cell.selectionStyle           = .none
        cell.totalTicketCountLbl.text = "\(quantity)x"
        cell.ticketNameLbl.text       = item.addOns?.name ?? ""
        cell.priceLbl.text            = total <= 0 ? "Free" : "\(currency)\(total.decimalFormat(true))"
        cell.extraFeesLbl.text        = ""
        return cell
    }

    private func makeFeesCell(
        item: FeeDisplayItem,
        in tableView: UITableView,
        at indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TicketItemTableViewCell.identifier, for: indexPath
        ) as? TicketItemTableViewCell else { return UITableViewCell() }

        cell.selectionStyle = .none
        cell.titleLbl.text  = item.title
        cell.amountLbl.text = "\(currency)\(item.amount.decimalFormat(true))"

        // Bold the Total row so it reads as a summary
        let isTotal = item.title.lowercased() == "total"
        let weight: UIFont.Weight = isTotal ? .semibold : .regular
        cell.titleLbl.font  = .systemFont(ofSize: cell.titleLbl.font.pointSize, weight: weight)
        cell.amountLbl.font = .systemFont(ofSize: cell.amountLbl.font.pointSize, weight: weight)
        return cell
    }
}

// MARK: - WebSocket
extension CoverTicketCheckOutVC: WebSocketCallBackDelegate {

    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool) {
        guard !isPaymentInitiated,
              navigationController?.viewControllers.last is CoverTicketCheckOutVC,
              venue?.uniqueId == uniqueId else { return }
        if isPriceUpdated { showPriceUpdateAlert() }
    }

    func updateTicketPrice(ticket: [CoverTicket]) {
        guard !isPaymentInitiated, !selectedCoverTickets.isEmpty else { return }
        let matched = ticket.filter { t in selectedCoverTickets.contains { $0.id == t.id } }
        if !matched.isEmpty { showPriceUpdateAlert() }
    }

    func updateAddOnsTicketPrice(ticket: [UpSellTicket]) {
        guard !isPaymentInitiated, !selectedAddOnsItems.isEmpty else { return }
        let matched = ticket.filter { t in selectedAddOnsItems.contains { $0.id == t.id } }
        if !matched.isEmpty { showPriceUpdateAlert() }
    }

    func updateVenueStatus(venueId: String, venueStatus: String) {
        Alert.showAlertSheet(
            style: .alert,
            title: "Update",
            message: "The venue you're booking is closing",
            actions: [popAction()]
        )
    }

    func didGenderWiseTicketChange(venueId: String, uniqueId: String) {
        guard !isPaymentInitiated,
              navigationController?.viewControllers.last is CoverTicketCheckOutVC,
              venue?.uniqueId == uniqueId else { return }
        Alert.showAlertSheet(
            style: .alert,
            title: "Update",
            message: "The venue updated its ticket options",
            actions: [popAction()]
        )
    }

    private func showPriceUpdateAlert() {
        Alert.showAlertSheet(
            style: .alert,
            title: "Update",
            message: "The venue updated their prices",
            actions: [popAction()]
        )
    }

    private func popAction() -> UIAlertAction {
        UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self else { return }
            if let vc = navigationController?.viewControllers.first(where: { $0 is MVPVenueListVc }) {
                navigationController?.popToViewController(vc, animated: true)
            } else if let vc = navigationController?.viewControllers.first(where: { $0 is MVPVenueDetailVc }) {
                navigationController?.popToViewController(vc, animated: true)
            }
        }
    }
}

// MARK: - CheckoutBarDelegate
extension CoverTicketCheckOutVC: CheckoutBarDelegate {
    func checkoutBarDidTapButton() {
        onClickContinueToCheckout()
    }
}
