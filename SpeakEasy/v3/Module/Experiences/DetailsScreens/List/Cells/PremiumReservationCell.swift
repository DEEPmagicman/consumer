//
//  PremiumReservationCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

final class PremiumReservationCell: UITableViewCell {

    // MARK: Callback

    var onBookTap: (() -> Void)?
    var onDescriptionToggle: (() -> Void)?

    // MARK: Glass

    private let cardView =  GradientBorderCardView()

    // MARK: Labels

    private let titleLabel = UILabel()

    private let guestView = PremiumInfoPillView()

    private let timeView = PremiumInfoPillView()

    private let descriptionLabel = UILabel()

    private let descriptionToggleButton = UIButton(type: .system)

    private let minimumLabel = UILabel()

    private let depositLabel = UILabel()

    private let bookButton = UIButton(type: .system)

    private var minimumBottomConstraint: NSLayoutConstraint?
    private var bookButtonCenterToDepositConstraint: NSLayoutConstraint?
    private var priceHiddenButtonTopConstraint: NSLayoutConstraint?
    private var priceHiddenButtonBottomConstraint: NSLayoutConstraint?
    private var descriptionToggleTopConstraint: NSLayoutConstraint?
    private var descriptionToggleHeightConstraint: NSLayoutConstraint?
    private var depositTopConstraint: NSLayoutConstraint?

    private let collapsedDescriptionLines = 2
    private var isDescriptionExpanded = false
    private var currentDescriptionText = ""
    private var lastDescriptionMeasurementWidth: CGFloat = 0
    private var lastDescriptionMeasurementText = ""
    private var needsDescriptionMeasurement = false
    private var cachedDescriptionNeedsToggle = false

    // MARK:

    override init(style: UITableViewCell.CellStyle,
                  reuseIdentifier: String?) {

        super.init(
            style: style,
            reuseIdentifier: reuseIdentifier
        )

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        cardView.glassCornerRadius = 20
        bookButton.layer.cornerRadius = 18
        updateDescriptionToggleVisibilityIfNeeded()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.text = nil
        descriptionLabel.text = nil
        descriptionLabel.isHidden = false
        descriptionLabel.numberOfLines = collapsedDescriptionLines
        descriptionLabel.lineBreakMode = .byTruncatingTail
        depositLabel.text = nil
        minimumLabel.text = nil
        onBookTap = nil
        onDescriptionToggle = nil
        isDescriptionExpanded = false
        currentDescriptionText = ""
        lastDescriptionMeasurementWidth = 0
        lastDescriptionMeasurementText = ""
        needsDescriptionMeasurement = false
        cachedDescriptionNeedsToggle = false
        descriptionToggleButton.isHidden = true
        descriptionToggleButton.setTitle("View More", for: .normal)
        updateDescriptionToggleSpacing(isVisible: false)

        guestView.isHidden = false
        timeView.isHidden = false
        depositLabel.isHidden = false
        minimumLabel.isHidden = false
        bookButton.isEnabled = true
        bookButton.isUserInteractionEnabled = true
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize
    ) -> CGSize {

        contentView.layoutIfNeeded()

        let size = contentView.systemLayoutSizeFitting(

            CGSize(
                width: targetSize.width,
                height: UIView.layoutFittingCompressedSize.height
            ),

            withHorizontalFittingPriority: .required,

            verticalFittingPriority: .fittingSizeLevel
        )

        return CGSize(
            width: targetSize.width,
            height: size.height
        )
    }

    func setupUI() {

        selectionStyle = .none

        backgroundColor = .clear

        contentView.backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.fillColor = AppColor.primaryWhiteColor
            .withAlphaComponent(0.05)
            .cgColor

        cardView.showsBlur = true
        cardView.blurAlpha = 0.60
        contentView.addSubview(cardView)

        setupTitle()

        setupPills()

        setupDescription()

        setupDescriptionToggleButton()

        setupPricing()

        setupButton()

        setupConstraints()
    }

    func setupTitle() {

        titleLabel.font =
        Constant.Font.geistMedium(size: 16)

        titleLabel.textColor = .white

        titleLabel.numberOfLines = 0

        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(titleLabel)
    }

    func setupPills() {

        guestView.translatesAutoresizingMaskIntoConstraints = false
        timeView.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(guestView)
        cardView.addSubview(timeView)
    }

