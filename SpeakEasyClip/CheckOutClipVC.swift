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

enum PaymentStatus: String {
    case SUCCESS
    case FAILED
}

final class CheckOutClipVC: UIViewController, ApplePayContextDelegate {

    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var countryCodeTextField: FPNTextField!
    @IBOutlet private weak var phoneNumTextField: UITextField!
    @IBOutlet private weak var countrySelectionView: UIView!
    @IBOutlet private weak var errorLbl: UILabel!
    @IBOutlet private weak var firstNameView: UIView!
    @IBOutlet private weak var lastNameView: UIView!
    @IBOutlet private weak var firstNameTF: UITextField!
    @IBOutlet private weak var lastNameTF: UITextField!
    @IBOutlet private weak var applePayBtn: PKPaymentButton!
    @IBOutlet private weak var dressCodeInfoLbl: UILabel!
    @IBOutlet private weak var policyCheckBox: UIButton!
    @IBOutlet private weak var policyView: UIView!
    @IBOutlet private weak var policyLbl: UILabel!
    @IBOutlet private weak var freeTicketBtn: UIButton!
    @IBOutlet private weak var freeTicketView: UIView!
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
    @IBOutlet weak var customFeeName: UILabel!
    @IBOutlet weak var customFeeAmount: UILabel!
    @IBOutlet weak var salesTextView: UIView!
    @IBOutlet weak var salesTextAmount: UILabel!
    @IBOutlet weak var noFeeView: UIView!
    @IBOutlet weak var salesTaxPr: UILabel!
    @IBOutlet weak var emailValidationLbl: UILabel!
    @IBOutlet weak var salesTaxName: UILabel!
    @IBOutlet weak var addOnsTableView: UITableView!
    @IBOutlet weak var addOnsTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var addOnsSubTotalView: UIView!
    @IBOutlet weak var addOnsSubTotalAmount: UILabel!
    @IBOutlet weak var addOnsProcessingView: UIView!
    @IBOutlet weak var addOnsProcessingAmount: UILabel!
    @IBOutlet weak var addOnsCustomFeeView: UIView!
    @IBOutlet weak var addOnsCustomFeeAmount: UILabel!
    @IBOutlet weak var addOnsCustomFeeName: UILabel!
    @IBOutlet weak var addOnsSalesTaxView: UIView!
    @IBOutlet weak var addOnsSalesTaxAmount: UILabel!
    @IBOutlet weak var addOnsSalesTaxeName: UILabel!
    @IBOutlet weak var addOnsTotalView: UIView!
    @IBOutlet weak var addOnsTotalAmount: UILabel!
    @IBOutlet weak var addOnsNOFeeView: UIView!
    @IBOutlet weak var addOnsView: UIView!
    @IBOutlet weak var totalView: UIView!
    @IBOutlet weak var grandTotalAmount: UILabel!
    @IBOutlet weak var ticketListView: UIView!
    
    var totalPrice = 1.0
    var venue: ClipVenue?
    var selectedAppClipTickets = [AppClipTicket]()
    private var paymentSheet: PaymentSheet?
    private var paymentIntent = ""
    private var paymentHistoryId = ""
    private var bookingId = ""
    private var isIntendCreated = false
    private var isApplePayNotSupported = false
    private var isPaymentInitiated = false
    private var checkFPNField = FPNTextField()
    private var countryCode = ""
    private var listController: FPNCountryListViewController = FPNCountryListViewController(style: .grouped)
    private var isValidNo = false
    private var isChangingFlag = false
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var addOnsHeightObservation: NSKeyValueObservation?
    private var retryCount = 0
    private var maxRetry = 3
    private var bookingCode = String()
    private var createdAT = String()
    private var addOnsPaymentDetails: PaymentDetail?
    var selectedAddOnsItem = [UpSellTicket]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        WebSocketWrapper.shared.delegate.append(self)
        
        ticketListView.isHidden = (selectedAppClipTickets.count == 0 && selectedAddOnsItem.count != 0) ? true : false
        addOnsView.isHidden = (selectedAppClipTickets.count == 0 || selectedAddOnsItem.count != 0) ? false : true
        totalView.isHidden = ticketListView.isHidden || addOnsView.isHidden
        
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        
        addOnsTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        addOnsHeightObservation = addOnsTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.addOnsTableViewHeight.constant = self.addOnsTableView.contentSize.height
            self.addOnsTableView.layoutIfNeeded()
        }
