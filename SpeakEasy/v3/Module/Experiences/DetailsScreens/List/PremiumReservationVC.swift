//
//  PremiumReservationVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

final class PremiumReservationVC: UIViewController {

    // MARK: Views

    private let tableView = UITableView(
        frame: .zero,
        style: .plain
    )

    private let refreshControl = UIRefreshControl()

    private let emptyView = UIView()

    private let emptyTitleLabel = UILabel()

    private let emptySubtitleLabel = UILabel()

    // MARK: Data

    var event: Event?

    var seatingAreas: [SeatingArea] = [] {
        didSet {
            filteredAreas = seatingAreas

            isInitialLoading = false
            isLoading = false
            isPaginating = false
            hasMore = false

            refreshControl.endRefreshing()

            reloadUI()
        }
    }
    
    private var filteredAreas: [SeatingArea] = []

    // MARK: Loading

    private var isInitialLoading = true

    private var isLoading = false

    private var isPaginating = false

    private var hasMore = false

    private var page = 1

    private let pageSize = 20

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
}

private extension PremiumReservationVC {

    func setupUI() {

        view.backgroundColor = .clear

        setupTableView()

        setupEmptyView()

        setupConstraints()
    }
}

private extension PremiumReservationVC {

    func setupTableView() {

        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.backgroundColor = .clear

        tableView.separatorStyle = .none

        tableView.showsVerticalScrollIndicator = false

        tableView.alwaysBounceVertical = true

        tableView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: 40,
            right: 0
        )

        tableView.delegate = self

        tableView.dataSource = self

        tableView.prefetchDataSource = self

        tableView.estimatedRowHeight = 178

        tableView.rowHeight = UITableView.automaticDimension

        tableView.register(
            PremiumReservationCell.self,
            forCellReuseIdentifier: PremiumReservationCell.identifier
        )

        tableView.register(
            PremiumReservationShimmerCell.self,
            forCellReuseIdentifier: PremiumReservationShimmerCell.identifier
        )

        tableView.register(
            PremiumReservationPaginationFooter.self,
            forHeaderFooterViewReuseIdentifier: PremiumReservationPaginationFooter.identifier
        )

        refreshControl.tintColor = AppColor.primaryWhiteColor.withAlphaComponent(0.8)

        refreshControl.addTarget(
            self,
            action: #selector(onRefresh),
            for: .valueChanged
        )

        tableView.refreshControl = refreshControl

        view.addSubview(tableView)
    }
}

private extension PremiumReservationVC {

    private func setupEmptyView() {

        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true

        view.addSubview(emptyView)

        let title = UILabel()
        title.text = "No reservations available"

        title.font =
            Constant.Font.geistMedium(size: 18)

        title.textColor =
            AppColor.primaryWhiteColor

        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()

        subtitle.text =
            "Reservations will appear here."

        subtitle.font =
            Constant.Font.geistRegular(size: 14)

        subtitle.textColor =
            UIColor.white.withAlphaComponent(0.6)

        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(
            arrangedSubviews: [
                title,
                subtitle
            ]
        )

        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        emptyView.addSubview(stack)

        NSLayoutConstraint.activate([

            emptyView.topAnchor.constraint(
                equalTo: tableView.topAnchor
            ),

            emptyView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),

            emptyView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),

            emptyView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),

            stack.centerXAnchor.constraint(
                equalTo: emptyView.centerXAnchor
            ),

            stack.centerYAnchor.constraint(
                equalTo: emptyView.centerYAnchor,
                constant: -60
            )
        ])
    }
}

private extension PremiumReservationVC {

    func setupConstraints() {

        NSLayoutConstraint.activate([

            tableView.topAnchor.constraint(equalTo: view.topAnchor),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.topAnchor.constraint(equalTo: view.topAnchor),

            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        ])
    }
}

private extension PremiumReservationVC {

    @objc
    func onRefresh() {

        refreshControl.endRefreshing()
    }
}

private extension PremiumReservationVC {

    func reloadUI() {

        updateEmptyState()

        UIView.performWithoutAnimation {

            tableView.reloadData()
            tableView.layoutIfNeeded()
        }
    }
}

private extension PremiumReservationVC {

    func updateEmptyState() {

        let empty = !isInitialLoading && filteredAreas.isEmpty

        emptyView.isHidden = !empty
        tableView.isHidden = empty
    }
}

private extension PremiumReservationVC {

    func loadNextPageIfNeeded() {

        guard !isInitialLoading else { return }

        guard !isPaginating else { return }

        guard hasMore else { return }

        isPaginating = true

        tableView.reloadSections(
            IndexSet(integer: 0),
            with: .none
        )

        page += 1
    }
}

