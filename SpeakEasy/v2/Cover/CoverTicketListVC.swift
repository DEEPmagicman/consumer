//
//  CoverTicketListVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/03/26.
//

import UIKit
import SDWebImage

final class CoverTicketListVC: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var venueImage: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var ticketsTitleLbl: UILabel!
    @IBOutlet weak var continueToCheckoutBtn: CheckoutBarView!

    // MARK: - Public

    var venueDetails: ClipVenue?
    var doormanId = ""

    // MARK: - Private

    private let maxTickets = 20

    private var coverTickets: [CoverTicket] = []
    private var upSellTickets: [UpSellTicket] = []

    private var coverTicketCount: [Int: Int] = [:]
    private var upSellTicketCount: [Int: Int] = [:]
    private var expandedIndexSet: Set<String> = []

    private var bookingType: TicketPriceType = .FREE

    private enum FlowStep {
        case coverTickets
        case addOns
    }

    private var currentStep: FlowStep = .coverTickets

    // MARK: - Computed Properties

    private var isVenueOpen: Bool {
        venueDetails?.venueSettings?.bookingStatus?.uppercased() == "OPEN"
    }

    private var totalSelectedCount: Int {
        coverTicketCount.values.reduce(0, +) +
        upSellTicketCount.values.reduce(0, +)
    }

    private var isMaxTicketReached: Bool {
        totalSelectedCount >= maxTickets
    }

    private var selectedCoverTickets: [CoverTicket] {
        coverTickets.enumerated().compactMap { index, ticket in
            let qty = coverTicketCount[index] ?? 0
            guard qty > 0 else { return nil }
            var item = ticket
            item.selectedQuantity = qty
            return item
        }
    }

    private var selectedAddOns: [UpSellTicket] {
        upSellTickets.enumerated().compactMap { index, ticket in
            let qty = upSellTicketCount[index] ?? 0
            guard qty > 0 else { return nil }
            var item = ticket
            item.selectedQuantity = qty
            return item
        }
    }

    private var hasPaidCoverTicket: Bool {
        selectedCoverTickets.contains { $0.price > 0 }
    }

    private var hasAnyCoverSelection: Bool {
        !selectedCoverTickets.isEmpty
    }

    private var hasAnyUpsell: Bool {
        !upSellTickets.isEmpty
    }

    private var modifiedUpSellTickets: [UpSellTicket] {
        var result = [UpSellTicket]()

        upSellTickets.enumerated().forEach { index, ticket in
            result.append(ticket)

            var taxRate = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isEnableSalesTax == true {
                taxRate = (venueDetails?.venueSettings?.addOnsBookingSettings?.salesTax ?? 0) / 100
            }

            var totalCustomFee = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isEnableCustomFee == true {
                if venueDetails?.venueSettings?.addOnsBookingSettings?.customFeeType == "PERCENTAGE" {
                    totalCustomFee = result[index].price *
                        (venueDetails?.venueSettings?.addOnsBookingSettings?.customFee ?? 0) / 100
                } else {
                    totalCustomFee = venueDetails?.venueSettings?.addOnsBookingSettings?.customFee ?? 0
                }
            }

            var totalProcessingFee = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isProcessingFeePassToCustomer == true {
                let stripeFee = (0.029 * (1 + taxRate) *
                    (ticket.price + seServiceFee(ticket.price) + totalCustomFee) + 0.3) /
                    (1 - (1 + taxRate) * 0.029)
                totalProcessingFee = stripeFee + seServiceFee(ticket.price)
            }

            var salesTax = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isEnableSalesTax == true {
                salesTax = (ticket.price + totalProcessingFee + totalCustomFee) * taxRate
            }

            let amountCharged = ticket.price + totalProcessingFee + totalCustomFee + salesTax
            result[index].price = round(amountCharged * 100) / 100
        }

        return result
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupContinueTap()
        setupScreen()
        setupCoverTickets()
        getUpsellTickets()
        updateCheckoutState()
    }
}

// MARK: - Setup

