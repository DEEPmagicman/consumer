//
//  PremiumInquiryCardView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 19/06/26.
//

import UIKit

final class PremiumInquiryCardView: UIView {

    // MARK: Public

    var event: Event?
    var seatingAreas: [SeatingArea] = []
    var onRequestSuccess: (() -> Void)?

    // MARK: UI

    private let descriptionLabel  = UILabel()
    private let cardView          = GradientBorderCardView()
    private let titleLabel        = UILabel()
    private let stackView         = UIStackView()

    private let dateField         = PremiumTextField()
    private let timeField         = PremiumTextField()
    private let partySizeRow      = PartySizeFieldRow()
    private let dseField          = PremiumTextView()
    private let commentView       = PremiumTextView()

    private let checkboxView      = PremiumCheckboxView()
    private let sendButton        = PrimaryButton()

    // MARK: Picker

    private let datePicker        = UIDatePicker()
    private let timePicker        = UIDatePicker()

    // MARK: Data

    private var selectedDate: Date?
    private var selectedTime: Date?
    private var selectedPartySize = 0

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.glassCornerRadius = 28
    }
}

// MARK: - Setup

private extension PremiumInquiryCardView {

    func setupUI() {
        backgroundColor = .clear
        setupDescription()
        setupCard()
        setupTitle()
        setupStack()
        setupFields()
        setupCheckbox()
        setupButton()
        setupConstraints()
    }

    func setupDescription() {
        descriptionLabel.text =
            "Please complete the form to submit your request and a VIP Services Host will contact you. This request form is not a table reservation confirmation and does not guarantee entry."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font          = Constant.Font.geistRegular(size: 11)
        descriptionLabel.textColor     = .white.withAlphaComponent(0.9)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(descriptionLabel)
    }

    func setupCard() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.fillColor = AppColor.primaryWhiteColor.withAlphaComponent(0.05).cgColor
        cardView.showsBlur = true
        cardView.blurAlpha = 0.60
        addSubview(cardView)
    }

    func setupTitle() {
        titleLabel.text      = "Your request"
        titleLabel.font      = Constant.Font.geistMedium(size: 20)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
    }

    func setupStack() {
        stackView.axis    = .vertical
        stackView.spacing = 9
        stackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stackView)
    }
}

// MARK: - Fields

private extension PremiumInquiryCardView {

    func setupFields() {
        setupDateField()
        setupTimeField()
        setupPartySizeRow()
        setupDSEField()
        setupCommentView()

        stackView.addArrangedSubview(dateField)
        stackView.addArrangedSubview(timeField)
        stackView.addArrangedSubview(partySizeRow)
        stackView.addArrangedSubview(dseField)
        stackView.addArrangedSubview(commentView)
    }

    func setupDateField() {
        dateField.title     = "Reservation date"
        dateField.leftImage = UIImage(resource: .calendarIcon)

        // Date field is display-only — low alpha, no interaction
        dateField.textField.tintColor        = .clear
        dateField.textField.isUserInteractionEnabled = false
        dateField.alpha = 0.7
        dseField.viewCornerRadius = 14

        datePicker.datePickerMode         = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate            = Date()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
    }

    func setupTimeField() {
        timeField.title     = "Arrival time"
        timeField.leftImage = UIImage(resource: .clockIcon)

        timeField.textField.tintColor     = .clear
        timeField.textField.inputView     = timePicker
        timeField.textField.inputAccessoryView = toolbar(action: #selector(doneTapped))
        timeField.viewCornerRadius = 14
        
        // Make entire row tappable
        let tap = UITapGestureRecognizer(target: self, action: #selector(openTimePicker))
        timeField.addGestureRecognizer(tap)
        timeField.isUserInteractionEnabled = true

        timePicker.datePickerMode          = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.addTarget(self, action: #selector(timeChanged), for: .valueChanged)
    }

    func setupPartySizeRow() {
        partySizeRow.onValueChanged = { [weak self] value in
            guard let self else { return }
            self.selectedPartySize = value
            self.updateButtonState()
        }
        partySizeRow.viewCornerRadius = 14
    }

    func setupDSEField() {
        dseField.placeholder = "dse"
        dseField.translatesAutoresizingMaskIntoConstraints = false
        dseField.heightAnchor.constraint(equalToConstant: 52).isActive = true
        dseField.viewCornerRadius = 14
    }

    func setupCommentView() {
        commentView.placeholder = "Questions and comments"
        commentView.translatesAutoresizingMaskIntoConstraints = false
        commentView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        commentView.viewCornerRadius = 14
    }
}

// MARK: - Checkbox

private extension PremiumInquiryCardView {

    func setupCheckbox() {
        checkboxView.labelText =
            "I agree to receive marketing related text messages from E11EVEN. Msg & data rates may apply. Reply STOP to opt out or HELP for support."
        checkboxView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(checkboxView)
    }
}

// MARK: - Button

private extension PremiumInquiryCardView {

    func setupButton() {
        sendButton.configure(title: "Send request", fontSize: 16, cornerRadius: 26)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(onRequest), for: .touchUpInside)
        cardView.addSubview(sendButton)
        updateButtonState()
    }
}

// MARK: - Constraints

private extension PremiumInquiryCardView {

    func setupConstraints() {
        NSLayoutConstraint.activate([

            descriptionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            cardView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 22),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 22),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -22),

            checkboxView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            checkboxView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            checkboxView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            sendButton.topAnchor.constraint(equalTo: checkboxView.bottomAnchor, constant: 24),
            sendButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            sendButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: 52),
            sendButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24)
        ])
    }
}

