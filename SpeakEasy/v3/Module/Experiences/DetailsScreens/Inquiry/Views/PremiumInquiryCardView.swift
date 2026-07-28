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
    private let tableService = TableService()

    // MARK: UI

    private let descriptionLabel  = UILabel()
    private let cardView          = GradientBorderCardView()
    private let titleLabel        = UILabel()
    private let stackView         = UIStackView()

    private let dateField         = PremiumTextField()
    private let timeField         = PremiumTextField()
    private let partySizeRow      = PartySizeFieldRow()
    private let commentView       = PremiumTextView()
    private let questionSectionView = UIView()
    private let questionStackView   = UIStackView()

    private let policyStackView   = UIStackView()
    private let checkboxView      = PremiumCheckboxView()
    private let emailCheckboxView = PremiumCheckboxView()
    private let sendButton        = PrimaryButton()
    private var questionSectionCollapsedHeightConstraint: NSLayoutConstraint?
    private var policyStackCollapsedHeightConstraint: NSLayoutConstraint?
    private var sendButtonTopConstraint: NSLayoutConstraint?

    // MARK: Picker

    private let datePicker        = UIDatePicker()
    private let timePicker        = UIDatePicker()

    // MARK: Data

    private var selectedDate: Date?
    private var selectedTime: Date?
    private var selectedPartySize = 0
    private var selectedMenCount = 0
    private var selectedWomenCount = 0
    private var reservationQuestions: [Questions] = []
    private var questionAnswers: [String: Any] = [:]
    private var questionViews: [PremiumRequestQuestionView] = []
    private var loadedQuestionsEventId: String?

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
        setupCheckbox()
        setupFields()
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
        setupCommentView()
        setupQuestionSection()

        stackView.addArrangedSubview(dateField)
        stackView.addArrangedSubview(timeField)
        stackView.addArrangedSubview(partySizeRow)
        stackView.addArrangedSubview(questionSectionView)
        stackView.addArrangedSubview(commentView)
    }

    func setupDateField() {
        dateField.title     = "Reservation date"
        dateField.isRequired = true
        dateField.leftImage = UIImage(resource: .calendarIcon)

        // Date field is display-only — low alpha, no interaction
        dateField.textField.tintColor        = .clear
        dateField.textField.isUserInteractionEnabled = false
        dateField.alpha = 0.7

        datePicker.datePickerMode         = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate            = Date()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
    }

    func setupTimeField() {
        timeField.title     = "Arrival time"
        timeField.isRequired = true
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
        timePicker.minuteInterval = 15
        timePicker.addTarget(self, action: #selector(timeChanged), for: .valueChanged)
    }

    func setupPartySizeRow() {
        partySizeRow.isRequired = true
        partySizeRow.onValueChanged = { [weak self] value in
            guard let self else { return }
            self.selectedPartySize = value
            self.updateButtonState()
        }
        partySizeRow.onGenderValueChanged = { [weak self] men, women in
            self?.selectedMenCount = men
            self?.selectedWomenCount = women
        }
        partySizeRow.viewCornerRadius = 14
    }

    func setupCommentView() {
        commentView.placeholder = "Questions and comments"
        commentView.translatesAutoresizingMaskIntoConstraints = false
        commentView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        commentView.viewCornerRadius = 14
    }

    func setupQuestionSection() {
        questionSectionView.translatesAutoresizingMaskIntoConstraints = false
        questionSectionView.isHidden = true
        questionSectionCollapsedHeightConstraint = questionSectionView.heightAnchor.constraint(equalToConstant: 0)
        questionSectionCollapsedHeightConstraint?.priority = .required
        questionSectionCollapsedHeightConstraint?.isActive = true

        questionStackView.axis = .vertical
        questionStackView.spacing = 10
        questionStackView.translatesAutoresizingMaskIntoConstraints = false
        questionSectionView.addSubview(questionStackView)

        let bottomConstraint = questionStackView.bottomAnchor.constraint(equalTo: questionSectionView.bottomAnchor)
        bottomConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            questionStackView.topAnchor.constraint(equalTo: questionSectionView.topAnchor),
            questionStackView.leadingAnchor.constraint(equalTo: questionSectionView.leadingAnchor),
            questionStackView.trailingAnchor.constraint(equalTo: questionSectionView.trailingAnchor),
            bottomConstraint
        ])
    }
}

// MARK: - Checkbox

