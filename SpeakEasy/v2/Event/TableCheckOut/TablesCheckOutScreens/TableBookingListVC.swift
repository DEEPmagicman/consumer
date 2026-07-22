// swiftlint: disable all

import UIKit

class TableBookingListVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var seatingAreas: [SeatingArea] = []
    var seatingAreasFilteredOut: [SeatingArea] = []
    var event: Event?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        tableView.reloadData()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TableListTVC.nib, forCellReuseIdentifier: TableListTVC.identifier)
    }

    // MARK: - HELPERS

    private func formatGuestCount(min: Int, max: Int) -> String {
        if min > 0 && max > 0 {
            return min == max ? "\(min) Guests" : "\(min) to \(max) Guests"
        } else if max > 0 {
            return "\(max) Guests"
        }
        return "Guests"
    }

    private func getLowestPricedAvailableSlot(for area: SeatingArea) -> (min: Double, deposit: Double)? {

        let fees = event?.venue?.venueSettings?.tableBookingSettings

        // ✅ NON-TIMEWISE (FIX 0000 + consistency)
        if area.bookingType != .timeWise {

            let min = Double(area.minimum ?? 0)

            let baseDeposit: Double
            if (area.depositType ?? "").uppercased() == "PERCENTAGE" {
                baseDeposit = (min * Double(area.deposit ?? 0)) / 100
            } else {
                baseDeposit = Double(area.deposit ?? 0)
            }

            let final = calculateFinalDeposit(deposit: baseDeposit, fees: fees)

            return (min, final)
        }

        // ✅ TIMEWISE
        let availableSlots = (area.timeSlots ?? []).filter {
            ($0.issuedPublicInventory ?? 0) > ($0.soldPublicInventory ?? 0)
        }

        guard let slot = availableSlots
            .sorted(by: { ($0.minimum ?? 0) < ($1.minimum ?? 0) })
            .first else {

            // 🔥 fallback (fix 0000)
            let min = Double(area.minimum ?? 0)
            let baseDeposit = Double(area.deposit ?? 0)
            let final = calculateFinalDeposit(deposit: baseDeposit, fees: fees)
            return (min, final)
        }

        let min = Double(slot.minimum ?? area.minimum ?? 0)

        let baseDeposit: Double
        if (slot.depositType ?? "").uppercased() == "PERCENTAGE" {
            baseDeposit = (min * Double(slot.deposit ?? 0)) / 100
        } else {
            baseDeposit = Double(slot.deposit ?? 0)
        }

        let final = calculateFinalDeposit(deposit: baseDeposit, fees: fees)

        return (min, final)
    }

    private func getAvailableTimeRange(for area: SeatingArea) -> String {

        guard area.bookingType == .timeWise else { return "" }

        let timezone = event?.venue?.timezone
            ?? event?.venue?.useTimezone
            ?? TimeZone.current.identifier

        let venueTZ = TimeZone(identifier: timezone)

        let slots = (area.timeSlots ?? [])
            .sorted { ($0.startTime ?? "") < ($1.startTime ?? "") }

        guard let first = slots.first,
              let start = first.startTime,
              let startDate = start.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: false)
        else { return "" }

        let startText = startDate.toString(dateFormat: .hmma, timeZone: venueTZ)

        if let last = slots.last,
           let end = last.startTime,
           let endDate = end.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: false) {

            let endText = endDate.toString(dateFormat: .hmma, timeZone: venueTZ)

            if startText == endText {
                return startText
            }

            return "\(startText) - \(endText)"
        }

        return startText
    }
    
    func calculateFinalDeposit(
        deposit: Double,
        fees: TableBookingSettings?
    ) -> Double {

        guard let fees = fees else { return deposit }
        var taxableFees = 0.0
        var nonTaxableFees = 0.0

        fees.customFees?.forEach { fee in
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

        var tax = 0.0

        if fees.isEnableSalesTax == true {
            let taxRate = (fees.salesTax ?? 0) / 100
            tax = (deposit + taxableFees) * taxRate
        }

        let amountChargedToConsumer =
            deposit +
            taxableFees +
            nonTaxableFees +
            tax
        let finalDeposit = amountChargedToConsumer - tax

        return finalDeposit
    }

    private func openSeatingArea(_ item: SeatingArea) {

        guard item.hideCheckout != true else {
            print("Inquire tapped for:", item.name ?? "")
            return
        }

        Navigate.to.tableSeatingVC(self, seatingArea: item, event: event) { [weak self] time, guestCount, _, _ in
            
            guard let self = self else { return }
            let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            let queueId = "TABLE_BOOKING_QUEUE_\(uuid)"
            let selectedSlot = (item.timeSlots ?? []).first { $0.id == time }
            let defaultGuests = item.defaultGuest ?? 0
            let extraGuests = max(0, guestCount - defaultGuests)
            let baseMinimum = item.bookingType == .timeWise
                ? selectedSlot?.minimum ?? item.minimum ?? 0
                : item.minimum ?? 0
            let extraCharge = item.bookingType == .timeWise
                ? selectedSlot?.extraPersonCharge ?? item.extraPersonCharge ?? 0
                : item.extraPersonCharge ?? 0
            let mininumSpend = baseMinimum + Double(extraGuests) * extraCharge

            TablePresenter.createSeatingAreaBooking(
                eventId: self.event?.id ?? "",
                seatingAreaId: item.id ?? "",
                timeSlotId: item.bookingType == .default ? nil : time,
                venueId: event?.venue?.id ?? "",
                guests: guestCount,
                queueId: queueId,
                consumerUserId: UserDefault.shared.user?.id ?? "",
                mininumSpend: mininumSpend
            ) { isSuccess, errMsg, _ in
                
                if isSuccess {
                    if let event = self.event {
                        Navigate.to.tablePurchaseVC(self, queueId: queueId, event: event, seatingAreas: self.seatingAreas)
                    }
                } else {
                    print(errMsg ?? "Booking failed")
                }
            }

            print("Queue ID:", queueId)
            print("Guest Count:", guestCount)
        }
    }

    private func convertPriceFormat(_ amount: Double?, _ currencyCode: String?) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode ?? "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount ?? 0)) ?? "$0"
    }
}