// MARK: - Actions

private extension PremiumInquiryCardView {

    @objc func doneTapped() {
        endEditing(true)
    }

    @objc func openTimePicker() {
        timeField.textField.becomeFirstResponder()
    }

    @objc func dateChanged() {
        selectedDate    = datePicker.date
        dateField.text  = formattedDisplayDate(datePicker.date)
        updateButtonState()
    }

    @objc func timeChanged() {
        selectedTime    = timePicker.date
        timeField.text  = formattedDisplayTime(timePicker.date)
        updateButtonState()
    }

}

// MARK: - UITextViewDelegate (dse field change tracking)

extension PremiumInquiryCardView: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        updateButtonState()
    }
}

// MARK: - Toolbar

private extension PremiumInquiryCardView {

    func toolbar(action: Selector) -> UIToolbar {
        let tb = UIToolbar()
        tb.sizeToFit()
        tb.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: action)
        ]
        return tb
    }
}

// MARK: - Button State

private extension PremiumInquiryCardView {

    func updateButtonState() {
        let dseText = dseField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let enabled =
            !(timeField.text?.isEmpty ?? true) &&
            selectedPartySize > 0 &&
            !dseText.isEmpty

        sendButton.isUserInteractionEnabled = enabled
        UIView.animate(withDuration: 0.2) {
            self.sendButton.alpha = enabled ? 1.0 : 0.7
        }
    }
}

// MARK: - Public

extension PremiumInquiryCardView {

    func configure() {
        configureTextsFromSettings()
        configureDefaultDateTime()
        configurePartySize()
        updateButtonState()
    }
}

private extension PremiumInquiryCardView {

    func configureTextsFromSettings() {
        let settings = event?.venue?.venueSettings
        let venueName = event?.venue?.name ?? "the venue"
        let fallbackInformation =
            "Please complete the form to submit your request and a VIP Services Host will contact you. This request form is not a table reservation confirmation and does not guarantee entry."
        let fallbackPolicy =
            "I agree to receive marketing related text messages from \(venueName). Msg & data rates may apply. Reply STOP to opt out or HELP for support."

        let information = cleanHTMLText(settings?.tableBookingImportantInformation ?? "")
        descriptionLabel.text = information.isEmpty ? fallbackInformation : information

        titleLabel.text = "Reservation request"

        let requestPolicy = cleanHTMLText(settings?.reservationRequestPolicy ?? "")
        let marketingPolicy = cleanHTMLText(settings?.policyText ?? "")
        checkboxView.labelText = requestPolicy.isEmpty
            ? (marketingPolicy.isEmpty ? fallbackPolicy : marketingPolicy)
            : requestPolicy
    }

    func configureDefaultDateTime() {
        guard
            let dateString = event?.startDateTime,
            let eventDate  = dateString.dateFormatter(formate: .yyyyMMddHHmmss, isUTC: true)
        else { return }

        selectedDate = eventDate
        selectedTime = eventDate

        datePicker.date = eventDate
        timePicker.date = eventDate

        dateField.text = formattedDisplayDate(eventDate)
        timeField.text = formattedDisplayTime(eventDate)

        // Date is locked — already set alpha 0.45 + isUserInteractionEnabled false above
    }

    func configurePartySize() {
        let maxGuest = seatingAreas.compactMap { $0.maxGuest }.max() ?? 100
        partySizeRow.configure(max: maxGuest)
    }

