//
//  TablePurchaseVC.swift
//  SpeakEasy-Consumer
//

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet
import MHLoadingButton

struct TableBookingCheckoutItem {
    let id: String
    let name: String
    let guests: Int
    let minimum: Double
    let deposit: Double
    let timeSlot: String?
}

final class TablePurchaseVC: UIViewController {

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
    @IBOutlet weak var promoCodeView: UIView!
    @IBOutlet weak var discountView: UIView!
    @IBOutlet weak var feesAndTaxesTitleView: UIView!
    @IBOutlet weak var discountToalLbl: UILabel!
    @IBOutlet weak var shimmerView: UIView!
    @IBOutlet weak var feesDropDowenIc: UIImageView!
    @IBOutlet weak var submitPromoCodeBtn: LoadingButton!
    @IBOutlet weak var addPromoCodeBtn: UIButton!
    @IBOutlet weak var tableMinimumDepositLbl: UILabel!
    @IBOutlet weak var promoCodeTextFeildView: UIView!
    @IBOutlet weak var feesAndTaxesTableParentView: UIView!
    
    var queueId: String?
    var seatingAreas: [SeatingArea] = []
    var event: Event?
    var venueDetails: ClipVenue?
    var selectedGuestCount: Int = 0
    var selectedTime: String = ""

    private var booking: SeatingAreaBookingResponse?
    private var feesAndTaxes: [FeeDisplayItem] = []
    private var checkoutItems: [TableBookingCheckoutItem] = []
    private var shimmerBlocks: [ShimmerView] = []

    private var paymentSheet: PaymentSheet?
    private var paymentIntentClientSecret: String = ""
    private var currentBookingId: String = ""
    private var paymentId: String = ""

    private var isPaymentInitiated = false
    private var isFreeBooking = false
    private var isPromoCodeApplied = false
    private var appliedPromoCode: String = ""

    private var currency: String {
        venueDetails?.venueSettings?.currencySymbol ?? "$"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let venue = event?.venue {
            self.venueDetails = venue
        }

        setupUI()
        setupHeaderData()
        updatePromoButtonIcon()
        showCheckoutShimmer()
        setupSocket()

        
        tableView.register(TableItemsTVC.nib,
                           forCellReuseIdentifier: TableItemsTVC.identifier)
        
        feesAndTaxesTableView.register(TicketItemTableViewCell.nib,
                           forCellReuseIdentifier: TicketItemTableViewCell.identifier)
        
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        feesAndTaxesTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
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
        tableView.removeObserver(self, forKeyPath: "contentSize")
        feesAndTaxesTableView.removeObserver(self, forKeyPath: "contentSize")
        BookingQueueSocketManager.shared.disconnect()
    }

    private func setupUI() {
        
        tableView.delegate = self
        tableView.dataSource = self
        feesAndTaxesTableView.delegate = self
        feesAndTaxesTableView.dataSource = self

        tableView.register(
            TicketItemTableViewCell.nib,
            forCellReuseIdentifier: TicketItemTableViewCell.identifier
        )

        feesAndTaxesTableView.register(
            TicketItemTableViewCell.nib,
            forCellReuseIdentifier: TicketItemTableViewCell.identifier
        )

        submitPromoCodeBtn.indicator = MaterialLoadingIndicator(color: .white)
        submitPromoCodeBtn.bgColor = .clear

        purchaseTicketBtn.isUserInteractionEnabled = false
        purchaseTicketBtn.alpha = 0.5

        discountView.isHidden = true
    }