private extension PremiumInquiryCardView {

    func setupCheckbox() {
        policyStackView.axis = .vertical
        policyStackView.spacing = 14
        policyStackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(policyStackView)
        policyStackCollapsedHeightConstraint = policyStackView.heightAnchor.constraint(equalToConstant: 0)
        policyStackCollapsedHeightConstraint?.priority = .required

        checkboxView.labelText =
            "I agree to receive marketing related text messages from E11EVEN. Msg & data rates may apply. Reply STOP to opt out or HELP for support."
        checkboxView.supportsExpansion = true
        checkboxView.isChecked = true
        checkboxView.onToggle = { [weak self] _ in
            self?.updateButtonState()
        }
        checkboxView.onExpansionChanged = { [weak self] in
            self?.updatePolicySectionLayout()
        }

        emailCheckboxView.supportsExpansion = true
        emailCheckboxView.isChecked = true
        emailCheckboxView.onToggle = { [weak self] _ in
            self?.updateButtonState()
        }
        emailCheckboxView.onExpansionChanged = { [weak self] in
            self?.updatePolicySectionLayout()
        }

        policyStackView.addArrangedSubview(emailCheckboxView)
        policyStackView.addArrangedSubview(checkboxView)
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
        sendButtonTopConstraint = sendButton.topAnchor.constraint(equalTo: policyStackView.bottomAnchor, constant: 24)

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

            policyStackView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            policyStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            policyStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            sendButtonTopConstraint!,
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

// MARK: - UITextViewDelegate

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
        let enabled =
            !(timeField.text?.isEmpty ?? true) &&
            selectedPartySize > 0

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
        fetchReservationQuestionsIfNeeded()
        updateButtonState()
    }
}

private extension PremiumInquiryCardView {

    func configureTextsFromSettings() {
        let settings = event?.venue?.venueSettings
        let venueName = event?.displayVenueNameOrFallback("the partner") ?? "the partner"
        let fallbackInformation =
            "Please complete the form to submit your request and a VIP Services Host will contact you. This request form is not a table reservation confirmation and does not guarantee entry."
        let fallbackPolicy =
            "I agree to receive marketing related text messages from \(venueName). Msg & data rates may apply. Reply STOP to opt out or HELP for support."

        let widgetFormHTML = settings?.reservationWidgetSettings?.isReservationRequestFormTextEnabled == true
            ? settings?.reservationWidgetSettings?.reservationRequestFormText ?? ""
            : ""
        let customNoteHTML = settings?.customNoteOnReservationManagementPage ?? ""
        let tableImportantInfoHTML = settings?.tableBookingImportantInformation ?? ""
        let informationHTML = !cleanHTMLText(widgetFormHTML).isEmpty
            ? widgetFormHTML
            : (!cleanHTMLText(customNoteHTML).isEmpty ? customNoteHTML : tableImportantInfoHTML)
        setDescriptionText(informationHTML, fallback: fallbackInformation)

//        titleLabel.text = "Reservation request"

        var marketingPolicy = cleanHTMLText(settings?.policyText ?? "")
        if settings?.optedPolicy == true, marketingPolicy.isEmpty {
            marketingPolicy = fallbackPolicy
        }

        let fallbackEmailPolicy = "I agree to receive marketing related email messages from \(venueName)."
        var emailPolicy = cleanHTMLText(settings?.emailPolicyText ?? "")
        if settings?.optedEmailPolicy == true, emailPolicy.isEmpty {
            emailPolicy = fallbackEmailPolicy
        }

        checkboxView.labelText = marketingPolicy
        checkboxView.isChecked = true
        checkboxView.isHidden = settings?.optedPolicy != true || marketingPolicy.isEmpty

        emailCheckboxView.labelText = emailPolicy
        emailCheckboxView.isChecked = true
        emailCheckboxView.isHidden = emailPolicy.isEmpty
        updatePolicySectionVisibility()
    }

