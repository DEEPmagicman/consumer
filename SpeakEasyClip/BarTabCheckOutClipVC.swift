//
//  BarTabCheckOutClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 30/06/25.
//

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet
import AVFoundation

final class BarTabCheckOutClipVC: UIViewController, ApplePayContextDelegate {
    
    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var phoneNumTextField: PhoneNumberTextField!
    @IBOutlet private weak var errorLbl: UILabel!
    @IBOutlet private weak var firstNameView: UIView!
    @IBOutlet private weak var lastNameView: UIView!
    @IBOutlet private weak var firstNameTF: UITextField!
    @IBOutlet private weak var lastNameTF: UITextField!
    @IBOutlet private weak var applePayBtn: PKPaymentButton!
    @IBOutlet private weak var applePayView: UIView!
    @IBOutlet private weak var cardPayView: UIView!
    @IBOutlet private weak var cardPayBtn: UIButton!
    @IBOutlet private weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var subTotalView: UIView!
    @IBOutlet weak var subTotalAmount: UILabel!
    @IBOutlet weak var processingFeeView: UIView!
    @IBOutlet weak var processingFeeAmount: UILabel!
    @IBOutlet weak var customFeeView: UIView!
    @IBOutlet weak var salesTextView: UIView!
    @IBOutlet weak var salesTextAmount: UILabel!
    @IBOutlet weak var emailValidationLbl: UILabel!
    @IBOutlet weak var salesTaxName: UILabel!
    @IBOutlet weak var ticketListView: UIView!
    @IBOutlet weak var phoneNumberView: UIView!
    @IBOutlet weak var firstNameUnderlineView: UIView!
    @IBOutlet weak var lastNameUnderlineView: UIView!
    @IBOutlet weak var emailUnderlineView: UIView!
    @IBOutlet weak var phoneNumberUnderlineView: UIView!
    @IBOutlet weak var customFeeTableView: UITableView!
    @IBOutlet weak var customFeeTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var paymentBtnStackView: UIStackView!
    @IBOutlet weak var userDetailsStackView: UIStackView!
    @IBOutlet weak var ticketDetailsView: UIStackView!
    @IBOutlet weak var policyView: UIView!
    @IBOutlet weak var policyCheckBox: UIButton!
    @IBOutlet weak var policyLbl: UILabel!
    @IBOutlet weak var insideScrollView: UIView!
    @IBOutlet weak var marketingView: UIView!
    @IBOutlet weak var marketingCheckBox: UIButton!
    @IBOutlet weak var marketingLbl: UILabel!
    
    var venue: ClipVenue?
    var selectedCoverTickets = [CoverTicket]()
    private var paymentSheet: PaymentSheet?
    private var paymentIntent = ""
    private var isIntendCreated = false
    private var isApplePayNotSupported = false
    private var isPaymentInitiated = false
    private var isValidNo = false
    private var ticketListHeightObservation: NSKeyValueObservation?
    var venueImageData = Data()
    let phoneNumberUtility = PhoneNumberUtility()
    var phoneNumber: PhoneNumber?
    private var paymentDetail: PaymentDetail?
    private var barTabData: BarTabData?
    private var barBooking: BarTabBooking?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        WebSocketWrapper.shared.delegate.append(self)
        
