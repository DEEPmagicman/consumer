//
//  TableRequestVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 05/01/26.
//

struct RequestFormPayload {
    let date: String
    let time: String
    let partySize: String
    let comments: String
    let marketingOptIn: Bool
}

import UIKit

class TableRequestVC: UIViewController {
    
    @IBOutlet weak var requestFormView: UIView!
    
    // MARK: - Fields
    private var dateField: UITextField!
    private var timeField: UITextField!
    private var partyField: UITextField!
    private var commentTextView: UITextView!
    private var requestButton: UIButton!
    private var marketingCheckbox: UIButton!
    
    private let commentPlaceholder = "Questions and comments"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRequestForm()
    }
}

extension TableRequestVC {

    func setupRequestForm() {

        let scrollView = UIScrollView()
        let contentView = UIView()

        requestFormView.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: requestFormView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: requestFormView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: requestFormView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: requestFormView.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10

        contentView.addSubview(stack)
        contentView.layer.cornerRadius = 10
        contentView.backgroundColor = .white
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])

        // Title
        let title = UILabel()
        title.text = "Your request"
        title.font = AppFont.font(.inter, weight: .medium, size: 10)
        title.textAlignment = .center
        title.textColor = .black
        stack.addArrangedSubview(title)

        // Fields
        stack.addArrangedSubview(makeInputField(icon: "calendar", placeholder: "Reservation date *", field: &dateField))
        stack.addArrangedSubview(makeInputField(icon: "clock", placeholder: "Arrival time *", field: &timeField))
        stack.addArrangedSubview(makeInputField(icon: "person.2", placeholder: "Party size *", field: &partyField))

        // Comment box
        stack.addArrangedSubview(makeCommentBox())

        // Checkbox
        stack.addArrangedSubview(makeCheckboxSection())

        // Separator
        let sep = UIView()
        sep.backgroundColor = UIColor(hex: "#A1A1A1").withAlphaComponent(0.5)
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stack.addArrangedSubview(sep)

        // Button
        stack.addArrangedSubview(makeRequestButton())
    }
}

extension TableRequestVC {

    func makeInputField(
        icon: String,
        placeholder: String,
        field: inout UITextField!
    ) -> UIView {

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .black
        iconView.widthAnchor.constraint(equalToConstant: 18).isActive = true

        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = AppFont.font(.inter, weight: .medium, size: 14)
        tf.textColor = .black
        tf.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        field = tf

        let hStack = UIStackView(arrangedSubviews: [iconView, tf])
        hStack.axis = .horizontal
        hStack.spacing = 13

        let container = UIView()
        container.layer.borderWidth = 0.5
        container.layer.borderColor = UIColor(hex: "#3D3A3A").cgColor
        container.layer.cornerRadius = 6

        container.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        return container
    }
}

extension TableRequestVC: UITextViewDelegate {

    func makeCommentBox() -> UITextView {

        let tv = UITextView()
        tv.delegate = self
        tv.backgroundColor = .clear
        tv.text = commentPlaceholder
        tv.textColor = UIColor(hex: "#A1A1A1")
        tv.font = AppFont.font(.inter, weight: .medium, size: 14)
        tv.layer.borderWidth = 0.5
        tv.layer.borderColor = UIColor(hex: "#3D3A3A").cgColor
        tv.layer.cornerRadius = 6
        tv.heightAnchor.constraint(equalToConstant: 80).isActive = true

        commentTextView = tv
        return tv
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == commentPlaceholder {
            textView.text = ""
            textView.textColor = .black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = commentPlaceholder
            textView.textColor = UIColor(hex: "#A1A1A1")
        }
    }
}

extension TableRequestVC {

    func makeCheckboxSection() -> UIView {

        marketingCheckbox = UIButton(type: .custom)
        marketingCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
        marketingCheckbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        marketingCheckbox.tintColor = .black
        marketingCheckbox.widthAnchor.constraint(equalToConstant: 20).isActive = true
        marketingCheckbox.addTarget(self, action: #selector(toggleCheckbox), for: .touchUpInside)

        let label = UILabel()
        label.text = "I agree to receive marketing related text messages from E11EVEN. Msg & data rates may apply. Reply STOP to opt out or HELP for support."
        label.textColor = .black
        label.font = AppFont.font(.inter, weight: .regular, size: 12)
        label.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [marketingCheckbox, label])
        stack.axis = .horizontal
        stack.spacing = 10
        return stack
    }

    @objc func toggleCheckbox() {
        marketingCheckbox.isSelected.toggle()
    }
}

extension TableRequestVC {

    func makeRequestButton() -> UIButton {

        let btn = UIButton(type: .system)
        btn.setTitle("REQUEST", for: .normal)
        btn.titleLabel?.font = AppFont.font(.inter, weight: .semibold, size: 12)
        btn.layer.cornerRadius = 20
        btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        btn.addTarget(self, action: #selector(onRequestTapped), for: .touchUpInside)

        requestButton.backgroundColor = .black
        requestButton = btn
        updateRequestButtonState()
        return btn
    }

    @objc func textFieldChanged() {
        updateRequestButtonState()
    }

    func updateRequestButtonState() {

        let valid =
            !(dateField.text?.isEmpty ?? true) &&
            !(timeField.text?.isEmpty ?? true) &&
            !(partyField.text?.isEmpty ?? true)

        requestButton.isEnabled = valid
        requestButton.backgroundColor = .black
        requestButton.setTitleColor(.white, for: .normal)
    }
}

extension TableRequestVC {

    @objc func onRequestTapped() {

        let comments =
            commentTextView.text == commentPlaceholder
            ? ""
            : commentTextView.text

        let payload = RequestFormPayload(
            date: dateField.text!,
            time: timeField.text!,
            partySize: partyField.text!,
            comments: comments ?? "",
            marketingOptIn: marketingCheckbox.isSelected
        )

        print("API PAYLOAD 👉", payload)
        // call API here
    }
}
