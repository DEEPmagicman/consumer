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
    @IBOutlet weak var policyLbl: UILabel!
    @IBOutlet weak var termsLbl: UILabel!
    @IBOutlet weak var privacyPolicyLbl: UILabel!
    @IBOutlet weak var questionsORcommentsView: UIView!
    @IBOutlet weak var questionAndCommentTextView: UITextView!
    @IBOutlet weak var termViewMoreBtn: UIButton!
    @IBOutlet weak var termViewMoreView: UIView!
    
    var queueId: String?
    var seatingAreas: [SeatingArea] = []
    var event: Event?
    var venueDetails: ClipVenue?
    var selectedGuestCount: Int = 0
    var selectedTime: String = ""
    
    private var isTermsExpanded = false
    private let termsCollapsedLines = 4
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
    private var isPolicyAccepted = true
    private var confirmedBookingResponse: TableBookingConfirmResponse?

    private var currency: String {
        venueDetails?.venueSettings?.currencySymbol ?? "$"
    }
    
    private var currencyPosition: String {
        venueDetails?.venueSettings?.currencyPosition ?? "$"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let venue = event?.venue {
            self.venueDetails = venue
        }
        questionAndCommentTextView.setPlaceholder("Questions or comments")

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
    
//        if let tableBookingPolicy = event?.venue?.venueSettings?.tableBookingPolicy {
//
//        }
       
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
        
        setHTMLText(event?.venue?.venueSettings?.tableBookingImportantInformation,
                    on: privacyPolicyLbl,
                    textColor: .black,
                    linkColor: .systemBlue)
        
     

        setHTMLText(event?.venue?.venueSettings?.tableBookingTermsAndCondition,
                    on: termsLbl,
                    linkColor: .systemBlue)
        setupTermsExpandableLabel()
        
    }
    
    private func setupTermsExpandableLabel() {
        termsLbl.numberOfLines = termsCollapsedLines
        termViewMoreBtn.setTitle("View More", for: .normal)

        view.layoutIfNeeded()
        checkIfTermsNeedsExpansion()
    }
    
    private func checkIfTermsNeedsExpansion() {
        termsLbl.numberOfLines = 0

        let fullHeight = termsLbl.sizeThatFits(
            CGSize(width: termsLbl.frame.width,
                   height: CGFloat.greatestFiniteMagnitude)
        ).height

        let maxCollapsedHeight = termsLbl.font.lineHeight * CGFloat(termsCollapsedLines)

        if fullHeight > maxCollapsedHeight {
            termsLbl.numberOfLines = termsCollapsedLines
            termViewMoreView.isHidden = false
        } else {
            termsLbl.numberOfLines = 0
            termViewMoreView.isHidden = true
        }
    }
    
    @objc private func handleHTMLLabelTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel,
              let attributedText = label.attributedText else { return }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)

        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let location = gesture.location(in: label)
        let index = layoutManager.characterIndex(
            for: location,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        guard index < attributedText.length else { return }

        let attrs = attributedText.attributes(at: index, effectiveRange: nil)

        if let url = attrs[.link] as? URL {
            UIApplication.shared.open(url)
        } else if let urlString = attrs[.link] as? String,
                  let url = URL(string: urlString) {
            UIApplication.shared.open(url)
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
                guests: bookingItem.guests,
                minimum: bookingItem.calculatedMinimum ?? 0,
                deposit: bookingItem.calculatedDeposit ?? 0,
                timeSlot: getStartTime(from: bookingItem.timeSlot?.startTime)
            )

            checkoutItems.append(item)
        }

        tableView.isHidden = false
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableViewHeight.constant = tableView.contentSize.height
    }
    
    private func confirmTableBooking(completion: @escaping (_ success: Bool) -> Void) {
        guard let eventId = event?.id,
              let queueId = queueId,
              !queueId.isEmpty,
              !currentBookingId.isEmpty,
              let venueId = venueDetails?.id ?? event?.venue?.id,
              let consumerUserId = UserDefault.shared.user?.id,
              !consumerUserId.isEmpty else {
            Alert.showToast("Booking details not found")
            completion(false)
            return
        }

        let notesText = questionAndCommentTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = notesText == "Questions or comments" ? "" : (notesText ?? "")

        TablePresenter.confirmSeatingAreaBooking(
            eventId: eventId,
            queueId: queueId,
            tableBookingId: currentBookingId,
            consumerUserId: consumerUserId,
            optedPolicy: isPolicyAccepted,
            notes: notes,
            venueId: venueId
        ) { [weak self] success, message, response in
            guard let self = self else { return }

            if success, let response = response {
                self.confirmedBookingResponse = response
                completion(true)
            } else {
                Alert.showToast(message ?? "Failed to confirm table booking")
                completion(false)
            }
        }
    }
    
    
    private func getStartTime(from startTime: String?) -> String {
        guard let startTime,
              let date = startTime.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: true)
        else { return "" }

        let timezone = event?.venue?.timezone
            ?? event?.venue?.useTimezone
            ?? TimeZone.current.identifier

        let venueTZ = TimeZone(identifier: timezone)

        return date.toString(dateFormat: .hmma, timeZone: venueTZ)
    }
    
    private func setHTMLText(_ html: String?,
                             on label: UILabel,
                             textColor: UIColor = .label,
                             linkColor: UIColor = .systemBlue) {

        guard let html,
              let attributed = html.htmlToAttributedString else {
            label.attributedText = nil
            label.isUserInteractionEnabled = false
            return
        }

        let mutable = NSMutableAttributedString(attributedString: attributed)

        mutable.trimTrailingWhitespaceAndNewlines()
        mutable.forceSystemFont15()

        mutable.addAttribute(.foregroundColor,
                             value: textColor,
                             range: NSRange(location: 0, length: mutable.length))

        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 0
        style.paragraphSpacingBefore = 0
        style.lineSpacing = 0

        mutable.addAttribute(.paragraphStyle,
                             value: style,
                             range: NSRange(location: 0, length: mutable.length))

        mutable.enumerateAttribute(.link,
                                   in: NSRange(location: 0, length: mutable.length),
                                   options: []) { value, range, _ in
            if value != nil {
                mutable.addAttribute(.foregroundColor, value: linkColor, range: range)
                mutable.addAttribute(.underlineStyle,
                                     value: NSUnderlineStyle.single.rawValue,
                                     range: range)
            }
        }

        label.attributedText = mutable
        label.numberOfLines = 0

        if html.containsHTMLLink {
            label.isUserInteractionEnabled = true

            if label.gestureRecognizers?.isEmpty ?? true {
                let tap = UITapGestureRecognizer(target: self, action: #selector(handleHTMLLabelTap(_:)))
                label.addGestureRecognizer(tap)
            }
        } else {
            label.isUserInteractionEnabled = false
        }
    }
    
    private var infoTextAttributes: [NSAttributedString.Key: Any] {
        [
            .font: AppFont.font(weight: .regular, size: 12),
            .foregroundColor: UIColor(hex: "#D2D5DB")
        ]
    }

    private func makeIconAttachment(systemName: String) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: systemName)?
            .withTintColor(UIColor(hex: "#D2D5DB"), renderingMode: .alwaysOriginal)
        attachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        return attachment
    }

    private func buildGuestsTimeText(guests: Int, time: String?) -> NSAttributedString {
        let text = NSMutableAttributedString()

        let guestText = guests == 1 ? "1 Guest" : "\(guests) Guests"

        text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "person.2")))
        text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))
        text.append(NSAttributedString(string: guestText, attributes: infoTextAttributes))

        if let time, !time.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text.append(NSAttributedString(string: "   ", attributes: infoTextAttributes))
            text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "clock")))
            text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))
            text.append(NSAttributedString(string: "\(time) Arrival Time", attributes: infoTextAttributes))
        }

        return text
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

