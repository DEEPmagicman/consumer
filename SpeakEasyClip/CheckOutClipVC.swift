//
//  CheckOutClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet

final class CheckOutClipVC: UIViewController, ApplePayContextDelegate {

    @IBOutlet private weak var phoneNoLbl: UILabel!
    @IBOutlet private weak var ticketTitleLbl: UILabel!
    @IBOutlet private weak var ticketPriceLbl: UILabel!
    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var applePayBtn: PKPaymentButton!
    @IBOutlet private weak var creditCardPayBtn: UIButton!
    @IBOutlet private weak var ticketQuantityLbl: UILabel!
    
    var phoneNo = ""
    var totalTicket = 1
    var ticketPrice = 1
    var isGeneralAdmission = false
    private var paymentSheet: PaymentSheet?
//    let backendCheckoutUrl = URL(string: "Your backend endpoint")! // Your backend endpoint

    override func viewDidLoad() {
        super.viewDidLoad()
        phoneNoLbl.text = phoneNo
        ticketQuantityLbl.text = "\(totalTicket)x"
        ticketTitleLbl.text = "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")"
        ticketPriceLbl.text = "$\(totalTicket * ticketPrice)"
        totalPriceLbl.text = "$\(totalTicket * ticketPrice)"
        applePayBtn.addTarget(self, action: #selector(applePayButtonTapped), for: .touchUpInside)
        if StripeAPI.deviceSupportsApplePay() {
            applePayBtn.isHidden = false
            creditCardPayBtn.isHidden = true
        } else {
            applePayBtn.isHidden = true
            creditCardPayBtn.isHidden = false
        }
        STPAPIClient.shared.publishableKey = "pk_test_51MVrDLBuSsaUd7BTwD22BrfvI0QvLhYMe1b4usjbCW5NefmUVgc0Th4ZrdeOBDL5Xdh3GgzYgvPsct7qFOw9q97W00Dx516uA1"
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "General Admission, Inc."
        //        configuration.customer = .init(id: "customerId", ephemeralKeySecret: "customerEphemeralKeySecret")
        // Set `allowsDelayedPaymentMethods` to true if your business can handle payment
        // methods that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = true
        paymentSheet = PaymentSheet(paymentIntentClientSecret: "pi_1DsvUh2eZvKYlo2CODPxUVui_secret_GOreV7KvU7RtPxq6XwgY5dolb", configuration: configuration)
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func onClickCreditCardPay(_ sender: Any) {
        // MARK: Start the checkout process
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                print("Your order is confirmed")
            case .canceled:
                print("Canceled!")
            case .failed(let error):
                print("Payment failed: \(error)")
            }
        }
    }
    
    @objc private func applePayButtonTapped() {
        let merchantIdentifier = "merchant.com.speakeasy"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")

        // Configure the line items on the payment request
        paymentRequest.paymentSummaryItems = [
            // The final line should represent your company;
            // it'll be prepended with the word "Pay" (that is, "Pay iHats, Inc $50")
            PKPaymentSummaryItem(label: "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")", amount: NSDecimalNumber(value: ticketPrice)),
        ]
        paymentRequest.requiredBillingContactFields = []
        // Initialize an STPApplePayContext instance
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            // Present Apple Pay payment sheet
            applePayContext.presentApplePay(on: self)
        } else {
            // There is a problem with your Apple Pay configuration
        }
    }
}

extension CheckOutClipVC {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        //        let clientSecret = ... // Retrieve the PaymentIntent client secret from your backend (see Server-side step above)
        // Call the completion block with the client secret or an error
//        completion(clientSecret, error);
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        switch status {
        case .success:
            // Payment succeeded, show a receipt view
            break
        case .error:
            // Payment failed, show the error
            break
        case .userCancellation:
            // User canceled the payment
            break
        @unknown default:
            fatalError()
        }
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "QRCodeClipVC")) as? QRCodeClipVC {
            vc.totalTicket = totalTicket
            vc.isGeneralAdmission = isGeneralAdmission
            vc.ticketPrice = ticketPrice
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
