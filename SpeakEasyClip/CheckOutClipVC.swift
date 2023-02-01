//
//  CheckOutClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit
import PassKit
import StripeApplePay

final class CheckOutClipVC: UIViewController, ApplePayContextDelegate {

    @IBOutlet private weak var phoneNoLbl: UILabel!
    @IBOutlet private weak var ticketTitleLbl: UILabel!
    @IBOutlet private weak var ticketPriceLbl: UILabel!
    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var payBtn: PKPaymentButton!
    @IBOutlet private weak var ticketQuantityLbl: UILabel!
    
    var phoneNo = ""
    var totalTicket = 1
    var ticketPrice = 1
    var isGeneralAdmission = false

    override func viewDidLoad() {
        super.viewDidLoad()
        phoneNoLbl.text = phoneNo
        ticketQuantityLbl.text = "\(totalTicket)x"
        ticketTitleLbl.text = "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")"
        ticketPriceLbl.text = "$\(totalTicket * ticketPrice)"
        totalPriceLbl.text = "$\(totalTicket * ticketPrice)"
        payBtn.isHidden = !StripeAPI.deviceSupportsApplePay()
        payBtn.addTarget(self, action: #selector(handlePayButtonTapped), for: .touchUpInside)
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handlePayButtonTapped() {
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
