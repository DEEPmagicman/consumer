//
//  OrderListViewController.swift
//  SpeakEasy-Consumer
//

import UIKit
import MHLoadingButton

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
    
    var selectedTickets: [EventTicket] = []
    var venueDetails: ClipVenue?
    var event: Event?
    var booking: Booking?
    var bookingId: String?

    private var isTermsAccepted = false
    private var isVenueMessageAccepted = false
    private var isTermsExpanded = false
    private let collapsedLines = 2
    private var hasLaidOutTerms = false  // ensures we only do first layout once

    private var fullTermsText = ""

    private var feesAndTaxes: [FeeDisplayItem] = []
    private var paymentDetail: PaymentDetail?

    private var isPromoCodeApplied = false
    private var appliedPromoCode = ""
    var selectedPaymentMethod: PaymentType?

    private var currency: String {
        return venueDetails?.venueSettings?.currencySymbol ?? "$"
    }
    private let posterHeaderView = EventPosterHeaderView()

    private let paymentService = PaymentService()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTableViews()
        setupHeaderData()
        calculateTotal()
        setupTermsText()

        getBooking(id: bookingId)
        fetchPaymentIntentAndSetup(promoCode: appliedPromoCode)

        ticketTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        feesAndTaxesTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)

        applyPromoBtn.indicator = MaterialLoadingIndicator(color: .black)

        fullTermsText = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s."
        venueMessageLbl.text = "Venue message text here"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Wait until label has a real frame, then render once
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
        feesAndTaxesParentView.applyAutoBorderBackground()
        view.applyScreenBgGradient()

        addPromoCodeView.isHidden = true
        promoCodeAppliedView.isHidden = true
        promoCodeTitleView.isHidden = false
        
        switch selectedPaymentMethod {
        case .applePay:
            paymentTypeName.text = "Apple Pay"
            paymentCardImage.image = UIImage(named: "applePayIcon")
        case .card:
            paymentTypeName.text = "Mastercard ending 0987"
            paymentCardImage.image = UIImage(named: "creditCardIcon")
        
        case .none:
            paymentTypeName.text = "Apple Pay"
        }
        checkOutView.delegate = self
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

        self.backgroundContainerView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: self.backgroundContainerView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: self.backgroundContainerView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: self.backgroundContainerView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: self.backgroundContainerView.bottomAnchor)
        ])

        let imageURLString = (event?.flyer?.key ?? "").imageURL
        posterHeaderView.loadImage(from: imageURLString)
    }

    private func setupHeaderData() {
        venueName.text = event?.venue?.name.uppercased()
        eventNameLbl.text = event?.title

        if let customText = event?.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dateandtimeLbl.text = customText
        } else {
            let timezone = venueDetails?.useTimezone ?? ""
            let dateText = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, customTimeZone: timezone) ?? ""
            let startTime = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: timezone) ?? ""
            let endTime = event?.endDateTime?.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: timezone) ?? "LATE"
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

        // Style "View More" / "View Less" differently
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

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
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

        if table == ticketTableView {
            tableViewHeight.constant = table.contentSize.height
        } else if table == feesAndTaxesTableView {
            feesAndTaxesTableViewHeight.constant = table.contentSize.height
        }

        view.layoutIfNeeded()
    }

    // MARK: - Checkout & Totals

    private func calculateTotal() {
        let subtotal = selectedTickets.reduce(0.0) { result, ticket in
            let quantity = ticket.selectedTicketCount ?? 0
            let price = ticket.price ?? 0
            return result + (Double(quantity) * price)
        }

        let totalTickets = selectedTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        checkOutView.updateSummary(currency: currency, count: totalTickets, subtotal: subtotal, fees: 0)
        checkOutView.setButtonTitle("Purchase Tickets")
    }

    // MARK: - Checkbox UI

    private func updateTermsCheckboxUI() {
        let image = isTermsAccepted ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon
        termsAndConditionsBtn.setImage(image, for: .normal)
    }

    private func updateVenueCheckboxUI() {
        let image = isVenueMessageAccepted ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon
        venueMessageBtn.setImage(image, for: .normal)
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
        let shouldShowPromoView = addPromoCodeView.isHidden

        UIView.animate(withDuration: 0.2, animations: {
            self.pluseBtn.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.pluseBtn.setImage(
                shouldShowPromoView ? UIImage(named: "minusPromoIcon") : UIImage(named: "plusIcon"),
                for: .normal
            )
            UIView.animate(withDuration: 0.25) {
                self.pluseBtn.transform = .identity
            }
        }

        if shouldShowPromoView {
            addPromoCodeView.alpha = 0
            addPromoCodeView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            addPromoCodeView.isHidden = false

            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                self.addPromoCodeView.alpha = 1
                self.addPromoCodeView.transform = .identity
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.addPromoCodeView.alpha = 0
                self.addPromoCodeView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                self.addPromoCodeView.isHidden = true
                self.addPromoCodeView.transform = .identity
            }
        }
    }

    @IBAction func onClickRemovePromoCodeBtn(_ sender: Any) {
        fetchPaymentIntentAndSetup(promoCode: "")

        isPromoCodeApplied = false
        appliedPromoCode = ""
        addCodeTextFeild.text = ""
        addCodeTextFeild.isUserInteractionEnabled = true
        addCodeTextFeild.alpha = 1

        updatePromoCodeUI()
    }

    @IBAction func onClickFeesAndTaxesView(_ sender: Any) {
        let shouldShowView = feesAndTaxesHiddenView.isHidden

        UIView.animate(withDuration: 0.2, animations: {
            self.feesDropDowenIc.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.25) {
                self.feesDropDowenIc.transform = shouldShowView
                    ? CGAffineTransform(rotationAngle: .pi)
                    : .identity
            }
        }

        if shouldShowView {
            feesAndTaxesHiddenView.alpha = 0
            feesAndTaxesHiddenView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            feesAndTaxesHiddenView.isHidden = false

            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseInOut]) {
                self.feesAndTaxesHiddenView.alpha = 1
                self.feesAndTaxesHiddenView.transform = .identity
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.feesAndTaxesHiddenView.alpha = 0
                self.feesAndTaxesHiddenView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                self.feesAndTaxesHiddenView.isHidden = true
                self.feesAndTaxesHiddenView.transform = .identity
            }
        }
    }
    
    @IBAction func onClickCardBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    // MARK: - Payment / Booking

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
        return selectedTickets.map {
            ["ticketId": $0.id ?? "", "quantity": $0.selectedTicketCount ?? 0]
        }
    }

    private func fetchPaymentIntentAndSetup(promoCode: String) {
        guard let bookingId else { return }

        let coverTickets = buildCoverTicketsForPaymentIntent()

        paymentService.createPaymentIntent(
            bookingId: bookingId,
            selectedTickets: coverTickets,
            promoCode: promoCode,
            type: .singleTickedEvent
        ) { [weak self] isSuccess, errMsg, clientSecret, paymentHistoryId, ephemeralKey, paymentDetail, isFreeTicket in
            guard let self = self else { return }
            self.applyPromoBtn.hideLoader()

            if isSuccess {
                self.paymentDetail = paymentDetail
                let discount = paymentDetail?.discount ?? 0

                if promoCode.isEmpty {
                    self.isPromoCodeApplied = false
                    self.appliedPromoCode = ""
                } else if discount > 0 {
                    self.isPromoCodeApplied = true
                    self.appliedPromoCode = promoCode
                    self.addCodeTextFeild.isUserInteractionEnabled = false
                    self.addCodeTextFeild.alpha = 0.5
                } else {
                    self.isPromoCodeApplied = false
                    self.appliedPromoCode = ""
                    self.addCodeTextFeild.isUserInteractionEnabled = true
                    self.addCodeTextFeild.alpha = 1
                }

                self.updatePromoCodeUI()
                self.updateUIWithPaymentDetail(paymentDetail)
            } else {
                self.isPromoCodeApplied = false
                self.appliedPromoCode = ""
                self.updatePromoCodeUI()
                Alert.showToast(errMsg ?? "Something went wrong")
            }
        }
    }

    private func updateUIWithPaymentDetail(_ detail: PaymentDetail?) {
        guard let detail else {
            feesAndTaxes = []
            feesAndTaxesHiddenView.isHidden = true
            feesAndTaxesTableView.reloadData()
            return
        }

        feesAndTaxes = buildFeesArray(from: detail)
        feesAndTaxesTableView.reloadData()

        let totalTickets = selectedTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        let feesAmount = detail.total - detail.subTotal

        checkOutView.updateSummary(currency: currency, count: totalTickets, subtotal: detail.total, fees: feesAmount)

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
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension OrderListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView == ticketTableView ? selectedTickets.count : feesAndTaxes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == ticketTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "OrderItemTableViewCell",
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

            if (ticket.extraFees ?? 0) > 0 {
                cell.extraFeesLbl.isHidden = false
                cell.extraFeesLbl.text = "Incl. \(currency)\((ticket.extraFees ?? 0).decimalFormat(true)) fees"
            } else {
                cell.extraFeesLbl.isHidden = true
            }

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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

// MARK: - CheckoutBarDelegate

extension OrderListViewController: CheckoutBarDelegate {

    func checkoutBarDidTapButton() {
//        let paymentVC = PaymentVC()
//        paymentVC.event = event
//        navigationController?.pushViewController(paymentVC, animated: true)
    }
}
