//
//  EnterPhoneNumberClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 25/01/23.
//

import UIKit
import FlagPhoneNumber
import DropDown

final class EnterPhoneNumberClipVC: UIViewController {
    
    @IBOutlet private weak var ticketTypeLbl: UILabel!
    @IBOutlet private weak var ticketPriceLbl: UILabel!
    @IBOutlet private weak var countryCodeTextField: FPNTextField!
    @IBOutlet private weak var continueBtn: UIButton!
    @IBOutlet private weak var phoneNumTextField: UITextField!
    @IBOutlet private weak var countrySelectionView: UIView!
    @IBOutlet private weak var continueBtnBottom: NSLayoutConstraint!
    @IBOutlet private weak var ticketNumberView: UIView!
    @IBOutlet private weak var ticketNumberLbl: UILabel!
    
    private var checkFPNField = FPNTextField()
    private var countryCode = ""
    private var listController: FPNCountryListViewController = FPNCountryListViewController(style: .grouped)
    private let numberDropDown = DropDown()
    var ticketPrice = 0
    var isGeneralAdmission = false
    var venueName = ""
    var appClipTicketId = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        ticketTypeLbl.text = isGeneralAdmission ? "General Admission" : "VIP Skip the Line"
        ticketPriceLbl.text = "$\(ticketPrice)"
        
        ticketNumberView.layer.borderColor = UIColor(red: 63/255, green: 63/255, blue: 63/255, alpha: 1).cgColor
        ticketNumberView.layer.borderWidth = 1
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickCountrySelect))
        countrySelectionView.addGestureRecognizer(tap)
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onClickDropDown))
        ticketNumberView.addGestureRecognizer(tap1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func onClickDropDown() {
        ticketNumberSelection()
        numberDropDown.show()
    }
    
    private func ticketNumberSelection() {
        numberDropDown.anchorView = ticketNumberView
        numberDropDown.bottomOffset = CGPoint(x: 0, y: ticketNumberView.bounds.height - 8)
        numberDropDown.cellHeight = 40
        numberDropDown.selectionBackgroundColor = .clear
        numberDropDown.cornerRadius = 10
        numberDropDown.textColor = .white
        numberDropDown.shadowOpacity = 0
        numberDropDown.backgroundColor = .darkGray
        numberDropDown.dataSource = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
        numberDropDown.width = ticketNumberView.bounds.width
        numberDropDown.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) in
            cell.optionLabel.textAlignment = .center
        }
        numberDropDown.selectionAction = { [weak self] _, item in
            self?.ticketNumberLbl.text = item
        }
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        let keyboardSize = (notification.userInfo?  [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardHeight = keyboardSize?.height ?? 336
        if #available(iOS 11.0, *) {
            continueBtnBottom.constant = keyboardHeight - view.safeAreaInsets.bottom + 10
        } else {
            continueBtnBottom.constant = view.safeAreaInsets.bottom + 10
        }
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        continueBtnBottom.constant =  77
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func getCustomTextFieldInputAccessoryView(with items: [UIBarButtonItem]) -> UIToolbar {
        let toolbar: UIToolbar = UIToolbar()
        
        toolbar.barStyle = UIBarStyle.default
        toolbar.items = items
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    @objc private func onClickCountrySelect() {
        fpnDisplayCountryList()
    }
    
    @objc private func dismissCountries() {
        listController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func onClickContinue(_ sender: Any) {
        phoneNumTextField.resignFirstResponder()
        createBooking()
    }
    
    func createBooking() {
        AppClipLoader.showLoader(self.view)
        let parameters = "{\n  \"phone\": \"\(phoneNumTextField.text?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "") ?? "")\",\n  \"appclipTicketId\": \"\(appClipTicketId)\",\n  \"ticketQuantity\": \(Int(ticketNumberLbl.text ?? "") ?? 1)\n}"
        let postData = parameters.data(using: .utf8)
        
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
                self.navigate(bookingId: bookingId)
            } else if let booking = json["booking"] as? [String: Any], let bookingId = booking["id"] as? String {
                self.navigate(bookingId: bookingId)
            } else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Booking failed")
            }
        }
        task.resume()
    }
    
    func navigate(bookingId: String) {
        DispatchQueue.main.async {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "CheckOutClipVC")) as? CheckOutClipVC {
                AppClipLoader.hideLoader()
                vc.phoneNo = self.phoneNumTextField.text?.replacingOccurrences(of: " ", with: "") ?? ""
                vc.totalTicket = Int(self.ticketNumberLbl.text ?? "") ?? 1
                vc.ticketPrice = self.ticketPrice
                vc.isGeneralAdmission = self.isGeneralAdmission
                vc.venueName = self.venueName
                vc.bookingId = bookingId
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

extension EnterPhoneNumberClipVC: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        checkFPNField.text = textField.text
        checkFPNField.sendActions(for: .editingChanged)
        phoneNumTextField.delegate = nil
        phoneNumTextField.text = checkFPNField.text
        phoneNumTextField.delegate = self
    }
}

extension EnterPhoneNumberClipVC: FPNTextFieldDelegate {
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
            if isValid {
                continueBtn.isUserInteractionEnabled = true
                continueBtn.alpha = 1
            } else {
                continueBtn.isUserInteractionEnabled = false
                continueBtn.alpha = 0.5
            }
        }
    }
}