    func setupDescription() {

        descriptionLabel.font =
        Constant.Font.geistRegular(size: 12)

        descriptionLabel.textColor =
        UIColor(hex: "#D2D5DB")

        descriptionLabel.numberOfLines = 0

        descriptionLabel.lineBreakMode = .byWordWrapping

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(descriptionLabel)
    }

    func setupDescriptionToggleButton() {

        descriptionToggleButton.setTitle(
            "View More",
            for: .normal
        )

        descriptionToggleButton.setTitleColor(
            UIColor(hex: "#D2D5DB"),
            for: .normal
        )

        descriptionToggleButton.titleLabel?.font =
        Constant.Font.geistMedium(size: 12)

        descriptionToggleButton.contentHorizontalAlignment = .leading

        descriptionToggleButton.translatesAutoresizingMaskIntoConstraints = false

        descriptionToggleButton.isHidden = true

        descriptionToggleButton.addTarget(
            self,
            action: #selector(descriptionTogglePressed),
            for: .touchUpInside
        )

        cardView.addSubview(descriptionToggleButton)
    }

    func setupPricing() {

        depositLabel.font =
        Constant.Font.geistRegular(size: 16)

        depositLabel.textColor = .white

        depositLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(depositLabel)

        minimumLabel.font =
        Constant.Font.geistRegular(size: 12)

        minimumLabel.textColor =
        UIColor(hex: "#A1A1A1")

        minimumLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(minimumLabel)
    }

    func setupButton() {

        bookButton.setTitleColor(
            .white,
            for: .normal
        )

        bookButton.titleLabel?.font =
        Constant.Font.geistMedium(size: 12)

        bookButton.backgroundColor =
        UIColor(hex: "#D99935")

        bookButton.translatesAutoresizingMaskIntoConstraints = false

        bookButton.addTarget(
            self,
            action: #selector(bookPressed),
            for: .touchUpInside
        )

        cardView.addSubview(bookButton)
    }

    @objc
    func bookPressed() {
        AppHaptic.primaryAction()
        onBookTap?()
    }

