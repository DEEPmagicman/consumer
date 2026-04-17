//
//  TableSeatingViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 17/02/26.
//

import UIKit

class TableSeatingViewController: UIViewController {

    @IBOutlet weak var tableName: UILabel!
    @IBOutlet weak var tableDetailLbl: UILabel!
    @IBOutlet weak var tableDescriptionLbl: UILabel!
    @IBOutlet weak var guestAndTimeLbl: UILabel!
    @IBOutlet weak var maxiMumGuestLbl: UILabel!
    @IBOutlet weak var miniMumAmountLbl: UILabel!
    @IBOutlet weak var feesLbl: UILabel!
    @IBOutlet weak var increaseBtn: UIButton!
    @IBOutlet weak var decreaseBtn: UIButton!
    @IBOutlet weak var timeCollectionView: UICollectionView!
    @IBOutlet weak var timeCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var selectedTimeLbl: UILabel!
    @IBOutlet weak var timeCollectionViewParentView: UIView!
    @IBOutlet weak var inquireView: UIView!
    @IBOutlet weak var conitnueToCheckOutBtn: UIButton!
    @IBOutlet weak var viewMoreBtnView: UIView!
    @IBOutlet weak var viewMoreBtn: UIButton!
    @IBOutlet weak var timeZoneView: UIView!
    
    var seatingArea: SeatingArea?
    var event: Event?
    private var currentGuestCount: Int = 1
    private var timeSlots: [String] = []
    private var selectedIndex: Int = 0
    private var isExpanded = false
    private let collapsedLines = 3
    private var selectedSlot: TableTimeSlot?
    var onSelectionUpdate: ((_ time: String,
                             _ guestCount: Int,
                             _ seatingArea: SeatingArea?,
                             _ event: Event?) -> Void)?
    
    let infoTextAttributes: [NSAttributedString.Key: Any] = [
        .font: AppFont.font(weight: .regular, size: 12),
        .foregroundColor: UIColor(hex: "#D2D5DB")
    ]
    