        ticketListView.isHidden = false
        
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        phoneNumTextField.delegate = self
        phoneNumTextField.withDefaultPickerUI = true
        phoneNumTextField.defaultRegion = "US"
        phoneNumTextField.withPrefix = false
        phoneNumTextField.withFlag = true
        phoneNumTextField.withExamplePlaceholder = true
        CountryCodePicker.alwaysShowsSearchBar = true
        CountryCodePicker.forceModalPresentation = true
        var options = CountryCodePickerOptions()
        options.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.00)
        options.textLabelFont = UIFont(name: "Poppins-Regular", size: 15)!
        options.textLabelColor = UIColor(red: 0.63, green: 0.63, blue: 0.63, alpha: 1.00)
        options.detailTextLabelFont = UIFont(name: "Poppins-Regular", size: 15)!
        phoneNumTextField.withDefaultPickerUIOptions = options
        
        totalPriceLbl.text = "\(venue?.venueSettings?.currencySymbol ?? "$")0.00"
        applePayBtn.addTarget(self, action: #selector(checkApplePay), for: .touchUpInside)
        if PKPaymentAuthorizationViewController.canMakePayments() {
            errorLbl.text = "Add Card to your Apple wallet & try again.".localize()
        } else {
            isApplePayNotSupported = true
            errorLbl.text = "Apple pay is not supported on your device, try another payment option.".localize()
        }
        
        firstNameTF.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.editingDidEnd)
        firstNameTF.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.editingChanged)
        lastNameTF.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.editingDidEnd)
        lastNameTF.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.editingChanged)
        emailTF.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.editingDidEnd)
        emailTF.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.editingChanged)
        phoneNumTextField.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.editingDidEnd)
        phoneNumTextField.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.editingChanged)
        firstNameTF.addNextButtonKeyboard(superViewCount: 3)
        lastNameTF.addNextButtonKeyboard(superViewCount: 3)
        emailTF.addDoneButtonKeyboard()
        emailValidationLbl.isHidden = true
        emailTF.delegate = self
        getCalculation()
        
        policyView.isHidden = venue?.venueSettings?.barTabBookingPolicy?.isEmpty ?? true == true
        policyLbl.text = venue?.venueSettings?.barTabBookingPolicy?.htmlToPlainText() ?? ""
        policyCheckBox.setImage(CommonConstant.Icon.checkBoxEmpty, for: .normal)
        policyCheckBox.setImage(CommonConstant.Icon.checkBoxFull, for: .selected)
        policyCheckBox.isSelected = true
        
        marketingView.isHidden = !(venue?.venueSettings?.optedPolicy == true)
        marketingLbl.text = venue?.venueSettings?.policyText ?? "Opt in for future messages"
        marketingCheckBox.setImage(CommonConstant.Icon.checkBoxEmpty, for: .normal)
        marketingCheckBox.setImage(CommonConstant.Icon.checkBoxFull, for: .selected)
        marketingCheckBox.isSelected = true
        
        firstNameView.isHidden = venue?.venueSettings?.collectNameDuringBooking ?? false == false
        lastNameView.isHidden = venue?.venueSettings?.collectNameDuringBooking ?? false == false
        emailView.isHidden = venue?.venueSettings?.collectEmailDuringBooking == true ? false : true
    }
    
    override func viewDidLayoutSubviews() {
        if paymentDetail?.total ?? 0 == 0 {
            scrollViewBottomConstraint.constant = 130 - view.safeAreaInsets.bottom
        } else {
            scrollViewBottomConstraint.constant = 190 - view.safeAreaInsets.bottom
        }
    }
    
    private func getCustomTextFieldInputAccessoryView(with items: [UIBarButtonItem]) -> UIToolbar {
        let toolbar: UIToolbar = UIToolbar()
        
        toolbar.barStyle = UIBarStyle.default
        toolbar.items = items
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    func getCalculation() {
        
        AppClipLoader.showLoader(self.view)
        var selectedTickets = [[String: Any]]()
        selectedCoverTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                    "ticketQuantity": $0.selectedQuantity ?? 0])
        }
        var paramData = [String: Any]()
        let param = ["tickets": selectedTickets,
                     "venueId": UserDefaults.standard.value(forKey: "venueIdLong") as? String ?? ""] as [String: Any]
        
        print("-=-= \(param)")
        if !SharedURL.isEncryptionEnabled {
            paramData = param
        } else {
            paramData = param.encrypted() ?? [:]
        }
        var postData = Data()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: paramData, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            if let jsonData = jsonString?.data(using: .utf8) {
                postData = jsonData
            }
        } catch {
            print("Error converting dictionary to JSON string: \(error)")
        }
        
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/bar-tab/calculation") else { return }
        var request = URLRequest(url: userURL, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Data not found")
                return
            }
            AppClipLoader.hideLoader()
            if let data = try? JSONDecoder().decode(PaymentDetail.self, from: data) {
                self.paymentDetail = data
                self.displayPaymentData()
            } else if let errData = convertDataToDictionary(data: data), let errMsg = errData["message"] as? String {
                DispatchQueue.main.async {
                    self.userDetailsStackView.isHidden = true
                    self.paymentBtnStackView.isHidden = true
                    self.ticketDetailsView.isHidden = true
                    self.insideScrollView.isHidden = true
                    self.alertPopup("", errMsg, "Go Back") {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
        task.resume()
    }
    
    func createBooking(completion: @escaping (()-> Void)) {
        let countryCode = phoneNumTextField?.flagButton.titleLabel?.text?.components(separatedBy: .whitespaces).joined().filter { $0.isASCII } ?? "+1"
        if !validateEmail {
            emailValidationLbl.isHidden = false
            return
        }
        if venue?.venueSettings?.barTabBookingPolicy?.isEmpty ?? true == false && policyCheckBox.isSelected == false {
            alertPopup("", "You must accept the terms and conditions by clicking the checkbox.")
            return
        }
        
        emailValidationLbl.isHidden = true
        AppClipLoader.showLoader(self.view)
        var selectedTickets = [[String: Any]]()
        selectedCoverTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                    "ticketQuantity": $0.selectedQuantity ?? 0])
        }
        var paramData = [String: Any]()
        var param = ["tickets": selectedTickets,
                     "venueId": UserDefaults.standard.value(forKey: "venueIdLong") as? String ?? "",
                     "code": countryCode,
                     "phone": "\(self.phoneNumber?.nationalNumber ?? 0)"] as [String: Any]
        if firstNameTF.text ?? "" != "" {
            param["firstName"] = firstNameTF.text ?? ""
        }
        if lastNameTF.text ?? "" != "" {
            param["lastName"] = lastNameTF.text ?? ""
        }
        if emailTF.text ?? "" != "" {
            param["email"] = (emailTF.text ?? "").replacingOccurrences(of: " ", with: "")
        }
        
        if !SharedURL.isEncryptionEnabled {
            paramData = param
        } else {
            paramData = param.encrypted() ?? [:]
        }
        var postData = Data()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: paramData, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            if let jsonData = jsonString?.data(using: .utf8) {
                postData = jsonData
            }
        } catch {
            print("Error converting dictionary to JSON string: \(error)")
        }
        
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/bar-tab") else { return }
        var request = URLRequest(url: userURL, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Data not found")
                return
            }
            AppClipLoader.hideLoader()
            if let data = try? JSONDecoder().decode(BarTabData.self, from: data) {
                self.barTabData = data
                self.paymentIntent = self.barTabData?.clientSecret ?? ""
                self.paymentDetail = self.barTabData?.barTab.barTabPayments?.first?.bookingFees
                self.setUpPaymentBottomSheet()
                completion()
            }
        }
        task.resume()
    }
    
    private func paymentStatus(completion: @escaping (()-> Void)) {
        let barTabId = barTabData?.barTab.id ?? ""
        let paymentId = barTabData?.barTab.barTabPayments?.first?.id ?? ""
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/bar-tab/\(barTabId)/payments/\(paymentId)/complete") else { return }
        var request = URLRequest(url: userURL, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                self.alertPopup("Alert", "Data not found")
                return
            }
            AppClipLoader.hideLoader()
            if let data = try? JSONDecoder().decode(BarTab.self, from: data) {
                completion()
            }
        }
        task.resume()
    }
    
    private func getBarBooking(completion: @escaping (()-> Void)) {
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/bar-tab/\(barTabData?.barTab.id ?? "")/payment-details") else { return }
        var request = URLRequest(url: userURL, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Data not found")
                return
            }
            AppClipLoader.hideLoader()
            if let data = try? JSONDecoder().decode(BarTabBooking.self, from: data) {
                self.barBooking = data
                completion()
            }
        }
        task.resume()
    }
    
    private func displayPaymentData() {
        let feeData = paymentDetail
        DispatchQueue.main.async {
            self.subTotalView.isHidden = feeData?.subTotal == feeData?.total
            self.salesTextView.isHidden = feeData?.salesTax ?? 0 == 0
            self.customFeeView.isHidden = feeData?.additionalFees?.count == 0
            self.processingFeeView.isHidden = true // !self.setProcessingFeeView
            
//            self.processingFeeAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\((feeData?.processingFee ?? 0).decimalFormat(true))"
            self.subTotalAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\((feeData?.subTotal ?? 0).decimalFormat(true))"
            self.salesTextAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\((feeData?.salesTax ?? 0).decimalFormat(true))"
            self.salesTaxName.text = feeData?.salesTaxName ?? "Sales Tax"
            self.totalPriceLbl.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\((feeData?.total ?? 0).decimalFormat(true))"
            
            self.customFeeTableViewHeight.constant = CGFloat((feeData?.additionalFees?.count ?? 0) * 30)
            self.customFeeTableView.reloadData()
            self.isIntendCreated = true
           
        }
    }
    
