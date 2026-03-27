//
//  TicketSelectionViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 05/02/26.
//
//
//  TicketSelectionViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 05/02/26.
//

import UIKit
import MHLoadingButton

 enum TicketMode {
    case normal
    case addOn
}

class TicketSelectionViewController: UIViewController {

    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueName2: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var ticketTableView: UITableView!
    @IBOutlet weak var hiddenTicketField: UITextField!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var continueToCheckOutBtn: LoadingButton!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var protectedTicketView: UIView!
    @IBOutlet weak var unLockTF: UITextField!
    @IBOutlet weak var unLockBtn: UIView!
    @IBOutlet weak var addOnTicketTitleView: UIView!
    @IBOutlet weak var addOnTicketTitleLbl: UILabel!
    @IBOutlet weak var groupTableView: UITableView!
    @IBOutlet weak var groupTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ticketTableViewHeight: NSLayoutConstraint!
   
    var mode: TicketMode = .normal

    private var tickets: [EventTicket] = []
    private var normalTickets: [EventTicket] = []
    private var addOnTickets: [EventTicket] = []

    private var selectedNormalTickets: [EventTicket] = []
    private var groupedNormalTickets: [(groupName: String, tickets: [EventTicket])] = []
    private var expandedTicketDescriptions: Set<String> = []
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var groupListHeightObservation: NSKeyValueObservation?
    private var ticketLinks: [EventTicketLink] = []
    private var disabledTicketIds: Set<String> = []
    
    var event: Event?
    var venueDetails: ClipVenue?
    private var isLoading = true

    private var eventTicketId = [String]()

    private var totalSelectedTickets: Int {
        switch mode {
        case .normal:
            let normalTotal = normalTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
            let groupedTotal = groupedNormalTickets
                .flatMap { $0.tickets }
                .reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
            return normalTotal + groupedTotal

        case .addOn:
            return tickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let venue = event?.venue {
            self.venueDetails = venue
        }

        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        ticketTableView.register(TicketsTVC.nib, forCellReuseIdentifier: TicketsTVC.identifier)
        
        groupTableView.delegate = self
        groupTableView.dataSource = self
        groupTableView.register(GroupTicketTVC.nib, forCellReuseIdentifier: GroupTicketTVC.identifier)
        
        ticketListHeightObservation = ticketTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketTableViewHeight.constant = self.ticketTableView.contentSize.height
            self.ticketTableView.layoutIfNeeded()
        }
        
        groupListHeightObservation = groupTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.groupTableViewHeight.constant = self.groupTableView.contentSize.height
            self.groupTableView.layoutIfNeeded()
        }
        
        continueToCheckOutBtn.indicator = MaterialLoadingIndicator(color: .white)
        continueToCheckOutBtn.bgColor = continueToCheckOutBtn.backgroundColor ?? .orange
        
