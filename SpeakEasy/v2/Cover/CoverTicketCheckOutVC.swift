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
    private var isBookingLoaded = false
    private var isPaymentIntentLoaded = false

    private var feesAndTaxes: [FeeDisplayItem] = []
    private var upsellFeesAndTaxes: [FeeDisplayItem] = []
    private let posterHeaderView = EventPosterHeaderView()

    private var countdownTimer: Timer?
    private var remainingSeconds: Int = 10 * 60
    private var enterBgDate = Date()
    private var exitBgDate = Date()

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
//        setupCheckoutButton()
        setupNotifications()

        checkOutBtnView.alpha = 0.5
        checkOutBtnView.isUserInteractionEnabled = false
        checkOutBtnView.delegate = self

        if !selectedCoverTickets.isEmpty && bookingType != .FREE {
            createBooking()
        } else {
            getAddOnsPaymentIntent(bookingId: "")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.interactivePopGestureRecognizer?.addTarget(
            self,
            action: #selector(handleBackSwipe)
        )

        imageParentView.playEntryAnimation()
        WebSocketWrapper.shared.delegate.append(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        navigationController?.interactivePopGestureRecognizer?.removeTarget(
            self,
            action: #selector(handleBackSwipe)
        )

        WebSocketWrapper.shared.delegate.removeAll(where: { $0 as? NSObject == self })
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        countdownTimer?.invalidate()

        tableView.removeObserver(self, forKeyPath: "contentSize")
        coverTicketFeesAndTaxTableView.removeObserver(self, forKeyPath: "contentSize")
        upsellTicketTableView.removeObserver(self, forKeyPath: "contentSize")
        upsellTicketFeesAndTaxTableView.removeObserver(self, forKeyPath: "contentSize")
    }

    // MARK: - Setup
    private func setupTableViews() {
        tableView.register(
            OrderItemTableViewCell.nib,
            forCellReuseIdentifier: OrderItemTableViewCell.identifier
        )

        upsellTicketTableView.register(
            OrderItemTableViewCell.nib,
            forCellReuseIdentifier: OrderItemTableViewCell.identifier
        )

        coverTicketFeesAndTaxTableView.register(
            TicketItemTableViewCell.nib,
            forCellReuseIdentifier: TicketItemTableViewCell.identifier
        )

        upsellTicketFeesAndTaxTableView.register(
            TicketItemTableViewCell.nib,
            forCellReuseIdentifier: TicketItemTableViewCell.identifier
        )

        [tableView, coverTicketFeesAndTaxTableView, upsellTicketTableView, upsellTicketFeesAndTaxTableView].forEach {
            $0?.delegate = self
            $0?.dataSource = self
            $0?.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        }
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
            SDWebImageManager.shared.loadImage(
                with: url,
                options: .highPriority,
                progress: nil
            ) { [weak self] image, _, _, _, _, _ in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.imageParentView.setImage(image ?? UIImage(named: "newSpeakeasy"))
                }
            }
        } else {
            imageParentView.setImage(named: "newSpeakeasy")
        }

        coverTicketParentView.isHidden = selectedCoverTickets.isEmpty
        upsellTicketParentView.isHidden = selectedAddOnsItems.isEmpty

        venueName.text = venue?.name ?? ""

        privacyPolicyLbl.text = "I agree to receive marketing related text messages from \(venue?.name ?? ""). Msg & data rates may apply. Reply STOP to opt out or HELP for support."
    }

