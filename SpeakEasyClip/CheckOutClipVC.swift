//
//  CheckOutClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit
import PassKit

final class CheckOutClipVC: UIViewController {

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
        payBtn.addTarget(self, action: #selector(onClickPay), for: .touchUpInside)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onClickPay() {
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
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "QRCodeClipVC")) as? QRCodeClipVC {
            vc.totalTicket = totalTicket
            vc.isGeneralAdmission = isGeneralAdmission
            vc.ticketPrice = ticketPrice
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
//    func displayDefaultAlert(title: String?, message: String?) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
//        alert.addAction(okAction)
//        self.present(alert, animated: true, completion: nil)
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
