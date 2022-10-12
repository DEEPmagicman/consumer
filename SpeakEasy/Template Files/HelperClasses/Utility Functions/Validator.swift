
import Foundation

class ValidationError: Error {
    var message: String
    
    init(_ message: String) {
        self.message = message
    }
}

protocol ValidatorConvertible {
     func validated(_ value: String) throws -> String
     func validated(oldPassword: String, newPassword: String, confirmPassword: String) throws -> String
}
extension ValidatorConvertible {
    func validated(oldPassword: String, newPassword: String, confirmPassword: String) throws -> String{
       return ""
    }
}

enum ValidatorType {
    case firstName
    case lastName
    case email
    case emptyPassword
    case password
    case requiredField(field: String)
    case passwordComparision
}
enum ValidatorTypeCustom {
    case passwordComparison
}
enum VaildatorFactory {
    static func validatorFor(type: ValidatorType) -> ValidatorConvertible {
        switch type {
        case .firstName: return FirstNameValidator()
        case .lastName: return LastNameValidator()
        case .email: return EmailValidator()
        case .password: return PasswordValidator()
        case .emptyPassword: return EmptyPasswordValidator()
        case .requiredField(let fieldName): return RequiredFieldValidator(fieldName)
        case .passwordComparision: return PasswordComparisionValidator()
        }
    }
}
struct RequiredFieldValidator: ValidatorConvertible {
    private let fieldName: String
    
    init(_ field: String) {
        fieldName = field
    }
    
    func validated(_ value: String) throws -> String {
        guard !value.isEmpty else {
            throw ValidationError("Required field " + fieldName)
        }
        return value
    }
}
struct FirstNameValidator: ValidatorConvertible {
    func validated(_ value: String) throws -> String {
        guard value.count >= 3 else {
            throw ValidationError(Strings.INVALID_F_NAME.text)
        }
        return value
    }
}
struct LastNameValidator: ValidatorConvertible {
    func validated(_ value: String) throws -> String {
        guard value.count >= 3 else {
            throw ValidationError(Strings.INVALID_L_NAME.text)
        }
        return value
    }
}
struct EmptyPasswordValidator: ValidatorConvertible {
    func validated(_ value: String) throws -> String {
        guard value.count > 0 else {
            throw ValidationError(Strings.EMPTY_PWD.text)
        }
        return value
    }
}
struct PasswordValidator: ValidatorConvertible {
    func validated(_ value: String) throws -> String {
        guard value != "" else {throw ValidationError(Strings.EMPTY_PWD.text)}
        guard value.count >= 8 else { throw ValidationError(Strings.INVALID_PWD.text) }
        return value
    }
}
struct PasswordComparisionValidator: ValidatorConvertible {
    func validated(_ value: String) throws -> String {
        return ""
    }
    func validated(oldPassword: String, newPassword: String, confirmPassword: String) throws -> String {
        guard oldPassword != "" else {throw ValidationError(Strings.EMPTY_PWD.text)}
        guard newPassword != "" else {throw ValidationError(Strings.EMPTY_PWD.text)}
        guard oldPassword != newPassword else {throw ValidationError(Strings.OLD_PWD_AND_NEW_PWD.text)}
        guard newPassword == confirmPassword else {throw ValidationError(Strings.PWD_DONT_MATCH.text)}
        return ""
    }
    
}
struct EmailValidator: ValidatorConvertible {
    func validated(_ value: String) throws -> String {
        guard value != "" else {throw ValidationError(Strings.EMPTY_EMAIL_ADDRESS.text)}
        do {
            if try NSRegularExpression(pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$", options: .caseInsensitive).firstMatch(in: value, options: [], range: NSRange(location: 0, length: value.count)) == nil {
                throw ValidationError(Strings.INVALID_EMAIL.text)
            }
        } catch {
            throw ValidationError(Strings.INVALID_EMAIL.text)
        }
        return value
    }
}
