
import Foundation
import UIKit

extension UITextField{
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSAttributedString.Key.foregroundColor: newValue!])
        }
    }
}

extension UITextField {
    func validatedText(validationType: ValidatorType) throws -> String {
        let validator = VaildatorFactory.validatorFor(type: validationType)
        return try validator.validated(self.text!)
    }
    func validatedPasswordComparision(validationType: ValidatorType, oldPassword: String, newPassword: String, ConfirmPassword: String) throws -> String {
        let validator = VaildatorFactory.validatorFor(type: validationType)
        return try validator.validated(oldPassword: oldPassword, newPassword: newPassword, confirmPassword: ConfirmPassword)
    }
}
