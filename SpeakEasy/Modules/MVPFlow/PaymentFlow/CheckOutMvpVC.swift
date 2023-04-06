//
//  CheckOutMvpVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/02/23.
//

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet

final class CheckOutMvpVC: UIViewController, ApplePayContextDelegate {

//    @IBOutlet private weak var ticketTitleLbl: UILabel!
//    @IBOutlet private weak var totalPriceLbl: UILabel!
//    @IBOutlet private weak var applePayBtn: PKPaymentButton!
//    @IBOutlet private weak var creditCardPayBtn: UIButton!
//    @IBOutlet private weak var ticketQuantityLbl: UILabel!
    @IBOutlet weak var dressCodeInfoLbl: UILabel!
//    @IBOutlet weak var ticketSubTitleLbl: UILabel!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!

    var totalTicket = 1 // remove
    var ticketPrice = 1 // remove
    var isGeneralAdmission = false // remove
    var ticketInfo = "" // remove
    var appClipTicketId = "" // remove
    var venueAttachment = ""
    var venueLogo = ""
    var selectedTickets = [AppClipTicket]()
    private var paymentSheet: PaymentSheet?
    private var paymentIntent = ""
    private var paymentHistoryId = ""
    var venueName = ""
    var bookingId = ""
    var mvpDelegate = MVPPresenter()
    var venueId = ""
    var isApplePayNotSupported = false
    var isPaymentInitiated = false
    private var ticketListHeightObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        WebSocketWrapper.shared.delegate.append(self)
        
        dressCodeInfoLbl.highlightBold(["\"All entry subject to doorman discretion\"."], size: 15, textColor: .white)
//        ticketQuantityLbl.text = "\(totalTicket)x"
//        ticketTitleLbl.text = "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")"
//        totalPriceLbl.text = "$\(totalTicket * ticketPrice)"
//        ticketSubTitleLbl.text = ticketInfo
//
//        applePayBtn.addTarget(self, action: #selector(applePayButtonTapped), for: .touchUpInside)
//        creditCardPayBtn.isHidden = false
//        creditCardPayBtn.alpha = 0.5
//        creditCardPayBtn.isUserInteractionEnabled = false
//        applePayBtn.alpha = 0.5
//        applePayBtn.isUserInteractionEnabled = false
//        if PKPaymentAuthorizationViewController.canMakePayments() {
//            NotificationCenter.default.addObserver(self, selector: #selector(checkApplePay), name: UIApplication.willEnterForegroundNotification, object: nil)
//            NotificationCenter.default.addObserver(self, selector: #selector(checkApplePay), name: UIApplication.didBecomeActiveNotification, object: nil)
//        } else {
//            isApplePayNotSupported = true
//        }
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func getCustomTextFieldInputAccessoryView(with items: [UIBarButtonItem]) -> UIToolbar {
        let toolbar: UIToolbar = UIToolbar()
        
        toolbar.barStyle = UIBarStyle.default
        toolbar.items = items
        toolbar.sizeToFit()
        
        return toolbar
    }
    
//    @objc func checkApplePay() {
//        if StripeAPI.deviceSupportsApplePay() {
//            applePayBtn.isHidden = false
//        } else if isApplePayNotSupported == false {
//            applePayBtn.isHidden = false
//        } else {
//            applePayBtn.isHidden = true
//        }
//    }
    
    func alertForWallet() {
        let alertController = UIAlertController(title: "Add Card to Apple Pay", message: "Please add a card to your Apple Pay wallet and check again.", preferredStyle: .alert)
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
    
    func createBooking() {
        mvpDelegate.createBookingForMVP(phone: "", ticketId: appClipTicketId, totalTicket: (totalTicket)) { [weak self] isSuccess, errMsg, id in
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
        mvpDelegate.addPaymentApiForMVP(bookingId: bookingId, name: isGeneralAdmission ? "General Admission" : "VIP Skip the Line", price: self.ticketPrice, totalTicket: self.totalTicket) { isSuccess, errMsg, clientSecret, paymentHistoryId in
            if isSuccess {
                guard let clientSecret = clientSecret else { Loader.hide(); return }
                self.paymentIntent = clientSecret
                self.paymentHistoryId = paymentHistoryId
                self.setUpPaymentBottemSheet()
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
    
    private func setUpPaymentBottemSheet() {
        STPAPIClient.shared.publishableKey = "pk_test_51MVrDLBuSsaUd7BTwD22BrfvI0QvLhYMe1b4usjbCW5NefmUVgc0Th4ZrdeOBDL5Xdh3GgzYgvPsct7qFOw9q97W00Dx516uA1"
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"
        //        configuration.customer = .init(id: "customerId", ephemeralKeySecret: "customerEphemeralKeySecret")
        // Set `allowsDelayedPaymentMethods` to true if your business can handle payment
        // methods that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = true
        paymentSheet = PaymentSheet(paymentIntentClientSecret: self.paymentIntent, configuration: configuration)
//        DispatchQueue.main.async {
//            self.creditCardPayBtn.alpha = 1
//            self.creditCardPayBtn.isUserInteractionEnabled = true
//            self.applePayBtn.alpha = 1
//            self.applePayBtn.isUserInteractionEnabled = true
//        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func onClickCreditCardPay(_ sender: Any) {
        // MARK: Start the checkout process
        isPaymentInitiated = true
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                self.paymentStatus {
                    Navigate.to.qrCodeMvpVC(self, totalTicket: self.totalTicket, ticketPrice: self.ticketPrice, isGeneral: self.isGeneralAdmission, venueName: self.venueName, bookingId: self.bookingId,ticketInfo: self.ticketInfo, venueAttachment: self.venueAttachment, venueLogo: self.venueLogo)
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
    
    @objc private func applePayButtonTapped() {
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
            PKPaymentSummaryItem(label: "Speakeasy Bookings Inc. (VIA Speakeasy Go!)", amount: NSDecimalNumber(value: ticketPrice * totalTicket)),
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
    
    func paymentStatus(completion: @escaping (()-> Void)) {
        Loader.show()
        mvpDelegate.successPayment(paymentHistoryId: paymentHistoryId, bookingId: bookingId) { isSuccess, errMsg in
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

extension CheckOutMvpVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        cell.selectionStyle = .none
        return cell
    }
}


extension CheckOutMvpVC {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        let clientSecret = paymentIntent
        // Call the completion block with the client secret or an error
        completion(clientSecret, nil)
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        switch status {
        case .success:
            paymentStatus {
                Navigate.to.qrCodeMvpVC(self, totalTicket: self.totalTicket, ticketPrice: self.ticketPrice, isGeneral: self.isGeneralAdmission, venueName: self.venueName, bookingId: self.bookingId,ticketInfo: self.ticketInfo, venueAttachment: self.venueAttachment, venueLogo: self.venueLogo)
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

extension CheckOutMvpVC: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        if isPaymentInitiated { return }
        if self.navigationController?.viewControllers.last is CheckOutMvpVC && self.venueId == uniqueId {
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
