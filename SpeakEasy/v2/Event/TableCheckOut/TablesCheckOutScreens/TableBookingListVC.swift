// swiftlint: disable all

import UIKit

class TableBookingListVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var seatingAreas: [SeatingArea] = []
    var seatingAreasFilteredOut: [SeatingArea] = []
    var event: Event?
    var skip: Int = 0
    var hasMore: Bool = true
    var isLoading: Bool = false
    private var showShimmer = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchSeatingAreas()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TableListTVC.nib, forCellReuseIdentifier: TableListTVC.identifier)
    }

    private func fetchSeatingAreas() {
        guard !isLoading, hasMore else { return }

        isLoading = true

        TablePresenter.getSeatingAreas(
            eventId: event?.id ?? "",
            skip: skip
        ) { [weak self] isSuccess, errMsg, list, apiHasMore in

            guard let self else { return }

            self.isLoading = false
            self.showShimmer = false

            if isSuccess {
                let filtered = self.filterSeatingAreas(list)

                self.seatingAreas.append(contentsOf: filtered.visible)
                self.seatingAreasFilteredOut.append(contentsOf: filtered.filteredOut)

                self.hasMore = apiHasMore
                self.skip += list.count

            } else {
                print(errMsg ?? "Error fetching seating areas")
            }

            self.tableView.reloadData()
        }
    }

    // MARK: - FILTER

    private func filterSeatingAreas(_ list: [SeatingArea]) -> (visible: [SeatingArea], filteredOut: [SeatingArea]) {

        let timezone = event?.venue?.timezone
            ?? event?.venue?.useTimezone
            ?? TimeZone.current.identifier

        var visible: [SeatingArea] = []
        var filteredOut: [SeatingArea] = []

        list.forEach { item in
            let conditions = checkTicketConditions(item, timezone: timezone)

            let isValid =
                conditions.isEnabled &&
                !conditions.isFutureTicket &&
                !conditions.isSoldOut &&
                !conditions.isPaused &&
                !conditions.isSaleEnded
            if isValid {
                visible.append(item)
            } else {
                filteredOut.append(item)
            }
        }

        return (visible, filteredOut)
    }

    // MARK: - CONDITIONS

    private func checkTicketConditions(
        _ area: SeatingArea,
        timezone: String
    ) -> (
        isFutureTicket: Bool,
        isSaleEnded: Bool,
        isSoldOut: Bool,
        isPaused: Bool,
        isEnabled: Bool
    ) {

        let now = Date.venueNow(timezone: timezone)

        let beginSale = area.beginSale?.toVenueDate(timezone: timezone)
        let endSale = area.endSale?.toVenueDate(timezone: timezone)

        let isFutureTicket = beginSale.map { $0 > now } ?? false
        let isSaleEnded = endSale.map { $0 < now } ?? false

        let baseSoldOut =
            (area.issuedPublicInventory ?? 0) <= (area.soldPublicInventory ?? 0)

        let isSoldOut: Bool = {
            if area.bookingType == .timeWise {
                let slots = area.timeSlots ?? []
                return slots.isEmpty ? baseSoldOut : slots.allSatisfy {
                    ($0.issuedPublicInventory ?? 0) <= ($0.soldPublicInventory ?? 0)
                }
            }
            return baseSoldOut
        }()

        let status = area.status?.uppercased() ?? ""
        let isPaused = status == "DISABLED"
        let isEnabled = status == "ENABLED"

        return (isFutureTicket, isSaleEnded, isSoldOut, isPaused, isEnabled)
    }

    private func formatGuestCount(min: Int, max: Int) -> String {
        if min > 0 && max > 0 {
            return min == max ? "\(min) Guests" : "\(min) to \(max) Guests"
        } else if max > 0 {
            return "\(max) Guests"
        }
        return "Guests"
    }

    private func getLowestPricedAvailableSlot(for area: SeatingArea) -> (min: Double, deposit: Double)? {

        guard area.bookingType == .timeWise else { return
            
            (Double(area.minimum ?? 0), Double(area.depositWithFees ?? 0)) }

        let availableSlots = (area.timeSlots ?? []).filter {
            ($0.issuedPublicInventory ?? 0) > ($0.soldPublicInventory ?? 0)
        }

        guard let slot = availableSlots.sorted(by: { ($0.minimum ?? 0) < ($1.minimum ?? 0) }).first else {
            return nil
        }

        let min = Double(slot.minimum ?? 0)
        

        let deposit: Double =
            (slot.depositType ?? "").uppercased() == "PERCENTAGE"
            ? (min * Double(slot.deposit ?? 0)) / 100
            : Double(slot.depositWithFees ?? slot.deposit ?? 0)
        
        let taxPercent = 16.76
        let final = deposit + (deposit * taxPercent / 100)

        return (min, final)
    }

    private func getAvailableTimeRange(for area: SeatingArea) -> String {

        guard area.bookingType == .timeWise else { return "" }

        let timezone = event?.venue?.timezone
            ?? event?.venue?.useTimezone
            ?? TimeZone.current.identifier

        let venueTZ = TimeZone(identifier: timezone)

        let slots = (area.timeSlots ?? [])
//            .filter { ($0.issuedPublicInventory ?? 0) > ($0.soldPublicInventory ?? 0) }
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

    private func openSeatingArea(_ item: SeatingArea) {

        guard item.hideCheckout != true else {
            print("Inquire tapped for:", item.name ?? "")
            return
        }

        Navigate.to.tableSeatingVC(self, seatingArea: item, event: event) { [weak self] time, guestCount, _, _ in
            
            guard let self = self else { return }
            let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            let queueId = "TABLE_BOOKING_QUEUE_\(uuid)"

            TablePresenter.createSeatingAreaBooking(
                eventId: self.event?.id ?? "",
                seatingAreaId: item.id ?? "",
                timeSlotId: item.bookingType == .default ? nil : time,
                venueId: event?.venue?.id ?? "",
                guests: guestCount,
                queueId: queueId
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
        return showShimmer ? 6 : seatingAreas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: TableListTVC = tableView.dequeue(
            withIdentifier: TableListTVC.identifier,
            for: indexPath
        )

        cell.selectionStyle = .none

        if showShimmer {
            cell.startShimmer()
            return cell
        }

        cell.stopShimmer()

        let item = seatingAreas[indexPath.row]

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

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !showShimmer && indexPath.row == seatingAreas.count - 1 {
            fetchSeatingAreas()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !showShimmer else { return }
        openSeatingArea(seatingAreas[indexPath.row])
    }
}