extension PremiumReservationVC: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {

        isInitialLoading
        ? 6
        : filteredAreas.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        if isInitialLoading {

            return tableView.dequeueReusableCell(
                withIdentifier: PremiumReservationShimmerCell.identifier,
                for: indexPath
            )
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: PremiumReservationCell.identifier,
            for: indexPath
        ) as! PremiumReservationCell

        let item = filteredAreas[indexPath.row]

        configure(
            cell: cell,
            with: item
        )

        return cell
    }
}

extension PremiumReservationVC: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        guard !isInitialLoading else {
            return
        }

        openSeatingArea(
            filteredAreas[indexPath.row]
        )
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {

        isInitialLoading
        ? 190
        : UITableView.automaticDimension
    }
}

extension PremiumReservationVC {

    func tableView(
        _ tableView: UITableView,
        viewForFooterInSection section: Int
    ) -> UIView? {

        guard isPaginating else {
            return nil
        }

        return tableView.dequeueReusableHeaderFooterView(
            withIdentifier: PremiumReservationPaginationFooter.identifier
        )
    }

    func tableView(
        _ tableView: UITableView,
        heightForFooterInSection section: Int
    ) -> CGFloat {

        isPaginating
        ? 320
        : .leastNormalMagnitude
    }
}

extension PremiumReservationVC: UITableViewDataSourcePrefetching {

    func tableView(
        _ tableView: UITableView,
        prefetchRowsAt indexPaths: [IndexPath]
    ) {

        guard !isInitialLoading else {
            return
        }

        if indexPaths.contains(where: {

            $0.row >= filteredAreas.count - 3

        }) {

            loadNextPageIfNeeded()
        }
    }
}

private extension PremiumReservationVC {

    func formatGuestCount(
        min: Int,
        max: Int
    ) -> String {

        if min > 0 && max > 0 {

            return min == max
            ? "\(min) Guests"
            : "\(min)-\(max) guests"

        } else if max > 0 {

            return "\(max) Guests"
        }

        return "Guests"
    }
}

private extension PremiumReservationVC {

    func getAvailableTimeRange(
        for area: SeatingArea
    ) -> String {

        guard area.bookingType == .timeWise else {
            return ""
        }

        let timezone =
            event?.venue?.timezone ??
            event?.venue?.useTimezone ??
            TimeZone.current.identifier

        let venueTimeZone = TimeZone(identifier: timezone)

        let slots = (area.timeSlots ?? [])
            .sorted {
                ($0.startTime ?? "") <
                ($1.startTime ?? "")
            }

        guard
            let first = slots.first,
            let start = first.startTime,
            let startDate = start.dateFormatter(
                formate: .yyyyMMddTHHmmssSSSz,
                isUTC: false
            )
        else {
            return ""
        }

        let startText = startDate.toString(
            dateFormat: .hmma,
            timeZone: venueTimeZone
        )

        guard
            let last = slots.last,
            let end = last.startTime,
            let endDate = end.dateFormatter(
                formate: .yyyyMMddTHHmmssSSSz,
                isUTC: false
            )
        else {
            return startText
        }

        let endText = endDate.toString(
            dateFormat: .hmma,
            timeZone: venueTimeZone
        )

        if startText == endText {
            return startText
        }

        return "\(startText) - \(endText)"
    }
}

private extension PremiumReservationVC {

    func getLowestPricedAvailableSlot(
        for area: SeatingArea
    ) -> (
        minimum: Double,
        deposit: Double
    )? {

        let fees = event?
            .venue?
            .venueSettings?
            .tableBookingSettings

        if area.bookingType != .timeWise {

            let minimum = Double(area.minimum ?? 0)

            let deposit: Double

            if (area.depositType ?? "")
                .uppercased() == "PERCENTAGE" {

                deposit =
                    minimum *
                    Double(area.deposit ?? 0) /
                    100

            } else {

                deposit = Double(area.deposit ?? 0)
            }

            return (
                minimum,
                calculateFinalDeposit(
                    deposit: deposit,
                    fees: fees
                )
            )
        }

        let availableSlots = (area.timeSlots ?? []).filter {

            ($0.issuedPublicInventory ?? 0) >
            ($0.soldPublicInventory ?? 0)
        }

        guard let slot = availableSlots
            .sorted(by: {

                ($0.minimum ?? 0) <
                ($1.minimum ?? 0)

            }).first else {

            let minimum = Double(area.minimum ?? 0)

            let deposit: Double

            if (area.depositType ?? "")
                .uppercased() == "PERCENTAGE" {

                deposit =
                    minimum *
                    Double(area.deposit ?? 0) /
                    100

            } else {

                deposit = Double(area.deposit ?? 0)
            }

            return (
                minimum,
                calculateFinalDeposit(
                    deposit: deposit,
                    fees: fees
                )
            )
        }

        let minimum = Double(
            slot.minimum ??
            area.minimum ??
            0
        )

        let deposit: Double

        let depositType = slot.depositType ?? area.depositType ?? "FLAT"

        if depositType
            .uppercased() == "PERCENTAGE" {

            deposit =
                minimum *
                Double(slot.deposit ?? area.deposit ?? 0) /
                100

        } else {

            deposit = Double(slot.deposit ?? area.deposit ?? 0)
        }

        return (
            minimum,
            calculateFinalDeposit(
                deposit: deposit,
                fees: fees
            )
        )
    }
}

