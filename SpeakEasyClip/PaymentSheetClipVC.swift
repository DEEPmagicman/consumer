//
//  PaymentSheetClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 15/08/23.
//

import UIKit

protocol CardPaymentDelegate: AnyObject {
    func paymentSuccess()
}

final class PaymentSheetClipVC: UIViewController {

    @IBOutlet weak var cardInfoView: UIView!
    @IBOutlet weak var cardNumberTF: UITextField!
    @IBOutlet weak var cardTypeLbl: UILabel!
    @IBOutlet weak var dateTF: UITextField!
    @IBOutlet weak var cvcTF: UITextField!    
    @IBOutlet weak var payBtn: LoadingButton!
    
    var bookingId = ""
    var totalPrice = 0
    var currencySymbol = "$"
    weak var delegate: CardPaymentDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        cardInfoView.layer.borderColor = UIColor.darkGray.cgColor
        cardInfoView.layer.borderWidth = 1
        cardNumberTF.addTarget(self, action: #selector(numberDidChange), for: .editingChanged)
        cardNumberTF.delegate = self
        dateTF.delegate = self
        cvcTF.delegate = self
        payBtn.setTitle("Pay \(currencySymbol)\(String(format: "%.2f", Double(totalPrice)))", for: .normal)
        cardNumberTF.addNextButtonKeyboard(superViewCount: 2)
        dateTF.addNextButtonKeyboard(superViewCount: 3)
        cvcTF.addDoneButtonKeyboard()
    }
    
    private func updatePayBtn() {
        DispatchQueue.main.async {
            if self.cardNumberTF.text?.count ?? 0 > 4, self.dateTF.text?.count == 5, self.cvcTF.text?.count ?? 0 >= 3 {
                self.payBtn.isUserInteractionEnabled = true
                self.payBtn.alpha = 1
            } else {
                self.payBtn.isUserInteractionEnabled = false
                self.payBtn.alpha = 0.5
            }
        }
    }
    
    @objc func numberDidChange() {
        if cardNumberTF.text ?? "" != checkCardNumber(input: cardNumberTF.text ?? "").formatted {
            cardNumberTF.text = checkCardNumber(input: cardNumberTF.text ?? "").formatted
        }
        if checkCardNumber(input: cardNumberTF.text ?? "").type == .Unknown {
            cardTypeLbl.text = ""
        } else {
            cardTypeLbl.text = checkCardNumber(input: cardNumberTF.text ?? "").type.rawValue
        }
        updatePayBtn()
    }
    
    func matchesRegex(regex: String!, text: String!) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [.caseInsensitive])
            let nsString = text as NSString
            let match = regex.firstMatch(in: text, options: [], range: NSMakeRange(0, nsString.length))
            return (match != nil)
        } catch {
            return false
        }
    }
    
    func luhnCheck(number: String) -> Bool {
        var sum = 0
        
        let digitStrings = number.reversed().map { String($0) }
        
        for tuple in digitStrings.enumerated() {
            guard let digit = Int(tuple.element) else { return false }
            let odd = tuple.offset % 2 == 1
            
            switch (odd, digit) {
            case (true, 9):
                sum += 9
            case (true, 0...8):
                sum += (digit * 2) % 9
            default:
                sum += digit
            }
        }
        
        return sum % 10 == 0
    }
    
    func checkCardNumber(input: String) -> (type: CardType, formatted: String, valid: Bool) {
        // Get only numbers from the input string
        let numberOnly =  input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        var type: CardType = .Unknown
        var formatted = ""
        var valid = false
        
        // detect card type
        for card in CardType.allCards {
            if (matchesRegex(regex: card.regex, text: numberOnly)) {
                type = card
                break
            }
        }
        
        // check validity
        valid = luhnCheck(number: numberOnly)
        
        // format
        var formatted4 = ""
        for character in numberOnly {
            if formatted4.count == 4 {
                formatted += formatted4 + " "
                formatted4 = ""
            }
            formatted4.append(character)
        }
        
        formatted += formatted4 // the rest
        
        // return the tuple
        return (type, formatted, valid)
    }

    @IBAction func onClickBack(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func onClickPay(_ sender: Any) {
        payBtn.showLoading()
        AppClipLoader.showLoader(self.view)
        guard let url = URL(string: "https://api.speakeasygo.com/appclip/payment") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let param = ["bookingId": bookingId,
                     "number": cardNumberTF.text?.replacingOccurrences(of: " ", with: "") ?? "",
                     "exp_month": Int(dateTF.text?.prefix(2) ?? "") ?? 0,
                     "exp_year": Int(dateTF.text?.dropFirst(3) ?? "") ?? 0,
                     "cvc": cvcTF.text ?? ""] as [String: Any]
        let bodyData = try? JSONSerialization.data(
            withJSONObject: param,
            options: [.prettyPrinted]
        )
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = bodyData
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let self = self else { return }
            guard let data = data else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Something went wrong")
                self.payBtn.hideLoading()
                return
            }
            guard let success = String(data: data, encoding: .utf8).flatMap(Bool.init), success == true else {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let errMsg = json["message"] as? String {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", errMsg)
                } else {
                    AppClipLoader.hideLoader()
                    self.alertPopup("Alert", "Something went wrong")
                }
                self.payBtn.hideLoading()
                return
            }
            AppClipLoader.hideLoader()
            self.delegate?.paymentSuccess()
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        })
        task.resume()
    }
}