private extension CoverTicketListVC {

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.alwaysBounceVertical = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220

        tableView.register(
            TicketsTVC.nib,
            forCellReuseIdentifier: TicketsTVC.identifier
        )
    }

    func setupContinueTap() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(onClickContinue)
        )
        continueToCheckoutBtn.addGestureRecognizer(tap)
    }

    func setupScreen() {
        let logoUrl = "\(SharedURL.amazonStorage)\(venueDetails?.logo?.key ?? "")"
        venueImage.sd_setImage(with: URL(string: logoUrl), completed: nil)

        let imageUrlString = "\(SharedURL.amazonStorage)\(venueDetails?.venueAttachment?.first?.key ?? "")"
        if let url = URL(string: imageUrlString) {
            bgImage.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "newSpeakeasy")
            )
        } else {
            bgImage.image = UIImage(named: "newSpeakeasy")
        }

        venueName.text = venueDetails?.name ?? ""
        timeLbl.text = venueDetails?.timezone

        if let hexColor = venueDetails?.venueSettings?.whiteLabelColor {
            timeLbl.textColor = UIColor(hex: hexColor)
        }

        continueToCheckoutBtn.isHidden = true
        continueToCheckoutBtn.alpha = 0
    }

    func setupCoverTickets() {
        guard let list = venueDetails?.coverTicket else {
            coverTickets = []
            tableView.reloadData()
            updateCheckoutState()
            return
        }

        coverTickets = list.filter {
            !($0.isDeleted ?? false) &&
            $0.status == "ENABLED"
        }

        tableView.reloadData()
        updateCheckoutState()
    }
}

// MARK: - API

private extension CoverTicketListVC {

    func getUpsellTickets() {
        guard let venueId = venueDetails?.id, !venueId.isEmpty else {
            upSellTickets = []
            tableView.reloadData()
            return
        }

        MVPPresenter.getUpSellItem(
            skip: 0,
            doormanId: doormanId,
            venueId: venueId
        ) { [weak self] isSuccess, errMsg, upSellItem, _, _ in
            guard let self else { return }

            if isSuccess {
                self.upSellTickets = upSellItem
            } else {
                self.upSellTickets = []
                if let errMsg, !errMsg.isEmpty {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                }
            }

            self.tableView.reloadData()
            self.updateCheckoutState()
        }
    }
}

// MARK: - Pricing

private extension CoverTicketListVC {

    func seServiceFee(_ ticketPrice: Double) -> Double {
        switch venueDetails?.speakEasyCharges {
        case "SAME_PRICE":    return 1
        case "FREE":          return 0
        case "DIFFRENT_PRICE": return 0.5
        case "TAO_PRICING":   return 0.5
        case "INCREMENTAL":
            if ticketPrice <= 10  { return 0.5 }
            if ticketPrice <= 20  { return 1 }
            if ticketPrice <= 100 { return 2 }
            return 5
        default: return 0
        }
    }
}

// MARK: - Checkout State

private extension CoverTicketListVC {

    func updateCheckoutState() {
        let shouldShow = hasAnyCoverSelection

        let subtotal =
            selectedCoverTickets.reduce(0.0) {
                $0 + ($1.price * Double($1.selectedQuantity ?? 0))
            }
            +
            selectedAddOns.reduce(0.0) {
                $0 + ($1.price * Double($1.selectedQuantity ?? 0))
            }

        continueToCheckoutBtn.updateSummary(
            currency: venueDetails?.venueSettings?.currencySymbol ?? "$",
            count: totalSelectedCount,
            subtotal: subtotal,
            fees: 0
        )

        bookingType = hasPaidCoverTicket ? .PAID : .FREE

        animateCheckoutBar(show: shouldShow)
    }