//    var setProcessingFeeView: Bool {
//        let feeData = barTabData?.barTab.barTabPayments?.first?.bookingFees
//        let totalCustomFee = feeData?.additionalFees?.reduce(0.0) { $0 + ($1.amount ?? 0) } ?? 0
//        let processingFee = feeData?.processingFee ?? 0
//        let subTotal = feeData?.subTotal ?? 0
//        let salesTax = feeData?.salesTax ?? 0
//        let total = feeData?.total ?? 0
//
//        return (processingFee != 0) && (total != subTotal) && ((subTotal + salesTax + totalCustomFee) != total)
//    }
    
    @objc func checkApplePay() {
        if !checkAllData {
            checkValidation()
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } else {
            if isValidNo == false {
                alertPopup("Alert", "Enter valid number")
                return
            }
            self.createBooking {
                DispatchQueue.main.async {
                    if StripeAPI.deviceSupportsApplePay() {
                        if self.isIntendCreated {
                            DispatchQueue.main.async {
                                self.applePayButtonTapped()
                            }
                            return
                        }
                        self.applePayBtn.isHidden = false
                        self.errorLbl.isHidden = true
                    } else if self.isApplePayNotSupported == false {
                        self.alertForWallet()
                        self.setUpPaymentBtn()
                    } else {
                        self.applePayBtn.isHidden = true
                        self.errorLbl.isHidden = false
                    }
                }
            }
        }
    }
    private func checkValidation() {
        if phoneNumTextField.text ?? "" == "" {
            phoneNumTextField.shake()
            phoneNumberUnderlineView.backgroundColor = .red
        }
        
        if venue?.venueSettings?.collectNameDuringBooking == true && firstNameTF.text ?? "" == "" {
            firstNameTF.shake()
            firstNameUnderlineView.backgroundColor = .red
        }
        if venue?.venueSettings?.collectNameDuringBooking == true && lastNameTF.text ?? "" == "" {
            lastNameTF.shake()
            lastNameUnderlineView.backgroundColor = .red
        }
    }
    
    private var checkAllData: Bool {
        if phoneNumTextField.text ?? "" == "" {
            return false
        }
        
        if (venue?.venueSettings?.collectNameDuringBooking == true && firstNameTF.text ?? "" == "") || (venue?.venueSettings?.collectNameDuringBooking == true && lastNameTF.text ?? "" == "") {
            return false
        }
        
        return true
    }
    
    @objc private func textFieldValDidChange(_ textField: UITextField) {
//        isIntendCreated = false
        if textField.text != "" {
            if textField == firstNameTF {
                firstNameUnderlineView.backgroundColor = UIColor(red: 0.48, green: 0.48, blue: 0.49, alpha: 1.00)
            } else if textField == lastNameTF {
                lastNameUnderlineView.backgroundColor = UIColor(red: 0.48, green: 0.48, blue: 0.49, alpha: 1.00)
            } else if textField == phoneNumTextField {
                phoneNumberUnderlineView.backgroundColor = UIColor(red: 0.48, green: 0.48, blue: 0.49, alpha: 1.00)
//                countryCodeUnderlineView.backgroundColor = UIColor(red: 0.48, green: 0.48, blue: 0.49, alpha: 1.00)
            } else {
                emailUnderlineView.backgroundColor = UIColor(red: 0.48, green: 0.48, blue: 0.49, alpha: 1.00)
            }
        }
    }
    
    private func setUpPaymentBtn() {
        DispatchQueue.main.async {
            self.applePayBtn.alpha = 1
            self.applePayBtn.isUserInteractionEnabled = true
        }
    }
    
    @IBAction private func onClickPolicyCheckBox(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    @IBAction private func onClickMarketingCheckBox(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func alertForWallet() {
        let alertController = UIAlertController(title: "Add Card to Apple Pay".localize(), message: "Please add a card to your Apple Pay wallet and check again.".localize(), preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Cancel".localize(), style: .cancel, handler: nil)
        let setUpAction = UIAlertAction(title: "Add Card".localize(), style: .default) { (_) in
            if let url = URL(string: "wallet://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(okAction)
        alertController.addAction(setUpAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func applePayButtonTapped() {
        if isApplePayNotSupported == false && StripeAPI.deviceSupportsApplePay() == false {
            alertForWallet()
            return
        }
        isPaymentInitiated = true
        let merchantIdentifier = "merchant.com.speakeasy"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: venue?.venueSettings?.currencyCode?.uppercased() ?? "USD")
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Speakeasy Bookings Inc. (VIA Speakeasy Go!)", amount: NSDecimalNumber(value: (paymentDetail?.total ?? 0)))
        ]
        paymentRequest.requiredBillingContactFields = []
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            applePayContext.presentApplePay()
        } else {
            alertPopup("Alert", "Problem with your Apple Pay configuration")
        }
    }
    
    private func setUpPaymentBottomSheet() {
        STPAPIClient.shared.publishableKey = Stripe.publishableKey
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"
        configuration.savePaymentMethodOptInBehavior = .automatic
        // Set `allowsDelayedPaymentMethods` to true if your business can handle payment
        // methods that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = true
        paymentSheet = PaymentSheet(paymentIntentClientSecret: self.paymentIntent, configuration: configuration)
    }
    
    private func onClickCreditCardPay() {
        // MARK: Start the checkout process
        isPaymentInitiated = true
        self.createBooking() {
            DispatchQueue.main.async {
                self.paymentSheet?.present(from: self) { paymentResult in
                    // MARK: Handle the payment result
                    switch paymentResult {
                    case .completed:
                        DispatchQueue.main.async {
                            AppClipLoader.showLoader(self.view)
                        }
                        
                        self.paymentStatus {
                            self.getBarBooking() {
                                self.navigateToQR()
                            }
                        }
                        
                        print("-=-= payment completed")
                    case .canceled:
                        print("-=-= payment canceled")
                        self.isPaymentInitiated = false
                    case .failed:
                        self.isPaymentInitiated = false
                        self.alertPopup("Alert", "Payment failed")
                    }
                }
            }
        }
    }
    
    private var validateEmail: Bool {
        if emailTF.text ?? "" == "" {
            return true
        }
        return (emailTF.text ?? "").isValidEmail
    }
    
    @IBAction func onClickCardPay(_ sender: Any) {
        if !checkAllData {
            checkValidation()
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } else {
            if isValidNo == false {
                alertPopup("Alert", "Enter valid number")
                return
            }
            if isIntendCreated {
                DispatchQueue.main.async {
                    self.onClickCreditCardPay()
                }
                return
            } else {
                print("-=-= isIntendCreated is false ")
            }
        }
    }
    
    private func navigateToQR() {
        DispatchQueue.main.async {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "BarTabQRCodeClipVC")) as? BarTabQRCodeClipVC {
                AppClipLoader.hideLoader()
                vc.venue = self.venue
                vc.appClipTicket = self.selectedCoverTickets
                vc.barBooking = self.barBooking
                vc.barTabId = self.barTabData?.barTab.id ?? ""
                var userData = ""
                if self.venue?.venueSettings?.collectNameDuringBooking == true {
                    userData =  "\(self.firstNameTF.text ?? "") \(self.lastNameTF.text ?? "")"
                } else {
                    userData = "+\(self.phoneNumber?.countryCode ?? 1) \(self.phoneNumber?.numberString ?? "")"
                }
                vc.guestInfo = "\(userData) - \(self.barBooking?.createdAt.convertDateFormat(from: "yyyy-MM-dd'T'HH:mm:ss.SSSz", to: "h:mma MMMM dd", isUTC: true, customTimeZone: self.venue?.useTimezone ?? "") ?? "")"
                if let selectVC = self.navigationController?.viewControllers.first(where: { $0.isKind(of: SelectTicketClipVC.self) }) as? SelectTicketClipVC {
                    selectVC.forceRemoveAllTicket()
                    self.navigationController?.viewControllers = [selectVC, vc]
                }
            }
        }
    }
}

extension BarTabCheckOutClipVC {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        let clientSecret = paymentIntent
        // Call the completion block with the client secret or an error
        completion(clientSecret, nil)
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        switch status {
        case .success:
            DispatchQueue.main.async {
                AppClipLoader.showLoader(self.view)
            }
            
            self.paymentStatus {
                self.getBarBooking() {
                    self.navigateToQR()
                }
            }
        case .error:
            isPaymentInitiated = false
            alertPopup("Alert", "Payment failed")
        case .userCancellation:
            isPaymentInitiated = false
            //            alertPopup("Alert", "Payment interrupted")
        }
    }
}

