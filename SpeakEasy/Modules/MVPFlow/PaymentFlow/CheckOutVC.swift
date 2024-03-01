//
//  CheckOutVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/02/23.
//

protocol UpdateDetailDelegate: AnyObject {
    func update()
}

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet

final class CheckOutVC: UIViewController, ApplePayContextDelegate {

    @IBOutlet private weak var purchaseImg: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet private weak var dateLbl: UILabel!
    @IBOutlet private weak var venueNameLbl: UILabel!
    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var infoLbl: UILabel!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var paymentMethodView: UIView!
    @IBOutlet private weak var paymentMethodImg: UIImageView!
    @IBOutlet private weak var buyNowBtn: UIButton!
    @IBOutlet private weak var policyCheckBox: UIButton!
    @IBOutlet private weak var policyView: UIView!
    @IBOutlet private weak var policyLbl: UILabel!
    @IBOutlet private weak var subTotalView: UIView!
    @IBOutlet private weak var processingFeesView: UIView!
    @IBOutlet private weak var customFeesView: UIView!
    @IBOutlet private weak var customFeeAmount: UILabel!
    @IBOutlet private weak var customFeeNameLbl: UILabel!
    @IBOutlet private weak var subTotalAmount: UILabel!
    @IBOutlet private weak var processingFeeAmount: UILabel!
    @IBOutlet private weak var timerLbl: UILabel!
    @IBOutlet private weak var noFeeView: UIView!
    @IBOutlet weak var salesTexView: UIView!
    @IBOutlet weak var salesTaxAmount: UILabel!
    @IBOutlet weak var salesTaxPr: UILabel!
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var promoCodeView: UIView!
    @IBOutlet weak var promoCodeTF: UITextField!
    @IBOutlet weak var applyPromoCodeBtn: UIButton!
    @IBOutlet weak var discountView: UIView!
    @IBOutlet weak var discountAmount: UILabel!
    @IBOutlet weak var promoCodeAppliedLbl: UILabel!
    @IBOutlet weak var salesTaxName: UILabel!
    