    func makeIconAttachment(systemName: String) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: systemName)?
            .withTintColor(UIColor(hex: "#D2D5DB"), renderingMode: .alwaysOriginal)

        attachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        return attachment
    }
    
    private var collectionObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        configureData()
        observeCollectionHeight()
    }
    
    private func setupCollectionView() {

        timeCollectionView.register(TimeTagCVC.self,
                                    forCellWithReuseIdentifier: TimeTagCVC.identifier)

        timeCollectionView.delegate = self
        timeCollectionView.dataSource = self
        timeCollectionView.isScrollEnabled = false

        if let layout = timeCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 8
            layout.minimumInteritemSpacing = 8
        }
        
        if !timeSlots.isEmpty {
            selectedIndex = 0
            selectedTimeLbl.text = timeSlots[0]
          
        }
        updatePricing(for: 0)
    }
    
    func updatePricing(for index: Int) {

        guard let item = seatingArea else { return }
        let feesSettings = event?.venue?.venueSettings?.tableBookingSettings

        if item.hidePricing == true {
            miniMumAmountLbl.text = ""
            feesLbl.text = ""
            return
        }

        var minValue: Double = 0
        var baseDeposit: Double = 0
        var depositType: String = "FLAT"

        // ✅ Handle slot + fallback properly
        if item.bookingType == .timeWise,
           let slots = item.timeSlots,
           !slots.isEmpty,
           slots.indices.contains(index) {

            let slot = slots[index]

            minValue = Double(slot.minimum ?? item.minimum ?? 0)
            baseDeposit = Double(slot.deposit ?? item.deposit ?? 0)
            depositType = slot.depositType ?? item.depositType ?? "FLAT"

        } else {

            minValue = Double(item.minimum ?? 0)
            baseDeposit = Double(item.deposit ?? 0)
            depositType = item.depositType ?? "FLAT"
        }

        // 🔥 Fix 0000 case (fallback if still zero)
        if (minValue == 0 || baseDeposit == 0),
           let firstSlot = item.timeSlots?.first {

            minValue = Double(firstSlot.minimum ?? minValue)
            baseDeposit = Double(firstSlot.deposit ?? baseDeposit)
            depositType = firstSlot.depositType ?? depositType
        }

        // ✅ Step 1: Calculate deposit
        let depositValue: Double
        if depositType.uppercased() == "PERCENTAGE" {
            depositValue = (minValue * baseDeposit) / 100
        } else {
            depositValue = baseDeposit
        }

        // ✅ Step 2: Apply fees
        let finalDeposit = calculateFinalDeposit(
            deposit: depositValue,
            fees: feesSettings
        )

        // ✅ UI
        miniMumAmountLbl.text = "$\(Int(minValue)) min."
        feesLbl.text = "$\(String(format: "%.2f", finalDeposit))"
    }
    
    func calculateFinalDeposit(
        deposit: Double,
        fees: TableBookingSettings?
    ) -> Double {

        guard let fees = fees else { return deposit }

        var taxableFees = 0.0
        var nonTaxableFees = 0.0

        fees.customFees?.forEach { fee in

            // ✅ FIX: match web exactly
            guard fee.isEnableCustomFee == true else { return }

            let value: Double

            if fee.customFeeType?.uppercased() == "FLAT" {
                value = fee.customFee ?? 0
            } else {
                value = deposit * (fee.customFee ?? 0) / 100
            }

            if fee.isCustomFeeTaxable == true {
                taxableFees += value
            } else {
                nonTaxableFees += value
            }
        }

        // ✅ TAX only on taxable parts
        var tax = 0.0

        if fees.isEnableSalesTax == true {
            let taxRate = (fees.salesTax ?? 0) / 100
            tax = (deposit + taxableFees) * taxRate
        }

        // ✅ WEB FINAL
        let amountChargedToConsumer =
            deposit +
            taxableFees +
            nonTaxableFees +
            tax

        let finalDeposit = amountChargedToConsumer - tax

        return finalDeposit
    }
    
    private func observeCollectionHeight() {

        collectionObserver = timeCollectionView.observe(\.contentSize,
                                                          options: [.new]) { [weak self] collection, _ in
            guard let self = self else { return }
            self.timeCollectionViewHeight.constant = collection.contentSize.height
        }
    }
    
    private func formatTime(_ time: String?) -> String {
        guard let time,
              let date = time.dateFormatter(
                formate: .yyyyMMddTHHmmssSSSz,
                isTimeZoneChanged: true,
                isUTC: false
              )
        else { return "" }

        let venueTZ = TimeZone(identifier: event?.venue?.useTimezone ?? "") ?? .current
        return date.toString(dateFormat: .hmma, timeZone: venueTZ)
    }

    private func configureData() {
        guard let item = seatingArea else { return }

//        let venueTimeZone = event?.venue?.timezone ?? event?.venue?.useTimezone ?? TimeZone.current.identifier

        tableName.text = item.name
        tableDetailLbl.text = item.highlight?.isEmpty == false
            ? item.highlight
            : item.description

        currentGuestCount = item.defaultGuest ?? 1
        maxiMumGuestLbl.text = "\(currentGuestCount)"
        updateGuestButtons()

        let minGuest = item.defaultGuest ?? 0
        let maxGuest = item.maxGuest ?? 0

        let guestsText: String = {
            if minGuest > 0 && maxGuest > 0 {
                return minGuest == maxGuest
                    ? "\(minGuest) Guests"
                    : "\(minGuest) to \(maxGuest) Guests"
            } else if maxGuest > 0 {
                return "\(maxGuest) Guests"
            } else {
                return "Guests"
            }
        }()

        inquireView.isHidden = !(item.inquiryEnabled ?? false)

        tableDescriptionLbl.text = item.description
        tableDescriptionLbl.numberOfLines = collapsedLines
        viewMoreBtn.setTitle("View More", for: .normal)

        view.layoutIfNeeded()
        checkIfTextNeedsExpansion()

        if item.bookingType == .timeWise {
            timeZoneView.isHidden = false
            timeCollectionViewParentView.isHidden = false

            let venueTZ = TimeZone(identifier: event?.venue?.useTimezone ?? "") ?? .current

            let availableSlots = (item.timeSlots ?? []).filter { slot in
                let issued = slot.issuedPublicInventory ?? 0
                let sold = slot.soldPublicInventory ?? 0
                return issued > sold
            }

            if !availableSlots.isEmpty {

                let sortedSlots = availableSlots.sorted { lhs, rhs in
                    (lhs.startTime ?? "") < (rhs.startTime ?? "")
                }

                if let firstSlot = sortedSlots.first,
                   let start = firstSlot.startTime,
                   let startDate = start.dateFormatter(
                        formate: .yyyyMMddTHHmmssSSSz,
                        isTimeZoneChanged: true,
                        isUTC: false
                   ) {
                    let startTime = startDate.toString(
                        dateFormat: .hmma,
                        timeZone: venueTZ
                    )

                    var finalTime = startTime

                    if let lastSlot = sortedSlots.last,
                       let end = lastSlot.endTime,
                       let endDate = end.dateFormatter(
                            formate: .yyyyMMddTHHmmssSSSz,
                            isTimeZoneChanged: true,
                            isUTC: false
                       ) {

                        let endTime = endDate.toString(
                            dateFormat: .hmma,
                            timeZone: venueTZ
                        )

                        finalTime = "\(startTime) - \(endTime)"
                    }

                    guestAndTimeLbl.attributedText = buildGuestsTimeText(
                        guests: guestsText,
                        time: finalTime
                    )

                } else {

                    guestAndTimeLbl.attributedText = buildGuestsTimeText(
                        guests: guestsText,
                        time: ""
                    )
                }

                // ✅ time slots also in venue timezone
                timeSlots = sortedSlots.compactMap { slot in
                    guard let start = slot.startTime,
                          let startDate = start.dateFormatter(
                                formate: .yyyyMMddTHHmmssSSSz,
                                isTimeZoneChanged: true,
                                isUTC: false
                          )
                    else { return nil }

                    return startDate.toString(
                        dateFormat: .hmma,
                        timeZone: venueTZ
                    )
                }

                if !timeSlots.isEmpty {
                    selectedIndex = 0
                    selectedSlot = sortedSlots[0]
                    selectedTimeLbl.text = formatTime(selectedSlot?.startTime)
                    timeCollectionView.isHidden = false
                    timeCollectionView.reloadData()
                    timeCollectionView.collectionViewLayout.invalidateLayout()
                    timeCollectionView.layoutIfNeeded()
                } else {
                    selectedIndex = 0
                    selectedSlot = nil
                    selectedTimeLbl.text = ""
                    timeCollectionView.isHidden = true
                }

            } else {

                guestAndTimeLbl.attributedText = buildGuestsTimeText(
                    guests: guestsText,
                    time: ""
                )

                timeSlots = []
                selectedIndex = 0
                selectedTimeLbl.text = ""
                timeCollectionView.isHidden = true
            }
        } else {
            timeCollectionViewParentView.isHidden = true
            timeZoneView.isHidden = true
            timeSlots = []
            selectedIndex = 0
            selectedTimeLbl.text = ""

            guestAndTimeLbl.attributedText = buildGuestsTimeText(
                guests: guestsText,
                time: ""
            )
        }

        if let hex = event?.whiteLabelColor {
            let color = UIColor(hex: hex)
            conitnueToCheckOutBtn.backgroundColor = color
        }
    }
    
    func buildGuestsTimeText(
        guests: String,
        time: String
    ) -> NSAttributedString {

        let text = NSMutableAttributedString()
        text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "person.2")))
        text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))
        text.append(NSAttributedString(string: guests, attributes: infoTextAttributes))
        text.append(NSAttributedString(string: "  ", attributes: infoTextAttributes))
        if !time.isEmpty {
            text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "clock")))
        }
        text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))
        text.append(NSAttributedString(string: time, attributes: infoTextAttributes))

        return text
    }

    private func updateGuestButtons() {

        guard let maxGuest = seatingArea?.maxGuest else { return }

        increaseBtn.isEnabled = currentGuestCount < maxGuest
        increaseBtn.alpha = increaseBtn.isEnabled ? 1 : 0.5

        decreaseBtn.isEnabled = currentGuestCount > 1
        decreaseBtn.alpha = decreaseBtn.isEnabled ? 1 : 0.5
    }
    
    private func checkIfTextNeedsExpansion() {
        tableDescriptionLbl.numberOfLines = 0

        let fullHeight = tableDescriptionLbl.sizeThatFits(
            CGSize(width: tableDescriptionLbl.frame.width,
                   height: CGFloat.greatestFiniteMagnitude)
        ).height

        let maxCollapsedHeight = tableDescriptionLbl.font.lineHeight * CGFloat(collapsedLines)

        if fullHeight > maxCollapsedHeight {
            tableDescriptionLbl.numberOfLines = collapsedLines
            viewMoreBtnView.isHidden = false
        } else {
            tableDescriptionLbl.numberOfLines = 0
            viewMoreBtnView.isHidden = true
        }
    }

    // MARK: - Actions

    @IBAction func onClickIncreaseGuest(_ sender: Any) {
        guard let maxGuest = seatingArea?.maxGuest else { return }

        if currentGuestCount < maxGuest {
            currentGuestCount += 1
            maxiMumGuestLbl.text = "\(currentGuestCount)"
        }
        updateGuestButtons()
    }

    @IBAction func onClickDecreaseGuest(_ sender: Any) {
        if currentGuestCount > 1 {
            currentGuestCount -= 1
            maxiMumGuestLbl.text = "\(currentGuestCount)"
        }
        updateGuestButtons()
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        dismiss(animated: false)
    }

    @IBAction func onClickOutSide(_ sender: Any) {
        dismiss(animated: false)
    }
    
    @IBAction func onClickCheckOutBtn(_ sender: Any) {
        let selectedTime = selectedSlot?.id ?? ""

        self.dismiss(animated: true)
           onSelectionUpdate?(selectedTime,
                              currentGuestCount,
                              seatingArea,
                              event)
    }
    
    @IBAction func onClickViewMoreBtn(_ sender: Any) {
        isExpanded.toggle()

        if isExpanded {
            tableDescriptionLbl.numberOfLines = 0
            viewMoreBtn.setTitle("View Less", for: .normal)
        } else {
            tableDescriptionLbl.numberOfLines = collapsedLines
            viewMoreBtn.setTitle("View More", for: .normal)
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
}

extension TableSeatingViewController: UICollectionViewDelegate,
                                      UICollectionViewDataSource,
                                      UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return timeSlots.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TimeTagCVC.identifier,
            for: indexPath
        ) as? TimeTagCVC else {
            return UICollectionViewCell()
        }

        let text = timeSlots[indexPath.item]

        var selectedColor: UIColor?
        if let hex = event?.whiteLabelColor {
            selectedColor = UIColor(hex: hex)
        }

        cell.configure(
            with: text,
            isSelected: indexPath.item == selectedIndex,
            selectedColor: selectedColor
        )

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard timeSlots.indices.contains(indexPath.item) else { return }
        selectedIndex = indexPath.item
        selectedSlot = seatingArea?.timeSlots?[indexPath.item]
        selectedTimeLbl.text = timeSlots[indexPath.item]
        updatePricing(for: indexPath.item)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let text = timeSlots[indexPath.item]
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let textWidth = text.size(withAttributes: [.font: font]).width

        let padding: CGFloat = 32
        let width = textWidth + padding

        return CGSize(width: width, height: 32)
    }
}

final class TimeTagCVC: UICollectionViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Constant.Font.interMedium(size: 12)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {

        backgroundColor = .white
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with text: String, isSelected: Bool, selectedColor: UIColor?) {
        
        titleLabel.text = text
        
        if isSelected {
            backgroundColor = selectedColor ?? UIColor(hex: "#7C3AED")
            titleLabel.textColor = .white
        } else {
            backgroundColor = .white
            titleLabel.textColor = .black
        }
    }
}
