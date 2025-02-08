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
import AVFoundation

enum PaymentStatus: String {
    case SUCCESS
    case FAILED
}

final class CheckOutClipVC: UIViewController, ApplePayContextDelegate {
    
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
    @IBOutlet weak var addOnsSalesTaxPr: UILabel!
    @IBOutlet weak var addOnsSalesTaxeName: UILabel!
    @IBOutlet weak var addOnsTotalView: UIView!
    @IBOutlet weak var addOnsTotalAmount: UILabel!
    @IBOutlet weak var addOnsNOFeeView: UIView!
    @IBOutlet weak var addOnsView: UIView!
    @IBOutlet weak var totalView: UIView!
    @IBOutlet weak var grandTotalAmount: UILabel!
    @IBOutlet weak var ticketListView: UIView!
    @IBOutlet weak var phoneNumberView: UIView!
    @IBOutlet weak var firstNameUnderlineView: UIView!
    @IBOutlet weak var lastNameUnderlineView: UIView!
    @IBOutlet weak var emailUnderlineView: UIView!
    @IBOutlet weak var phoneNumberUnderlineView: UIView!
    @IBOutlet weak var noFeesText: UILabel!
    @IBOutlet weak var noFeesTextForAddOns: UILabel!
    
    var totalPrice = 1.0
    var totalAddOnPrice = 0.0
    var venue: ClipVenue?
    var selectedCoverTickets = [CoverTicket]()
    private var paymentSheet: PaymentSheet?
    private var paymentIntent = ""
    private var paymentHistoryId = ""
    private var bookingId = ""
    private var addOnsBookingId = ""
    private var isIntendCreated = false
    private var isApplePayNotSupported = false
    private var isPaymentInitiated = false
    private var isValidNo = false
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var addOnsHeightObservation: NSKeyValueObservation?
    private var retryCount = 0
    private var maxRetry = 3
    private var createdAT = String()
    private var addOnsPaymentDetails: PaymentDetail?
    var selectedAddOnsItem = [UpSellTicket]()
    var isOnlyAddOnsAvailable = false
    var bookingType: TicketPriceType = .PAID
    var venueImageData = Data()
    let phoneNumberUtility = PhoneNumberUtility()
    var phoneNumber: PhoneNumber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        WebSocketWrapper.shared.delegate.append(self)
        
        ticketListView.isHidden = (selectedCoverTickets.count == 0 && selectedAddOnsItem.count != 0) ? true : false
        addOnsView.isHidden = (selectedCoverTickets.count == 0 || selectedAddOnsItem.count != 0) ? false : true
        totalView.isHidden = ticketListView.isHidden || addOnsView.isHidden
        isOnlyAddOnsAvailable = selectedCoverTickets.count == 0 ? true : false
        
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
        
