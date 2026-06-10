import UIKit
import MHLoadingButton

// MARK: - PaymentVC

enum PaymentType {
    case applePay
    case card
}

struct CardDetails {
    let firstName: String
    let lastName: String
    let cardNumber: String
    let expiryMonth: UInt
    let expiryYear: UInt
    let cvv: String
}

final class PaymentVC: UIViewController {

    // MARK: - UI Components

    private let backBtn = AppIconButton()
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Single outer card that holds everything
    private let mainCard = UIView()

    // Apple Pay row
    private let applePayRow = UIView()
    private let applePayLabel = UILabel()
    private let applePayIcon = UIImageView()
    private let applePayCheckbox = UIButton()

    // Card row
    private let cardRow = UIView()
    private let cardLabel = UILabel()
    private let cardIcon = UIImageView()
    private let cardCheckbox = UIButton()

    // Card detail fields
    let firstNameField  = PaymentTextField(placeholder: "First name")
     let lastNameField   = PaymentTextField(placeholder: "Last name")
     let cardNumberField = PaymentTextField(placeholder: "Card number")
     let expiryField     = PaymentTextField(placeholder: "Expiry date")
     let cvvField        = PaymentTextField(placeholder: "CVV")
     let zipField        = PaymentTextField(placeholder: "Zip code")

    // Save card row
    private let saveCardCheckbox = UIButton()
    private let saveCardLabel    = UILabel()

    // Done button
    private let doneBtn = LoadingButton()

    // MARK: - State

    private var isApplePaySelected = false
    private var isCardSelected     = true
    private var isSaveCard         = false
    