//    private func setupCheckoutButton() {
//        let tap = UITapGestureRecognizer(
//            target: self,
//            action: #selector(onClickContinueToCheckout)
//        )
//
//        checkOutBtnView.addGestureRecognizer(tap)
//        checkOutBtnView.isUserInteractionEnabled = false
//    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackGround),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(exitBackGround),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackGround),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(exitBackGround),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: - KVO
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "contentSize", let table = object as? UITableView else { return }

        DispatchQueue.main.async {
            if table == self.tableView {
                self.tableViewHeight.constant = table.contentSize.height
            } else if table == self.coverTicketFeesAndTaxTableView {
                self.coverTicketFeesAndTaxTableViewHeight.constant = table.contentSize.height
            } else if table == self.upsellTicketTableView {
                self.upsellTicketTableViewHeight.constant = table.contentSize.height
            } else if table == self.upsellTicketFeesAndTaxTableView {
                self.upsellTicketFeesAndTaxTableViewHeight.constant = table.contentSize.height
            }
        }
    }

    // MARK: - Actions
    @IBAction func onClickBackBtn(_ sender: Any) {
        cancelBooking()
    }

    @objc private func handleBackSwipe() {
        navigationController?.interactivePopGestureRecognizer?.removeTarget(
            self,
            action: #selector(handleBackSwipe)
        )
        cancelBooking()
    }

 func onClickContinueToCheckout() {
        if isPaymentInitiated { return }

        isPaymentInitiated = true

        if isFreeTicket || bookingType == .FREE || totalPrice <= 0 {
            isPaymentInitiated = false
            createFreeBookingIfNeeded()
            return
        }

        guard let paymentSheet = paymentSheet else {
            isPaymentInitiated = false
            Alert.showAlertSheet(
                style: .alert,
                title: Constant.String.somethingWrong,
                message: ""
            )
            return
        }

        paymentSheet.present(from: self) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .completed:
                self.isPaymentInitiated = false
                self.handleSuccessfulCardPayment()

            case .canceled:
                self.isPaymentInitiated = false

            case .failed:
                self.isPaymentInitiated = false
                Alert.showAlertSheet(
                    style: .alert,
                    title: "Payment failed",
                    message: ""
                )
            }
        }
    }
}

// MARK: - API Calls
extension CoverTicketCheckOutVC {

