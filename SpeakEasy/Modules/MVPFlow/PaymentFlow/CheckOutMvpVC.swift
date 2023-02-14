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

    @IBOutlet private weak var phoneNoLbl: UILabel!
    @IBOutlet private weak var ticketTitleLbl: UILabel!
    @IBOutlet private weak var ticketPriceLbl: UILabel!
    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var applePayBtn: PKPaymentButton!
    @IBOutlet private weak var creditCardPayBtn: UIButton!
    @IBOutlet private weak var ticketQuantityLbl: UILabel!
    @IBOutlet weak var dressCodeInfoLbl: UILabel!
    
    var phoneNo = ""
    var totalTicket = 1
    var ticketPrice = 1
    var isGeneralAdmission = false
    private var paymentSheet: PaymentSheet?
    private var paymentIntent = ""
    private var paymentHistoryId = ""
    var venueName = ""
    var bookingId = ""
    var mvpDelegate = MVPPresenter()
    var isApplePayNotSupported = false

    override func viewDidLoad() {
        super.viewDidLoad()
        dressCodeInfoLbl.text = "*All entries subject to doorman discretion*  At \(self.venueName), we encourage smart, casual-elegant attire."
        dressCodeInfoLbl.highlightBold(["*All entries subject to doorman discretion*"], size: 15, textColor: .white)
        phoneNoLbl.text = phoneNo
        ticketQuantityLbl.text = "\(totalTicket)x"
        ticketTitleLbl.text = "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")"
        ticketPriceLbl.text = "$\(totalTicket * ticketPrice)"
        totalPriceLbl.text = "$\(totalTicket * ticketPrice)"
        applePayBtn.addTarget(self, action: #selector(applePayButtonTapped), for: .touchUpInside)
        creditCardPayBtn.isHidden = false
        creditCardPayBtn.alpha = 0.5
        creditCardPayBtn.isUserInteractionEnabled = false
        applePayBtn.alpha = 0.5
        applePayBtn.isUserInteractionEnabled = false
        if PKPaymentAuthorizationViewController.canMakePayments() {
            NotificationCenter.default.addObserver(self, selector: #selector(checkApplePay), name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(checkApplePay), name: UIApplication.didBecomeActiveNotification, object: nil)
        } else {
            isApplePayNotSupported = true
        }
        checkApplePay()
        addPaymentApi()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func checkApplePay() {
        if StripeAPI.deviceSupportsApplePay() {
            applePayBtn.isHidden = false
        } else if isApplePayNotSupported == false {
            applePayBtn.isHidden = false
        } else {
            applePayBtn.isHidden = true
        }
    }
    
    func alertForWallet() {
        let alertController = UIAlertController(title: "Error", message: "Please add a card to your Apple Pay wallet and check again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let setUpAction = UIAlertAction(title: "Go to Apple Wallet", style: .default) { (_) in
            if let url = URL(string: "wallet://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(okAction)
        alertController.addAction(setUpAction)
        present(alertController, animated: true, completion: nil)
    }
        
    private func addPaymentApi() {
        mvpDelegate.addPaymentApiForMvp(bookingId: bookingId, name: isGeneralAdmission ? "General Admission" : "VIP Skip the Line", price: self.ticketPrice, totalTicket: self.totalTicket) { isSuccess, errMsg, clientSecret, paymentHistoryId in
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
        STPAPIClient.shared.publishableKey = "pk_live_51MVrDLBuSsaUd7BTVNumpYdLm1NT3cnQF2HmwWRmedtNmDiHm20T8kwmPMSSI7lEXzSbfyXrJ2hcBqOMOJv0h0TD00krZxi0Tg"
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")"
        //        configuration.customer = .init(id: "customerId", ephemeralKeySecret: "customerEphemeralKeySecret")
        // Set `allowsDelayedPaymentMethods` to true if your business can handle payment
        // methods that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = true
        paymentSheet = PaymentSheet(paymentIntentClientSecret: self.paymentIntent, configuration: configuration)
        DispatchQueue.main.async {
            self.creditCardPayBtn.alpha = 1
            self.creditCardPayBtn.isUserInteractionEnabled = true
            self.applePayBtn.alpha = 1
            self.applePayBtn.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func onClickCreditCardPay(_ sender: Any) {
        // MARK: Start the checkout process
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                self.paymentStatus {
                    Navigate.to.qrCodeMvpVC(self, totalTicket: self.totalTicket, ticketPrice: self.ticketPrice, isGeneral: self.isGeneralAdmission, venueName: self.venueName, bookingId: self.bookingId)
                }
            case .canceled:
                let alert = UIAlertController(title: "Alert", message: "Payment interrupted", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            case .failed:
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
        let merchantIdentifier = "merchant.com.speakeasy"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")

        // Configure the line items on the payment request
        paymentRequest.paymentSummaryItems = [
            // The final line should represent your company;
            // it'll be prepended with the word "Pay" (that is, "Pay iHats, Inc $50")
            PKPaymentSummaryItem(label: "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")", amount: NSDecimalNumber(value: ticketPrice * totalTicket)),
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
        mvpDelegate.successPeyment(paymentHistoryId: paymentHistoryId, bookingId: bookingId) { isSuccess, errMsg in
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

extension CheckOutMvpVC {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        let clientSecret = paymentIntent
        // Call the completion block with the client secret or an error
        completion(clientSecret, nil);
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        switch status {
        case .success:
            paymentStatus {
                Navigate.to.qrCodeMvpVC(self, totalTicket: self.totalTicket, ticketPrice: self.ticketPrice, isGeneral: self.isGeneralAdmission, venueName: self.venueName, bookingId: self.bookingId)
            }
        case .error:
            let alert = UIAlertController(title: "Alert", message: "Payment field", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        case .userCancellation:
            let alert = UIAlertController(title: "Alert", message: "Payment interrupted", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        @unknown default:
            fatalError()
        }
    }
}

