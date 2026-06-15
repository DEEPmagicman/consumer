import UIKit
import MHLoadingButton
import StripePaymentSheet

// MARK: - OrderListViewController

final class OrderListViewController: UIViewController {

    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var ticketTableView: UITableView!
    @IBOutlet weak var eventNameLbl: UILabel!
    @IBOutlet weak var yourOrderView: UIView!
    @IBOutlet weak var promoCodeStackView: UIStackView!
    @IBOutlet weak var addPromoCodeView: UIView!
    @IBOutlet weak var pluseBtn: UIButton!
    @IBOutlet weak var addCodeTextFeild: UITextField!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var checkOutView: CheckoutBarView!
    @IBOutlet weak var feesAndTaxesStackView: UIStackView!
    @IBOutlet weak var feesAndTaxesHiddenView: UIView!
    @IBOutlet weak var feesAndTaxesTableView: UITableView!
    @IBOutlet weak var feesAndTaxesTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feesAndTaxesParentView: UIView!
    @IBOutlet weak var promoCodeTitleView: UIView!
    @IBOutlet weak var promoCodeAppliedView: UIView!
    @IBOutlet weak var promoCodeLbl: UILabel!
    @IBOutlet weak var promoCodeTitleLbl: UILabel!
    @IBOutlet weak var feesDropDowenIc: UIImageView!
    @IBOutlet weak var applyPromoBtn: LoadingButton!
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
    var selectedTickets: [EventTicket] = []
    var venueDetails: ClipVenue?
    var event: Event?
    var booking: Booking?
    var bookingId: String?
    var selectedPaymentMethod: PaymentType?
    var cardDetails: CardDetails?

    // MARK: - Stripe state
    private var paymentSheet: PaymentSheet?
    private var paymentIntentClientSecret: String = ""
    private var stripePaymentHistoryId: String = ""
    private var stripeEphemeralKey: String = ""
    private var savedPaymentMethods: [PaymentMethod] = []
    private var isFreeTicket: Bool = false
    private var isPaymentInitiated = false

    // MARK: - UI state
    private var isTermsAccepted = true
    private var isVenueMessageAccepted = true
    private var isTermsExpanded = false
    private let collapsedLines = 2
    private var hasLaidOutTerms = false
    private var fullTermsText = ""

    // MARK: - Data state
    private var feesAndTaxes: [FeeDisplayItem] = []
    private var paymentDetail: PaymentDetail?
    private var isPromoCodeApplied = false
    private var appliedPromoCode = ""

    private var currency: String {
        venueDetails?.venueSettings?.currencySymbol ?? "$"
    }

