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
import FlagPhoneNumber

final class CheckOutMvpVC: UIViewController, ApplePayContextDelegate {

    @IBOutlet private weak var phoneNoLbl: UILabel!
    @IBOutlet private weak var ticketTitleLbl: UILabel!
    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var applePayBtn: PKPaymentButton!
    @IBOutlet private weak var creditCardPayBtn: UIButton!
    @IBOutlet private weak var ticketQuantityLbl: UILabel!
    @IBOutlet weak var dressCodeInfoLbl: UILabel!
    @IBOutlet weak var countryCodeTextField: FPNTextField!
    @IBOutlet weak var phoneNumTextField: UITextField!
    @IBOutlet weak var ticketSubTitleLbl: UILabel!
    
    var totalTicket = 1
    var ticketPrice = 1
    var isGeneralAdmission = false
    var ticketInfo = ""
    var appClipTicketId = ""
    var venueAttachment = ""
    var venueLogo = ""
    private var checkFPNField = FPNTextField()
    private var paymentSheet: PaymentSheet?
    private var paymentIntent = ""
    private var paymentHistoryId = ""
    var venueName = ""
    var bookingId = ""
    var mvpDelegate = MVPPresenter()
    var venueId = ""
    var isApplePayNotSupported = false
    var isPaymentInitiated = false
    private var isValidNo = false
    private var listController: FPNCountryListViewController = FPNCountryListViewController(style: .grouped)
    private var countryCode = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        WebSocketWrapper.shared.delegate.append(self)
        
        countryCodeTextField.textColor = .white
        
        phoneNumTextField.delegate = self
        checkFPNField.delegate = self
        
        countryCodeTextField.delegate = self
        countryCodeTextField.setFlag(countryCode: .US)
        countryCode = "+1"
        
        listController.setup(repository: countryCodeTextField.countryRepository)
        listController.didSelect = { [weak self] country in
            self?.countryCodeTextField.setFlag(countryCode: country.code)
        }
        
        countryCodeTextField.flagButtonSize = CGSize(width: 44, height: 44)
        countryCodeTextField.flagButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        countryCodeTextField.displayMode = .list

        let items = [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.save, target: self, action: nil),
            UIBarButtonItem(title: "Item 1", style: .plain, target: self, action: nil),
            UIBarButtonItem(title: "Item 2", style: .plain, target: self, action: nil)
        ]
        countryCodeTextField.textFieldInputAccessoryView = getCustomTextFieldInputAccessoryView(with: items)
        
        listController.showCountryPhoneCode = true
        
        dressCodeInfoLbl.highlightBold(["*All entries subject to doorman discretion*"], size: 15, textColor: .white)
        ticketQuantityLbl.text = "\(totalTicket)x"
        ticketTitleLbl.text = "\(isGeneralAdmission ? "General Admission" : "VIP Skip the Line")"
        totalPriceLbl.text = "$\(totalTicket * ticketPrice)"
        ticketSubTitleLbl.text = ticketInfo

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
    
    @objc func checkApplePay() {
        if StripeAPI.deviceSupportsApplePay() {
            applePayBtn.isHidden = false
        } else if isApplePayNotSupported == false {
            applePayBtn.isHidden = false
        } else {
            applePayBtn.isHidden = true
        }
    }
    
    @objc private func dismissCountries() {
        listController.dismiss(animated: true, completion: nil)
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
    
    func createBooking() {
        mvpDelegate.createBookingForMVP(phone: phoneNumTextField.text?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "") ?? "", ticketId: appClipTicketId, totalTicket: (totalTicket)) { [weak self] isSuccess, errMsg, id in
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
        STPAPIClient.shared.publishableKey = "pk_live_51MVrDLBuSsaUd7BTVNumpYdLm1NT3cnQF2HmwWRmedtNmDiHm20T8kwmPMSSI7lEXzSbfyXrJ2hcBqOMOJv0h0TD00krZxi0Tg"
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"
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

extension CheckOutMvpVC: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        checkFPNField.text = textField.text
        checkFPNField.sendActions(for: .editingChanged)
        phoneNumTextField.delegate = nil
        phoneNumTextField.text = checkFPNField.text
        phoneNumTextField.delegate = self
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        applePayBtn.alpha = 0.5
        applePayBtn.isUserInteractionEnabled = false
        creditCardPayBtn.alpha = 0.5
        creditCardPayBtn.isUserInteractionEnabled = false
        if isValidNo {
            checkApplePay()
            createBooking()
        } else {
            if textField.text?.replacingOccurrences(of: " ", with: "") != "" {
                Alert.showAlertSheet(style: .alert, title: "Alert", message: "Enter valid number")
            }
        }
    }
}

extension CheckOutMvpVC: FPNTextFieldDelegate {
    func fpnDisplayCountryList() {
        let navigationViewController = UINavigationController(rootViewController: listController)
        listController.title = "Countries"
        listController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissCountries))
        present(navigationViewController, animated: true, completion: nil)
    }
    
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
        if let countryCode = FPNCountryCode(rawValue: code) {
            if countryCode == checkFPNField.selectedCountry?.code { return }
            checkFPNField.delegate = nil
            checkFPNField.setFlag(countryCode: countryCode)
            checkFPNField.delegate = self
            checkFPNField.sendActions(for: .editingChanged)
            self.countryCode = dialCode
        }
    }
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        if textField == countryCodeTextField {
            phoneNumTextField.placeholder = countryCodeTextField.placeholder
            countryCodeTextField.placeholder = ""
            countryCodeTextField.text = ""
        } else if textField == checkFPNField {
            isValidNo = isValid
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

