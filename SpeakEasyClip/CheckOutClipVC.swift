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
    var ticketPrice = 90
    var isGeneralAdmission = false

    override func viewDidLoad() {
        super.viewDidLoad()
        phoneNoLbl.text = phoneNo
        ticketQuantityLbl.text = "\(totalTicket)x"
        ticketTitleLbl.text = "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")"
        ticketPriceLbl.text = "$\(totalTicket * ticketPrice)"
        totalPriceLbl.text = "$\(totalTicket * ticketPrice)"
//        payBtn.addTarget(self, action: #selector(onClickPay), for: .touchUpInside)
//        payBtn.isHidden = !StripeAPI.deviceSupportsApplePay()
        payBtn.addTarget(self, action: #selector(handleApplePayButtonTapped), for: .touchUpInside)
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleApplePayButtonTapped() {
        let merchantIdentifier = "merchant.com.speakeasy"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")

        // Configure the line items on the payment request
        paymentRequest.paymentSummaryItems = [
            // The final line should represent your company;
            // it'll be prepended with the word "Pay" (that is, "Pay iHats, Inc $50")
            PKPaymentSummaryItem(label: "General Admission, Inc", amount: 50.00),
        ]
        // Initialize an STPApplePayContext instance
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            // Present Apple Pay payment sheet
            applePayContext.presentApplePay(on: self)
        } else {
            // There is a problem with your Apple Pay configuration
        }
    }
    
    @objc func onClickPay() {
//        let config = STPPaymentConfiguration()
//        config.requiredBillingAddressFields = .full
//
//        let viewController = STPAddCardViewController(configuration: config, theme: STPTheme.defaultTheme)
//        viewController.delegate = self
//        let navigationController = UINavigationController(rootViewController: viewController)
//        present(navigationController, animated: true, completion: nil)
//        let paymentItem = PKPaymentSummaryItem.init(label: "speakeasy skip line", amount: NSDecimalNumber(value: 90.0))
//        let paymentNetworks =  [PKPaymentNetwork.amex, .discover ,.masterCard, .visa]
//        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
//            let request = PKPaymentRequest()
//            request.currencyCode = "USD"
//            request.countryCode = "US"
//            request.merchantIdentifier = ""
//            request.merchantCapabilities = PKMerchantCapability.capability3DS
//            request.supportedNetworks = paymentNetworks
//            request.paymentSummaryItems = [paymentItem]
//            guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
//                displayDefaultAlert(title: "Error", message: "Unable to present Apple Pay authorization.")
//                return
//            }
//            paymentVC.delegate = self
//            self.present(paymentVC, animated: true, completion: nil)
//        } else {
//            displayDefaultAlert(title: "Error", message: "Unable to make Apple Pay transaction.")
//        }
//        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "QRCodeClipVC")) as? QRCodeClipVC {
//            vc.totalTicket = totalTicket
//            vc.isGeneralAdmission = isGeneralAdmission
//            vc.ticketPrice = ticketPrice
//            navigationController?.pushViewController(vc, animated: true)
//        }
    }
    
//    func displayDefaultAlert(title: String?, message: String?) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
//        alert.addAction(okAction)
//        self.present(alert, animated: true, completion: nil)
//    }
    
//    fileprivate func createPayment(token: String, amount: Float) {
//
//        Alamofire.request(paymentURL, method: .post, parameters: ["stripeToken": token, "amount": amount * 100],encoding: JSONEncoding.default, headers: nil).responseString {
//            response in
//            switch response.result {
//            case .success:
//                print("Success")
//
//                break
//            case .failure(let error):
//
//                print("Failure")
//            }
//        }
//    }
}

//extension CheckOutClipVC: PKPaymentAuthorizationViewControllerDelegate {
//    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
//        dismiss(animated: true, completion: nil)
//    }
//    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
//        dismiss(animated: true, completion: nil)
//        displayDefaultAlert(title: "Success!", message: "The Apple Pay transaction was complete.")
//    }
//}

//extension CheckOutClipVC: STPAddCardViewControllerDelegate {
//    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
//        //
//    }
//
//    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreatePaymentMethod paymentMethod: STPPaymentMethod, completion: @escaping STPErrorBlock) {
//        //
//
//    }
//}

extension CheckOutClipVC {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        print("")
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
    }
}