    private let posterHeaderView = EventPosterHeaderView()
    private let paymentService = PaymentService()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSavedPaymentMethods()
        setupTableViews()
        setupHeaderData()
        calculateTotal()
        setupTermsText()
        fetchPaymentIntentAndSetup(promoCode: "")
        getBooking(id: bookingId)
        ticketTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        feesAndTaxesTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        applyPromoBtn.indicator = MaterialLoadingIndicator(color: .black)
        fullTermsText = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s."
        venueMessageLbl.text = "Venue message text here"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasLaidOutTerms, termsAndConditionsLbl.frame.width > 0 else { return }
        hasLaidOutTerms = true
        updateTermsLabel()
        setupPosterBackground()
    }

    deinit {
        ticketTableView.removeObserver(self, forKeyPath: "contentSize")
        feesAndTaxesTableView.removeObserver(self, forKeyPath: "contentSize")
    }

    // MARK: - Setup

    private func setupUI() {
        yourOrderView.applyAutoBorderBackground()
//        feesAndTaxesParentView.applyAutoBorderBackground()
        view.applyScreenBgGradient()
        addPromoCodeView.isHidden = true
        promoCodeAppliedView.isHidden = true
        promoCodeTitleView.isHidden = false

        paymentTypeView.isUserInteractionEnabled = false
        updatePaymentMethodUI()

        checkOutView.delegate = self
    }

    private func loadSavedPaymentMethods() {
        let customerId = UserDefault.shared.user?.stripeCusId ?? ""
        guard !customerId.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.updatePaymentMethodUI()
            }
            return
        }

        PaymentPresenter.getUserSavedMethods(customerId: customerId) { [weak self] isSuccess, _, paymentMethods in
            guard let self else { return }

            DispatchQueue.main.async {
                if isSuccess {
                    self.savedPaymentMethods = paymentMethods
                    if self.selectedPaymentMethod == nil {
                        self.selectedPaymentMethod = paymentMethods.isEmpty ? .applePay : .card
                    }
                }

                self.updatePaymentMethodUI()
            }
        }
    }

    private func updatePaymentMethodUI() {
        let title: String
        let image: UIImage?

        if let savedMethod = savedPaymentMethods.first {
            title = "\(savedMethod.brand.capitalized) ending \(savedMethod.last4)"
            image = savedMethod.brand.paymentImg
        } else if selectedPaymentMethod == .applePay {
            title = "Apple Pay"
            image = UIImage(named: "applePayIcon")
        } else if let cardDetails, selectedPaymentMethod == .card {
            let last4 = cardDetails.cardNumber.suffix(4)
            title = last4.isEmpty ? "Pay with Card" : "Card ending \(last4)"
            image = UIImage(named: "creditCardIcon")
        } else if selectedPaymentMethod == .card {
            title = "Pay with Card"
            image = UIImage(named: "creditCardIcon")
        } else {
            title = "Apple Pay"
            image = UIImage(named: "applePayIcon")
        }

        paymentTypeName.text = title
        paymentCardImage.image = image
    }

    private func setupTableViews() {
        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        feesAndTaxesTableView.delegate = self
        feesAndTaxesTableView.dataSource = self
        ticketTableView.separatorStyle = .none
        feesAndTaxesTableView.separatorStyle = .none
        ticketTableView.showsVerticalScrollIndicator = false
        feesAndTaxesTableView.showsVerticalScrollIndicator = false
        ticketTableView.register(
            OrderItemTableViewCell.nib,
            forCellReuseIdentifier: OrderItemTableViewCell.identifier
        )
        feesAndTaxesTableView.register(
            TicketItemTableViewCell.nib,
            forCellReuseIdentifier: TicketItemTableViewCell.identifier
        )
    }

    private func setupPosterBackground() {
        backgroundContainerView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: backgroundContainerView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: backgroundContainerView.bottomAnchor)
        ])
        posterHeaderView.loadImage(from: (event?.flyer?.key ?? "").imageURL)
    }

    private func setupHeaderData() {
        venueName.text = event?.venue?.name.uppercased()
        eventNameLbl.text = event?.title

        if let customText = event?.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dateandtimeLbl.text = customText
        } else {
            let timezone = venueDetails?.useTimezone ?? ""
            let dateText = event?.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss, to: .EEEMMMD, customTimeZone: timezone) ?? ""
            let startTime = event?.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: timezone) ?? ""
            let endTime = event?.endDateTime?.convertDateFormat(
                from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: timezone) ?? "LATE"
            dateandtimeLbl.text = "\(dateText) at \(startTime) - \(endTime)"
        }
    }

    // MARK: - Terms & Conditions

    private func setupTermsText() {
        termsAndConditionsLbl.font = Constant.Font.geistMedium(size: 12)
        termsAndConditionsLbl.textColor = .white
        termsAndConditionsLbl.isUserInteractionEnabled = true
        venueMessageLbl.font = Constant.Font.geistMedium(size: 12)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapTermsLabel))
        termsAndConditionsLbl.addGestureRecognizer(tap)
        updateTermsCheckboxUI()
        updateVenueCheckboxUI()
    }

    private func updateTermsLabel() {
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

    @objc private func onTapTermsLabel(_ gesture: UITapGestureRecognizer) {
        guard let text = termsAndConditionsLbl.attributedText?.string else { return }
        let targetText = isTermsExpanded ? "View Less" : "View More"
        let range = (text as NSString).range(of: targetText)
        guard gesture.didTapAttributedTextInLabel(label: termsAndConditionsLbl, inRange: range) else { return }
        isTermsExpanded.toggle()
        updateTermsLabel()
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    // MARK: - KVO

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "contentSize", let table = object as? UITableView else { return }
        if table === ticketTableView {
            tableViewHeight.constant = table.contentSize.height
        } else if table === feesAndTaxesTableView {
            feesAndTaxesTableViewHeight.constant = table.contentSize.height
        }
        view.layoutIfNeeded()
    }

    // MARK: - Totals

    private func calculateTotal() {
        let subtotal = selectedTickets.reduce(0.0) {
            $0 + (Double($1.selectedTicketCount ?? 0) * ($1.price ?? 0))
        }
        let totalTickets = selectedTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        checkOutView.updateSummary(currency: currency, count: totalTickets, subtotal: subtotal, fees: 0)
        checkOutView.setButtonTitle("Purchase Tickets")
    }

    // MARK: - Checkbox UI

    private func updateTermsCheckboxUI() {
        termsAndConditionsBtn.setImage(
            isTermsAccepted ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon,
            for: .normal
        )
    }

    private func updateVenueCheckboxUI() {
        venueMessageBtn.setImage(
            isVenueMessageAccepted ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon,
            for: .normal
        )
    }

    // MARK: - IBActions

    @IBAction func onClickTermsBtn(_ sender: UIButton) {
        isTermsAccepted.toggle()
        updateTermsCheckboxUI()
    }

    @IBAction func onClickVenueMessageBtn(_ sender: UIButton) {
        isVenueMessageAccepted.toggle()
        updateVenueCheckboxUI()
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickApplyBtn(_ sender: Any) {
        let promo = (addCodeTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !promo.isEmpty else { return }
        applyPromoBtn.showLoader(userInteraction: false)
        fetchPaymentIntentAndSetup(promoCode: promo)
    }

    @IBAction func onClickPluseBtn(_ sender: Any) {
        let shouldShow = addPromoCodeView.isHidden
        UIView.animate(withDuration: 0.2) {
            self.pluseBtn.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            self.pluseBtn.setImage(
                UIImage(named: shouldShow ? "minusPromoIcon" : "plusIcon"),
                for: .normal
            )
            UIView.animate(withDuration: 0.25) { self.pluseBtn.transform = .identity }
        }

        if shouldShow {
            addPromoCodeView.alpha = 0
            addPromoCodeView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            addPromoCodeView.isHidden = false
            UIView.animate(
                withDuration: 0.35, delay: 0,
                usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5
            ) {
                self.addPromoCodeView.alpha = 1
                self.addPromoCodeView.transform = .identity
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.addPromoCodeView.alpha = 0
                self.addPromoCodeView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            } completion: { _ in
                self.addPromoCodeView.isHidden = true
                self.addPromoCodeView.transform = .identity
            }
        }
    }

    @IBAction func onClickRemovePromoCodeBtn(_ sender: Any) {
        isPromoCodeApplied = false
        appliedPromoCode = ""
        addCodeTextFeild.text = ""
        addCodeTextFeild.isUserInteractionEnabled = true
        addCodeTextFeild.alpha = 1
        updatePromoCodeUI()
        fetchPaymentIntentAndSetup(promoCode: "")
    }

    @IBAction func onClickFeesAndTaxesView(_ sender: Any) {
        let shouldShow = feesAndTaxesHiddenView.isHidden
        UIView.animate(withDuration: 0.2) {
            self.feesDropDowenIc.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            UIView.animate(withDuration: 0.25) {
                self.feesDropDowenIc.transform = shouldShow
                    ? CGAffineTransform(rotationAngle: .pi) : .identity
            }
        }

        if shouldShow {
            feesAndTaxesHiddenView.alpha = 0
            feesAndTaxesHiddenView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            feesAndTaxesHiddenView.isHidden = false
            UIView.animate(
                withDuration: 0.35, delay: 0,
                usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5,
                options: .curveEaseInOut
            ) {
                self.feesAndTaxesHiddenView.alpha = 1
                self.feesAndTaxesHiddenView.transform = .identity
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.feesAndTaxesHiddenView.alpha = 0
                self.feesAndTaxesHiddenView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            } completion: { _ in
                self.feesAndTaxesHiddenView.isHidden = true
                self.feesAndTaxesHiddenView.transform = .identity
            }
        }
    }

    @IBAction func onClickCardBtn(_ sender: Any) {
        startPaymentFlow()
    }

    // MARK: - Booking

    private func getBooking(id: String?) {
        guard let id else { return }
        paymentService.fetchBookingDetail(bookingId: id) { [weak self] isSuccess, _, booking in
            guard let self else { return }
            if isSuccess {
                self.booking = booking
                self.reloadFeesUIFromBooking()
            }
        }
    }

    private func reloadFeesUIFromBooking() {
        feesAndTaxes = buildFeesArray(from: booking?.fees)
        feesAndTaxesHiddenView.isHidden = feesAndTaxes.isEmpty
        feesAndTaxesTableView.reloadData()
        DispatchQueue.main.async {
            self.feesAndTaxesTableViewHeight.constant = self.feesAndTaxesTableView.contentSize.height
        }
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

    // MARK: - Payment Intent

    private func fetchPaymentIntentAndSetup(promoCode: String) {
        guard let bookingId else { return }

        let coverTickets = buildCoverTicketsForPaymentIntent()

        paymentService.createPaymentIntent(
            bookingId: bookingId,
            selectedTickets: coverTickets,
            promoCode: promoCode,
            type: .singleTickedEvent
        ) { [weak self] isSuccess, errMsg, clientSecret, paymentHistoryId, ephemeralKey, paymentDetail, isFreeTicket in
            guard let self else { return }

            DispatchQueue.main.async {
                self.applyPromoBtn.hideLoader()

                guard isSuccess else {
                    Alert.showToast(errMsg ?? "Something went wrong")
                    return
                }

                self.isFreeTicket              = isFreeTicket
                self.stripePaymentHistoryId    = paymentHistoryId
                self.paymentIntentClientSecret = clientSecret ?? ""
                self.stripeEphemeralKey        = ephemeralKey
                self.paymentDetail             = paymentDetail

                let discount = paymentDetail?.discount ?? 0
                if promoCode.isEmpty {
                    self.isPromoCodeApplied = false
                    self.appliedPromoCode   = ""
                } else if discount > 0 {
                    self.isPromoCodeApplied = true
                    self.appliedPromoCode   = promoCode
                    self.addCodeTextFeild.isUserInteractionEnabled = false
                    self.addCodeTextFeild.alpha = 0.5
                } else {
                    self.isPromoCodeApplied = false
                    self.appliedPromoCode   = ""
                    self.addCodeTextFeild.isUserInteractionEnabled = true
                    self.addCodeTextFeild.alpha = 1
                }

                self.updatePromoCodeUI()
                self.updateUIWithPaymentDetail(paymentDetail)

                // Setup Stripe for both card and Apple Pay
                if !isFreeTicket, let secret = clientSecret, !secret.isEmpty {
                    STPAPIClient.shared.publishableKey = Stripe.publishableKey
                    self.setupPaymentSheet(
                        clientSecret: secret,
                        ephemeralKey: ephemeralKey
                    )
                }
            }
        }
    }

    // MARK: - Stripe: PaymentSheet (Apple Pay)

    private func setupPaymentSheet(clientSecret: String, ephemeralKey: String) {
        STPAPIClient.shared.publishableKey = Stripe.publishableKey

        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"

        let customerId = UserDefault.shared.user?.stripeCusId ?? ""
        if !customerId.isEmpty && !ephemeralKey.isEmpty {
            config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
        }

        config.savePaymentMethodOptInBehavior = .automatic
        config.allowsDelayedPaymentMethods = true
        config.applePay = .init(
            merchantId: "merchant.com.speakeasy",
            merchantCountryCode: "US"
        )

        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: config
        )
        paymentTypeView.isUserInteractionEnabled = true
    }

    // MARK: - UI Updates

    private func updateUIWithPaymentDetail(_ detail: PaymentDetail?) {
        paymentTypeView.isHidden = isFreeTicket

        guard let detail else {
            feesAndTaxes = []
            feesAndTaxesHiddenView.isHidden = true
            feesAndTaxesTableView.reloadData()
            paymentTypeView.isUserInteractionEnabled = paymentSheet != nil && !isFreeTicket
            return
        }

        feesAndTaxes = buildFeesArray(from: detail)
        feesAndTaxesTableView.reloadData()

        let totalTickets = selectedTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        let feesAmount = detail.total - detail.subTotal
        checkOutView.updateSummary(
            currency: currency,
            count: totalTickets,
            subtotal: detail.total,
            fees: feesAmount
        )

        let discount = detail.discount ?? 0
        if discount > 0 {
            promoCodeAppliedView.isHidden = false
            promoCodeTitleView.isHidden = true
            promoCodeTitleLbl.text = "-\(currency)\(discount.decimalFormat(true)) Discount"
        } else {
            promoCodeAppliedView.isHidden = true
            promoCodeTitleView.isHidden = false
        }

        DispatchQueue.main.async {
            self.tableViewHeight.constant = self.ticketTableView.contentSize.height
            self.feesAndTaxesTableViewHeight.constant = self.feesAndTaxesTableView.contentSize.height
        }
        paymentTypeView.isUserInteractionEnabled = paymentSheet != nil && !isFreeTicket
    }

    private func buildFeesArray(from fees: PaymentDetail?) -> [FeeDisplayItem] {
        guard let fees, fees.total != fees.subTotal else { return [] }
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

    private func updatePromoCodeUI() {
        promoCodeAppliedView.isHidden = !isPromoCodeApplied
        promoCodeTitleView.isHidden = isPromoCodeApplied
        if isPromoCodeApplied {
            promoCodeLbl.text = appliedPromoCode.uppercased()
            let discount = paymentDetail?.discount ?? 0
            promoCodeTitleLbl.text = discount > 0
                ? "\(currency)\(discount.decimalFormat(true)) OFF Applied"
                : "Promo Applied"
        } else {
            promoCodeLbl.text = ""
            promoCodeTitleLbl.text = ""
            addCodeTextFeild.text = ""
            addCodeTextFeild.isUserInteractionEnabled = true
            addCodeTextFeild.alpha = 1
        }
    }

    // MARK: - Stripe Checkout

    private func startPaymentFlow() {
        guard !isPaymentInitiated else { return }

        guard isTermsAccepted || termsAndConditions.isHidden else {
            Alert.showToast("Please accept the terms and conditions")
            return
        }

        if !venueMessageView.isHidden && !isVenueMessageAccepted {
            Alert.showToast("Please accept the venue message")
            return
        }

        if isFreeTicket {
            isPaymentInitiated = true
            confirmPaymentAndNavigate()
            return
        }

        guard let paymentSheet else {
            Alert.showToast("Payment not ready yet. Please wait.")
            return
        }

        isPaymentInitiated = true
        paymentSheet.present(from: self) { [weak self] result in
            guard let self else { return }

            switch result {
            case .completed:
                self.confirmPaymentAndNavigate()
            case .canceled:
                self.isPaymentInitiated = false
            case .failed:
                self.isPaymentInitiated = false
                Alert.showToast("Payment failed. Please try again.")
            }
        }
    }

    // MARK: - Confirm + Navigate

    private func confirmPaymentAndNavigate() {
        guard let bookingId else {
            isPaymentInitiated = false
            Alert.showToast("Missing booking information.")
            return
        }

        Loader.show()

        paymentService.confirmPaymentSuccess(
            paymentHistoryId: stripePaymentHistoryId,
            bookingId: bookingId
        ) { [weak self] isSuccess, errMsg in
            DispatchQueue.main.async {
                Loader.hide()
                guard let self else { return }
                self.isPaymentInitiated = false

                if isSuccess {
                    Navigate.to.ticketConfirmationVC(
                        self,
                        booking: nil,
                        bookingId: bookingId,
                        type: .singleTickedEvent
                    )
                } else {
                    Alert.showToast(errMsg ?? "Payment confirmation failed")
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension OrderListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView === ticketTableView ? selectedTickets.count : feesAndTaxes.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        if tableView === ticketTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: OrderItemTableViewCell.identifier,
                for: indexPath
            ) as? OrderItemTableViewCell else { return UITableViewCell() }

            let ticket = selectedTickets[indexPath.row]
            let quantity = ticket.selectedTicketCount ?? 0
            let price = (ticket.price ?? 0) - (ticket.extraFees ?? 0)
            let total = Double(quantity) * price

            cell.selectionStyle = .none
            cell.totalTicketCountLbl.text = "\(quantity)x"
            cell.ticketNameLbl.text = ticket.tierName
            cell.priceLbl.text = total <= 0 ? "Free" : "\(currency)\(total.decimalFormat(true))"
//            cell.extraFeesLbl.isHidden = (ticket.extraFees ?? 0) <= 0
//            if (ticket.extraFees ?? 0) > 0 {
//                cell.extraFeesLbl.text = "Incl. \(currency)\((ticket.extraFees ?? 0).decimalFormat(true)) fees"
//            }
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketItemTableViewCell.identifier,
                for: indexPath
            ) as? TicketItemTableViewCell else { return UITableViewCell() }

            let item = feesAndTaxes[indexPath.row]
            cell.titleLbl.text = item.title
            cell.amountLbl.text = "\(currency)\(item.amount.decimalFormat(true))"
            return cell
        }
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        UITableView.automaticDimension
    }
}

// MARK: - CheckoutBarDelegate

extension OrderListViewController: CheckoutBarDelegate {

    func checkoutBarDidTapButton() {
        startPaymentFlow()
    }
}