    func configureDefaultDateTime() {
        guard
            let dateString = event?.startDateTime,
            let eventDate  = dateString.dateFormatter(formate: .yyyyMMddHHmmss, isUTC: true)
        else { return }

        let timezone = venueTimeZone()
        datePicker.timeZone = timezone
        timePicker.timeZone = timezone
        timePicker.minimumDate = eventDate
        if
            let endDateString = event?.endDateTime,
            let endDate = endDateString.dateFormatter(formate: .yyyyMMddHHmmss, isUTC: true),
            endDate > eventDate
        {
            timePicker.maximumDate = endDate
        } else {
            timePicker.maximumDate = nil
        }

        datePicker.date = eventDate
        timePicker.setDate(eventDate, animated: false)

        selectedDate = eventDate
        selectedTime = timePicker.date

        dateField.text = formattedDisplayDate(eventDate)
        timeField.text = formattedDisplayTime(timePicker.date)

        // Date is locked — already set alpha 0.45 + isUserInteractionEnabled false above
    }

    func configurePartySize() {
        let maxGuest = event?.eventSettings?.guestCount ?? event?.venue?.venueSettings?.reservationWidgetSettings?.guestCount ?? seatingAreas.compactMap { $0.maxGuest }.max() ?? 100
        selectedPartySize = 0
        selectedMenCount = 0
        selectedWomenCount = 0
        partySizeRow.configure(max: maxGuest, showsGenderCounts: isGuestListByGenderEnabled)
    }

    func cleanHTMLText(_ text: String) -> String {
        text.htmlPlainText()
    }

    func setDescriptionText(_ htmlText: String, fallback: String) {
        let cleanedText = cleanHTMLText(htmlText)
        guard !cleanedText.isEmpty else {
            descriptionLabel.attributedText = nil
            descriptionLabel.text = fallback
            return
        }

        descriptionLabel.attributedText = htmlText.htmlAttributedString(
            fontSize: 11,
            textColor: UIColor.white.withAlphaComponent(0.9),
            regularFont: Constant.Font.geistRegular(size: 11),
            boldFont: Constant.Font.geistMedium(size: 11),
            lineSpacing: 3,
            paragraphSpacing: 6
        ) ?? NSAttributedString(
            string: cleanedText,
            attributes: [
                .font: Constant.Font.geistRegular(size: 11),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
        )
    }
}

// MARK: - Request

private extension PremiumInquiryCardView {

    @objc func onRequest() {
        guard LoginRequiredCoordinator.isAuthenticated else {
            guard let presenter = Utility.main.topViewController() else { return }
            LoginRequiredCoordinator.presentLogin(from: presenter) { [weak self] in
                self?.onRequest()
            }
            return
        }

        guard validateUserProfile() else { return }
        guard validatePolicyAcceptance() else { return }
        guard validateQuestionAnswers() else { return }
        createRequest()
    }

    func createRequest() {
        guard
            let reservationDate = selectedDate,
            let arrivalTime = selectedTime,
            let reservationDateTime = combineDateAndTime(date: reservationDate, time: reservationDate),
            let arrivalDateTime = combineDateAndTime(date: reservationDate, time: arrivalTime)
        else { return }

        let payload = RequestFormPayload(
            date: formattedUTCDateTime(from: reservationDateTime),
            time: formattedUTCDateTime(from: arrivalDateTime),
            partySize: "\(selectedPartySize)",
            comments: commentView.text,
            marketingOptIn: areVisiblePoliciesAccepted()
        )

        callReservationAPI(payload)
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
        tableService.createReservationRequest(
            firstName: user.firstName,
            lastName: user.lastName,
            email: user.email,
            totalGuests: guests,
            note: payload.comments,
            dob: user.dateOfBirth,
            date: payload.date,
            time: payload.time,
            optedPolicy: payload.marketingOptIn,
            eventId: event.id ?? "",
            seatingArea: nil,
            venueId: event.venue?.id ?? "",
            token: UserDefault.shared.accessToken ?? "",
            optedEmailPolicy: emailCheckboxView.isHidden || emailCheckboxView.isChecked,
            maleGuests: isGuestListByGenderEnabled ? selectedMenCount : nil,
            femaleGuests: isGuestListByGenderEnabled ? selectedWomenCount : nil,
            answers: reservationQuestionAnswersPayload()
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
        selectedMenCount = 0
        selectedWomenCount = 0
        configurePartySize()
        commentView.text = ""
        checkboxView.isChecked = true
        emailCheckboxView.isChecked = true
        questionAnswers.removeAll()
        reloadQuestionViews()
        configureDefaultDateTime()
        updateButtonState()
    }
}

// MARK: - Reservation Questions

private extension PremiumInquiryCardView {

