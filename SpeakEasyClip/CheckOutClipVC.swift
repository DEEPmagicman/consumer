//
//  CheckOutClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit
import PassKit
import StripeApplePay
import FlagPhoneNumber

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
    @IBOutlet private weak var errorLbl: UILabel!
    @IBOutlet private weak var applePayBtn: PKPaymentButton!
    @IBOutlet private weak var dressCodeInfoLbl: UILabel!
    @IBOutlet private weak var policyCheckBox: UIButton!
    @IBOutlet private weak var policyView: UIView!
    @IBOutlet private weak var policyLbl: UILabel!

    var totalPrice = 1
    var venue: ClipVenue?
    var selectedAppClipTickets = [AppClipTicket]()
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

    override func viewDidLoad() {
        super.viewDidLoad()
        WebSocketWrapper.shared.delegate.append(self)
        
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        
        applePayBtn.alpha = 0.5
        applePayBtn.isUserInteractionEnabled = false

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

        dressCodeInfoLbl.highlightBold(["\"All entry subject to doorman discretion\"."], size: 14, textColor: UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1))
        totalPriceLbl.text = "$\(totalPrice)"
        applePayBtn.addTarget(self, action: #selector(applePayButtonTapped), for: .touchUpInside)
        if PKPaymentAuthorizationViewController.canMakePayments() {
            errorLbl.text = "Add Card to your Apple wallet & try again."
            NotificationCenter.default.addObserver(self, selector: #selector(checkApplePay), name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(checkApplePay), name: UIApplication.didBecomeActiveNotification, object: nil)
        } else {
            isApplePayNotSupported = true
            errorLbl.text = "Apple pay is not supported on your device, use main app to book ticket."
        }
        policyCheckBox.setImage(CommonConstant.Icon.checkBoxEmpty, for: .normal)
        policyCheckBox.setImage(CommonConstant.Icon.checkBoxFull, for: .selected)
        policyView.isHidden = !(venue?.venueSettings?.optedPolicy == true)
        policyLbl.text = venue?.venueSettings?.policyText ?? "Opt in for future messages"
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
    
    @objc private func dismissCountries() {
        isChangingFlag = false
        listController.dismiss(animated: true, completion: nil)
    }
    
    @objc func checkApplePay() {
        if isValidNo == false { return }
        if StripeAPI.deviceSupportsApplePay() {
            if isIntendCreated { return }
            createBooking()
            applePayBtn.isHidden = false
            errorLbl.isHidden = true
            applePayBtn.alpha = 0.5
            applePayBtn.isUserInteractionEnabled = false
        } else if isApplePayNotSupported == false {
            alertForWallet()
            setUpPaymentBtn()
            applePayBtn.alpha = 0.5
            applePayBtn.isUserInteractionEnabled = false
        } else {
            applePayBtn.isHidden = true
            errorLbl.isHidden = false
        }
    }
    
    private func addPaymentApi() {
        if isIntendCreated { return }
        guard let url = URL(string: "https://api.speakeasygo.com/consumer/payment/\(bookingId)") else { return }
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
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")
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
    
    func paymentStatus(_ status: PaymentStatus, completion: @escaping (()-> Void)) {
        guard let url = URL(string: "https://api.speakeasygo.com/consumer/payment/\(paymentHistoryId)/\(bookingId)/status?status=\(status.rawValue)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        var param = [String: Any]()
        if venue?.venueSettings?.optedPolicy == true {
            param["optedPolicy"] = policyCheckBox.isSelected
        }
        let bodyData = try? JSONSerialization.data(
            withJSONObject: param,
            options: [.prettyPrinted]
        )
        request.httpBody = bodyData
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
            AppClipLoader.showLoader(view)
            paymentStatus(.SUCCESS) { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "QRCodeClipVC")) as? QRCodeClipVC {
                        AppClipLoader.hideLoader()
                        vc.venueName = self.venue?.name ?? ""
                        vc.bookingId = self.bookingId
                        vc.venueLogo = self.venue?.logo?.key ?? ""
                        vc.venueAttachment = self.venue?.venueAttachment.first?.key ?? ""
                        vc.selectedAppClipTickets = self.selectedAppClipTickets
                        if let selectVC = self.navigationController?.viewControllers.first(where: { $0.isKind(of: SelectTicketClipVC.self) }) {
                            self.navigationController?.viewControllers = [selectVC, vc]
                        }
                    }
                }
            }
        case .error:
            isPaymentInitiated = false
            alertPopup("Alert", "Payment field")
        case .userCancellation:
            isPaymentInitiated = false
//            alertPopup("Alert", "Payment interrupted")
        @unknown default:
            fatalError()
        }
    }

    func createBooking() {
        AppClipLoader.showLoader(self.view)
        var selectedTickets = [[String: Any]]()
        selectedAppClipTickets.forEach {
            selectedTickets.append(["ticketId": $0.id,
                                   "ticketQuantity": $0.selectedQuantity ?? 0])
        }
        let param = ["appclipTicket": selectedTickets,
                     "venueId": UserDefaults.standard.value(forKey: "venueIdLong") as? String ?? "",
                     "phone": "\(phoneNumTextField.text?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "") ?? "")"] as [String: Any]
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
        
        guard let userURL = URL(string: "https://api.speakeasygo.com/appclip-user") else { return }
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
                self.addPaymentApi()
            } else if let booking = json["booking"] as? [String: Any], let bookingId = booking["id"] as? String {
                self.bookingId = bookingId
                self.addPaymentApi()
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
}

extension CheckOutClipVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       selectedAppClipTickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        cell.titleLbl.text = selectedAppClipTickets[indexPath.row].name
        cell.subTitleLbl.text = selectedAppClipTickets[indexPath.row].description
        cell.quantityLbl.text = "\(selectedAppClipTickets[indexPath.row].selectedQuantity ?? 0)x"
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
        applePayBtn.alpha = 0.5
        applePayBtn.isUserInteractionEnabled = false
        if isChangingFlag { return }
        if isValidNo {
            checkApplePay()
        } else {
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
                alertPopup("Update", "Venue your trying to booking, updated it's price") {
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
