//
//  TableRequestVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 05/01/26.
//

import UIKit

struct RequestFormPayload {
    let date: String
    let time: String
    let partySize: String
    let comments: String
    let marketingOptIn: Bool
}

class TableRequestVC: UIViewController {
    
    @IBOutlet weak var requestFormView: UIView!
    
    var event: Event?
    
    // MARK: - Fields
    private var dateField: UITextField!
    private var timeField: UITextField!
    private var partyField: UITextField!
    private var commentTextView: UITextView!
    private var requestButton: UIButton!
    private var marketingCheckbox: UIButton!
    
    // MARK: - Pickers
    private let reservationDatePicker = UIDatePicker()
    private let arrivalTimePicker = UIDatePicker()
    
    // MARK: - Selected Values
    private var selectedReservationDate: Date?
    private var selectedArrivalTime: Date?
    
    private let commentPlaceholder = "Questions and comments"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRequestForm()
        setupPickers()
    }
}

// MARK: - UI Setup
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
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        let title = UILabel()
        title.text = "Your request"
        title.font = AppFont.font(.inter, weight: .medium, size: 12)
        title.textAlignment = .center
        title.textColor = .black
        stack.addArrangedSubview(title)
        
        stack.addArrangedSubview(makeInputField(icon: "calendar", placeholder: "Reservation date *", field: &dateField))
        stack.addArrangedSubview(makeInputField(icon: "clock", placeholder: "Arrival time *", field: &timeField))
        stack.addArrangedSubview(makeInputField(icon: "ic_outline-people", placeholder: "Party size *", field: &partyField))
        
        stack.addArrangedSubview(makeCommentBox())
        stack.addArrangedSubview(makeCheckboxSection())
        
        let sep = UIView()
        sep.backgroundColor = UIColor(hex: "#A1A1A1").withAlphaComponent(0.5)
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stack.addArrangedSubview(sep)
        
        stack.addArrangedSubview(makeRequestButton())
    }
    
    func makeInputField(
        icon: String,
        placeholder: String,
        field: inout UITextField!
    ) -> UIView {
        
        let iconView = UIImageView(image: UIImage(named: icon))
        iconView.tintColor = .black
        iconView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        iconView.contentMode = .scaleAspectFit
        
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(hex: "#A1A1A1"),
                .font: AppFont.font(.inter, weight: .medium, size: 14)
            ]
        )
        tf.font = AppFont.font(.inter, weight: .medium, size: 14)
        tf.textColor = .black
        tf.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        field = tf
        
        let hStack = UIStackView(arrangedSubviews: [iconView, tf])
        hStack.axis = .horizontal
        hStack.spacing = 13
        hStack.alignment = .center
        
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

// MARK: - Pickers
extension TableRequestVC {
    
    func setupPickers() {
        
        reservationDatePicker.datePickerMode = .date
        reservationDatePicker.preferredDatePickerStyle = .wheels
        reservationDatePicker.minimumDate = Date()
        reservationDatePicker.addTarget(self, action: #selector(handleReservationDateChanged), for: .valueChanged)
        
        arrivalTimePicker.datePickerMode = .time
        arrivalTimePicker.preferredDatePickerStyle = .wheels
        arrivalTimePicker.addTarget(self, action: #selector(handleArrivalTimeChanged), for: .valueChanged)
        
        dateField.inputView = reservationDatePicker
        timeField.inputView = arrivalTimePicker
        
        dateField.inputAccessoryView = makeToolbar(selector: #selector(doneTapped))
        timeField.inputAccessoryView = makeToolbar(selector: #selector(doneTapped))
        
        dateField.tintColor = .clear
        timeField.tintColor = .clear
    }
    
    func makeToolbar(selector: Selector) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        
        toolbar.items = [flex, done]
        return toolbar
    }
    
    @objc func doneTapped() {
        view.endEditing(true)
    }
    
    @objc func handleReservationDateChanged() {
        selectedReservationDate = reservationDatePicker.date
        dateField.text = formattedDisplayDate(reservationDatePicker.date)
        updateRequestButtonState()
    }
    
    @objc func handleArrivalTimeChanged() {
        selectedArrivalTime = arrivalTimePicker.date
        timeField.text = formattedDisplayTime(arrivalTimePicker.date)
        updateRequestButtonState()
    }
    
    func formattedDisplayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    func formattedDisplayTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    func formattedAPIDateTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    func combineDateAndTime(date: Date, time: Date) -> Date? {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = timeComponents.second ?? 0
        
        return calendar.date(from: combined)
    }
}

// MARK: - Comment Box
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
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        tv.textContainer.lineFragmentPadding = 0
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

// MARK: - Checkbox
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
        label.textColor = UIColor(hex: "#3D3A3A")
        label.font = AppFont.font(.inter, weight: .regular, size: 12)
        label.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [marketingCheckbox, label])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .top
        return stack
    }
    