enum CardType: String {
    case Unknown, Amex, Visa, MasterCard, Diners, Discover, JCB, Elo, Hipercard, UnionPay
    
    static let allCards = [Amex, Visa, MasterCard, Diners, Discover, JCB, Elo, Hipercard, UnionPay]
    
    var regex : String {
        switch self {
        case .Amex:
            return "^3[47][0-9]{5,}$"
        case .Visa:
            return "^4[0-9]{6,}([0-9]{3})?$"
        case .MasterCard:
            return "^(5[1-5][0-9]{4}|677189)[0-9]{5,}$"
        case .Diners:
            return "^3(?:0[0-5]|[68][0-9])[0-9]{4,}$"
        case .Discover:
            return "^6(?:011|5[0-9]{2})[0-9]{3,}$"
        case .JCB:
            return "^(?:2131|1800|35[0-9]{3})[0-9]{3,}$"
        case .UnionPay:
            return "^(62|88)[0-9]{5,}$"
        case .Hipercard:
            return "^(606282|3841)[0-9]{5,}$"
        case .Elo:
            return "^((((636368)|(438935)|(504175)|(451416)|(636297))[0-9]{0,10})|((5067)|(4576)|(4011))[0-9]{0,12})$"
        default:
            return ""
        }
    }
}

extension PaymentSheetClipVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // NOTE: only allow number entry
        let aSet = NSCharacterSet(charactersIn: "0123456789").inverted
        let compSepByCharInSet = string.components(separatedBy: aSet)
        let numberFiltered = compSepByCharInSet.joined(separator: "")
        
        switch textField {
        case cardNumberTF:
            // NOTE: card number can have a length of 13 to 19 digits, American Express is 15 digits
            let maxLength = 24 // (19 max digits + 4 spaces + 1 extra)
            let currentString = (textField.text ?? "") as NSString
            let newString = currentString.replacingCharacters(in: range, with: string)
            
            return newString.count <= maxLength && string == numberFiltered
        case cvcTF:
            // NOTE: CSV length can't be more than 4
            let maxLength = 4
            let currentString = (textField.text ?? "") as NSString
            let newString = currentString.replacingCharacters(in: range, with: string)
            
            return newString.count <= maxLength && string == numberFiltered
        case dateTF:
            // NOTE: MM/YY length can't be more than 5
            let maxLength = 5
            let currentString = (textField.text ?? "") as NSString
            let newString = currentString.replacingCharacters(in: range, with: string)
            
            return newString.count <= maxLength && string == numberFiltered
        default:
            return string == numberFiltered
        }
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        switch textField {
        case dateTF:
            if dateTF.text?.last == "/" {
                dateTF.text?.removeLast()
                return
            }
            if dateTF.text?.count ?? 0 <= 2 && Int(dateTF.text?.prefix(2) ?? "") ?? 10 < 10 && (2..<10).contains(Int(dateTF.text?.prefix(1) ?? "") ?? 10) {
                dateTF.delegate = nil
                dateTF.text = "0\(dateTF.text?.prefix(1) ?? "")/"
                dateTF.delegate = self
            }
            if dateTF.text?.count ?? 0 > 2, dateTF.text?.contains("/") == false {
                if let last = dateTF.text?.removeLast(), let month = dateTF.text {
                    dateTF.delegate = nil
                    dateTF.text = "\(month)/\(last)"
                    dateTF.delegate = self
                }
            }
            if dateTF.text?.count == 5 {
                cvcTF.becomeFirstResponder()
            }
        default:
            break
        }
        updatePayBtn()
    }
}