//        totalView.isHidden = true
//        addOnsView.isHidden = true
        
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickCountrySelect))
        countrySelectionView.addGestureRecognizer(tap)
        
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

        dressCodeInfoLbl.highlightBold(["\"All entry subject to doorman discretion\"."], size: 14, textColor: UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1))
        totalPriceLbl.text = totalPrice == 0 ? "\(venue?.venueSettings?.currencySymbol ?? "$")0.0" : "-"
        applePayBtn.addTarget(self, action: #selector(checkApplePay), for: .touchUpInside)
        if PKPaymentAuthorizationViewController.canMakePayments() {
            errorLbl.text = "Add Card to your Apple wallet & try again."
        } else {
            isApplePayNotSupported = true
            errorLbl.text = "Apple pay is not supported on your device, try another payment option."
        }
        policyCheckBox.setImage(CommonConstant.Icon.checkBoxEmpty, for: .normal)
        policyCheckBox.setImage(CommonConstant.Icon.checkBoxFull, for: .selected)
        policyCheckBox.isSelected = true
        policyView.isHidden = !(venue?.venueSettings?.optedPolicy == true)
        policyLbl.text = venue?.venueSettings?.policyText ?? "Opt in for future messages"
        firstNameView.isHidden = venue?.venueSettings?.collectNameDuringBooking ?? false == false
        lastNameView.isHidden = venue?.venueSettings?.collectNameDuringBooking ?? false == false
        
        if totalPrice == 0 {
            applePayView.isHidden = true
            cardPayView.isHidden = true
            freeTicketView.isHidden = false
        } else {
            applePayView.isHidden = false
            cardPayView.isHidden = !(venue?.allowCC ?? false)
            freeTicketView.isHidden = true
        }
        checkValidation(isCorrectDetails: false)
        firstNameTF.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.allEvents)
        lastNameTF.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.allEvents)
        emailTF.addTarget(self, action: #selector(textFieldValDidChange), for: UIControl.Event.allEvents)
        firstNameTF.addNextButtonKeyboard(superViewCount: 3)
        lastNameTF.addNextButtonKeyboard(superViewCount: 3)
        emailTF.addDoneButtonKeyboard()
        emailTF.placeholder = venue?.venueSettings?.collectEmailDuringBookingOptional == true ? "Email (optional)" : "Email"
        emailView.isHidden = venue?.venueSettings?.collectEmailDuringBooking == true ? false : true
        if venue?.venueSettings?.coverTicketFeesSettings != nil && totalPrice != 0 {
            customFeeCount()
        } else {
            noFeeView.isHidden = false
        }
        emailValidationLbl.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        if totalPrice == 0 {
            scrollViewBottomConstraint.constant = 130 - view.safeAreaInsets.bottom
        } else {
            scrollViewBottomConstraint.constant = 190 - view.safeAreaInsets.bottom
        }
    }
    
    private var setSalesTaxView: Bool {
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == true }) {
            salesTaxPr.text = "(\(venue?.venueSettings?.customCoverTicketFeesSettings?.salesTax ?? 0.0)%)"
            return venue?.venueSettings?.customCoverTicketFeesSettings?.isEnableSalesTax == true ? true : false
        }
        
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == false }) {
            salesTaxPr.text = "(\(venue?.venueSettings?.coverTicketFeesSettings?.salesTax ?? 0.0)%)"
            return venue?.venueSettings?.coverTicketFeesSettings?.isEnableSalesTax == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false ? true : false
        }
        
        if (venue?.venueSettings?.coverTicketFeesSettings?.isEnableSalesTax == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketFeesSettings?.isEnableSalesTax == true {
            return true
        }
        return false
    }
    
    private var setCustomTaxView: Bool {
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == true }) {
            return venue?.venueSettings?.customCoverTicketFeesSettings?.isEnableCustomFee == true ? true : false
        }
        
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == false }) {
            return venue?.venueSettings?.coverTicketFeesSettings?.isEnableCustomFee == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false ? true : false
        }
        
        if (venue?.venueSettings?.coverTicketFeesSettings?.isEnableCustomFee == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketFeesSettings?.isEnableCustomFee == true {
            return true
        }
        return false
    }
    
    private var setProcessingTaxView: Bool {
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == true }) {
            return venue?.venueSettings?.customCoverTicketFeesSettings?.isProcessingFeePassToCustomer == true ? true : false
        }
        
        if selectedAppClipTickets.allSatisfy({ $0.isCustom ?? false == false }) {
            return venue?.venueSettings?.coverTicketFeesSettings?.isProcessingFeePassToCustomer == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false ? true : false
        }
        
        if (venue?.venueSettings?.coverTicketFeesSettings?.isProcessingFeePassToCustomer == true && venue?.venueSettings?.coverTicketFeesSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketFeesSettings?.isProcessingFeePassToCustomer == true {
            return true
        }
        return false
    }
    
    private var setAddOnsSalesTaxView: Bool {
        return venue?.venueSettings?.addOnsBookingFeesSettings?.isEnableSalesTax == true ? true : false
    }
    
    private var setAddOnsProcessingTaxView: Bool {
        return venue?.venueSettings?.addOnsBookingFeesSettings?.isProcessingFeePassToCustomer == true ? true : false
    }
    
    private var setAddOnsCustomTaxView: Bool {
        return venue?.venueSettings?.addOnsBookingFeesSettings?.isEnableCustomFee == true ? true : false
    }
    
    private func setAddOnsData() {
        addOnsSubTotalView.isHidden = !setAddOnsSalesTaxView && !setAddOnsProcessingTaxView && !setAddOnsCustomTaxView
        addOnsSalesTaxView.isHidden = !setAddOnsSalesTaxView
        addOnsProcessingView.isHidden = !setAddOnsProcessingTaxView
        addOnsCustomFeeView.isHidden = !setAddOnsCustomTaxView
        addOnsNOFeeView.isHidden = !addOnsSubTotalView.isHidden
        
        addOnsCustomFeeAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((addOnsPaymentDetails?.customFee ?? 0).decimalFormat(true))"
        addOnsProcessingAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((addOnsPaymentDetails?.processingFee ?? 0).decimalFormat(true))"
        addOnsTotalAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((addOnsPaymentDetails?.total ?? 0).decimalFormat(true))"
        addOnsSalesTaxAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((addOnsPaymentDetails?.salesTax ?? 0).decimalFormat(true))"
        addOnsSubTotalAmount.text = "\(venue?.venueSettings?.currencySymbol ?? "$")\((addOnsPaymentDetails?.subTotal ?? 0).decimalFormat(true))"
        addOnsCustomFeeName.text = addOnsPaymentDetails?.customFeeName ?? "Custom fee"
        addOnsSalesTaxeName.text = addOnsPaymentDetails?.salesTaxName ?? "" == "" ? "Sales Tax" : addOnsPaymentDetails?.salesTaxName
    }
    
    private func getAddOnsPaymentIntent(bookingId: String) {
        AppClipLoader.showLoader(self.view)
        var addOnsItems = [[String: Any]]()
        selectedAddOnsItem.forEach {
            addOnsItems.append(["id": $0.id,
                                "addOnsId": $0.addOns?.id ?? "",
                                "quantity": $0.selectedQuantity ?? 0])
        }
        var param = [String: Any]()
        param["addOnsItems"] = addOnsItems
        param["venueId"] = venue?.id ?? ""
        param["phone"] = "\(phoneNumTextField.text?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "") ?? "")"
        param["code"] = countryCode
        if bookingId != "" {
            param["bookingId"] = bookingId
        }
        
        var postData = Data()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            if let jsonData = jsonString?.data(using: .utf8) {
                postData = jsonData
            }
        } catch {
            print("Error converting dictionary to JSON string: \(error)")
        }
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/payment/add-ons") else { return }
        var request = URLRequest(url: userURL, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Data not found")
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Internal data formate error")
                return
            }
            
            if let paymentDetail = json["fees"] as? [String: Any], let subTotal = paymentDetail["sub_total"] as? Double, let processingFee = paymentDetail["processing_fee"] as? Double, let customFee = paymentDetail["custom_fee"] as? Double, let salesTax = paymentDetail["sales_tax"] as? Double, let total = paymentDetail["total"] as? Double, let customFeeName = paymentDetail["custom_fee_name"] as? String, let salesTaxName = paymentDetail["sales_tax_name"] as? String {
                DispatchQueue.main.async {
                    AppClipLoader.hideLoader()
                    self.addOnsSubTotalView.isHidden = !self.setAddOnsSalesTaxView && !self.setAddOnsProcessingTaxView && !self.setAddOnsCustomTaxView
                    self.addOnsSalesTaxView.isHidden = !self.setAddOnsSalesTaxView
                    self.addOnsProcessingView.isHidden = !self.setAddOnsProcessingTaxView
                    self.addOnsCustomFeeView.isHidden = !self.setAddOnsCustomTaxView
                    self.addOnsNOFeeView.isHidden = !self.addOnsSubTotalView.isHidden
                    
                    self.addOnsSubTotalAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(subTotal.decimalFormat(true))"
                    self.addOnsProcessingAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(processingFee.decimalFormat(true))"
                    self.addOnsSalesTaxAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(salesTax.decimalFormat(true))"
                    self.addOnsCustomFeeAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(customFee.decimalFormat(true))"
                    self.addOnsCustomFeeName.text = customFeeName == "" ? "Custom Fee" : customFeeName
                    self.addOnsTotalAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(total.decimalFormat(true))"
                    self.addOnsSalesTaxeName.text = salesTaxName == "" ? "Sales Tax" : salesTaxName
                }
            }
        }
        task.resume()
    }
    
    private func customFeeCount() {
        AppClipLoader.showLoader(self.view)
        var selectedTickets = [[String: Any]]()
        selectedAppClipTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                    "quantity": $0.selectedQuantity ?? 0])
        }
        let param = ["cart": selectedTickets,
                     "isAppClipPayment": true,
                     "isTieredTicket": false,
                     "venueId": venue?.id ?? ""] as [String: Any]
        var postData = Data()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            if let jsonData = jsonString?.data(using: .utf8) {
                postData = jsonData
            }
        } catch {
            print("Error converting dictionary to JSON string: \(error)")
        }
        
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/payment/calculate-cover-fees") else { return }
        var request = URLRequest(url: userURL, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Data not found")
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Internal data formate error")
                return
            }
            if let subTotal = json["sub_total"] as? Double, let processingFee = json["processing_fee"] as? Double, let customFee = json["custom_fee"] as? Double, let salesTax = json["sales_tax"] as? Double, let total = json["total"] as? Double, let customFeeName = json["custom_fee_name"] as? String, let salesTaxName = json["sales_tax_name"] as? String {
                DispatchQueue.main.async {
                    AppClipLoader.hideLoader()
                    self.subTotalView.isHidden = !self.setSalesTaxView && !self.setProcessingTaxView && !self.setCustomTaxView
                    self.salesTextView.isHidden = !self.setSalesTaxView
                    self.processingFeeView.isHidden = !self.setProcessingTaxView
                    self.customFeeView.isHidden = !self.setCustomTaxView
                    self.noFeeView.isHidden = !self.subTotalView.isHidden
                    
                    self.subTotalAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(subTotal.decimalFormat(true))"
                    self.processingFeeAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(processingFee.decimalFormat(true))"
                    self.salesTextAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(salesTax.decimalFormat(true))"
                    self.customFeeAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(customFee.decimalFormat(true))"
                    self.customFeeName.text = customFeeName == "" ? "Custom Fee" : customFeeName
                    self.totalPriceLbl.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(total.decimalFormat(true))"
                    self.totalPrice = total
                    self.salesTaxName.text = salesTaxName == "" ? "Sales Tax" : salesTaxName
                }
            }
        }
        task.resume()
    }
    
    private func getCustomTextFieldInputAccessoryView(with items: [UIBarButtonItem]) -> UIToolbar {
        let toolbar: UIToolbar = UIToolbar()
        
        toolbar.barStyle = UIBarStyle.default
        toolbar.items = items
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    @objc private func dismissCountries() {
        isChangingFlag = false
        listController.dismiss(animated: true, completion: nil)
    }
    
    @objc func onClickCountrySelect() {
        fpnDisplayCountryList()
    }
    
    @objc func checkApplePay() {
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
            createBooking()
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
    
    private func checkValidation(isCorrectDetails: Bool) {
        freeTicketBtn.alpha = isCorrectDetails ? 1 : 0.5
        freeTicketBtn.isUserInteractionEnabled = isCorrectDetails
        applePayBtn.alpha = isCorrectDetails ? 1 : 0.5
        applePayBtn.isUserInteractionEnabled = isCorrectDetails
        cardPayBtn.alpha = isCorrectDetails ? 1 : 0.5
        cardPayBtn.isUserInteractionEnabled = isCorrectDetails
    }
    
    private var checkAllData: Bool {
        if !isValidNo {
            return false
        }
        if venue?.venueSettings?.collectNameDuringBooking ?? false == false {
            return true
        }
        if venue?.venueSettings?.collectNameDuringBooking == true {
            if firstNameTF.text == "" || lastNameTF.text == "" || !isValidNo {
                return false
            }
        }
        return true
    }
    
    @objc private func textFieldValDidChange(_ textField: UITextField) {
        isIntendCreated = false
        checkValidation(isCorrectDetails: checkAllData)
    }

    private func addPaymentApi(isApplePay: Bool = true) {
        if isIntendCreated { return }
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/payment/\(bookingId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        var selectedTickets = [[String: Any]]()
        selectedAppClipTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                   "quantity": $0.selectedQuantity ?? 0])
        }
        var param = ["cart": selectedTickets] as [String: Any]
        param["isAppClipPayment"] = true
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
            self.setUpPaymentBottomSheet()
            self.setUpPaymentBtn()
            DispatchQueue.main.async {
                if isApplePay {
                    self.applePayButtonTapped()
                } else {
                    self.onClickCreditCardPay()
                }
            }
        })
        task.resume()
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
        let alertController = UIAlertController(title: "Add Card to Apple Pay", message: "Please add a card to your Apple Pay wallet and check again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let setUpAction = UIAlertAction(title: "Add Card", style: .default) { (_) in
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
            PKPaymentSummaryItem(label: "Speakeasy Bookings Inc. (VIA Speakeasy Go!)", amount: NSDecimalNumber(value: totalPrice))
        ]
        paymentRequest.requiredBillingContactFields = []
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            applePayContext.presentApplePay()
        } else {
            alertPopup("Alert", "Problem with your Apple Pay configuration")
        }
    }
    
    func paymentStatus(_ status: PaymentStatus, optedPolicy: Bool, completion: @escaping (()-> Void)) {
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/payment/\(paymentHistoryId)/\(bookingId)/status?status=\(status.rawValue)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        var param = [String: Any]()
        if venue?.venueSettings?.optedPolicy == true {
            param["optedPolicy"] = optedPolicy
        }
        let bodyData = try? JSONSerialization.data(
            withJSONObject: param,
            options: [.prettyPrinted]
        )
        request.httpBody = bodyData
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            if let error = error as? NSError {
                if self?.retryCount ?? 0 < self?.maxRetry ?? 0 {
                    self?.retryCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.paymentStatus(status, optedPolicy: optedPolicy, completion: completion)
                    }
                    return
                } else {
                    self?.failedAPI("error code:\(error.code), des:\(error.localizedDescription)")
                    completion()
                }
            } else {
                completion()
            }
        })
        task.resume()
    }

    private func failedAPI(_ msg: String) {
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/payment/failed") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        var param = [String: Any]()
        
        let msg = """
{
    "platform": "iOS appClip",
    "message": "reported after 3 failed try",
    "time": \(Date()),
    "comment": \(msg)
}
"""
        param["message"] = msg
        param["bookingId"] = bookingId
        let bodyData = try? JSONSerialization.data(
            withJSONObject: param,
            options: [.prettyPrinted]
        )
        request.httpBody = bodyData
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
        })
        task.resume()
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
                    self.paymentStatus(.SUCCESS, optedPolicy: self.policyCheckBox.isSelected) { [weak self] in
                        guard let self = self else { return }
                        self.navigateToQRCode()
                    }
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
        if venue?.venueSettings?.collectEmailDuringBooking == true {
            if venue?.venueSettings?.collectEmailDuringBookingOptional == true {
                if emailTF.text != "" {
                    if !(emailTF.text ?? "").isValidEmail {
                        return false
                    }
                }
            } else {
                let email = emailTF.text ?? ""
                if emailTF.text == "" || !(email.isValidEmail) {
                    return false
                }
            }
        }
        return true
    }
    
    @IBAction func onClickCardPay(_ sender: Any) {
        if isIntendCreated {
            DispatchQueue.main.async {
                self.onClickCreditCardPay()
            }
            return
        }
        createBooking(isApplePay: false)
    }

    @IBAction func onClickFreeTicket(_ sender: Any) {
        if !validateEmail {
            emailValidationLbl.isHidden = false
        } else {
            emailValidationLbl.isHidden = true
            createFreeBooking()
        }
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
            AppClipLoader.showLoader(view)
            paymentStatus(.SUCCESS, optedPolicy: policyCheckBox.isSelected) { [weak self] in
                guard let self = self else { return }
                self.navigateToQRCode()
            }
        case .error:
            isPaymentInitiated = false
            alertPopup("Alert", "Payment failed")
        case .userCancellation:
            isPaymentInitiated = false
//            alertPopup("Alert", "Payment interrupted")
        @unknown default:
            fatalError()
        }
    }

    func createBooking(isApplePay: Bool = true) {
        if !validateEmail {
            emailValidationLbl.isHidden = false
            return
        }
        emailValidationLbl.isHidden = true
        AppClipLoader.showLoader(self.view)
        var selectedTickets = [[String: Any]]()
        selectedAppClipTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                   "ticketQuantity": $0.selectedQuantity ?? 0])
        }
        var param = ["appclipTicket": selectedTickets,
                     "venueId": UserDefaults.standard.value(forKey: "venueIdLong") as? String ?? "",
                     "code": countryCode,
                     "phone": "\(phoneNumTextField.text?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "") ?? "")"] as [String: Any]
        if venue?.venueSettings?.collectNameDuringBooking == true {
            param["firstName"] = firstNameTF.text ?? ""
            param["lastName"] = lastNameTF.text ?? ""
        }
        if venue?.venueSettings?.collectEmailDuringBooking == true {
            if emailTF.text ?? "" != "" {
                param["email"] = emailTF.text ?? ""
            }
        }
        var postData = Data()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            if let jsonData = jsonString?.data(using: .utf8) {
                postData = jsonData
            }
        } catch {
            print("Error converting dictionary to JSON string: \(error)")
        }
        
        guard let userURL = URL(string: "\(SharedURL.baseURL)/appclip-user") else { return }
        var request = URLRequest(url: userURL, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Data not found")
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Internal data formate error")
                return
            }
            if let bookingId = json["id"] as? String {
                self.bookingId = bookingId
                self.addPaymentApi(isApplePay: isApplePay)
            } else if let booking = json["booking"] as? [String: Any], let bookingId = booking["id"] as? String, let venueObj = booking["venueObject"] as? [String: Any], let bookingCode = venueObj["bookingCode"] as? String, let createdAt = booking["createdAt"] as? String {
                self.bookingId = bookingId
                self.bookingCode = bookingCode
                self.createdAT = createdAt
                self.addPaymentApi(isApplePay: isApplePay)
            } else if let error = json["error"] as? String, let message = json["message"] as? String {
                AppClipLoader.hideLoader()
                self.alertPopup(error, message)
            } else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Booking failed")
            }
        }
        task.resume()
    }
    
    func createFreeBooking() {
        AppClipLoader.showLoader(self.view)
        var selectedTickets = [[String: Any]]()
        selectedAppClipTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                   "ticketQuantity": $0.selectedQuantity ?? 0])
        }
        var param = ["appclipTicket": selectedTickets,
                     "venueId": UserDefaults.standard.value(forKey: "venueIdLong") as? String ?? "",
                     "code": countryCode,
                     "phone": "\(phoneNumTextField.text?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "") ?? "")",
                     "optedPolicy": policyCheckBox.isSelected] as [String: Any]
        if venue?.venueSettings?.collectNameDuringBooking ?? false {
            param["firstName"] = firstNameTF.text ?? ""
            param["lastName"] = lastNameTF.text ?? ""
        }
        var postData = Data()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            if let jsonData = jsonString?.data(using: .utf8) {
                postData = jsonData
            }
        } catch {
            print("Error converting dictionary to JSON string: \(error)")
        }
        
        guard let userURL = URL(string: "\(SharedURL.baseURL)/appclip-user/free-booking") else { return }
        var request = URLRequest(url: userURL, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Data not found")
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Internal data formate error")
                return
            }
            if let bookingId = json["id"] as? String {
                self.bookingId = bookingId
                self.navigateToQRCode()
            } else if let booking = json["booking"] as? [String: Any], let bookingId = booking["id"] as? String {
                self.bookingId = bookingId
                self.navigateToQRCode()
            } else if let error = json["error"] as? String, let message = json["message"] as? String {
                AppClipLoader.hideLoader()
                self.alertPopup(error, message)
            } else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Booking failed")
            }
        }
        task.resume()
    }
    
    private func navigateToQRCode() {
        DispatchQueue.main.async {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "QRCodeClipVC")) as? QRCodeClipVC {
                AppClipLoader.hideLoader()
                vc.venueName = self.venue?.name ?? ""
                vc.bookingId = self.bookingId
                vc.venueLogo = self.venue?.logo?.key ?? ""
                vc.venueAttachment = self.venue?.venueAttachment.first?.key ?? ""
                vc.selectedAppClipTickets = self.selectedAppClipTickets
                vc.bookingCode = self.bookingCode
                vc.createdAT = self.createdAT.convertDateFormat(from: "yyyy-MM-dd'T'HH:mm:ss.SSSz", to: "h:mma MMMM dd")
                if let selectVC = self.navigationController?.viewControllers.first(where: { $0.isKind(of: SelectTicketClipVC.self) }) {
                    self.navigationController?.viewControllers = [selectVC, vc]
                }
            }
        }
    }
}