    @objc func toggleCheckbox() {
        marketingCheckbox.isSelected.toggle()
    }
}

// MARK: - Button State
extension TableRequestVC {
    
    func makeRequestButton() -> UIButton {
        
        let btn = UIButton(type: .system)
        btn.setTitle("REQUEST", for: .normal)
        btn.titleLabel?.font = AppFont.font(.inter, weight: .semibold, size: 12)
        btn.layer.cornerRadius = 20
        btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        btn.addTarget(self, action: #selector(onRequestTapped), for: .touchUpInside)
        
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
        requestButton.backgroundColor = valid ? .black : .lightGray
        requestButton.setTitleColor(.white, for: .normal)
    }
}

// MARK: - Actions
extension TableRequestVC {
    
    private func suitablePresenter() -> UIViewController {
        if let parent = parent {
            return parent
        }
        if let navigationController = navigationController {
            return navigationController
        }
        return self
    }
    
    @objc func onRequestTapped() {
        
        guard UserDefault.shared.user != nil else {
            
            let loginVC = Navigate.to.loginPopUpVc(suitablePresenter())
            
            loginVC.onContinueToVerify = { [weak self] otp, otpRef, phone, countryCode, _, _ in
                guard let self = self else { return }
                
                Navigate.to.enterVerificationCodeVc(
                    self.suitablePresenter(),
                    isFromLogin: true,
                    otp: otp,
                    otpRef: otpRef,
                    phoneNum: phone,
                    countryCode: countryCode
                ) { [weak self] in
                    self?.onRequestTapped()
                }
            }
            
            return
        }
        
        guard
            let reservationDate = selectedReservationDate,
            let arrivalTime = selectedArrivalTime,
            let combinedDateTime = combineDateAndTime(date: reservationDate, time: arrivalTime)
        else {
            print("❌ Invalid reservation date/time")
            return
        }
        
        let comments = commentTextView.text == commentPlaceholder ? "" : (commentTextView.text ?? "")
        let apiDateTime = formattedAPIDateTime(from: combinedDateTime)
        
        let payload = RequestFormPayload(
            date: apiDateTime,
            time: apiDateTime,
            partySize: partyField.text ?? "",
            comments: comments,
            marketingOptIn: marketingCheckbox.isSelected
        )
        
        callReservationAPI(payload)
    }
}

extension TableRequestVC {
    
    func callReservationAPI(_ payload: RequestFormPayload) {
        
        guard let user = UserDefault.shared.user else { return }
        
        let firstName = user.firstName
        let lastName = user.lastName
        let email = user.email
        let dob = user.dateOfBirth
        
        let guests = Int(payload.partySize) ?? 0
        
        TablePresenter.createReservationRequest(
            firstName: firstName,
            lastName: lastName,
            email: email,
            totalGuests: guests,
            note: payload.comments,
            dob: dob,
            date: payload.date,
            time: payload.time,
            optedPolicy: payload.marketingOptIn,
            eventId: event?.id ?? "",
            seatingArea: nil,
            venueId: event?.venue?.id ?? "",
            token: UserDefault.shared.accessToken ?? ""
        ) { success, message, _ in
            
            DispatchQueue.main.async {
                if success {
                    print("✅ Reservation success")
                } else {
                    print("❌ Reservation failed:", message ?? "")
                }
            }
        }
    }
}