//        timerLbl.text = "You are #\(position) in queue. Wait ~ \(timeText)"
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

        let base = breakdown.base ?? 0
        let discount = breakdown.discount ?? 0
        let gratuity = breakdown.gratuity ?? 0
        let salesTax = breakdown.salesTax ?? 0
        let seFee = breakdown.seFees ?? 0
        let stripeFee = breakdown.stripeFees ?? 0
        let total = breakdown.total ?? 0

        let processingFee = seFee + stripeFee

        isFreeBooking = total <= 0

        var items: [FeeDisplayItem] = []

        if processingFee > 0 {
            items.append(FeeDisplayItem(title: "Processing Fee", amount: processingFee))
        }

        if gratuity > 0 {
            items.append(FeeDisplayItem(title: breakdown.gratuityName ?? "Gratuity", amount: gratuity))
        }

        if salesTax > 0 {
            items.append(FeeDisplayItem(title: breakdown.salesTaxName ?? "Sales Tax", amount: salesTax))
        }

        breakdown.tableBookingPriceBreakdownHasCustomFees?.forEach {
            let fee = $0.fee ?? 0
            if fee > 0 {
                items.append(FeeDisplayItem(title: $0.name ?? "Fee", amount: fee))
            }
        }

        feesAndTaxes = items
        feesAndTaxesTitleView.isHidden = items.isEmpty
        feesAndTaxesTableView.reloadData()

        totalAmountLbl.text = total <= 0
            ? "Free"
            : CurrencyFormatter.amount(total, symbol: currency, position: currencyPosition)

        let totalFeesAmount = total - base + discount
        feesAndTxtTotalAmountLbl.text = totalFeesAmount > 0
            ? CurrencyFormatter.amount(totalFeesAmount, symbol: currency, position: currencyPosition)
            : ""

        if discount > 0 {
            discountView.isHidden = false
            discountToalLbl.isHidden = false
            discountToalLbl.text = "-\(CurrencyFormatter.amount(discount, symbol: currency, position: currencyPosition))"
        } else {
            discountView.isHidden = true
            discountToalLbl.isHidden = true
        }

        tableMinimumDepositLbl.text = "\(CurrencyFormatter.amount(base, symbol: currency, position: currencyPosition))"

        feesAndTaxesTableView.layoutIfNeeded()
        feesAndTaxesTableViewHeight.constant = feesAndTaxesTableView.contentSize.height
    }
    
    private func toDouble(_ value: Any?) -> Double {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? String { return Double(value) ?? 0 }
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
        confirmTableBooking { [weak self] success in
            guard let self = self, success else { return }
            NotificationCenter.default.postOrdersRefresh(.tables)

            let alert = UIAlertController(
                title: "Success",
                message: "Your table booking was completed successfully.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                Navigate.to.back(self)
            })

            self.present(alert, animated: true)
        }
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

    private func hideCheckoutShimmer() {
        shimmerBlocks.forEach { $0.stopAnimating() }
        shimmerView.isHidden = true
    }
    
    private func updateUIAfterPromoCode(_ breakdown: PriceBreakdown) {
        let base = Double(breakdown.base ?? 0)
        let discount = Double(breakdown.discount ?? 0)
        let gratuity = Double(breakdown.gratuity ?? 0)
        let salesTax = Double(breakdown.salesTax ?? 0)

        var items: [FeeDisplayItem] = []

        if gratuity > 0 {
            items.append(FeeDisplayItem(
                title: breakdown.gratuityName ?? "Gratuity",
                amount: gratuity
            ))
        }

        if salesTax > 0 {
            items.append(FeeDisplayItem(
                title: breakdown.salesTaxName ?? "Sales Tax",
                amount: salesTax
            ))
        }

     
        feesAndTaxes = items
        feesAndTaxesTitleView.isHidden = items.isEmpty
        feesAndTaxesTableParentView.isHidden = items.isEmpty
        feesAndTaxesTableView.reloadData()
        feesAndTaxesTableView.layoutIfNeeded()
        feesAndTaxesTableViewHeight.constant = feesAndTaxesTableView.contentSize.height

        if discount > 0 {
            discountView.isHidden = false
            discountToalLbl.isHidden = false
            discountToalLbl.text = "-\(CurrencyFormatter.amount(discount, symbol: currency, position: currencyPosition))"
        } else {
            discountView.isHidden = true
            discountToalLbl.isHidden = true
            discountToalLbl.text = ""
        }

        let total = max(base + gratuity + salesTax + items.reduce(0) { $0 + $1.amount } - discount, 0)
        let feesOnly = max(total - base, 0)

        tableMinimumDepositLbl.text = "\(CurrencyFormatter.amount(base, symbol: currency, position: currencyPosition))"
        totalAmountLbl.text = total <= 0 ? "Free" : CurrencyFormatter.amount(total, symbol: currency, position: currencyPosition)
        feesAndTxtTotalAmountLbl.text = feesOnly > 0 ? CurrencyFormatter.amount(feesOnly, symbol: currency, position: currencyPosition) : ""

        view.layoutIfNeeded()
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        BookingQueueSocketManager.shared.disconnect()
        Navigate.to.back(self)
    }

    @IBAction func onClickAddPromoCode(_ sender: Any) {
//        let isHidden = promoCodeTextFeildView.isHidden

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

        guard let eventId = event?.id,
              let venueId = venueDetails?.id ?? event?.venue?.id,
              let tableBookingId = booking?.content?.tableBooking?.id,
              !tableBookingId.isEmpty else {
            submitPromoCodeBtn.hideLoader()
            Alert.showToast("Booking details not found")
            return
        }

        if isPromoCodeApplied {
            TablePresenter.removeCode(
                eventId: eventId,
                tableBookingId: tableBookingId,
                venueId: venueId
            ) { [weak self] success, message, data in
                guard let self = self else { return }

                self.submitPromoCodeBtn.hideLoader()

                if success, let data = data {
                    self.isPromoCodeApplied = false
                    self.appliedPromoCode = ""
                    self.promoCodeTextFeild.text = ""
                    self.promoCodeTextFeild.isUserInteractionEnabled = true
                    self.promoCodeTextFeild.alpha = 1
                    self.updatePromoButtonIcon()
                    self.updateUIAfterPromoCode(data)
                    Alert.showToast("Promo code removed")
                } else {
                    Alert.showToast(message ?? "Failed to remove promo code")
                }
            }
            return
        }

        guard !promo.isEmpty else {
            submitPromoCodeBtn.hideLoader()
            return
        }

        TablePresenter.applyCode(
            eventId: eventId,
            tableBookingId: tableBookingId,
            code: promo,
            venueId: venueId
        ) { [weak self] success, message, data in
            guard let self = self else { return }

            self.submitPromoCodeBtn.hideLoader()

            if success, let data = data {
                self.isPromoCodeApplied = true
                self.appliedPromoCode = promo
                self.promoCodeTextFeild.isUserInteractionEnabled = false
                self.promoCodeTextFeild.alpha = 0.5
                self.updatePromoButtonIcon()
                self.updateUIAfterPromoCode(data)
                Alert.showToast("Promo code applied")
            } else {
                Alert.showToast(message ?? "Failed to apply promo code")
            }
        }
    }
    @IBAction func onClickPurchaseTicket(_ sender: Any) {
        if isPaymentInitiated { return }
        isPaymentInitiated = true

        if isFreeBooking {
            isPaymentInitiated = false
            self.completePaymentSuccess()
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
    
    @IBAction func onClickAddNote(_ sender: Any) {
        questionsORcommentsView.isHidden.toggle()
    }
    
    
    @IBAction func onClickTermViewMoreBtn(_ sender: Any) {
        isTermsExpanded.toggle()

        if isTermsExpanded {
            termsLbl.numberOfLines = 0
            termViewMoreBtn.setTitle("View Less", for: .normal)
        } else {
            termsLbl.numberOfLines = termsCollapsedLines
            termViewMoreBtn.setTitle("View More", for: .normal)
        }
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
            cell.guestLbl.attributedText = buildGuestsTimeText(
                guests: item.guests,
                time: item.timeSlot
            )
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
            cell.amountLbl.text = CurrencyFormatter.amount(item.amount, symbol: currency, position: currencyPosition)
            
            return cell
        }

    }
}

private struct TableCheckoutItem {
    let title: String
    let value: String
}