        getTicketLinksAndSetup()
        setupHeaderData()
//        setupData()
        
    }
    private func ticketDate(_ value: String?) -> Date? {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return value.toDate(withFormat: .yyyyMMddHHmmss)
    }

    private func isTicketSoldOut(_ ticket: EventTicket) -> Bool {
        let remaining = ticket.remainingQuantity ?? max((ticket.issuedUnits ?? 0) - (ticket.soldUnits ?? 0), 0)
        return remaining <= 0
        
    }
    
    private func shouldHideSoldOutTicket(_ ticket: EventTicket) -> Bool {
        let hideSoldOut = event?.eventTicketSettings?.hideSoldOut == true
        return isTicketSoldOut(ticket) && hideSoldOut
    }

    private func isTicketSaleStarted(_ ticket: EventTicket) -> Bool {
        let now = Date.venueNow(timezone: venueDetails?.useTimezone)

        guard let startSaleDate = ticketDate(ticket.beginSale) else {
            return true
        }

        return now >= startSaleDate
    }

    private func isTicketSaleNotEnded(_ ticket: EventTicket) -> Bool {
        let now = Date.venueNow(timezone: venueDetails?.useTimezone)

        guard let endSaleDate = ticketDate(ticket.endSale) else {
            return true
        }

        return now <= endSaleDate
    }

    private func isTicketAvailableForDisplay(_ ticket: EventTicket) -> Bool {
        let isNotDeleted = ticket.isDeleted == false
        let isNotPaused = ticket.sellingPaused == false
        let saleStarted = isTicketSaleStarted(ticket)
        let saleNotEnded = isTicketSaleNotEnded(ticket)
        let hideBecauseSoldOut = shouldHideSoldOutTicket(ticket)

        return isNotDeleted &&
               isNotPaused &&
               saleStarted &&
               saleNotEnded &&
               !hideBecauseSoldOut
    }

    private func filterAvailableTickets(_ list: [EventTicket]) -> [EventTicket] {

        let allTickets = (event?.eventTicket ?? []) + (event?.eventAddOnTicket ?? []) + (event?.protectedEventTicket ?? [])

        return list.filter { ticket in
            guard isTicketAvailableForDisplay(ticket) else { return false }

            let state = linkedState(for: ticket, in: allTickets)

            if let id = ticket.id, state.isDisabled {
                disabledTicketIds.insert(id)
            }

            return !state.isHidden
        }
    }
    
    private func isTicketDisabledByLink(_ ticket: EventTicket) -> Bool {
        guard let id = ticket.id else { return false }
        return disabledTicketIds.contains(id)
    }
    
    private func isTicketSaleEnded(_ ticket: EventTicket) -> Bool {
        let now = Date.venueNow(timezone: venueDetails?.useTimezone)

        guard let endSaleDate = ticketDate(ticket.endSale) else {
            return false
        }

        return now > endSaleDate
    }

    private func linkedState(for ticket: EventTicket, in allTickets: [EventTicket]) -> (isHidden: Bool, isDisabled: Bool) {
        guard let ticketId = ticket.id else { return (false, false) }

        let validLinks = ticketLinks.filter {
            $0.eventTicketId == ticketId &&
            $0.status == "ENABLED" &&
            $0.isDeleted == false
        }

        guard !validLinks.isEmpty else {
            return (false, false)
        }

        var shouldHide = false
        var shouldDisable = false

        for link in validLinks {
            guard let targetId = link.targetEventTicketId,
                  let targetTicket = allTickets.first(where: { $0.id == targetId }) else {
                continue
            }

            let action = link.linkAction ?? ""
            let state = link.linkState ?? ""

            var conditionMatched = false

            switch action {
            case "SELLS_OUT":
                conditionMatched = isTicketSoldOut(targetTicket)

            case "SALE_END":
                conditionMatched = isTicketSaleEnded(targetTicket)

            default:
                conditionMatched = false
            }

            if conditionMatched {
                switch state {
                case "HIDDEN_UNTIL":
                    shouldHide = false
                case "DISABLE_UNTIL":
                    shouldDisable = false
                default:
                    break
                }
            } else {
                switch state {
                case "HIDDEN_UNTIL":
                    shouldHide = true
                case "DISABLE_UNTIL":
                    shouldDisable = true
                default:
                    break
                }
            }
        }

        return (shouldHide, shouldDisable)
    }
    
    private func setupHeaderData() {
        guard let event = event else { return }

        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueName.text = venueDetails?.name ?? ""
        venueName2.text = venueDetails?.name ?? ""
        eventTitleLbl.text = event.title

        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

            dateandtimeLbl.text = customText

        } else {

            let timezone = venueDetails?.useTimezone ?? ""

            let dateText = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .EEEMMMD,
                customTimeZone: timezone
            )

            let startTime = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            )

            let endTime = event.endDateTime?.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            ) ?? "LATE"

            dateandtimeLbl.text = "\(dateText) at \(startTime) - \(endTime)"
        }

        if let hex = self.event?.whiteLabelColor {
            let color = UIColor(hex: hex)
            dateandtimeLbl.textColor = color
            continueToCheckOutBtn.backgroundColor = color
            continueToCheckOutBtn.bgColor = color
        }
    }

    private func setupData() {
        guard let event = event else { return }

        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueName.text = venueDetails?.name ?? ""
        venueName2.text = venueDetails?.name ?? ""
        eventTitleLbl.text = event.title
        disabledTicketIds.removeAll()

        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

            dateandtimeLbl.text = customText

        } else {

            let timezone = venueDetails?.useTimezone ?? ""

            let dateText = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .EEEMMMD,
                customTimeZone: timezone
            )

            let startTime = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            )

            let endTime = event.endDateTime?.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            ) ?? "LATE"

            dateandtimeLbl.text = "\(dateText) at \(startTime) - \(endTime)"
        }

        if let hex = self.event?.whiteLabelColor {
            let color = UIColor(hex: hex)
            dateandtimeLbl.textColor = color
            continueToCheckOutBtn.backgroundColor = color
            continueToCheckOutBtn.bgColor = color
        }

        let filteredNormalTickets = filterAvailableTickets(event.eventTicket ?? [])
        let filteredAddOnTickets = filterAvailableTickets(event.eventAddOnTicket ?? [])

        let normalSplit = makeGroupedTickets(from: filteredNormalTickets)
        normalTickets = normalSplit.nonGrouped
        groupedNormalTickets = normalSplit.grouped

        addOnTickets = filteredAddOnTickets
        
        groupTableView.reloadData()
        ticketTableView.reloadData()
        updateGroupTableHeight()
        
        let protectedVisibleCandidates = filterAvailableTickets(event.protectedEventTicket ?? [])
        protectedTicketView.isHidden = protectedVisibleCandidates.isEmpty

        if mode == .addOn {
            switchToAddOnMode()
        } else {
            switchToNormalMode()
        }
    }
    
    private func getTicketLinksAndSetup() {
        isLoading = true
        ticketTableView.reloadData()
        guard let eventId = event?.uniqueId else {
            isLoading = false
            setupData()
            return
        }

        EventPresenter.getTicketLinks(eventId: eventId) { [weak self] isSuccess, _, links in
            guard let self = self else { return }

            if isSuccess {
                self.ticketLinks = links ?? []
            } else {
                self.ticketLinks = []
            }
            
            self.isLoading = false
            self.setupData()
        }
    }

    private func switchToNormalMode() {
        mode = .normal
        tickets = normalTickets

        addOnTicketTitleView.isHidden = true
        groupTableView.isHidden = groupedNormalTickets.isEmpty

        updateContinueButtonForMode()
        updateContinueBtnState()
        ticketTableView.reloadData()
        groupTableView.reloadData()
        updateGroupTableHeight()
    }

    private func switchToAddOnMode() {
        mode = .addOn
        tickets = addOnTickets

        addOnTicketTitleView.isHidden = false
        groupTableView.isHidden = true

        updateContinueButtonForMode()
        updateContinueBtnState()
        ticketTableView.reloadData()
    }
    
    private func refreshContinueButtonTitle() {
        updateContinueButtonForMode()
    }
    
    private func makeGroupedTickets(from list: [EventTicket]) -> (nonGrouped: [EventTicket], grouped: [(groupName: String, tickets: [EventTicket])]) {

        var nonGrouped: [EventTicket] = []
        var groupedMap: [String: (groupName: String, tickets: [EventTicket])] = [:]

        for ticket in list {
            if let group = ticket.eventTicketGroupHasTicket?.eventTicketGroup,
               let groupId = group.id,
               !groupId.isEmpty {

                let groupName = group.name ?? ""

                if groupedMap[groupId] != nil {
                    groupedMap[groupId]?.tickets.append(ticket)
                } else {
                    groupedMap[groupId] = (groupName: groupName, tickets: [ticket])
                }
            } else {
                nonGrouped.append(ticket)
            }
        }

        let grouped = Array(groupedMap.values)

        return (nonGrouped, grouped)
    }

    private func updateContinueButtonForMode() {
        switch mode {
        case .normal:
            continueToCheckOutBtn.setTitle("Continue to Checkout", for: .normal)

        case .addOn:
            let anyAddOnSelected = addOnTickets.contains(where: { ($0.selectedTicketCount ?? 0) > 0 })
            continueToCheckOutBtn.setTitle(anyAddOnSelected ? "Continue to Checkout" : "NO THANKS", for: .normal)
        }
    }
    
    private func updateGroupTableHeight() {
        groupTableView.reloadData()
        groupTableView.layoutIfNeeded()
        groupTableViewHeight.constant = groupTableView.contentSize.height
        view.layoutIfNeeded()
    }

    private func updateGroupTableLayout() {
        groupTableView.reloadData()
        groupTableView.beginUpdates()
        groupTableView.endUpdates()
        groupTableView.layoutIfNeeded()
        groupTableViewHeight.constant = groupTableView.contentSize.height
        view.layoutIfNeeded()
    }
    
    private func buildTicketsPayload(from selected: [EventTicket]) -> [[String: Any]] {
        var payload = [[String: Any]]()

        selected.forEach {
            payload.append([
                "ticketId": $0.id ?? "",
                "ticketQuantity": $0.selectedTicketCount ?? 0,
                "ticketPrice": $0.price ?? 0
            ])
        }

        return payload
    }

    private func getTicketByPassWord() {

        EventPresenter.getEventTicketByPassWord(
            eventId: self.event?.uniqueId ?? "",
            venueTimeZone: venueDetails?.useTimezone,
            password: unLockTF.text ?? ""
        ) { isSuccess, errMsg, ticket in

            if isSuccess {
                let tickets = ticket ?? []

                for tics in tickets {
                    if self.eventTicketId.contains(where: { $0 == tics.id }) == false {
                        self.eventTicketId.append(tics.id ?? "")
                    }
                }

                self.protectedTicketView.isHidden = self.event?.totalTickets == self.eventTicketId.count

                for data in tickets {
                    if self.event?.protectedEventTicket?.contains(where: { $0.id == data.id }) ?? false == false {
                        if self.event?.protectedEventTicket == nil {
                            self.event?.protectedEventTicket = [data]
                        } else {
                            self.event?.protectedEventTicket?.append(data)
                        }
                    }
                }
                self.unLockTF.text = ""
                self.unLockPassword()
                self.setupData()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    @objc func unLockPassword() {
//        unLockBtn.alpha = (unLockTF.text ?? "").isEmpty ? 0.5 : 1
//        unLockBtn.isUserInteractionEnabled = !(unLockTF.text ?? "").isEmpty
    }

    @IBAction func onClickUnLockBtn(_ sender: Any) {
        let code = (unLockTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        guard var event = event else { return }

        let protectedList = event.protectedEventTicket ?? []
        let alreadyUnlocked = normalTickets.contains { ticket in
            let pass = ticket.eventTicketHasPassword?.password ?? ""
            return pass.caseInsensitiveCompare(code) == .orderedSame
        }

        if alreadyUnlocked {
            Alert.showToast("Tickets already unlocked")
            return
        }

        let displayableProtectedList = filterAvailableTickets(protectedList)

        guard !displayableProtectedList.isEmpty else {
            protectedTicketView.isHidden = true
            return
        }

        let matchedTickets = displayableProtectedList.filter { ticket in
            let pass = ticket.eventTicketHasPassword?.password ?? ""
            return pass.caseInsensitiveCompare(code) == .orderedSame
        }

        guard !matchedTickets.isEmpty else {
            Alert.showToast("Invalid password please try again")
            return
        }

        let validUnlockedTickets = filterAvailableTickets(matchedTickets)

        for ticket in validUnlockedTickets {
            if !normalTickets.contains(where: { $0.id == ticket.id }) {
                normalTickets.append(ticket)
            }
        }

        let unlockedIds = Set(validUnlockedTickets.compactMap { $0.id })
        event.protectedEventTicket = protectedList.filter { ticket in
            guard let id = ticket.id else { return true }
            return !unlockedIds.contains(id)
        }

        self.event = event

        unLockTF.text = ""
        unLockPassword()

        let remainingDisplayableLockedTickets = filterAvailableTickets(event.protectedEventTicket ?? [])
        protectedTicketView.isHidden = remainingDisplayableLockedTickets.isEmpty

        if mode == .normal {
            tickets = normalTickets
            ticketTableView.reloadData()
        }
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
//        Navigate.to.ticketConfirmationVC(self, booking: nil, bookingId: "be5af872-e29d-4115-93ab-6660d47662eb", type: .singleTickedEvent)
        Navigate.to.back(self)
    }

    @IBAction func onClickLockBtn(_ sender: Any) {
  
    }

    @IBAction func onClickContinueBtn(_ sender: Any) {
        guard let user = UserDefault.shared.user else {
            let loginVC = Navigate.to.loginPopUpVc(self)

            loginVC.onContinueToVerify = { [weak self] otp, otpRef, phone, countryCode, _, _ in
                guard let self else { return }

                Navigate.to.enterVerificationCodeVc(
                    self,
                    isFromLogin: true,
                    otp: otp,
                    otpRef: otpRef,
                    phoneNum: phone,
                    countryCode: countryCode
                ) { [weak self] in
                    self?.onClickContinueBtn(self as Any)
                }
            }
            return
        }
        guard let event = event else { return }

        switch mode {

        case .normal:
            let selectedNormal = normalTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
            let selectedGrouped = groupedNormalTickets
                .flatMap { $0.tickets }
                .filter { ($0.selectedTicketCount ?? 0) > 0 }

            let selected = selectedNormal + selectedGrouped
            guard !selected.isEmpty else { return }

            selectedNormalTickets = selected

            if addOnTickets.isEmpty {
                let ticketsPayload = buildTicketsPayload(from: selectedNormalTickets)
                continueToCheckOutBtn.showLoader(userInteraction: false)
                PaymentPresenter.createEventBookingV2(
                    eventId: event.id,
                    code: user.code,
                    phone: user.phone,
                    gender: user.gender,
                    userId: user.id,
                    tickets: ticketsPayload
                ) { [weak self] isSuccess, errMsg, id, _ in
                    guard let self = self else { return }
                    continueToCheckOutBtn.hideLoader()
                    if isSuccess {
                        Navigate.to.ticketCheckoutVC(self, event: event, selectedTickets: self.selectedNormalTickets, bookingId: id)
                    } else {
                        Alert.showToast(errMsg ?? "Somthing went wrong")
                    }
                }
                return
            }

            switchToAddOnMode()

        case .addOn:
            let selectedAddOns = addOnTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
            let finalSelectedTickets = selectedNormalTickets + selectedAddOns
            let ticketsPayload = buildTicketsPayload(from: finalSelectedTickets)
            continueToCheckOutBtn.showLoader(userInteraction: true)
            PaymentPresenter.createEventBookingV2(
                eventId: event.id,
                code: user.code,
                phone: user.phone,
                gender: user.gender,
                userId: user.id,
                tickets: ticketsPayload
            ) { [weak self] isSuccess, errMsg, id, _ in
                guard let self = self else { return }
                continueToCheckOutBtn.hideLoader()
                if isSuccess {
                    Navigate.to.ticketCheckoutVC(self, event: event, selectedTickets: finalSelectedTickets, bookingId: id)
                } else {
                    Alert.showToast(errMsg ?? "Somthing went wrong")
                }
            }
        }
    }

    private func indexForTicket(_ ticket: EventTicket) -> Int? {
        guard let id = ticket.id else { return nil }
        return tickets.firstIndex(where: { $0.id == id })
    }

    private func replaceTicketInCurrentMode(_ updated: EventTicket) {
        guard let id = updated.id else { return }

        switch mode {
        case .normal:
            if let idx = normalTickets.firstIndex(where: { $0.id == id }) {
                normalTickets[idx] = updated
            }
            tickets = normalTickets

        case .addOn:
            if let idx = addOnTickets.firstIndex(where: { $0.id == id }) {
                addOnTickets[idx] = updated
            }
            tickets = addOnTickets
        }
    }

    private func handlePlus(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket) else { return }
        guard let index = indexForTicket(ticket) else { return }

        let currentTicket = tickets[index]
        let currentCount = currentTicket.selectedTicketCount ?? 0
        let issuedUnits = currentTicket.issuedUnits ?? 0
        let remaining = currentTicket.remainingQuantity ?? max(issuedUnits - (currentTicket.soldUnits ?? 0), 0)

        let minPurchaseQuantity = max(currentTicket.miniPurchaseQuantity ?? 1, 1)
        let maxPurchaseQuantity = currentTicket.maxPurchaseQuantity ?? Int.max
        let isSellInMultiples = currentTicket.sellInMultiples == true

        let nextCount: Int
        if isSellInMultiples {
            nextCount = currentCount == 0
                ? minPurchaseQuantity
                : currentCount + minPurchaseQuantity
        } else {
            nextCount = currentCount + 1
        }

        let maxAllowed = min(issuedUnits, remaining, maxPurchaseQuantity)

        if nextCount <= maxAllowed {
            tickets[index].selectedTicketCount = nextCount
            replaceTicketInCurrentMode(tickets[index])

            ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            updateContinueBtnState()
            updateContinueButtonForMode()
        } else {
            Alert.showToast("Max tickets selected: create a separate order to purchase more.")
        }
    }
    
    private func handleMinus(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket) else { return }
        guard let index = indexForTicket(ticket) else { return }

        let currentTicket = tickets[index]
        let currentCount = currentTicket.selectedTicketCount ?? 0
        guard currentCount > 0 else { return }

        let minPurchaseQuantity = max(currentTicket.miniPurchaseQuantity ?? 1, 1)
        let isSellInMultiples = currentTicket.sellInMultiples == true

        let nextCount: Int
        if isSellInMultiples {
            nextCount = currentCount - minPurchaseQuantity
        } else {
            nextCount = currentCount - 1
        }

        tickets[index].selectedTicketCount = nextCount > 0 ? nextCount : nil

        replaceTicketInCurrentMode(tickets[index])

        ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        updateContinueBtnState()
        updateContinueButtonForMode()
    }

    private func handleRSVP(ticket: EventTicket, cell: TicketsTVC) {
        cell.rsvpBtn.showLoader(userInteraction: false)
        guard !isTicketDisabledByLink(ticket) else {
            cell.rsvpBtn.hideLoader()
            return
        }
        guard let event = event else {
            cell.rsvpBtn.hideLoader()
            return
        }

        switch mode {

        case .normal:
            selectedNormalTickets = [ticket]

            if addOnTickets.isEmpty {
                cell.rsvpBtn.hideLoader()
                Navigate.to.ticketCheckoutVC(
                    self,
                    event: event,
                    selectedTickets: selectedNormalTickets, bookingId: nil
                )
            } else {
                cell.rsvpBtn.hideLoader()
                switchToAddOnMode()
            }

        case .addOn:
            cell.rsvpBtn.hideLoader()
            let finalTickets = selectedNormalTickets + [ticket]

            Navigate.to.ticketCheckoutVC(
                self,
                event: event,
                selectedTickets: finalTickets, bookingId: nil
            )
        }
    }

    private func handleGroupPlus(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket) else { return }
        guard let ticketId = ticket.id else { return }

        for groupIndex in groupedNormalTickets.indices {
            guard let ticketIndex = groupedNormalTickets[groupIndex].tickets.firstIndex(where: { $0.id == ticketId }) else { continue }

            let currentTicket = groupedNormalTickets[groupIndex].tickets[ticketIndex]
            let currentCount = currentTicket.selectedTicketCount ?? 0
            let issuedUnits = currentTicket.issuedUnits ?? 0
            let remaining = currentTicket.remainingQuantity ?? max(issuedUnits - (currentTicket.soldUnits ?? 0), 0)

            let minPurchaseQuantity = max(currentTicket.miniPurchaseQuantity ?? 1, 1)
            let maxPurchaseQuantity = currentTicket.maxPurchaseQuantity ?? Int.max
            let isSellInMultiples = currentTicket.sellInMultiples == true

            let nextCount: Int
            if isSellInMultiples {
                nextCount = currentCount == 0 ? minPurchaseQuantity : currentCount + minPurchaseQuantity
            } else {
                nextCount = currentCount + 1
            }

            let maxAllowed = min(issuedUnits, remaining, maxPurchaseQuantity)

            if nextCount <= maxAllowed {
                groupedNormalTickets[groupIndex].tickets[ticketIndex].selectedTicketCount = nextCount
                updateContinueBtnState()
                updateContinueButtonForMode()
                updateGroupTableLayout()
            } else {
                Alert.showToast("Max tickets selected: create a separate order to purchase more.")
            }
            return
        }
    }

    private func handleGroupMinus(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket) else { return }
        guard let ticketId = ticket.id else { return }

        for groupIndex in groupedNormalTickets.indices {
            guard let ticketIndex = groupedNormalTickets[groupIndex].tickets.firstIndex(where: { $0.id == ticketId }) else { continue }

            let currentTicket = groupedNormalTickets[groupIndex].tickets[ticketIndex]
            let currentCount = currentTicket.selectedTicketCount ?? 0
            guard currentCount > 0 else { return }

            let minPurchaseQuantity = max(currentTicket.miniPurchaseQuantity ?? 1, 1)
            let isSellInMultiples = currentTicket.sellInMultiples == true

            let nextCount: Int
            if isSellInMultiples {
                nextCount = currentCount - minPurchaseQuantity
            } else {
                nextCount = currentCount - 1
            }

            groupedNormalTickets[groupIndex].tickets[ticketIndex].selectedTicketCount = nextCount > 0 ? nextCount : nil
            updateContinueBtnState()
            updateContinueButtonForMode()
            updateGroupTableLayout()
            return
        }
    }

    private func handleGroupRSVP(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket) else { return }
        guard let event = event, let ticketId = ticket.id else { return }

        for group in groupedNormalTickets {
            if let selectedTicket = group.tickets.first(where: { $0.id == ticketId }) {
                selectedNormalTickets = [selectedTicket]

                if addOnTickets.isEmpty {
                    Navigate.to.ticketCheckoutVC(
                        self,
                        event: event,
                        selectedTickets: selectedNormalTickets,
                        bookingId: nil
                    )
                } else {
                    switchToAddOnMode()
                }
                return
            }
        }
    }

    private func updateContinueBtnState(animated: Bool = true) {
        let shouldShow: Bool
        switch mode {
        case .normal:
            shouldShow = totalSelectedTickets > 0
        case .addOn:
            shouldShow = true
        }

        let hiddenBottom: CGFloat = -continueToCheckOutBtn.bounds.height - 24
        let shownBottom: CGFloat = 32

        let applyState = {
            self.continueToCheckOutBtn.isHidden = false
            self.continueButtonBottomConstraint.constant = shouldShow ? shownBottom : hiddenBottom
            self.continueToCheckOutBtn.alpha = shouldShow ? 1 : 0
            self.view.layoutIfNeeded()
        }

        if !animated {
            applyState()
            self.continueToCheckOutBtn.isHidden = !shouldShow
            return
        }

        if shouldShow && continueToCheckOutBtn.isHidden {
            continueToCheckOutBtn.isHidden = false
            continueToCheckOutBtn.alpha = 0
            continueButtonBottomConstraint.constant = hiddenBottom
            view.layoutIfNeeded()
        }

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0.6,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            applyState()
        } completion: { _ in
            if !shouldShow {
                self.continueToCheckOutBtn.isHidden = true
            }
        }
    }
}