    var event: Event?
    var selectedTickets: [EventTicket] = []
    var venueDetails: ClipVenue?
    var bookingId: String?
    var selectedPaymentMethod: PaymentType = .card
    var onPaymentSelected: ((PaymentType, CardDetails?) -> Void)?
    private let posterHeaderView = EventPosterHeaderView()
    private let backgroundContainerView = UIView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackgroundView()
        setupNav()
        setupScrollView()
        setupMainCard()
//        setupSaveCardRow()
//        setupDoneButton()
        setupConstraints()
        updateCheckboxStates()
    }


    private func setupBackgroundView() {

        backgroundContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundContainerView)

        NSLayoutConstraint.activate([
            backgroundContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        backgroundContainerView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: backgroundContainerView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: backgroundContainerView.bottomAnchor)
        ])

        let imageURLString = (event?.flyer?.key ?? "").imageURL
        posterHeaderView.loadImage(from: imageURLString)
    }

    private func setupNav() {
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 14
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)

        titleLabel.text = "Payment"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }

    // MARK: - ScrollView

    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
    }

    // MARK: - Main Card (Apple Pay + Card row + all fields)

    private func setupMainCard() {
        // ── Outer card styling ───────────────────────────────────────────────
        mainCard.backgroundColor = UIColor(hex: "#000000", alpha: 0.25)
        mainCard.layer.cornerRadius = 16
        mainCard.layer.cornerCurve = .continuous
        mainCard.layer.borderWidth = 1
        mainCard.layer.borderColor = UIColor(hex: "#FFFFFF", alpha: 0.12).cgColor
        mainCard.clipsToBounds = true
        mainCard.translatesAutoresizingMaskIntoConstraints = false

        // ── Inner stack ──────────────────────────────────────────────────────
        let innerStack = UIStackView()
        innerStack.axis = .vertical
        innerStack.spacing = 0
        innerStack.alignment = .fill
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        mainCard.addSubview(innerStack)

        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: mainCard.topAnchor),
            innerStack.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor),
            innerStack.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor),
            innerStack.bottomAnchor.constraint(equalTo: mainCard.bottomAnchor, constant: -16),
        ])

        // ── Apple Pay row ────────────────────────────────────────────────────
        applePayLabel.text = "Pay with Apple Pay"
        applePayLabel.textColor = AppColor.primaryWhiteColor
        applePayLabel.font = Constant.Font.geistMedium(size: 18)
        applePayLabel.translatesAutoresizingMaskIntoConstraints = false

        applePayIcon.image = UIImage(named: "applePayIcon")
        applePayIcon.contentMode = .scaleAspectFit
        applePayIcon.translatesAutoresizingMaskIntoConstraints = false

        applePayCheckbox.setImage(UIImage(named: "uncheckedIcon"), for: .normal)
        applePayCheckbox.setImage(UIImage(named: "checkedIcon"), for: .selected)
        applePayCheckbox.addTarget(self, action: #selector(onApplePayTapped), for: .touchUpInside)
        applePayCheckbox.translatesAutoresizingMaskIntoConstraints = false

        applePayRow.translatesAutoresizingMaskIntoConstraints = false
        applePayRow.addSubview(applePayLabel)
        applePayRow.addSubview(applePayIcon)
        applePayRow.addSubview(applePayCheckbox)

        NSLayoutConstraint.activate([
            applePayRow.heightAnchor.constraint(equalToConstant: 64),
            applePayLabel.leadingAnchor.constraint(equalTo: applePayRow.leadingAnchor, constant: 16),
            applePayLabel.centerYAnchor.constraint(equalTo: applePayRow.centerYAnchor),
            applePayCheckbox.trailingAnchor.constraint(equalTo: applePayRow.trailingAnchor, constant: -16),
            applePayCheckbox.centerYAnchor.constraint(equalTo: applePayRow.centerYAnchor),
            applePayCheckbox.widthAnchor.constraint(equalToConstant: 18),
            applePayCheckbox.heightAnchor.constraint(equalToConstant: 18),
            applePayIcon.trailingAnchor.constraint(equalTo: applePayCheckbox.leadingAnchor, constant: -10),
            applePayIcon.centerYAnchor.constraint(equalTo: applePayRow.centerYAnchor),
            applePayIcon.widthAnchor.constraint(equalToConstant: 34),
            applePayIcon.heightAnchor.constraint(equalToConstant: 21),
        ])
        innerStack.addArrangedSubview(applePayRow)

        // ── Divider 1 ────────────────────────────────────────────────────────
        innerStack.addArrangedSubview(makeDivider())

        // ── Pay with card row ────────────────────────────────────────────────
        cardLabel.text = "Pay with card"
        cardLabel.textColor = AppColor.primaryWhiteColor
        cardLabel.font = Constant.Font.geistMedium(size: 18)
        cardLabel.translatesAutoresizingMaskIntoConstraints = false

        cardIcon.image = UIImage(named: "creditCardIcon")
        cardIcon.contentMode = .scaleAspectFit
        cardIcon.translatesAutoresizingMaskIntoConstraints = false

        cardCheckbox.setImage(UIImage(named: "uncheckedIcon"), for: .normal)
        cardCheckbox.setImage(UIImage(named: "checkedIcon"), for: .selected)
        cardCheckbox.addTarget(self, action: #selector(onCardTapped), for: .touchUpInside)
        cardCheckbox.translatesAutoresizingMaskIntoConstraints = false

        cardRow.translatesAutoresizingMaskIntoConstraints = false
        cardRow.addSubview(cardLabel)
        cardRow.addSubview(cardIcon)
        cardRow.addSubview(cardCheckbox)

        NSLayoutConstraint.activate([
            cardRow.heightAnchor.constraint(equalToConstant: 64),
            cardLabel.leadingAnchor.constraint(equalTo: cardRow.leadingAnchor, constant: 16),
            cardLabel.centerYAnchor.constraint(equalTo: cardRow.centerYAnchor),
            cardCheckbox.trailingAnchor.constraint(equalTo: cardRow.trailingAnchor, constant: -16),
            cardCheckbox.centerYAnchor.constraint(equalTo: cardRow.centerYAnchor),
            cardCheckbox.widthAnchor.constraint(equalToConstant: 18),
            cardCheckbox.heightAnchor.constraint(equalToConstant: 18),
            cardIcon.trailingAnchor.constraint(equalTo: cardCheckbox.leadingAnchor, constant: -10),
            cardIcon.centerYAnchor.constraint(equalTo: cardRow.centerYAnchor),
            cardIcon.widthAnchor.constraint(equalToConstant: 34),
            cardIcon.heightAnchor.constraint(equalToConstant: 21),
        ])
        innerStack.addArrangedSubview(cardRow)

        // ── Card detail fields inside the card ───────────────────────────────
        cardNumberField.keyboardType = .numberPad
        expiryField.keyboardType    = .numberPad
        cvvField.keyboardType       = .numberPad
        zipField.keyboardType       = .numberPad

        let fieldStack = UIStackView(arrangedSubviews: [
            firstNameField, lastNameField, cardNumberField,
            expiryField, cvvField, zipField
        ])
        fieldStack.axis = .vertical
        fieldStack.spacing = 10
        fieldStack.alignment = .fill
        fieldStack.translatesAutoresizingMaskIntoConstraints = false

        // Padded container so fields sit inside the card with 16pt margins
        let fieldContainer = UIView()
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.addSubview(fieldStack)

        NSLayoutConstraint.activate([
            fieldStack.topAnchor.constraint(equalTo: fieldContainer.topAnchor, constant: 16),
            fieldStack.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 16),
            fieldStack.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -16),
            fieldStack.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor),
        ])
        innerStack.addArrangedSubview(fieldContainer)

        // Add main card to content stack
        // ── Save card row inside main card ─────────────────────────────────────
        saveCardCheckbox.setImage(UIImage(named: "uncheckedIcon"), for: .normal)
        saveCardCheckbox.setImage(UIImage(named: "checkedIcon"), for: .selected)
        saveCardCheckbox.addTarget(self, action: #selector(onSaveCardTapped), for: .touchUpInside)
        saveCardCheckbox.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            saveCardCheckbox.widthAnchor.constraint(equalToConstant: 18),
            saveCardCheckbox.heightAnchor.constraint(equalToConstant: 18)
        ])

        saveCardLabel.text = "Save card to my profile"
        saveCardLabel.textColor = AppColor.primaryWhiteColor
        saveCardLabel.font = Constant.Font.geistRegular(size: 14)
        saveCardLabel.translatesAutoresizingMaskIntoConstraints = false

        let saveCardStack = UIStackView(arrangedSubviews: [saveCardCheckbox, saveCardLabel])
        saveCardStack.axis = .horizontal
        saveCardStack.spacing = 10
        saveCardStack.alignment = .center
        saveCardStack.translatesAutoresizingMaskIntoConstraints = false

        let saveCardContainer = UIView()
        saveCardContainer.translatesAutoresizingMaskIntoConstraints = false
        saveCardContainer.addSubview(saveCardStack)

        NSLayoutConstraint.activate([
            saveCardStack.topAnchor.constraint(equalTo: saveCardContainer.topAnchor, constant: 16),
            saveCardStack.leadingAnchor.constraint(equalTo: saveCardContainer.leadingAnchor, constant: 16),
            saveCardStack.trailingAnchor.constraint(lessThanOrEqualTo: saveCardContainer.trailingAnchor, constant: -16),
            saveCardStack.bottomAnchor.constraint(equalTo: saveCardContainer.bottomAnchor, constant: -16)
        ])

        innerStack.addArrangedSubview(saveCardContainer)

        // ── Done button inside main card ───────────────────────────────────────
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.setTitleColor(AppColor.primaryBlackColor, for: .normal)
        doneBtn.titleLabel?.font = Constant.Font.geistMedium(size: 17)
        doneBtn.bgColor = AppColor.primaryWhiteColor
        doneBtn.layer.cornerRadius = 28
        doneBtn.clipsToBounds = true
        doneBtn.indicator = MaterialLoadingIndicator(color: AppColor.primaryBlackColor)
        doneBtn.addTarget(self, action: #selector(onClickDone), for: .touchUpInside)
        doneBtn.translatesAutoresizingMaskIntoConstraints = false

        let doneContainer = UIView()
        doneContainer.translatesAutoresizingMaskIntoConstraints = false
        doneContainer.addSubview(doneBtn)

        NSLayoutConstraint.activate([
            doneBtn.topAnchor.constraint(equalTo: doneContainer.topAnchor, constant: 4),
            doneBtn.leadingAnchor.constraint(equalTo: doneContainer.leadingAnchor, constant: 16),
            doneBtn.trailingAnchor.constraint(equalTo: doneContainer.trailingAnchor, constant: -16),
            doneBtn.bottomAnchor.constraint(equalTo: doneContainer.bottomAnchor, constant: -16),
            doneBtn.heightAnchor.constraint(equalToConstant: 56)
        ])

        innerStack.addArrangedSubview(doneContainer)
        contentStack.addArrangedSubview(mainCard)
    }
    private func setupDoneButton() {
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.setTitleColor(AppColor.primaryBlackColor, for: .normal)
        doneBtn.titleLabel?.font = Constant.Font.geistMedium(size: 17)
        doneBtn.bgColor = AppColor.primaryWhiteColor
        doneBtn.layer.cornerRadius = 28
        doneBtn.clipsToBounds = true
        doneBtn.indicator = MaterialLoadingIndicator(color: AppColor.primaryBlackColor)
        doneBtn.addTarget(self, action: #selector(onClickDone), for: .touchUpInside)
        doneBtn.translatesAutoresizingMaskIntoConstraints = false
        doneBtn.heightAnchor.constraint(equalToConstant: 56).isActive = true

        contentStack.addArrangedSubview(makeSpacer(4))
        contentStack.addArrangedSubview(doneBtn)
        contentStack.addArrangedSubview(makeSpacer(24))
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Back button
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backBtn.widthAnchor.constraint(equalToConstant: 40),
            backBtn.heightAnchor.constraint(equalToConstant: 40),

            // Title
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // ScrollView
            scrollView.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentStack
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])
    }

    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func onApplePayTapped() {
        selectedPaymentMethod = .applePay
        updateCheckboxStates()
    }

    @objc private func onSaveCardTapped() {
        isSaveCard.toggle()
        saveCardCheckbox.isSelected = isSaveCard
    }

    @objc private func onCardTapped() {
        selectedPaymentMethod = .card
        updateCheckboxStates()
    }

    @objc private func onClickDone() {
        // Apple Pay — no card fields needed, pass nil
        if selectedPaymentMethod == .applePay {
            if let onPaymentSelected {
                onPaymentSelected(selectedPaymentMethod, nil)
                navigationController?.popViewController(animated: true)
                return
            }

            guard let event else { return }
            Navigate.orderListVC(
                self,
                event: event,
                selectedTickets: selectedTickets,
                bookingId: bookingId,
                paymentMethod: selectedPaymentMethod,
                cardDetails: nil
            )
            return
        }

        // Card — validate fields
        let firstName  = firstNameField.text ?? ""
        let lastName   = lastNameField.text ?? ""
        let cardNumber = cardNumberField.text ?? ""
        let expiry     = expiryField.text ?? ""       // expects "MM/YY"
        let cvv        = cvvField.text ?? ""

        guard !firstName.isEmpty else { Alert.showToast("Enter first name"); return }
        guard !lastName.isEmpty  else { Alert.showToast("Enter last name"); return }
        guard cardNumber.count >= 15 else { Alert.showToast("Enter valid card number"); return }
        guard !cvv.isEmpty       else { Alert.showToast("Enter CVV"); return }

        // Parse MM/YY
        let parts = expiry.split(separator: "/")
        guard parts.count == 2,
              let month = UInt(parts[0]),
              let year  = UInt(parts[1]),
              month >= 1, month <= 12 else {
            Alert.showToast("Enter expiry as MM/YY")
            return
        }

        let cardDetails = CardDetails(
            firstName:   firstName,
            lastName:    lastName,
            cardNumber:  cardNumber.replacingOccurrences(of: " ", with: ""),
            expiryMonth: month,
            expiryYear:  2000 + year,
            cvv:         cvv
        )

        if let onPaymentSelected {
            onPaymentSelected(selectedPaymentMethod, cardDetails)
            navigationController?.popViewController(animated: true)
            return
        }

        guard let event else { return }
        Navigate.orderListVC(
            self,
            event: event,
            selectedTickets: selectedTickets,
            bookingId: bookingId,
            paymentMethod: selectedPaymentMethod,
            cardDetails: cardDetails
        )
    }
    
    private func updateCheckboxStates() {
        applePayCheckbox.isSelected = selectedPaymentMethod == .applePay
        cardCheckbox.isSelected = selectedPaymentMethod == .card
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#FFFFFF", alpha: 0.12)
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func makeSpacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }
}