    private func createBooking() {
        let tickets: [[String: Any]] = selectedCoverTickets.map {
            [
                "ticketId": $0.id,
                "ticketQuantity": $0.selectedQuantity ?? 0
            ]
        }

        PaymentPresenter.createCoverBooking(
            coverTickets: tickets,
            venueId: venue?.id ?? ""
        ) { [weak self] isSuccess, errMsg, id, _ in
            guard let self = self else { return }

            if isSuccess, let id = id {
                self.bookingId = id
                self.isBookingLoaded = true
                self.fetchPaymentIntentAndSetup(
                    promoCode: self.isPromoCodeApplied ? self.appliedPromoCode : ""
                )
            } else {
                self.isBookingLoaded = true
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }

    private func fetchPaymentIntentAndSetup(promoCode: String) {
        let tickets: [[String: Any]] = selectedCoverTickets.map {
            [
                "ticketId": $0.id,
                "quantity": $0.selectedQuantity ?? 0
            ]
        }

        PaymentPresenter.getPaymentIntent(
            bookingId: bookingId,
            selectedTickets: tickets,
            promoCode: promoCode,
            type: .appClip
        ) { [weak self] isSuccess, errMsg, clientSecret, paymentHistoryId, ephemeralKey, paymentDetail, isFreeTicket in
            guard let self = self else { return }

            if isSuccess, let clientSecret = clientSecret {
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

                if self.isPromoCodeApplied {
                    self.isPromoCodeApplied = false
                }

                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }

    private func getAddOnsPaymentIntent(bookingId: String) {
        let addOnsItems: [[String: Any]] = selectedAddOnsItems.map {
            [
                "id": $0.id,
                "addOnsId": $0.addOns?.id ?? "",
                "quantity": $0.selectedQuantity ?? 0
            ]
        }

        PaymentPresenter.addOnsPaymentIntent(
            bookingId: bookingId,
            venueId: venue?.id ?? "",
            addOnsItems: addOnsItems
        ) { [weak self] isSuccess, errMsg, clientSecret, ephemeralKey, paymentDetail, bookingId in
            guard let self = self else { return }

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

                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }

    private func cancelBooking() {
        countdownTimer?.invalidate()

        if bookingId.isEmpty {
            navigationController?.popToRootViewController(animated: false)
            return
        }

        PaymentPresenter.cancelBooking(bookingId: bookingId) { _, _ in
            self.navigationController?.popToRootViewController(animated: false)
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

        DispatchQueue.main.async {
            self.checkOutBtnView.alpha = 1
            self.checkOutBtnView.isUserInteractionEnabled = true
        }
    }
}

// MARK: - Payment Completion Flow
extension CoverTicketCheckOutVC {

    private func handleSuccessfulCardPayment() {
        if bookingType == .FREE {
            createFreeBooking {
                self.addOnsPaymentSuccess {
                    self.countdownTimer?.invalidate()
                    Navigate.to.scanQR(
                        self,
                        isAddOnsAvailable: true,
                        bookingId: self.bookingId,
                        isOnlyAddOnAvailable: false,
                        venueId: self.venue?.id ?? "",
                        addOnsBookingId: self.addOnsBookingId ?? "",
                        venueName: self.venue?.name ?? ""
                    )
                }
            }
            return
        }

        if selectedCoverTickets.isEmpty && !selectedAddOnsItems.isEmpty {
            addOnsPaymentSuccess {
                self.countdownTimer?.invalidate()
                Navigate.to.scanQR(
                    self,
                    isAddOnsAvailable: true,
                    bookingId: self.bookingId,
                    isOnlyAddOnAvailable: true,
                    venueId: self.venue?.id ?? "",
                    addOnsBookingId: self.addOnsBookingId ?? "",
                    venueName: self.venue?.name ?? ""
                )
            }
            return
        }

        paymentStatus(
            optedPolicy: venue?.venueSettings?.optedPolicy == true ? true : nil
        ) {
            if self.selectedAddOnsItems.isEmpty {
                self.countdownTimer?.invalidate()
                Navigate.to.scanQR(
                    self,
                    bookingId: self.bookingId,
                    addOnsBookingId: self.addOnsBookingId ?? "",
                    venueName: self.venue?.name ?? ""
                )
            } else {
                self.addOnsPaymentSuccess {
                    self.countdownTimer?.invalidate()
                    Navigate.to.scanQR(
                        self,
                        isAddOnsAvailable: true,
                        bookingId: self.bookingId,
                        isOnlyAddOnAvailable: false,
                        venueId: self.venue?.id ?? "",
                        addOnsBookingId: self.addOnsBookingId ?? "",
                        venueName: self.venue?.name ?? ""
                    )
                }
            }
        }
    }

    private func createFreeBookingIfNeeded() {
        if selectedCoverTickets.isEmpty && !selectedAddOnsItems.isEmpty {
            addOnsPaymentSuccess {
                self.countdownTimer?.invalidate()
                Navigate.to.scanQR(
                    self,
                    isAddOnsAvailable: true,
                    bookingId: self.bookingId,
                    isOnlyAddOnAvailable: true,
                    venueId: self.venue?.id ?? "",
                    addOnsBookingId: self.addOnsBookingId ?? "",
                    venueName: self.venue?.name ?? ""
                )
            }
            return
        }

        createFreeBooking {
            if self.selectedAddOnsItems.isEmpty {
                self.countdownTimer?.invalidate()
                Navigate.to.scanQR(
                    self,
                    bookingId: self.bookingId,
                    addOnsBookingId: self.addOnsBookingId ?? "",
                    venueName: self.venue?.name ?? ""
                )
            } else {
                self.addOnsPaymentSuccess {
                    self.countdownTimer?.invalidate()
                    Navigate.to.scanQR(
                        self,
                        isAddOnsAvailable: true,
                        bookingId: self.bookingId,
                        isOnlyAddOnAvailable: false,
                        venueId: self.venue?.id ?? "",
                        addOnsBookingId: self.addOnsBookingId ?? "",
                        venueName: self.venue?.name ?? ""
                    )
                }
            }
        }
    }

    private func paymentStatus(
        optedPolicy: Bool? = nil,
        completion: @escaping (() -> Void)
    ) {
        Loader.show()

        PaymentPresenter.successPayment(
            paymentHistoryId: paymentHistoryId,
            bookingId: bookingId,
            optedPolicy: optedPolicy
        ) { isSuccess, errMsg in
            Loader.hide()

            if isSuccess {
                completion()
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }

    private func addOnsPaymentSuccess(completion: @escaping (() -> Void)) {
        var mainBookingId = ""

        if bookingType == .FREE {
            mainBookingId = bookingId
        }

        PaymentPresenter.successAddOnsPayment(
            bookingId: addOnsBookingId ?? "",
            mainBookingId: mainBookingId
        ) { isSuccess, errMsg in
            if isSuccess {
                completion()
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }

    private func createFreeBooking(completion: @escaping (() -> Void)) {
        let appClipTickets: [[String: Any]] = selectedCoverTickets.map {
            [
                "ticketId": $0.id,
                "ticketQuantity": $0.selectedQuantity ?? 0
            ]
        }

        PaymentPresenter.createCoverFreeBooking(
            coverTickets: appClipTickets,
            venueId: venue?.id ?? ""
        ) { [weak self] isSuccess, errMsg, id, _ in
            guard let self = self else { return }

            if isSuccess, let id = id {
                self.bookingId = id
                completion()
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }
}

// MARK: - Apple Pay
extension CoverTicketCheckOutVC {

    private func applePayButtonTapped() {
        isFromApplePay = true

        if StripeAPI.deviceSupportsApplePay() == false {
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

        if let applePayContext = STPApplePayContext(
            paymentRequest: paymentRequest,
            delegate: self
        ) {
            applePayContext.presentApplePay()
        } else {
            Alert.showToast("Problem with your Apple Pay")
        }
    }

    private func alertForWallet() {
        let title = isApplePayNotSupported
            ? Constant.String.notSupported
            : Constant.String.addCardToApplePay

        let message = isApplePayNotSupported
            ? Constant.String.applePayNotSupported
            : Constant.String.addCardToYourApplePayWallet

        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.isFromApplePay = true
            self.isPaymentInitiated = false
        }

        let setUpAction = UIAlertAction(title: "Add Card", style: .default) { _ in
            if let url = URL(string: "wallet://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        alertController.addAction(okAction)
        alertController.addAction(setUpAction)

        present(alertController, animated: true)
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
            isPaymentInitiated = false
            handleSuccessfulCardPayment()

        case .error:
            isFromApplePay = true
            isPaymentInitiated = false
            Alert.showAlertSheet(
                style: .alert,
                title: "Payment failed",
                message: ""
            )

        case .userCancellation:
            isFromApplePay = true
            isPaymentInitiated = false
        }
    }
}

// MARK: - UI Update
extension CoverTicketCheckOutVC {

    private func updateUIWithPaymentDetail() {
        feesAndTaxes = buildFeesArray(from: paymentDetail)
        upsellFeesAndTaxes = buildFeesArray(from: addOnsPaymentDetail)

        let coverTotal = paymentDetail?.total ?? 0
        let upsellTotal = addOnsPaymentDetail?.total ?? 0

        totalPrice = coverTotal + upsellTotal
        isFreeTicket = totalPrice <= 0

        DispatchQueue.main.async {
            self.coverTicketParentView.isHidden = self.selectedCoverTickets.isEmpty
            self.upsellTicketParentView.isHidden = self.selectedAddOnsItems.isEmpty

            self.tableView.reloadData()
            self.coverTicketFeesAndTaxTableView.reloadData()
            self.upsellTicketTableView.reloadData()
            self.upsellTicketFeesAndTaxTableView.reloadData()
        }
    }

    private func buildFeesArray(from detail: PaymentDetail?) -> [FeeDisplayItem] {
        var items: [FeeDisplayItem] = []
        guard let detail = detail else { return items }

        let subTotal = detail.subTotal
        let total = detail.total

        if subTotal == total {
            return [
                FeeDisplayItem(title: "Total", amount: total)
            ]
        }

        if subTotal > 0 {
            items.append(
                FeeDisplayItem(title: "Subtotal", amount: subTotal)
            )
        }

        if let customFees = detail.customFees, !customFees.isEmpty {
            customFees.forEach {
                items.append(
                    FeeDisplayItem(
                        title: $0.name,
                        amount: $0.fee ?? 0
                    )
                )
            }
        } else if detail.customFee > 0 {
            items.append(
                FeeDisplayItem(
                    title: detail.customFeeName ?? "Custom Fee",
                    amount: detail.customFee
                )
            )
        }

        if (detail.salesTax ?? 0) > 0 {
            items.append(
                FeeDisplayItem(
                    title: detail.salesTaxName ?? "Sales Tax",
                    amount: detail.salesTax ?? 0
                )
            )
        }

        if detail.processingFee > 0 {
            items.append(
                FeeDisplayItem(
                    title: "Processing Fee",
                    amount: detail.processingFee
                )
            )
        }

        items.append(
            FeeDisplayItem(title: "Total", amount: total)
        )

        return items
    }
}

// MARK: - Background Timer Handling
extension CoverTicketCheckOutVC {

    private func startCountdown() {
        updateTimerLabel()

        countdownTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] timer in
            guard let self = self else { return }

            self.remainingSeconds -= 1

            if self.remainingSeconds <= 0 {
                timer.invalidate()
                self.timerExpired()
                return
            }

            self.updateTimerLabel()
        }
    }

    private func updateTimerLabel() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        _ = "\(String(format: "%01d", minutes)):\(String(format: "%02d", seconds))"
    }

    private func timerExpired() {
        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            self.countdownTimer?.invalidate()
            self.cancelBooking()
            self.updateDelegate?.update()
            self.navigationController?.popViewController(animated: true)
        }

        Alert.showAlertSheet(
            style: .alert,
            title: "Sorry, your ticket reservation has expired, please try again",
            message: "",
            actions: [okAction]
        )
    }

    @objc private func enterBackGround() {
        enterBgDate = Date()
    }

    @objc private func exitBackGround() {
        if isFromApplePay {
            isFromApplePay = false
            return
        }

        exitBgDate = Date()

        let diff = exitBgDate.timeIntervalSince(enterBgDate)
        enterBgDate = exitBgDate
        remainingSeconds -= Int(diff)

        if remainingSeconds < 0 {
            remainingSeconds = 0
        }

        updateTimerLabel()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension CoverTicketCheckOutVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        if tableView == self.tableView {
            return selectedCoverTickets.count
        } else if tableView == coverTicketFeesAndTaxTableView {
            return feesAndTaxes.count
        } else if tableView == upsellTicketTableView {
            return selectedAddOnsItems.count
        } else if tableView == upsellTicketFeesAndTaxTableView {
            return upsellFeesAndTaxes.count
        }

        return 0
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        if tableView == self.tableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: OrderItemTableViewCell.identifier,
                for: indexPath
            ) as? OrderItemTableViewCell else {
                return UITableViewCell()
            }

            let ticket = selectedCoverTickets[indexPath.row]
            let quantity = ticket.selectedQuantity ?? 0
            let total = Double(quantity) * ticket.price

            cell.selectionStyle = .none
            cell.totalTicketCountLbl.text = "\(quantity)x"
            cell.ticketNameLbl.text = ticket.customName?.isEmpty == false
                ? ticket.customName
                : ticket.name
            cell.priceLbl.text = total <= 0
                ? "Free"
                : "\(currency)\(total.decimalFormat(true))"
            cell.extraFeesLbl.text = ""

            return cell
        }

        if tableView == coverTicketFeesAndTaxTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketItemTableViewCell.identifier,
                for: indexPath
            ) as? TicketItemTableViewCell else {
                return UITableViewCell()
            }

            let item = feesAndTaxes[indexPath.row]

            cell.selectionStyle = .none
            cell.titleLbl.text = item.title
            cell.amountLbl.text = "\(currency)\(item.amount.decimalFormat(true))"

            return cell
        }

        if tableView == upsellTicketTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: OrderItemTableViewCell.identifier,
                for: indexPath
            ) as? OrderItemTableViewCell else {
                return UITableViewCell()
            }

            let item = selectedAddOnsItems[indexPath.row]
            let quantity = item.selectedQuantity ?? 0
            let total = Double(quantity) * item.calculatedNetPrice

            cell.selectionStyle = .none
            cell.totalTicketCountLbl.text = "\(quantity)x"
            cell.ticketNameLbl.text = item.addOns?.name ?? ""
            cell.priceLbl.text = total <= 0
                ? "Free"
                : "\(currency)\(total.decimalFormat(true))"
            cell.extraFeesLbl.text = ""

            return cell
        }

        if tableView == upsellTicketFeesAndTaxTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketItemTableViewCell.identifier,
                for: indexPath
            ) as? TicketItemTableViewCell else {
                return UITableViewCell()
            }

            let item = upsellFeesAndTaxes[indexPath.row]

            cell.selectionStyle = .none
            cell.titleLbl.text = item.title
            cell.amountLbl.text = "\(currency)\(item.amount.decimalFormat(true))"

            return cell
        }

        return UITableViewCell()
    }
}

// MARK: - WebSocket
extension CoverTicketCheckOutVC: WebSocketCallBackDelegate {