private extension PremiumReservationVC {

    func guestCharge(
        for area: SeatingArea
    ) -> Double {

        if area.bookingType == .timeWise {

            let charges = (area.timeSlots ?? [])
                .filter {

                    ($0.issuedPublicInventory ?? 0) >
                    ($0.soldPublicInventory ?? 0)
                }
                .compactMap {

                    $0.extraPersonCharge
                }

            if !charges.isEmpty {
                return charges.reduce(0, +)
            }
        }

        return area.extraPersonCharge ?? 0
    }

    func calculateFinalDeposit(
        deposit: Double,
        fees: TableBookingSettings?
    ) -> Double {

        guard let fees else {
            return deposit
        }

        let customFees = calculatedCustomFees(
            deposit: deposit,
            fees: fees
        )
        let taxable = customFees
            .filter(\.isTaxable)
            .reduce(0) { $0 + $1.amount }
        let nonTaxable = customFees
            .filter { !$0.isTaxable }
            .reduce(0) { $0 + $1.amount }
        let speakeasyFee = calculateSEFees(
            deposit: deposit,
            fees: fees
        ) / 100
        let stripePerc = fees.stripePerc ?? 0.029
        let stripeFlat = (fees.stripeFlat ?? 30) / 100
        let taxRate = fees.isEnableSalesTax == true
            ? (fees.salesTax ?? 0) / 100
            : 0

        func rounded2(_ value: Double) -> Double {
            (value * 100).rounded() / 100
        }

        let stripeFee: Double
        let totalProcessingFees: Double
        let salesTax: Double

        if fees.isProcessingFeePassToCustomer == true {

            if fees.isProcessingFeeTaxable == true {
                stripeFee = rounded2(
                    (
                        stripePerc * (
                            (1 + taxRate) *
                            (deposit + speakeasyFee + taxable) +
                            nonTaxable
                        ) +
                        stripeFlat
                    ) /
                    (1 - (1 + taxRate) * stripePerc)
                )
                totalProcessingFees = rounded2(speakeasyFee + stripeFee)
                salesTax = rounded2(
                    (deposit + taxable + totalProcessingFees) *
                    taxRate
                )
            } else {
                stripeFee = rounded2(
                    (
                        stripePerc * (
                            (deposit + taxable) *
                            (1 + taxRate) +
                            nonTaxable +
                            speakeasyFee
                        ) +
                        stripeFlat
                    ) /
                    (1 - stripePerc)
                )
                totalProcessingFees = rounded2(speakeasyFee + stripeFee)
                salesTax = rounded2(
                    (deposit + taxable) *
                    taxRate
                )
            }
        } else {
            stripeFee = rounded2(
                stripePerc *
                (
                    (deposit + taxable) *
                    (1 + taxRate) +
                    nonTaxable
                ) +
                stripeFlat
            )
            totalProcessingFees = rounded2(speakeasyFee + stripeFee)
            salesTax = rounded2(
                (deposit + taxable) *
                taxRate
            )
        }

        let roundedProcessingFees =
            (totalProcessingFees * 100).rounded() / 100
        let amountCharged = rounded2(
            deposit +
            (fees.isProcessingFeePassToCustomer == true
             ? roundedProcessingFees
             : 0) +
            taxable +
            nonTaxable +
            salesTax
        )

        return max(0, amountCharged - salesTax)
    }

    func calculatedCustomFees(
        deposit: Double,
        fees: TableBookingSettings
    ) -> [(amount: Double, isTaxable: Bool)] {

        (fees.customFees ?? []).compactMap { customFee in

            guard customFee.isEnableCustomFee == true else {
                return nil
            }

            let amount = customFee.customFeeType?.uppercased() == "FLAT"
                ? (customFee.customFee ?? 0)
                : deposit * (customFee.customFee ?? 0) / 100

            return (
                amount,
                customFee.isCustomFeeTaxable == true
            )
        }
    }