    func setupConstraints() {
        let minimumBottom = minimumLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18)
        let buttonCenterToDeposit = bookButton.centerYAnchor.constraint(equalTo: depositLabel.centerYAnchor, constant: 6)
        let hiddenButtonTop = bookButton.topAnchor.constraint(greaterThanOrEqualTo: descriptionToggleButton.bottomAnchor, constant: 18)
        let hiddenButtonBottom = bookButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18)
        let toggleTop = descriptionToggleButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor)
        let toggleHeight = descriptionToggleButton.heightAnchor.constraint(equalToConstant: 0)
        let depositTop = depositLabel.topAnchor.constraint(equalTo: descriptionToggleButton.bottomAnchor, constant: 22)

        minimumBottomConstraint = minimumBottom
        bookButtonCenterToDepositConstraint = buttonCenterToDeposit
        priceHiddenButtonTopConstraint = hiddenButtonTop
        priceHiddenButtonBottomConstraint = hiddenButtonBottom
        descriptionToggleTopConstraint = toggleTop
        descriptionToggleHeightConstraint = toggleHeight
        depositTopConstraint = depositTop
        hiddenButtonTop.isActive = false
        hiddenButtonBottom.isActive = false

        NSLayoutConstraint.activate([

            // MARK: Card

            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            // MARK: Title

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),

            // MARK: Guest

            guestView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            guestView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            guestView.heightAnchor.constraint(equalToConstant: 22),

            // MARK: Time

            timeView.centerYAnchor.constraint(equalTo: guestView.centerYAnchor),
            timeView.leadingAnchor.constraint(equalTo: guestView.trailingAnchor, constant: 8),
            timeView.heightAnchor.constraint(equalToConstant: 22),
            timeView.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -18),

            // MARK: Description

            descriptionLabel.topAnchor.constraint(equalTo: guestView.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // MARK: Description Toggle

            toggleTop,
            descriptionToggleButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionToggleButton.trailingAnchor.constraint(lessThanOrEqualTo: titleLabel.trailingAnchor),
            toggleHeight,

            // MARK: Deposit

            depositTop,
            depositLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            // MARK: Minimum Spend

            minimumLabel.topAnchor.constraint(equalTo: depositLabel.bottomAnchor, constant: 4),
            minimumLabel.leadingAnchor.constraint(equalTo: depositLabel.leadingAnchor),
            minimumBottom,

            // MARK: Book Button

            bookButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            buttonCenterToDeposit,

            bookButton.widthAnchor.constraint(equalToConstant: 94),
            bookButton.heightAnchor.constraint(equalToConstant: 36),

            bookButton.leadingAnchor.constraint(greaterThanOrEqualTo: depositLabel.trailingAnchor, constant: 16),

            minimumLabel.trailingAnchor.constraint(lessThanOrEqualTo: bookButton.leadingAnchor, constant: -12)
        ])
    }

    func configure(
        title: String,
        guestText: String,
        timeText: String,
        description: String,
        depositText: String,
        minimumText: String,
        buttonTitle: String,
        hidePricing: Bool,
        isDescriptionExpanded: Bool = false
    ) {

        titleLabel.text = title

        configureDescription(
            description,
            isExpanded: isDescriptionExpanded
        )

        guestView.configure(
            style: .guests,
            text: guestText
        )

        if timeText.isEmpty {

            timeView.isHidden = true

        } else {

            timeView.isHidden = false

            timeView.configure(
                style: .time,
                text: timeText
            )
        }

        depositLabel.text = depositText

        minimumLabel.text = minimumText

        depositLabel.isHidden = hidePricing
        minimumLabel.isHidden = hidePricing
        minimumBottomConstraint?.isActive = !hidePricing
        bookButtonCenterToDepositConstraint?.isActive = !hidePricing
        priceHiddenButtonTopConstraint?.isActive = hidePricing
        priceHiddenButtonBottomConstraint?.isActive = hidePricing

        bookButton.setTitle(
            buttonTitle,
            for: .normal
        )

        if buttonTitle == "Inquiry" {

            configureInquiryButton()

        } else {

            configureBookButton()
        }
    }

    func configureBookButton() {

        bookButton.setTitleColor(
            .white,
            for: .normal
        )

        bookButton.titleLabel?.font =
        Constant.Font.geistMedium(size: 12)

        bookButton.backgroundColor = .clear

        if let glass = bookButton.subviews.first(where: {
            $0 is LiquidGlassBackgroundView
        }) {

            glass.removeFromSuperview()
        }

        let glass = LiquidGlassBackgroundView(

            cornerRadius: 18,

            fillColor:
                UIColor(hex: "#D99935")
                .withAlphaComponent(0.30),

            borderColor:
                UIColor.white.withAlphaComponent(0.25),

            borderWidth: 0.8
        )

        glass.isUserInteractionEnabled = false
        glass.translatesAutoresizingMaskIntoConstraints = false

        bookButton.insertSubview(
            glass,
            at: 0
        )

        NSLayoutConstraint.activate([

            glass.topAnchor.constraint(
                equalTo: bookButton.topAnchor
            ),

            glass.leadingAnchor.constraint(
                equalTo: bookButton.leadingAnchor
            ),

            glass.trailingAnchor.constraint(
                equalTo: bookButton.trailingAnchor
            ),

            glass.bottomAnchor.constraint(
                equalTo: bookButton.bottomAnchor
            )
        ])
    }

    func configureInquiryButton() {

        bookButton.setTitleColor(
            .white,
            for: .normal
        )

        bookButton.titleLabel?.font =
        Constant.Font.geistMedium(size: 12)

        bookButton.backgroundColor = .clear

        if let glass = bookButton.subviews.first(where: {
            $0 is LiquidGlassBackgroundView
        }) {

            glass.removeFromSuperview()
        }

        let glass = LiquidGlassBackgroundView(

            cornerRadius: 18,

            fillColor:
                UIColor(hex: "#FF9B00")
                .withAlphaComponent(0.22),

            borderColor:
                UIColor.white.withAlphaComponent(0.25),

            borderWidth: 0.8
        )

        glass.isUserInteractionEnabled = false
        glass.translatesAutoresizingMaskIntoConstraints = false

        bookButton.insertSubview(
            glass,
            at: 0
        )

        NSLayoutConstraint.activate([

            glass.topAnchor.constraint(
                equalTo: bookButton.topAnchor
            ),

            glass.leadingAnchor.constraint(
                equalTo: bookButton.leadingAnchor
            ),

            glass.trailingAnchor.constraint(
                equalTo: bookButton.trailingAnchor
            ),

            glass.bottomAnchor.constraint(
                equalTo: bookButton.bottomAnchor
            )
        ])
    }

    private func configureDescription(
        _ text: String,
        isExpanded: Bool
    ) {
        let trimmed = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        currentDescriptionText = trimmed
        self.isDescriptionExpanded = isExpanded
        lastDescriptionMeasurementWidth = 0
        lastDescriptionMeasurementText = ""
        needsDescriptionMeasurement = !trimmed.isEmpty
        cachedDescriptionNeedsToggle = false

        guard !trimmed.isEmpty else {
            descriptionLabel.text = nil
            descriptionLabel.isHidden = true
            descriptionToggleButton.isHidden = true
            updateDescriptionToggleSpacing(isVisible: false)
            return
        }

        descriptionLabel.isHidden = false
        descriptionLabel.text = trimmed
        applyDescriptionExpansionState()
        descriptionToggleButton.isHidden = true
        updateDescriptionToggleSpacing(isVisible: false)
        setNeedsLayout()
        updateDescriptionToggleVisibilityIfNeeded(force: true)
    }

    private func applyDescriptionExpansionState() {
        descriptionLabel.numberOfLines = isDescriptionExpanded
            ? 0
            : collapsedDescriptionLines
        descriptionLabel.lineBreakMode = isDescriptionExpanded
            ? .byWordWrapping
            : .byTruncatingTail
        descriptionToggleButton.setTitle(
            isDescriptionExpanded ? "View Less" : "View More",
            for: .normal
        )
    }

    private func updateDescriptionToggleVisibilityIfNeeded(force: Bool = false) {
        guard !currentDescriptionText.isEmpty,
              !descriptionLabel.isHidden else {
            return
        }

        let width = descriptionLabel.bounds.width
        guard width > 1 else {
            needsDescriptionMeasurement = true
            return
        }

        if !force,
           !needsDescriptionMeasurement,
           abs(width - lastDescriptionMeasurementWidth) < 0.5,
           lastDescriptionMeasurementText == currentDescriptionText {
            return
        }

        let needsToggle = descriptionNeedsToggle(
            text: currentDescriptionText,
            width: width
        )

        cachedDescriptionNeedsToggle = needsToggle
        needsDescriptionMeasurement = false
        lastDescriptionMeasurementWidth = width
        lastDescriptionMeasurementText = currentDescriptionText

        descriptionToggleButton.isHidden = !needsToggle
        updateDescriptionToggleSpacing(isVisible: needsToggle)

        if needsToggle {
            applyDescriptionExpansionState()
        } else {
            descriptionLabel.numberOfLines = 0
            descriptionLabel.lineBreakMode = .byWordWrapping
            descriptionToggleButton.setTitle("View More", for: .normal)
        }
    }

    private func updateDescriptionToggleSpacing(isVisible: Bool) {
        descriptionToggleTopConstraint?.constant = isVisible ? 4 : 0
        descriptionToggleHeightConstraint?.constant = isVisible ? 20 : 0
        depositTopConstraint?.constant = isVisible ? 14 : 22
    }

    private func descriptionNeedsToggle(
        text: String,
        width: CGFloat
    ) -> Bool {
        let font = descriptionLabel.font ?? Constant.Font.geistRegular(size: 12)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let rect = (text as NSString).boundingRect(
            with: CGSize(
                width: width,
                height: .greatestFiniteMagnitude
            ),
            options: [
                .usesLineFragmentOrigin,
                .usesFontLeading
            ],
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ],
            context: nil
        )

        let collapsedHeight = ceil(font.lineHeight * CGFloat(collapsedDescriptionLines))
        return ceil(rect.height) > collapsedHeight + 0.5
    }

    @objc
    private func descriptionTogglePressed() {
        guard cachedDescriptionNeedsToggle || !descriptionToggleButton.isHidden else {
            return
        }

        AppHaptic.selectionChanged()
        isDescriptionExpanded.toggle()
        UIView.performWithoutAnimation {
            applyDescriptionExpansionState()
            layoutIfNeeded()
        }
        onDescriptionToggle?()
    }
}