    var selectedAppClipTickets = [AppClipTicket]()
    var selectedAddOnsItem = [UpSellTicket]()
    var selectedEventTicket = [EventTicket]()
    var totalPrice: Double = 0
    var venue: ClipVenue?
    var type: PaymentIntentType = .appClip
    var event: Event?
    var promoteId = ""
    private var paymentSheet: PaymentSheet?
    private var paymentIntent = ""
    private var paymentHistoryId = ""
    private var ephemeralKey = ""
    private var paymentDetail: PaymentDetail?
    private var selectedId = Constant.String.defaultSelectedPM
    private var bookingId = ""
    private var isApplePayNotSupported: Bool {
        !PKPaymentAuthorizationViewController.canMakePayments()
    }
    private var isPaymentInitiated = false
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var timer = Timer()
    private var count = 600
    private var lastCount = 0
    private var enterBgDate = Date()
    private var exitBgDate = Date()
    private var isFromApplePay = false
    weak var updateDelegate: UpdateDetailDelegate?
    private var isPromoCodeApplied = false
    var isFreeTicket = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedAppClipTickets.count != 0 || selectedEventTicket.count != 0 {
            createBooking()
        } else {
            getAddOnsPaymentIntent(bookingId: "")
        }
        totalPriceLbl.text = "-"
        buyNowBtn.alpha = 0.5
        buyNowBtn.isUserInteractionEnabled = false
        setUpData()
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickPaymentMethod))
        paymentMethodView.addGestureRecognizer(tap)
        
        infoLbl.text = type == .appClip ? Constant.String.checkoutTextCover : Constant.String.checkoutTextEvent
        // \(type == .appClip ? Constant.String.coverTicketText : "")"
        infoLbl.highlightBold(["terms of service", "privacy policy"], size: 12, textColor: .white, addUnderLine: true)
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onClickInfoLabel(_:)))
        infoLbl.addGestureRecognizer(tap1)
        infoLbl.isUserInteractionEnabled = true
        policyCheckBox.setImage(CommonConstant.Icon.checkBoxEmpty, for: .normal)
        policyCheckBox.setImage(CommonConstant.Icon.checkBoxFull, for: .selected)
        policyCheckBox.isSelected = true
        let time = secondsToHoursMinutesSeconds(seconds: count)
        timerLbl.text = makeTimeString(minutes: time.0, seconds: time.1)
        validateBtn(isValid: false)
        promoCodeTF.addTarget(self, action: #selector(promoCodeValueChange), for: .allEvents)
        applyPromoCodeBtn.isSelected = false
        applyPromoCodeBtn.setTitle("Remove", for: .selected)
        applyPromoCodeBtn.setTitle("Apply Code", for: .normal)
        // background event
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackGround), name: UIApplication.didEnterBackgroundNotification, object: nil)
        // foreground event
        NotificationCenter.default.addObserver(self, selector: #selector(exitBackGround), name: UIApplication.willEnterForegroundNotification, object: nil)
        // add these 2 notifications to prevent freeze on long Home button press and back
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackGround), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(exitBackGround), name: UIApplication.didBecomeActiveNotification, object: nil)
        startTimer()
        navigationController?.interactivePopGestureRecognizer?.addTarget(self, action: #selector(handleBackSwipe))
    }
    
    @objc private func handleBackSwipe() {
        navigationController?.interactivePopGestureRecognizer?.removeTarget(self, action: #selector(handleBackSwipe))
        cancelBooking()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WebSocketWrapper.shared.delegate.append(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        WebSocketWrapper.shared.delegate.removeAll(where: { $0 as? NSObject == self })
    }
    
    private func setUpData() {
        switch type {
        case .appClip:
            noFeeView.isHidden = (venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == true) ? false : (venue?.venueSettings?.coverTicketFeesSettings?.isEnableSalesTax == true || venue?.venueSettings?.coverTicketFeesSettings?.isProcessingFeePassToCustomer == true || venue?.venueSettings?.coverTicketFeesSettings?.isEnableCustomFee == true)
            titleLbl.text = Constant.String.liveCoverTicket
            dateLbl.text = "Tonight"
            purchaseImg.image = Constant.Icon.liveCover
            bgImage.image = Constant.Icon.liveCover
            promoCodeView.isHidden = true
            venueNameLbl.text = venue?.name ?? ""
        case .singleTickedEvent:
            noFeeView.isHidden = !(event?.upfront == true)
            titleLbl.text = event?.title ?? "Untitle Event"
            dateLbl.text = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: event?.venue?.useTimezone ?? "")
            purchaseImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            bgImage.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            promoCodeView.isHidden = false
            venueNameLbl.text = (event?.customVenue != nil && venue?.venueSettings?.isOrganizer == true) ? "\(event?.customVenue?.name ?? ""), \(event?.customVenue?.address ?? "")" : "\(venue?.name ?? "")"
        case .tieredTickedEvent:
            break
        }
        policyView.isHidden = !(venue?.venueSettings?.optedPolicy == true)
        policyLbl.text = venue?.venueSettings?.policyText ?? "Opt in for future messages"
    }
        
    @objc func exitBackGround() {
        if isFromApplePay {
            isFromApplePay = false
            return
        }
        exitBgDate = Date()
        let diff = exitBgDate.timeIntervalSince(enterBgDate)
        enterBgDate = exitBgDate
        count = count - Int(diff)
    }
    
    @objc func enterBackGround() {
        enterBgDate = Date()
    }
    
    func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int) {
        return (((seconds % 3600) / 60),((seconds % 3600) % 60))
    }
    
    func makeTimeString(minutes: Int, seconds : Int) -> String {
        "\(String(format: "%01d", minutes)):\(String(format: "%02d", seconds))"
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.count = self.count - 1
            if self.count <= 0 {
                timer.invalidate()
                self.crossTimeLimit()
            }
            let time = self.secondsToHoursMinutesSeconds(seconds: self.count)
            let timeString = self.makeTimeString(minutes: time.0, seconds: time.1)
            if self.count < 0 {
                self.timerLbl.text = "00:00"
            } else {
                self.timerLbl.text = timeString
            }
        }
    }
    
    private func crossTimeLimit() {
        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
            self.timer.invalidate()
            self.cancelBooking()
            self.updateDelegate?.update()
            Navigate.to.back(self)
        }
        Alert.showAlertSheet(style: .alert, title: "Sorry, your ticket reservation has expired, please try again", message: "", actions: [okAction])
    }
    
    @objc private func onClickPaymentMethod() {
        Navigate.to.paymentMethodsVc(self, selectedId: selectedId)
    }
    
    private func alertForWallet() {
        let title = isApplePayNotSupported ? Constant.String.notSupported : Constant.String.addCardToApplePay
        let message = isApplePayNotSupported ? Constant.String.applePayNotSupported : Constant.String.addCardToYourApplePayWallet
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.isFromApplePay = true
        }
        let setUpAction = UIAlertAction(title: "Add Card", style: .default) { (_) in
            if let url = URL(string: "wallet://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(okAction)
        alertController.addAction(setUpAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func onClickInfoLabel(_ sender: UITapGestureRecognizer) {
        if let range = infoLbl.text?.range(of: "terms of service")?.nsRange, sender.didTapAttributedTextInLabel(label: infoLbl, inRange: range) {
            Navigate.externalURL(APIBuilder.termsConsumerURL)
        }
        
        if let range = infoLbl.text?.range(of: "privacy policy")?.nsRange, sender.didTapAttributedTextInLabel(label: infoLbl, inRange: range) {
            Navigate.externalURL(APIBuilder.privacyConsumerURL)
        }
    }
    
    private func createBooking() {
        var tickets = [[String: Any]]()
        switch type {
        case .appClip:
            selectedAppClipTickets.forEach {
                tickets.append(["ticketId": $0.id,
                                       "ticketQuantity": $0.selectedQuantity ?? 0])
            }
            Loader.show()
            PaymentPresenter.createCoverBooking(appClipTickets: tickets, venueId: venue?.id ?? "") { [weak self] isSuccess, errMsg, id in
                guard let self = self else {
                    Loader.hide()
                    return
                }
                if isSuccess {
                    guard let id = id else {
                        Loader.hide()
                        Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                        return
                    }
                    self.bookingId = id
                    self.addPaymentApi()
                } else {
                    if errMsg != nil {
                        Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                    } else {
                        Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                    }
                    Loader.hide()
                }
            }
        case .singleTickedEvent:
            selectedEventTicket.forEach {
                tickets.append(["ticketId": $0.id,
                                       "ticketQuantity": $0.selectedTicketCount ?? 0])
            }
            Loader.show()
            PaymentPresenter.createEventBooking(eventId: event?.id ?? "", phone: UserDefault.shared.user?.phone ?? "", userId: UserDefault.shared.user?.id ?? "", tickets: tickets, promoteId: promoteId) { [weak self] isSuccess, errMsg, id in
                guard let self = self else {
                    Loader.hide()
                    return
                }
                if isSuccess {
                    guard let id = id else {
                        Loader.hide()
                        Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                        return
                    }
                    self.bookingId = id
                    self.addPaymentApi()
                } else {
                    if errMsg != nil {
                        Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                    } else {
                        Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                    }
                    Loader.hide()
                }
            }
        case .tieredTickedEvent:
            break
        }
    }
    
    private func cancelBooking() {
        timer.invalidate()
        PaymentPresenter.cancelBooking(bookingId: bookingId) { _, _ in
        }
    }
    
    private func addPaymentApi() {
        Loader.show()
        var appClipTickets = [[String: Any]]()
        switch type {
        case .appClip:
            selectedAppClipTickets.forEach {
                appClipTickets.append(["ticketId": $0.id,
                                       "quantity": $0.selectedQuantity ?? 0])
            }
        case .singleTickedEvent:
            selectedEventTicket.forEach {
                appClipTickets.append(["ticketId": $0.id,
                                       "quantity": $0.selectedTicketCount ?? 0])
            }
        case .tieredTickedEvent:
            break
        }
        PaymentPresenter.getPaymentIntent(bookingId: bookingId, selectedTickets: appClipTickets, promoCode: promoCodeTF.text ?? "", type: type) { isSuccess, errMsg, clientSecret, paymentHistoryId, ephemeralKey, paymentDetail, isFreeTicket  in
            if isSuccess {
                guard let clientSecret = clientSecret else { Loader.hide(); return }
                if isFreeTicket {
                    self.paymentMethodView.isHidden = true
                    self.buyNowBtn.setTitle("GET FREE TICKET", for: .normal)
                } else {
                    self.paymentMethodView.isHidden = false
                    self.buyNowBtn.setTitle("BUY TICKET", for: .normal)
                }
                self.isFreeTicket = isFreeTicket
                self.paymentIntent = clientSecret
                self.paymentHistoryId = paymentHistoryId
                self.ephemeralKey = ephemeralKey
                self.paymentDetail = paymentDetail
                if self.isPromoCodeApplied {
                    self.applyPromoCodeBtn.setTitle("Remove", for: .normal)
                } else {
                    self.applyPromoCodeBtn.setTitle("Apply Code", for: .normal)
                }
                self.promoCodeAppliedLbl.isHidden = self.isPromoCodeApplied ? false : true
                self.promoCodeAppliedLbl.text = self.isPromoCodeApplied ? "Promo Code Applied." : ""
                self.promoCodeAppliedLbl.textColor = .white
                self.promoCodeTF.isUserInteractionEnabled = self.isPromoCodeApplied ? false : true
                self.promoCodeTF.alpha = self.isPromoCodeApplied ? 0.5  : 1
                if self.type == .appClip && self.selectedAddOnsItem.count != 0 {
                    self.getAddOnsPaymentIntent(bookingId: self.bookingId)
                } else {
                    self.setUpPaymentBottomSheet()
                }
               
            } else {
                if errMsg != nil {
                    if self.isPromoCodeApplied == true {
                        self.promoCodeAppliedLbl.isHidden = false
                        self.promoCodeAppliedLbl.text = errMsg
                        self.promoCodeAppliedLbl.textColor = .red
                        self.isPromoCodeApplied = false
                    } else {
                        Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                    }
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            Loader.hide()
        }
    }
    
    private func getAddOnsPaymentIntent(bookingId: String) {
        var addOnsItems = [[String: Any]]()
        selectedAddOnsItem.forEach {
            addOnsItems.append(["id": $0.id,
                                "addOnsId": $0.addOns.id,
                                "quantity": $0.selectedQuantity ?? 0])
        }
        Loader.show()
        PaymentPresenter.addOnsPaymentIntent(bookingId: bookingId, venueId: venue?.id ?? "", addOnsItems: addOnsItems) { isSuccess, errMsg, clientSecret, ephemeralKey, paymentDetail in
            Loader.hide()
            if isSuccess {
                self.bookingId = bookingId
                self.paymentIntent = clientSecret ?? ""
                self.ephemeralKey = ephemeralKey
                self.paymentDetail = paymentDetail
                self.setUpPaymentBottomSheet()
            } else {
                Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
            }
        }
    }
    
    private func createFreeEventBooking() {
        var tickets = [[String: Any]]()
        selectedEventTicket.forEach {
            tickets.append(["ticketId": $0.id,
                            "ticketQuantity": $0.selectedTicketCount ?? 0])
        }
        Loader.show()
        PaymentPresenter.createEventFreeBooking(eventId: event?.id ?? "", phone: UserDefault.shared.user?.phone ?? "", userId: UserDefault.shared.user?.id ?? "", tickets: tickets, bookingId: bookingId) { [weak self] isSuccess, errMsg, id in
            guard let self = self else {
                Loader.hide()
                return
            }
            Loader.hide()
            if isSuccess, let id = id {
                self.timer.invalidate()
                Navigate.to.showQRCode(self, booking: nil, bookingId: id, type: .singleTickedEvent)
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
    
    private func setUpPaymentBottomSheet() {
        STPAPIClient.shared.publishableKey = Stripe.publishableKey
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"
        configuration.customer = .init(id: UserDefault.shared.user?.stripeCusId ?? "", ephemeralKeySecret: ephemeralKey)
        configuration.savePaymentMethodOptInBehavior = .automatic
        // Set `allowsDelayedPaymentMethods` to true if your business can handle payment
        // methods that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = true
        paymentSheet = PaymentSheet(paymentIntentClientSecret: self.paymentIntent, configuration: configuration)
        DispatchQueue.main.async {
            self.buyNowBtn.alpha = 1
            self.buyNowBtn.isUserInteractionEnabled = true
            self.displayPayment()
        }
    }
    
    private var setSalesTaxView: Bool {
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == true }) {
            salesTaxPr.text = "(\(venue?.venueSettings?.customCoverTicketFeesSettings?.salesTax ?? 0.0)%)"
            return venue?.venueSettings?.customCoverTicketFeesSettings?.isEnableSalesTax == true ? true : false
        }
        
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == false }) {
            salesTaxPr.text = "(\(venue?.venueSettings?.coverTicketFeesSettings?.salesTax ?? 0.0)%)"
            return venue?.venueSettings?.coverTicketFeesSettings?.isEnableSalesTax == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false ? true : false
        }
        
        if (venue?.venueSettings?.coverTicketFeesSettings?.isEnableSalesTax == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketFeesSettings?.isEnableSalesTax == true {
            return true
        }
        return false
    }
    
    private var setCustomTaxView: Bool {
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == true }) {
            return venue?.venueSettings?.customCoverTicketFeesSettings?.isEnableCustomFee == true ? true : false
        }
        
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == false }) {
            return venue?.venueSettings?.coverTicketFeesSettings?.isEnableCustomFee == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false ? true : false
        }
        
        if (venue?.venueSettings?.coverTicketFeesSettings?.isEnableCustomFee == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketFeesSettings?.isEnableCustomFee == true {
            return true
        }
        return false
    }
    
    private var setProcessingTaxView: Bool {
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == true }) {
            return venue?.venueSettings?.customCoverTicketFeesSettings?.isProcessingFeePassToCustomer == true ? true : false
        }
        
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == false }) {
            return venue?.venueSettings?.coverTicketFeesSettings?.isProcessingFeePassToCustomer == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false ? true : false
        }
        
        if (venue?.venueSettings?.coverTicketFeesSettings?.isProcessingFeePassToCustomer == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketFeesSettings?.isProcessingFeePassToCustomer == true {
            return true
        }
        return false
    }

    
    private func displayPayment() {
        switch type {
        case .singleTickedEvent:
            totalPriceLbl.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((paymentDetail?.total ?? 0).decimalFormat(true))"
            totalPrice = paymentDetail?.total ?? 0
            subTotalAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((paymentDetail?.subTotal ?? 0).decimalFormat(true))"
            processingFeeAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((paymentDetail?.processingFee ?? 0).decimalFormat(true))"
            salesTaxName.text = paymentDetail?.salesTaxName ?? "" == "" ? "Sales Tax" : paymentDetail?.salesTaxName
            if paymentDetail?.customFee ?? 0 == 0 {
                customFeesView.isHidden = true
            } else {
                customFeeAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((paymentDetail?.customFee ?? 0).decimalFormat(true))"
                customFeeNameLbl.text = paymentDetail?.customFeeName ?? "Custom fee"
                customFeesView.isHidden = false
            }
            if paymentDetail?.discount ?? 0 == 0 {
                discountView.isHidden = true
            } else {
                discountView.isHidden = false
                discountAmount.text = "-\(venue?.venueSettings?.currencySymbol ?? "$")\((paymentDetail?.discount ?? 0).decimalFormat(true))"
            }
            subTotalView.isHidden = false
            processingFeesView.isHidden = false
            if event?.upfront == true {
                if paymentDetail?.discount ?? 0 == 0 {
                    subTotalView.isHidden = true
                    discountView.isHidden = true
                } else {
                    subTotalView.isHidden = false
                    discountView.isHidden = false
                }
                processingFeesView.isHidden = true
                customFeesView.isHidden = true
                return
            }
        default:

            subTotalView.isHidden = !setSalesTaxView && !setProcessingTaxView && !setCustomTaxView
            salesTexView.isHidden = !setSalesTaxView
            processingFeesView.isHidden = !setProcessingTaxView
            customFeesView.isHidden = !setCustomTaxView
            noFeeView.isHidden = !subTotalView.isHidden

//            salesTaxPr.text = "(\(venue?.venueSettings?.coverTicketFeesSettings?.salesTax ?? 0.0)%)"
            customFeeAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((paymentDetail?.customFee ?? 0).decimalFormat(true))"
            processingFeeAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((paymentDetail?.processingFee ?? 0).decimalFormat(true))"
            totalPriceLbl.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((paymentDetail?.total ?? 0).decimalFormat(true))"
            totalPrice = paymentDetail?.total ?? 0
            salesTaxAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((paymentDetail?.salesTax ?? 0).decimalFormat(true))"
            subTotalAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((paymentDetail?.subTotal ?? 0).decimalFormat(true))"
            customFeeNameLbl.text = paymentDetail?.customFeeName ?? "Custom fee"
            salesTaxName.text = paymentDetail?.salesTaxName ?? "" == "" ? "Sales Tax" : paymentDetail?.salesTaxName
        }
    }
    
    @objc func promoCodeValueChange() {
        let valid = promoCodeTF.text ?? "" != ""
        validateBtn(isValid: valid)
    }
    
    private func validateBtn(isValid: Bool) {
        applyPromoCodeBtn.alpha = isValid ? 1 : 0.5
        applyPromoCodeBtn.isUserInteractionEnabled = isValid ? true : false
    }
    
    @IBAction func onClickApplyCode(_ sender: Any) {
        isPromoCodeApplied.toggle()
        if !isPromoCodeApplied {
            promoCodeTF.text = ""
        }
        addPaymentApi()
    }
    
    @IBAction private func onClickPolicyCheckBox(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        timer.invalidate()
        cancelBooking()
        updateDelegate?.update()
        Navigate.to.back(self)
    }
    
    @IBAction private func onClickBuy(_ sender: Any) {
        if isFreeTicket {
            createFreeEventBooking()
        } else {
            if selectedId == Constant.String.defaultSelectedPM {
                applePayButtonTapped()
            } else {
                onClickCreditCardPay()
            }
        }
    }

    private func onClickCreditCardPay() {
        // MARK: Start the checkout process
        isPaymentInitiated = true
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                self.paymentStatus(optedPolicy: self.venue?.venueSettings?.optedPolicy == true ? self.policyCheckBox.isSelected : nil) {
                    if self.selectedAddOnsItem.count == 0 {
                        self.timer.invalidate()
                        Navigate.to.showQRCode(self, booking: nil, bookingId: self.bookingId, type: self.type)
                    } else {
                        self.addOnsPaymentSuccess {
                            self.timer.invalidate()
                            Navigate.to.showQRCode(self, booking: nil, bookingId: self.bookingId, type: self.type)
                        }
                    }
                }
            case .canceled:
                self.isPaymentInitiated = false
//                let alert = UIAlertController(title: "Alert", message: "Payment interrupted", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
            case .failed:
                self.isPaymentInitiated = false
                let alert = UIAlertController(title: "Alert", message: "Payment failed", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func applePayButtonTapped() {
        isFromApplePay = true
        if StripeAPI.deviceSupportsApplePay() == false {
            alertForWallet()
            return
        }
        isPaymentInitiated = true
        let merchantIdentifier = "merchant.com.speakeasy"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: venue?.venueSettings?.currencyCode?.uppercased() ?? "USD")

        // Configure the line items on the payment request
        paymentRequest.paymentSummaryItems = [
            // The final line should represent your company;
            // it'll be prepended with the word "Pay" (that is, "Pay iHats, Inc $50")
            PKPaymentSummaryItem(label: "Speakeasy Bookings Inc. (VIA Speakeasy Go!)", amount: NSDecimalNumber(value: totalPrice)),
        ]
        paymentRequest.requiredBillingContactFields = []
        // Initialize an STPApplePayContext instance
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            // Present Apple Pay payment sheet
            applePayContext.presentApplePay()
        } else {
            Alert.showToast("Problem with your Apple Pay")
            // There is a problem with your Apple Pay configuration
        }
    }
    
    private func paymentStatus(optedPolicy: Bool? = nil, completion: @escaping (()-> Void)) {
        Loader.show()
        PaymentPresenter.successPayment(paymentHistoryId: paymentHistoryId, bookingId: bookingId, optedPolicy: optedPolicy) { isSuccess, errMsg in
            Loader.hide()
            if isSuccess {
                completion()
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
    
    private func addOnsPaymentSuccess(completion: @escaping (()-> Void)) {
        Loader.show()
        PaymentPresenter.successAddOnsPayment(bookingId: bookingId) { isSuccess, errMsg in
            Loader.show()
            if isSuccess {
                completion()
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
}

extension CheckOutVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch type {
        case .appClip:
            return selectedAppClipTickets.count
        case .singleTickedEvent:
            return selectedEventTicket.count
        case .tieredTickedEvent:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        switch type {
        case .appClip:
            cell.titleLbl.text = selectedAppClipTickets[indexPath.row].name
            cell.subTitleLbl.text = selectedAppClipTickets[indexPath.row].description
            cell.quantityLbl.text = "\(selectedAppClipTickets[indexPath.row].selectedQuantity ?? 0)x"
        case .singleTickedEvent:
            cell.titleLbl.text = selectedEventTicket[indexPath.row].tierName
            cell.subTitleLbl.text = selectedEventTicket[indexPath.row].tierDescription
            cell.quantityLbl.text = "\(selectedEventTicket[indexPath.row].selectedTicketCount ?? 0)x"
        case .tieredTickedEvent:
            break
        }
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}

extension CheckOutVC {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        let clientSecret = paymentIntent
        // Call the completion block with the client secret or an error
        completion(clientSecret, nil)
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        switch status {
        case .success:
            paymentStatus(optedPolicy: venue?.venueSettings?.optedPolicy == true ? policyCheckBox.isSelected : nil) {
                if self.selectedAddOnsItem.count == 0 {
                    self.timer.invalidate()
                    Navigate.to.showQRCode(self, booking: nil, bookingId: self.bookingId, type: self.type)
                } else {
                    self.addOnsPaymentSuccess {
                        self.timer.invalidate()
                        Navigate.to.showQRCode(self, booking: nil, bookingId: self.bookingId, type: self.type)
                    }
                }
            }
        case .error:
            isFromApplePay = true
            self.isPaymentInitiated = false
            let alert = UIAlertController(title: "Alert", message: "Payment field", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        case .userCancellation:
            isFromApplePay = true
            self.isPaymentInitiated = false
//            let alert = UIAlertController(title: "Alert", message: "Payment interrupted", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
//            present(alert, animated: true, completion: nil)
        @unknown default:
            fatalError()
        }
    }
}

extension CheckOutVC: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        if isPaymentInitiated { return }
        if self.navigationController?.viewControllers.last is CheckOutVC && venue?.uniqueId ?? "" == uniqueId {
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                UIAlertAction in
                if let vc = self.navigationController?.viewControllers.first(where: { viewC in
                    viewC.isKind(of: MVPVenueListVc.self)
                }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                } else if let vc = self.navigationController?.viewControllers.first(where: { viewC in
                    viewC.isKind(of: MVPVenueDetailVc.self)
                }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                }
            }
            if isVenueStatusUpdate {
                Alert.showAlertSheet(style: .alert, title: "Update", message: "Venue your trying to booking is closed",actions: [okAction])
            } else if isPriceUpdated {
                Alert.showAlertSheet(style: .alert, title: "Update", message: "The venue updated their prices",actions: [okAction])
            }
        }
    }
    
    func didGenderWiseTicketChange(venueId: String, uniqueId: String) {
        if isPaymentInitiated { return }
        if self.navigationController?.viewControllers.last is CheckOutVC && venue?.uniqueId ?? "" == uniqueId && type == .appClip {
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                UIAlertAction in
                if let vc = self.navigationController?.viewControllers.first(where: { viewC in
                    viewC.isKind(of: MVPVenueListVc.self)
                }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                } else if let vc = self.navigationController?.viewControllers.first(where: { viewC in
                    viewC.isKind(of: MVPVenueDetailVc.self)
                }) {
                    self.navigationController?.popToViewController(vc, animated: true)
                }
            }
            Alert.showAlertSheet(style: .alert, title: "Update", message: "Venue your trying to booking, updated it's ticket",actions: [okAction])
        }
    }
    
    func didUpdateEventTicket(ticketId: String) {
        if isPaymentInitiated { return }
        print(ticketId)
        if selectedEventTicket.contains(where: { $0.id == ticketId }) {
            cancelBooking()
            Navigate.to.back(self)
        }
    }
}

extension CheckOutVC: PaymentMethodVCDelegate {
    func didSelectMethod(_ id: String, image: UIImage?) {
        selectedId = id
        paymentMethodImg.image = image
    }
    
    func addCard() {
        selectedId = Constant.String.addNewCard
        paymentMethodImg.image = Constant.Card.cardIc
        DispatchQueue.main.async {
            self.onClickCreditCardPay()
        }
    }
}
