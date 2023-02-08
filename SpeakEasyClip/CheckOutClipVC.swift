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
    @IBOutlet weak var dressCodeInfoLbl: UILabel!
    
    var phoneNo = ""
    var totalTicket = 1
    var ticketPrice = 1
    var isGeneralAdmission = false
    private var paymentSheet: PaymentSheet?
    private var paymentIntent = ""
    var venueName = ""

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
        if StripeAPI.deviceSupportsApplePay() {
            applePayBtn.isHidden = false
            creditCardPayBtn.isHidden = true
            applePayBtn.alpha = 0.5
            applePayBtn.isUserInteractionEnabled = false
        } else {
            applePayBtn.isHidden = true
            creditCardPayBtn.isHidden = false
            creditCardPayBtn.alpha = 0.5
            creditCardPayBtn.isUserInteractionEnabled = false
        }
        addPaymentApi()
    }
    
    private func addPaymentApi() {
        guard let url = URL(string: "https://speakeasy-stag.cmdev.cc/consumer/payment") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let param = ["cart":
                        [
                            ["name": (isGeneralAdmission ? "General Admission" : "VIP Skip the Line"),
                             "price": self.ticketPrice,
                             "quantity": self.totalTicket
                            ]
                        ]
        ] as [String: Any]
        let bodyData = try? JSONSerialization.data(
            withJSONObject: param,
            options: [.prettyPrinted]
        )
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = bodyData
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                  let customerId = json["customer"] as? String,
                  let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                  let paymentIntentClientSecret = json["paymentIntent"] as? String,
                  let self = self else {
                // Handle error
                return
            }
            self.paymentIntent = paymentIntentClientSecret
            self.setUpPaymentBottemSheet()
        })
        task.resume()
    }
    
    private func setUpPaymentBottemSheet() {
        STPAPIClient.shared.publishableKey = "pk_test_51MVrDLBuSsaUd7BTwD22BrfvI0QvLhYMe1b4usjbCW5NefmUVgc0Th4ZrdeOBDL5Xdh3GgzYgvPsct7qFOw9q97W00Dx516uA1"
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "General Admission, Inc."
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
    
    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func onClickCreditCardPay(_ sender: Any) {
        // MARK: Start the checkout process
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "QRCodeClipVC")) as? QRCodeClipVC {
                    vc.totalTicket = self.totalTicket
                    vc.isGeneralAdmission = self.isGeneralAdmission
                    vc.ticketPrice = self.ticketPrice
                    vc.venueName = self.venueName
                    self.navigationController?.pushViewController(vc, animated: true)
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
            applePayContext.presentApplePay()
        } else {
            // There is a problem with your Apple Pay configuration
        }
    }
}

extension CheckOutClipVC {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        let clientSecret = paymentIntent
        // Call the completion block with the client secret or an error
        completion(clientSecret, nil);
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        switch status {
        case .success:
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "QRCodeClipVC")) as? QRCodeClipVC {
                vc.totalTicket = totalTicket
                vc.isGeneralAdmission = isGeneralAdmission
                vc.ticketPrice = ticketPrice
                vc.venueName = self.venueName
                navigationController?.pushViewController(vc, animated: true)
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
