//
//  CheckOutVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/02/23.
//

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet

final class CheckOutVC: UIViewController, ApplePayContextDelegate {

    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var infoLbl: UILabel!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var paymentMethodView: UIView!
    @IBOutlet private weak var paymentMethodImg: UIImageView!
    @IBOutlet private weak var buyNowBtn: UIButton!

    var venueAttachment = ""
    var venueLogo = ""
    var selectedAppClipTickets = [AppClipTicket]()
    var selectedEventTicket = [EventTicket]()
    var totalPrice = 0
    var venueName = ""
    var venueId = ""
    var type: PaymentIntentType = .appClip
    private var paymentSheet: PaymentSheet?
    private var paymentIntent = ""
    private var paymentHistoryId = ""
    private var ephemeralKey = ""
    private var selectedId = Constant.String.defaultSelectedPM
    private var bookingId = ""
    private var isApplePayNotSupported: Bool {
        !PKPaymentAuthorizationViewController.canMakePayments()
    }
    private var isPaymentInitiated = false
    private var ticketListHeightObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        createBooking()
        WebSocketWrapper.shared.delegate.append(self)
        totalPriceLbl.text = "$\(totalPrice)"
        buyNowBtn.alpha = 0.5
        buyNowBtn.isUserInteractionEnabled = false
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickPaymentMethod))
        paymentMethodView.addGestureRecognizer(tap)
    }
    
    @objc private func onClickPaymentMethod() {
        Navigate.to.paymentMethodsVc(self, selectedId: selectedId)
    }
    
    private func alertForWallet() {
        let title = isApplePayNotSupported ? Constant.String.notSupported : Constant.String.addCardToApplePay
        let message = isApplePayNotSupported ? Constant.String.applePayNotSupported : Constant.String.addCardToYourApplePayWallet
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let setUpAction = UIAlertAction(title: "Add Card", style: .default) { (_) in
            if let url = URL(string: "wallet://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(okAction)
        alertController.addAction(setUpAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func createBooking() {
        var appClipTickets = [[String: Any]]()
        switch type {
        case .appClip:
            selectedAppClipTickets.forEach {
                appClipTickets.append(["ticketId": $0.id,
                                       "ticketQuantity": $0.selectedQuantity ?? 0])
            }
        case .singleTickedEvent:
            selectedEventTicket.forEach {
                appClipTickets.append(["ticketId": $0.id,
                                       "ticketQuantity": $0.selectedTicketCount ?? 0])
            }
        case .tieredTickedEvent:
            break
        }
        Loader.show()
        PaymentPresenter.createBooking(phone: UserDefault.shared.user?.phone ?? "", appClipTickets: appClipTickets, venueId: venueId) { [weak self] isSuccess, errMsg, id in
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
    }
        
    private func addPaymentApi() {
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
        PaymentPresenter.getPaymentIntent(bookingId: bookingId, selectedTickets: appClipTickets, type: type) { isSuccess, errMsg, clientSecret, paymentHistoryId, ephemeralKey in
            if isSuccess {
                guard let clientSecret = clientSecret else { Loader.hide(); return }
                self.paymentIntent = clientSecret
                self.paymentHistoryId = paymentHistoryId
                self.ephemeralKey = ephemeralKey
                self.setUpPaymentBottomSheet()
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            Loader.hide()
        }
    }
    
    private func setUpPaymentBottomSheet() {
        STPAPIClient.shared.publishableKey = "pk_live_51MVrDLBuSsaUd7BTVNumpYdLm1NT3cnQF2HmwWRmedtNmDiHm20T8kwmPMSSI7lEXzSbfyXrJ2hcBqOMOJv0h0TD00krZxi0Tg"
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"
        configuration.customer = .init(id: "cus_NjIf65HxFjE65P", ephemeralKeySecret: ephemeralKey)
        configuration.savePaymentMethodOptInBehavior = .automatic
        // Set `allowsDelayedPaymentMethods` to true if your business can handle payment
        // methods that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = true
        paymentSheet = PaymentSheet(paymentIntentClientSecret: self.paymentIntent, configuration: configuration)
        DispatchQueue.main.async {
            self.buyNowBtn.alpha = 1
            self.buyNowBtn.isUserInteractionEnabled = true
        }
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction private func onClickBuy(_ sender: Any) {
        if selectedId == Constant.String.defaultSelectedPM {
            applePayButtonTapped()
        } else {
            onClickCreditCardPay()
        }
    }

    private func onClickCreditCardPay() {
        // MARK: Start the checkout process
        isPaymentInitiated = true
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                self.paymentStatus {
                    Navigate.to.QRCode(self, venueName: self.venueName, bookingId: self.bookingId, venueAttachment: self.venueAttachment, venueLogo: self.venueLogo, selectedTickets: self.selectedAppClipTickets)
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
        if StripeAPI.deviceSupportsApplePay() == false {
            alertForWallet()
            return
        }
        isPaymentInitiated = true
        let merchantIdentifier = "merchant.com.speakeasy"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")

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
            // There is a problem with your Apple Pay configuration
        }
    }
    
    private func paymentStatus(completion: @escaping (()-> Void)) {
        Loader.show()
        PaymentPresenter.successPayment(paymentHistoryId: paymentHistoryId, bookingId: bookingId) { isSuccess, errMsg in
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
            paymentStatus {
                Navigate.to.QRCode(self, venueName: self.venueName, bookingId: self.bookingId, venueAttachment: self.venueAttachment, venueLogo: self.venueLogo, selectedTickets: self.selectedAppClipTickets)
            }
        case .error:
            self.isPaymentInitiated = false
            let alert = UIAlertController(title: "Alert", message: "Payment field", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        case .userCancellation:
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
        if self.navigationController?.viewControllers.last is CheckOutVC && self.venueId == uniqueId {
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
                Alert.showAlertSheet(style: .alert, title: "Update", message: "Venue your trying to booking, updated it's price",actions: [okAction])
            }
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