extension BarTabCheckOutClipVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == ticketListTableView {
            return selectedCoverTickets.count
        } else {
            return self.paymentDetail?.additionalFees?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == customFeeTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomFeeTVC", for: indexPath) as! CustomFeeTVC
            let customFee = self.paymentDetail?.additionalFees?[indexPath.row]
            cell.lblFeeName.text = customFee?.name ?? "Custom fee"
            cell.lblFeeValue.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((customFee?.amount ?? 0).decimalFormat(true))"
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        
        cell.titleLbl.text = selectedCoverTickets[indexPath.row].customName ?? "" == "" ? selectedCoverTickets[indexPath.row].displayName : selectedCoverTickets[indexPath.row].displayCustomName
        cell.subTitleLbl.text = selectedCoverTickets[indexPath.row].displayDescription
        cell.quantityLbl.text = "\(selectedCoverTickets[indexPath.row].selectedQuantity ?? 0)x"
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}

extension BarTabCheckOutClipVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == emailTF && string == " " {
            return false
        }
         return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        do {
            let phoneNumber = try phoneNumberUtility.parse(phoneNumTextField.text ?? "", withRegion: phoneNumTextField.defaultRegion)
            self.phoneNumber = phoneNumber
            self.isValidNo = true
        }
        catch {
            self.isValidNo = false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if !isValidNo {
            if textField.text?.replacingOccurrences(of: " ", with: "") != "" {
                alertPopup("Alert", "Enter valid number")
            }
        }
    }
}