    func didValueChange(
        venueId: String,
        uniqueId: String,
        isPriceUpdated: Bool
    ) {
        if isPaymentInitiated { return }

        guard navigationController?.viewControllers.last is CoverTicketCheckOutVC,
              venue?.uniqueId ?? "" == uniqueId else {
            return
        }

        if isPriceUpdated {
            Alert.showAlertSheet(
                style: .alert,
                title: "Update",
                message: "The venue updated their prices",
                actions: [popAction()]
            )
        }
    }

    func updateTicketPrice(ticket: [CoverTicket]) {
        if isPaymentInitiated || selectedCoverTickets.isEmpty { return }

        let matched = ticket.filter { ticket in
            selectedCoverTickets.contains(where: { $0.id == ticket.id })
        }

        if !matched.isEmpty {
            Alert.showAlertSheet(
                style: .alert,
                title: "Update",
                message: "The venue updated their prices",
                actions: [popAction()]
            )
        }
    }

    func updateAddOnsTicketPrice(ticket: [UpSellTicket]) {
        if isPaymentInitiated || selectedAddOnsItems.isEmpty { return }

        let matched = ticket.filter { ticket in
            selectedAddOnsItems.contains(where: { $0.id == ticket.id })
        }

        if !matched.isEmpty {
            Alert.showAlertSheet(
                style: .alert,
                title: "Update",
                message: "The venue updated their prices",
                actions: [popAction()]
            )
        }
    }