        dressCodeInfoLbl.highlightBold(["\"All entry subject to doorman discretion\"."], size: 14, textColor: UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1))
        totalPriceLbl.text = totalPrice == 0 ? "\(venue?.venueSettings?.currencySymbol ?? "$")0.00" : "-"
        applePayBtn.addTarget(self, action: #selector(checkApplePay), for: .touchUpInside)
        if PKPaymentAuthorizationViewController.canMakePayments() {
            errorLbl.text = "Add Card to your Apple wallet & try again.".localize()
        } else {
            isApplePayNotSupported = true
            errorLbl.text = "Apple pay is not supported on your device, try another payment option.".localize()
        }
        policyCheckBox.setImage(CommonConstant.Icon.checkBoxEmpty, for: .normal)
        policyCheckBox.setImage(CommonConstant.Icon.checkBoxFull, for: .selected)
        policyCheckBox.isSelected = true
        policyView.isHidden = !(venue?.venueSettings?.optedPolicy == true)
        policyLbl.text = venue?.venueSettings?.policyText ?? "Opt in for future messages".localize()
        firstNameView.isHidden = venue?.venueSettings?.collectNameDuringBooking ?? false == false
        lastNameView.isHidden = venue?.venueSettings?.collectNameDuringBooking ?? false == false
        
        if totalPrice == 0 && selectedAddOnsItem.count == 0 {
            applePayView.isHidden = true
            cardPayView.isHidden = true
            freeTicketView.isHidden = false
        } else {
            applePayView.isHidden = false
            cardPayView.isHidden = !(venue?.allowCC ?? false)
            freeTicketView.isHidden = true
        }
        if bookingType == .FREE {
            applePayView.isHidden = selectedAddOnsItem.count == 0
            cardPayView.isHidden = selectedAddOnsItem.count == 0
            freeTicketView.isHidden = !(selectedAddOnsItem.count == 0)
        }
//        checkValidation(isCorrectDetails: false)
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
        emailTF.placeholder = venue?.venueSettings?.collectEmailDuringBookingOptional == true ? "Email (optional)" : "Email"
        emailView.isHidden = venue?.venueSettings?.collectEmailDuringBooking == true ? false : true
        if venue?.venueSettings?.coverTicketSettings != nil && totalPrice != 0 {
            customFeeCount()
            if selectedAddOnsItem.count != 0 {
                getCalculatedAddOnsFee()
            }
        } else {
            noFeeView.isHidden = false
        }
        emailValidationLbl.isHidden = true
        if let color = self.venue?.venueSettings?.whiteLabelColor {
            self.freeTicketBtn.backgroundColor = UIColor(hex: color)
            self.noFeesText.textColor = UIColor(hex: color)
            self.noFeesTextForAddOns.textColor = UIColor(hex: color)
        }
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
        
        if (venue?.venueSettings?.coverTicketSettings?.isEnableSalesTax == true && venue?.venueSettings?.coverTicketSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketSettings?.isEnableSalesTax == true {
            let customTicket = selectedCoverTickets.first(where: { $0.isCustom == true && $0.price > 0 })
            salesTaxPr.text = customTicket == nil ? "(\(venue?.venueSettings?.coverTicketSettings?.salesTax ?? 0.0)%)" : "(\(venue?.venueSettings?.customCoverTicketSettings?.salesTax ?? 0.0)%)"
            return true
        }
        return false
    }
    
    private var setCustomTaxView: Bool {
        if selectedCoverTickets.allSatisfy({ $0.isCustom == true }) {
            return venue?.venueSettings?.customCoverTicketSettings?.isEnableCustomFee == true ? true : false
        }
        
        if selectedCoverTickets.allSatisfy({ $0.isCustom == false }) {
            return venue?.venueSettings?.coverTicketSettings?.isEnableCustomFee == true && venue?.venueSettings?.coverTicketSettings?.isUpFront == false ? true : false
        }
        
        if (venue?.venueSettings?.coverTicketSettings?.isEnableCustomFee == true && venue?.venueSettings?.coverTicketSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketSettings?.isEnableCustomFee == true {
            return true
        }
        return false
    }
    
    private var setProcessingTaxView: Bool {
        if selectedCoverTickets.allSatisfy({ $0.isCustom == true }) {
            return venue?.venueSettings?.customCoverTicketSettings?.isProcessingFeePassToCustomer == true ? true : false
        }
        
        if selectedCoverTickets.allSatisfy({ $0.isCustom == false }) {
            return venue?.venueSettings?.coverTicketSettings?.isProcessingFeePassToCustomer == true && venue?.venueSettings?.coverTicketSettings?.isUpFront == false ? true : false
        }
        
        if (venue?.venueSettings?.coverTicketSettings?.isProcessingFeePassToCustomer == true && venue?.venueSettings?.coverTicketSettings?.isUpFront == false) || venue?.venueSettings?.customCoverTicketSettings?.isProcessingFeePassToCustomer == true {
            return true
        }
        return false
    }
    
    private var setAddOnsSalesTaxView: Bool {
        addOnsSalesTaxPr.text = "(\(venue?.venueSettings?.addOnsBookingSettings?.salesTax ?? 0.0)%)"
        return (venue?.venueSettings?.addOnsBookingSettings?.isEnableSalesTax ?? true && venue?.venueSettings?.addOnsBookingSettings?.isUpFront == false) ? true : false
    }
    
    private var setAddOnsProcessingTaxView: Bool {
        return (venue?.venueSettings?.addOnsBookingSettings?.isProcessingFeePassToCustomer == true && venue?.venueSettings?.addOnsBookingSettings?.isUpFront == false) ? true : false
    }
    
    private var setAddOnsCustomTaxView: Bool {
        return (venue?.venueSettings?.addOnsBookingSettings?.isEnableCustomFee ?? true && venue?.venueSettings?.addOnsBookingSettings?.isUpFront == false) ? true : false
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
    
    private func getCalculatedAddOnsFee() {
        AppClipLoader.showLoader(self.view)
        var addOnsItems = [[String: Any]]()
        selectedAddOnsItem.forEach {
            addOnsItems.append(["id": $0.id,
                                "addOnsId": $0.addOns?.id ?? "",
                                "quantity": $0.selectedQuantity ?? 0])
        }
        var param = [String: Any]()
        var paramData = [String: Any]()
        param["addOnsItems"] = addOnsItems
        param["venueId"] = venue?.id ?? ""
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
        
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/payment/calculate-add-ons-fees") else { return }
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
            
            var paymentDetail = [String: Any]()
            if !SharedURL.isEncryptionEnabled {
                guard let paymentDetailData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                paymentDetail = paymentDetailData
            } else {
                guard let response = String(data: data, encoding: .utf8) else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                paymentDetail =  response.decrypted() ?? [:]
            }
            AppClipLoader.hideLoader()
            
            if let subTotal = paymentDetail["subTotal"] as? Double, let processingFee = paymentDetail["processingFee"] as? Double, let customFee = paymentDetail["customFee"] as? Double, let salesTax = paymentDetail["salesTax"] as? Double, let total = paymentDetail["total"] as? Double, let customFeeName = paymentDetail["customFeeName"] as? String, let salesTaxName = paymentDetail["salesTaxName"] as? String {
                DispatchQueue.main.async {
                    AppClipLoader.hideLoader()
                    self.addOnsSubTotalView.isHidden = (!self.setAddOnsSalesTaxView && !self.setAddOnsProcessingTaxView && !self.setAddOnsCustomTaxView) || (subTotal == total)
                    self.addOnsSalesTaxView.isHidden = !self.setAddOnsSalesTaxView
                    self.addOnsProcessingView.isHidden = (!self.setAddOnsProcessingTaxView) || (processingFee == 0)
                    self.addOnsCustomFeeView.isHidden = !self.setAddOnsCustomTaxView
                    self.addOnsNOFeeView.isHidden = !self.addOnsSubTotalView.isHidden
                    self.totalAddOnPrice = total
//                    self.addOnsProcessingView.isHidden = processingFee == 0
//                    self.addOnsSubTotalView.isHidden = subTotal == total
                    
                    self.addOnsSubTotalAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(subTotal.decimalFormat(true))"
                    self.addOnsProcessingAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(processingFee.decimalFormat(true))"
                    self.addOnsSalesTaxAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(salesTax.decimalFormat(true))"
                    self.addOnsCustomFeeAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(customFee.decimalFormat(true))"
                    self.addOnsCustomFeeName.text = customFeeName == "" ? "Custom Fee" : customFeeName
                    self.addOnsTotalAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\(total.decimalFormat(true))"
                    self.addOnsSalesTaxeName.text = salesTaxName == "" ? "Sales Tax" : salesTaxName
                    self.grandTotalAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\((total + self.totalPrice).decimalFormat(true))"
                }
            }
        }
        task.resume()
    }
    
    private func getAddOnsPaymentIntent(bookingId: String, isApplePay: Bool) {
        let countryCode = phoneNumTextField?.flagButton.titleLabel?.text?.components(separatedBy: .whitespaces).joined().filter { $0.isASCII } ?? "+1"
        DispatchQueue.main.async {
            AppClipLoader.showLoader(self.view)
        }
        var addOnsItems = [[String: Any]]()
        selectedAddOnsItem.forEach {
            addOnsItems.append(["id": $0.id,
                                "addOnsId": $0.addOns?.id ?? "",
                                "quantity": $0.selectedQuantity ?? 0])
        }
        var param = [String: Any]()
        var paramData = [String: Any]()
        param["addOnsItems"] = addOnsItems
        param["venueId"] = venue?.id ?? ""
        param["phone"] = "\(self.phoneNumber?.nationalNumber ?? 0)"
        param["code"] = countryCode
        if bookingId != "" {
            param["bookingId"] = bookingId
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
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/payment/add-ons") else { return }
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
            var json = [String: Any]()
            if !SharedURL.isEncryptionEnabled {
                guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json = jsonData
            } else {
                guard let jsonData = String(data: data, encoding: .utf8) else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json = jsonData.decrypted() ?? [:]
            }
            if let paymentIntent = json["clientSecret"] as? String, let addOnsBookingId = json["bookingId"] as? String {
                DispatchQueue.main.async {
                    AppClipLoader.hideLoader()
                    self.isIntendCreated = true
                    self.addOnsBookingId = addOnsBookingId
                    self.paymentIntent = paymentIntent
//                    self.paymentHistoryId = paymentHistoryId
                    self.setUpPaymentBottomSheet()
                    self.setUpPaymentBtn()
                    DispatchQueue.main.async {
                        if isApplePay {
                            self.applePayButtonTapped()
                        } else {
                            self.onClickCreditCardPay()
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    private func getAddOnsBooking(completion: @escaping (()-> Void)) {
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/add-ons/\(self.addOnsBookingId)") else { return }
        var request = URLRequest(url: url)
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
        request.httpMethod = "GET"
        
        DispatchQueue.main.async {
            AppClipLoader.showLoader(self.view)
        }
        
        URLSession.shared.dataTask(with: request) { data, respons, error in
            DispatchQueue.main.async {
                guard let data = data else {
                    AppClipLoader.hideLoader()
                    return
                }
                var json = [String: Any]()
                if !SharedURL.isEncryptionEnabled {
                    guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                        AppClipLoader.hideLoader()
                        return
                    }
                    json = jsonData
                } else {
                    guard let response = String(data: data, encoding: .utf8) else {
                        AppClipLoader.hideLoader()
                        return
                    }
                    json = response.decrypted() ?? [:]
                }
                self.createdAT = json["createdAt"] as? String ?? ""
                completion()
            }
        }.resume()
    }
    
    private func customFeeCount() {
        AppClipLoader.showLoader(self.view)
        var selectedTickets = [[String: Any]]()
        selectedCoverTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                    "quantity": $0.selectedQuantity ?? 0])
        }
        var param = [String: Any]()
        let paramData = ["cart": selectedTickets,
                     "isAppClipPayment": true,
                     "isTieredTicket": false,
                     "venueId": venue?.id ?? ""] as [String: Any]
        
        if !SharedURL.isEncryptionEnabled {
            param = paramData
        } else {
            param = paramData.encrypted() ?? [:]
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
        
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/payment/calculate-cover-fees") else { return }
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
            var json = [String: Any]()
            if !SharedURL.isEncryptionEnabled {
                guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json = jsonData
            } else {
                guard let response = String(data: data, encoding: .utf8) else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json =  response.decrypted() ?? [:]
            }
            if let subTotal = json["subTotal"] as? Double, let processingFee = json["processingFee"] as? Double, let customFee = json["customFee"] as? Double, let salesTax = json["salesTax"] as? Double, let total = json["total"] as? Double, let customFeeName = json["customFeeName"] as? String, let salesTaxName = json["salesTaxName"] as? String {
                DispatchQueue.main.async {
                    AppClipLoader.hideLoader()
                    self.subTotalView.isHidden = (!self.setSalesTaxView && !self.setProcessingTaxView && !self.setCustomTaxView) || (subTotal == total)
                    self.salesTextView.isHidden = !self.setSalesTaxView
                    self.processingFeeView.isHidden = !self.setProcessingTaxView || processingFee == 0
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
                    self.grandTotalAmount.text = "\(self.venue?.venueSettings?.currencySymbol ?? "$")\((self.totalAddOnPrice + self.totalPrice).decimalFormat(true))"
                    if self.bookingType == .FREE {
                        self.subTotalView.isHidden = true
                        self.processingFeeView.isHidden = true
                        self.customFeeView.isHidden = true
                        self.salesTextView.isHidden = true
                    }
                }
            } else {
                AppClipLoader.hideLoader()
                alertPopup("Alert", "Something went wrong")
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
                if bookingType == .FREE && selectedAddOnsItem.count != 0 {
                    getAddOnsPaymentIntent(bookingId: "", isApplePay: true)
                } else {
                    if selectedCoverTickets.count == 0 {
                        getAddOnsPaymentIntent(bookingId: "", isApplePay: true)
                    } else {
                        createBooking()
                    }
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
//            countryCodeUnderlineView.backgroundColor = .red
        }
        
        if venue?.venueSettings?.collectNameDuringBooking ?? false == true {
            if firstNameTF.text ?? "" == "" {
                firstNameTF.shake()
                firstNameUnderlineView.backgroundColor = .red
            }
            if lastNameTF.text ?? "" == "" {
                lastNameTF.shake()
                lastNameUnderlineView.backgroundColor = .red
            }
        }
        
        if venue?.venueSettings?.collectEmailDuringBooking ?? false == true {
            if venue?.venueSettings?.collectEmailDuringBookingOptional ?? false == false {
                if emailTF.text ?? "" == "" {
                    emailTF.shake()
                    emailUnderlineView.backgroundColor = .red
                }
            }
        }
    }
    
    private var checkAllData: Bool {
        if phoneNumTextField.text ?? "" == "" {
            return false
        }
        
        if venue?.venueSettings?.collectNameDuringBooking ?? false == true && (firstNameTF.text ?? "" == "" || lastNameTF.text ?? "" == "") {
            return false
        }
        
        if venue?.venueSettings?.collectEmailDuringBooking ?? false == true {
            if venue?.venueSettings?.collectEmailDuringBookingOptional ?? false == false && emailTF.text ?? "" == "" {
                return false
            }
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
    
    private func addPaymentApi(isApplePay: Bool = true) {
        if isIntendCreated { return }
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/payment/\(bookingId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        var selectedTickets = [[String: Any]]()
        selectedCoverTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                    "quantity": $0.selectedQuantity ?? 0])
        }
        var paramData = [String: Any]()
        var param = ["cart": selectedTickets] as [String: Any]
        param["isAppClipPayment"] = true
        if !SharedURL.isEncryptionEnabled {
            paramData = param
        } else {
            paramData = param.encrypted() ?? [:]
        }
        let bodyData = try? JSONSerialization.data(
            withJSONObject: paramData,
            options: [.prettyPrinted]
        )
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = bodyData
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            AppClipLoader.hideLoader()
            guard let self = self else { return }
            guard let data = data else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Data not found")
                return
            }
            var json = [String: Any]()
            if !SharedURL.isEncryptionEnabled {
                guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json = jsonData
            } else {
                guard let response = String(data: data, encoding: .utf8) else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json =  response.decrypted() ?? [:]
            }
            guard let paymentIntentClientSecret = json["clientSecret"] as? String, let paymentHistoryId = json["paymentHistoryId"] as? String else {
                self.alertPopup("Alert", "Payment Initialisation issue")
                return
            }
            self.paymentIntent = paymentIntentClientSecret
            self.paymentHistoryId = paymentHistoryId
            if self.selectedAddOnsItem.count != 0 {
                DispatchQueue.main.async {
                    self.getAddOnsPaymentIntent(bookingId: self.bookingId, isApplePay: isApplePay)
                }
            } else {
                self.isIntendCreated = true
                self.setUpPaymentBottomSheet()
                self.setUpPaymentBtn()
                DispatchQueue.main.async {
                    if isApplePay {
                        self.applePayButtonTapped()
                    } else {
                        self.onClickCreditCardPay()
                    }
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
            PKPaymentSummaryItem(label: "Speakeasy Bookings Inc. (VIA Speakeasy Go!)", amount: NSDecimalNumber(value: (totalPrice + totalAddOnPrice)))
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
        var paramData = [String: Any]()
        if venue?.venueSettings?.optedPolicy == true {
            param["optedPolicy"] = optedPolicy
        }
        if !SharedURL.isEncryptionEnabled {
            paramData = param
        } else {
            paramData = param.encrypted() ?? [:]
        }
        let bodyData = try? JSONSerialization.data(
            withJSONObject: paramData,
            options: [.prettyPrinted]
        )
        request.httpBody = bodyData
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
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
    
    func addOnsPaymentSuccess(_ status: PaymentStatus, completion: @escaping (()-> Void)) {
        retryCount = 0
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/payment/add-ons/\(addOnsBookingId)/status?status=\(status.rawValue)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        var param = [String: Any]()
        var paramData = [String: Any]()
        param["bookingId"] = addOnsBookingId
        if bookingType == .FREE {
            param["mainBookingId"] = bookingId
        }
        if !SharedURL.isEncryptionEnabled {
            paramData = param
        } else {
            paramData = param.encrypted() ?? [:]
        }
        let bodyData = try? JSONSerialization.data(
            withJSONObject: paramData,
            options: [.prettyPrinted]
        )
        request.httpBody = bodyData
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            if let error = error as? NSError {
                if self?.retryCount ?? 0 < self?.maxRetry ?? 0 {
                    self?.retryCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.addOnsPaymentSuccess(status, completion: completion)
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
        var paramData = [String: Any]()
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
        if !SharedURL.isEncryptionEnabled {
            paramData = param
        } else {
            paramData = param.encrypted() ?? [:]
        }
        let bodyData = try? JSONSerialization.data(
            withJSONObject: paramData,
            options: [.prettyPrinted]
        )
        request.httpBody = bodyData
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
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
                    
                    if self.bookingType == .FREE {
                        self.createFreeBookingWithAddOns {
                            self.addOnsPaymentSuccess(.SUCCESS) {
                                self.getAddOnsBooking {
                                    AppClipLoader.hideLoader()
                                    if VenueImageManager.shared.customQRData == nil || VenueImageManager.shared.isEnableCoverTicketViewSettings == false {
                                        self.navigateToQR()
                                    } else {
                                        self.navigateToCustomQR()
                                    }
                                }
                            }
                        }
                    } else {
                        if self.selectedCoverTickets.count == 0 {
                            self.addOnsPaymentSuccess(.SUCCESS) {
                                self.getAddOnsBooking {
                                    AppClipLoader.hideLoader()
                                    if VenueImageManager.shared.customQRData == nil || VenueImageManager.shared.isEnableCoverTicketViewSettings == false {
                                        self.navigateToQR()
                                    } else {
                                        self.navigateToCustomQR()
                                    }
                                }
                            }
                        } else {
                            self.paymentStatus(.SUCCESS, optedPolicy: self.policyCheckBox.isSelected) { [weak self] in
                                guard let self = self else { return }
                                if self.selectedAddOnsItem.count != 0 {
                                    self.addOnsPaymentSuccess(.SUCCESS) {
                                        if VenueImageManager.shared.customQRData == nil || VenueImageManager.shared.isEnableCoverTicketViewSettings == false {
                                            self.navigateToQR()
                                        } else {
                                            self.navigateToCustomQR()
                                        }
                                    }
                                } else {
                                    if VenueImageManager.shared.customQRData == nil || VenueImageManager.shared.isEnableCoverTicketViewSettings == false {
                                        self.navigateToQR()
                                    } else {
                                        self.navigateToCustomQR()
                                    }
                                }
                            }
                        }
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
            
            if bookingType == .FREE && selectedAddOnsItem.count != 0 {
                getAddOnsPaymentIntent(bookingId: "", isApplePay: true)
            } else {
                if selectedCoverTickets.count == 0 {
                    getAddOnsPaymentIntent(bookingId: "", isApplePay: true)
                } else {
                    createBooking(isApplePay: false)
                }
            }
        }
    }

    @IBAction func onClickFreeTicket(_ sender: Any) {
        if !checkAllData {
            checkValidation()
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } else {
            if !validateEmail {
                emailValidationLbl.isHidden = false
            } else {
                emailValidationLbl.isHidden = true
                if isValidNo == false {
                    alertPopup("Alert", "Enter valid number")
                    return
                }
                createFreeBooking()
            }
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
            if bookingType == .FREE {
                createFreeBookingWithAddOns {
                    self.addOnsPaymentSuccess(.SUCCESS) {
                        self.getAddOnsBooking {
                            AppClipLoader.hideLoader()
                            if VenueImageManager.shared.customQRData == nil || VenueImageManager.shared.isEnableCoverTicketViewSettings == false {
                                self.navigateToQR()
                            } else {
                                self.navigateToCustomQR()
                            }
                        }
                    }
                }
            } else {
                if selectedCoverTickets.count == 0 {
                    self.addOnsPaymentSuccess(.SUCCESS) {
                        self.getAddOnsBooking {
                            AppClipLoader.hideLoader()
                            if VenueImageManager.shared.customQRData == nil || VenueImageManager.shared.isEnableCoverTicketViewSettings == false {
                                self.navigateToQR()
                            } else {
                                self.navigateToCustomQR()
                            }
                        }
                    }
                } else {
                    paymentStatus(.SUCCESS, optedPolicy: policyCheckBox.isSelected) { [weak self] in
                        guard let self = self else { return }
                        if self.selectedAddOnsItem.count != 0 {
                            self.addOnsPaymentSuccess(.SUCCESS) {
                                if VenueImageManager.shared.customQRData == nil || VenueImageManager.shared.isEnableCoverTicketViewSettings == false {
                                    self.navigateToQR()
                                } else {
                                    self.navigateToCustomQR()
                                }
                            }
                        } else {
                            if VenueImageManager.shared.customQRData == nil || VenueImageManager.shared.isEnableCoverTicketViewSettings == false {
                                self.navigateToQR()
                            } else {
                                self.navigateToCustomQR()
                            }
                        }
                    }
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

    func createBooking(isApplePay: Bool = true) {
        let countryCode = phoneNumTextField?.flagButton.titleLabel?.text?.components(separatedBy: .whitespaces).joined().filter { $0.isASCII } ?? "+1"
        if !validateEmail {
            emailValidationLbl.isHidden = false
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
        var param = ["appclipTicket": selectedTickets,
                     "venueId": UserDefaults.standard.value(forKey: "venueIdLong") as? String ?? "",
                     "code": countryCode,
                     "phone": "\(self.phoneNumber?.nationalNumber ?? 0)"] as [String: Any]
        if venue?.venueSettings?.collectNameDuringBooking == true {
            param["firstName"] = firstNameTF.text ?? ""
            param["lastName"] = lastNameTF.text ?? ""
        }
        if venue?.venueSettings?.collectEmailDuringBooking == true {
            if emailTF.text ?? "" != "" {
                param["email"] = emailTF.text ?? ""
            }
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
        
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/booking/create") else { return }
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
            var json = [String: Any]()
            if !SharedURL.isEncryptionEnabled {
                guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json = jsonData
            } else {
                guard let jsonData = String(data: data, encoding: .utf8) else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json = jsonData.decrypted() ?? [:]
            }
            
            if let bookingId = json["id"] as? String {
                self.bookingId = bookingId
                self.addPaymentApi(isApplePay: isApplePay)
            } else if let booking = json["booking"] as? [String: Any], let bookingId = booking["id"] as? String, let createdAt = booking["createdAt"] as? String {
                self.bookingId = bookingId
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
        let countryCode = phoneNumTextField?.flagButton.titleLabel?.text?.components(separatedBy: .whitespaces).joined().filter { $0.isASCII } ?? "+1"
        AppClipLoader.showLoader(self.view)
        var selectedTickets = [[String: Any]]()
        selectedCoverTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                   "ticketQuantity": $0.selectedQuantity ?? 0])
        }
        var paramData = [String: Any]()
        var param = ["appclipTicket": selectedTickets,
                     "venueId": UserDefaults.standard.value(forKey: "venueIdLong") as? String ?? "",
                     "code": countryCode,
                     "phone": "\(self.phoneNumber?.nationalNumber ?? 0)",
                     "optedPolicy": policyCheckBox.isSelected] as [String: Any]
        if venue?.venueSettings?.collectNameDuringBooking ?? false {
            param["firstName"] = firstNameTF.text ?? ""
            param["lastName"] = lastNameTF.text ?? ""
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
        
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/booking/appclip/free-booking") else { return }
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
            var json = [String: Any]()
            if !SharedURL.isEncryptionEnabled {
                guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json = jsonData
            } else {
                guard let jsonData = String(data: data, encoding: .utf8) else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json = jsonData.decrypted() ?? [:]
            }
            if let bookingId = json["id"] as? String {
                self.bookingId = bookingId
                if VenueImageManager.shared.customQRData == nil || VenueImageManager.shared.isEnableCoverTicketViewSettings == false {
                    self.navigateToQR()
                } else {
                    self.navigateToCustomQR()
                }
            } else if let booking = json["booking"] as? [String: Any], let bookingId = booking["id"] as? String, let createdAt = booking["createdAt"] as? String {
                self.bookingId = bookingId
                if VenueImageManager.shared.customQRData == nil || VenueImageManager.shared.isEnableCoverTicketViewSettings == false {
                    self.navigateToQR()
                } else {
                    self.navigateToCustomQR()
                }
                self.createdAT = createdAt
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
    
    func createFreeBookingWithAddOns(completion: @escaping (()-> Void)) {
        let countryCode = phoneNumTextField?.flagButton.titleLabel?.text?.components(separatedBy: .whitespaces).joined().filter { $0.isASCII } ?? "+1"
        AppClipLoader.showLoader(self.view)
        var selectedTickets = [[String: Any]]()
        selectedCoverTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                   "ticketQuantity": $0.selectedQuantity ?? 0])
        }
        var paramData = [String: Any]()
        var param = ["appclipTicket": selectedTickets,
                     "venueId": UserDefaults.standard.value(forKey: "venueIdLong") as? String ?? "",
                     "code": countryCode,
                     "phone": "\(self.phoneNumber?.nationalNumber ?? 0)",
                     "optedPolicy": policyCheckBox.isSelected] as [String: Any]
        if venue?.venueSettings?.collectNameDuringBooking ?? false {
            param["firstName"] = firstNameTF.text ?? ""
            param["lastName"] = lastNameTF.text ?? ""
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
        
        guard let userURL = URL(string: "\(SharedURL.baseURL)/appclip-user/free-booking") else { return }
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
            var json = [String: Any]()
            if !SharedURL.isEncryptionEnabled {
                guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json = jsonData
            } else {
                guard let jsonData = String(data: data, encoding: .utf8) else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Internal data formate error")
                    return
                }
                json = jsonData.decrypted() ?? [:]
            }
            if let bookingId = json["id"] as? String {
                self.bookingId = bookingId
                completion()
            } else if let booking = json["booking"] as? [String: Any], let bookingId = booking["id"] as? String {
                self.bookingId = bookingId
                completion()
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
    
    private func navigateToQR() {
        let countryCode = phoneNumTextField?.flagButton.titleLabel?.text?.components(separatedBy: .whitespaces).joined().filter { $0.isASCII } ?? "+1"
        DispatchQueue.main.async {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "QRClipVC")) as? QRClipVC {
                AppClipLoader.hideLoader()
                vc.venueName = self.venue?.name ?? ""
                vc.bookingId = self.bookingId
                vc.addOnBookingId = self.addOnsBookingId
                vc.venueLogo = self.venue?.logo?.key ?? ""
                vc.venueAttachment = self.venue?.venueAttachment?.first?.key ?? ""
                vc.appClipTicket = self.selectedCoverTickets
                vc.selectedAddOns = self.selectedAddOnsItem
                vc.bookingCode = self.venue?.bookingCode ?? ""
                vc.isOnlyAddOnsAvailable = self.isOnlyAddOnsAvailable
                vc.venueImageData = self.venueImageData
                vc.createdAT = self.createdAT.convertDateFormat(from: "yyyy-MM-dd'T'HH:mm:ss.SSSz", to: "h:mma MMMM dd", isUTC: true, customTimeZone: self.venue?.useTimezone ?? "")
                let userData = self.venue?.venueSettings?.collectNameDuringBooking ?? false == true ? "\(self.firstNameTF.text ?? "") \(self.lastNameTF.text ?? "")" : "\(countryCode) \(self.phoneNumber?.nationalNumber ?? 0)"
                vc.guestInfo = "\(userData) - \(self.createdAT.convertDateFormat(from: "yyyy-MM-dd'T'HH:mm:ss.SSSz", to: "h:mma MMMM dd", isUTC: true, customTimeZone: self.venue?.useTimezone ?? ""))"
                if let selectVC = self.navigationController?.viewControllers.first(where: { $0.isKind(of: SelectTicketClipVC.self) }) as? SelectTicketClipVC {
                    selectVC.forceRemoveAllTicket()
                    self.navigationController?.viewControllers = [selectVC, vc]
                }
            }
        }
    }
    
    private func navigateToCustomQR() {
        let countryCode = phoneNumTextField?.flagButton.titleLabel?.text?.components(separatedBy: .whitespaces).joined().filter { $0.isASCII } ?? "+1"
        DispatchQueue.main.async {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "CustomQRScreen")) as? CustomQRScreen {
                AppClipLoader.hideLoader()
                vc.bookingId = self.bookingId
                vc.addOnBookingId = self.addOnsBookingId
                vc.appClipTicket = self.selectedCoverTickets
                vc.selectedAddOns = self.selectedAddOnsItem
                vc.bookingCode = self.venue?.bookingCode ?? ""
                vc.isOnlyAddOnsAvailable = self.isOnlyAddOnsAvailable
                vc.createdAT = self.createdAT.convertDateFormat(from: "yyyy-MM-dd'T'HH:mm:ss.SSSz", to: "h:mma MMMM dd", isUTC: true, customTimeZone: self.venue?.useTimezone ?? "")
                
                let userData = self.venue?.venueSettings?.collectNameDuringBooking ?? false == true ? "\(self.firstNameTF.text ?? "") \(self.lastNameTF.text ?? "")" : "\(countryCode) \(self.phoneNumber?.nationalNumber ?? 0)"
                vc.guestInfo = "\(userData) - \(self.createdAT.convertDateFormat(from: "yyyy-MM-dd'T'HH:mm:ss.SSSz", to: "h:mma MMMM dd", isUTC: true, customTimeZone: self.venue?.useTimezone ?? ""))"
                if let selectVC = self.navigationController?.viewControllers.first(where: { $0.isKind(of: SelectTicketClipVC.self) }) as? SelectTicketClipVC {
                    selectVC.forceRemoveAllTicket()
                    self.navigationController?.viewControllers = [selectVC, vc]
                }
            }
        }
    }
}

extension CheckOutClipVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return tableView == ticketListTableView ? selectedCoverTickets.count : selectedAddOnsItem.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC

        if tableView == ticketListTableView {
            cell.titleLbl.text = selectedCoverTickets[indexPath.row].customName ?? "" == "" ? selectedCoverTickets[indexPath.row].displayName : selectedCoverTickets[indexPath.row].displayCustomName
        } else {
            cell.titleLbl.text = selectedAddOnsItem[indexPath.row].addOns?.name
        }
        cell.subTitleLbl.text = tableView == ticketListTableView ? selectedCoverTickets[indexPath.row].description : selectedAddOnsItem[indexPath.row].addOns?.description
        cell.quantityLbl.text = tableView == ticketListTableView ? "\(selectedCoverTickets[indexPath.row].selectedQuantity ?? 0)x" : "\(selectedAddOnsItem[indexPath.row].selectedQuantity ?? 0)x"
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}

extension CheckOutClipVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
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

extension CheckOutClipVC: WebSocketCallBackDelegate {
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
    
    func updateAddOnsTicketPrice(ticket: [UpSellTicket]) {
        if isPaymentInitiated { return }
        if selectedAddOnsItem.count == 0 { return }
        var upSellTickets = [UpSellTicket]()
        ticket.forEach({ tick in
            upSellTickets = selectedAddOnsItem.filter({ $0.id == tick.id})
        })
        if upSellTickets.count != 0 {
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

extension CheckOutClipVC: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
//        isChangingFlag = false
    }
}

extension UITextField {
    func shake() {
        let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shakeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        shakeAnimation.duration = 0.5
        shakeAnimation.values = [-10, 10, -8, 8, -5, 5, -2, 2, 0]
        layer.add(shakeAnimation, forKey: "shake")
    }
}
