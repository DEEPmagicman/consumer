import UIKit
import MHLoadingButton

enum TicketMode {
    case normal
    case addOn
}

class TicketSelectionViewController: UIViewController {

    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var ticketTableView: UITableView!
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
    @IBOutlet weak var continueToCheckOutView: UIView!
    @IBOutlet weak var totalAmountLbl: UILabel!
    @IBOutlet weak var totalTicketLbl: UILabel!
    @IBOutlet weak var extraFeesLbl: UILabel!
    @IBOutlet weak var backgroundContainerView: UIView!

    var mode: TicketMode = .normal
    var event: Event?
    var venueDetails: ClipVenue?

    private var tickets: [EventTicket] = []
    private var normalTickets: [EventTicket] = []
    private var addOnTickets: [EventTicket] = []
    private var selectedNormalTickets: [EventTicket] = []
    private var groupedNormalTickets: [(groupName: String, tickets: [EventTicket])] = []
    private var expandedTicketDescriptions: Set<String> = []
    private var ticketLinks: [EventTicketLink] = []
    private var disabledTicketIds: Set<String> = []
    private var isLoading = true
    private var isCheckoutInProgress = false
    private let posterHeaderView = EventPosterHeaderView()
    private lazy var interactionBlockerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var ticketListHeightObservation: NSKeyValueObservation?
    private var groupListHeightObservation: NSKeyValueObservation?
    private var eventTicketId = [String]()

    private let paymentService = PaymentService()
    private let eventService = EventService()
    
    private var totalSelectedTickets: Int {
        switch mode {
        case .normal:
            let normalTotal = normalTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
            let groupedTotal = groupedNormalTickets.flatMap { $0.tickets }.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
            return normalTotal + groupedTotal
        case .addOn:
            return tickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        }
    }

    private var allCurrentlySelectedTickets: [EventTicket] {
        switch mode {
        case .normal:
            let fromNormal = normalTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
            let fromGrouped = groupedNormalTickets.flatMap { $0.tickets }.filter { ($0.selectedTicketCount ?? 0) > 0 }
            return fromNormal + fromGrouped
        case .addOn:
            let fromAddOn = addOnTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
            return selectedNormalTickets + fromAddOn
        }
    }

    private var checkoutSubtotal: Double {
        allCurrentlySelectedTickets.reduce(0) {
            $0 + Double($1.price ?? 0) * Double($1.selectedTicketCount ?? 0)
        }
    }

    private var checkoutExtraFees: Double {
        allCurrentlySelectedTickets.reduce(0) {
            $0 + ($1.extraFees ?? 0) * Double($1.selectedTicketCount ?? 0)
        }
    }

    private var checkoutTotalTicketCount: Int {
        allCurrentlySelectedTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let venue = event?.venue {
            venueDetails = venue
        }

        setupTableViews()
        setupTableViewObservers()
        setupContinueButton()
        getTicketLinksAndSetup()
        setupHeaderData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupPosterBackground()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setCheckoutInProgress(false)
    }
    
