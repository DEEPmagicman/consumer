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
//    @IBOutlet weak var promoCodeLbl: UILabel!
    @IBOutlet weak var promoCodeTitleLbl: UILabel!
    @IBOutlet weak var orderFeesAmountLbl: UILabel!
    @IBOutlet weak var orderTotalAmountLbl: UILabel!
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
    @IBOutlet weak var discountAmountLbl: UILabel!
    @IBOutlet weak var addedPromoCodeFeild: UITextField!
    @IBOutlet weak var removePromoCodeView: UIView!
    // MARK: - Data
    var selectedTickets: [EventTicket] = []
    var venueDetails: ClipVenue?
    var event: Event?
    var booking: Booking?
    var bookingId: String?
    var selectedPaymentMethod: PaymentType?
    var cardDetails: CardDetails?
    var promotionLinkId = ""
    var promotionLinkUniqueCode = ""

    // MARK: - Stripe state
    private var paymentSheet: PaymentSheet?
    private var paymentIntentClientSecret: String = ""
    private var stripePaymentHistoryId: String = ""
    private var stripeEphemeralKey: String = ""
    private var savedPaymentMethods: [PaymentMethod] = []
    private var isFreeTicket: Bool = false
    private var isPaymentInitiated = false
    private var isFreeBookingInProgress = false
    private var isCancellingTransaction = false
    private var wasInteractivePopGestureEnabled = true
    private var countdownTimer: Timer?
    private var remainingSeconds: Int = 5 * 60

    // MARK: - UI state
    private var isTermsAccepted = true
    private var isVenueMessageAccepted = true
    private var isTermsExpanded = false
    private var isVenueMessageExpanded = false
    private let collapsedLines = 2
    private var hasLaidOutTerms = false
    private var fullTermsText = ""
    private var fullVenueMessageText = ""
    private let questionTableView = UITableView(frame: .zero, style: .plain)
    private var questionTableViewHeight: NSLayoutConstraint?
    private var questionContentSizeObservation: NSKeyValueObservation?
    private weak var questionSectionView: UIView?

    // MARK: - Data state
    private var feesAndTaxes: [FeeDisplayItem] = []
    private var paymentDetail: PaymentDetail?
    private var isPromoCodeApplied = false
    private var appliedPromoCode = ""
    private var eventQuestions: [Questions] = []
    private var questionAnswers: [String: Any] = [:]
    private let holdTimerView = UIView()
    private let holdTimerLabel = UILabel()
    private let titleMarqueeLabel = PremiumMarqueeLabel()

    private var currency: String {
        venueDetails?.venueSettings?.currencySymbol ?? "$"
    }
    
    private var currencyPosition: String? {
        venueDetails?.venueSettings?.currencyPosition
    }

    private let posterHeaderView = EventPosterHeaderView()
    private let paymentService = PaymentService()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSavedPaymentMethods()
        setupTableViews()
        setupTitleMarqueeLabel()
        setupHeaderData()
        calculateTotal()
        setupTermsText()
        setupHoldTimerView()
        applyWhiteLabelTheme()
        startCountdown()
        fetchPaymentIntentAndSetup(promoCode: "")
        fetchEventQuestions()
        getBooking(id: bookingId)
        ticketTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        feesAndTaxesTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        applyPromoBtn.indicator = MaterialLoadingIndicator(color: .black)
        applyWhiteLabelTheme()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasLaidOutTerms, termsAndConditionsLbl.frame.width > 0 else { return }
        hasLaidOutTerms = true
        updateAgreementLabels()
        setupPosterBackground()
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
        ticketTableView.removeObserver(self, forKeyPath: "contentSize")
        feesAndTaxesTableView.removeObserver(self, forKeyPath: "contentSize")
        questionContentSizeObservation?.invalidate()
        countdownTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupUI() {
        yourOrderView.applyAutoBorderBackground()
//        yourOrderView.backgroundColor = UIColor(red: 0.176, green: 0.176, blue: 0.165, alpha: 0.95)
//        yourOrderView.layer.cornerRadius = 16
//        yourOrderView.layer.masksToBounds = true
//        feesAndTaxesParentView.applyAutoBorderBackground()
        view.applyScreenBgGradient()
        addPromoCodeView.isHidden = true
        promoCodeAppliedView.isHidden = true
        promoCodeTitleView.isHidden = false
        feesAndTaxesHiddenView.isHidden = true
        updateFeesAndTaxesVisibility()

        paymentTypeView.isHidden = true
        paymentTypeView.isUserInteractionEnabled = false
        updatePaymentMethodUI()
        configureQuestionSection()

        checkOutView.delegate = self
        applyWhiteLabelTheme()
    }

    private var whiteLabelAccentColor: UIColor {
        UIColor(hex: Event.normalizedHexColor(event?.whiteLabelColor))
    }

    private func applyWhiteLabelTheme() {
        let color = whiteLabelAccentColor

        dateandtimeLbl.textColor = color
        checkOutView.applyAccentColor(color)
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
        ticketTableView.register(
            UINib(nibName: OrderItemTableViewCell.identifier, bundle: nil),
            forCellReuseIdentifier: OrderItemTableViewCell.identifier
        )
        feesAndTaxesTableView.register(
            UINib(nibName: TicketItemTableViewCell.identifier, bundle: nil),
            forCellReuseIdentifier: TicketItemTableViewCell.identifier
        )
        questionTableView.register(
            OrderQuestionTableViewCell.self,
            forCellReuseIdentifier: OrderQuestionTableViewCell.identifier
        )

        feesAndTaxesTableView.tableHeaderView = nil
        feesAndTaxesTableView.tableFooterView = nil
        questionTableView.tableHeaderView = nil
        questionTableView.tableFooterView = nil
        ticketTableView.separatorStyle = .none
        feesAndTaxesTableView.separatorStyle = .none
        questionTableView.separatorStyle = .none
        ticketTableView.showsVerticalScrollIndicator = false
        feesAndTaxesTableView.showsVerticalScrollIndicator = false
        questionTableView.showsVerticalScrollIndicator = false
        questionTableView.isScrollEnabled = false
        questionTableView.backgroundColor = .clear
        ticketTableView.rowHeight = UITableView.automaticDimension
        ticketTableView.estimatedRowHeight = 44
        feesAndTaxesTableView.rowHeight = UITableView.automaticDimension
        feesAndTaxesTableView.estimatedRowHeight = 30
        questionTableView.rowHeight = UITableView.automaticDimension
        questionTableView.estimatedRowHeight = 132

        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        feesAndTaxesTableView.delegate = self
        feesAndTaxesTableView.dataSource = self
        questionTableView.delegate = self
        questionTableView.dataSource = self
    }

    private func configureQuestionSection() {
        guard questionSectionView == nil,
              let contentStack = yourOrderView.superview as? UIStackView else { return }

        let sectionView = UIView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.backgroundColor = UIColor(hex: "#000000", alpha: 0.25)
        sectionView.layer.cornerRadius = 16
        sectionView.layer.borderWidth = 1
        sectionView.layer.borderColor = UIColor(hex: "#FFFFFF", alpha: 0.12).cgColor
        sectionView.clipsToBounds = true
        sectionView.isHidden = true

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Additional Information"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistSemiBold(size: 18)

        questionTableView.translatesAutoresizingMaskIntoConstraints = false

        sectionView.addSubview(titleLabel)
        sectionView.addSubview(questionTableView)

        let height = questionTableView.heightAnchor.constraint(equalToConstant: 1)
        questionTableViewHeight = height

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -18),

            questionTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            questionTableView.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 10),
            questionTableView.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -10),
            questionTableView.bottomAnchor.constraint(equalTo: sectionView.bottomAnchor, constant: -12),
            height
        ])

        let insertIndex: Int
        if let paymentIndex = contentStack.arrangedSubviews.firstIndex(of: paymentTypeView) {
            insertIndex = paymentIndex + 1
        } else if let termsIndex = contentStack.arrangedSubviews.firstIndex(of: termsAndConditions) {
            insertIndex = termsIndex
        } else {
            insertIndex = contentStack.arrangedSubviews.count
        }

        contentStack.insertArrangedSubview(sectionView, at: insertIndex)
        questionSectionView = sectionView

        questionContentSizeObservation = questionTableView.observe(\.contentSize, options: [.new]) { [weak self] tableView, _ in
            self?.questionTableViewHeight?.constant = max(1, tableView.contentSize.height)
            self?.view.layoutIfNeeded()
        }
    }

    private func setupHoldTimerView() {
        guard holdTimerView.superview == nil,
              let contentStack = yourOrderView.superview as? UIStackView else { return }

        holdTimerView.translatesAutoresizingMaskIntoConstraints = false
        holdTimerView.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        holdTimerView.layer.cornerRadius = 16
        holdTimerView.layer.cornerCurve = .continuous
        holdTimerView.layer.borderWidth = 1
        holdTimerView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        holdTimerView.clipsToBounds = true
        holdTimerView.setContentHuggingPriority(.required, for: .vertical)
        holdTimerView.setContentCompressionResistancePriority(.required, for: .vertical)

        holdTimerLabel.translatesAutoresizingMaskIntoConstraints = false
        holdTimerLabel.textColor = AppColor.primaryWhiteColor
        holdTimerLabel.font = Constant.Font.geistMedium(size: 14)
        holdTimerLabel.textAlignment = .center
        holdTimerLabel.numberOfLines = 1
        holdTimerLabel.setContentHuggingPriority(.required, for: .vertical)
        holdTimerLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        holdTimerView.addSubview(holdTimerLabel)
        NSLayoutConstraint.activate([
            holdTimerLabel.topAnchor.constraint(equalTo: holdTimerView.topAnchor, constant: 12),
            holdTimerLabel.leadingAnchor.constraint(equalTo: holdTimerView.leadingAnchor, constant: 16),
            holdTimerLabel.trailingAnchor.constraint(equalTo: holdTimerView.trailingAnchor, constant: -16),
            holdTimerLabel.bottomAnchor.constraint(equalTo: holdTimerView.bottomAnchor, constant: -12),
            holdTimerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])

        if let orderIndex = contentStack.arrangedSubviews.firstIndex(of: yourOrderView) {
            contentStack.insertArrangedSubview(holdTimerView, at: orderIndex)
        } else {
            contentStack.insertArrangedSubview(holdTimerView, at: 0)
        }

        updateTimerLabel()
    }

    private func startCountdown() {
        countdownTimer?.invalidate()
        updateTimerLabel()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            self.remainingSeconds -= 1

            if self.remainingSeconds <= 0 {
                timer.invalidate()
                self.remainingSeconds = 0
                self.updateTimerLabel()
                self.timerExpired()
            } else {
                self.updateTimerLabel()
            }
        }
    }

    private func updateTimerLabel() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        holdTimerLabel.text = "Tickets held for \(minutes) mins \(seconds) secs"
    }

    private func timerExpired() {
        guard !isCancellingTransaction else { return }

        let okAction = UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
            self?.cancelBookingAndReturnToEventDetails()
        }

        Alert.showAlertSheet(
            style: .alert,
            title: "Sorry, your ticket reservation has expired, please try again",
            message: "",
            actions: [okAction]
        )
    }

    private func setupPosterBackground() {
        posterHeaderView.applyBackgroundStyle(.softColorWash)
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
        venueName.text = event?.displayVenueName.uppercased()
        setHeaderTitle(event?.title)

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

        configureAgreementText()
        applyWhiteLabelTheme()
    }

    private func setupTitleMarqueeLabel() {
        guard let headerView = eventNameLbl.superview else { return }

        let titleHeight = ceil(eventNameLbl.font?.lineHeight ?? 22)
        titleMarqueeLabel.font = eventNameLbl.font ?? titleMarqueeLabel.font
        titleMarqueeLabel.textColor = eventNameLbl.textColor
        titleMarqueeLabel.animationDelay = 1.2
        titleMarqueeLabel.animationSpeed = 25
        titleMarqueeLabel.translatesAutoresizingMaskIntoConstraints = false

        eventNameLbl.removeFromSuperview()
        headerView.addSubview(titleMarqueeLabel)

        NSLayoutConstraint.activate([
            titleMarqueeLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 13),
            titleMarqueeLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 76),
            titleMarqueeLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -76),
            titleMarqueeLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleMarqueeLabel.heightAnchor.constraint(equalToConstant: titleHeight),

            venueName.topAnchor.constraint(equalTo: titleMarqueeLabel.bottomAnchor, constant: 8)
        ])
    }

    private func setHeaderTitle(_ title: String?) {
        titleMarqueeLabel.setText(title)
    }

    // MARK: - Terms & Conditions

    private func setupTermsText() {
        AgreementTextFormatter.configure(termsAndConditionsLbl)
        AgreementTextFormatter.configure(venueMessageLbl)

        let termsTap = UITapGestureRecognizer(target: self, action: #selector(onTapTermsLabel))
        termsAndConditionsLbl.addGestureRecognizer(termsTap)

        let venueMessageTap = UITapGestureRecognizer(target: self, action: #selector(onTapVenueMessageLabel))
        venueMessageLbl.addGestureRecognizer(venueMessageTap)

        updateAgreementLabels()
        updateTermsCheckboxUI()
        updateVenueCheckboxUI()
    }

    private func configureAgreementText() {
        let settings = venueDetails?.venueSettings ?? event?.venue?.venueSettings
        let policyText = cleanAgreementText(settings?.policyText ?? "")
        let emailPolicyText = cleanAgreementText(settings?.emailPolicyText ?? "")

        fullTermsText = emailPolicyText
        fullVenueMessageText = policyText
        termsAndConditions.isHidden = fullTermsText.isEmpty
        venueMessageView.isHidden = settings?.optedPolicy != true || fullVenueMessageText.isEmpty
        updateAgreementLabels()
    }

    private func cleanAgreementText(_ text: String) -> String {
        AgreementTextFormatter.clean(text)
    }

    private func updateAgreementLabels() {
        updateAgreementLabel(termsAndConditionsLbl, text: fullTermsText, isExpanded: isTermsExpanded)
        updateAgreementLabel(venueMessageLbl, text: fullVenueMessageText, isExpanded: isVenueMessageExpanded)
    }

    private func updateAgreementLabel(_ label: UILabel, text: String, isExpanded: Bool) {
        guard !text.isEmpty else {
            label.attributedText = nil
            label.text = ""
            label.numberOfLines = 0
            return
        }

        _ = AgreementTextFormatter.apply(
            to: label,
            text: text,
            isExpanded: isExpanded,
            widthFallback: view.bounds.width - 64
        )
    }

    @objc private func onTapTermsLabel(_ gesture: UITapGestureRecognizer) {
        toggleAgreementIfNeeded(
            gesture: gesture,
            label: termsAndConditionsLbl,
            expanded: isTermsExpanded
        ) { [weak self] in
            self?.isTermsExpanded.toggle()
        }
    }

    @objc private func onTapVenueMessageLabel(_ gesture: UITapGestureRecognizer) {
        toggleAgreementIfNeeded(
            gesture: gesture,
            label: venueMessageLbl,
            expanded: isVenueMessageExpanded
        ) { [weak self] in
            self?.isVenueMessageExpanded.toggle()
        }
    }

    private func toggleAgreementIfNeeded(
        gesture: UITapGestureRecognizer,
        label: UILabel,
        expanded: Bool,
        toggle: () -> Void
    ) {
        let range = AgreementTextFormatter.toggleRange(in: label, isExpanded: expanded)
        guard range.location != NSNotFound else { return }
        let tappedToggle = gesture.didTapAttributedTextInLabel(label: label, inRange: range)
        guard tappedToggle || label.bounds.contains(gesture.location(in: label)) else { return }
        toggle()
        UIView.performWithoutAnimation {
            updateAgreementLabels()
            label.superview?.layoutIfNeeded()
            yourOrderView.superview?.layoutIfNeeded()
        }
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

    private var selectedTicketsSubtotal: Double {
        selectedTickets.reduce(0.0) {
            $0 + (Double($1.selectedTicketCount ?? 0) * ($1.price ?? 0))
        }
    }

    private func calculateTotal() {
        let subtotal = selectedTicketsSubtotal
        let totalTickets = selectedTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        isFreeTicket = subtotal <= 0
        updateOrderSummaryAmounts(total: subtotal, fees: 0)
        checkOutView.updateSummary(currency: currency, currencyPosition: currencyPosition, count: totalTickets, subtotal: subtotal, fees: 0)
        checkOutView.setButtonTitle("Purchase Tickets")
        updateFreeTicketUI()
    }

    private func updateOrderSummaryAmounts(total: Double, fees: Double) {
        orderFeesAmountLbl.text = CurrencyFormatter.amount(fees, symbol: currency, position: currencyPosition)
        orderTotalAmountLbl.text = total <= 0 ? "Free" : "\(CurrencyFormatter.amount(total, symbol: currency, position: currencyPosition))"
    }

    private func updateFeesAndTaxesVisibility() {
        let shouldHide = feesAndTaxes.isEmpty
        feesAndTaxesStackView.isHidden = shouldHide

        if shouldHide {
            feesAndTaxesHiddenView.isHidden = true
            feesAndTaxesHiddenView.alpha = 0
            feesAndTaxesHiddenView.transform = .identity
            feesDropDowenIc.transform = .identity
            feesAndTaxesTableViewHeight.constant = 0
        }
    }

    private func updateFreeTicketUI() {
        paymentTypeView.isHidden = true
        paymentTypeView.isUserInteractionEnabled = !isFreeTicket && paymentSheet != nil

        guard isFreeTicket else {
            updatePromoCodeUI()
            return
        }

        guard !isPromoCodeApplied else {
            updatePromoCodeUI()
            return
        }

        promoCodeTitleView.isHidden = true
        promoCodeStackView.isHidden = true
        addPromoCodeView.isHidden = true
        promoCodeAppliedView.isHidden = true
        removePromoCodeView.isHidden = true
        addCodeTextFeild.text = ""
        addedPromoCodeFeild.text = ""
        promoCodeTitleLbl.text = ""
        discountAmountLbl.text = ""
        addCodeTextFeild.isUserInteractionEnabled = false
        addCodeTextFeild.alpha = 1
        pluseBtn.setImage(UIImage(named: "plusIcon"), for: .normal)
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
        AppHaptic.selectionChanged()
        updateTermsCheckboxUI()
    }

    @IBAction func onClickVenueMessageBtn(_ sender: UIButton) {
        isVenueMessageAccepted.toggle()
        AppHaptic.selectionChanged()
        updateVenueCheckboxUI()
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        showCancelTransactionPrompt()
    }

    @IBAction func onClickApplyBtn(_ sender: Any) {
        guard !isFreeTicket else { return }
        let promo = (addCodeTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !promo.isEmpty else {
            AppHaptic.warning()
            return
        }
        AppHaptic.primaryAction()
        applyPromoBtn.showLoader(userInteraction: false)
        fetchPaymentIntentAndSetup(promoCode: promo)
    }

    @IBAction func onClickPluseBtn(_ sender: Any) {
        guard !isFreeTicket else { return }
        AppHaptic.selectionChanged()
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
        AppHaptic.destructive()
        isPromoCodeApplied = false
        appliedPromoCode = ""
        addCodeTextFeild.text = ""
        addCodeTextFeild.isUserInteractionEnabled = true
        addCodeTextFeild.alpha = 1
        updatePromoCodeUI()
        fetchPaymentIntentAndSetup(promoCode: "")
    }

    @IBAction func onClickFeesAndTaxesView(_ sender: Any) {
        guard !feesAndTaxes.isEmpty else { return }

        AppHaptic.selectionChanged()
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
        guard !isFreeTicket else { return }
        AppHaptic.primaryAction()
        startPaymentFlow()
    }

    // MARK: - Booking

    private func getBooking(id: String?) {
        guard let id else { return }
        paymentService.fetchBookingDetail(bookingId: id) { [weak self] isSuccess, _, booking in
            guard let self else { return }
            if isSuccess {
                self.booking = booking
            }
        }
    }

    private func showCancelTransactionPrompt() {
        guard !isPaymentInitiated, !isCancellingTransaction else { return }
        presentTransactionCancelConfirmation { [weak self] in
            self?.cancelBookingAndReturnToEventDetails()
        }
    }

    private func handlePaymentCanceled() {
        isPaymentInitiated = false
        AppHaptic.warning()
        Alert.showToast("Payment canceled.")
    }

    private func cancelBookingAndReturnToEventDetails() {
        guard !isCancellingTransaction else { return }
        isCancellingTransaction = true
        countdownTimer?.invalidate()

        guard let bookingId, !bookingId.isEmpty else {
            isCancellingTransaction = false
            notifyEventDetailsTransactionCanceled()
            returnToEventDetails(animated: false)
            return
        }

        paymentService.cancelBooking(bookingId: bookingId) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isCancellingTransaction = false
                self.notifyEventDetailsTransactionCanceled()
                self.returnToEventDetails(animated: false)
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
                    AppHaptic.error()
                    Alert.showToast(errMsg ?? "Something went wrong")
                    return
                }

                if !promoCode.isEmpty {
                    AppHaptic.success()
                }

                self.isFreeTicket              = isFreeTicket || (paymentDetail?.total ?? 0) <= 0
                let payableTotal = paymentDetail?.total ?? self.selectedTicketsSubtotal
                self.isFreeTicket              = payableTotal <= 0
                self.stripePaymentHistoryId    = paymentHistoryId
                self.paymentIntentClientSecret = clientSecret ?? ""
                self.stripeEphemeralKey        = ephemeralKey
                self.paymentDetail             = paymentDetail
                if self.isFreeTicket {
                    self.paymentSheet = nil
                    self.selectedPaymentMethod = nil
                    self.cardDetails = nil
                }

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
                if !self.isFreeTicket, let secret = clientSecret, !secret.isEmpty {
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
        guard let detail else {
            feesAndTaxes = []
            feesAndTaxesHiddenView.isHidden = true
            feesAndTaxesTableView.reloadData()
            updateFeesAndTaxesVisibility()
            updateFreeTicketUI()
            return
        }

        feesAndTaxes = buildFeesArray(from: detail)
        feesAndTaxesTableView.reloadData()
        updateFeesAndTaxesVisibility()

        let totalTickets = selectedTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        let feesAmount = feesAndTaxes.reduce(0) { $0 + $1.amount }
        updateOrderSummaryAmounts(total: detail.total, fees: feesAmount)
        checkOutView.updateSummary(
            currency: currency,
            currencyPosition: currencyPosition,
            count: totalTickets,
            subtotal: detail.total,
            fees: feesAmount
        )
        updateFreeTicketUI()

//        DispatchQueue.main.async {
//            self.tableViewHeight.constant = self.ticketTableView.contentSize.height
//            self.feesAndTaxesTableViewHeight.constant = self.feesAndTaxesTableView.contentSize.height
//        }
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
        guard !isFreeTicket || isPromoCodeApplied else {
            updateFreeTicketUI()
            return
        }

        promoCodeTitleView.isHidden = false
        promoCodeAppliedView.isHidden = !isPromoCodeApplied
        promoCodeStackView.isHidden = isPromoCodeApplied
        removePromoCodeView.isHidden = !isPromoCodeApplied
        if isPromoCodeApplied {
            addedPromoCodeFeild.text = appliedPromoCode.isEmpty ? addCodeTextFeild.text : appliedPromoCode
            addCodeTextFeild.isUserInteractionEnabled = false
            let discount = paymentDetail?.discount ?? 0
            promoCodeTitleLbl.text = "Discount Applied"
            discountAmountLbl.text = "-\(CurrencyFormatter.amount(discount, symbol: currency, position: currencyPosition))"
        } else {
            promoCodeTitleLbl.text = ""
            discountAmountLbl.text = ""
            addCodeTextFeild.text = ""
            addCodeTextFeild.isUserInteractionEnabled = true
            addCodeTextFeild.alpha = 1
        }
    }

    // MARK: - Event Questions

    private func fetchEventQuestions() {
        guard let eventUniqueId = event?.uniqueId, !eventUniqueId.isEmpty else {
            updateQuestionSectionVisibility()
            return
        }

        PaymentPresenter.getEventBookingQuestion(eventUniqueId: eventUniqueId) { [weak self] isSuccess, _, questions in
            DispatchQueue.main.async {
                guard let self else { return }
                if isSuccess {
                    self.eventQuestions = (questions ?? [])
                        .filter { !$0.isDeleted }
                        .sorted { $0.order < $1.order }
                } else {
                    self.eventQuestions = []
                }

                self.questionAnswers = self.questionAnswers.filter { answer in
                    self.eventQuestions.contains { $0.id == answer.key }
                }
                self.questionTableView.reloadData()
                self.updateQuestionSectionVisibility()
            }
        }
    }

    private func updateQuestionSectionVisibility() {
        questionSectionView?.isHidden = eventQuestions.isEmpty
        questionTableViewHeight?.constant = eventQuestions.isEmpty ? 1 : max(1, questionTableView.contentSize.height)
        view.layoutIfNeeded()
    }

    private func validateQuestionAnswers() -> Bool {
        guard let invalidQuestion = eventQuestions.first(where: { question in
            guard !question.isOptional else { return false }
            return !hasValidAnswer(for: question)
        }) else { return true }

        showRequiredQuestionAlert(for: invalidQuestion)
        return false
    }

    private func showRequiredQuestionAlert(for question: Questions) {
        let action = UIAlertAction(title: "Answer Now", style: .default) { [weak self] _ in
            self?.scrollToQuestion(question)
        }

        Alert.showAlertSheet(
            style: .alert,
            title: "Additional information required",
            message: "Please answer: \(question.question)",
            actions: [action]
        )
    }

    private func scrollToQuestion(_ question: Questions) {
        guard let row = eventQuestions.firstIndex(where: { $0.id == question.id }) else { return }
        let indexPath = IndexPath(row: row, section: 0)
        questionTableView.scrollToRow(at: indexPath, at: .middle, animated: true)

        guard question.questionType == "TEXT" else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self,
                  let cell = self.questionTableView.cellForRow(at: indexPath) as? OrderQuestionTableViewCell
            else { return }

            cell.focusAnswerField()
        }
    }

    private func hasValidAnswer(for question: Questions) -> Bool {
        let answer = questionAnswers[question.id]

        switch question.questionType {
        case "MULTI_SELECT":
            return !(answer as? [String] ?? []).isEmpty
        case "SINGLE_SELECT", "TEXT":
            return !((answer as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        case "CHECKBOX":
            return answer as? Bool == true
        default:
            return true
        }
    }

    private func submitQuestionAnswersIfNeeded(completion: @escaping (Bool) -> Void) {
        guard !eventQuestions.isEmpty else {
            completion(true)
            return
        }

        guard validateQuestionAnswers() else {
            completion(false)
            return
        }

        guard let eventUniqueId = event?.uniqueId, !eventUniqueId.isEmpty, let bookingId else {
            Alert.showToast("Missing booking information.")
            completion(false)
            return
        }

        let answers: [Any] = questionAnswers.map {
            ["eventQuestionId": $0.key, "answer": $0.value] as [String: Any]
        }

        PaymentPresenter.postEventBookingQueAns(
            eventUniqueId: eventUniqueId,
            answers: answers,
            bookingId: bookingId
        ) { isSuccess, errMsg in
            DispatchQueue.main.async {
                if isSuccess {
                    completion(true)
                } else {
                    Alert.showToast(errMsg ?? "Unable to save additional information")
                    completion(false)
                }
            }
        }
    }

    // MARK: - Stripe Checkout

    private func startPaymentFlow() {
        guard !isCancellingTransaction else { return }

        if isFreeTicket {
            guard !isFreeBookingInProgress else { return }
            // A stale Stripe state must not block redemption of a free ticket.
            isPaymentInitiated = false
        } else {
            guard !isPaymentInitiated else { return }
        }

        guard isTermsAccepted || termsAndConditions.isHidden else {
            Alert.showToast("Please accept the terms and conditions")
            return
        }

        if !venueMessageView.isHidden && !isVenueMessageAccepted {
            Alert.showToast("Please accept the venue message")
            return
        }

        guard validateQuestionAnswers() else { return }

        isPaymentInitiated = true
        showPurchaseLoading()
        submitQuestionAnswersIfNeeded { [weak self] isSubmitted in
            guard let self else { return }
            guard isSubmitted else {
                self.isPaymentInitiated = false
                self.hidePurchaseLoading()
                return
            }
            self.continuePaymentFlow()
        }
    }

    private func continuePaymentFlow() {
        if isFreeTicket {
            createFreeEventBookingAndNavigate()
            return
        }

        guard let paymentSheet else {
            isPaymentInitiated = false
            hidePurchaseLoading()
            AppHaptic.warning()
            Alert.showToast("Payment not ready yet. Please wait.")
            return
        }

        paymentSheet.present(from: self) { [weak self] result in
            guard let self else { return }

            switch result {
            case .completed:
                self.confirmPaymentAndNavigate()
            case .canceled:
                self.hidePurchaseLoading()
                self.handlePaymentCanceled()
            case .failed:
                self.isPaymentInitiated = false
                self.hidePurchaseLoading()
                AppHaptic.error()
                Alert.showToast("Payment failed. Please try again.")
            }
        }
    }

    // MARK: - Confirm + Navigate

    private func createFreeEventBookingAndNavigate() {
        guard let eventId = event?.id else {
            isPaymentInitiated = false
            hidePurchaseLoading()
            Alert.showToast("Missing event information.")
            return
        }

        guard let user = UserDefault.shared.user else {
            isPaymentInitiated = false
            hidePurchaseLoading()
            Alert.showToast("Missing user information.")
            return
        }

        guard !isFreeBookingInProgress else { return }
        isFreeBookingInProgress = true

        let tickets = selectedTickets.map {
            [
                "ticketId": $0.id ?? "",
                "ticketQuantity": $0.selectedTicketCount ?? 0,
                "ticketPrice": $0.price ?? 0
            ] as [String: Any]
        }

        paymentService.checkEventTicketStock(
            eventId: eventId,
            code: user.code,
            phone: user.phone,
            gender: user.gender,
            userId: user.id,
            tickets: tickets
        ) { [weak self] isAvailable, errMsg in
            DispatchQueue.main.async {
                guard let self else { return }

                guard isAvailable else {
                    self.hidePurchaseLoading()
                    self.isPaymentInitiated = false
                    self.isFreeBookingInProgress = false
                    Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                    return
                }

                self.createCheckedFreeEventBooking(
                    eventId: eventId,
                    user: user,
                    tickets: tickets
                )
            }
        }
    }

    private func createCheckedFreeEventBooking(
        eventId: String,
        user: User,
        tickets: [[String: Any]]
    ) {

        paymentService.createEventFreeBooking(
            eventId: eventId,
            phone: user.phone,
            userId: user.id,
            tickets: tickets,
            bookingId: bookingId,
            promotionLinkId: promotionLinkId,
            promotionLinkUniqueCode: promotionLinkUniqueCode
        ) { [weak self] isSuccess, errMsg, freeBookingId, message in
            DispatchQueue.main.async {
                guard let self else { return }
                self.hidePurchaseLoading()
                self.isPaymentInitiated = false
                self.isFreeBookingInProgress = false

                guard isSuccess else {
                    AppHaptic.error()
                    Alert.showToast(message ?? errMsg ?? "Unable to redeem tickets")
                    return
                }

                AppHaptic.success()
                self.countdownTimer?.invalidate()
                NotificationCenter.default.postOrdersRefresh(.tickets)
                Navigate.to.showQRCode(
                    self,
                    booking: nil,
                    bookingId: freeBookingId ?? self.bookingId ?? "",
                    type: .singleTickedEvent,
                    sourceEvent: self.event,
                    presentationMode: .pushedFromPurchase
                )
            }
        }
    }

    private func confirmPaymentAndNavigate() {
        guard let bookingId else {
            isPaymentInitiated = false
            hidePurchaseLoading()
            AppHaptic.error()
            Alert.showToast("Missing booking information.")
            return
        }

        showPurchaseLoading()

        let optedPolicy = venueMessageView.isHidden ? nil : isVenueMessageAccepted
        paymentService.confirmPaymentSuccess(
            paymentHistoryId: stripePaymentHistoryId,
            bookingId: bookingId,
            optedPolicy: optedPolicy
        ) { [weak self] isSuccess, errMsg in
            DispatchQueue.main.async {
                self?.hidePurchaseLoading()
                guard let self else { return }
                self.isPaymentInitiated = false

                if isSuccess {
                    AppHaptic.success()
                    self.countdownTimer?.invalidate()
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
                    AppHaptic.error()
                    Alert.showToast(errMsg ?? "Payment confirmation failed")
                }
            }
        }
    }

    private func showPurchaseLoading() {
        checkOutView.isUserInteractionEnabled = false
        checkOutView.showLoader()
    }

    private func hidePurchaseLoading() {
        checkOutView.hideLoader()
        checkOutView.isUserInteractionEnabled = true
    }

}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension OrderListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === ticketTableView {
            return selectedTickets.count
        } else if tableView === questionTableView {
            return eventQuestions.count
        } else {
            return feesAndTaxes.count
        }
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        if tableView === ticketTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: OrderItemTableViewCell.identifier
            ) as? OrderItemTableViewCell else { return UITableViewCell() }

            let ticket = selectedTickets[indexPath.row]
            let quantity = ticket.selectedTicketCount ?? 0
            let price = (ticket.price ?? 0) - (ticket.extraFees ?? 0)
            let total = Double(quantity) * price

            cell.selectionStyle = .none
            cell.totalTicketCountLbl.text = "\(quantity)x"
            cell.ticketNameLbl.text = ticket.tierName
            cell.priceLbl.text = total <= 0 ? "Free" : "\(CurrencyFormatter.amount(total, symbol: currency, position: currencyPosition))"
//            cell.extraFeesLbl.isHidden = (ticket.extraFees ?? 0) <= 0
//            if (ticket.extraFees ?? 0) > 0 {
//                cell.extraFeesLbl.text = "Incl. \(currency)\((ticket.extraFees ?? 0).decimalFormat(true)) fees"
//            }
            return cell

        } else if tableView === questionTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: OrderQuestionTableViewCell.identifier
            ) as? OrderQuestionTableViewCell else { return UITableViewCell() }

            let question = eventQuestions[indexPath.row]
            cell.configure(
                question: question,
                answer: questionAnswers[question.id],
                delegate: self
            )
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketItemTableViewCell.identifier
            ) as? TicketItemTableViewCell else { return UITableViewCell() }

            let item = feesAndTaxes[indexPath.row]
            cell.titleLbl.text = item.title
            cell.amountLbl.text = CurrencyFormatter.amount(item.amount, symbol: currency, position: currencyPosition)
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