extension CheckOutClipVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return tableView == ticketListTableView ? selectedAppClipTickets.count : selectedAddOnsItem.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        
        cell.titleLbl.text = tableView == ticketListTableView ? selectedAppClipTickets[indexPath.row].name : selectedAddOnsItem[indexPath.row].addOns?.name
        cell.subTitleLbl.text = tableView == ticketListTableView ? selectedAppClipTickets[indexPath.row].description : selectedAddOnsItem[indexPath.row].addOns?.description
        cell.quantityLbl.text = tableView == ticketListTableView ? "\(selectedAppClipTickets[indexPath.row].selectedQuantity ?? 0)x" : "\(selectedAddOnsItem[indexPath.row].selectedQuantity ?? 0)x"
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}

extension CheckOutClipVC: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        checkFPNField.text = textField.text
        checkFPNField.sendActions(for: .editingChanged)
        phoneNumTextField.delegate = nil
        if textField.text?.contains("+") == true && checkFPNField.text?.contains("+") == false {
            checkFPNField.sendActions(for: .editingChanged)
        }
        phoneNumTextField.text = checkFPNField.text
        phoneNumTextField.delegate = self
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if isChangingFlag { return }
        if !isValidNo {
            if textField.text?.replacingOccurrences(of: " ", with: "") != "" {
                alertPopup("Alert", "Enter valid number")
            }
        }
    }
}

