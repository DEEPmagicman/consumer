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
    private var skeletonView: SkeletonOverlayView?
    private var isLoading = false

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

        setupHeaderData()
        startCountdown()
        calculateTotal()
        getBooking(id: bookingId)

        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        feesAndTaxesTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)

        fetchPaymentIntentAndSetup(promoCode: "")
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
        guard let id = id else { return }

        if booking == nil {  }

        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, _, booking in
            guard let self = self else { return }
            if isSuccess {
                self.booking = booking
                self.reloadFeesUIFromBooking()
            }
        }
    }

    private func reloadFeesUIFromBooking() {
        feesAndTaxes = buildFeesArray(from: booking?.fees)
        feesAndTaxesTitleView.isHidden = feesAndTaxes.isEmpty
        feesAndTaxesTableView.reloadData()
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

        if fees.processingFee > 0 {
            items.append(FeeDisplayItem(title: "Processing Fee", amount: fees.processingFee))
        }
        if fees.customFee > 0 {
            items.append(FeeDisplayItem(title: fees.customFeeName ?? "Custom Fee", amount: fees.customFee))
        }
        if (fees.salesTax ?? 0) > 0 {
            items.append(FeeDisplayItem(title: fees.salesTaxName ?? "Sales Tax", amount: fees.salesTax ?? 0))
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
        timerLbl.text = "Ticket hold expired"
        navigationController?.popToRootViewController(animated: true)
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

    private func fetchPaymentIntentAndSetup(promoCode: String) {
        guard let bookingId = bookingId else { return }

        let coverTickets = buildCoverTicketsForPaymentIntent()

        PaymentPresenter.getPaymentIntent(
            bookingId: bookingId,
            selectedTickets: coverTickets,
            promoCode: promoCode,
            type: .singleTickedEvent
        ) { [weak self] isSuccess, _, clientSecret, paymentHistoryId, ephemeralKey, paymentDetail, isFreeTicket in

            guard let self = self else { return }

            guard isSuccess, let clientSecret else { return }

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
                Navigate.to.showQRCode(self, booking: nil, bookingId: bookingId, type: .singleTickedEvent)
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

    // MARK: - Actions
    @IBAction func onClickSubmitPromoBtn(_ sender: Any) {
        let promo = (promoCodeTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if isPromoCodeApplied {
            isPromoCodeApplied = false
            appliedPromoCode = ""
            promoCodeTextFeild.isUserInteractionEnabled = true
            promoCodeTextFeild.alpha = 1
            promoCodeTextFeild.text = ""
            fetchPaymentIntentAndSetup(promoCode: "")
        } else {
            if promo.isEmpty { return }
            isPromoCodeApplied = true
            appliedPromoCode = promo
            promoCodeTextFeild.isUserInteractionEnabled = false
            promoCodeTextFeild.alpha = 0.5
            fetchPaymentIntentAndSetup(promoCode: promo)
        }
    }
    
    @IBAction func onClickChekBox(_ sender: Any) {
        
    }
    
    @IBAction func onClickPurchaseTicket(_ sender: Any) {
        
        Navigate.to.ticketConfirmationVC(self)
//        if isPaymentInitiated { return }
//        isPaymentInitiated = true
//
//        if isFreeTicket {
//            isPaymentInitiated = false
//            createFreeEventBookingAndNavigate()
//            return
//        }
//
//        guard let paymentSheet else {
//            isPaymentInitiated = false
//            return
//        }
//
//        paymentSheet.present(from: self) { [weak self] result in
//            guard let self = self else { return }
//
//            switch result {
//            case .completed:
//                self.isPaymentInitiated = false
//                self.completePaymentSuccess()
//
//            case .canceled:
//                self.isPaymentInitiated = false
//
//            case .failed:
//                self.isPaymentInitiated = false
//            }
//        }
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickFeesAndTaxes(_ sender: Any) {
        feesAndTaxesContainerView.isHidden.toggle()
    }
    

    @IBAction func onClickAddPromoCode(_ sender: Any) {
        
        self.promoCodeView.isHidden.toggle()
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
