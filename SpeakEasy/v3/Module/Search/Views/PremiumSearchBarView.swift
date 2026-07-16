//
//  PremiumSearchBarView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 16/06/26.
//

import UIKit

final class PremiumSearchBarView: UIControl {

    // MARK: - Callbacks

    var onTap: (() -> Void)?
    var onClear: (() -> Void)?
    var onTextChanged: ((String) -> Void)?

    // MARK: - UI

    private let glassView = LiquidGlassBackgroundView(
        cornerRadius: 18,
        fillColor: UIColor.white.withAlphaComponent(0.06),
        borderColor: UIColor.white.withAlphaComponent(0.18),
        borderWidth: 0.8
    )

    private let searchIconView = UIImageView()
    private let textField = UITextField()
    private let clearButton = UIButton(type: .system)

    // MARK: -

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(glassView)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        
        searchIconView.translatesAutoresizingMaskIntoConstraints = false
        searchIconView.image = UIImage(resource: .searchIconV3)
        searchIconView.tintColor = UIColor.white.withAlphaComponent(0.85)
        searchIconView.contentMode = .scaleAspectFit
        addSubview(searchIconView)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.tintColor = .white
        textField.textColor = .white
        textField.font = Constant.Font.geistMedium(size: 14)
        textField.returnKeyType = .search
        textField.delegate = self
        
        textField.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.55),
                .font: Constant.Font.geistMedium(size: 14)
            ]
        )
        
        textField.addTarget(
            self,
            action: #selector(textChanged),
            for: .editingChanged
        )
        
        addSubview(textField)
        
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.setImage(
            UIImage(resource: .searchCrossIcon),
            for: .normal
        )
        clearButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        clearButton.isHidden = true
        
        clearButton.addTarget(
            self,
            action: #selector(clearPressed),
            for: .touchUpInside
        )
        
        addSubview(clearButton)
        
        NSLayoutConstraint.activate([

            heightAnchor.constraint(equalToConstant: 36),

            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),

            searchIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            searchIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchIconView.widthAnchor.constraint(equalToConstant: 16),
            searchIconView.heightAnchor.constraint(equalToConstant: 16),

            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 15),
            clearButton.heightAnchor.constraint(equalToConstant: 15),

            textField.leadingAnchor.constraint(equalTo: searchIconView.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -6),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 22)
        ])

        addTarget(
            self,
            action: #selector(beginSearch),
            for: .touchUpInside
        )
    }

    // MARK: - Public

    var text: String {
        textField.text ?? ""
    }

    func setText(_ text: String) {
        textField.text = text
        clearButton.isHidden = text.isEmpty
    }

    func clear() {
        textField.text = ""
        clearButton.isHidden = true
    }

    func focus() {
        textField.becomeFirstResponder()
    }

    func resign() {
        textField.resignFirstResponder()
    }

    // MARK: - Actions

    @objc
    private func beginSearch() {

        AppHaptic.tap()
        textField.becomeFirstResponder()
        onTap?()
    }

    @objc
    private func clearPressed() {

        textField.text = ""
        clearButton.isHidden = true

        AppHaptic.tap()
        onClear?()
    }

    @objc
    private func textChanged() {

        clearButton.isHidden = (textField.text ?? "").isEmpty
        onTextChanged?(textField.text ?? "")
    }
}

// MARK: - UITextFieldDelegate

extension PremiumSearchBarView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        textField.resignFirstResponder()
        AppHaptic.selectionChanged()
        onTap?()

        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onTap?()
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {

        clear()

        onClear?()

        return false
    }
}
