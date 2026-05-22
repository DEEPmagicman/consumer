//
//  GlobalTextFieldHandler.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 22/05/26.
//

import UIKit

final class GlobalTextFieldHandler: NSObject {

    static let shared = GlobalTextFieldHandler()

    private override init() {}

    func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTextFieldDidBeginEditing(_:)),
            name: UITextField.textDidBeginEditingNotification,
            object: nil
        )
    }

    @objc private func handleTextFieldDidBeginEditing(_ notification: Notification) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.handleTextFieldDidBeginEditing(notification)
            }
            return
        }

        guard let textField = notification.object as? UITextField else { return }

        if textField.returnKeyType == .default {
            textField.returnKeyType = .done
        }

        textField.removeTarget(
            self,
            action: #selector(doneFromReturnKey(_:)),
            for: .editingDidEndOnExit
        )

        textField.addTarget(
            self,
            action: #selector(doneFromReturnKey(_:)),
            for: .editingDidEndOnExit
        )

//        addToolbarIfNeeded(to: textField)
    }

    private func addToolbarIfNeeded(to textField: UITextField) {
        switch textField.keyboardType {
        case .numberPad, .phonePad, .decimalPad:
            if textField.inputAccessoryView != nil { return }

            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            toolbar.isTranslucent = true

            let flex = UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil
            )

            let done = UIBarButtonItem(
                title: "Done",
                style: .done,
                target: self,
                action: #selector(doneFromToolbar)
            )

            toolbar.items = [flex, done]
            textField.inputAccessoryView = toolbar

        default:
            break
        }
    }

    @objc private func doneFromReturnKey(_ textField: UITextField) {
        textField.resignFirstResponder()
    }

    @objc private func doneFromToolbar() {
        keyWindow?.endEditing(true)
    }

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
