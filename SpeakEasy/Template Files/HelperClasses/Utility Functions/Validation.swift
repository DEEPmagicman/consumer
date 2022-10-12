import Foundation
import UIKit
import PhoneNumberKit

//MARK: AppHelperUtility setup
@objc class Validation: NSObject{
    static let shared = Validation()
    fileprivate override init() {}
}
extension Validation {
    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    func isValidPasswordLength(_ value:String) -> Bool {
        return value.count > 5 ? true : false
    }
    func isValidPassword(_ value:String) -> Bool {
        let pwdRegEx = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$"
        
        let pwdTest = NSPredicate(format:"SELF MATCHES %@", pwdRegEx)
        return pwdTest.evaluate(with: value)
    }
    func isValidName(_ value: String) -> Bool {
        if value.count > 2{
            return true
        }
        return false
    }
    func isValidNumber(_ value: String) -> Bool {
        guard let _ = Double(value) else {return false}
        return true
    }
    func isValidPhoneNumber(_ value: String)->Bool{
        let phoneNumberKit = PhoneNumberKit()
        do {
            let _ = try phoneNumberKit.parse(value).countryCode
            return true
        }
        catch {
            return false
        }
    }
    func isConfirmPasswordIsEqualToPassword(password: String, confirm: String) -> Bool {
        if(password == confirm){
            return true
        }
        return false
    }
    func validateStringLength(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return !trimmed.isEmpty
    }
    func validateDouble(_ text: String) -> Bool {
        if let _ = Double(text){
            return true
        }
        else{
            return false
        }
    }
    func validateDiscount(_ text: String) -> Bool {
        if let discount = Double(text){
            return (discount > 0) && (discount < 100)
        }
        else{
            return false
        }
    }
}