// MARK: - TABLE

extension TableBookingListVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return seatingAreasFilteredOut.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: TableListTVC = tableView.dequeue(
            withIdentifier: TableListTVC.identifier,
            for: indexPath
        )

        cell.selectionStyle = .none

        let item = seatingAreasFilteredOut[indexPath.row]

        let isInquiry = item.inquiryEnabled == true && item.hideCheckout == true
        let hidePricing = isInquiry && item.hidePricing == true

        let guestsText = formatGuestCount(
            min: item.defaultGuest ?? 0,
            max: item.maxGuest ?? 0
        )

        let timeText = item.bookingType == .timeWise
            ? getAvailableTimeRange(for: item)
            : ""

        let values = getLowestPricedAvailableSlot(for: item)

        let depositText = hidePricing ? "" :
            convertPriceFormat(values?.deposit, event?.venue?.venueSettings?.currencyCode)

        let minimumText = hidePricing ? "" :
            (values?.min != nil
             ? "\(convertPriceFormat(values?.min, event?.venue?.venueSettings?.currencyCode)) min."
             : "")

        cell.configure(
            name: item.name ?? "",
            depositText: depositText,
            minimumText: minimumText,
            guestsText: guestsText,
            timeText: timeText,
            descriptionText: item.highlight?.isEmpty == false ? (item.highlight ?? "") : (item.description ?? ""),
            buttonTitle: isInquiry ? "Inquire" : "Book",
            hidePricing: hidePricing
        )

        cell.onBookTap = { [weak self] in
            self?.openSeatingArea(item)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openSeatingArea(seatingAreasFilteredOut[indexPath.row])
    }
}