extension TicketSelectionViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == ticketTableView {
            return isLoading ? 5 : tickets.count
        } else if tableView == groupTableView {
            return groupedNormalTickets.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if tableView == ticketTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketsTVC.identifier,
                for: indexPath
            ) as? TicketsTVC else {
                return UITableViewCell()
            }

            cell.selectionStyle = .none
            if isLoading {
                cell.showShimmer()
            } else {
                let ticket = tickets[indexPath.row]
                let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
                let isExpanded = expandedTicketDescriptions.contains(ticket.id ?? "")
                
                cell.hideShimmer()
                cell.configure(
                    ticket: ticket,
                    currency: currency,
                    whiteLabelColor: event?.whiteLabelColor,
                    eventTicketSetting: self.event?.eventTicketSettings,
                    isDescriptionExpanded: isExpanded,
                    isLinkDisabled: isTicketDisabledByLink(ticket)
                )
                
                cell.onPlusTap = { [weak self] ticket in
                    self?.handlePlus(ticket: ticket)
                }
                
                cell.onMinusTap = { [weak self] ticket in
                    self?.handleMinus(ticket: ticket)
                }
                
                cell.onRSVPTap = { [weak self] ticket in
                    self?.handleRSVP(ticket: ticket, cell: cell)
                }
                
                cell.onDescriptionToggle = { [weak self] in
                    guard let self = self, let id = ticket.id else { return }
                    if self.expandedTicketDescriptions.contains(id) {
                        self.expandedTicketDescriptions.remove(id)
                    } else {
                        self.expandedTicketDescriptions.insert(id)
                    }
                    
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            }

            return cell
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: GroupTicketTVC.identifier,
            for: indexPath
        ) as? GroupTicketTVC else {
            return UITableViewCell()
        }

        let item = groupedNormalTickets[indexPath.row]
        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"

