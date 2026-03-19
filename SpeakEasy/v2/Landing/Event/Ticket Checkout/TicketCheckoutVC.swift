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

final class TicketCheckoutVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueName2: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var totalAmountLbl: UILabel!
    @IBOutlet weak var feesAndTxtTotalAmountLbl: UILabel!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feesAndTaxesTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feesAndTaxesTableView: UITableView!
    @IBOutlet weak var purchaseTicketBtn: UIButton!
    @IBOutlet weak var timerLbl: UILabel!
    @IBOutlet weak var promoCodeTextFeild: UITextField!
    @IBOutlet weak var submitPromoBtn: UIButton!
    @IBOutlet weak var promoCodeView: UIView!
    @IBOutlet weak var discountView: UIView!
    @IBOutlet weak var feesAndTaxesTitleView: UIView!
    @IBOutlet weak var feesAndTaxesContainerView: UIView!
    @IBOutlet weak var discountToalLbl: UILabel!
    @IBOutlet weak var shimmerView: UIView!
    @IBOutlet weak var feesDropDowenIc: UIImageView!
    @IBOutlet weak var addPromoCodeBtn: LoadingButton!
    
    var selectedTickets: [EventTicket] = []
    var venueDetails: ClipVenue?
    var event: Event?
    var booking: Booking?
    var bookingId: String?

    private var countdownTimer: Timer?
    private var remainingSeconds: Int = 5 * 60

    private var feesAndTaxes: [FeeDisplayItem] = []

    private var isPromoCodeApplied = false
    private var appliedPromoCode: String = ""

    private var currency: String {
        return venueDetails?.venueSettings?.currencySymbol ?? "$"
    }

    private var paymentSheet: PaymentSheet?
    private var paymentIntentClientSecret: String = ""
    private var paymentHistoryId: String = ""
    private var ephemeralKey: String = ""
    private var paymentDetail: PaymentDetail?
    private var isFreeTicket: Bool = false
    private var isPaymentInitiated = false
    private var isLoading = false
    private var shimmerBlocks: [ShimmerView] = []
    private var isBookingLoaded = false
    private var isPaymentIntentLoaded = false

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
        
        addPromoCodeBtn.indicator = MaterialLoadingIndicator(color: .white)
        addPromoCodeBtn.bgColor = .clear
        updatePromoButtonIcon()

        setupHeaderData()
        startCountdown()
        calculateTotal()
        showCheckoutShimmer()
        getBooking(id: bookingId)

        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        feesAndTaxesTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)

        fetchPaymentIntentAndSetup(promoCode: "")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.addTarget(self, action: #selector(handleBackSwipe))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.removeTarget(self, action: #selector(handleBackSwipe))
    }

    deinit {
        countdownTimer?.invalidate()
        tableView.removeObserver(self, forKeyPath: "contentSize")
        feesAndTaxesTableView.removeObserver(self, forKeyPath: "contentSize")
    }

    private func setupHeaderData() {
        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueName.text = venueDetails?.name
        venueName2.text = venueDetails?.name
        eventTitleLbl.text = event?.title
    }

    private func getBooking(id: String?) {
        
        guard let id = id else {
            isBookingLoaded = true
            hideCheckoutShimmerIfNeeded()
            return
        }
        
        if booking == nil {  }
        
        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, _, booking in
            guard let self = self else { return }
            if isSuccess {
                self.booking = booking
                self.reloadFeesUIFromBooking()
            }
            self.isBookingLoaded = true
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
    }

    private func calculateTotal() {
        let subtotal = selectedTickets.reduce(0.0) { result, ticket in
            let quantity = ticket.selectedTicketCount ?? 0
            let price = ticket.price ?? 0
            return result + (Double(quantity) * price)
        }
        
        
        
        

        totalAmountLbl.text = subtotal == 0 ? "Free" : "\(currency)\(subtotal.decimalFormat(true))"

        if let hex = event?.whiteLabelColor {
            let color = UIColor(hex: hex)
            dateandtimeLbl.textColor = color
            purchaseTicketBtn.backgroundColor = color
        }

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
            self.cancelBooking()
            Navigate.to.back(self)
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

        PaymentPresenter.getPaymentIntent(
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

            self.purchaseTicketBtn.isUserInteractionEnabled = true
            self.purchaseTicketBtn.alpha = 1
        }
    }

    private func updateUIWithPaymentDetail(_ detail: PaymentDetail?) {

        guard let detail = detail else {
            feesAndTaxes = []
            feesAndTaxesTitleView.isHidden = true
            feesAndTaxesTableView.reloadData()
            totalAmountLbl.text = "Free"
            feesAndTxtTotalAmountLbl.text = ""
            discountView.isHidden = true
            discountToalLbl.isHidden = true
            return
        }
        feesAndTaxes = buildFeesArray(from: detail)
        feesAndTaxesTitleView.isHidden = feesAndTaxes.isEmpty
        feesAndTaxesTableView.reloadData()

        let total = detail.total
        let subTotal = detail.subTotal   

        let feesAmount = total - subTotal

        if total <= 0 {
            totalAmountLbl.text = "Free"
            feesAndTxtTotalAmountLbl.text = ""
        } else {
            totalAmountLbl.text = "\(currency)\(total.decimalFormat(true))"
            feesAndTxtTotalAmountLbl.text = "\(currency)\(feesAmount.decimalFormat(true))"
        }

        let discount = detail.discount ?? 0

        if discount > 0 {
            discountView.isHidden = false
            discountToalLbl.isHidden = false
            discountToalLbl.text = "-\(currency)\(discount.decimalFormat(true))"
        } else {
            discountView.isHidden = true
            discountToalLbl.isHidden = true
        }
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
        guard let bookingId = bookingId else { return }
        PaymentPresenter.successPayment(paymentHistoryId: paymentHistoryId, bookingId: bookingId, optedPolicy: nil) { [weak self] isSuccess, _ in
            guard let self = self else { return }
            if isSuccess {
                countdownTimer?.invalidate()
                Navigate.to.ticketConfirmationVC(self, booking: nil, bookingId: bookingId, type: .singleTickedEvent)
            }
        }
    }

    private func createFreeEventBookingAndNavigate() {
        guard let eventId = event?.id else { return }

        let ticketsPayload: [[String: Any]] = selectedTickets.map {
            [
                "ticketId": $0.id ?? "",
                "ticketQuantity": $0.selectedTicketCount ?? 0,
                "ticketPrice": $0.price ?? 0
            ]
        }

        PaymentPresenter.createEventBookingV2(
            eventId: eventId,
            code: UserDefault.shared.user?.code ?? "+1",
            phone: UserDefault.shared.user?.phone ?? "",
            gender: "UNASSIGNED",
            userId: UserDefault.shared.user?.id ?? "",
            tickets: ticketsPayload
        ) { [weak self] isSuccess, _, id, _ in
            guard let self = self else { return }
            if isSuccess, let id = id {
                Navigate.to.showQRCode(self, booking: nil, bookingId: id, type: .singleTickedEvent)
            }
        }
    }
    
    private func cancelBooking() {
        countdownTimer?.invalidate()
        PaymentPresenter.cancelBooking(bookingId: bookingId ?? "") { _, _ in
        }
    }

    @IBAction func onClickSubmitPromoBtn(_ sender: Any) {
        let promo = (promoCodeTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        addPromoCodeBtn.showLoader(userInteraction: false)

        if isPromoCodeApplied {
            fetchPaymentIntentAndSetup(promoCode: "", completion: { [weak self] isSuccess in
                guard let self else { return }
                self.addPromoCodeBtn.hideLoader()

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
                return
            }

            fetchPaymentIntentAndSetup(promoCode: promo, completion: { [weak self] isSuccess in
                guard let self else { return }
                self.addPromoCodeBtn.hideLoader()

                if isSuccess {
                    self.isPromoCodeApplied = true
                    self.appliedPromoCode = promo
                    self.promoCodeTextFeild.isUserInteractionEnabled = false
                    self.promoCodeTextFeild.alpha = 0.5
                    self.updatePromoButtonIcon()
                }
            })
        }
    }
    
    @IBAction func onClickChekBox(_ sender: Any) {
        
    }
    
    @IBAction func onClickPurchaseTicket(_ sender: Any) {
        
//        Navigate.to.ticketConfirmationVC(self)
        if isPaymentInitiated { return }
        isPaymentInitiated = true

        if isFreeTicket {
            isPaymentInitiated = false
            createFreeEventBookingAndNavigate()
            return
        }

        guard let paymentSheet else {
            isPaymentInitiated = false
            return
        }

        paymentSheet.present(from: self) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .completed:
                self.isPaymentInitiated = false
                self.completePaymentSuccess()

            case .canceled:
                self.isPaymentInitiated = false

            case .failed:
                self.isPaymentInitiated = false
            }
        }
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        cancelBooking()
        Navigate.to.back(self)
    }

    @IBAction func onClickFeesAndTaxes(_ sender: Any) {
        feesAndTaxesContainerView.isHidden.toggle()
    }
    

    @IBAction func onClickAddPromoCode(_ sender: Any) {

        let isHidden = promoCodeView.isHidden
        
        UIView.animate(withDuration: 0.25) {
            self.feesDropDowenIc.transform = isHidden
            ? CGAffineTransform(rotationAngle: .pi)
            : .identity
            
            self.view.layoutIfNeeded()
        }
        
        promoCodeView.isHidden.toggle()
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
            }
        }
    }
    
    @objc private func handleBackSwipe() {
        navigationController?.interactivePopGestureRecognizer?.removeTarget(self, action: #selector(handleBackSwipe))
        cancelBooking()
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

        func makeBlock(height: CGFloat, width: CGFloat? = nil, corner: CGFloat = 8) -> ShimmerView {
            let v = ShimmerView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.layer.cornerRadius = corner
            v.clipsToBounds = true
            NSLayoutConstraint.activate([
                v.heightAnchor.constraint(equalToConstant: height)
            ])
            if let width {
                v.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            shimmerBlocks.append(v)
            return v
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

        shimmerBlocks.forEach { $0.startAnimating() }
    }

    private func hideCheckoutShimmerIfNeeded() {
        guard isBookingLoaded, isPaymentIntentLoaded else { return }

        shimmerBlocks.forEach { $0.stopAnimating() }
        shimmerView.isHidden = true
    }
    
    
}

extension TicketCheckoutVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView { return selectedTickets.count }
        return feesAndTaxes.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TicketItemTableViewCell.identifier,
            for: indexPath
        ) as? TicketItemTableViewCell else { return UITableViewCell() }

        cell.selectionStyle = .none
        cell.titleTopConstraint.constant = (indexPath.row == 0) ? 0 : 12

        if tableView == self.tableView {
            let ticket = selectedTickets[indexPath.row]
            let quantity = ticket.selectedTicketCount ?? 0
            let price = (ticket.price ?? 0) - (ticket.extraFees ?? 0)
            let total = Double(quantity) * price

            cell.titleLbl.text = "\(quantity)x \(ticket.tierName)"
            cell.amountLbl.text = total <= 0 ? "Free" : "\(currency)\(total.decimalFormat(true))"
        } else {
            let item = feesAndTaxes[indexPath.row]
            cell.titleLbl.text = item.title
            cell.amountLbl.text = "\(currency)\(item.amount.decimalFormat(true))"
        }

        return cell
    }
}