    func updateVenueStatus(venueId: String, venueStatus: String) {
        Alert.showAlertSheet(
            style: .alert,
            title: "Update",
            message: "Venue your trying to close booking",
            actions: [popAction()]
        )
    }

    func didGenderWiseTicketChange(
        venueId: String,
        uniqueId: String
    ) {
        if isPaymentInitiated { return }

        guard navigationController?.viewControllers.last is CoverTicketCheckOutVC,
              venue?.uniqueId ?? "" == uniqueId else {
            return
        }

        Alert.showAlertSheet(
            style: .alert,
            title: "Update",
            message: "Venue your trying to booking, updated it's ticket",
            actions: [popAction()]
        )
    }

    private func popAction() -> UIAlertAction {
        UIAlertAction(title: "OK", style: .default) { _ in
            if let vc = self.navigationController?.viewControllers.first(where: {
                $0.isKind(of: MVPVenueListVc.self)
            }) {
                self.navigationController?.popToViewController(vc, animated: true)
            } else if let vc = self.navigationController?.viewControllers.first(where: {
                $0.isKind(of: MVPVenueDetailVc.self)
            }) {
                self.navigationController?.popToViewController(vc, animated: true)
            }
        }
    }
}

extension CoverTicketCheckOutVC: CheckoutBarDelegate {

    func checkoutBarDidTapButton() {
        onClickContinueToCheckout()
    }
}