extension CheckOutClipVC: FPNTextFieldDelegate {
    func fpnDisplayCountryList() {
        isChangingFlag = true
        let navigationViewController = UINavigationController(rootViewController: listController)
        listController.title = "Countries"
        listController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissCountries))
        listController.navigationController?.presentationController?.delegate = self
        present(navigationViewController, animated: true, completion: nil)
    }
    
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
        if let countryCode = FPNCountryCode(rawValue: code) {
            isChangingFlag = false
            if countryCode == checkFPNField.selectedCountry?.code { return }
            checkFPNField.delegate = nil
            checkFPNField.setFlag(countryCode: countryCode)
            checkFPNField.delegate = self
            checkFPNField.sendActions(for: .editingChanged)
            phoneNumTextField.delegate = nil
            phoneNumTextField.text = checkFPNField.text
            phoneNumTextField.delegate = self
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
            checkValidation(isCorrectDetails: checkAllData)
            isIntendCreated = false
        }
    }
}

extension CheckOutClipVC: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        if isPaymentInitiated { return }
        if navigationController?.viewControllers.last is CheckOutClipVC && uniqueId == UserDefaults.standard.value(forKey: "venueId") as? String ?? "" {
            if isVenueStatusUpdate {
                alertPopup("Update", "Venue your trying to booking is closed") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else if isPriceUpdated {
                alertPopup("Update", "The venue updated their prices") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
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

extension CheckOutClipVC: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        isChangingFlag = false
    }
}