    private func setupHeaderData() {
        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueName.text = venueDetails?.name
        venueName2.text = venueDetails?.name
        eventTitleLbl.text = event?.title

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

            dateandtimeLbl.text = (!dateText.isEmpty && !startTime.isEmpty)
                ? "\(dateText) at \(startTime) - \(endTime)"
                : ""
        }
    }

    private func configureSelectedTableData() {
        let seatingAreas = seatingAreas
        guard let bookingItems = booking?.items else { return }

        checkoutItems.removeAll()

        for bookingItem in bookingItems {

            guard let area = seatingAreas.first(where: {
                $0.id == bookingItem.seatingAreaId
            }) else { continue }

            let item = TableBookingCheckoutItem(
                id: area.id ?? "",
                name: area.name ?? "",
                guests: bookingItem.guests ?? 0,
                minimum: bookingItem.calculatedMinimum ?? 0,
                deposit: bookingItem.calculatedDeposit ?? 0,
                timeSlot: nil
            )

            checkoutItems.append(item)
        }

        tableView.isHidden = false
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableViewHeight.constant = tableView.contentSize.height
    }

    private func setupSocket() {
        BookingQueueSocketManager.shared.delegate = self
        if let queueId = queueId {
            BookingQueueSocketManager.shared.connect(queueId: queueId)
        }
    }

    private func handleQueue(_ booking: SeatingAreaBookingResponse) {
        let position = booking.position
        let approxWait = booking.approxWait

        let timeText = approxWait > 60
            ? "\(approxWait / 60) min \(approxWait % 60) sec"
            : "\(approxWait) sec"

        timerLbl.text = "You are #\(position) in queue. Wait ~ \(timeText)"
    }

    private func handlePayment(_ booking: SeatingAreaBookingResponse) {

        
        self.booking = booking
        self.currentBookingId = booking.content?.tableBooking?.id ?? ""
        self.paymentIntentClientSecret = booking.content?.clientSecret ?? ""
        self.paymentId = booking.content?.tableBooking?.paymentId ?? ""
        configureSelectedTableData()

        guard let breakdown = booking.content?.tableBooking?.tableBookingPriceBreakdown else {
            hideCheckoutShimmer()
            purchaseTicketBtn.isUserInteractionEnabled = true
            purchaseTicketBtn.alpha = 1
            return
        }

        updateUI(breakdown)

        if !paymentIntentClientSecret.isEmpty {
            setupStripePaymentSheet(clientSecret: paymentIntentClientSecret)
        }

        hideCheckoutShimmer()
        purchaseTicketBtn.isUserInteractionEnabled = true
        purchaseTicketBtn.alpha = 1
    }

    private func handleFailure(_ booking: SeatingAreaBookingResponse) {
        let message = booking.message ?? "Something went wrong"
        timerLbl.text = message
        hideCheckoutShimmer()

        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func toDouble(_ value: String?) -> Double {
        return Double(value ?? "0") ?? 0
    }
    
    private func updateUI(_ breakdown: PriceBreakdown) {

        let base = toDouble(breakdown.base)
        let discount = toDouble(breakdown.discount)
        let gratuity = toDouble(breakdown.gratuity)
        let salesTax = toDouble(breakdown.salesTax)
//        let stripeFee = toDouble(breakdown.stripeFees)
//        let total = toDouble(breakdown.total)

//        isFreeBooking = total <= 0

        var items: [FeeDisplayItem] = []

//        if stripeFee > 0 {
//            items.append(FeeDisplayItem(title: "Processing Fee", amount: stripeFee))
//        }

        if gratuity > 0 {
            items.append(FeeDisplayItem(title: breakdown.gratuityName ?? "Gratuity", amount: gratuity))
        }

        if salesTax > 0 {
            items.append(FeeDisplayItem(title: breakdown.salesTaxName ?? "Sales Tax", amount: salesTax))
        }

//        breakdown.tableBookingPriceBreakdownHasCustomFees?.forEach {
//            let fee = toDouble($0.fee)
//            if fee > 0 {
//                items.append(FeeDisplayItem(title: $0.name ?? "Fee", amount: fee))
//            }
//        }

        feesAndTaxes = items
        feesAndTaxesTitleView.isHidden = items.isEmpty
        feesAndTaxesTableView.reloadData()

//        totalAmountLbl.text = total <= 0
//            ? "Free"
//            : "\(currency)\(total.decimalFormat(true))"
//
//        let totalFeesAmount = total - base + discount
//        feesAndTxtTotalAmountLbl.text = totalFeesAmount > 0
//            ? "\(currency)\(totalFeesAmount.decimalFormat(true))"
//            : ""

        if discount > 0 {
            discountView.isHidden = false
            discountToalLbl.isHidden = false
            discountToalLbl.text = "-\(currency)\(discount.decimalFormat(true))"
        } else {
            discountView.isHidden = true
            discountToalLbl.isHidden = true
        }

        tableMinimumDepositLbl.text = "\(currency)\(base.decimalFormat(true))"

        feesAndTaxesTableView.layoutIfNeeded()
        feesAndTaxesTableViewHeight.constant = feesAndTaxesTableView.contentSize.height
    }
    
    private func toDouble(_ value: Any?) -> Double {
        if let v = value as? Double { return v }
        if let v = value as? Int { return Double(v) }
        if let v = value as? String { return Double(v) ?? 0 }
        return 0
    }


    private func setupStripePaymentSheet(clientSecret: String) {
        STPAPIClient.shared.publishableKey = Stripe.publishableKey

        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"
        config.allowsDelayedPaymentMethods = true
        config.applePay = .init(
            merchantId: "merchant.com.speakeasy",
            merchantCountryCode: "US"
        )

        if let customerId = UserDefault.shared.user?.stripeCusId,
           !customerId.isEmpty {
            // customer without ephemeral key is intentionally not set
        }

        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: config
        )
    }

    private func completePaymentSuccess() {
        guard !paymentId.isEmpty, !currentBookingId.isEmpty else {
            let alert = UIAlertController(
                title: "Success",
                message: "Table booking payment completed.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                Navigate.to.back(self)
            })
            present(alert, animated: true)
            return
        }

        PaymentPresenter.successPayment(
            paymentHistoryId: paymentId,
            bookingId: currentBookingId,
            optedPolicy: nil
        ) { [weak self] isSuccess, _ in
            guard let self = self else { return }

            let alert = UIAlertController(
                title: isSuccess ? "Success" : "Payment Submitted",
                message: isSuccess
                    ? "Your table booking payment was successful."
                    : "Your payment was submitted successfully.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                Navigate.to.back(self)
            })

            self.present(alert, animated: true)
        }
    }

    private func completeFreeBookingSuccess() {
        let alert = UIAlertController(
            title: "Success",
            message: "Your table booking was completed successfully.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            Navigate.to.back(self)
        })
        present(alert, animated: true)
    }

    private func updatePromoButtonIcon() {
        let imageName = isPromoCodeApplied ? "trash" : "ArrowRight"

        if isPromoCodeApplied {
            submitPromoCodeBtn.setImage(UIImage(systemName: imageName), for: .normal)
            submitPromoCodeBtn.tintColor = .white
        } else {
            submitPromoCodeBtn.setImage(UIImage(named: imageName), for: .normal)
            submitPromoCodeBtn.tintColor = nil
        }
    }

    @objc private func handleBackSwipe() {
        navigationController?.interactivePopGestureRecognizer?.removeTarget(self, action: #selector(handleBackSwipe))
        BookingQueueSocketManager.shared.disconnect()
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

    private func hideCheckoutShimmer() {
        shimmerBlocks.forEach { $0.stopAnimating() }
        shimmerView.isHidden = true
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        BookingQueueSocketManager.shared.disconnect()
        Navigate.to.back(self)
    }

    @IBAction func onClickAddPromoCode(_ sender: Any) {
        let isHidden = promoCodeTextFeildView.isHidden

//        UIView.animate(withDuration: 0.25) {
//            self.feesDropDowenIc.transform = isHidden
//                ? CGAffineTransform(rotationAngle: .pi)
//                : .identity
//            self.view.layoutIfNeeded()
//        }

        promoCodeTextFeildView.isHidden.toggle()
    }

    @IBAction func onClickSubmitPromoCode(_ sender: Any) {
        let promo = (promoCodeTextFeild.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        submitPromoCodeBtn.showLoader(userInteraction: false)

        if isPromoCodeApplied {
            isPromoCodeApplied = false
            appliedPromoCode = ""
            promoCodeTextFeild.text = ""
            promoCodeTextFeild.isUserInteractionEnabled = true
            promoCodeTextFeild.alpha = 1
            updatePromoButtonIcon()
            submitPromoCodeBtn.hideLoader()
            Alert.showToast("Promo code removed")
            return
        }

        guard !promo.isEmpty else {
            submitPromoCodeBtn.hideLoader()
            return
        }

        // Table promo backend hook is not available in the shared code.
        // UI state is handled here safely.
        isPromoCodeApplied = true
        appliedPromoCode = promo
        promoCodeTextFeild.isUserInteractionEnabled = false
        promoCodeTextFeild.alpha = 0.5
        updatePromoButtonIcon()
        submitPromoCodeBtn.hideLoader()
        Alert.showToast("Promo code applied")
    }

    @IBAction func onClickPurchaseTicket(_ sender: Any) {
        if isPaymentInitiated { return }
        isPaymentInitiated = true

        if isFreeBooking {
            isPaymentInitiated = false
            completeFreeBookingSuccess()
            return
        }

        guard let paymentSheet else {
            isPaymentInitiated = false
            Alert.showToast("Payment is not ready yet")
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

    @IBAction func onClickFeesAndTaxes(_ sender: Any) {
        feesAndTaxesTableParentView.isHidden.toggle()
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "contentSize", let table = object as? UITableView {
            if table == self.tableView {
                tableViewHeight.constant = table.contentSize.height
            } else if table == self.feesAndTaxesTableView {
                feesAndTaxesTableViewHeight.constant = table.contentSize.height
            }
        }
    }
    
    private func convertPriceFormat(_ amount: Double?, _ currencyCode: String?) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode ?? "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount ?? 0)) ?? "$0"
    }
}

extension TablePurchaseVC: BookingQueueSocketDelegate {

    func didUpdateQueue(seatingAreaBooking: SeatingAreaBookingResponse?) {
        guard let booking = seatingAreaBooking else { return }

        switch booking.status.lowercased() {
        case "queued":
            handleQueue(booking)

        case "payment":
            handlePayment(booking)

        case "failed":
            handleFailure(booking)

        default:
            break
        }
    }
}

extension TablePurchaseVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return checkoutItems.count
        }
        return feesAndTaxes.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        if tableView == self.tableView {
            
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TableItemsTVC.identifier,
                for: indexPath
            ) as? TableItemsTVC else {
                return UITableViewCell()
            }

            cell.selectionStyle = .none
            
            let item = checkoutItems[indexPath.row]
            cell.name.text = item.name
            cell.guestLbl.text = "\(item.guests)"
            let minimumAmount = convertPriceFormat(item.minimum, nil)
            cell.minimumSpendLbl.text = "\(minimumAmount) spend minimum"
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketItemTableViewCell.identifier,
                for: indexPath
            ) as? TicketItemTableViewCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.titleTopConstraint.constant = (indexPath.row == 0) ? 0 : 12
            
            let item = feesAndTaxes[indexPath.row]
            cell.titleLbl.text = item.title
            cell.amountLbl.text = "\(currency)\(item.amount.decimalFormat(true))"
            
            return cell
        }

    }
}

private struct TableCheckoutItem {
    let title: String
    let value: String
}