extension BarTabCheckOutClipVC: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool) {
        if isPaymentInitiated { return }
        if navigationController?.viewControllers.last is CheckOutClipVC && uniqueId == UserDefaults.standard.value(forKey: "venueId") as? String ?? "" {
            if isPriceUpdated {
                alertPopup("Update", "The venue updated their prices") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    func updateTicketPrice(ticket: [CoverTicket]) {
        if isPaymentInitiated { return }
        if selectedCoverTickets.count == 0 { return }
        var coverTickets = [CoverTicket]()
        ticket.forEach({ tick in
            coverTickets = selectedCoverTickets.filter({ $0.id == tick.id})
        })
        if coverTickets.count != 0 {
            if navigationController?.viewControllers.last is CheckOutClipVC {
                alertPopup("Update", "Venue you trying to booking, updated it's ticket") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    func updateVenueStatus(venueId: String, venueStatus: String) {
        if isPaymentInitiated { return }
        if navigationController?.viewControllers.last is CheckOutClipVC && venueId == UserDefaults.standard.value(forKey: "venueId") as? String ?? "" {
            alertPopup("Update", "Venue your trying to booking is closed") {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    func didGenderWiseTicketChange(venueId: String, uniqueId: String) {
        if isPaymentInitiated { return }
        if navigationController?.viewControllers.last is CheckOutClipVC && uniqueId == UserDefaults.standard.value(forKey: "venueId") as? String ?? "" {
            alertPopup("Update", "Venue your trying to booking, updated it's ticket") {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}

extension BarTabCheckOutClipVC: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
//        isChangingFlag = false
    }
}

func convertDataToDictionary(data: Data) -> [String: Any]? {
    do {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        return json as? [String: Any]
    } catch {
        print("Failed to convert Data to Dictionary: \(error.localizedDescription)")
        return nil
    }
}

extension String {
    func htmlToPlainText() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        
        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
            )
            return attributedString.string
        } catch {
            print("Error converting HTML to plain text: \(error)")
            return self
        }
    }
}
