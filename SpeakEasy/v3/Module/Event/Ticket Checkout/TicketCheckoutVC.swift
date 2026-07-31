//
//  TicketCheckoutVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 06/02/26.
//

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet
import MHLoadingButton

enum DummyQuestionType {
    case text
    case dropdown
    case checkbox
}

final class TicketCheckoutVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueName2: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var totalAmountLbl: UILabel!
    @IBOutlet weak var feesAndTxtTotalAmountLbl: UILabel!
    @IBOutlet weak var totalTaxIncludedLbl: UILabel!
    @IBOutlet weak var totalTaxIncludedHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feesAndTaxesTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feesAndTaxesTableView: UITableView!
    @IBOutlet weak var purchaseTicketBtn: LoadingButton!
    @IBOutlet weak var timerLbl: UILabel!
    @IBOutlet weak var promoCodeTextFeild: UITextField!
    @IBOutlet weak var submitPromoBtn: UIButton!
    @IBOutlet weak var promoCodeView: UIView!
    @IBOutlet weak var discountView: UIView!
    @IBOutlet weak var feesAndTaxesTitleView: UIView!
    @IBOutlet weak var feesAndTaxesTitleLbl: UILabel!
    @IBOutlet weak var feesAndTaxesContainerView: UIView!
    @IBOutlet weak var discountToalLbl: UILabel!
    @IBOutlet weak var shimmerView: UIView!
    @IBOutlet weak var feesDropDowenIc: UIImageView!
    @IBOutlet weak var addPromoCodeBtn: LoadingButton!
    @IBOutlet weak var customQuestionTableView: UITableView!
    @IBOutlet weak var customQuestionTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var customQuestionView: UIView!
    @IBOutlet weak var privacyPolicyLbl: UILabel!
    @IBOutlet weak var checkBox: UIButton!
    @IBOutlet weak var promoCodeParentView: UIView!
    @IBOutlet weak var feesAndTaxesParentTableView: UIView!
    
    private let paymentService = PaymentService()
    
    var selectedTickets: [EventTicket] = []
    var venueDetails: ClipVenue?
    var event: Event?
    var booking: Booking?
    var bookingId: String?
    var promotionLinkId = ""
    var promotionLinkUniqueCode = ""
    var dummyQuestions: [DummyQuestionType] = [.text, .dropdown, .checkbox]
    
    var eventQuestions = [Questions]()
    var questionAnswers = [String: Any]()
    var isEventQueAnsCollected = false
    
    private var faqs: [(question: String, answer: String)] = [
        (
            question: "Event Details.",
            answer: "View all event information including partner, date, time, and other event-related details."
        ),
        (
            question: "How to use my tickets",
            answer: "Show your QR ticket at the partner entrance for scanning and entry."
        )
    ]

    private var expandedFAQIndex: Int?
    private var isUpdatingTableHeight = false
    private var questionHeightObservation: NSKeyValueObservation?
    private var setAnswerData: Bool {

        var requiredIndex = [Int]()

        for (index, element) in eventQuestions.enumerated() {
            if !element.isOptional {
                requiredIndex.append(index)
            }
        }

        var requiredEmptyIndex = [Int]()

        for index in requiredIndex {
            let q = eventQuestions[index]
            let id = q.id

            if q.questionType == "MULTI_SELECT" {
                if questionAnswers[id] as? [String] ?? [] == [] {
                    requiredEmptyIndex.append(index)
                }
            } else if q.questionType == "SINGLE_SELECT" || q.questionType == "TEXT" {
                if questionAnswers[id] as? String ?? "" == "" {
                    requiredEmptyIndex.append(index)
                }
            } else {
                if questionAnswers[id] as? Bool ?? false == false {
                    requiredEmptyIndex.append(index)
                }
            }
        }

        return requiredEmptyIndex.isEmpty
    }

    private var countdownTimer: Timer?
    private var remainingSeconds: Int = 5 * 60

    private var feesAndTaxes: [FeeDisplayItem] = []

    private var isPromoCodeApplied = false
    private var appliedPromoCode: String = ""

    private var currency: String {
        return venueDetails?.venueSettings?.currencySymbol ?? "$"
    }
    
    private var currencyPosition: String? {
        return venueDetails?.venueSettings?.currencyPosition
    }

    private var whiteLabelAccentColor: UIColor {
        UIColor(hex: Event.normalizedHexColor(event?.whiteLabelColor))
    }

    private var paymentSheet: PaymentSheet?
    private var paymentIntentClientSecret: String = ""
    private var paymentHistoryId: String = ""
    private var ephemeralKey: String = ""
    private var paymentDetail: PaymentDetail?
    private var isFreeTicket: Bool = false
    private var isPaymentInitiated = false
    private var isCancellingTransaction = false
    private var wasInteractivePopGestureEnabled = true
    private var isPromoRequestInProgress = false
    private var isSubmittingQuestions = false
    private var isLoading = false
    private var shimmerBlocks: [ShimmerViewV3] = []
    private var isBookingLoaded = false
    private var isPaymentIntentLoaded = false
    private var isPrivacyPolicyExpanded = false
    private var fullPrivacyPolicyText = ""
    private var fullPrivacyPolicyAttributedText: NSAttributedString?
    private let titleMarqueeLabel = PremiumMarqueeLabel()
    private lazy var interactionBlockerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let venue = event?.venue {
            self.venueDetails = venue
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TicketItemTableViewCell.nib,
                           forCellReuseIdentifier: TicketItemTableViewCell.identifier)

        feesAndTaxesTableView.delegate = self
        feesAndTaxesTableView.dataSource = self
        feesAndTaxesTableView.register(TicketItemTableViewCell.nib,
                                       forCellReuseIdentifier: TicketItemTableViewCell.identifier)
        
        customQuestionTableView.delegate = self
        customQuestionTableView.dataSource = self
        customQuestionTableView.register(CustomQuestionTextFieldCell.nib,
                                         forCellReuseIdentifier: CustomQuestionTextFieldCell.identifier)
        customQuestionTableView.register(CustomQuestionDropdownCell.nib,
                                         forCellReuseIdentifier: CustomQuestionDropdownCell.identifier)
        customQuestionTableView.register(CustomQuestionCheckboxCell.nib,
                                         forCellReuseIdentifier: CustomQuestionCheckboxCell.identifier)
        
        customQuestionTableView.register(EventQuestionTVC.nib,
                                         forCellReuseIdentifier: EventQuestionTVC.identifier)

        questionHeightObservation = customQuestionTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.customQuestionTableViewHeight.constant = self.customQuestionTableView.contentSize.height
        }
                
        addPromoCodeBtn.indicator = MaterialLoadingIndicator(color: .white)
        purchaseTicketBtn.indicator = MaterialLoadingIndicator(color: .white)
        addPromoCodeBtn.bgColor = .clear
        promoCodeTextFeild.addTarget(self, action: #selector(promoCodeValueChanged), for: .editingChanged)
        updatePromoButtonIcon()
        updatePromoButtonState()
        purchaseTicketBtn.isEnabled = false
        purchaseTicketBtn.alpha = 0.5
        updateFeesAndTaxesTitle(hasTax: true)
        setTaxIncludedVisible(false)

        calculateTotal()
        setupTitleMarqueeLabel()
        setupPrivacyPolicyText()
        setupHeaderData()
        startCountdown()
        showCheckoutShimmer()
        getBooking(id: bookingId)
        getEventQuestions()

        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        feesAndTaxesTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)

        if !isFreeTicket {
            fetchPaymentIntentAndSetup(promoCode: "")
        }

        setupInteractionBlocker()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        wasInteractivePopGestureEnabled = navigationController?.interactivePopGestureRecognizer?.isEnabled ?? true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = wasInteractivePopGestureEnabled
    }

    deinit {
        countdownTimer?.invalidate()
        tableView.removeObserver(self, forKeyPath: "contentSize")
        feesAndTaxesTableView.removeObserver(self, forKeyPath: "contentSize")
    }

    private func setupHeaderData() {
//        venueLogoImg.sd_setImage(
//            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
//            placeholderImage: Constant.Icon.uploadImage
//        )
        if isFreeTicket {
            promoCodeParentView.isHidden = true
            feesAndTaxesParentTableView.isHidden = true
        } else {
            promoCodeParentView.isHidden = false
            feesAndTaxesParentTableView.isHidden = false
        }

        let displayVenueName = event?.displayVenueNameOrFallback(venueDetails?.name ?? "") ?? venueDetails?.name ?? ""
        venueName.text = displayVenueName
        venueName2.text = displayVenueName
        setHeaderTitle(event?.title)
        let policy = checkoutPolicy()
        fullPrivacyPolicyText = policy.text
        fullPrivacyPolicyAttributedText = policy.attributedText
        updatePrivacyPolicyLabel()
    }

    private func setupPrivacyPolicyText() {
        checkBox.isHidden = true
        checkBox.isUserInteractionEnabled = false
        AgreementTextFormatter.configure(privacyPolicyLbl)
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(onTapPrivacyPolicyLabel)
        )
        privacyPolicyLbl.addGestureRecognizer(tap)
        updatePrivacyPolicyLabel()
    }

    private func updatePrivacyPolicyLabel() {
        _ = AgreementTextFormatter.apply(
            to: privacyPolicyLbl,
            text: fullPrivacyPolicyText,
            isExpanded: isPrivacyPolicyExpanded,
            widthFallback: view.bounds.width - 64,
            expandedAttributedText: fullPrivacyPolicyAttributedText
        )
    }

    @objc private func onTapPrivacyPolicyLabel(_ gesture: UITapGestureRecognizer) {
        let range = AgreementTextFormatter.toggleRange(
            in: privacyPolicyLbl,
            isExpanded: isPrivacyPolicyExpanded
        )
        guard range.location != NSNotFound else { return }

        let tappedToggle = gesture.didTapAttributedTextInLabel(
            label: privacyPolicyLbl,
            inRange: range
        )
        guard tappedToggle || privacyPolicyLbl.bounds.contains(gesture.location(in: privacyPolicyLbl)) else { return }

        isPrivacyPolicyExpanded.toggle()
        UIView.performWithoutAnimation {
            updatePrivacyPolicyLabel()
            privacyPolicyLbl.superview?.layoutIfNeeded()
            privacyPolicyLbl.superview?.superview?.layoutIfNeeded()
        }
    }

    private func checkoutPolicy() -> (text: String, attributedText: NSAttributedString?) {
        let eventPolicy = normalizedPurchasePolicy(event?.eventSettings?.purchasePolicy)
        let venuePolicy = normalizedPurchasePolicy(event?.venue?.venueSettings?.purchasePolicy ?? venueDetails?.venueSettings?.purchasePolicy)
        let policy = eventPolicy ?? venuePolicy
        return (policy?.string ?? defaultPurchasePolicyText, policy)
    }

    private var defaultPurchasePolicyText: String {
        "By purchasing a ticket, you confirm that you are 21 years of age or older and agree to our Terms of Service and Privacy Policy. All sales are final and non-refundable. Patrons must adhere to the partner dress code. Entry is subject to valid ticket and ID verification at entry."
    }

    private func normalizedPurchasePolicy(_ policy: String?) -> NSAttributedString? {
        guard let trimmed = policy?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }

        let renderedText = trimmed.fromHTML
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if renderedText.isEmpty {
            return trimmed.contains("<") && trimmed.contains(">") ? nil : NSAttributedString(string: trimmed)
        }

        return trimmed.htmlToAttributedString ?? NSAttributedString(string: renderedText)
    }

    private func setupTitleMarqueeLabel() {
        titleMarqueeLabel.install(over: eventTitleLbl, horizontalInset: 72)
    }

    private func setHeaderTitle(_ title: String?) {
        titleMarqueeLabel.setText(title)
    }

    private func getBooking(id: String?) {
        
        guard let id = id else {
            isBookingLoaded = true
            hideCheckoutShimmerIfNeeded()
            return
        }
        
        if booking == nil {  }
        
        paymentService.fetchBookingDetail(bookingId: id) { [weak self] isSuccess, _, booking in
            guard let self = self else { return }
            if isSuccess {
                self.booking = booking
                self.reloadFeesUIFromBooking()
            }
            self.isBookingLoaded = true
            hideCheckoutShimmerIfNeeded()
        }
    }
    
    private func getEventQuestions() {
        paymentService.fetchEventBookingQuestions(eventUniqueId: event?.uniqueId ?? "") { [weak self] isSuccess, errMsg, questions in
            guard let self = self else { return }

            if isSuccess {
                self.eventQuestions = questions?.filter({ $0.isDeleted == false }) ?? []
                self.customQuestionView.isHidden = self.eventQuestions.isEmpty
                DispatchQueue.main.async {
                    self.customQuestionTableView.reloadData()
                }
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? "Error", message: "")
            }
        }
    }

    private func reloadFeesUIFromBooking() {
        feesAndTaxes = buildFeesArray(from: booking?.fees)
        feesAndTaxesTitleView.isHidden = feesAndTaxes.isEmpty
        feesAndTaxesTableView.reloadData()
    }
    
    private func updatePromoButtonIcon() {
        let imageName = isPromoCodeApplied ? "trash" : "ArrowRight"
        
        if isPromoCodeApplied {
            addPromoCodeBtn.setImage(UIImage(systemName: imageName), for: .normal)
            addPromoCodeBtn.tintColor = .white
        } else {
            addPromoCodeBtn.setImage(UIImage(named: imageName), for: .normal)
            addPromoCodeBtn.tintColor = nil
        }
        updatePromoButtonState()
    }

    @objc private func promoCodeValueChanged() {
        updatePromoButtonState()
    }

    private func updatePromoButtonState() {
        let hasPromoCode = !(promoCodeTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isEnabled = isPromoCodeApplied || hasPromoCode
        addPromoCodeBtn.isUserInteractionEnabled = isEnabled
        addPromoCodeBtn.alpha = isEnabled ? 1 : 0.5
    }

    private func setupInteractionBlocker() {
        view.addSubview(interactionBlockerView)
        NSLayoutConstraint.activate([
            interactionBlockerView.topAnchor.constraint(equalTo: view.topAnchor),
            interactionBlockerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            interactionBlockerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            interactionBlockerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setScreenInteractionBlocked(_ blocked: Bool) {
        interactionBlockerView.isHidden = !blocked
        if blocked {
            view.bringSubviewToFront(interactionBlockerView)
        }
    }

    private func calculateTotal() {
        let subtotal = selectedTickets.reduce(0.0) { result, ticket in
            let quantity = ticket.selectedTicketCount ?? 0
            let price = ticket.price ?? 0
            return result + (Double(quantity) * price)
        }

        totalAmountLbl.text = subtotal == 0 ? "Free" : CurrencyFormatter.amount(subtotal, symbol: currency, position: currencyPosition)
        setTaxIncludedVisible(false)
        self.isFreeTicket = subtotal == 0
        updatePurchaseButtonTitle()

        let color = whiteLabelAccentColor
        dateandtimeLbl.textColor = color
        purchaseTicketBtn.backgroundColor = color
        purchaseTicketBtn.setTitleColor(color.suitableTextColor(), for: .normal)

        if let customText = event?.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dateandtimeLbl.text = customText
        } else {
            let timezone = venueDetails?.useTimezone ?? ""

            let dateText = event?.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .EEEMMMD,
                customTimeZone: timezone
            ) ?? ""

            let startTime = event?.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            ) ?? ""

            let endTime = event?.endDateTime?.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            ) ?? "LATE"

            dateandtimeLbl.text = (!dateText.isEmpty && !startTime.isEmpty) ? "\(dateText) at \(startTime) - \(endTime)" : ""
        }
    }

    private func updatePurchaseButtonTitle() {
        let totalTickets = selectedTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        let ticketText = totalTickets == 1 ? "Ticket" : "Tickets"
        purchaseTicketBtn.setTitle(
            hasOnlyFreeSelectedTickets ? "Redeem \(ticketText)" : "Purchase \(ticketText)",
            for: .normal
        )
    }

    private var hasOnlyFreeSelectedTickets: Bool {
        selectedTickets.allSatisfy {
            ($0.price ?? 0) <= 0 && ($0.extraFees ?? 0) <= 0
        }
    }

    private func buildFeesArray(from fees: PaymentDetail?) -> [FeeDisplayItem] {
        guard let fees = fees else { return [] }
        if fees.total == fees.subTotal { return [] }

        var items: [FeeDisplayItem] = []

        if fees.customFee > 0 {
            items.append(FeeDisplayItem(title: fees.customFeeName ?? "Custom Fee", amount: fees.customFee))
        }
        if (fees.salesTax ?? 0) > 0 {
            items.append(FeeDisplayItem(title: fees.salesTaxName ?? "Sales Tax", amount: fees.salesTax ?? 0))
        }
        if fees.processingFee > 0 {
            items.append(FeeDisplayItem(title: "Processing Fee", amount: fees.processingFee))
        }
        return items
    }

    private func startCountdown() {
        updateTimerLabel()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                self.updateTimerLabel()
            } else {
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
                self.timerExpired()
            }
        }
    }

    private func updateTimerLabel() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLbl.text = "\(minutes) mins \(seconds) secs"
    }

    private func timerExpired() {
        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            self.countdownTimer?.invalidate()
            self.cancelBooking { [weak self] in
                self?.returnToEventDetails(animated: false)
            }
        }
        Alert.showAlertSheet(style: .alert, title: "Sorry, your ticket reservation has expired, please try again", message: "", actions: [okAction])
    }

    private func buildCoverTicketsForPaymentIntent() -> [[String: Any]] {
        var coverTickets = [[String: Any]]()
        selectedTickets.forEach {
            coverTickets.append([
                "ticketId": $0.id ?? "",
                "quantity": $0.selectedTicketCount ?? 0
            ])
        }
        return coverTickets
    }

    private func fetchPaymentIntentAndSetup(
        promoCode: String,
        completion: ((_ isSuccess: Bool) -> Void)? = nil
    ) {
        guard let bookingId = bookingId else {
            isPaymentIntentLoaded = true
            hideCheckoutShimmerIfNeeded()
            completion?(false)
            return
        }

        let coverTickets = buildCoverTicketsForPaymentIntent()

        paymentService.createPaymentIntent(
            bookingId: bookingId,
            selectedTickets: coverTickets,
            promoCode: promoCode,
            type: .singleTickedEvent
        ) { [weak self] isSuccess, errMsg, clientSecret, paymentHistoryId, ephemeralKey, paymentDetail, isFreeTicket in

            guard let self = self else { return }

            defer {
                self.isPaymentIntentLoaded = true
                self.hideCheckoutShimmerIfNeeded()
                completion?(isSuccess)
            }

            guard isSuccess, let clientSecret else {
                AppHaptic.error()
                Alert.showToast(errMsg ?? "Something went wrong")
                return
            }

            self.isFreeTicket = isFreeTicket
            self.paymentIntentClientSecret = clientSecret
            self.paymentHistoryId = paymentHistoryId
            self.ephemeralKey = ephemeralKey
            self.paymentDetail = paymentDetail

            self.updateUIWithPaymentDetail(paymentDetail)
            self.setupStripePaymentSheet(clientSecret: clientSecret, ephemeralKey: self.ephemeralKey)

            self.updatePurchaseButtonAvailability()
        }
    }

    private func updateUIWithPaymentDetail(_ detail: PaymentDetail?) {

        guard let detail = detail else {
            feesAndTaxes = []
            feesAndTaxesTitleView.isHidden = true
            feesAndTaxesTableView.reloadData()
            totalAmountLbl.text = "Free"
            feesAndTxtTotalAmountLbl.text = ""
            updateFeesAndTaxesTitle(hasTax: false)
            setTaxIncludedVisible(false)
            discountView.isHidden = true
            discountToalLbl.isHidden = true
            return
        }
        feesAndTaxes = buildFeesArray(from: detail)
        feesAndTaxesTitleView.isHidden = feesAndTaxes.isEmpty
        feesAndTaxesTableView.reloadData()
        let containsTax = hasSalesTax(detail)
        updateFeesAndTaxesTitle(hasTax: containsTax)
        setTaxIncludedVisible(containsTax)

        let total = detail.total
        let subTotal = detail.subTotal   

        let feesAmount = total - subTotal

        if total <= 0 {
            totalAmountLbl.text = "Free"
            feesAndTxtTotalAmountLbl.text = ""
        } else {
            totalAmountLbl.text = CurrencyFormatter.amount(total, symbol: currency, position: currencyPosition)
            feesAndTxtTotalAmountLbl.text = CurrencyFormatter.amount(feesAmount, symbol: currency, position: currencyPosition)
        }

        let discount = detail.discount ?? 0

        if discount > 0 {
            discountView.isHidden = false
            discountToalLbl.isHidden = false
            discountToalLbl.text = "-\(CurrencyFormatter.amount(discount, symbol: currency, position: currencyPosition))"
        } else {
            discountView.isHidden = true
            discountToalLbl.isHidden = true
        }
    }

    private func hasSalesTax(_ fees: PaymentDetail) -> Bool {
        if (fees.salesTax ?? 0) > 0 { return true }
        return fees.salesTaxes?.contains { ($0.salesTax ?? 0) > 0 } == true
    }

    private func setTaxIncludedVisible(_ visible: Bool) {
        totalTaxIncludedLbl.isHidden = !visible
        totalTaxIncludedHeight.constant = visible ? 12 : 0
    }

    private func updateFeesAndTaxesTitle(hasTax: Bool) {
        feesAndTaxesTitleLbl.text = hasTax ? "Fees & taxes" : "Fees"
    }
    
    private func setupStripePaymentSheet(clientSecret: String, ephemeralKey: String) {
        STPAPIClient.shared.publishableKey = Stripe.publishableKey

        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"

        config.customer = .init(
            id: UserDefault.shared.user?.stripeCusId ?? "",
            ephemeralKeySecret: ephemeralKey
        )

        config.allowsDelayedPaymentMethods = true

        config.applePay = .init(
            merchantId: "merchant.com.speakeasy",
            merchantCountryCode: "US"
        )

        paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
    }

    private func completePaymentSuccess() {
        guard let bookingId = bookingId else {
            isPaymentInitiated = false
            setScreenInteractionBlocked(false)
            AppHaptic.error()
            return
        }
        paymentService.confirmPaymentSuccess(paymentHistoryId: paymentHistoryId, bookingId: bookingId, optedPolicy: nil) { [weak self] isSuccess, _ in
            guard let self = self else { return }
            if isSuccess {
                AppHaptic.success()
                countdownTimer?.invalidate()
                NotificationCenter.default.postOrdersRefresh(.tickets)
                Navigate.to.showQRCode(
                    self,
                    booking: nil,
                    bookingId: bookingId,
                    type: .singleTickedEvent,
                    sourceEvent: self.event,
                    presentationMode: .pushedFromPurchase
                )
            } else {
                self.isPaymentInitiated = false
                self.setScreenInteractionBlocked(false)
                AppHaptic.error()
                Alert.showToast(Constant.String.somethingWrong)
            }
        }
    }

    private func createFreeEventBookingAndNavigate() {
        guard let eventId = event?.id else {
            isPaymentInitiated = false
            hidePurchaseButtonLoader()
            setScreenInteractionBlocked(false)
            return
        }

        let ticketsPayload: [[String: Any]] = selectedTickets.map {
            [
                "ticketId": $0.id ?? "",
                "ticketQuantity": ($0.selectedTicketCount ?? 0),
                "ticketPrice": $0.price ?? 0
            ]
        }

        let user = UserDefault.shared.user

        paymentService.checkEventTicketStock(
            eventId: eventId,
            code: user?.code ?? "+1",
            phone: user?.phone ?? "",
            gender: user?.gender ?? "UNASSIGNED",
            userId: user?.id ?? "",
            tickets: ticketsPayload
        ) { [weak self] isAvailable, errMsg in
            guard let self = self else { return }

            guard isAvailable else {
                self.isPaymentInitiated = false
                self.hidePurchaseButtonLoader()
                self.setScreenInteractionBlocked(false)
                Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                return
            }

            self.paymentService.createEventBooking(
                eventId: eventId,
                code: user?.code ?? "+1",
                phone: user?.phone ?? "",
                gender: user?.gender ?? "UNASSIGNED",
                userId: user?.id ?? "",
                tickets: ticketsPayload,
                promotionLinkId: self.promotionLinkId,
                promotionLinkUniqueCode: self.promotionLinkUniqueCode
            ) { [weak self] isSuccess, errMsg, id, message in
                guard let self = self else { return }
                if isSuccess, let id = id {
                    self.hidePurchaseButtonLoader()
                    AppHaptic.success()
                    self.countdownTimer?.invalidate()
                    NotificationCenter.default.postOrdersRefresh(.tickets)
                    Navigate.to.showQRCode(
                        self,
                        booking: nil,
                        bookingId: id,
                        type: .singleTickedEvent,
                        sourceEvent: self.event,
                        presentationMode: .pushedFromPurchase
                    )
                } else {
                    self.isPaymentInitiated = false
                    self.hidePurchaseButtonLoader()
                    self.setScreenInteractionBlocked(false)
                    AppHaptic.error()
                    Alert.showToast(message ?? errMsg ?? Constant.String.somethingWrong)
                }
            }
        }
    }
    
    private func cancelBooking() {
        cancelBooking(completion: nil)
    }

    private func cancelBooking(completion: (() -> Void)?) {
        countdownTimer?.invalidate()
        guard let bookingId, !bookingId.isEmpty else {
            completion?()
            return
        }
        paymentService.cancelBooking(bookingId: bookingId) { _, _ in
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    private func showCancelTransactionPrompt() {
        guard !isPaymentInitiated, !isPromoRequestInProgress, !isCancellingTransaction else { return }
        presentTransactionCancelConfirmation { [weak self] cancelPrompt in
            guard let self else {
                cancelPrompt.finishCancelTransaction()
                return
            }
            self.cancelBookingAndReturnToEventDetails(cancelPrompt: cancelPrompt)
        }
    }

    private func handlePaymentCanceled() {
        isPaymentInitiated = false
        AppHaptic.warning()
        cancelBookingAndReturnToEventDetails()
    }

    private func cancelBookingAndReturnToEventDetails(
        cancelPrompt: TransactionCancelPopupVC? = nil
    ) {
        guard !isCancellingTransaction else { return }
        isCancellingTransaction = true
        setScreenInteractionBlocked(true)

        cancelBooking { [weak self] in
            guard let self else { return }
            self.isCancellingTransaction = false
            self.setScreenInteractionBlocked(false)

            let returnAction = { [weak self] in
                guard let self else { return }
                self.notifyEventDetailsTransactionCanceled()
                self.returnToEventDetails(animated: false)
            }

            if let cancelPrompt {
                cancelPrompt.finishCancelTransaction(afterDismiss: returnAction)
            } else {
                returnAction()
            }
        }
    }

    private func notifyEventDetailsTransactionCanceled() {
        var userInfo: [String: String] = [:]
        if let eventId = event?.uniqueId ?? event?.id,
           !eventId.isEmpty {

            userInfo["eventId"] = eventId
        }

        NotificationCenter.default.post(
            name: .eventTransactionDidCancelAndReturnToDetails,
            object: nil,
            userInfo: userInfo
        )
    }

    private func returnToEventDetails(animated: Bool) {
        guard let navigationController else { return }
        if let eventDetailsVC = navigationController.viewControllers.last(where: { $0 is EventDetailsVC }) {
            navigationController.popToViewController(eventDetailsVC, animated: animated)
        } else {
            navigationController.popViewController(animated: animated)
        }
    }
    
    private func postQuestionAns(ans: [Any]) {
        paymentService.submitEventBookingAnswers(
            eventUniqueId: event?.uniqueId ?? "",
            answers: ans,
            bookingId: bookingId ?? ""
        ) { [weak self] isSuccess, errMsg in
            guard let self = self else { return }

            if isSuccess {
                self.isSubmittingQuestions = false
                self.isEventQueAnsCollected = true
                self.customQuestionTableView.reloadData()

//                if self.isFreeTicket {
//                    self.paymentMethodView.isHidden = true
//                    self.buyNowBtn.setTitle("GET FREE TICKET", for: .normal)
//                } else {
//                    self.paymentMethodView.isHidden = false
//                    self.buyNowBtn.setTitle("BUY TICKET", for: .normal)
//                }

                self.isPaymentInitiated = false
                self.onClickPurchaseTicket(UIButton())
            } else {
                self.isSubmittingQuestions = false
                self.isPaymentInitiated = false
                self.setScreenInteractionBlocked(false)
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }

    @IBAction func onClickSubmitPromoBtn(_ sender: Any) {
        guard !isPromoRequestInProgress, !isPaymentInitiated else { return }

        let promo = (promoCodeTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        isPromoRequestInProgress = true
        setScreenInteractionBlocked(true)
        addPromoCodeBtn.showLoader(userInteraction: false)

        if isPromoCodeApplied {
            AppHaptic.primaryAction()
            fetchPaymentIntentAndSetup(promoCode: "", completion: { [weak self] isSuccess in
                guard let self else { return }
                self.addPromoCodeBtn.hideLoader()
                self.isPromoRequestInProgress = false
                self.setScreenInteractionBlocked(false)

                if isSuccess {
                    self.isPromoCodeApplied = false
                    self.appliedPromoCode = ""
                    self.promoCodeTextFeild.isUserInteractionEnabled = true
                    self.promoCodeTextFeild.alpha = 1
                    self.promoCodeTextFeild.text = ""
                    self.updatePromoButtonIcon()
                }
            })
        } else {
            guard !promo.isEmpty else {
                addPromoCodeBtn.hideLoader()
                isPromoRequestInProgress = false
                setScreenInteractionBlocked(false)
                AppHaptic.warning()
                return
            }

            AppHaptic.primaryAction()
            fetchPaymentIntentAndSetup(promoCode: promo, completion: { [weak self] isSuccess in
                guard let self else { return }
                self.addPromoCodeBtn.hideLoader()
                self.isPromoRequestInProgress = false
                self.setScreenInteractionBlocked(false)

                if isSuccess {
                    self.isPromoCodeApplied = true
                    self.appliedPromoCode = promo
                    self.promoCodeTextFeild.isUserInteractionEnabled = false
                    self.promoCodeTextFeild.alpha = 0.5
                    self.updatePromoButtonIcon()
                } else {
                    self.isPromoCodeApplied = false
                    self.appliedPromoCode = ""
                    self.promoCodeTextFeild.text = ""
                    self.promoCodeTextFeild.isUserInteractionEnabled = true
                    self.promoCodeTextFeild.alpha = 1
                    self.updatePromoButtonIcon()
                }
            })
        }
    }
    
    @IBAction func onClickCheckBox(_ sender: UIButton) {
        guard !checkBox.isHidden, !isPaymentInitiated, !isPromoRequestInProgress else { return }

        sender.isSelected.toggle()
        AppHaptic.selectionChanged()
        
        let image = sender.isSelected
            ? UIImage(named: "checkBox")
            : UIImage(named: "ic_checkbox_unchecked")
        
        sender.setImage(image, for: .normal)
        purchaseTicketBtn.isEnabled = sender.isSelected
        purchaseTicketBtn.alpha = sender.isSelected ? 1.0 : 0.5
        UIView.animate(withDuration: 0.15, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                sender.transform = .identity
            }
        }
    }
    
    @IBAction func onClickPurchaseTicket(_ sender: Any) {
        guard !isPaymentInitiated, !isPromoRequestInProgress, !isCancellingTransaction else { return }

        isPaymentInitiated = true
        setScreenInteractionBlocked(true)

        if !validateQuestionsAndProceed() {
            if !isSubmittingQuestions {
                isPaymentInitiated = false
                setScreenInteractionBlocked(false)
            }
            return
        }

        AppHaptic.primaryAction()
        if isFreeTicket {
            showPurchaseButtonLoader()
            DispatchQueue.main.async { [weak self] in
                self?.createFreeEventBookingAndNavigate()
            }
            return
        }

        guard let paymentSheet else {
            isPaymentInitiated = false
            setScreenInteractionBlocked(false)
            AppHaptic.warning()
            return
        }

        paymentSheet.present(from: self) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .completed:
                self.completePaymentSuccess()

            case .canceled:
                self.handlePaymentCanceled()

            case .failed:
                self.isPaymentInitiated = false
                self.setScreenInteractionBlocked(false)
                AppHaptic.error()
            }
        }
    }

    private func showPurchaseButtonLoader() {
        purchaseTicketBtn.showLoader(userInteraction: false)
    }

    private func hidePurchaseButtonLoader() {
        purchaseTicketBtn.hideLoader()
    }

    private func validateQuestionsAndProceed() -> Bool {
        let answers: [[String: Any]] = questionAnswers.map {
            [
                "eventQuestionId": $0.key,
                "answer": $0.value
            ]
        }

        if !eventQuestions.isEmpty,
           !isEventQueAnsCollected {

            guard setAnswerData else {
                AppHaptic.error()
                Alert.showAlertSheet(style: .alert, title: "Please fill required answers", message: "")
                return false
            }

            isSubmittingQuestions = true
            postQuestionAns(ans: answers)
            return false
        }

        return true
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        guard !isPaymentInitiated, !isPromoRequestInProgress else { return }
        showCancelTransactionPrompt()

    }

    @IBAction func onClickFeesAndTaxes(_ sender: Any) {
        guard !isPaymentInitiated, !isPromoRequestInProgress else { return }

        AppHaptic.selectionChanged()
        let isHidden = feesAndTaxesContainerView.isHidden
        feesAndTaxesContainerView.isHidden.toggle()
        UIView.animate(withDuration: 0.25) {
            self.feesDropDowenIc.transform = isHidden
            ? CGAffineTransform(rotationAngle: .pi)
            : .identity
        }
    }
    
    @IBAction func onClickAddPromoCode(_ sender: Any) {
        guard !isPaymentInitiated, !isPromoRequestInProgress else { return }
        AppHaptic.selectionChanged()
        promoCodeView.isHidden.toggle()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {

        if keyPath == "contentSize", let table = object as? UITableView {
            if table == self.tableView {
                tableViewHeight.constant = table.contentSize.height
            } else if table == self.feesAndTaxesTableView {
                feesAndTaxesTableViewHeight.constant = table.contentSize.height
            }
        }
    }
    
    @objc private func handleBackSwipe() {
        showCancelTransactionPrompt()
    }
    
    private func showCheckoutShimmer() {
        shimmerView.isHidden = false
        shimmerView.subviews.forEach { $0.removeFromSuperview() }
        shimmerBlocks.removeAll()

        let content = UIView()
        shimmerView.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: shimmerView.topAnchor),
            content.leadingAnchor.constraint(equalTo: shimmerView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: shimmerView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: shimmerView.bottomAnchor)
        ])

        func makeBlock(height: CGFloat, width: CGFloat? = nil, corner: CGFloat = 8) -> ShimmerViewV3 {
            let view = ShimmerViewV3()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layer.cornerRadius = corner
            view.clipsToBounds = true
            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalToConstant: height)
            ])
            if let width {
                view.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            shimmerBlocks.append(view)
            return view
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        content.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -16)
        ])

        // first divider line
        let line1 = UIView()
        line1.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        line1.translatesAutoresizingMaskIntoConstraints = false
        line1.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        stack.addArrangedSubview(line1)

        // row 1
        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.alignment = .center
        row1.distribution = .equalSpacing
        row1.addArrangedSubview(makeBlock(height: 14, width: 120))
        row1.addArrangedSubview(makeBlock(height: 14, width: 58))
        stack.addArrangedSubview(row1)

        // row 2
        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.alignment = .center
        row2.distribution = .equalSpacing
        row2.addArrangedSubview(makeBlock(height: 14, width: 120))
        row2.addArrangedSubview(makeBlock(height: 14, width: 58))
        stack.addArrangedSubview(row2)

        // second divider line
        let line2 = UIView()
        line2.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        line2.translatesAutoresizingMaskIntoConstraints = false
        line2.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        stack.addArrangedSubview(line2)

        // row 3
        let row3 = UIStackView()
        row3.axis = .horizontal
        row3.alignment = .center
        row3.distribution = .equalSpacing
        row3.addArrangedSubview(makeBlock(height: 14, width: 100))
        row3.addArrangedSubview(makeBlock(height: 14, width: 48))
        stack.addArrangedSubview(row3)

        shimmerBlocks.forEach { $0.startShimmer() }
    }

    private func hideCheckoutShimmerIfNeeded() {
        if isFreeTicket {
            guard isBookingLoaded else { return }
        } else {
            guard isBookingLoaded, isPaymentIntentLoaded else { return }
        }
        shimmerBlocks.forEach { $0.stopShimmer() }
        shimmerView.isHidden = true
        updatePurchaseButtonAvailability()
    }

    private func updatePurchaseButtonAvailability() {
        let isReady = isFreeTicket ? isBookingLoaded : (isBookingLoaded && isPaymentIntentLoaded)
        purchaseTicketBtn.isEnabled = isReady && !isPaymentInitiated && !isPromoRequestInProgress
        purchaseTicketBtn.alpha = purchaseTicketBtn.isEnabled ? 1.0 : 0.5
    }
    
}

