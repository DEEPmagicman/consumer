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
    @IBOutlet weak var salesTaxPr: UILabel!
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
    
    var totalPrice = 1.0
    var venue: ClipVenue?
    var selectedCoverTickets = [CoverTicket]()
    private var paymentSheet: PaymentSheet?
    private var paymentIntent = ""
    private var isIntendCreated = false
    private var isApplePayNotSupported = false
    private var isPaymentInitiated = false
    private var isValidNo = false
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var booking: Booking?
    var venueImageData = Data()
    let phoneNumberUtility = PhoneNumberUtility()
    var phoneNumber: PhoneNumber?
    private var paymentDetail: PaymentDetail?

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
        
        totalPriceLbl.text = totalPrice == 0 ? "\(venue?.venueSettings?.currencySymbol ?? "$")0.00" : "-"
        applePayBtn.addTarget(self, action: #selector(checkApplePay), for: .touchUpInside)
        if PKPaymentAuthorizationViewController.canMakePayments() {
            errorLbl.text = "Add Card to your Apple wallet & try again.".localize()
        } else {
            isApplePayNotSupported = true
            errorLbl.text = "Apple pay is not supported on your device, try another payment option.".localize()
        }
        
//        firstNameView.isHidden = venue?.venueSettings?.collectNameDuringBooking ?? false == false
//        lastNameView.isHidden = venue?.venueSettings?.collectNameDuringBooking ?? false == false
        
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
    }
    
    override func viewDidLayoutSubviews() {
        if totalPrice == 0 {
            scrollViewBottomConstraint.constant = 130 - view.safeAreaInsets.bottom
        } else {
            scrollViewBottomConstraint.constant = 190 - view.safeAreaInsets.bottom
        }
    }
    
    private var setSalesTaxView: Bool {
        if selectedCoverTickets.allSatisfy({ $0.isCustom == true }) {
            salesTaxPr.text = "(\(venue?.venueSettings?.customCoverTicketSettings?.salesTax ?? 0.0)%)"
            return venue?.venueSettings?.customCoverTicketSettings?.isEnableSalesTax == true ? true : false
        }
        
        if selectedCoverTickets.allSatisfy({ $0.isCustom == false }) {
            salesTaxPr.text = "(\(venue?.venueSettings?.coverTicketSettings?.salesTax ?? 0.0)%)"
            return venue?.venueSettings?.coverTicketSettings?.isEnableSalesTax == true && venue?.venueSettings?.coverTicketSettings?.isUpFront == false ? true : false
        }
        
        if ((venue?.venueSettings?.coverTicketSettings?.isEnableSalesTax == true && venue?.venueSettings?.coverTicketSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketSettings?.isEnableSalesTax == true) && paymentDetail?.salesTax ?? 0 > 0 {
            let customTicket = selectedCoverTickets.first(where: { $0.isCustom == true && $0.price > 0 })
            salesTaxPr.text = customTicket == nil ? "(\(venue?.venueSettings?.coverTicketSettings?.salesTax ?? 0.0)%)" : "(\(venue?.venueSettings?.customCoverTicketSettings?.salesTax ?? 0.0)%)"
            return true
        }
        return false
    }
    
    private var setCustomTaxView: Bool {
        if selectedCoverTickets.allSatisfy({ $0.isCustom == true }) {
            return venue?.venueSettings?.customCoverTicketSettings?.customFees?.filter({$0.isEnableCustomFee == true }).count ?? 0 > 0
        }
        
        if selectedCoverTickets.allSatisfy({ $0.isCustom == false }) {
            return (venue?.venueSettings?.coverTicketSettings?.customFees?.filter({$0.isEnableCustomFee == true }).count ?? 0 > 0) && venue?.venueSettings?.coverTicketSettings?.isUpFront == false ? true : false
        }
        
        if (((venue?.venueSettings?.coverTicketSettings?.customFees?.filter({$0.isEnableCustomFee == true }).count ?? 0 > 0) && venue?.venueSettings?.coverTicketSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketSettings?.customFees?.filter({$0.isEnableCustomFee == true }).count ?? 0 > 0) && (paymentDetail?.customFees?.reduce(0.0) { $0 + ($1.fee ?? 0) } ?? 0 > 0) {
            return true
        }
        return false
    }
    
    private var setProcessingTaxView: Bool {
        
        var isProcessingFeeApplied = paymentDetail?.processingFee ?? 0 > 0
        let totalCustomFee = paymentDetail?.customFees?.reduce(0.0) { $0 + ($1.fee ?? 0) } ?? 0
        let processingFee = paymentDetail?.processingFee ?? 0
        let subTotal = paymentDetail?.subTotal ?? 0
        let salesTax = paymentDetail?.salesTax ?? 0
        let total = paymentDetail?.total ?? 0
        let totalAmount = (subTotal + processingFee + salesTax + totalCustomFee)
        isProcessingFeeApplied = totalAmount == total
        
        if selectedCoverTickets.allSatisfy({ $0.isCustom == true }) {
            return venue?.venueSettings?.customCoverTicketSettings?.isProcessingFeePassToCustomer == true ? true : false
        }
        
        if selectedCoverTickets.allSatisfy({ $0.isCustom == false }) {
            return venue?.venueSettings?.coverTicketSettings?.isProcessingFeePassToCustomer == true && venue?.venueSettings?.coverTicketSettings?.isUpFront == false ? true : false
        }
        
        if ((venue?.venueSettings?.coverTicketSettings?.isProcessingFeePassToCustomer == true && venue?.venueSettings?.coverTicketSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketSettings?.isProcessingFeePassToCustomer == true) && isProcessingFeeApplied {
            return true
        }
        return false
    }
    
    private func getCustomTextFieldInputAccessoryView(with items: [UIBarButtonItem]) -> UIToolbar {
        let toolbar: UIToolbar = UIToolbar()
        
        toolbar.barStyle = UIBarStyle.default
        toolbar.items = items
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    @objc func checkApplePay() {
        if !checkAllData {
            checkValidation()
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } else {
            if isValidNo == false {
                alertPopup("Alert", "Enter valid number")
                return
            }
            if StripeAPI.deviceSupportsApplePay() {
                if isIntendCreated {
                    DispatchQueue.main.async {
                        self.applePayButtonTapped()
                    }
                    return
                }
                
                applePayBtn.isHidden = false
                errorLbl.isHidden = true
            } else if isApplePayNotSupported == false {
                alertForWallet()
                setUpPaymentBtn()
            } else {
                applePayBtn.isHidden = true
                errorLbl.isHidden = false
            }
        }
    }
    
    private func checkValidation() {
        if phoneNumTextField.text ?? "" == "" {
            phoneNumTextField.shake()
            phoneNumberUnderlineView.backgroundColor = .red
        }
        
        if firstNameTF.text ?? "" == "" {
                firstNameTF.shake()
                firstNameUnderlineView.backgroundColor = .red
            }
            if lastNameTF.text ?? "" == "" {
                lastNameTF.shake()
                lastNameUnderlineView.backgroundColor = .red
            }
    }
    
    private var checkAllData: Bool {
        if phoneNumTextField.text ?? "" == "" {
            return false
        }
        
        if firstNameTF.text ?? "" == "" || lastNameTF.text ?? "" == "" {
            return false
        }
        
        return true
    }
    
    @objc private func textFieldValDidChange(_ textField: UITextField) {
        isIntendCreated = false
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
            PKPaymentSummaryItem(label: "Speakeasy Bookings Inc. (VIA Speakeasy Go!)", amount: NSDecimalNumber(value: (totalPrice)))
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
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                DispatchQueue.main.async {
                    AppClipLoader.showLoader(self.view)
                }
            case .canceled:
                self.isPaymentInitiated = false
            case .failed:
                self.isPaymentInitiated = false
                self.alertPopup("Alert", "Payment failed")
            }
        }
    }
    
    private var validateEmail: Bool {
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
            AppClipLoader.showLoader(view)
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
            let customFee = self.paymentDetail?.customFees?[indexPath.row]
            cell.lblFeeName.text = customFee?.name ?? "Custom fee"
            cell.lblFeeValue.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((customFee?.fee ?? 0).decimalFormat(true))"
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