    func fetchReservationQuestionsIfNeeded() {
        guard let eventId = event?.id, !eventId.isEmpty else {
            reservationQuestions = []
            questionAnswers.removeAll()
            loadedQuestionsEventId = nil
            reloadQuestionViews()
            updateQuestionSectionVisibility()
            return
        }

        guard loadedQuestionsEventId != eventId else {
            updateQuestionSectionVisibility()
            return
        }

        loadedQuestionsEventId = eventId

        TablePresenter.getReservationRequestQuestions(
            eventId: eventId,
            venueId: event?.venue?.id ?? ""
        ) { [weak self] isSuccess, _, questions in
            DispatchQueue.main.async {
                guard let self else { return }

                if isSuccess {
                    self.reservationQuestions = (questions ?? [])
                        .filter {
                            !$0.isDeleted &&
                            $0.status.caseInsensitiveCompare("ENABLED") == .orderedSame
                        }
                        .sorted { $0.order < $1.order }
                } else {
                    self.reservationQuestions = []
                }

                self.questionAnswers = self.questionAnswers.filter { answer in
                    self.reservationQuestions.contains { $0.id == answer.key }
                }
                self.reloadQuestionViews()
                self.updateQuestionSectionVisibility()
                self.updateButtonState()
            }
        }
    }

    func reloadQuestionViews() {
        questionViews.removeAll()
        questionStackView.arrangedSubviews.forEach {
            questionStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        reservationQuestions.forEach { question in
            let view = PremiumRequestQuestionView()
            view.configure(question: question, answer: questionAnswers[question.id])
            view.onAnswerChanged = { [weak self] answer, question in
                guard let self else { return }
                self.questionAnswers[question.id] = answer
                self.updateQuestionSectionVisibility()
                self.updateButtonState()
            }
            view.onHeightChanged = { [weak self] in
                self?.updateQuestionSectionVisibility()
            }

            questionStackView.addArrangedSubview(view)
            questionViews.append(view)
        }
    }

    func updateQuestionSectionVisibility() {
        let hasQuestions = !reservationQuestions.isEmpty
        questionSectionView.isHidden = !hasQuestions
        questionSectionCollapsedHeightConstraint?.isActive = !hasQuestions
        questionStackView.layoutIfNeeded()
        stackView.layoutIfNeeded()
        layoutIfNeeded()
    }

    func updatePolicySectionVisibility() {
        let hasPolicies = !(checkboxView.isHidden && emailCheckboxView.isHidden)
        policyStackView.isHidden = !hasPolicies
        policyStackCollapsedHeightConstraint?.isActive = !hasPolicies
        sendButtonTopConstraint?.constant = hasPolicies ? 24 : 0
        updatePolicySectionLayout()
    }

    func updatePolicySectionLayout() {
        policyStackView.layoutIfNeeded()
        stackView.layoutIfNeeded()
        UIView.performWithoutAnimation {
            layoutIfNeeded()
        }
    }

    func validateQuestionAnswers() -> Bool {
        guard let invalidQuestion = reservationQuestions.first(where: { question in
            guard !question.isOptional else { return false }
            return !hasValidAnswer(for: question)
        }) else { return true }

        Alert.showToast("Please answer: \(invalidQuestion.question)")
        scrollToQuestion(invalidQuestion)
        return false
    }

    func validatePolicyAcceptance() -> Bool {
        guard !areVisiblePoliciesAccepted() else { return true }
        Alert.showToast("Please accept the terms and privacy policy.")
        return false
    }

    func areVisiblePoliciesAccepted() -> Bool {
        let smsAccepted = checkboxView.isHidden || checkboxView.isChecked
        let emailAccepted = emailCheckboxView.isHidden || emailCheckboxView.isChecked
        return smsAccepted && emailAccepted
    }

    func scrollToQuestion(_ question: Questions) {
        guard question.questionType == "TEXT",
              let view = questionViews.first(where: { $0.questionId == question.id }) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            view.focusAnswerField()
        }
    }