extension TicketCheckoutVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if tableView == self.tableView {
            return selectedTickets.count
        } else if tableView == self.feesAndTaxesTableView {
            return feesAndTaxes.count
        } else if tableView == self.customQuestionTableView {
            return eventQuestions.count
        }

        return 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if tableView == self.tableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketItemTableViewCell.identifier,
                for: indexPath
            ) as? TicketItemTableViewCell else { return UITableViewCell() }

            cell.selectionStyle = .none

            let ticket = selectedTickets[indexPath.row]
            let quantity = ticket.selectedTicketCount ?? 0
            let price = (ticket.price ?? 0) - (ticket.extraFees ?? 0)
            let total = Double(quantity) * price

            cell.titleLbl.text = "\(quantity)x \(ticket.tierName)"
            cell.amountLbl.text = CurrencyFormatter.amount(total, symbol: currency, position: currencyPosition)

            return cell
        }

        if tableView == self.feesAndTaxesTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketItemTableViewCell.identifier,
                for: indexPath
            ) as? TicketItemTableViewCell else { return UITableViewCell() }

            let item = feesAndTaxes[indexPath.row]
            let isProcessingFee = item.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "processing fee"
            cell.configure(
                title: item.title,
                amount: CurrencyFormatter.amount(item.amount, symbol: currency, position: currencyPosition),
                infoText: isProcessingFee ? "This covers payment processing fees" : nil
            )
            cell.selectionStyle = .none

            return cell
        }

        if tableView == self.customQuestionTableView {

            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: EventQuestionTVC.identifier,
                for: indexPath
            ) as? EventQuestionTVC else { return UITableViewCell() }

            let question = eventQuestions[indexPath.row]

            cell.delegate = self
            cell.selectedIndex = indexPath.row
            cell.questionType = question.questionType

            cell.questionNameLbl.text = "\(question.question) \(question.isOptional == false ? "*" : "")"
            cell.checkBoxQuestionLbl.text = cell.questionNameLbl.text

            cell.multiSelectView.isHidden = !(question.questionType == "SINGLE_SELECT" || question.questionType == "MULTI_SELECT")
            cell.checkBoxView.isHidden = !(question.questionType == "CHECKBOX")
            cell.textQuestionView.isHidden = !(question.questionType == "TEXT")
            cell.questionView.isHidden = question.questionType == "CHECKBOX"

            cell.options = question.eventQuestionHasOption?.map { $0.option } ?? []

            let isEnabled = !isEventQueAnsCollected
            cell.dropDownBtn.isUserInteractionEnabled = isEnabled
            cell.textQuestionView.isUserInteractionEnabled = isEnabled
            cell.checkBox.isUserInteractionEnabled = isEnabled
            cell.multiSelectView.isUserInteractionEnabled = isEnabled
            cell.selectionStyle = .none

            if let answer = questionAnswers[question.id] {
                if let str = answer as? String {
                    if question.questionType == "TEXT" {
                        cell.textQuestionView.text = str
                    } else {
                        cell.multiSelectLbl.text = str
                    }
                } else if let arr = answer as? [String] {
                    cell.multiSelectLbl.text = arr.joined(separator: ", ")
                } else if let bool = answer as? Bool {
                    cell.checkBox.isSelected = bool
                }
            }

            return cell
        }

        return UITableViewCell()
    }
}

extension TicketCheckoutVC: DropDownDelegate {

    func textAns(ans: String, index: Int) {
        let id = eventQuestions[index].id
        questionAnswers[id] = ans
    }

    func boolAns(ans: Bool, index: Int) {
        let id = eventQuestions[index].id
        questionAnswers[id] = ans
    }

    func multipleAns(ans: [String], index: Int) {
        let id = eventQuestions[index].id
        questionAnswers[id] = ans
    }
}