    func animateCheckoutBar(show: Bool) {
        // Avoid redundant animations
        let isCurrentlyVisible = !continueToCheckoutBtn.isHidden && continueToCheckoutBtn.alpha == 1

        if show == isCurrentlyVisible { return }

        if show {
            continueToCheckoutBtn.isHidden = false
            continueToCheckoutBtn.alpha = 0
            continueToCheckoutBtn.transform = CGAffineTransform(translationX: 0, y: 80)

            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.6,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                self.continueToCheckoutBtn.alpha = 1
                self.continueToCheckoutBtn.transform = .identity
            }
        } else {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: [.curveEaseIn, .allowUserInteraction]
            ) {
                self.continueToCheckoutBtn.alpha = 0
                self.continueToCheckoutBtn.transform = CGAffineTransform(translationX: 0, y: 80)
            } completion: { _ in
                self.continueToCheckoutBtn.isHidden = true
            }
        }
    }

    func moveToAddOnStep() {
        currentStep = .addOns
        expandedIndexSet.removeAll()
        tableView.reloadData()
        updateCheckoutState()
    }

    func proceedToFinalCheckout() {
        guard !selectedCoverTickets.isEmpty else { return }

        if !selectedAddOns.isEmpty || hasPaidCoverTicket {
            Navigate.to.coverCheckOutVC(
                self,
                venue: venueDetails,
                selectedCoverTickets: selectedCoverTickets,
                selectedAddOnsItem: selectedAddOns,
                totalPrice: 0,
                bookingType: bookingType
            )
        } else {
            createFreeBooking()
        }
    }

    func canSelectMoreTickets() -> Bool {
        if isMaxTicketReached {
            Alert.showToast(Constant.String.maxTicketSelectionReached)
            return false
        }
        return true
    }
}

// MARK: - Actions

extension CoverTicketListVC {

    @IBAction func onClickBackBtn(_ sender: Any) {
        if currentStep == .addOns {
            currentStep = .coverTickets
            expandedIndexSet.removeAll()
            tableView.reloadData()
            updateCheckoutState()
            return
        }
        Navigate.to.back(self)
    }

    @objc func onClickContinue() {
        if UserDefault.shared.isGuest == true {
            Navigate.to.loginMandatory(self)
            return
        }

        guard !selectedCoverTickets.isEmpty else { return }

        switch currentStep {
        case .coverTickets:
            hasAnyUpsell ? moveToAddOnStep() : proceedToFinalCheckout()
        case .addOns:
            proceedToFinalCheckout()
        }
    }