    func hasValidAnswer(for question: Questions) -> Bool {
        let answer = questionAnswers[question.id]

        switch question.questionType {
        case "MULTI_SELECT":
            return !(answer as? [String] ?? []).isEmpty
        case "SINGLE_SELECT", "TEXT":
            return !((answer as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        case "CHECKBOX":
            return answer as? Bool == true
        default:
            return true
        }
    }

    func reservationQuestionAnswersPayload() -> [Any] {
        reservationQuestions.compactMap { question in
            guard let answer = questionAnswers[question.id] else { return nil }

            if question.isOptional, !hasValidAnswer(for: question) {
                return nil
            }

            return [
                "reservationQuestionId": question.id,
                "answer": answer
            ] as [String: Any]
        }
    }
}

// MARK: - Question View

final class PremiumRequestQuestionView: UIView, UITextFieldDelegate {

    var questionId: String { question?.id ?? "" }
    var onAnswerChanged: ((Any, Questions) -> Void)?
    var onHeightChanged: (() -> Void)?

    private var question: Questions?
    private var currentAnswer: Any?
    private var optionButtons: [UIButton] = []
    private var isOptionsExpanded = false
    private var selectFieldHeightConstraint: NSLayoutConstraint?

    private let mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let textFieldCard = GradientBorderCardView()
    private let selectFieldCard = GradientBorderCardView()
    private let selectDividerView = UIView()

    private let textField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.textColor = .white
        field.tintColor = .white
        field.font = Constant.Font.geistMedium(size: 15)
        return field
    }()

    private let selectTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = Constant.Font.geistMedium(size: 15)
        label.textColor = UIColor.white.withAlphaComponent(0.45)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let selectArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "arrowTopIcon")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.white.withAlphaComponent(0.65)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let selectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let optionStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.isHidden = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let checkboxRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 12
        return stack
    }()

    private let checkboxButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let checkboxQuestionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.white.withAlphaComponent(0.95)
        label.font = Constant.Font.geistRegular(size: 15)
        label.isUserInteractionEnabled = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(question: Questions, answer: Any?) {
        self.question = question
        currentAnswer = answer

        let title = "\(question.question)\(question.isOptional ? "" : " *")"

        textFieldCard.isHidden = question.questionType != "TEXT"
        selectFieldCard.isHidden = !(question.questionType == "SINGLE_SELECT" || question.questionType == "MULTI_SELECT")
        optionStack.isHidden = true
        selectFieldHeightConstraint?.constant = 52
        checkboxRow.isHidden = question.questionType != "CHECKBOX"
        isOptionsExpanded = false
        updateSelectExpandedAppearance(animated: false)

        textField.text = answer as? String
        textField.attributedPlaceholder = NSAttributedString(
            string: title,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.45)]
        )