    func cleanHTMLText(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
              ) else {
            return text
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return attributed.string
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Request

private extension PremiumInquiryCardView {

    @objc func onRequest() {
        guard UserDefault.shared.isLoggedIn ?? false else {
            Navigate.to.openPhoneLoginPopup(
                Utility.main.topViewController() ?? UIViewController()
            )
            return
        }
        guard validateUserProfile() else { return }
        createRequest()
    }

    func createRequest() {
        guard
            let reservationDate = selectedDate,
            let arrivalTime     = selectedTime,
            let date            = combineDateAndTime(date: reservationDate, time: arrivalTime)
        else { return }

        let payload = RequestFormPayload(
            date:            formattedAPIDateTime(from: date),
            time:            formattedAPIDateTime(from: date),
            partySize:       "\(selectedPartySize)",
            comments:        commentView.text,
            marketingOptIn:  checkboxView.isChecked
        )

        callReservationAPI(payload)
    }

    func combineDateAndTime(date: Date, time: Date) -> Date? {
        let cal          = Calendar.current
        let dateParts    = cal.dateComponents([.year, .month, .day], from: date)
        let timeParts    = cal.dateComponents([.hour, .minute, .second], from: time)
        var combined     = DateComponents()
        combined.year    = dateParts.year
        combined.month   = dateParts.month
        combined.day     = dateParts.day
        combined.hour    = timeParts.hour
        combined.minute  = timeParts.minute
        combined.second  = timeParts.second ?? 0
        return cal.date(from: combined)
    }
}

private extension PremiumInquiryCardView {

    func callReservationAPI(_ payload: RequestFormPayload) {
        guard
            let user  = UserDefault.shared.user,
            let event
        else { return }

        let guests = Int(payload.partySize) ?? 1

        sendButton.isUserInteractionEnabled = false
        sendButton.startLoading()
        TablePresenter.createReservationRequest(
            firstName:   user.firstName,
            lastName:    user.lastName,
            email:       user.email,
            totalGuests: guests,
            note:        payload.comments,
            dob:         user.dateOfBirth,
            date:        payload.date,
            time:        payload.time,
            optedPolicy: payload.marketingOptIn,
            eventId:     event.id ?? "",
            seatingArea: nil,
            venueId:     event.venue?.id ?? "",
            token:       UserDefault.shared.accessToken ?? ""
        ) { [weak self] success, message, _ in
            self?.sendButton.stopLoading()
            
            guard let self else { return }
            DispatchQueue.main.async {
                self.sendButton.isUserInteractionEnabled = true
                if success {
                    self.resetForm()
                    self.onRequestSuccess?()
                } else {
                    Alert.showToast(message ?? Constant.String.somethingWrong)
                }
            }
        }
    }

    func resetForm() {
        selectedPartySize = 0
        partySizeRow.configure(max: seatingAreas.compactMap { $0.maxGuest }.max() ?? 100)
        dseField.text    = ""
        commentView.text = ""
        checkboxView.isChecked = false
        configureDefaultDateTime()
        updateButtonState()
    }
}

// MARK: - Validation

private extension PremiumInquiryCardView {

    func validateUserProfile() -> Bool {
        guard let user = UserDefault.shared.user else { return false }
        let valid = !user.firstName.isEmpty && !user.email.isEmpty && !user.dateOfBirth.isEmpty
        if !valid { showProfileIncompleteAlert() }
        return valid
    }

    func showProfileIncompleteAlert() {
        guard let vc = Utility.main.topViewController() else { return }
        let alert = UIAlertController(
            title:   "Incomplete Profile",
            message: "Please complete your profile before sending a request.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Go to Profile", style: .default) { _ in
            Navigate.to.profileVC(vc)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        vc.present(alert, animated: true)
    }
}

// MARK: - Date Helpers

private extension PremiumInquiryCardView {
    func formattedDisplayDate(_ date: Date) -> String {
        let formate         = DateFormatter()
        formate.dateFormat   = "MM/dd/yyyy"
        formate.timeZone     = TimeZone(identifier: event?.venue?.useTimezone ?? TimeZone.current.identifier)
        return formate.string(from: date)
    }

    func formattedDisplayTime(_ date: Date) -> String {
        let formate          = DateFormatter()
        formate.dateFormat   = "hh:mm a"
        formate.timeZone     = TimeZone(identifier: event?.venue?.useTimezone ?? TimeZone.current.identifier)
        return formate.string(from: date)
    }

    func formattedAPIDateTime(from date: Date) -> String {
        let formate          = DateFormatter()
        formate.dateFormat   = "yyyy-MM-dd HH:mm:ss"
        formate.locale       = Locale(identifier: "en_US_POSIX")
        return formate.string(from: date)
    }
}
