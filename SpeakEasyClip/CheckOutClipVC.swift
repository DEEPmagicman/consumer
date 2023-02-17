//
//  CheckOutClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit
import PassKit
import StripeApplePay

enum PaymentStatus: String {
    case SUCCESS
    case FAILED
}

final class CheckOutClipVC: UIViewController, ApplePayContextDelegate {

    @IBOutlet private weak var phoneNoLbl: UILabel!
    @IBOutlet private weak var ticketTitleLbl: UILabel!
    @IBOutlet private weak var ticketPriceLbl: UILabel!
    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var errorLbl: UILabel!
    @IBOutlet private weak var applePayBtn: PKPaymentButton!
    @IBOutlet private weak var ticketQuantityLbl: UILabel!
    @IBOutlet weak var dressCodeInfoLbl: UILabel!
    
    var phoneNo = ""
    var totalTicket = 1
    var ticketPrice = 1
    var isGeneralAdmission = false
    private var paymentIntent = ""
    var paymentHistoryId = ""
    var venueName = ""
    var bookingId = ""
    var isIntendCreated = false
    var isApplePayNotSupported = false
    private var isPaymentInitiated = false

    override func viewDidLoad() {
        super.viewDidLoad()
        WebSocketWrapper.shared.delegate.append(self)
        dressCodeInfoLbl.text = "*All entries subject to doorman discretion*  At \(venueName), we encourage smart, casual-elegant attire."
        dressCodeInfoLbl.highlightBold(["*All entries subject to doorman discretion*"], size: 15, textColor: .white)
        phoneNoLbl.text = phoneNo
        ticketQuantityLbl.text = "\(totalTicket)x"
        ticketTitleLbl.text = "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")"
        ticketPriceLbl.text = "$\(totalTicket * ticketPrice)"
        totalPriceLbl.text = "$\(totalTicket * ticketPrice)"
        applePayBtn.addTarget(self, action: #selector(applePayButtonTapped), for: .touchUpInside)
        if PKPaymentAuthorizationViewController.canMakePayments() {
            errorLbl.text = "Add Card to your Apple wallet & try again."
            NotificationCenter.default.addObserver(self, selector: #selector(checkApplePay), name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(checkApplePay), name: UIApplication.didBecomeActiveNotification, object: nil)
        } else {
            isApplePayNotSupported = true
            errorLbl.text = "Apple pay is not supported on your device, use main app to book ticket."
        }
        checkApplePay()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func checkApplePay() {
        if StripeAPI.deviceSupportsApplePay() {
            if isIntendCreated { return }
            addPaymentApi()
            applePayBtn.isHidden = false
            errorLbl.isHidden = true
            applePayBtn.alpha = 0.5
            applePayBtn.isUserInteractionEnabled = false
        } else if isApplePayNotSupported == false {
            alertForWallet()
            applePayBtn.alpha = 0.5
            applePayBtn.isUserInteractionEnabled = false
        } else {
            applePayBtn.isHidden = true
            errorLbl.isHidden = false
        }
    }
    
    private func addPaymentApi() {
        if isIntendCreated { return }
        AppClipLoader.showLoader(view)
        guard let url = URL(string: "https://api.speakeasygo.com/consumer/payment/\(bookingId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let param = ["cart":
                        [
                            ["name": (isGeneralAdmission ? "General Admission" : "VIP Skip the Line"),
                             "price": ticketPrice,
                             "quantity": totalTicket
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
            AppClipLoader.hideLoader()
            guard let self = self else { return }
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let paymentIntentClientSecret = json["clientSecret"] as? String, let paymentHistoryId = json["paymentHistoryId"] as? String else {
                self.alertPopup("Alert", "Payment Initialisation issue")
                return
            }
            self.isIntendCreated = true
            self.paymentIntent = paymentIntentClientSecret
            self.paymentHistoryId = paymentHistoryId
            self.setUpPaymentBtn()
        })
        task.resume()
    }
    
    private func setUpPaymentBtn() {
        DispatchQueue.main.async {
            self.applePayBtn.alpha = 1
            self.applePayBtn.isUserInteractionEnabled = true
        }
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
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
    
    @objc private func applePayButtonTapped() {
        isPaymentInitiated = true
        let merchantIdentifier = "merchant.com.speakeasy"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Speakeasy Bookings Inc. (VIA Speakeasy Go!)", amount: NSDecimalNumber(value: ticketPrice * totalTicket))
        ]
        paymentRequest.requiredBillingContactFields = []
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            applePayContext.presentApplePay()
        } else {
            alertPopup("Alert", "Problem with your Apple Pay configuration")
        }
    }
    
    func paymentStatus(_ status: PaymentStatus, completion: @escaping (()-> Void)) {
        guard let url = URL(string: "https://api.speakeasygo.com/consumer/payment/\(paymentHistoryId)/\(bookingId)/status?status=\(status.rawValue)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            completion()
        })
        task.resume()
    }
}

extension CheckOutClipVC {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        let clientSecret = paymentIntent
        // Call the completion block with the client secret or an error
        completion(clientSecret, nil)
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        switch status {
        case .success:
            paymentStatus(.SUCCESS) { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "QRCodeClipVC")) as? QRCodeClipVC {
                        vc.totalTicket = self.totalTicket
                        vc.isGeneralAdmission = self.isGeneralAdmission
                        vc.ticketPrice = self.ticketPrice
                        vc.venueName = self.venueName
                        vc.bookingId = self.bookingId
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        case .error:
            isPaymentInitiated = false
            alertPopup("Alert", "Payment field")
        case .userCancellation:
            isPaymentInitiated = false
            alertPopup("Alert", "Payment interrupted")
        @unknown default:
            fatalError()
        }
    }
}

extension CheckOutClipVC: webSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        if isPaymentInitiated { return }
        if navigationController?.viewControllers.last is CheckOutClipVC && uniqueId == UserDefaults.standard.value(forKey: "venueId") as? String ?? "" {
            if isPriceUpdated {
                alertPopup("Update", "Venue your trying to booking, updated it's price") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else if isVenueStatusUpdate {
                alertPopup("Update", "Venue your trying to booking is closed") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
}