    private func createFreeBooking() {
        guard !selectedCoverTickets.isEmpty else { return }

        let tickets: [[String: Any]] = selectedCoverTickets.map {
            ["ticketId": $0.id ?? "", "ticketQuantity": $0.selectedQuantity ?? 0]
        }

        view.isUserInteractionEnabled = false

        PaymentPresenter.createCoverFreeBooking(
            coverTickets: tickets,
            venueId: venueDetails?.id ?? ""
        ) { [weak self] isSuccess, errMsg, id, _ in
            guard let self else { return }
            self.view.isUserInteractionEnabled = true

            if isSuccess, let id {
                Navigate.to.scanQR(self, bookingId: id, addOnsBookingId: "")
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }

    private func plusBtnClicked(at indexPath: IndexPath) {
        guard isVenueOpen else { return }
        guard canSelectMoreTickets() else { return }

        switch currentStep {
        case .coverTickets:
            guard indexPath.row < coverTickets.count else { return }
            guard coverTickets[indexPath.row].status == "ENABLED" else { return }
            coverTicketCount[indexPath.row] = (coverTicketCount[indexPath.row] ?? 0) + 1

        case .addOns:
            guard indexPath.row < upSellTickets.count else { return }
            upSellTicketCount[indexPath.row] = (upSellTicketCount[indexPath.row] ?? 0) + 1
        }

        updateCheckoutState()
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    private func minusBtnClicked(at indexPath: IndexPath) {
        switch currentStep {
        case .coverTickets:
            let current = coverTicketCount[indexPath.row] ?? 0
            coverTicketCount[indexPath.row] = max(0, current - 1)

        case .addOns:
            let current = upSellTicketCount[indexPath.row] ?? 0
            upSellTicketCount[indexPath.row] = max(0, current - 1)
        }

        updateCheckoutState()
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

// MARK: - UITableViewDataSource

extension CoverTicketListVC: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        switch currentStep {
        case .coverTickets: return coverTickets.count
        case .addOns:       return upSellTickets.count
        }
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TicketsTVC.identifier,
            for: indexPath
        ) as? TicketsTVC else {
            return UITableViewCell()
        }

        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
        let whiteLabelColor = venueDetails?.venueSettings?.whiteLabelColor

        switch currentStep {
            
        case .coverTickets:
            let ticket = coverTickets[indexPath.row]
            let count = coverTicketCount[indexPath.row] ?? 0
            let name = ticket.customName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? (ticket.customName ?? ticket.name ?? "")
                : (ticket.name ?? "")

            cell.configure(
                coverTicketName: name,
                description: ticket.description,
                price: ticket.price ?? 0,
                extraFees: ticket.extraFees,
                selectedCount: count,
                currency: currency,
                whiteLabelColor: whiteLabelColor,
                isDescriptionExpanded: expandedIndexSet.contains(ticket.id ?? ""),
                onPlus: { [weak self] in self?.plusBtnClicked(at: indexPath) },
                onMinus: { [weak self] in self?.minusBtnClicked(at: indexPath) }
            )

            cell.onDescriptionToggle = { [weak self] in
                guard let self else { return }
                let id = ticket.id ?? ""
                if self.expandedIndexSet.contains(id) {
                    self.expandedIndexSet.remove(id)
                } else {
                    self.expandedIndexSet.insert(id)
                }
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }

        case .addOns:
            let ticket = upSellTickets[indexPath.row]
            let count = upSellTicketCount[indexPath.row] ?? 0

            cell.configure(
                coverTicketName: ticket.addOns?.name ?? "",
                description: ticket.addOns?.description,
                price: modifiedUpSellTickets[indexPath.row].price,
                extraFees: ticket.extraFees,
                selectedCount: count,
                currency: currency,
                whiteLabelColor: whiteLabelColor,
                isDescriptionExpanded: expandedIndexSet.contains(ticket.id ?? ""),
                onPlus: { [weak self] in self?.plusBtnClicked(at: indexPath) },
                onMinus: { [weak self] in self?.minusBtnClicked(at: indexPath) }
            )

            cell.onDescriptionToggle = { [weak self] in
                guard let self else { return }
                let id = ticket.id ?? ""
                if self.expandedIndexSet.contains(id) {
                    self.expandedIndexSet.remove(id)
                } else {
                    self.expandedIndexSet.insert(id)
                }
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }   
        }

        cell.onPlusTap = { [weak self] _ in
            self?.plusBtnClicked(at: indexPath)
        }

        cell.onMinusTap = { [weak self] _ in
            self?.minusBtnClicked(at: indexPath)
        }

        cell.onRSVPTap = nil

        return cell

        cell.onPlusTap = { [weak self] _ in
            self?.plusBtnClicked(at: indexPath)
        }

        cell.onMinusTap = { [weak self] _ in
            self?.minusBtnClicked(at: indexPath)
        }

        cell.onRSVPTap = nil

        return cell
    }
}

// MARK: - UITableViewDelegate

extension CoverTicketListVC: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        guard isVenueOpen else { return }
        guard canSelectMoreTickets() else { return }

        switch currentStep {
        case .coverTickets:
            guard indexPath.row < coverTickets.count else { return }
            guard coverTickets[indexPath.row].status == "ENABLED" else { return }
            coverTicketCount[indexPath.row] = (coverTicketCount[indexPath.row] ?? 0) + 1

        case .addOns:
            guard indexPath.row < upSellTickets.count else { return }
            upSellTicketCount[indexPath.row] = (upSellTicketCount[indexPath.row] ?? 0) + 1
        }

        updateCheckoutState()
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(
        _ tableView: UITableView,
        estimatedHeightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return 220
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
    }

    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        return nil
    }

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return .leastNormalMagnitude
    }
}