final class PaymentTextField: UIView {

     let textField = UITextField()

    init(placeholder: String) {
        super.init(frame: .zero)
        setup(placeholder: placeholder)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(placeholder: "")
    }

    var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }

    var text: String? { textField.text }

    private func setup(placeholder: String) {
        backgroundColor = UIColor(hex: "#000000", alpha: 0.25)
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: "#FFFFFF", alpha: 0.12).cgColor
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 54).isActive = true

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(hex: "#FFFFFF", alpha: 0.40),
                .font: Constant.Font.geistRegular(size: 16)
            ]
        )
        textField.textColor = AppColor.primaryWhiteColor
        textField.font = Constant.Font.geistRegular(size: 16)
        textField.tintColor = AppColor.primaryWhiteColor
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8)  / 255
        let b = CGFloat(rgb & 0x0000FF)          / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}


extension PaymentVC: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard textField == expiryField.textField else { return true }

        let current = (textField.text ?? "") as NSString
        var updated = current.replacingCharacters(in: range, with: string)
            .replacingOccurrences(of: "/", with: "")

        if updated.count > 4 { return false }

        if updated.count > 2 {
            updated.insert("/", at: updated.index(updated.startIndex, offsetBy: 2))
        }

        textField.text = updated
        return false
    }
}
