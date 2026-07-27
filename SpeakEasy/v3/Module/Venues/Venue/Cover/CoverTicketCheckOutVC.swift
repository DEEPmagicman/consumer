//
//  CoverTicketCheckOutVC.swift
//  SpeakEasy-Consumer
//

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet
import StripePayments
import MHLoadingButton
import SDWebImage

private enum FeeBreakdownSection {
    case cover
    case upsell
}

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
    var initialPaymentMethod: PaymentType?
    var initialCardDetails: CardDetails?
    var doormanId = ""
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
    private var selectedPaymentMethod: PaymentType = .applePay
    private var cardDetails: CardDetails?

    // MARK: - State
    private var isPromoCodeApplied = false
    private var appliedPromoCode = ""
    private var isFreeTicket = false
    private var isPaymentInitiated = false
    private var isCancellingTransaction = false
    private var wasInteractivePopGestureEnabled = true
    private var isFromApplePay = false
    
    private var isTermsAccepted = true
    private var isVenueMessageAccepted = true
    private var isEmailMessageAccepted = true
    private var isTermsExpanded = false
    private var isVenueMessageExpanded = false
    private var isEmailMessageExpanded = false
    private var isCoverFeesExpanded = true
    private var isUpsellFeesExpanded = true
    private var isPricingLoading = false
    private var shouldShowCheckoutButton = false
    private let coverFeeShimmerRowCount = 3
    private let upsellFeeShimmerRowCount = 1
    private var hasLaidOutTerms = false
    private var hasPlayedTicketCardEntryAnimation = false
    private var didInstallVenueAgreementRow = false
    private var loadedHeaderImageURLString: String?
    private var loadedLogoURLString: String?
    private var fullTermsText = ""
    private var fullTermsAttributedText: NSAttributedString?
    private var fullVenueMessageText = ""
    private var fullEmailMessageText = ""
    private let emailMessageBtn = UIButton(type: .custom)
    private let emailMessageLbl = UILabel()
    private lazy var emailMessageView: UIView = makeEmailAgreementRow()
    private lazy var interactionBlockerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

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
    
    private var currencyPosition: String? {
        venue?.venueSettings?.currencyPosition
    }

    private var whiteLabelAccentColor: UIColor {
        UIColor(hex: Event.normalizedHexColor(venue?.venueSettings?.whiteLabelColor))
    }

    private var hasPaidCoverSelection: Bool {
        selectedCoverTickets.contains {
            $0.price > 0 || ($0.extraFees ?? 0) > 0
        }
    }

    private var shouldUseAddOnsPaymentIntentAsPrimary: Bool {
        !selectedAddOnsItems.isEmpty &&
        (selectedCoverTickets.isEmpty || !hasPaidCoverSelection || bookingType == .FREE)
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
        setupPaymentMethodUI()
        setupCheckoutSurfaceStyle()
        setupInteractionBlocker()
        hideScrollIndicators(in: view)
        setPricingLoading(true, animated: false)

        if !selectedCoverTickets.isEmpty && hasPaidCoverSelection {
            createBooking()
        } else {
            isBookingLoaded = true
            getAddOnsPaymentIntent(bookingId: "")
        }
        setupTermsText()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !hasLaidOutTerms else { return }
        hasLaidOutTerms = true
        updateAgreementLabels()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        wasInteractivePopGestureEnabled = navigationController?.interactivePopGestureRecognizer?.isEnabled ?? true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        playTicketCardEntryAnimationIfNeeded()
        WebSocketWrapper.shared.addDelegate(self) 
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = wasInteractivePopGestureEnabled
        WebSocketWrapper.shared.removeDelegate(self)
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
        tableView.register(QRTicketTableViewCell.nib,
                           forCellReuseIdentifier: QRTicketTableViewCell.identifier)
        upsellTicketTableView.register(QRTicketTableViewCell.nib,
                                       forCellReuseIdentifier: QRTicketTableViewCell.identifier)
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

        [tableView, upsellTicketTableView].forEach {
            $0?.rowHeight = UITableView.automaticDimension
            $0?.estimatedRowHeight = 92
        }
        kvoRegistered = true
        applyFeeBreakdownState(animated: false)
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
        let logoUrlString = (venue?.logo?.key ?? "").imageURL
        if loadedLogoURLString != logoUrlString {
            loadedLogoURLString = logoUrlString
            venueLogoImg.sd_setImage(
                with: URL(string: logoUrlString),
                placeholderImage: Constant.Icon.uploadImage
            )
        }

        let imageUrlString = "\(SharedURL.amazonStorage)\(venue?.venueAttachment?.first?.key ?? "")"
        if loadedHeaderImageURLString != imageUrlString {
            loadedHeaderImageURLString = imageUrlString

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
        }

        venueName.text = venue?.name ?? ""
        configureAgreementText()

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

    private func playTicketCardEntryAnimationIfNeeded() {
        guard !hasPlayedTicketCardEntryAnimation else { return }
        hasPlayedTicketCardEntryAnimation = true
        imageParentView.playEntryAnimation()
    }

    private func setupCheckoutBar() {
        checkOutBtnView.delegate = self
        setCheckoutButton(enabled: false, animated: false)
        checkOutBtnView.isHidden = true
        checkOutBtnView.alpha = 0
        checkOutBtnView.transform = CGAffineTransform(translationX: 0, y: 80)
        checkOutBtnView.setButtonTitle(initialCheckoutButtonTitle)
        checkOutBtnView.applyAccentColor(whiteLabelAccentColor)
    }

    private func setupPaymentMethodUI() {
        selectedPaymentMethod = initialPaymentMethod
            ?? (StripeAPI.deviceSupportsApplePay() ? .applePay : .card)
        cardDetails = initialCardDetails
        paymentTypeView.isHidden = true
        updatePaymentMethodUI()
    }

    private func setupCheckoutSurfaceStyle() {
        [tableView, coverTicketFeesAndTaxTableView,
         upsellTicketTableView, upsellTicketFeesAndTaxTableView].forEach {
            $0?.contentInset = .zero
            $0?.sectionHeaderHeight = 0
            $0?.sectionFooterHeight = 0
            $0?.estimatedSectionHeaderHeight = 0
            $0?.estimatedSectionFooterHeight = 0
        }

        [coverTicketParentView, upsellTicketParentView].forEach {
            $0?.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            $0?.layer.cornerRadius = 16
            $0?.layer.cornerCurve = .continuous
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        }

        paymentTypeView.isHidden = true
//        paymentTypeView.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        paymentTypeView.layer.cornerRadius = 14
        paymentTypeView.layer.cornerCurve = .continuous
        paymentTypeView.layer.borderWidth = 1
        paymentTypeView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        paymentTypeView.clipsToBounds = true
        paymentTypeView.isUserInteractionEnabled = false
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

    private func resetPaymentInteractionAfterFailure() {
        isPaymentInitiated = false
        setScreenInteractionBlocked(false)
        updateCheckoutButtonState()
    }

    private func updatePaymentMethodUI() {
        switch selectedPaymentMethod {
        case .applePay:
            paymentTypeName.text = "Apple Pay"
            paymentCardImage.image = UIImage(named: "applePayIcon")
        case .card:
            if let last4 = cardDetails?.cardNumber.suffix(4), !last4.isEmpty {
                paymentTypeName.text = "Card ending \(last4)"
            } else {
                paymentTypeName.text = "Pay with Card"
            }
            paymentCardImage.image = UIImage(named: "creditCardIcon")
        }
    }

    private func setupNotifications() {
        let pairs: [(Notification.Name, Selector)] = [
            (UIApplication.didEnterBackgroundNotification, #selector(enterBackGround)),
            (UIApplication.willEnterForegroundNotification, #selector(exitBackGround)),
            (UIApplication.willResignActiveNotification, #selector(enterBackGround)),
            (UIApplication.didBecomeActiveNotification, #selector(exitBackGround))
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

    private func updateEmailCheckboxUI() {
        let image = isEmailMessageAccepted ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon
        emailMessageBtn.setImage(image, for: .normal)
    }
    
    private func setupTermsText() {
        installVenueAgreementRowIfNeeded()
        installEmailAgreementRowIfNeeded()
        movePurchasePolicyAfterOptInsIfNeeded()
        AgreementTextFormatter.configure(termsAndConditionsLbl)
        AgreementTextFormatter.configure(venueMessageLbl)
        AgreementTextFormatter.configure(emailMessageLbl)
        termsAndConditionsBtn.isHidden = true
        termsAndConditionsBtn.isUserInteractionEnabled = false

        let termsTap = UITapGestureRecognizer(
            target: self,
            action: #selector(onTapTermsLabel)
        )
        termsAndConditionsLbl.addGestureRecognizer(termsTap)

        let venueMessageTap = UITapGestureRecognizer(
            target: self,
            action: #selector(onTapVenueMessageLabel)
        )
        venueMessageLbl.addGestureRecognizer(venueMessageTap)

        let emailMessageTap = UITapGestureRecognizer(
            target: self,
            action: #selector(onTapEmailMessageLabel)
        )
        emailMessageLbl.addGestureRecognizer(emailMessageTap)

        updateAgreementLabels()
        updateTermsCheckboxUI()
        updateVenueCheckboxUI()
        updateEmailCheckboxUI()
    }

    private func installVenueAgreementRowIfNeeded() {
        guard !didInstallVenueAgreementRow,
              let stackView = venueMessageView.superview as? UIStackView else { return }

        didInstallVenueAgreementRow = true
        let insertIndex = stackView.arrangedSubviews.firstIndex(of: venueMessageView)
            ?? stackView.arrangedSubviews.count
        let originalIsHidden = venueMessageView.isHidden

        stackView.removeArrangedSubview(venueMessageView)
        venueMessageView.removeFromSuperview()

        let venueMessageRow = makeOptInAgreementRow(
            button: venueMessageBtn,
            label: venueMessageLbl
        )
        stackView.insertArrangedSubview(venueMessageRow, at: insertIndex)
        venueMessageView = venueMessageRow
        venueMessageView.isHidden = originalIsHidden
    }

    private func installEmailAgreementRowIfNeeded() {
        guard emailMessageView.superview == nil,
              let stackView = termsAndConditions.superview as? UIStackView else { return }

        let insertIndex = stackView.arrangedSubviews.firstIndex(of: termsAndConditions)
            .map { $0 + 1 } ?? stackView.arrangedSubviews.count
        stackView.insertArrangedSubview(emailMessageView, at: insertIndex)
    }

    private func movePurchasePolicyAfterOptInsIfNeeded() {
        guard let stackView = termsAndConditions.superview as? UIStackView else { return }

        stackView.removeArrangedSubview(termsAndConditions)
        termsAndConditions.removeFromSuperview()

        let visibleOptInRows = [venueMessageView, emailMessageView].filter { !$0.isHidden }
        let anchorIndex = visibleOptInRows
            .compactMap { stackView.arrangedSubviews.firstIndex(of: $0) }
            .max()
        let insertIndex = anchorIndex.map { $0 + 1 } ?? stackView.arrangedSubviews.count
        stackView.insertArrangedSubview(termsAndConditions, at: min(insertIndex, stackView.arrangedSubviews.count))
    }

    private func makeEmailAgreementRow() -> UIView {
        emailMessageBtn.addTarget(self, action: #selector(onClickEmailMessageBtn(_:)), for: .touchUpInside)
        return makeOptInAgreementRow(
            button: emailMessageBtn,
            label: emailMessageLbl
        )
    }

    private func makeOptInAgreementRow(button: UIButton, label: UILabel) -> UIView {
        let row = UIView()
        row.backgroundColor = .clear
        row.translatesAutoresizingMaskIntoConstraints = false

        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.contentMode = .scaleAspectFit

        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping

        row.addSubview(button)
        row.addSubview(label)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            button.topAnchor.constraint(equalTo: label.topAnchor),
            button.widthAnchor.constraint(equalToConstant: 16),
            button.heightAnchor.constraint(equalToConstant: 16),

            label.topAnchor.constraint(equalTo: row.topAnchor),
            label.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            row.bottomAnchor.constraint(greaterThanOrEqualTo: button.bottomAnchor)
        ])

        return row
    }

    private func hideScrollIndicators(in rootView: UIView) {
        if let scrollView = rootView as? UIScrollView {
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
        }
        rootView.subviews.forEach { hideScrollIndicators(in: $0) }
    }

    private func configureAgreementText() {
        let settings = venue?.venueSettings
        let fallbackTermsText = "By purchasing a ticket, you confirm that you are 21 years of age or older and agree to our Terms of Service and Privacy Policy. All sales are final and non-refundable. Patrons must adhere to the partner dress code. Entry is subject to valid ticket and ID verification at entry."
        let purchasePolicyText = normalizedPurchasePolicy(settings?.purchasePolicy)
        let fallbackVenueMessageText =
            "I agree to receive marketing related text messages from \(venue?.name ?? ""). Msg & data rates may apply. Reply STOP to opt out or HELP for support."
        let fallbackEmailMessageText =
            "I agree to receive marketing related email messages from \(venue?.name ?? "the partner")."

        var venueMessageText = cleanAgreementText(settings?.policyText ?? fallbackVenueMessageText)
        if settings?.optedPolicy == true, venueMessageText.isEmpty {
            venueMessageText = cleanAgreementText(fallbackVenueMessageText)
        }

        var emailMessageText = cleanAgreementText(settings?.emailPolicyText ?? fallbackEmailMessageText)
        if settings?.optedEmailPolicy == true, emailMessageText.isEmpty {
            emailMessageText = cleanAgreementText(fallbackEmailMessageText)
        }

        fullTermsText = cleanAgreementText(purchasePolicyText?.string ?? fallbackTermsText)
        fullTermsAttributedText = purchasePolicyText
        fullVenueMessageText = venueMessageText
        fullEmailMessageText = emailMessageText
        termsAndConditions.isHidden = fullTermsText.isEmpty
        venueMessageView.isHidden = settings?.optedPolicy != true || fullVenueMessageText.isEmpty
        emailMessageView.isHidden = true
        updateAgreementLabels()
    }

    private func setPricingLoading(_ isLoading: Bool, animated: Bool) {
        isPricingLoading = isLoading
        reloadFeeTables()
        applyFeeBreakdownState(animated: animated)
    }

    private func reloadFeeTables() {
        coverTicketFeesAndTaxTableView.reloadData()
        upsellTicketFeesAndTaxTableView.reloadData()
    }

    private func cleanAgreementText(_ text: String) -> String {
        AgreementTextFormatter.clean(text)
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

    private func updateAgreementLabels() {
        updateAgreementLabel(
            termsAndConditionsLbl,
            text: fullTermsText,
            isExpanded: isTermsExpanded,
            allowsViewMore: true,
            attributedText: fullTermsAttributedText
        )
        updateAgreementLabel(
            venueMessageLbl,
            text: fullVenueMessageText,
            isExpanded: isVenueMessageExpanded,
            allowsViewMore: false
        )
        updateAgreementLabel(
            emailMessageLbl,
            text: fullEmailMessageText,
            isExpanded: isEmailMessageExpanded,
            allowsViewMore: false
        )
    }

    private func updateAgreementLabel(
        _ label: UILabel,
        text: String,
        isExpanded: Bool,
        allowsViewMore: Bool,
        attributedText: NSAttributedString? = nil
    ) {
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
            widthFallback: view.bounds.width - 64,
            allowsViewMore: allowsViewMore,
            expandedAttributedText: attributedText
        )
    }

    private func agreementToggleRange(in label: UILabel, expanded: Bool) -> NSRange {
        AgreementTextFormatter.toggleRange(in: label, isExpanded: expanded)
    }

    private func toggleAgreementIfNeeded(
        gesture: UITapGestureRecognizer,
        label: UILabel,
        expanded: Bool,
        toggle: () -> Void
    ) {
        let range = agreementToggleRange(in: label, expanded: expanded)
        guard range.location != NSNotFound else { return }
        let tappedToggle = gesture.didTapAttributedTextInLabel(label: label, inRange: range)

        // The rendered "View More" can be tight on small devices, so the whole label toggles.
        guard tappedToggle || label.bounds.contains(gesture.location(in: label)) else { return }

        toggle()
        UIView.performWithoutAnimation {
            updateAgreementLabels()
            label.superview?.layoutIfNeeded()
            label.superview?.superview?.layoutIfNeeded()
        }
    }

    private func applyFeeBreakdownState(animated: Bool) {
        let coverHasFees = !feesAndTaxes.isEmpty
        let upsellHasFees = !upsellFeesAndTaxes.isEmpty
        let coverIsLoading = isPricingLoading && !selectedCoverTickets.isEmpty
        let upsellIsLoading = isPricingLoading && !selectedAddOnsItems.isEmpty

        let coverVisible = coverIsLoading || (isCoverFeesExpanded && coverHasFees)
        let upsellVisible = upsellIsLoading || (isUpsellFeesExpanded && upsellHasFees)

        coverTicketFeesAndTaxTableView.superview?.isHidden = !coverVisible
        upsellTicketFeesAndTaxTableView.superview?.isHidden = !upsellVisible

        coverTicketFeesAndTaxTableViewHeight.constant = coverVisible
            ? feeTableHeight(
                coverTicketFeesAndTaxTableView,
                itemCount: coverIsLoading ? coverFeeShimmerRowCount : feesAndTaxes.count
            )
            : 0
        upsellTicketFeesAndTaxTableViewHeight.constant = upsellVisible
            ? feeTableHeight(
                upsellTicketFeesAndTaxTableView,
                itemCount: upsellIsLoading ? upsellFeeShimmerRowCount : upsellFeesAndTaxes.count
            )
            : 0

        let updates = { self.view.layoutIfNeeded() }
        guard animated else {
            updates()
            return
        }

        UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            updates()
        }
    }

    private func feeTableHeight(_ tableView: UITableView, itemCount: Int) -> CGFloat {
        tableView.layoutIfNeeded()
        let contentHeight = ceil(tableView.contentSize.height)
        if contentHeight > 1 { return contentHeight }
        return CGFloat(itemCount) * 44
    }

    @objc private func onCoverFeesToggle() {
        guard !isPricingLoading, !feesAndTaxes.isEmpty else { return }
        isCoverFeesExpanded.toggle()
        applyFeeBreakdownState(animated: true)
    }

    @objc private func onUpsellFeesToggle() {
        guard !isPricingLoading, !upsellFeesAndTaxes.isEmpty else { return }
        isUpsellFeesExpanded.toggle()
        applyFeeBreakdownState(animated: true)
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
                self.coverTicketFeesAndTaxTableViewHeight.constant =
                    (self.isPricingLoading && !self.selectedCoverTickets.isEmpty) || self.isCoverFeesExpanded
                    ? table.contentSize.height
                    : 0
            case self.upsellTicketTableView:
                self.upsellTicketTableViewHeight.constant = table.contentSize.height
            case self.upsellTicketFeesAndTaxTableView:
                self.upsellTicketFeesAndTaxTableViewHeight.constant =
                    (self.isPricingLoading && !self.selectedAddOnsItems.isEmpty) || self.isUpsellFeesExpanded
                    ? table.contentSize.height
                    : 0
            default:
                break
            }
            self.applyFeeBreakdownState(animated: false)
        }
    }
    
    @objc
    private func onTapTermsLabel(_ gesture: UITapGestureRecognizer) {
        toggleAgreementIfNeeded(
            gesture: gesture,
            label: termsAndConditionsLbl,
            expanded: isTermsExpanded
        ) { [weak self] in
            self?.isTermsExpanded.toggle()
        }
    }

    @objc
    private func onTapVenueMessageLabel(_ gesture: UITapGestureRecognizer) {
        toggleAgreementIfNeeded(
            gesture: gesture,
            label: venueMessageLbl,
            expanded: isVenueMessageExpanded
        ) { [weak self] in
            self?.isVenueMessageExpanded.toggle()
        }
    }

    @objc
    private func onTapEmailMessageLabel(_ gesture: UITapGestureRecognizer) {
        toggleAgreementIfNeeded(
            gesture: gesture,
            label: emailMessageLbl,
            expanded: isEmailMessageExpanded
        ) { [weak self] in
            self?.isEmailMessageExpanded.toggle()
        }
    }

    // MARK: - Actions
    @IBAction func onClickBackBtn(_ sender: Any) {
        guard !isPaymentInitiated else { return }
        showCancelTransactionPrompt()
    }
    
    @IBAction func onClickTermsBtn(_ sender: UIButton) {
        guard !isPaymentInitiated else { return }
        isTermsAccepted.toggle()
        AppHaptic.selectionChanged()
        updateTermsCheckboxUI()
    }

    @IBAction func onClickVenueMessageBtn(_ sender: UIButton) {
        guard !isPaymentInitiated else { return }
        isVenueMessageAccepted.toggle()
        AppHaptic.selectionChanged()
        updateVenueCheckboxUI()
    }

    @objc private func onClickEmailMessageBtn(_ sender: UIButton) {
        guard !isPaymentInitiated else { return }
        isEmailMessageAccepted.toggle()
        AppHaptic.selectionChanged()
        updateEmailCheckboxUI()
    }

    @IBAction func onClickPaymentTypeBtn(_ sender: Any) {
        // Payment selection is handled inline through PaymentSheet now.
    }

    @objc private func handleBackSwipe() {
        showCancelTransactionPrompt()
    }

    func onClickContinueToCheckout() {
        guard !isPaymentInitiated, !isCancellingTransaction else { return }
        AppHaptic.primaryAction()
        isPaymentInitiated = true
        setScreenInteractionBlocked(true)
        updateCheckoutButtonState()

        if isFreeTicket || totalPrice <= 0 {
            checkOutBtnView.showLoader()
            createFreeBookingIfNeeded()
            return
        }

        guard let paymentSheet else {
            resetPaymentInteractionAfterFailure()
            AppHaptic.warning()
            Alert.showToast("Payment not ready yet. Please wait.")
            return
        }

        paymentSheet.present(from: self) { [weak self] result in
            guard let self else { return }

            switch result {
            case .completed:
                self.checkOutBtnView.showLoader()
                self.handleSuccessfulCardPayment()
            case .canceled:
                self.handlePaymentCanceled()
            case .failed:
                self.resetPaymentInteractionAfterFailure()
                AppHaptic.error()
                Alert.showToast("Payment failed. Please try again.")
            }
        }
    }
}

// MARK: - Checkout Button State
extension CoverTicketCheckOutVC {

    /// Only called via didSet — single place that drives enabled/disabled.
    private func updateCheckoutButtonState() {
        let hasData =
            selectedCoverTickets.contains { ($0.selectedQuantity ?? 0) > 0 } ||
            selectedAddOnsItems.contains { ($0.selectedQuantity ?? 0) > 0 }
        let shouldShow = hasData && isBookingLoaded && isPaymentIntentLoaded
        let enabled = shouldShow && !isPaymentInitiated
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.setCheckoutButton(visible: shouldShow, enabled: enabled, animated: true)
            self.refreshCheckoutBarSummary()
        }
    }

    private func setCheckoutButton(enabled: Bool, animated: Bool) {
        setCheckoutButton(visible: enabled, enabled: enabled, animated: animated)
    }

    private func setCheckoutButton(visible: Bool, enabled: Bool, animated: Bool) {
        shouldShowCheckoutButton = visible
        checkOutBtnView.isUserInteractionEnabled = enabled

        let targetAlpha: CGFloat = visible ? 1.0 : 0
        let targetTransform = visible ? .identity : CGAffineTransform(translationX: 0, y: 80)

        guard animated else {
            checkOutBtnView.isHidden = !visible
            checkOutBtnView.alpha = targetAlpha
            checkOutBtnView.transform = targetTransform
            return
        }

        if visible {
            checkOutBtnView.isHidden = false
        }

        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0.35,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.checkOutBtnView.alpha = targetAlpha
            self.checkOutBtnView.transform = targetTransform
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.checkOutBtnView.isHidden = !self.shouldShowCheckoutButton
        }
    }

    /// Pushes correct totals + fee summary into CheckoutBarView.
    private func refreshCheckoutBarSummary() {
        let coverTotal  = paymentDetail?.total ?? 0
        let upsellTotal = addOnsPaymentDetail?.total ?? 0
        let grandTotal  = coverTotal + upsellTotal

        let coverCount  = selectedCoverTickets.reduce(0) { $0 + ($1.selectedQuantity ?? 0) }
        let upsellCount = selectedAddOnsItems.reduce(0) { $0 + ($1.selectedQuantity ?? 0) }
        let totalCount  = coverCount + upsellCount

        let totalFees = feesAboveSubtotal(from: paymentDetail, section: .cover)
                      + feesAboveSubtotal(from: addOnsPaymentDetail, section: .upsell)

        checkOutBtnView.updateSummary(
            currency: currency,
            currencyPosition: currencyPosition,
            count: totalCount,
            subtotal: grandTotal,
            fees: totalFees
        )
        
        checkOutBtnView.setButtonTitle(checkoutButtonTitle(for: grandTotal))
        checkOutBtnView.applyAccentColor(whiteLabelAccentColor)
    }

    /// Sum of all fees/tax above the subtotal for one PaymentDetail.
    private func feesAboveSubtotal(from detail: PaymentDetail?, section: FeeBreakdownSection) -> Double {
        visibleFeeItems(from: detail, section: section).reduce(0) { $0 + $1.amount }
    }

    private func totalSalesTax(from detail: PaymentDetail) -> Double {
        let salesTaxesTotal = detail.salesTaxes?
            .reduce(0) { $0 + ($1.salesTax ?? 0) } ?? 0
        return salesTaxesTotal > 0 ? salesTaxesTotal : (detail.salesTax ?? 0)
    }

    private var initialCheckoutButtonTitle: String {
        hasOnlyFreeSelection ? "Redeem Ticket" : "Pay Now"
    }

    private func checkoutButtonTitle(for total: Double) -> String {
        hasOnlyFreeSelection && total <= 0
            ? "Redeem Ticket"
            : "Pay \(CurrencyFormatter.amount(total, symbol: currency, position: currencyPosition))"
    }

    private var hasOnlyFreeSelection: Bool {
        let hasPaidCover = selectedCoverTickets.contains {
            $0.price > 0 || ($0.extraFees ?? 0) > 0
        }
        let hasPaidAddOn = selectedAddOnsItems.contains {
            $0.price > 0 || ($0.extraFees ?? 0) > 0
        }
        return !hasPaidCover && !hasPaidAddOn
    }

    fileprivate var selectedCoverTicketsAreAllCustom: Bool {
        !selectedCoverTickets.isEmpty && selectedCoverTickets.allSatisfy { $0.isCustom }
    }

    fileprivate var selectedCoverTicketsAreAllStandard: Bool {
        !selectedCoverTickets.isEmpty && selectedCoverTickets.allSatisfy { !$0.isCustom }
    }
}

// MARK: - API Calls
extension CoverTicketCheckOutVC {

    private func confirmCardPayment() {
        guard let cardDetails else {
            resetPaymentInteractionAfterFailure()
            Alert.showToast("Card details missing.")
            return
        }

        guard !paymentIntent.isEmpty else {
            resetPaymentInteractionAfterFailure()
            Alert.showToast("Payment not ready yet.")
            return
        }

        checkOutBtnView.showLoader()

        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = cardDetails.cardNumber
        cardParams.expMonth = NSNumber(value: cardDetails.expiryMonth)
        cardParams.expYear = NSNumber(value: cardDetails.expiryYear)
        cardParams.cvc = cardDetails.cvv

        let billing = STPPaymentMethodBillingDetails()
        billing.name = "\(cardDetails.firstName) \(cardDetails.lastName)"

        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billing,
            metadata: nil
        )

        STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { [weak self] paymentMethod, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.checkOutBtnView.hideLoader()
                    self.resetPaymentInteractionAfterFailure()
                    Alert.showToast(error.localizedDescription)
                }
                return
            }

            guard let paymentMethodId = paymentMethod?.stripeId else {
                DispatchQueue.main.async {
                    self.checkOutBtnView.hideLoader()
                    self.resetPaymentInteractionAfterFailure()
                    Alert.showToast("Failed to create payment method.")
                }
                return
            }

            self.confirmIntentViaREST(paymentMethodId: paymentMethodId)
        }
    }

    private func confirmIntentViaREST(paymentMethodId: String) {
        let intentId = paymentIntent.components(separatedBy: "_secret_").first ?? ""

        guard !intentId.isEmpty,
              let url = URL(string: "https://api.stripe.com/v1/payment_intents/\(intentId)/confirm") else {
            DispatchQueue.main.async {
                self.checkOutBtnView.hideLoader()
                self.resetPaymentInteractionAfterFailure()
                Alert.showToast("Invalid payment intent.")
            }
            return
        }

        let bodyString = [
            "payment_method=\(paymentMethodId)",
            "client_secret=\(paymentIntent)"
        ].joined(separator: "&")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "Bearer \(STPAPIClient.shared.publishableKey ?? "")",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.checkOutBtnView.hideLoader()

                if let error {
                    self.resetPaymentInteractionAfterFailure()
                    Alert.showToast(error.localizedDescription)
                    return
                }

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.resetPaymentInteractionAfterFailure()
                    Alert.showToast("Payment failed. Please try again.")
                    return
                }

                if let errorObj = json["error"] as? [String: Any],
                   let message = errorObj["message"] as? String {
                    self.resetPaymentInteractionAfterFailure()
                    Alert.showToast(message)
                    return
                }

                let status = json["status"] as? String ?? ""
                switch status {
                case "succeeded", "requires_capture":
                    self.checkOutBtnView.showLoader()
                    self.handleSuccessfulCardPayment()
                case "requires_action":
                    self.resetPaymentInteractionAfterFailure()
                    Alert.showToast("Additional authentication required. Please use Apple Pay.")
                default:
                    self.resetPaymentInteractionAfterFailure()
                    Alert.showToast("Payment status: \(status). Please try again.")
                }
            }
        }.resume()
    }

    private func createBooking() {
        let tickets: [[String: Any]] = selectedCoverTickets.map {
            ["ticketId": $0.id, "ticketQuantity": $0.selectedQuantity ?? 0]
        }
        PaymentPresenter.createCoverBooking(coverTickets: tickets, venueId: venue?.id ?? "", doormanId: doormanId) {
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
                self.setPricingLoading(false, animated: true)
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
            type: .appClip,
            doormanId: doormanId
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
                self.setPricingLoading(false, animated: true)
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
            addOnsItems: addOnsItems,
            doormanId: doormanId
        ) { [weak self] isSuccess, errMsg, clientSecret, ephemeralKey, paymentDetail, bookingId in
            guard let self else { return }
            if isSuccess {
                self.addOnsPaymentDetail = paymentDetail
                self.addOnsBookingId = bookingId
                if self.shouldUseAddOnsPaymentIntentAsPrimary {
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
                self.setPricingLoading(false, animated: true)
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    private func cancelBooking() {
        guard !isCancellingTransaction else { return }
        countdownTimer?.invalidate()
        isCancellingTransaction = true
        setScreenInteractionBlocked(true)

        guard !bookingId.isEmpty else {
            isCancellingTransaction = false
            setScreenInteractionBlocked(false)
            returnToCoverFlow(animated: false)
            return
        }
        PaymentPresenter.cancelBooking(bookingId: bookingId) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isCancellingTransaction = false
                self.setScreenInteractionBlocked(false)
                self.returnToCoverFlow(animated: false)
            }
        }
    }

    private func showCancelTransactionPrompt() {
        guard !isPaymentInitiated, !isCancellingTransaction else { return }
        presentTransactionCancelConfirmation { [weak self] in
            self?.cancelBooking()
        }
    }

    private func handlePaymentCanceled() {
        resetPaymentInteractionAfterFailure()
    }

    private func returnToCoverFlow(animated: Bool) {
        guard let navigationController else { return }

        if let coverListVC = navigationController.viewControllers.first(where: { $0 is CoverTicketListVC }) as? CoverTicketListVC {
            coverListVC.resetToCoverTicketStep()
            navigationController.popToViewController(coverListVC, animated: animated)
        } else {
            navigationController.popViewController(animated: animated)
        }
    }
}

// MARK: - Stripe Setup
extension CoverTicketCheckOutVC {

    private func setupStripePaymentSheet() {
        guard !paymentIntent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            paymentSheet = nil
            return
        }

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
        let newFees       = buildFeesArray(from: paymentDetail, section: .cover)
        let newUpsellFees = buildFeesArray(from: addOnsPaymentDetail, section: .upsell)

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
            self.upsellTicketTableView.reloadData()
            self.setPricingLoading(false, animated: false)

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
    private func buildFeesArray(from detail: PaymentDetail?, section: FeeBreakdownSection) -> [FeeDisplayItem] {
        guard let detail else { return [] }

        let subTotal = detail.subTotal
        let total    = detail.total

        let feeItems = visibleFeeItems(from: detail, section: section)

        guard subTotal != total, !feeItems.isEmpty else {
            return [FeeDisplayItem(title: "Total", amount: total)]
        }

        var items: [FeeDisplayItem] = []

        if subTotal > 0 {
            items.append(FeeDisplayItem(title: "Subtotal", amount: subTotal))
        }

        items.append(contentsOf: feeItems)
        items.append(FeeDisplayItem(title: "Total", amount: total))
        return items
    }

    private func visibleFeeItems(from detail: PaymentDetail?, section: FeeBreakdownSection) -> [FeeDisplayItem] {
        guard let detail else { return [] }
        var items: [FeeDisplayItem] = []

        if shouldShowCustomFees(section: section) {
            appendCustomFeeItems(from: detail, to: &items)
        }

        if shouldShowSalesTax(section: section, detail: detail) {
            appendSalesTaxItems(from: detail, to: &items)
        }

        if shouldShowProcessingFee(section: section, detail: detail) {
            appendFeeItem(title: "Processing Fee", amount: detail.processingFee, to: &items)
        }

        return items
    }

    private func appendCustomFeeItems(from detail: PaymentDetail, to items: inout [FeeDisplayItem]) {
        if let customFees = detail.customFees, !customFees.isEmpty {
            customFees.forEach {
                appendFeeItem(
                    title: $0.name,
                    amount: $0.fee ?? $0.amount ?? 0,
                    to: &items
                )
            }
        } else if detail.customFee > 0 {
            appendFeeItem(
                title: detail.customFeeName ?? "Custom Fee",
                amount: detail.customFee,
                to: &items
            )
        }
    }

    private func appendSalesTaxItems(from detail: PaymentDetail, to items: inout [FeeDisplayItem]) {
        let salesTaxItems = feeItemsForSalesTaxes(from: detail)
        if !salesTaxItems.isEmpty {
            salesTaxItems.forEach {
                appendFeeItem(title: $0.title, amount: $0.amount, to: &items)
            }
        } else if let salesTax = detail.salesTax, salesTax > 0 {
            appendFeeItem(
                title: detail.salesTaxName ?? "Sales Tax",
                amount: salesTax,
                to: &items
            )
        }
    }

    private func feeItemsForSalesTaxes(from detail: PaymentDetail) -> [FeeDisplayItem] {
        guard let salesTaxes = detail.salesTaxes, !salesTaxes.isEmpty else { return [] }
        return salesTaxes.compactMap { tax in
            let amount = tax.salesTax ?? 0
            guard amount > 0 else { return nil }
            return FeeDisplayItem(
                title: tax.salesTaxName ?? "Sales Tax",
                amount: amount
            )
        }
    }

    private func appendFeeItem(title: String, amount: Double, to items: inout [FeeDisplayItem]) {
        guard amount > 0 else { return }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayTitle = cleanTitle.isEmpty ? "Fee" : cleanTitle
        let normalizedTitle = displayTitle.lowercased()

        if let index = items.firstIndex(where: {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedTitle
        }) {
            items[index].amount += amount
        } else {
            items.append(FeeDisplayItem(title: displayTitle, amount: amount))
        }
    }

    private func shouldShowCustomFees(section: FeeBreakdownSection) -> Bool {
        switch section {
        case .cover:
            if selectedCoverTicketsAreAllCustom {
                return venue?.venueSettings?.customCoverTicketSettings?.isEnableCustomFee == true
            }
            if selectedCoverTicketsAreAllStandard {
                let settings = venue?.venueSettings?.coverTicketSettings
                return settings?.isEnableCustomFee == true && settings?.isUpFront == false
            }
            let standardSettings = venue?.venueSettings?.coverTicketSettings
            return (standardSettings?.isEnableCustomFee == true && standardSettings?.isUpFront == false)
                || venue?.venueSettings?.customCoverTicketSettings?.isEnableCustomFee == true
        case .upsell:
            let settings = venue?.venueSettings?.addOnsBookingSettings
            return (settings?.isEnableCustomFee ?? true) && settings?.isUpFront == false
        }
    }

    private func shouldShowSalesTax(section: FeeBreakdownSection, detail: PaymentDetail) -> Bool {
        guard totalSalesTax(from: detail) > 0 else { return false }

        switch section {
        case .cover:
            if selectedCoverTicketsAreAllCustom {
                return venue?.venueSettings?.customCoverTicketSettings?.isEnableSalesTax == true
            }
            if selectedCoverTicketsAreAllStandard {
                let settings = venue?.venueSettings?.coverTicketSettings
                return settings?.isEnableSalesTax == true && settings?.isUpFront == false
            }
            let standardSettings = venue?.venueSettings?.coverTicketSettings
            return (standardSettings?.isEnableSalesTax == true && standardSettings?.isUpFront == false)
                || venue?.venueSettings?.customCoverTicketSettings?.isEnableSalesTax == true
        case .upsell:
            let settings = venue?.venueSettings?.addOnsBookingSettings
            return (settings?.isEnableSalesTax ?? true) && settings?.isUpFront == false
        }
    }

    private func shouldShowProcessingFee(section: FeeBreakdownSection, detail: PaymentDetail) -> Bool {
        guard detail.processingFee > 0 else { return false }

        switch section {
        case .cover:
            if selectedCoverTicketsAreAllCustom {
                return venue?.venueSettings?.customCoverTicketSettings?.isProcessingFeePassToCustomer == true
            }
            if selectedCoverTicketsAreAllStandard {
                let settings = venue?.venueSettings?.coverTicketSettings
                return settings?.isProcessingFeePassToCustomer == true && settings?.isUpFront == false
            }
            let standardSettings = venue?.venueSettings?.coverTicketSettings
            return (standardSettings?.isProcessingFeePassToCustomer == true && standardSettings?.isUpFront == false)
                || venue?.venueSettings?.customCoverTicketSettings?.isProcessingFeePassToCustomer == true
        case .upsell:
            let settings = venue?.venueSettings?.addOnsBookingSettings
            return (settings?.isProcessingFeePassToCustomer ?? true) && settings?.isUpFront == false
        }
    }

}

// MARK: - Payment Completion Flow
extension CoverTicketCheckOutVC {

    private func handleSuccessfulCardPayment() {
        if selectedCoverTickets.isEmpty && !selectedAddOnsItems.isEmpty {
            addOnsPaymentSuccess {
                self.finishAndNavigate(isAddOnsAvailable: true, isOnlyAddOn: true)
            }
            return
        }

        if bookingType == .FREE {
            createFreeBooking {
                self.addOnsPaymentSuccess {
                    self.finishAndNavigate(isAddOnsAvailable: true, isOnlyAddOn: false)
                }
            }
            return
        }

        paymentStatus(
            optedPolicy: self.selectedVenueMessageOptIn,
            optedEmailPolicy: self.selectedEmailMessageOptIn
        ) {
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
        NotificationCenter.default.postOrdersRefresh(.tickets)
        AppHaptic.success()
        let qrPresenter = resetCoverListForFreshPurchaseIfNeeded() ?? self
        Navigate.to.scanQR(
            qrPresenter,
            isAddOnsAvailable: isAddOnsAvailable,
            bookingId: bookingId,
            isOnlyAddOnAvailable: isOnlyAddOn,
            venueId: venue?.id ?? "",
            addOnsBookingId: addOnsBookingId ?? "",
            venueName: venue?.name ?? "",
            shouldPushFromVenueFlow: true,
            buyAnotherCoverListTarget: qrPresenter as? CoverTicketListVC
        )
    }

    private var selectedVenueMessageOptIn: Bool? {
        venueMessageView.isHidden ? nil : isVenueMessageAccepted
    }

    private var selectedEmailMessageOptIn: Bool? {
        emailMessageView.isHidden ? nil : isEmailMessageAccepted
    }

    private func paymentStatus(
        optedPolicy: Bool? = nil,
        optedEmailPolicy: Bool? = nil,
        completion: @escaping () -> Void
    ) {
        PaymentPresenter.successPayment(
            paymentHistoryId: paymentHistoryId,
            bookingId: bookingId,
            optedPolicy: optedPolicy,
            optedEmailPolicy: optedEmailPolicy,
            doormanId: doormanId
        ) { [weak self] isSuccess, errMsg in
            if isSuccess {
                completion()
            } else {
                self?.checkOutBtnView.hideLoader()
                self?.resetPaymentInteractionAfterFailure()
                AppHaptic.error()
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    private func addOnsPaymentSuccess(completion: @escaping () -> Void) {
        let mainBookingId = bookingType == .FREE && !selectedCoverTickets.isEmpty ? bookingId : ""
        PaymentPresenter.successAddOnsPayment(
            bookingId: addOnsBookingId ?? "",
            mainBookingId: mainBookingId,
            doormanId: doormanId
        ) { [weak self] isSuccess, errMsg in
            if isSuccess {
                completion()
            } else {
                self?.checkOutBtnView.hideLoader()
                self?.resetPaymentInteractionAfterFailure()
                AppHaptic.error()
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    private func createFreeBooking(completion: @escaping () -> Void) {
        let tickets: [[String: Any]] = selectedCoverTickets.map {
            ["ticketId": $0.id, "ticketQuantity": $0.selectedQuantity ?? 0]
        }
        PaymentPresenter.createCoverFreeBooking(
            coverTickets: tickets,
            venueId: venue?.id ?? "",
            optedPolicy: selectedVenueMessageOptIn,
            optedEmailPolicy: selectedEmailMessageOptIn,
            doormanId: doormanId
        ) { [weak self] isSuccess, errMsg, id, _ in
            guard let self else { return }
            if isSuccess, let id {
                self.bookingId = id
                completion()
            } else {
                self.checkOutBtnView.hideLoader()
                self.resetPaymentInteractionAfterFailure()
                AppHaptic.error()
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
        setScreenInteractionBlocked(true)
        updateCheckoutButtonState()

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
            resetPaymentInteractionAfterFailure()
            Alert.showToast("Problem with your Apple Pay")
        }
    }

    private func alertForWallet() {
        let title   = isApplePayNotSupported ? Constant.String.notSupported    : Constant.String.addCardToApplePay
        let message = isApplePayNotSupported ? Constant.String.applePayNotSupported : Constant.String.addCardToYourApplePayWallet

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.isFromApplePay = true
            self?.resetPaymentInteractionAfterFailure()
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
        switch status {
        case .success:
            checkOutBtnView.showLoader()
            handleSuccessfulCardPayment()
        case .error:
            isFromApplePay = true
            resetPaymentInteractionAfterFailure()
            Alert.showAlertSheet(style: .alert, title: "Payment failed", message: "")
        case .userCancellation:
            isFromApplePay = true
            handlePaymentCanceled()
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
            self.updateDelegate?.update()
            self.cancelBooking()
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
        case coverTicketFeesAndTaxTableView:
            return isPricingLoading && !selectedCoverTickets.isEmpty
                ? coverFeeShimmerRowCount
                : feesAndTaxes.count
        case upsellTicketTableView:             return selectedAddOnsItems.count
        case upsellTicketFeesAndTaxTableView:
            return isPricingLoading && !selectedAddOnsItems.isEmpty
                ? upsellFeeShimmerRowCount
                : upsellFeesAndTaxes.count
        default:                                return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case self.tableView:
            return makeCoverTicketCell(for: indexPath, in: tableView)
        case coverTicketFeesAndTaxTableView:
            if isPricingLoading && !selectedCoverTickets.isEmpty {
                return makeFeeShimmerCell(in: tableView)
            }
            return makeFeesCell(item: feesAndTaxes[indexPath.row], in: tableView, at: indexPath)
        case upsellTicketTableView:
            return makeUpsellTicketCell(for: indexPath, in: tableView)
        case upsellTicketFeesAndTaxTableView:
            if isPricingLoading && !selectedAddOnsItems.isEmpty {
                return makeFeeShimmerCell(in: tableView)
            }
            return makeFeesCell(item: upsellFeesAndTaxes[indexPath.row], in: tableView, at: indexPath)
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch tableView {
        case self.tableView:
            onCoverFeesToggle()
        case upsellTicketTableView:
            onUpsellFeesToggle()
        default:
            break
        }
    }

    private func makeCoverTicketCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: QRTicketTableViewCell.identifier, for: indexPath
        ) as? QRTicketTableViewCell else { return UITableViewCell() }

        let ticket   = selectedCoverTickets[indexPath.row]
        let quantity = ticket.selectedQuantity ?? 0
        let price    = ticket.price - (ticket.extraFees ?? 0)
        let total    = Double(quantity) * price

        cell.selectionStyle           = .none
        cell.totalTicketCountLbl.text = "\(quantity)"
        cell.ticketNameLbl.text       = ticket.customName?.isEmpty == false ? ticket.customName : ticket.name
        applyDescription(ticket.description, to: cell)
        cell.priceLbl.text            = total <= 0 ? "Free" : "\(CurrencyFormatter.amount(total, symbol: currency, position: currencyPosition))"
        cell.priceLbl.isHidden        = false
        return cell
    }

    private func makeUpsellTicketCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: QRTicketTableViewCell.identifier, for: indexPath
        ) as? QRTicketTableViewCell else { return UITableViewCell() }

        let item     = selectedAddOnsItems[indexPath.row]
        let quantity = item.selectedQuantity ?? 0
        let total    = Double(quantity) * item.calculatedNetPrice

        cell.selectionStyle           = .none
        cell.totalTicketCountLbl.text = "\(quantity)"
        cell.ticketNameLbl.text       = item.addOns?.name ?? ""
        applyDescription(item.addOns?.description, to: cell)
        cell.priceLbl.text            = total <= 0 ? "Free" : "\(CurrencyFormatter.amount(total, symbol: currency, position: currencyPosition))"
        cell.priceLbl.isHidden        = false
        return cell
    }

    private func applyDescription(_ description: String?, to cell: QRTicketTableViewCell) {
        let text = description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        cell.discriptionLbl.text = text
        cell.discriptionLbl.isHidden = text.isEmpty
        cell.discriptionLbl.superview?.isHidden = text.isEmpty
    }

    private func makeFeeShimmerCell(in tableView: UITableView) -> UITableViewCell {
        let identifier = FeeBreakdownShimmerCell.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            as? FeeBreakdownShimmerCell
            ?? FeeBreakdownShimmerCell(style: .default, reuseIdentifier: identifier)
        cell.selectionStyle = .none
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
        cell.amountLbl.text = CurrencyFormatter.amount(item.amount, symbol: currency, position: currencyPosition)

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
        guard venue?.id == venueId else { return }
        Alert.showAlertSheet(
            style: .alert,
            title: "Update",
            message: "The partner you're booking is closing",
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
            message: "The partner updated its ticket options",
            actions: [popAction()]
        )
    }

    private func showPriceUpdateAlert() {
        Alert.showAlertSheet(
            style: .alert,
            title: "Update",
            message: "The partner updated their prices",
            actions: [popAction()]
        )
    }

    private func popAction() -> UIAlertAction {
        UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self else { return }
            if let vc = navigationController?.viewControllers.first(where: { $0 is CoverTicketListVC }) as? CoverTicketListVC {
                vc.resetForFreshPurchase()
                navigationController?.popToViewController(vc, animated: true)
            } else if let vc = navigationController?.viewControllers.first(where: { $0 is VenueVC }) {
                navigationController?.popToViewController(vc, animated: true)
            } else if let vc = navigationController?.viewControllers.first(where: { $0 is MVPVenueListVc }) {
                navigationController?.popToViewController(vc, animated: true)
            } else if let vc = navigationController?.viewControllers.first(where: { $0 is MVPVenueDetailVc }) {
                navigationController?.popToViewController(vc, animated: true)
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }
}

private extension CoverTicketCheckOutVC {

    func resetCoverListForFreshPurchaseIfNeeded() -> CoverTicketListVC? {
        guard let coverListVC = navigationController?.viewControllers
            .first(where: { $0 is CoverTicketListVC }) as? CoverTicketListVC else {
            return nil
        }

        coverListVC.reloadForFreshPurchase()

        if let navigationController = coverListVC.navigationController,
           let coverListIndex = navigationController.viewControllers.firstIndex(of: coverListVC) {
            let retainedStack = Array(navigationController.viewControllers.prefix(coverListIndex + 1))
            navigationController.setViewControllers(retainedStack, animated: false)
        }

        return coverListVC
    }
}

// MARK: - CheckoutBarDelegate
extension CoverTicketCheckOutVC: CheckoutBarDelegate {
    func checkoutBarDidTapButton() {
        onClickContinueToCheckout()
    }
}

private extension CoverTicketFeesSettings {
    var hasEnabledCustomFees: Bool {
        if let customFees, !customFees.isEmpty {
            return customFees.contains { $0.isEnableCustomFee }
        }
        return isEnableCustomFee
    }
}

private final class FeeBreakdownShimmerCell: UITableViewCell {

    private let titleLine = ShimmerViewV3()
    private let amountLine = ShimmerViewV3()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        [titleLine, amountLine].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            titleLine.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            titleLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.44),
            titleLine.heightAnchor.constraint(equalToConstant: 12),

            amountLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            amountLine.centerYAnchor.constraint(equalTo: titleLine.centerYAnchor),
            amountLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.22),
            amountLine.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            titleLine.stopShimmer()
            amountLine.stopShimmer()
        } else {
            titleLine.startShimmer()
            amountLine.startShimmer()
        }
    }
}