//        cell.configure(
//            groupName: item.groupName,
//            tickets: item.tickets,
//            currency: currency,
//            whiteLabelColor: event?.whiteLabelColor,
//            eventTicketSetting: event?.eventTicketSettings,
//            expandedTicketDescriptions: expandedTicketDescriptions
//        )
        
        cell.configure(
            groupName: item.groupName,
            tickets: item.tickets,
            currency: currency,
            whiteLabelColor: event?.whiteLabelColor,
            eventTicketSetting: event?.eventTicketSettings,
            expandedTicketDescriptions: expandedTicketDescriptions,
            disabledTicketIds: disabledTicketIds
        )

        cell.onDescriptionToggle = { [weak self] ticket in
            guard let self = self, let id = ticket.id else { return }

            if self.expandedTicketDescriptions.contains(id) {
                self.expandedTicketDescriptions.remove(id)
            } else {
                self.expandedTicketDescriptions.insert(id)
            }

            self.groupTableView.beginUpdates()
            self.groupTableView.endUpdates()
            self.groupTableView.layoutIfNeeded()
            self.groupTableViewHeight.constant = self.groupTableView.contentSize.height
        }
        
        cell.selectionStyle = .none

        cell.onPlusTap = { [weak self] ticket in
            self?.handleGroupPlus(ticket: ticket)
        }

        cell.onMinusTap = { [weak self] ticket in
            self?.handleGroupMinus(ticket: ticket)
        }

        cell.onRSVPTap = { [weak self] ticket in
            self?.handleGroupRSVP(ticket: ticket)
        }
        
        cell.onRowTap = { [weak self] ticket in
            self?.handleGroupPlus(ticket: ticket)
        }
        cell.onHeightChanged = { [weak self] in
            guard let self = self else { return }

            UIView.performWithoutAnimation {
                self.groupTableView.performBatchUpdates(nil)
            }

            UIView.animate(
                withDuration: 0.28,
                delay: 0,
                usingSpringWithDamping: 0.95,
                initialSpringVelocity: 0.2,
                options: [.curveEaseInOut, .allowUserInteraction]
            ) {
                self.groupTableViewHeight.constant = self.groupTableView.contentSize.height
                self.view.layoutIfNeeded()
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView == ticketTableView else { return }

        let ticket = tickets[indexPath.row]
        guard !isTicketDisabledByLink(ticket) else { return }

        let currentCount = ticket.selectedTicketCount ?? 0
        guard currentCount == 0 else { return }

        handlePlus(ticket: ticket)
    }
}
