//
//  CoverTicketCheckOutVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 31/03/26.
//

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet
import MHLoadingButton

final class CoverTicketCheckOutVC: UIViewController, ApplePayContextDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var totalAmountLbl: UILabel!
    @IBOutlet weak var feesAndTxtTotalAmountLbl: UILabel!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feesAndTaxesTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feesAndTaxesTableView: UITableView!
    @IBOutlet weak var purchaseTicketBtn: UIButton!
    @IBOutlet weak var timerLbl: UILabel!
    @IBOutlet weak var promoCodeTextFeild: UITextField!
    @IBOutlet weak var promoCodeView: UIView!
    @IBOutlet weak var discountView: UIView!
    @IBOutlet weak var feesAndTaxesTitleView: UIView!
    @IBOutlet weak var feesAndTaxesContainerView: UIView!
    @IBOutlet weak var discountToalLbl: UILabel!
    @IBOutlet weak var shimmerView: UIView!
    @IBOutlet weak var feesDropDowenIc: UIImageView!
    @IBOutlet weak var addPromoCodeBtn: LoadingButton!
    @IBOutlet weak var privacyPolicyLbl: UILabel!
    @IBOutlet weak var checkBox: UIButton!
    @IBOutlet weak var promoCodeParentView: UIView!
    @IBOutlet weak var feesAndTaxesParentTableView: UIView!
    @IBOutlet weak var coverTicketStackView: UIStackView!
    @IBOutlet weak var upSellTicketStackView: UIStackView!
    @IBOutlet weak var upSellTicketsTableView: UITableView!
    @IBOutlet weak var upSellFeesAndTaxDropDownIc: UIImageView!
    @IBOutlet weak var upSellFeesAndTaxTableView: UITableView!
    @IBOutlet weak var upSellTotalLbl: UILabel!
    @IBOutlet weak var upSellfeesAndTaxesContainerView: UIView!
    @IBOutlet weak var upSellfeesAndTaxesTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var upSellTicketsTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var coverTicketTotal: UILabel!
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var mainContentView: UIStackView!
    @IBOutlet weak var upSellStackView: UIStackView!
    @IBOutlet weak var totalView: UIView!
    
    // MARK: - Data
    var selectedCoverTickets: [CoverTicket] = []
    var selectedAddOnsItem: [UpSellTicket] = []
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
    private var addOnsPaymentDetails: PaymentDetail?
    private var selectedId = Constant.String.defaultSelectedPM
    private var bookingId = ""
    private var addOnsBookingId: String?

    // MARK: - State
    private var isPromoCodeApplied = false
    private var appliedPromoCode = ""
    private var isFreeTicket = false
    private var isPaymentInitiated = false
    private var isFromApplePay = false

    private var countdownTimer: Timer?
    private var remainingSeconds: Int = 10 * 60
    private var enterBgDate = Date()
    private var exitBgDate = Date()

    private var feesAndTaxes: [FeeDisplayItem] = []
    private var upSellFeesAndTaxes: [FeeDisplayItem] = []

    private var ticketHeightObservation: NSKeyValueObservation?
    private var feeHeightObservation: NSKeyValueObservation?

    private var isBookingLoaded = false
    private var isPaymentIntentLoaded = false
    
    private var shimmerBlocks: [ShimmerView] = []

    private var currency: String {
        venue?.venueSettings?.currencySymbol ?? "$"
    }

    private var isApplePayNotSupported: Bool {
        !PKPaymentAuthorizationViewController.canMakePayments()
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTableViews()
        setupHeaderData()
        calculateBaseSubtotal()
//        startCountdown()
        showCheckoutShimmer()

        if !selectedCoverTickets.isEmpty && bookingType != .FREE {
            createBooking()
        } else {
            getAddOnsPaymentIntent(bookingId: "")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.addTarget(self, action: #selector(handleBackSwipe))
        WebSocketWrapper.shared.delegate.append(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.removeTarget(self, action: #selector(handleBackSwipe))
        WebSocketWrapper.shared.delegate.removeAll(where: { $0 as? NSObject == self })
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        countdownTimer?.invalidate()
        tableView.removeObserver(self, forKeyPath: "contentSize")
        feesAndTaxesTableView.removeObserver(self, forKeyPath: "contentSize")
        upSellTicketsTableView.removeObserver(self, forKeyPath: "contentSize")
        upSellFeesAndTaxTableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    private func setupUI() {
        addPromoCodeBtn.indicator = MaterialLoadingIndicator(color: .white)
        addPromoCodeBtn.bgColor = .clear

        purchaseTicketBtn.alpha = 0.5
        purchaseTicketBtn.isUserInteractionEnabled = false

        promoCodeView.isHidden = true
        discountView.isHidden = true

        checkBox.setImage(UIImage(named: "ic_checkbox_unchecked"), for: .normal)
        checkBox.setImage(UIImage(named: "checkBox"), for: .selected)
        checkBox.isSelected = true
        
        let imageUrlString = "\(SharedURL.amazonStorage)\(venue?.venueAttachment?.first?.key ?? "")"
        if let url = URL(string: imageUrlString) {
            bgImage.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "newSpeakeasy")
            )
        } else {
            bgImage.image = UIImage(named: "newSpeakeasy")
        }

        promoCodeTextFeild.addTarget(self, action: #selector(promoCodeValueChange), for: .editingChanged)
        updatePromoButtonIcon()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enterBackGround),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(exitBackGround),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enterBackGround),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(exitBackGround),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    private func setupTableViews() {
        tableView.delegate = self
        tableView.dataSource = self
        feesAndTaxesTableView.delegate = self
        feesAndTaxesTableView.dataSource = self

        upSellTicketsTableView.delegate = self
        upSellTicketsTableView.dataSource = self
        upSellFeesAndTaxTableView.delegate = self
        upSellFeesAndTaxTableView.dataSource = self

        tableView.register(TicketItemTableViewCell.nib,
                           forCellReuseIdentifier: TicketItemTableViewCell.identifier)

        feesAndTaxesTableView.register(TicketItemTableViewCell.nib,
                                       forCellReuseIdentifier: TicketItemTableViewCell.identifier)

        upSellTicketsTableView.register(TicketItemTableViewCell.nib,
                                        forCellReuseIdentifier: TicketItemTableViewCell.identifier)

        upSellFeesAndTaxTableView.register(TicketItemTableViewCell.nib,
                                           forCellReuseIdentifier: TicketItemTableViewCell.identifier)

        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        feesAndTaxesTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        upSellTicketsTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        upSellFeesAndTaxTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }

    private func setupHeaderData() {
        venueLogoImg.sd_setImage(
            with: URL(string: (venue?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueName.text = venue?.name ?? ""
        dateandtimeLbl.text = ""

        privacyPolicyLbl.text = "I agree to receive marketing related text messages from \(venue?.name ?? ""). Msg & data rates may apply. Reply STOP to opt out or HELP for support."

//        promoCodeParentView.isHidden = bookingType == .FREE || selectedCoverTickets.isEmpty
        feesAndTaxesParentTableView.isHidden = selectedCoverTickets.isEmpty

        coverTicketStackView.isHidden = selectedCoverTickets.isEmpty
        upSellTicketStackView.isHidden = selectedAddOnsItem.isEmpty

        purchaseTicketBtn.setTitle(bookingType == .FREE ? "REDEEM TICKETS" : "BUY TICKETS", for: .normal)

        if let colorHex = venue?.venueSettings?.whiteLabelColor {
            
            let bgColor = UIColor(hex: colorHex)
            
            purchaseTicketBtn.backgroundColor = bgColor
            purchaseTicketBtn.setTitleColor(bgColor.suitableTextColor(), for: .normal)
        }
    }

    private func calculateBaseSubtotal() {
        let coverSubtotal = selectedCoverTickets.reduce(0.0) { result, ticket in
            let quantity = ticket.selectedQuantity ?? 0
            let price = ticket.price
            return result + (Double(quantity) * price)
        }

        let upSellSubtotal = selectedAddOnsItem.reduce(0.0) { result, item in
            let quantity = item.selectedQuantity ?? 0
            let price = item.calculatedNetPrice
            return result + (Double(quantity) * price)
        }

        let grandTotal = coverSubtotal + upSellSubtotal
        coverTicketTotal.text = coverSubtotal == 0 ? "Free" : "\(currency)\(coverSubtotal.decimalFormat(true))"
        totalAmountLbl.text = grandTotal == 0 ? "Free" : "\(currency)\(grandTotal.decimalFormat(true))"
        upSellTotalLbl.text = upSellSubtotal == 0 ? "Free" : "\(currency)\(upSellSubtotal.decimalFormat(true))"
        isFreeTicket = grandTotal == 0
    }
    
    private func showCheckoutShimmer() {
        shimmerView.isHidden = false
        mainContentView.isHidden = true
        upSellStackView.isHidden = true
        totalView.isHidden = true
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

        func makeBlock(height: CGFloat, width: CGFloat? = nil, corner: CGFloat = 8) -> ShimmerView {
            let view = ShimmerView()
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

        let line1 = UIView()
        line1.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        line1.translatesAutoresizingMaskIntoConstraints = false
        line1.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        stack.addArrangedSubview(line1)

        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.alignment = .center
        row1.distribution = .equalSpacing
        row1.addArrangedSubview(makeBlock(height: 14, width: 120))
        row1.addArrangedSubview(makeBlock(height: 14, width: 58))
        stack.addArrangedSubview(row1)

        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.alignment = .center
        row2.distribution = .equalSpacing
        row2.addArrangedSubview(makeBlock(height: 14, width: 120))
        row2.addArrangedSubview(makeBlock(height: 14, width: 58))
        stack.addArrangedSubview(row2)

        let line2 = UIView()
        line2.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        line2.translatesAutoresizingMaskIntoConstraints = false
        line2.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        stack.addArrangedSubview(line2)

        let row3 = UIStackView()
        row3.axis = .horizontal
        row3.alignment = .center
        row3.distribution = .equalSpacing
        row3.addArrangedSubview(makeBlock(height: 14, width: 100))
        row3.addArrangedSubview(makeBlock(height: 14, width: 48))
        stack.addArrangedSubview(row3)

        shimmerBlocks.forEach { $0.startAnimating() }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let table = object as? UITableView {
            if table == self.tableView {
                tableViewHeight.constant = table.contentSize.height
            } else if table == self.feesAndTaxesTableView {
                feesAndTaxesTableViewHeight.constant = table.contentSize.height
            } else if table == self.upSellTicketsTableView {
                upSellTicketsTableViewHeight.constant = table.contentSize.height
            } else if table == self.upSellFeesAndTaxTableView {
                upSellfeesAndTaxesTableViewHeight.constant = table.contentSize.height
            }
        }
    }
    
    private func hideCheckoutShimmerIfNeeded() {

        if bookingType == .FREE {
            guard isBookingLoaded else { return }
        } else {
            guard isBookingLoaded, isPaymentIntentLoaded else { return }
        }

        shimmerBlocks.forEach { $0.stopAnimating() }
        mainContentView.isHidden = false
        shimmerView.isHidden = true
        totalView.isHidden = false
    }
    
    @IBAction func onClickUpSellFeesAndTaxes(_ sender: Any) {
        let isHidden = upSellfeesAndTaxesContainerView.isHidden
        upSellfeesAndTaxesContainerView.isHidden.toggle()

        UIView.animate(withDuration: 0.25) {
            self.upSellFeesAndTaxDropDownIc.transform = isHidden
                ? CGAffineTransform(rotationAngle: .pi)
                : .identity
        }
    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        cancelBooking()
    }
    
    @IBAction func onClickFeesAndTaxesBtn(_ sender: Any) {
        let isHidden = feesAndTaxesContainerView.isHidden
        feesAndTaxesContainerView.isHidden.toggle()

        UIView.animate(withDuration: 0.25) {
            self.feesDropDowenIc.transform = isHidden
                ? CGAffineTransform(rotationAngle: .pi)
                : .identity
        }
    }
}

extension CoverTicketCheckOutVC {

    private func startCountdown() {
        updateTimerLabel()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
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
//        timerLbl.text = "\(String(format: "%01d", minutes)):\(String(format: "%02d", seconds))"
    }

    private func timerExpired() {
        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            self.countdownTimer?.invalidate()
            self.cancelBooking()
            self.updateDelegate?.update()
            self.navigationController?.popViewController(animated: true)
        }

        Alert.showAlertSheet(style: .alert,
                             title: "Sorry, your ticket reservation has expired, please try again",
                             message: "",
                             actions: [okAction])
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
        if remainingSeconds < 0 { remainingSeconds = 0 }
        updateTimerLabel()
    }

    @objc private func handleBackSwipe() {
        navigationController?.interactivePopGestureRecognizer?.removeTarget(self, action: #selector(handleBackSwipe))
        cancelBooking()
    }
    
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
            self.purchaseTicketBtn.alpha = 1
            self.purchaseTicketBtn.isUserInteractionEnabled = true
        }
    }
}

extension CoverTicketCheckOutVC {

    private func createBooking() {
        var tickets = [[String: Any]]()

        selectedCoverTickets.forEach {
            tickets.append([
                "ticketId": $0.id,
                "ticketQuantity": $0.selectedQuantity ?? 0
            ])
        }

        PaymentPresenter.createCoverBooking(coverTickets: tickets, venueId: venue?.id ?? "") { [weak self] isSuccess, errMsg, id, _ in
            guard let self = self else {
                return
            }

            if isSuccess, let id = id {
                self.bookingId = id
                self.isBookingLoaded = true
                self.fetchPaymentIntentAndSetup(promoCode: self.isPromoCodeApplied ? self.appliedPromoCode : "")
            } else {
                self.isBookingLoaded = true
                self.hideCheckoutShimmerIfNeeded()
                Alert.showAlertSheet(style: .alert,
                                     title: errMsg ?? Constant.String.somethingWrong,
                                     message: "")
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

                if self.selectedAddOnsItem.isEmpty {
                    self.setupStripePaymentSheet()
                    self.updateUIWithPaymentDetail()
                    self.isPaymentIntentLoaded = true
                    self.hideCheckoutShimmerIfNeeded()
                } else {
                    self.getAddOnsPaymentIntent(bookingId: self.bookingId)
                }
            } else {
                self.isPaymentIntentLoaded = true
                self.hideCheckoutShimmerIfNeeded()
                if self.isPromoCodeApplied {
                    self.isPromoCodeApplied = false
                }
                Alert.showAlertSheet(style: .alert,
                                     title: errMsg ?? Constant.String.somethingWrong,
                                     message: "")
            }
        }
    }

    private func getAddOnsPaymentIntent(bookingId: String) {

        let addOnsItems: [[String: Any]] = selectedAddOnsItem.map {
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
                self.addOnsPaymentDetails = paymentDetail
                self.addOnsBookingId = bookingId

                if self.selectedCoverTickets.isEmpty {
                    self.paymentIntent = clientSecret ?? ""
                    self.ephemeralKey = ephemeralKey
                }

                self.setupStripePaymentSheet()
                self.updateUIWithPaymentDetail()
                self.isBookingLoaded = true
                self.isPaymentIntentLoaded = true
                self.hideCheckoutShimmerIfNeeded()
            } else {
                self.isBookingLoaded = true
                self.isPaymentIntentLoaded = true
                self.hideCheckoutShimmerIfNeeded()
                Alert.showAlertSheet(style: .alert,
                                     title: errMsg ?? Constant.String.somethingWrong,
                                     message: "")
            }
        }
    }
}

extension CoverTicketCheckOutVC {

    private func buildFeesArray(from detail: PaymentDetail?) -> [FeeDisplayItem] {
        var items: [FeeDisplayItem] = []

        guard let detail = detail else { return [] }
        
        let subtotal = detail.subTotal
        if subtotal > 0 {
            items.append(FeeDisplayItem(title: "Subtotal", amount: subtotal))
        }
         
        if let customFees = detail.customFees, !customFees.isEmpty {
            customFees.forEach {
                items.append(FeeDisplayItem(title: $0.name, amount: $0.fee ?? 0))
            }
        } else if detail.customFee > 0 {
            items.append(FeeDisplayItem(title: detail.customFeeName ?? "Custom Fee", amount: detail.customFee))
        }

        if (detail.salesTax ?? 0) > 0 {
            items.append(FeeDisplayItem(title: detail.salesTaxName ?? "Sales Tax", amount: detail.salesTax ?? 0))
        }

        if detail.processingFee > 0 {
            items.append(FeeDisplayItem(title: "Processing Fee", amount: detail.processingFee))
        }

        return items
    }

    private func updateUIWithPaymentDetail() {
        feesAndTaxes = buildFeesArray(from: paymentDetail)
        upSellFeesAndTaxes = buildFeesArray(from: addOnsPaymentDetails)

        let coverTotal = paymentDetail?.total ?? 0
        let coverSubTotal = paymentDetail?.subTotal ?? 0
        let coverFeesTotal = max(0, coverTotal - coverSubTotal)

        let upSellTotal = addOnsPaymentDetails?.total ?? 0
        let upSellSubTotal = addOnsPaymentDetails?.subTotal ?? 0
        let upSellFeesTotal = max(0, upSellTotal - upSellSubTotal)

        let grandTotal = coverTotal + upSellTotal
        self.totalPrice = grandTotal

        coverTicketStackView.isHidden = selectedCoverTickets.isEmpty
        feesAndTaxesParentTableView.isHidden = selectedCoverTickets.isEmpty || feesAndTaxes.isEmpty
        upSellTicketStackView.isHidden = selectedAddOnsItem.isEmpty
        upSellfeesAndTaxesContainerView.superview?.isHidden = selectedAddOnsItem.isEmpty

        totalAmountLbl.text = grandTotal <= 0 ? "Free" : "\(currency)\(grandTotal.decimalFormat(true))"
        feesAndTxtTotalAmountLbl.text = coverFeesTotal <= 0 ? "" : "\(currency)\(coverFeesTotal.decimalFormat(true))"
        coverTicketTotal.text = coverTotal <= 0 ? "Free" : "\(currency)\(coverTotal.decimalFormat(true))"

        upSellTotalLbl.text = upSellTotal <= 0 ? "Free" : "\(currency)\(upSellTotal.decimalFormat(true))"

        let discount = paymentDetail?.discount ?? 0
        if discount > 0 {
            discountView.isHidden = false
            discountToalLbl.text = "-\(currency)\(discount.decimalFormat(true))"
        } else {
            discountView.isHidden = true
        }
        upSellfeesAndTaxesContainerView.superview?.isHidden = selectedAddOnsItem.isEmpty
        upSellTicketStackView.isHidden = selectedAddOnsItem.isEmpty || upSellFeesAndTaxes.isEmpty

        tableView.reloadData()
        feesAndTaxesTableView.reloadData()
        upSellTicketsTableView.reloadData()
        upSellFeesAndTaxTableView.reloadData()
    }
}

extension CoverTicketCheckOutVC {

    @objc private func promoCodeValueChange() {
        let hasText = !(promoCodeTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        addPromoCodeBtn.alpha = hasText || isPromoCodeApplied ? 1 : 0.5
        addPromoCodeBtn.isUserInteractionEnabled = hasText || isPromoCodeApplied
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
    }

    @IBAction func onClickAddPromoCode(_ sender: Any) {
        promoCodeView.isHidden.toggle()
    }

    @IBAction func onClickSubmitPromo(_ sender: Any) {
        let promo = (promoCodeTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        addPromoCodeBtn.showLoader(userInteraction: false)

        if isPromoCodeApplied {
            isPromoCodeApplied = false
            appliedPromoCode = ""
            promoCodeTextFeild.text = ""
            promoCodeTextFeild.isUserInteractionEnabled = true
            promoCodeTextFeild.alpha = 1
            updatePromoButtonIcon()

            fetchPaymentIntentAndSetup(promoCode: "")

            addPromoCodeBtn.hideLoader()
            return
        }

        guard !promo.isEmpty else {
            addPromoCodeBtn.hideLoader()
            return
        }

        appliedPromoCode = promo
        isPromoCodeApplied = true
        promoCodeTextFeild.isUserInteractionEnabled = false
        promoCodeTextFeild.alpha = 0.5
        updatePromoButtonIcon()

        fetchPaymentIntentAndSetup(promoCode: promo)
        addPromoCodeBtn.hideLoader()
    }
}

extension CoverTicketCheckOutVC {

    @IBAction func onClickPurchaseTicket(_ sender: Any) {
        if isPaymentInitiated { return }
        isPaymentInitiated = true

        if isFreeTicket || bookingType == .FREE {
            isPaymentInitiated = false
            createFreeBookingIfNeeded()
            return
        }

        guard let paymentSheet = paymentSheet else {
            isPaymentInitiated = false
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
                Alert.showAlertSheet(style: .alert, title: "Payment failed", message: "")
            }
        }
    }

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

        if selectedCoverTickets.isEmpty && !selectedAddOnsItem.isEmpty {
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

        paymentStatus(optedPolicy: venue?.venueSettings?.optedPolicy == true ? checkBox.isSelected : nil) {
            if self.selectedAddOnsItem.isEmpty {
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
                        addOnsBookingId: self.addOnsBookingId ?? ""
                    )
                }
            }
        }
    }

    private func createFreeBookingIfNeeded() {
        if selectedCoverTickets.isEmpty && !selectedAddOnsItem.isEmpty {
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
        } else {
            createFreeBooking {
                if self.selectedAddOnsItem.isEmpty {
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
    }
}

extension CoverTicketCheckOutVC {

    private func paymentStatus(optedPolicy: Bool? = nil, completion: @escaping (() -> Void)) {
        PaymentPresenter.successPayment(paymentHistoryId: paymentHistoryId, bookingId: bookingId, optedPolicy: optedPolicy) { isSuccess, errMsg in
            if isSuccess {
                completion()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    private func addOnsPaymentSuccess(completion: @escaping (() -> Void)) {
        var mainBookingId = ""
        if bookingType == .FREE {
            mainBookingId = bookingId
        }

        PaymentPresenter.successAddOnsPayment(bookingId: addOnsBookingId ?? "", mainBookingId: mainBookingId) { isSuccess, errMsg in
            if isSuccess {
                completion()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
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

        PaymentPresenter.createCoverFreeBooking(coverTickets: appClipTickets, venueId: venue?.id ?? "") { [weak self] isSuccess, errMsg, id, _ in
            guard let self = self else { return }

            if isSuccess, let id = id {
                self.bookingId = id
                completion()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    private func cancelBooking() {
        countdownTimer?.invalidate()
        PaymentPresenter.cancelBooking(bookingId: bookingId) { _, _ in
            self.navigationController?.popToRootViewController(animated: false)
        }
    }
}

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

        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            applePayContext.presentApplePay()
        } else {
            Alert.showToast("Problem with your Apple Pay")
        }
    }

    private func alertForWallet() {
        let title = isApplePayNotSupported ? Constant.String.notSupported : Constant.String.addCardToApplePay
        let message = isApplePayNotSupported ? Constant.String.applePayNotSupported : Constant.String.addCardToYourApplePayWallet

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.isFromApplePay = true
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

    func applePayContext(_ context: STPApplePayContext,
                         didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
                         paymentInformation: PKPayment,
                         completion: @escaping STPIntentClientSecretCompletionBlock) {
        completion(paymentIntent, nil)
    }

    func applePayContext(_ context: STPApplePayContext,
                         didCompleteWith status: STPApplePayContext.PaymentStatus,
                         error: Error?) {
        switch status {
        case .success:
            handleSuccessfulCardPayment()
        case .error:
            isFromApplePay = true
            isPaymentInitiated = false
            Alert.showAlertSheet(style: .alert, title: "Payment failed", message: "")
        case .userCancellation:
            isFromApplePay = true
            isPaymentInitiated = false
        }
    }
}

extension CoverTicketCheckOutVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return selectedCoverTickets.count
        } else if tableView == self.feesAndTaxesTableView {
            return feesAndTaxes.count
        } else if tableView == self.upSellTicketsTableView {
            return selectedAddOnsItem.count
        } else if tableView == self.upSellFeesAndTaxTableView {
            return upSellFeesAndTaxes.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TicketItemTableViewCell.identifier,
            for: indexPath
        ) as? TicketItemTableViewCell else {
            return UITableViewCell()
        }

        cell.selectionStyle = .none

        if tableView == self.tableView {
            let ticket = selectedCoverTickets[indexPath.row]
            let quantity = ticket.selectedQuantity ?? 0
            let price = ticket.price
            let total = Double(quantity) * price

            cell.titleLbl.text = "\(quantity)x \(ticket.customName?.isEmpty == false ? (ticket.customName ?? "") : ticket.name)"
            cell.amountLbl.text = total <= 0 ? "Free" : "\(currency)\(total.decimalFormat(true))"

        } else if tableView == self.feesAndTaxesTableView {
            let item = feesAndTaxes[indexPath.row]
            cell.titleLbl.text = item.title
            cell.amountLbl.text = "\(currency)\(item.amount.decimalFormat(true))"

        } else if tableView == self.upSellTicketsTableView {
            let item = selectedAddOnsItem[indexPath.row]
            let quantity = item.selectedQuantity ?? 0
            let price = item.calculatedNetPrice
            let total = Double(quantity) * price

            cell.titleLbl.text = "\(quantity)x \(item.addOns?.name ?? "")"
            cell.amountLbl.text = total <= 0 ? "Free" : "\(currency)\(total.decimalFormat(true))"

        } else if tableView == self.upSellFeesAndTaxTableView {
            let item = upSellFeesAndTaxes[indexPath.row]
            cell.titleLbl.text = item.title
            cell.amountLbl.text = "\(currency)\(item.amount.decimalFormat(true))"
        }

        return cell
    }
}

extension CoverTicketCheckOutVC: WebSocketCallBackDelegate {

    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool) {
        if isPaymentInitiated { return }

        if self.navigationController?.viewControllers.last is CoverTicketCheckOutVC,
           venue?.uniqueId ?? "" == uniqueId {

            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueListVc.self) }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                } else if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueDetailVc.self) }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                }
            }

            if isPriceUpdated {
                Alert.showAlertSheet(style: .alert,
                                     title: "Update",
                                     message: "The venue updated their prices",
                                     actions: [okAction])
            }
        }
    }

    func updateTicketPrice(ticket: [CoverTicket]) {
        if isPaymentInitiated { return }
        if selectedCoverTickets.isEmpty { return }

        var coverTickets = [CoverTicket]()
        ticket.forEach { tick in
            coverTickets = selectedCoverTickets.filter { $0.id == tick.id }
        }

        if !coverTickets.isEmpty {
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueListVc.self) }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                } else if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueDetailVc.self) }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                }
            }

            Alert.showAlertSheet(style: .alert,
                                 title: "Update",
                                 message: "The venue updated their prices",
                                 actions: [okAction])
        }
    }

    func updateAddOnsTicketPrice(ticket: [UpSellTicket]) {
        if isPaymentInitiated { return }
        if selectedAddOnsItem.isEmpty { return }

        var upSellTickets = [UpSellTicket]()
        ticket.forEach { tick in
            upSellTickets = selectedAddOnsItem.filter { $0.id == tick.id }
        }

        if !upSellTickets.isEmpty {
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueListVc.self) }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                } else if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueDetailVc.self) }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                }
            }

            Alert.showAlertSheet(style: .alert,
                                 title: "Update",
                                 message: "The venue updated their prices",
                                 actions: [okAction])
        }
    }

    func updateVenueStatus(venueId: String, venueStatus: String) {
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueListVc.self) }) {
                self.navigationController?.popToViewController(vc, animated: true)
            } else if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueDetailVc.self) }) {
                self.navigationController?.popToViewController(vc, animated: true)
            }
        }

        Alert.showAlertSheet(style: .alert,
                             title: "Update",
                             message: "Venue your trying to close booking",
                             actions: [okAction])
    }

    func didGenderWiseTicketChange(venueId: String, uniqueId: String) {
        if isPaymentInitiated { return }

        if self.navigationController?.viewControllers.last is CoverTicketCheckOutVC,
           venue?.uniqueId ?? "" == uniqueId {

            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueListVc.self) }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                } else if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: MVPVenueDetailVc.self) }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                }
            }

            Alert.showAlertSheet(style: .alert,
                                 title: "Update",
                                 message: "Venue your trying to booking, updated it's ticket",
                                 actions: [okAction])
        }
    }
}