    func calculateSEFees(
        deposit: Double,
        fees: TableBookingSettings
    ) -> Double {

        var amount = 0.0

        if let percentage = fees.speakeasyFeePerc {
            amount = deposit * percentage * 100
        }

        if let flat = fees.speakeasyFeeFlat {
            amount += deposit <= 10
                ? deposit * 0.1 * flat
                : flat
        }

        return amount
    }
}

private extension PremiumReservationVC {

    func convertPriceFormat(
        _ amount: Double?,
        _ currency: String?
    ) -> String {

        let formatter = NumberFormatter()

        formatter.numberStyle = .currency

        formatter.currencyCode =
            currency ?? "USD"

        formatter.maximumFractionDigits = 0

        formatter.minimumFractionDigits = 0

        return formatter.string(
            from: NSNumber(value: amount ?? 0)
        ) ?? "$0"
    }
}

private extension PremiumReservationVC {

    func configure(
        cell: PremiumReservationCell,
        with item: SeatingArea
    ) {

        let isInquiry =
            item.inquiryEnabled == true &&
            item.hideCheckout == true

        let hidePricing =
            isInquiry &&
            item.hidePricing == true

        let guestText = formatGuestCount(
            min: item.defaultGuest ?? 0,
            max: item.maxGuest ?? 0
        )

        let timeText = item.bookingType == .timeWise
            ? getAvailableTimeRange(for: item)
            : ""

        let values = getLowestPricedAvailableSlot(
            for: item
        )

        let depositText = hidePricing
            ? ""
            : convertPriceFormat(
                values?.deposit,
                event?
                    .venue?
                    .venueSettings?
                    .currencyCode
            )

        let minimumText = hidePricing
            ? ""
            : (
                values?.minimum != nil
                ? "\(convertPriceFormat(values?.minimum, event?.venue?.venueSettings?.currencyCode)) minimum"
                : ""
            )

        cell.configure(
            title: item.name ?? "",
            guestText: guestText,
            timeText: timeText,
            description: item.highlight?.isEmpty == false
                ? (item.highlight ?? "")
                : (item.description ?? ""),
            depositText: depositText,
            minimumText: minimumText,
            buttonTitle: isInquiry ? "Inquire" : "Book now",
            hidePricing: hidePricing
        )

        cell.onBookTap = { [weak self] in
            self?.openSeatingArea(item)
        }
    }
}

private extension PremiumReservationVC {

    func openSeatingArea(
        _ item: SeatingArea
    ) {

        guard item.hideCheckout != true else {

            print("Inquiry tapped")

            return
        }
        
        Navigate.to.premiumTableSeatingVC(self, event: event, seatingArea: item)

///* ff */  Navigate.to.premiumTableSeatingVC(
//            self,
//            seatingArea: item,
//            event: event
//        ) { [weak self] timeSlotId,
//            guestCount,
//            _,
//            _ in
//
//            guard let self else {
//                return
//            }
//
//            createQueue(
//                area: item,
//                timeSlotId: timeSlotId,
//                guestCount: guestCount
//            )
//        }
    }
}

private extension PremiumReservationVC {

    func createQueue(
        area: SeatingArea,
        timeSlotId: String?,
        guestCount: Int
    ) {

        guard let event else {
            return
        }

        let uuid = UUID()
            .uuidString
            .replacingOccurrences(
                of: "-",
                with: ""
            )
            .lowercased()

        let queueId =
            "TABLE_BOOKING_QUEUE_\(uuid)"

        TablePresenter.createSeatingAreaBooking(

            eventId: event.id ?? "",

            seatingAreaId: area.id ?? "",

            timeSlotId:
                area.bookingType == .default
                ? nil
                : timeSlotId,

            venueId: event.venue?.id ?? "",

            guests: guestCount,

            queueId: queueId

        ) { [weak self]
            success,
            message,
            _ in

            guard let self else {
                return
            }

            if success {

                Navigate.to.tablePurchaseVC(
                    self,
                    queueId: queueId,
                    event: event,
                    seatingAreas: seatingAreas
                )

            } else {

                Alert.showToast(
                    message ??
                    Constant.String.somethingWrong
                )
            }
        }
    }
}

extension PremiumReservationVC {

    func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {

        guard !isInitialLoading else {
            return
        }

        let offset = scrollView.contentOffset.y

        let content =
            scrollView.contentSize.height

        let visible =
            scrollView.bounds.height

        if offset >
            content - visible - 300 {

            loadNextPageIfNeeded()
        }
    }
}