        checkboxQuestionLabel.text = title
        configureOptions(question.eventQuestionHasOption?.filter { !$0.isDeleted }.map { $0.option } ?? [])
        updateSelectTitle(title: title)
        updateCheckboxState()
        updateOptionStates()
    }

    func focusAnswerField() {
        guard question?.questionType == "TEXT" else { return }
        textField.becomeFirstResponder()
    }

    private func setup() {
        backgroundColor = .clear
        addSubview(mainStack)
        mainStack.addArrangedSubview(textFieldCard)
        mainStack.addArrangedSubview(selectFieldCard)
        mainStack.addArrangedSubview(checkboxRow)

        [textFieldCard, selectFieldCard].forEach { card in
            card.fillColor = UIColor.white.withAlphaComponent(0.05).cgColor
            card.showsBlur = true
            card.blurAlpha = 0.55
            card.thinBorder = true
            card.glassCornerRadius = 14
            card.translatesAutoresizingMaskIntoConstraints = false
            card.clipsToBounds = true
        }

        selectDividerView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        selectDividerView.isHidden = true
        selectDividerView.translatesAutoresizingMaskIntoConstraints = false

        textFieldCard.addSubview(textField)
        selectFieldCard.addSubview(selectTitleLabel)
        selectFieldCard.addSubview(selectArrowImageView)
        selectFieldCard.addSubview(selectButton)
        selectFieldCard.addSubview(selectDividerView)
        selectFieldCard.addSubview(optionStack)
        checkboxRow.addArrangedSubview(checkboxButton)
        checkboxRow.addArrangedSubview(checkboxQuestionLabel)

        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        selectButton.addTarget(self, action: #selector(onTapSelectField), for: .touchUpInside)
        checkboxButton.addTarget(self, action: #selector(onTapCheckbox), for: .touchUpInside)
        checkboxQuestionLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(onTapCheckbox))
        )

        let textTap = UITapGestureRecognizer(target: self, action: #selector(onTapTextFieldContainer))
        textFieldCard.addGestureRecognizer(textTap)
        textFieldCard.isUserInteractionEnabled = true

        let selectHeight = selectFieldCard.heightAnchor.constraint(equalToConstant: 52)
        selectFieldHeightConstraint = selectHeight

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            textFieldCard.heightAnchor.constraint(equalToConstant: 52),
            textField.topAnchor.constraint(equalTo: textFieldCard.topAnchor, constant: 4),
            textField.leadingAnchor.constraint(equalTo: textFieldCard.leadingAnchor, constant: 14),
            textField.trailingAnchor.constraint(equalTo: textFieldCard.trailingAnchor, constant: -14),
            textField.bottomAnchor.constraint(equalTo: textFieldCard.bottomAnchor, constant: -4),

            selectHeight,
            selectTitleLabel.leadingAnchor.constraint(equalTo: selectFieldCard.leadingAnchor, constant: 14),
            selectTitleLabel.trailingAnchor.constraint(equalTo: selectArrowImageView.leadingAnchor, constant: -12),
            selectTitleLabel.centerYAnchor.constraint(equalTo: selectFieldCard.topAnchor, constant: 26),
            selectArrowImageView.trailingAnchor.constraint(equalTo: selectFieldCard.trailingAnchor, constant: -16),
            selectArrowImageView.centerYAnchor.constraint(equalTo: selectFieldCard.topAnchor, constant: 26),
            selectArrowImageView.widthAnchor.constraint(equalToConstant: 9),
            selectArrowImageView.heightAnchor.constraint(equalToConstant: 6),
            selectButton.topAnchor.constraint(equalTo: selectFieldCard.topAnchor),
            selectButton.leadingAnchor.constraint(equalTo: selectFieldCard.leadingAnchor),
            selectButton.trailingAnchor.constraint(equalTo: selectFieldCard.trailingAnchor),
            selectButton.heightAnchor.constraint(equalToConstant: 52),
            selectDividerView.topAnchor.constraint(equalTo: selectFieldCard.topAnchor, constant: 52),
            selectDividerView.leadingAnchor.constraint(equalTo: selectFieldCard.leadingAnchor, constant: 14),
            selectDividerView.trailingAnchor.constraint(equalTo: selectFieldCard.trailingAnchor, constant: -14),
            selectDividerView.heightAnchor.constraint(equalToConstant: 0.5),
            optionStack.topAnchor.constraint(equalTo: selectFieldCard.topAnchor, constant: 52),
            optionStack.leadingAnchor.constraint(equalTo: selectFieldCard.leadingAnchor, constant: 10),
            optionStack.trailingAnchor.constraint(equalTo: selectFieldCard.trailingAnchor, constant: -10),

            checkboxButton.widthAnchor.constraint(equalToConstant: 18),
            checkboxButton.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    private func configureOptions(_ options: [String]) {
        optionStack.arrangedSubviews.forEach {
            optionStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        optionButtons.removeAll()

        options.enumerated().forEach { index, option in
            let button = UIButton(type: .system)
            button.tag = index
            button.contentHorizontalAlignment = .left
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.font = Constant.Font.geistMedium(size: 14)
            button.setTitle(option, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.tintColor = .white
            button.backgroundColor = .clear
            button.layer.cornerRadius = 0
            button.layer.borderWidth = 0
            button.contentEdgeInsets = UIEdgeInsets(top: 9, left: 4, bottom: 9, right: 4)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)
            button.addTarget(self, action: #selector(onTapOption(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 38).isActive = true
            optionStack.addArrangedSubview(button)
            optionButtons.append(button)
        }
    }

    private func updateSelectFieldHeight() {
        let optionCount = optionButtons.count
        let optionHeight = CGFloat(optionCount * 38)
        let spacingHeight = CGFloat(max(0, optionCount - 1) * 8)
        selectFieldHeightConstraint?.constant = isOptionsExpanded
            ? 52 + optionHeight + spacingHeight + 12
            : 52
    }

    private func updateSelectExpandedAppearance(animated: Bool) {
        let changes = {
            self.selectDividerView.isHidden = !self.isOptionsExpanded
            self.selectFieldCard.fillColor = UIColor.white
                .withAlphaComponent(self.isOptionsExpanded ? 0.075 : 0.05)
                .cgColor
            self.selectFieldCard.blurAlpha = self.isOptionsExpanded ? 0.65 : 0.55
            self.selectArrowImageView.transform = self.isOptionsExpanded
                ? .identity
                : CGAffineTransform(rotationAngle: .pi)
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }
    }

    private func updateSelectTitle(title: String) {
        selectTitleLabel.text = title
        selectTitleLabel.textColor = UIColor.white.withAlphaComponent(0.45)
    }

    private func updateOptionStates() {
        guard let question else { return }

        optionButtons.forEach { button in
            let option = button.title(for: .normal) ?? ""
            let isSelected: Bool
            if question.questionType == "MULTI_SELECT" {
                isSelected = (currentAnswer as? [String] ?? []).contains(option)
            } else {
                isSelected = (currentAnswer as? String) == option
            }

            button.setImage(
                (isSelected ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon)?
                    .withRenderingMode(.alwaysOriginal),
                for: .normal
            )
            button.setTitleColor(.white, for: .normal)
        }
    }

    private func updateCheckboxState() {
        let isChecked = currentAnswer as? Bool == true
        checkboxButton.setImage(
            (isChecked ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon)?
                .withRenderingMode(.alwaysOriginal),
            for: .normal
        )
        checkboxQuestionLabel.textColor = UIColor.white.withAlphaComponent(0.95)
    }

    @objc private func textFieldChanged() {
        guard let question else { return }
        let answer = textField.text ?? ""
        currentAnswer = answer
        onAnswerChanged?(answer, question)
    }

    @objc private func onTapTextFieldContainer() {
        textField.becomeFirstResponder()
    }

    @objc private func onTapSelectField() {
        guard !optionButtons.isEmpty else { return }
        AppHaptic.selectionChanged()
        isOptionsExpanded.toggle()
        optionStack.isHidden = !isOptionsExpanded
        updateSelectFieldHeight()
        updateSelectExpandedAppearance(animated: true)
        onHeightChanged?()
    }

    @objc private func onTapOption(_ sender: UIButton) {
        guard let question, let selectedOption = sender.title(for: .normal) else { return }

        AppHaptic.selectionChanged()
        if question.questionType == "MULTI_SELECT" {
            var answers = currentAnswer as? [String] ?? []
            if let index = answers.firstIndex(of: selectedOption) {
                answers.remove(at: index)
            } else {
                answers.append(selectedOption)
            }
            currentAnswer = answers
            onAnswerChanged?(answers, question)
        } else {
            currentAnswer = selectedOption
            onAnswerChanged?(selectedOption, question)
        }

        updateSelectTitle(title: "\(question.question)\(question.isOptional ? "" : " *")")
        updateOptionStates()
    }

    @objc private func onTapCheckbox() {
        guard let question else { return }
        let answer = !(currentAnswer as? Bool ?? false)
        AppHaptic.selectionChanged()
        currentAnswer = answer
        updateCheckboxState()
        onAnswerChanged?(answer, question)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldCard.fillColor = UIColor.white.withAlphaComponent(0.08).cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldCard.fillColor = UIColor.white.withAlphaComponent(0.05).cgColor
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
            title: "Incomplete Profile",
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
    var isGuestListByGenderEnabled: Bool {
        event?.eventSettings?.isGuestListByGender == true
    }

    func venueTimeZone() -> TimeZone {
        TimeZone(identifier: venueTimeZoneIdentifier()) ?? .current
    }

    func venueTimeZoneIdentifier() -> String {
        Event.normalizedTimezone(
            event?.venue?.useTimezone,
            event?.venue?.timezone
        ) ?? TimeZone.current.identifier
    }

    func formattedDisplayDate(_ date: Date) -> String {
        let formate         = DateFormatter()
        formate.dateFormat   = "MM/dd/yyyy"
        formate.timeZone     = venueTimeZone()
        return formate.string(from: date)
    }

    func formattedDisplayTime(_ date: Date) -> String {
        let formate          = DateFormatter()
        formate.dateFormat   = "hh:mm a"
        formate.timeZone     = venueTimeZone()
        return formate.string(from: date)
    }

    func combineDateAndTime(date: Date, time: Date) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = venueTimeZone()
        let dateParts = calendar.dateComponents([.year, .month, .day], from: date)
        let timeParts = calendar.dateComponents([.hour, .minute, .second], from: time)
        var combined = DateComponents()
        combined.timeZone = venueTimeZone()
        combined.year = dateParts.year
        combined.month = dateParts.month
        combined.day = dateParts.day
        combined.hour = timeParts.hour
        combined.minute = timeParts.minute
        combined.second = timeParts.second ?? 0
        return calendar.date(from: combined)
    }

    func formattedUTCDateTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}
