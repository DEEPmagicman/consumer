//
//  TableRequestVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 05/01/26.
//

import UIKit
import MHLoadingButton

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
    private var requestButton: LoadingButton!
    private var marketingCheckbox: UIButton!
    
    // MARK: - Pickers
    private let reservationDatePicker = UIDatePicker()
    private let arrivalTimePicker = UIDatePicker()
    
    // MARK: - Selected Values
    private var selectedReservationDate: Date?
    private var selectedArrivalTime: Date?
    
    private let commentPlaceholder = "Questions and comments"
    private var isRequestInProgress = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRequestForm()
        setupPickers()
        setDefaultEventDateTime()
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
        if placeholder == "Party size *" {
            tf.keyboardType = .numberPad
            tf.inputAccessoryView = makeToolbar(selector: #selector(doneTapped))
        }
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
    
    func validateUserProfile() -> Bool {
        
        guard let user = UserDefault.shared.user else { return false }
        
        if (user.firstName.isEmpty) ||
            (user.email.isEmpty) ||
            (user.dateOfBirth.isEmpty) {
            
            showProfileIncompleteAlert()
            return false
        }
        
        return true
    }
    
    func showProfileIncompleteAlert() {
        let alert = UIAlertController(
            title: "Incomplete Profile",
            message: "Please add your name, email and date of birth in profile.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Go to Profile", style: .default, handler: { _ in
            Navigate.to.profileVC(self)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
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
    
    func getEventDate() -> Date? {
        
        guard let dateString = event?.startDateTime else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return formatter.date(from: dateString)
    }
    
    func setDefaultEventDateTime() {
        
        guard let eventDate = getEventDate() else { return }
        
        // ✅ DATE (LOCKED)
        selectedReservationDate = eventDate
        reservationDatePicker.date = eventDate
        dateField.text = formattedDisplayDate(eventDate)
        dateField.isUserInteractionEnabled = false
        
        // ✅ TIME (EDITABLE)
        selectedArrivalTime = eventDate
        arrivalTimePicker.date = eventDate
        timeField.text = formattedDisplayTime(eventDate)
        
        updateRequestButtonState()
    }
    
    func formattedDisplayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if let timezone = event?.venue?.useTimezone,
           let tz = TimeZone(identifier: timezone) {
            formatter.timeZone = tz
        }

        return formatter.string(from: date)
    }
    
    func formattedDisplayTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if let timezone = event?.venue?.useTimezone,
           let tz = TimeZone(identifier: timezone) {
            formatter.timeZone = tz
        }

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
    
    func showSuccessView() {
        requestFormView.isHidden = true
        requestButton.isHidden = true
        
        let successView = UIView()
        successView.backgroundColor = .black
        successView.translatesAutoresizingMaskIntoConstraints = false
        
        let title = UILabel()
        title.text = "Request Sent"
        title.textColor = .white
        title.font = UIFont.boldSystemFont(ofSize: 20)
        title.textAlignment = .center
        
        let desc = UILabel()
        desc.text = "Your request has been sent successfully. Our team will contact you."
        desc.textColor = .lightGray
        desc.font = UIFont.systemFont(ofSize: 14)
        desc.numberOfLines = 0
        desc.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [title, desc])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        successView.addSubview(stack)
        view.addSubview(successView)
        
        NSLayoutConstraint.activate([
            successView.topAnchor.constraint(equalTo: view.topAnchor),
            successView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            successView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            successView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            stack.centerXAnchor.constraint(equalTo: successView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: successView.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: successView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: successView.trailingAnchor, constant: -20)
        ])
    }
    
    func showError(_ message: String?) {
        let alert = UIAlertController(
            title: "Error",
            message: message ?? "Something went wrong",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Button State
extension TableRequestVC {
    
    func makeRequestButton() -> UIView {

        let container = UIView()
        container.backgroundColor = .black
        container.layer.cornerRadius = 20
        container.clipsToBounds = true
        container.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let btn = LoadingButton(type: .system)
        btn.setTitle("REQUEST", for: .normal)
        btn.titleLabel?.font = AppFont.font(.inter, weight: .semibold, size: 12)
        btn.setTitleColor(.white, for: .normal)

        btn.indicator = MaterialLoadingIndicator(color: .white)
        btn.bgColor = .clear

        btn.addTarget(self, action: #selector(onRequestTapped), for: .touchUpInside)

        btn.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(btn)

        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: container.topAnchor),
            btn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            btn.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        requestButton = btn
        updateRequestButtonState()

        return container
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
        
        if isRequestInProgress { return }
        
        guard UserDefault.shared.user != nil else { return }
        guard validateUserProfile() else { return }
        
        guard
            let reservationDate = selectedReservationDate,
            let arrivalTime = selectedArrivalTime,
            let combinedDateTime = combineDateAndTime(date: reservationDate, time: arrivalTime)
        else { return }
        
        isRequestInProgress = true
        requestButton.setTitle("", for: .normal)
        requestButton.showLoader(userInteraction: false)
        
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
                
                self.isRequestInProgress = false
                self.requestButton.hideLoader()
                self.requestButton.setTitle("REQUEST", for: .normal)
                if success {
                    self.showSuccessView()
                } else {
                    self.showError(message)
                }
            }
        }
    }
}