// MARK: - OrderQuestionTableViewCellDelegate

extension OrderListViewController: OrderQuestionTableViewCellDelegate {

    func orderQuestionCell(_ cell: OrderQuestionTableViewCell, didUpdate answer: Any, for question: Questions) {
        questionAnswers[question.id] = answer
    }
}

// MARK: - CheckoutBarDelegate

extension OrderListViewController: CheckoutBarDelegate {

    func checkoutBarDidTapButton() {
        AppHaptic.primaryAction()
        startPaymentFlow()
    }
}

// MARK: - OrderQuestionTableViewCell

protocol OrderQuestionTableViewCellDelegate: AnyObject {
    func orderQuestionCell(_ cell: OrderQuestionTableViewCell, didUpdate answer: Any, for question: Questions)
}

final class OrderQuestionTableViewCell: UITableViewCell, UITextFieldDelegate {

    private weak var delegate: OrderQuestionTableViewCellDelegate?
    private var question: Questions?
    private var currentAnswer: Any?
    private var optionButtons: [UIButton] = []

    private let mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let questionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.white.withAlphaComponent(0.92)
        label.font = Constant.Font.geistMedium(size: 14)
        return label
    }()

    private let textFieldContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        return view
    }()

    private let textField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.textColor = .white
        field.tintColor = .white
        field.font = Constant.Font.geistMedium(size: 14)
        field.attributedPlaceholder = NSAttributedString(
            string: "Enter answer",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.45)]
        )
        return field
    }()

    private let optionStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    private let checkboxRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 10
        return stack
    }()

    private let checkboxButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let checkboxQuestionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.white.withAlphaComponent(0.92)
        label.font = Constant.Font.geistMedium(size: 14)
        return label
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        question = nil
        currentAnswer = nil
        delegate = nil
        optionButtons.removeAll()
        optionStack.arrangedSubviews.forEach {
            optionStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        textField.text = nil
        updateTextFieldFocus(isFocused: false)
    }

    func configure(question: Questions, answer: Any?, delegate: OrderQuestionTableViewCellDelegate?) {
        self.question = question
        self.currentAnswer = answer
        self.delegate = delegate

        let title = "\(question.question)\(question.isOptional ? "" : " *")"
        questionLabel.text = title
        checkboxQuestionLabel.text = title

        questionLabel.isHidden = question.questionType == "CHECKBOX"
        textFieldContainer.isHidden = question.questionType != "TEXT"
        optionStack.isHidden = !(question.questionType == "SINGLE_SELECT" || question.questionType == "MULTI_SELECT")
        checkboxRow.isHidden = question.questionType != "CHECKBOX"

        textField.text = answer as? String
        updateTextFieldFocus(isFocused: textField.isFirstResponder)
        configureOptions(question.eventQuestionHasOption?.filter { !$0.isDeleted }.map { $0.option } ?? [])
        updateCheckboxState()
        updateOptionStates()
    }

    func focusAnswerField() {
        guard question?.questionType == "TEXT" else { return }
        textField.becomeFirstResponder()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(mainStack)
        mainStack.addArrangedSubview(questionLabel)
        mainStack.addArrangedSubview(textFieldContainer)
        mainStack.addArrangedSubview(optionStack)
        mainStack.addArrangedSubview(checkboxRow)
        mainStack.addArrangedSubview(separatorView)

        textFieldContainer.addSubview(textField)
        checkboxRow.addArrangedSubview(checkboxButton)
        checkboxRow.addArrangedSubview(checkboxQuestionLabel)

        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        checkboxButton.addTarget(self, action: #selector(onTapCheckbox), for: .touchUpInside)

        let textFieldTap = UITapGestureRecognizer(target: self, action: #selector(onTapTextFieldContainer))
        textFieldContainer.addGestureRecognizer(textFieldTap)
        textFieldContainer.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            textFieldContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            textField.topAnchor.constraint(equalTo: textFieldContainer.topAnchor, constant: 4),
            textField.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor, constant: 14),
            textField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -14),
            textField.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor, constant: -4),

            checkboxButton.widthAnchor.constraint(equalToConstant: 24),
            checkboxButton.heightAnchor.constraint(equalToConstant: 24),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func updateTextFieldFocus(isFocused: Bool) {
        textFieldContainer.layer.borderColor = (isFocused
            ? UIColor.white.withAlphaComponent(0.36)
            : UIColor.white.withAlphaComponent(0.14)).cgColor
    }

    private func configureOptions(_ options: [String]) {
        optionStack.arrangedSubviews.forEach {
            optionStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        optionButtons.removeAll()

        options.enumerated().forEach { index, option in
            let button = UIButton(type: .system)
            button.tag = index
            button.contentHorizontalAlignment = .left
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.font = Constant.Font.geistMedium(size: 14)
            button.setTitle(option, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.tintColor = .white
            button.backgroundColor = UIColor.black.withAlphaComponent(0.18)
            button.layer.cornerRadius = 12
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
            button.addTarget(self, action: #selector(onTapOption(_:)), for: .touchUpInside)
            optionStack.addArrangedSubview(button)
            optionButtons.append(button)
        }
    }

    private func updateOptionStates() {
        guard let question else { return }

        optionButtons.forEach { button in
            let option = button.title(for: .normal) ?? ""
            let isSelected: Bool
            if question.questionType == "MULTI_SELECT" {
                isSelected = (currentAnswer as? [String] ?? []).contains(option)
            } else {
                isSelected = (currentAnswer as? String) == option
            }

            button.setImage(isSelected ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon, for: .normal)
            button.layer.borderColor = (isSelected
                ? UIColor(hex: "#69DC82", alpha: 0.65)
                : UIColor.white.withAlphaComponent(0.14)).cgColor
            button.setTitleColor(isSelected ? UIColor(hex: "#69DC82") : .white, for: .normal)
        }
    }

    private func updateCheckboxState() {
        let isChecked = currentAnswer as? Bool == true
        checkboxButton.setImage(isChecked ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon, for: .normal)
        checkboxQuestionLabel.textColor = isChecked ? UIColor(hex: "#69DC82") : UIColor.white.withAlphaComponent(0.92)
    }

    @objc private func textFieldChanged() {
        guard let question else { return }
        let answer = textField.text ?? ""
        currentAnswer = answer
        delegate?.orderQuestionCell(self, didUpdate: answer, for: question)
    }

    @objc private func onTapTextFieldContainer() {
        textField.becomeFirstResponder()
    }

    @objc private func onTapOption(_ sender: UIButton) {
        guard let question, let selectedOption = sender.title(for: .normal) else { return }

        AppHaptic.selectionChanged()
        if question.questionType == "MULTI_SELECT" {
            var answers = currentAnswer as? [String] ?? []
            if let index = answers.firstIndex(of: selectedOption) {
                answers.remove(at: index)
            } else {
                answers.append(selectedOption)
            }
            currentAnswer = answers
            delegate?.orderQuestionCell(self, didUpdate: answers, for: question)
        } else {
            currentAnswer = selectedOption
            delegate?.orderQuestionCell(self, didUpdate: selectedOption, for: question)
        }

        updateOptionStates()
    }

    @objc private func onTapCheckbox() {
        guard let question else { return }
        let answer = !(currentAnswer as? Bool ?? false)
        AppHaptic.selectionChanged()
        currentAnswer = answer
        updateCheckboxState()
        delegate?.orderQuestionCell(self, didUpdate: answer, for: question)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateTextFieldFocus(isFocused: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateTextFieldFocus(isFocused: false)
    }
}