    private func setupPosterBackground() {

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

    private func setupTableViews() {
        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        ticketTableView.register(TicketsTVC.nib, forCellReuseIdentifier: TicketsTVC.identifier)

        groupTableView.delegate = self
        groupTableView.dataSource = self
        groupTableView.register(GroupTicketTVC.nib, forCellReuseIdentifier: GroupTicketTVC.identifier)
    }

    private func setupTableViewObservers() {
        ticketListHeightObservation = ticketTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self else { return }
            self.ticketTableViewHeight.constant = self.ticketTableView.contentSize.height
            self.ticketTableView.layoutIfNeeded()
        }

        groupListHeightObservation = groupTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self else { return }
            self.groupTableViewHeight.constant = self.groupTableView.contentSize.height
            self.groupTableView.layoutIfNeeded()
        }
    }

    private func setupContinueButton() {
        continueToCheckOutBtn.indicator = MaterialLoadingIndicator(color: .black)
        view.addSubview(interactionBlockerView)
        NSLayoutConstraint.activate([
            interactionBlockerView.topAnchor.constraint(equalTo: view.topAnchor),
            interactionBlockerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            interactionBlockerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            interactionBlockerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setCheckoutInProgress(_ inProgress: Bool) {
        isCheckoutInProgress = inProgress
        interactionBlockerView.isHidden = !inProgress
        if inProgress {
            view.bringSubviewToFront(interactionBlockerView)
        }
    }

    private func ticketDate(_ value: String?) -> Date? {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return value.toDate(withFormat: .yyyyMMddHHmmss)
    }

    private func isTicketSoldOut(_ ticket: EventTicket) -> Bool {
        let remaining = ticket.remainingQuantity ?? max((ticket.issuedUnits ?? 0) - (ticket.soldUnits ?? 0), 0)
        return remaining <= 0
    }

    private func shouldHideSoldOutTicket(_ ticket: EventTicket) -> Bool {
        isTicketSoldOut(ticket) && event?.eventTicketSettings?.hideSoldOut == true
    }

    private func isTicketSaleStarted(_ ticket: EventTicket) -> Bool {
        guard let startSaleDate = ticketDate(ticket.beginSale) else { return true }
        return Date.venueNow(timezone: venueDetails?.useTimezone) >= startSaleDate
    }

    private func isTicketSaleNotEnded(_ ticket: EventTicket) -> Bool {
        guard let endSaleDate = ticketDate(ticket.endSale) else { return true }
        return Date.venueNow(timezone: venueDetails?.useTimezone) <= endSaleDate
    }

    private func isTicketSaleEnded(_ ticket: EventTicket) -> Bool {
        guard let endSaleDate = ticketDate(ticket.endSale) else { return false }
        return Date.venueNow(timezone: venueDetails?.useTimezone) > endSaleDate
    }

    private func isTicketAvailableForDisplay(_ ticket: EventTicket) -> Bool {
        ticket.isDeleted == false &&
        ticket.sellingPaused == false &&
        isTicketSaleStarted(ticket) &&
        isTicketSaleNotEnded(ticket) &&
        !shouldHideSoldOutTicket(ticket)
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

    private func linkedState(for ticket: EventTicket, in allTickets: [EventTicket]) -> (isHidden: Bool, isDisabled: Bool) {
        guard let ticketId = ticket.id else { return (false, false) }

        let validLinks = ticketLinks.filter {
            $0.eventTicketId == ticketId && $0.status == "ENABLED" && $0.isDeleted == false
        }

        guard !validLinks.isEmpty else { return (false, false) }

        var shouldHide = false
        var shouldDisable = false

        for link in validLinks {
            guard let targetId = link.targetEventTicketId,
                  let targetTicket = allTickets.first(where: { $0.id == targetId }) else { continue }

            let conditionMatched: Bool
            switch link.linkAction ?? "" {
            case "SELLS_OUT": conditionMatched = isTicketSoldOut(targetTicket)
            case "SALE_END":  conditionMatched = isTicketSaleEnded(targetTicket)
            default:          conditionMatched = false
            }

            if !conditionMatched {
                switch link.linkState ?? "" {
                case "HIDDEN_UNTIL":   shouldHide = true
                case "DISABLE_UNTIL":  shouldDisable = true
                default: break
                }
            }
        }

        return (shouldHide, shouldDisable)
    }

    private func setupHeaderData() {
        guard let event = event else { return }

        venueName.text = venueDetails?.name ?? ""
        eventTitleLbl.text = event.title
        dateandtimeLbl.text = formattedDateText(for: event)
    }

    private func setupData() {
        guard let event = event else { return }

        venueName.text = venueDetails?.name ?? ""
        eventTitleLbl.text = event.title
        dateandtimeLbl.text = formattedDateText(for: event)
        disabledTicketIds.removeAll()

        let filteredNormal = filterAvailableTickets(event.eventTicket ?? [])
        let filteredAddOn = filterAvailableTickets(event.eventAddOnTicket ?? [])
        let split = makeGroupedTickets(from: filteredNormal)

        normalTickets = split.nonGrouped
        groupedNormalTickets = split.grouped
        addOnTickets = filteredAddOn

        groupTableView.reloadData()
        ticketTableView.reloadData()
        updateGroupTableHeight()

//        let protectedVisible = filterAvailableTickets(event.protectedEventTicket ?? [])
//        protectedTicketView.isHidden = protectedVisible.isEmpty

        mode == .addOn ? switchToAddOnMode() : switchToNormalMode()
    }
    
    private func currentProtectedTickets() -> [EventTicket] {

        switch mode {

        case .normal:

            return event?.protectedEventTicket ?? []

        case .addOn:

            return event?.protectedeventAddOnTicket ?? []
        }
    }
    
    private func updateProtectedTicketVisibility() {

        let protectedTickets =
        filterAvailableTickets(
            currentProtectedTickets()
        )

        protectedTicketView.isHidden =
        protectedTickets.isEmpty
    }

    private func formattedDateText(for event: Event) -> String {
        if let customText = event.openTimeCustomText, !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customText
        }

        let timezone = venueDetails?.useTimezone ?? ""
        let dateText = event.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, customTimeZone: timezone)
        let startTime = event.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: timezone)
        let endTime = event.endDateTime?.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: timezone) ?? "LATE"
        return "\(dateText) at \(startTime) - \(endTime)"
    }

    private func getTicketLinksAndSetup() {
        isLoading = true
        ticketTableView.reloadData()

        guard let eventId = event?.uniqueId else {
            isLoading = false
            setupData()
            return
        }

        eventService.fetchTicketLinks(eventId: eventId) { [weak self] isSuccess, _, links in
            guard let self else { return }
            self.ticketLinks = isSuccess ? (links ?? []) : []
            self.isLoading = false
            self.setupData()
        }
    }

    private func switchToNormalMode() {

        mode = .normal

        tickets = normalTickets

        addOnTicketTitleView.isHidden = true

        groupTableView.isHidden =
        groupedNormalTickets.isEmpty

        updateProtectedTicketVisibility()

        updateContinueButtonForMode()

        updateContinueBtnState()

        updateCheckoutSummary()

        ticketTableView.reloadData()

        groupTableView.reloadData()

        updateGroupTableHeight()
    }

    private func switchToAddOnMode() {

        mode = .addOn

        tickets = addOnTickets

        addOnTicketTitleView.isHidden = false

        groupTableView.isHidden = true

        updateProtectedTicketVisibility()

        updateContinueButtonForMode()

        updateContinueBtnState()

        updateCheckoutSummary()

        ticketTableView.reloadData()
    }

    private func makeGroupedTickets(from list: [EventTicket]) -> (nonGrouped: [EventTicket], grouped: [(groupName: String, tickets: [EventTicket])]) {
        var nonGrouped: [EventTicket] = []
        var groupedMap: [String: (groupName: String, tickets: [EventTicket])] = [:]

        for ticket in list {
            if let group = ticket.eventTicketGroupHasTicket?.eventTicketGroup,
               let groupId = group.id, !groupId.isEmpty {
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

        return (nonGrouped, Array(groupedMap.values))
    }

    private func updateContinueButtonForMode() {
        switch mode {
        case .normal:
            continueToCheckOutBtn.setTitle("Continue to Checkout", for: .normal)
        case .addOn:
            let anySelected = addOnTickets.contains(where: { ($0.selectedTicketCount ?? 0) > 0 })
            continueToCheckOutBtn.setTitle(anySelected ? "Continue to Checkout" : "No Thanks", for: .normal)
        }
    }

    private func updateGroupTableHeight() {
        groupTableView.reloadData()
        groupTableView.layoutIfNeeded()
        groupTableViewHeight.constant = groupTableView.contentSize.height
        view.layoutIfNeeded()
    }

    private func updateGroupTableLayout() {
        groupTableView.beginUpdates()
        groupTableView.reloadData()
        groupTableView.endUpdates()
        groupTableView.layoutIfNeeded()
        groupTableViewHeight.constant = groupTableView.contentSize.height
        view.layoutIfNeeded()
    }

    private func buildTicketsPayload(from selected: [EventTicket]) -> [[String: Any]] {
        selected.map {[
            "ticketId": $0.id ?? "",
            "ticketQuantity": $0.selectedTicketCount ?? 0,
            "ticketPrice": $0.price ?? 0
        ]}
    }

    private func getTicketByPassWord() {
        eventService.fetchTicketsByPassword(
            eventId: event?.uniqueId ?? "",
            venueTimeZone: venueDetails?.useTimezone,
            password: unLockTF.text ?? ""
        ) { isSuccess, errMsg, ticket in
            if isSuccess {
                let tickets = ticket ?? []

                for tics in tickets {
                    if !self.eventTicketId.contains(where: { $0 == tics.id }) {
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

    @objc func unLockPassword() {}

    @IBAction func onClickUnLockBtn(
        _ sender: Any
    ) {

        let code =
        (unLockTF.text ?? "")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !code.isEmpty,
              var event = event else {
            return
        }

        let protectedList =
        currentProtectedTickets()

        let displayable =
        filterAvailableTickets(
            protectedList
        )

        guard !displayable.isEmpty else {

            protectedTicketView.isHidden = true
            return
        }

        let matched =
        displayable.filter {

            ($0.eventTicketHasPassword?.password ?? "")
                .caseInsensitiveCompare(code)
            == .orderedSame
        }

        guard !matched.isEmpty else {

            Alert.showToast(
                "Invalid password please try again"
            )

            return
        }

        let valid =
        filterAvailableTickets(matched)

        switch mode {

        case .normal:

            for ticket in valid
            where !normalTickets.contains(
                where: { $0.id == ticket.id }
            ) {

                normalTickets.append(ticket)
            }

        case .addOn:

            for ticket in valid
            where !addOnTickets.contains(
                where: { $0.id == ticket.id }
            ) {

                addOnTickets.append(ticket)
            }
        }

        let unlockedIds =
        Set(valid.compactMap { $0.id })

        switch mode {

        case .normal:

            event.protectedEventTicket =
            protectedList.filter {

                guard let id = $0.id else {
                    return true
                }

                return !unlockedIds.contains(id)
            }

        case .addOn:

            event.protectedeventAddOnTicket =
            protectedList.filter {

                guard let id = $0.id else {
                    return true
                }

                return !unlockedIds.contains(id)
            }
        }

        self.event = event

        unLockTF.text = ""

        unLockPassword()

        updateProtectedTicketVisibility()

        switch mode {

        case .normal:

            tickets = normalTickets

        case .addOn:

            tickets = addOnTickets
        }

        ticketTableView.reloadData()
    }
    
    @IBAction func onClickCloseBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickLockBtn(_ sender: Any) {}

    @IBAction func onClickContinueBtn(_ sender: Any) {
        guard !isCheckoutInProgress else { return }

        guard let user = UserDefault.shared.user else {
            Navigate.to.openPhoneLoginPopup(self)
            return
        }

        guard let event = event else { return }

        switch mode {
        case .normal:
            let selectedNormal = normalTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
            let selectedGrouped = groupedNormalTickets.flatMap { $0.tickets }.filter { ($0.selectedTicketCount ?? 0) > 0 }
            let selected = selectedNormal + selectedGrouped
            guard !selected.isEmpty else { return }

            selectedNormalTickets = selected

            if addOnTickets.isEmpty {
                continueToCheckOutBtn.showLoader(userInteraction: false)
                setCheckoutInProgress(true)
                createBooking(event: event, user: user, tickets: selectedNormalTickets)
            } else {
                switchToAddOnMode()
            }

        case .addOn:
            let selectedAddOns = addOnTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
            let finalSelected = selectedNormalTickets + selectedAddOns
            continueToCheckOutBtn.showLoader(userInteraction: false)
            setCheckoutInProgress(true)
            createBooking(event: event, user: user, tickets: finalSelected)
        }
    }

    private func createBooking(event: Event, user: User, tickets: [EventTicket]) {
        let payload = buildTicketsPayload(from: tickets)
        paymentService.createEventBooking(
            eventId: event.id,
            code: user.code,
            phone: user.phone,
            gender: user.gender,
            userId: user.id,
            tickets: payload
        ) { [weak self] isSuccess, errMsg, id, _ in
            guard let self else { return }
            self.continueToCheckOutBtn.hideLoader()
            if isSuccess {
//                Navigate.to.ticketCheckoutVC(self, event: event, selectedTickets: tickets, bookingId: id)
                Navigate.orderListVC(
                    self,
                    event: event,
                    selectedTickets: tickets,
                    bookingId: id,
                    paymentMethod: nil
                )
            } else {
                self.setCheckoutInProgress(false)
                Alert.showToast(errMsg ?? "Something went wrong")
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
            if let idx = normalTickets.firstIndex(where: { $0.id == id }) { normalTickets[idx] = updated }
            tickets = normalTickets
        case .addOn:
            if let idx = addOnTickets.firstIndex(where: { $0.id == id }) { addOnTickets[idx] = updated }
            tickets = addOnTickets
        }
    }

    private func handlePlus(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket), let index = indexForTicket(ticket) else { return }

        let current = tickets[index]
        let currentCount = current.selectedTicketCount ?? 0
        let issuedUnits = current.issuedUnits ?? 0
        let remaining = current.remainingQuantity ?? max(issuedUnits - (current.soldUnits ?? 0), 0)
        let minQty = max(current.miniPurchaseQuantity ?? 1, 1)
        let maxQty = current.maxPurchaseQuantity ?? Int.max
        let sellInMultiples = current.sellInMultiples == true

        let nextCount = sellInMultiples
            ? (currentCount == 0 ? minQty : currentCount + minQty)
            : currentCount + 1

        guard nextCount <= min(issuedUnits, remaining, maxQty) else {
            Alert.showToast("Max tickets selected: create a separate order to purchase more.")
            return
        }

        tickets[index].selectedTicketCount = nextCount
        replaceTicketInCurrentMode(tickets[index])
        ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        updateContinueBtnState()
        updateContinueButtonForMode()
        updateCheckoutSummary()
    }

    private func handleMinus(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket), let index = indexForTicket(ticket) else { return }

        let current = tickets[index]
        let currentCount = current.selectedTicketCount ?? 0
        guard currentCount > 0 else { return }

        let minQty = max(current.miniPurchaseQuantity ?? 1, 1)
        let sellInMultiples = current.sellInMultiples == true
        let nextCount = sellInMultiples ? currentCount - minQty : currentCount - 1

        tickets[index].selectedTicketCount = nextCount > 0 ? nextCount : nil
        replaceTicketInCurrentMode(tickets[index])
        ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        updateContinueBtnState()
        updateContinueButtonForMode()
        updateCheckoutSummary()
    }

    private func handleRSVP(ticket: EventTicket, cell: TicketsTVC) {

        guard !isCheckoutInProgress else { return }
        guard !isTicketDisabledByLink(ticket),
              let event = event else { return }
        
        normalTickets.indices.forEach {
            normalTickets[$0].selectedTicketCount = nil
        }

        for groupIndex in groupedNormalTickets.indices {
            for ticketIndex in groupedNormalTickets[groupIndex].tickets.indices {
                groupedNormalTickets[groupIndex].tickets[ticketIndex].selectedTicketCount = nil
            }
        }

        var updatedTicket = ticket
        updatedTicket.selectedTicketCount = 1

        if let index = normalTickets.firstIndex(where: { $0.id == updatedTicket.id }) {
            normalTickets[index].selectedTicketCount = 1
            updatedTicket = normalTickets[index]
        }

        selectedNormalTickets = [updatedTicket]

        if addOnTickets.isEmpty {
            setCheckoutInProgress(true)
            Navigate.to.ticketCheckoutVC(
                self,
                event: event,
                selectedTickets: selectedNormalTickets,
                bookingId: nil
            )
        } else {
            switchToAddOnMode()
        }
    }

    private func handleGroupPlus(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket), let ticketId = ticket.id else { return }

        for groupIndex in groupedNormalTickets.indices {
            guard let ticketIndex = groupedNormalTickets[groupIndex].tickets.firstIndex(where: { $0.id == ticketId }) else { continue }

            let current = groupedNormalTickets[groupIndex].tickets[ticketIndex]
            let currentCount = current.selectedTicketCount ?? 0
            let issuedUnits = current.issuedUnits ?? 0
            let remaining = current.remainingQuantity ?? max(issuedUnits - (current.soldUnits ?? 0), 0)
            let minQty = max(current.miniPurchaseQuantity ?? 1, 1)
            let maxQty = current.maxPurchaseQuantity ?? Int.max
            let sellInMultiples = current.sellInMultiples == true

            let nextCount = sellInMultiples
                ? (currentCount == 0 ? minQty : currentCount + minQty)
                : currentCount + 1

            guard nextCount <= min(issuedUnits, remaining, maxQty) else {
                Alert.showToast("Max tickets selected: create a separate order to purchase more.")
                return
            }

            groupedNormalTickets[groupIndex].tickets[ticketIndex].selectedTicketCount = nextCount
            updateContinueBtnState()
            updateContinueButtonForMode()
            updateCheckoutSummary()
            updateGroupTableLayout()
            return
        }
    }

    private func handleGroupMinus(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket), let ticketId = ticket.id else { return }

        for groupIndex in groupedNormalTickets.indices {
            guard let ticketIndex = groupedNormalTickets[groupIndex].tickets.firstIndex(where: { $0.id == ticketId }) else { continue }

            let current = groupedNormalTickets[groupIndex].tickets[ticketIndex]
            let currentCount = current.selectedTicketCount ?? 0
            guard currentCount > 0 else { return }

            let minQty = max(current.miniPurchaseQuantity ?? 1, 1)
            let sellInMultiples = current.sellInMultiples == true
            let nextCount = sellInMultiples ? currentCount - minQty : currentCount - 1

            groupedNormalTickets[groupIndex].tickets[ticketIndex].selectedTicketCount = nextCount > 0 ? nextCount : nil
            updateContinueBtnState()
            updateContinueButtonForMode()
            updateCheckoutSummary()
            updateGroupTableLayout()
            return
        }
    }

    private func handleGroupRSVP(ticket: EventTicket) {

        guard !isCheckoutInProgress else { return }
        guard !isTicketDisabledByLink(ticket),
              let event = event,
              let ticketId = ticket.id else { return }

        // Remove all previous selections
        normalTickets.indices.forEach {
            normalTickets[$0].selectedTicketCount = nil
        }

        for groupIndex in groupedNormalTickets.indices {
            for ticketIndex in groupedNormalTickets[groupIndex].tickets.indices {
                groupedNormalTickets[groupIndex].tickets[ticketIndex].selectedTicketCount = nil
            }
        }

        for groupIndex in groupedNormalTickets.indices {

            guard let ticketIndex = groupedNormalTickets[groupIndex]
                .tickets
                .firstIndex(where: { $0.id == ticketId }) else { continue }

            // Select only RSVP ticket
            groupedNormalTickets[groupIndex]
                .tickets[ticketIndex]
                .selectedTicketCount = 1

            let selected =
            groupedNormalTickets[groupIndex]
                .tickets[ticketIndex]

            selectedNormalTickets = [selected]

            if addOnTickets.isEmpty {
                setCheckoutInProgress(true)
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

    private func updateCheckoutSummary() {
        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
        let count = checkoutTotalTicketCount
        let subtotal = checkoutSubtotal
        let fees = checkoutExtraFees

        totalTicketLbl.text = "\(count) Ticket\(count == 1 ? "" : "s")"
        totalAmountLbl.text = "\(currency)\(subtotal.decimalFormat(true))"

        if fees > 0 {
            extraFeesLbl.isHidden = false
            extraFeesLbl.text = "Incl. \(currency)\(fees.decimalFormat(true)) in fees"
        } else {
            extraFeesLbl.isHidden = true
        }
    }

    private func updateContinueBtnState(animated: Bool = true) {
        let shouldShow: Bool
        switch mode {
        case .normal:  shouldShow = totalSelectedTickets > 0
        case .addOn:   shouldShow = true
        }

        guard continueToCheckOutView.isHidden == shouldShow else { return }

        let hiddenBottom: CGFloat = -continueToCheckOutView.bounds.height - 24
        let shownBottom: CGFloat = 32

        continueToCheckOutView.isHidden = false

        UIView.animate(withDuration: 0.25) {
            self.continueButtonBottomConstraint.constant = shouldShow ? shownBottom : hiddenBottom
            self.continueToCheckOutView.alpha = shouldShow ? 1 : 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.continueToCheckOutView.isHidden = !shouldShow
        }
    }
}

extension TicketSelectionViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == ticketTableView {
            return isLoading ? 4 : tickets.count
        } else if tableView == groupTableView {
            return groupedNormalTickets.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == ticketTableView {
            return ticketCell(for: indexPath, in: tableView)
        }
        return groupTicketCell(for: indexPath, in: tableView)
    }

    private func ticketCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TicketsTVC.identifier, for: indexPath) as? TicketsTVC else {
            return UITableViewCell()
        }

        cell.selectionStyle = .none

        if isLoading {
            cell.showShimmer()
            return cell
        }

        let ticket = tickets[indexPath.row]
        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
        let isExpanded = expandedTicketDescriptions.contains(ticket.id ?? "")

        cell.hideShimmer()
        cell.configure(
            ticket: ticket,
            currency: currency,
            whiteLabelColor: event?.whiteLabelColor,
            eventTicketSetting: event?.eventTicketSettings,
            isDescriptionExpanded: isExpanded,
            isLinkDisabled: isTicketDisabledByLink(ticket)
        )

        cell.onPlusTap = { [weak self] ticket in self?.handlePlus(ticket: ticket) }
        cell.onMinusTap = { [weak self] ticket in self?.handleMinus(ticket: ticket) }
        cell.onRSVPTap = { [weak self] ticket in self?.handleRSVP(ticket: ticket, cell: cell) }
        cell.onDescriptionToggle = { [weak self] in
            guard let self, let id = ticket.id else { return }
            if self.expandedTicketDescriptions.contains(id) {
                self.expandedTicketDescriptions.remove(id)
            } else {
                self.expandedTicketDescriptions.insert(id)
            }
            tableView.beginUpdates()
            tableView.endUpdates()
        }

        return cell
    }

    private func groupTicketCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GroupTicketTVC.identifier, for: indexPath) as? GroupTicketTVC else {
            return UITableViewCell()
        }

        let item = groupedNormalTickets[indexPath.row]
        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"

        cell.selectionStyle = .none
        cell.configure(
            groupName: item.groupName,
            tickets: item.tickets,
            currency: currency,
            whiteLabelColor: event?.whiteLabelColor,
            eventTicketSetting: event?.eventTicketSettings,
            expandedTicketDescriptions: expandedTicketDescriptions,
            disabledTicketIds: disabledTicketIds
        )

        cell.onPlusTap = { [weak self] ticket in self?.handleGroupPlus(ticket: ticket) }
        cell.onMinusTap = { [weak self] ticket in self?.handleGroupMinus(ticket: ticket) }
        cell.onRSVPTap = { [weak self] ticket in self?.handleGroupRSVP(ticket: ticket) }
        cell.onRowTap = { [weak self] ticket in self?.handleGroupPlus(ticket: ticket) }

        cell.onDescriptionToggle = { [weak self] ticket in
            guard let self, let id = ticket.id else { return }
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

        cell.onHeightChanged = { [weak self] in
            guard let self else { return }
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

        guard !isTicketDisabledByLink(ticket),
              (ticket.selectedTicketCount ?? 0) == 0 else {
            return
        }

        if isRSVPTicket(ticket),
           let cell = tableView.cellForRow(at: indexPath) as? TicketsTVC {
            handleRSVP(ticket: ticket, cell: cell)
        } else {
            handlePlus(ticket: ticket)
        }
    }
    
    private func isRSVPTicket(_ ticket: EventTicket) -> Bool {
        let price = ticket.price ?? 0
        let extraFees = ticket.extraFees ?? 0
        return price == 0 && extraFees == 0
    }
}
