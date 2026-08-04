//
//  FloatingInputView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 19/05/26.
//

import UIKit

final class FloatingInputView: UIControl {

    let textField = UITextField()

    private let titleLabel = UILabel()

    private var valueTopConstraint: NSLayoutConstraint!
    private var valueCenterConstraint: NSLayoutConstraint!

    var title: String {
        didSet {
            titleLabel.text = title
            updateState()
        }
    }

    var emptyValuePlaceholder: String? {
        didSet {
            updateState()
        }
    }

    var text: String? {
        get { textField.text }
        set {
            textField.text = cleanText(newValue)
            updateState()
        }
    }

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        self.title = ""
        super.init(coder: coder)
        setup()
    }

    private func setup() {

        backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.05)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.35)
        titleLabel.font = Constant.Font.geistRegular(size: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        textField.backgroundColor = .clear
        textField.textColor = AppColor.primaryWhiteColor
        textField.tintColor = AppColor.primaryWhiteColor
        textField.font = Constant.Font.geistRegular(size: 18)
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)

        valueTopConstraint = textField.topAnchor.constraint(equalTo: topAnchor, constant: 38)

        valueCenterConstraint = textField.centerYAnchor.constraint(equalTo: centerYAnchor)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 26),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),

            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 26),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 28)
        ])

        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        updateState()
    }

    @objc private func textChanged() {
        updateState()
        clearError()
    }

    private func updateState() {

        let value = cleanText(textField.text) ?? ""
        let placeholder = cleanText(emptyValuePlaceholder)
        let state = DisplayState(
            hasValue: !value.isEmpty,
            emptyValuePlaceholder: placeholder
        )

        textField.text = value

        titleLabel.isHidden = !state.showsTitle

        valueTopConstraint.isActive = state.usesFloatingValuePosition
        valueCenterConstraint.isActive = !state.usesFloatingValuePosition

        if state.hasValue {

            textField.attributedPlaceholder = nil

        } else {

            textField.attributedPlaceholder = NSAttributedString(
                string: state.placeholderText(fallback: title),
                attributes: [
                    .foregroundColor: AppColor.primaryWhiteColor.withAlphaComponent(0.35),
                    .font: Constant.Font.geistRegular(size: 18)
                ]
            )
        }
    }

    private struct DisplayState {
        let hasValue: Bool
        let emptyValuePlaceholder: String?

        var showsTitle: Bool {
            hasValue || emptyValuePlaceholder != nil
        }

        var usesFloatingValuePosition: Bool {
            hasValue || emptyValuePlaceholder != nil
        }

        func placeholderText(fallback: String) -> String {
            emptyValuePlaceholder ?? fallback
        }
    }

    private func cleanText(_ text: String?) -> String? {

        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if value.isEmpty || value == "No date Found" {
            return nil
        }

        return value
    }

    func showError() {
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemRed.cgColor
        shake()
    }

    func clearError() {
        layer.borderWidth = 0
        layer.borderColor = UIColor.clear.cgColor
    }
}
