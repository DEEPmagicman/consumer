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
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var protectedTicketView: UIView!
    @IBOutlet weak var unLockTF: UITextField!
    @IBOutlet weak var unLockBtn: UIView!
    @IBOutlet weak var addOnTicketTitleView: UIView!
    @IBOutlet weak var addOnTicketTitleLbl: UILabel!
    @IBOutlet weak var groupTableView: UITableView!
    @IBOutlet weak var groupTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ticketTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var continueToCheckOutView: CheckoutBarView!
    @IBOutlet weak var backgroundContainerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var eventTitleView: UIView!
    @IBOutlet weak var ticketOptionsContainerView: UIView!
    @IBOutlet weak var ticketOptionsTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewTopConstraint: NSLayoutConstraint!
    
    var mode: TicketMode = .normal
    var event: Event?
    var venueDetails: ClipVenue?
    var preselectedNormalTickets: [EventTicket] = []
    var promotionLinkId = ""
    var promotionLinkUniqueCode = ""

    private var tickets: [EventTicket] = []
    private var normalTickets: [EventTicket] = []
    private var addOnTickets: [EventTicket] = []
    private var selectedNormalTickets: [EventTicket] = []
    private var groupedNormalTickets: [(groupId: String, groupName: String, tickets: [EventTicket])] = []
    private var expandedGroupIds: Set<String> = []
    private var expandedTicketDescriptions: Set<String> = []
    private var ticketLinks: [EventTicketLink] = []
    private var disabledTicketIds: Set<String> = []
    private var hasVisibleAddOnOptionsCache = false
    private var isLoading = true
    private var isCheckoutInProgress = false
    private let shimmerRowCount = 3
    private lazy var emptyStateView: V3EmptyStateView = {
        let view = V3EmptyStateView(style: .tickets)
        view.setTitle("No Tickets Available")
        return view
    }()
    private let posterHeaderView = EventPosterHeaderView()
    private let titleMarqueeLabel = PremiumMarqueeLabel()
    private lazy var interactionBlockerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var ticketListHeightObservation: NSKeyValueObservation?
    private var groupListHeightObservation: NSKeyValueObservation?
    private var isDescriptionHeightUpdateInProgress = false
    private var eventTicketId = [String]()
    private let groupRowSpacing: CGFloat = 12

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
        selectedNormalTickets = preselectedNormalTickets

        setupTableViews()
        setupTableViewObservers()
        setupContinueButton()
        setupUnlockButton()
        setupTitleMarqueeLabel()
        getTicketLinksAndSetup()
        setupHeaderData()
        applyWhiteLabelTheme()
        registerSocketDelegate()
    }

    deinit {
        unregisterSocketDelegate()
        ticketListHeightObservation?.invalidate()
        groupListHeightObservation?.invalidate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupPosterBackground()
        if shouldShowTicketEmptyState() {
            updateTicketTableHeight()
        }
        updateScrollBottomInset()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setCheckoutInProgress(false)
    }
    
    private func setupPosterBackground() {
        guard posterHeaderView.superview == nil else { return }

        posterHeaderView.applyBackgroundStyle(.softColorWash)
        backgroundContainerView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: backgroundContainerView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: backgroundContainerView.bottomAnchor)
        ])

        let imageURLString = event?.resolvedBackgroundImageURL(venue: venueDetails) ?? ""
        posterHeaderView.loadImage(from: imageURLString)
    }

    private func setupTableViews() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        removeScrollContentHeightConstraintIfNeeded()

        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        ticketTableView.register(TicketsTVC.nib, forCellReuseIdentifier: TicketsTVC.identifier)
        ticketTableView.register(
            TicketSelectionShimmerCell.self,
            forCellReuseIdentifier: TicketSelectionShimmerCell.identifier
        )
        ticketTableView.showsVerticalScrollIndicator = false
        ticketTableView.showsHorizontalScrollIndicator = false
        ticketTableView.isScrollEnabled = false
        ticketTableView.alwaysBounceVertical = false
        ticketTableView.contentInset = .zero
        ticketTableView.scrollIndicatorInsets = .zero
        ticketTableView.rowHeight = UITableView.automaticDimension
        ticketTableView.estimatedRowHeight = 150
        ticketTableView.sectionHeaderHeight = .leastNonzeroMagnitude
        ticketTableView.sectionFooterHeight = .leastNonzeroMagnitude
        if #available(iOS 11.0, *) {
            ticketTableView.contentInsetAdjustmentBehavior = .never
        }
        if #available(iOS 15.0, *) {
            ticketTableView.sectionHeaderTopPadding = 0
        }

        groupTableView.delegate = self
        groupTableView.dataSource = self
        groupTableView.showsVerticalScrollIndicator = false
        groupTableView.showsHorizontalScrollIndicator = false
        groupTableView.isScrollEnabled = false
        groupTableView.alwaysBounceVertical = false
        groupTableView.separatorStyle = .none
        groupTableView.backgroundColor = .clear
        groupTableView.contentInset = .zero
        groupTableView.scrollIndicatorInsets = .zero
        groupTableView.rowHeight = UITableView.automaticDimension
        groupTableView.estimatedRowHeight = 220
        groupTableView.sectionHeaderHeight = .leastNonzeroMagnitude
        groupTableView.sectionFooterHeight = .leastNonzeroMagnitude
        if #available(iOS 11.0, *) {
            groupTableView.contentInsetAdjustmentBehavior = .never
        }
        if #available(iOS 15.0, *) {
            groupTableView.sectionHeaderTopPadding = 0
        }
        groupTableView.register(GroupTicketTVC.nib, forCellReuseIdentifier: GroupTicketTVC.identifier)

        groupTableView.isHidden = true
        groupTableViewHeight.constant = 0
        ticketTableViewHeight.constant = 0
        updateTicketOptionsLayout()
    }

    private func removeScrollContentHeightConstraintIfNeeded() {
        guard let contentStackView = ticketTableView.superview else { return }

        scrollView.constraints
            .filter {
                ($0.firstItem as? UIView) === contentStackView &&
                ($0.secondItem as? UIView) === scrollView &&
                $0.firstAttribute == .height &&
                $0.secondAttribute == .height
            }
            .forEach { $0.isActive = false }
    }

    private func setupTableViewObservers() {
        ticketListHeightObservation = ticketTableView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
            guard let self else { return }
            guard !self.isDescriptionHeightUpdateInProgress else { return }
            self.updateTicketTableHeight()
        }

        groupListHeightObservation = groupTableView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
            guard let self else { return }
            guard !self.isDescriptionHeightUpdateInProgress else { return }
            self.updateGroupTableHeightFromContent()
        }
    }

    private func updateTicketTableHeight() {
        ticketTableView.layoutIfNeeded()
        let contentHeight = ceil(ticketTableView.contentSize.height)
        let shouldShowEmptyState = shouldShowTicketEmptyState()

        ticketTableView.backgroundView = shouldShowEmptyState
            ? emptyStateView
            : nil
        emptyStateView.isHidden = !shouldShowEmptyState

        if shouldShowEmptyState {
            ticketTableViewHeight.constant = emptyTicketTableHeight()
        } else {
            ticketTableViewHeight.constant = isLoading
                ? max(contentHeight, CGFloat(shimmerRowCount) * 150)
                : contentHeight
        }

        ticketTableView.contentOffset = .zero
        updateScrollBottomInset()
    }

    private func shouldShowTicketEmptyState() -> Bool {
        let hasGroupedTickets =
        mode == .normal &&
        !groupedNormalTickets.isEmpty

        return !isLoading &&
        tickets.isEmpty &&
        !hasGroupedTickets &&
        protectedTicketView.isHidden
    }

    private func emptyTicketTableHeight() -> CGFloat {
        let tableTop = ticketTableView
            .convert(ticketTableView.bounds, to: view)
            .minY

        let bottomLimit: CGFloat
        if continueToCheckOutView.isHidden {
            bottomLimit = view.bounds.height - view.safeAreaInsets.bottom
        } else {
            bottomLimit = continueToCheckOutView
                .convert(continueToCheckOutView.bounds, to: view)
                .minY
        }

        return max(320, bottomLimit - tableTop - 24)
    }

    private func updateGroupTableHeightFromContent() {
        groupTableView.layoutIfNeeded()
        groupTableViewHeight.constant = groupTableView.isHidden
            ? 0
            : ceil(groupTableView.contentSize.height)
        groupTableView.contentOffset = .zero
        updateScrollBottomInset()
    }

    private func resetTicketScrollPosition() {
        scrollView.setContentOffset(
            CGPoint(x: -scrollView.contentInset.left, y: -scrollView.contentInset.top),
            animated: false
        )
        ticketTableView.contentOffset = .zero
        groupTableView.contentOffset = .zero
    }

    private func updateScrollBottomInset(checkoutVisible: Bool? = nil) {
        let visible = checkoutVisible ?? (!continueToCheckOutView.isHidden || continueToCheckOutView.alpha > 0.01)
        let baselineInset: CGFloat = 18
        var bottomInset = baselineInset

        if visible {
            let scrollFrame = scrollView.convert(scrollView.bounds, to: view)
            let checkoutFrame = continueToCheckOutView.convert(continueToCheckOutView.bounds, to: view)
            let overlap = max(0, scrollFrame.maxY - checkoutFrame.minY)
            bottomInset = max(baselineInset + 10, overlap + baselineInset)
        }

        guard abs(scrollView.contentInset.bottom - bottomInset) > 0.5 else {
            clampScrollOffsetIfNeeded()
            return
        }

        scrollView.contentInset.bottom = bottomInset
        scrollView.scrollIndicatorInsets.bottom = bottomInset
        clampScrollOffsetIfNeeded()
    }

    private func clampScrollOffsetIfNeeded() {
        let minOffsetY = -scrollView.contentInset.top
        let maxOffsetY = max(
            minOffsetY,
            scrollView.contentSize.height + scrollView.contentInset.bottom - scrollView.bounds.height
        )

        if scrollView.contentOffset.y > maxOffsetY {
            scrollView.setContentOffset(
                CGPoint(x: scrollView.contentOffset.x, y: maxOffsetY),
                animated: false
            )
        } else if scrollView.contentOffset.y < minOffsetY {
            scrollView.setContentOffset(
                CGPoint(x: scrollView.contentOffset.x, y: minOffsetY),
                animated: false
            )
        }
    }

    private func setupContinueButton() {
        applyWhiteLabelTheme()
        continueToCheckOutView.delegate = self
        continueToCheckOutView.isHidden = true
        continueToCheckOutView.alpha = 0
        continueToCheckOutView.setButtonTitle("Continue to Checkout")
        view.addSubview(interactionBlockerView)
        NSLayoutConstraint.activate([
            interactionBlockerView.topAnchor.constraint(equalTo: view.topAnchor),
            interactionBlockerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            interactionBlockerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            interactionBlockerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private var whiteLabelAccentColor: UIColor {
        UIColor(hex: event?.resolvedWhiteLabelColor(venue: venueDetails) ?? Event.normalizedHexColor(venueDetails?.venueSettings?.whiteLabelColor))
    }

    private func applyWhiteLabelTheme() {
        let color = whiteLabelAccentColor

        dateandtimeLbl.textColor = color
        continueToCheckOutView?.applyAccentColor(color)
    }

    private func setCheckoutInProgress(_ inProgress: Bool) {
        isCheckoutInProgress = inProgress
        interactionBlockerView.isHidden = !inProgress
        if inProgress {
            view.bringSubviewToFront(interactionBlockerView)
        }
    }

    private func setupUnlockButton() {
        unLockTF.addTarget(self, action: #selector(unLockPassword), for: .editingChanged)
        updateUnlockButtonState()
    }

    private var unlockCode: String {
        (unLockTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var unlockIconImageView: UIImageView? {
        unLockBtn.subviews.compactMap { $0 as? UIImageView }.first
    }

    private func updateUnlockButtonState() {
        let isEnabled = !unlockCode.isEmpty
        unLockBtn.alpha = isEnabled ? 1 : 0.5
        unLockBtn.isUserInteractionEnabled = isEnabled

        guard let iconView = unlockIconImageView else { return }
        iconView.alpha = isEnabled ? 1 : 0.65

        iconView.image = UIImage(named: isEnabled ? "unLockIcon" : "lockIcon")
        iconView.tintColor = nil
    }

    private func venueTimezoneIdentifier() -> String {
        if let timezone = event?.venue?.timezone?.trimmingCharacters(in: .whitespacesAndNewlines),
           !timezone.isEmpty {
            return timezone
        }

        if let timezone = event?.venue?.useTimezone.trimmingCharacters(in: .whitespacesAndNewlines),
           !timezone.isEmpty {
            return timezone
        }

        if let timezone = venueDetails?.timezone?.trimmingCharacters(in: .whitespacesAndNewlines),
           !timezone.isEmpty {
            return timezone
        }

        let useTimezone = venueDetails?.useTimezone.trimmingCharacters(in: .whitespacesAndNewlines)
        if let useTimezone, !useTimezone.isEmpty {
            return useTimezone
        }

        return TimeZone.current.identifier
    }

    private func venueComparableDate(from date: Date) -> Date? {
        let timezone = TimeZone(identifier: venueTimezoneIdentifier()) ?? .current
        let venueFormatter = DateFormatter()
        venueFormatter.locale = Locale(identifier: "en_US_POSIX")
        venueFormatter.timeZone = timezone
        venueFormatter.dateFormat = DateFormat.yyyyMMddHHmmss.rawValue

        let comparableFormatter = DateFormatter()
        comparableFormatter.locale = Locale(identifier: "en_US_POSIX")
        comparableFormatter.timeZone = TimeZone(identifier: "UTC")
        comparableFormatter.dateFormat = DateFormat.yyyyMMddHHmmss.rawValue

        return comparableFormatter.date(from: venueFormatter.string(from: date))
    }

    private func venueNow() -> Date {
        venueComparableDate(from: Date()) ?? Date()
    }

    private func utcDate(_ value: String?) -> Date? {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = DateFormat.yyyyMMddHHmmss.rawValue
        return formatter.date(from: value)
    }

    private func ticketDate(_ value: String?) -> Date? {
        guard let utcDate = utcDate(value) else { return nil }
        return venueComparableDate(from: utcDate)
    }

    private func isTicketSoldOut(_ ticket: EventTicket) -> Bool {
        let remaining = ticket.remainingQuantity ?? max((ticket.issuedUnits ?? 0) - (ticket.soldUnits ?? 0), 0)
        return remaining <= 0
    }

    private func shouldHideSoldOutTicket(_ ticket: EventTicket) -> Bool {
        isTicketSoldOut(ticket) && event?.eventTicketSettings?.hideSoldOut == true
    }

    private func isTicketSaleStarted(_ ticket: EventTicket) -> Bool {
        let now = venueNow()
        guard let startSaleDate = ticketDate(ticket.beginSale) else { return true }
        return now >= startSaleDate
    }

    private func isTicketSaleNotEnded(_ ticket: EventTicket) -> Bool {
        let now = venueNow()
        guard let endSaleDate = ticketDate(ticket.endSale) else { return true }
        return now <= endSaleDate
    }

    private func isTicketSaleEnded(_ ticket: EventTicket) -> Bool {
        let now = venueNow()
        guard let endSaleDate = ticketDate(ticket.endSale) else { return false }
        return now > endSaleDate
    }

    private func isTicketAvailableForDisplay(_ ticket: EventTicket) -> Bool {
        ticket.isDeleted == false &&
        ticket.isMembersOnly != true &&
        ticket.sellingPaused == false &&
        isTicketSaleStarted(ticket) &&
        isTicketSaleNotEnded(ticket) &&
        !shouldHideSoldOutTicket(ticket)
    }

    private func filterAvailableTickets(_ list: [EventTicket]) -> [EventTicket] {
        var allTickets: [EventTicket] = []
        allTickets.append(contentsOf: event?.eventTicket ?? [])
        allTickets.append(contentsOf: event?.eventAddOnTicket ?? [])
        allTickets.append(contentsOf: event?.protectedEventTicket ?? [])
        allTickets.append(contentsOf: event?.protectedeventAddOnTicket ?? [])

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
            case "SELLS_OUT": conditionMatched = isTicketSoldOut(targetTicket) && !isTicketSaleEnded(targetTicket)
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

        venueName.text = event.displayVenueNameOrFallback(venueDetails?.name ?? "")
        setHeaderTitle(event.title)
        dateandtimeLbl.text = formattedDateText(for: event)
        applyWhiteLabelTheme()
    }

    private func setupTitleMarqueeLabel() {
        eventTitleView.backgroundColor = .clear
        titleMarqueeLabel.install(over: eventTitleLbl, horizontalInset: 72)
    }

    private func setHeaderTitle(_ title: String?) {
        titleMarqueeLabel.setText(title)
    }

    private func setupData() {
        guard let event = event else {
            isLoading = false
            tickets.removeAll()
            normalTickets.removeAll()
            addOnTickets.removeAll()
            groupedNormalTickets.removeAll()
            hasVisibleAddOnOptionsCache = false
            protectedTicketView.isHidden = true
            updateTicketOptionsLayout()
            ticketTableView.reloadData()
            groupTableView.reloadData()
            updateTicketTableHeight()
            updateGroupTableHeight()
            return
        }

        venueName.text = event.displayVenueNameOrFallback(venueDetails?.name ?? "")
        setHeaderTitle(event.title)
        dateandtimeLbl.text = formattedDateText(for: event)
        applyWhiteLabelTheme()
        disabledTicketIds.removeAll()

        let filteredNormal = filterAvailableTickets(event.eventTicket ?? [])
        let filteredAddOn = filterAvailableTickets(event.eventAddOnTicket ?? [])
        let filteredProtectedAddOn = filterAvailableTickets(event.protectedeventAddOnTicket ?? [])
        let split = makeGroupedTickets(from: filteredNormal)

        normalTickets = split.nonGrouped
        groupedNormalTickets = split.grouped
        let validGroupIds = Set(groupedNormalTickets.map { $0.groupId })
        expandedGroupIds = expandedGroupIds.intersection(validGroupIds)
        let validTicketIds = Set(
            (
                split.nonGrouped +
                split.grouped.flatMap { $0.tickets } +
                filteredAddOn +
                filteredProtectedAddOn
            )
            .compactMap { $0.id }
        )
        expandedTicketDescriptions =
            expandedTicketDescriptions.intersection(validTicketIds)
        addOnTickets = filteredAddOn
        hasVisibleAddOnOptionsCache = !filteredAddOn.isEmpty || !filteredProtectedAddOn.isEmpty

        groupTableView.reloadData()
        ticketTableView.reloadData()
        updateTicketTableHeight()
        updateGroupTableHeight()
        resetTicketScrollPosition()

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
        updateTicketOptionsLayout()
    }

    private func updateTicketOptionsLayout() {
        let shouldShowOptions =
        !addOnTicketTitleView.isHidden ||
        !protectedTicketView.isHidden

        ticketOptionsContainerView.isHidden = !shouldShowOptions
        ticketOptionsTopConstraint.constant = shouldShowOptions ? 24 : 14
        scrollViewTopConstraint.constant = shouldShowOptions ? 10 : 0
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
        updateTicketTableHeight()
        resetTicketScrollPosition()

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

        updateTicketTableHeight()
        updateGroupTableHeight()
        updateScrollBottomInset()
        resetTicketScrollPosition()
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
        updateTicketTableHeight()
        updateGroupTableHeightFromContent()
        updateScrollBottomInset()
        resetTicketScrollPosition()
    }

    private func makeGroupedTickets(from list: [EventTicket]) -> (nonGrouped: [EventTicket], grouped: [(groupId: String, groupName: String, tickets: [EventTicket])]) {
        var nonGrouped: [EventTicket] = []
        var groupOrder: [String] = []
        var groupedMap: [String: (groupId: String, groupName: String, tickets: [EventTicket])] = [:]

        for ticket in list {
            if let group = ticket.eventTicketGroupHasTicket?.eventTicketGroup,
               let groupId = group.id, !groupId.isEmpty {
                let groupName = group.name ?? ""
                if groupedMap[groupId] != nil {
                    groupedMap[groupId]?.tickets.append(ticket)
                } else {
                    groupOrder.append(groupId)
                    groupedMap[groupId] = (groupId: groupId, groupName: groupName, tickets: [ticket])
                }
            } else {
                nonGrouped.append(ticket)
            }
        }

        return (
            nonGrouped,
            groupOrder.compactMap { groupedMap[$0] }
        )
    }

    private func updateContinueButtonForMode() {
        switch mode {
        case .normal:
            continueToCheckOutView.setButtonTitle("Continue to Checkout")
        case .addOn:
            let anySelected = addOnTickets.contains(where: { ($0.selectedTicketCount ?? 0) > 0 })
            continueToCheckOutView.setButtonTitle(
                anySelected ? "Continue to Checkout" : "No Thanks"
            )
        }
    }

    private func updateGroupTableHeight() {
        groupTableView.reloadData()
        groupTableView.layoutIfNeeded()
        updateGroupTableHeightFromContent()
        view.layoutIfNeeded()
        updateScrollBottomInset()
    }

    private func updateGroupTableLayout() {
        groupTableView.beginUpdates()
        groupTableView.reloadData()
        groupTableView.endUpdates()
        groupTableView.layoutIfNeeded()
        updateGroupTableHeightFromContent()
        view.layoutIfNeeded()
        updateScrollBottomInset()
    }

    private func updateDescriptionRowHeight(
        in tableView: UITableView
    ) {
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        isDescriptionHeightUpdateInProgress = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tableView.beginUpdates()
        tableView.endUpdates()
        tableView.layoutIfNeeded()

        if tableView === ticketTableView {
            ticketTableViewHeight.constant = ceil(ticketTableView.contentSize.height)
        } else if tableView === groupTableView {
            groupTableViewHeight.constant = groupTableView.isHidden
                ? 0
                : ceil(groupTableView.contentSize.height)
        }

        updateScrollBottomInset()
        view.layoutIfNeeded()
        CATransaction.commit()
        isDescriptionHeightUpdateInProgress = false
        UIView.setAnimationsEnabled(animationsEnabled)
    }

    private func refreshGroupTicketRow(
        groupIndex: Int,
        ticketIndex: Int
    ) {
        expandedGroupIds.insert(groupedNormalTickets[groupIndex].groupId)

        let groupIndexPath = IndexPath(row: groupIndex, section: 0)

        if let cell = groupTableView.cellForRow(at: groupIndexPath) as? GroupTicketTVC {
            cell.updateTickets(
                groupedNormalTickets[groupIndex].tickets,
                reloadingTicketAt: ticketIndex
            )

            UIView.performWithoutAnimation {
                groupTableView.beginUpdates()
                groupTableView.endUpdates()
            }

            updateGroupTableHeightFromContent()
            view.layoutIfNeeded()
            updateScrollBottomInset()
            return
        }

        UIView.performWithoutAnimation {
            groupTableView.reloadRows(at: [groupIndexPath], with: .none)
            groupTableView.layoutIfNeeded()
        }
        updateGroupTableHeightFromContent()
        view.layoutIfNeeded()
        updateScrollBottomInset()
    }

    private func buildTicketsPayload(from selected: [EventTicket]) -> [[String: Any]] {
        selected.map {[
            "ticketId": $0.id ?? "",
            "ticketQuantity": $0.selectedTicketCount ?? 0,
            "ticketPrice": $0.price ?? 0
        ]}
    }

    private func hasVisibleAddOnOptions() -> Bool {
        hasVisibleAddOnOptionsCache
    }

    private func getTicketByPassWord() {
        eventService.fetchTicketsByPassword(
            eventId: event?.uniqueId ?? "",
            venueTimeZone: venueDetails?.useTimezone,
            password: unLockTF.text ?? ""
        ) { isSuccess, _, ticket in
            if isSuccess {
                let tickets = ticket ?? []

                guard !tickets.isEmpty else {
                    Alert.showToast("Invalid password. Please try again.")
                    return
                }

                for tics in tickets {
                    if !self.eventTicketId.contains(where: { $0 == tics.id }) {
                        self.eventTicketId.append(tics.id ?? "")
                    }
                }

                self.protectedTicketView.isHidden = self.event?.totalTickets == self.eventTicketId.count
                self.updateTicketOptionsLayout()

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
                Alert.showToast("Invalid password. Please try again.")
            }
        }
    }

    @objc func unLockPassword() {
        updateUnlockButtonState()
    }

    @IBAction func onClickUnLockBtn(
        _ sender: Any
    ) {

        let code = unlockCode

        guard !code.isEmpty,
              var event = event else {
            AppHaptic.warning()
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
            updateTicketOptionsLayout()
            return
        }

        let matched =
        displayable.filter {

            ($0.eventTicketHasPassword?.password ?? "")
                .caseInsensitiveCompare(code)
            == .orderedSame
        }

        guard !matched.isEmpty else {

            AppHaptic.error()
            Alert.showToast(
                "Invalid password. Please try again."
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
        updateTicketTableHeight()
        AppHaptic.success()
    }
    
    @IBAction func onClickCloseBtn(_ sender: Any) {
        AppHaptic.navigation()
        Navigate.to.back(self)
    }

    @IBAction func onClickLockBtn(_ sender: Any) {}

    @IBAction func onClickContinueBtn(_ sender: Any) {
        guard !isCheckoutInProgress else { return }

        guard LoginRequiredCoordinator.isAuthenticated else {
            AppHaptic.warning()
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                self?.onClickContinueBtn(sender)
            }
            return
        }

        guard let user = UserDefault.shared.user else { return }
        guard let event = event else { return }

        switch mode {
        case .normal:
            let selectedNormal = normalTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
            let selectedGrouped = groupedNormalTickets.flatMap { $0.tickets }.filter { ($0.selectedTicketCount ?? 0) > 0 }
            let selected = selectedNormal + selectedGrouped
            guard !selected.isEmpty else {
                AppHaptic.warning()
                return
            }

            AppHaptic.primaryAction()

            selectedNormalTickets = selected

            if hasVisibleAddOnOptions() {
                switchToAddOnMode()
            } else {
                beginBookingAfterUIUpdate(
                    event: event,
                    user: user,
                    tickets: selectedNormalTickets
                )
            }

        case .addOn:
            let selectedAddOns = addOnTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
            let finalSelected = selectedNormalTickets + selectedAddOns
            AppHaptic.primaryAction()
            beginBookingAfterUIUpdate(
                event: event,
                user: user,
                tickets: finalSelected
            )
        }
    }

    private func beginBookingAfterUIUpdate(
        event: Event,
        user: User,
        tickets: [EventTicket],
        rsvpCell: TicketsTVC? = nil
    ) {
        if let rsvpCell {
            rsvpCell.showRSVPLoader()
        } else {
            continueToCheckOutView.showLoader()
        }

        setCheckoutInProgress(true)

        DispatchQueue.main.async { [weak self, weak rsvpCell] in
            self?.createBooking(
                event: event,
                user: user,
                tickets: tickets,
                rsvpCell: rsvpCell
            )
        }
    }

    private func stopBookingLoader(rsvpCell: TicketsTVC?) {
        if let rsvpCell {
            rsvpCell.hideRSVPLoader()
        } else {
            continueToCheckOutView.hideLoader()
        }
    }

    private func createBooking(
        event: Event,
        user: User,
        tickets: [EventTicket],
        rsvpCell: TicketsTVC?
    ) {
        let payload = buildTicketsPayload(from: tickets)

        checkFreeTicketStockIfNeeded(
            event: event,
            user: user,
            tickets: tickets,
            payload: payload
        ) { [weak self] isAvailable, errMsg in
            guard let self else { return }

            guard isAvailable else {
                self.stopBookingLoader(rsvpCell: rsvpCell)
                self.setCheckoutInProgress(false)
                Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                return
            }

            self.createCheckedBooking(
                event: event,
                user: user,
                tickets: tickets,
                payload: payload
            )
        }
    }

    private func checkFreeTicketStockIfNeeded(
        event: Event,
        user: User,
        tickets: [EventTicket],
        payload: [[String: Any]],
        completion: @escaping (_ isAvailable: Bool, _ errMsg: String?) -> Void
    ) {

        guard isFreeTicketSelection(tickets) else {
            completion(true, nil)
            return
        }

        paymentService.checkEventTicketStock(
            eventId: event.id,
            code: user.code,
            phone: user.phone,
            gender: user.gender,
            userId: user.id,
            tickets: payload,
            completion: completion
        )
    }

    private func isFreeTicketSelection(_ tickets: [EventTicket]) -> Bool {
        let total = tickets.reduce(0.0) {
            $0 + (Double($1.selectedTicketCount ?? 0) * ($1.price ?? 0))
        }
        return total <= 0
    }

    private func checkRSVPStock(
        event: Event,
        user: User,
        ticket: EventTicket,
        completion: @escaping (Bool) -> Void
    ) {
        var ticket = ticket
        ticket.selectedTicketCount = 1
        let payload = buildTicketsPayload(from: [ticket])

        setCheckoutInProgress(true)
        paymentService.checkEventTicketStock(
            eventId: event.id,
            code: user.code,
            phone: user.phone,
            gender: user.gender,
            userId: user.id,
            tickets: payload
        ) { [weak self] isAvailable, errMsg in
            guard let self else { return }
            self.setCheckoutInProgress(false)

            guard isAvailable else {
                AppHaptic.error()
                Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                completion(false)
                return
            }

            completion(true)
        }
    }

    private func createCheckedBooking(
        event: Event,
        user: User,
        tickets: [EventTicket],
        payload: [[String: Any]]
    ) {

        paymentService.createEventBooking(
            eventId: event.id,
            code: user.code,
            phone: user.phone,
            gender: user.gender,
            userId: user.id,
            tickets: payload,
            promotionLinkId: promotionLinkId,
            promotionLinkUniqueCode: promotionLinkUniqueCode
        ) { [weak self] isSuccess, errMsg, id, _ in
            guard let self else { return }
            self.continueToCheckOutView.hideLoader()
            if isSuccess {
                AppHaptic.success()
//                Navigate.to.ticketCheckoutVC(self, event: event, selectedTickets: tickets, bookingId: id)
                Navigate.orderListVC(
                    self,
                    event: event,
                    selectedTickets: tickets,
                    bookingId: id,
                    paymentMethod: nil,
                    venueDetails: venueDetails,
                    promotionLinkId: promotionLinkId,
                    promotionLinkUniqueCode: promotionLinkUniqueCode
                )
            } else {
                self.setCheckoutInProgress(false)
                AppHaptic.error()
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

    private func applySoldCountUpdate(_ update: EventTicketSoldCountUpdate) {
        guard isCurrentEventTicketSoldCountUpdate(update) else { return }

        var didUpdate = false

        if var eventTickets = event?.eventTicket {
            didUpdate = updateTicketList(&eventTickets, with: update) || didUpdate
            event?.eventTicket = eventTickets
        }

        if var addOnTickets = event?.eventAddOnTicket {
            didUpdate = updateTicketList(&addOnTickets, with: update) || didUpdate
            event?.eventAddOnTicket = addOnTickets
        }

        if var protectedTickets = event?.protectedEventTicket {
            didUpdate = updateTicketList(&protectedTickets, with: update) || didUpdate
            event?.protectedEventTicket = protectedTickets
        }

        didUpdate = updateTicketList(&normalTickets, with: update) || didUpdate
        didUpdate = updateTicketList(&addOnTickets, with: update) || didUpdate
        didUpdate = updateTicketList(&selectedNormalTickets, with: update) || didUpdate

        for groupIndex in groupedNormalTickets.indices {
            didUpdate = updateTicketList(&groupedNormalTickets[groupIndex].tickets, with: update) || didUpdate
        }

        guard didUpdate else { return }

        tickets = mode == .normal ? normalTickets : addOnTickets
        setupData()
        updateCheckoutSummary()
        updateContinueBtnState()
        updateContinueButtonForMode()
    }

    private func isCurrentEventTicketSoldCountUpdate(_ update: EventTicketSoldCountUpdate) -> Bool {
        if let eventId = update.eventId,
           !eventId.isEmpty,
           eventId != event?.id {
            return false
        }

        return containsEventTicket(id: update.ticketId)
    }

    private func containsEventTicket(id: String) -> Bool {
        (event?.eventTicket?.contains { $0.id == id } == true) ||
        (event?.eventAddOnTicket?.contains { $0.id == id } == true) ||
        (event?.protectedEventTicket?.contains { $0.id == id } == true) ||
        normalTickets.contains { $0.id == id } ||
        addOnTickets.contains { $0.id == id } ||
        selectedNormalTickets.contains { $0.id == id } ||
        groupedNormalTickets.contains { group in
            group.tickets.contains { $0.id == id }
        }
    }

    private func updateTicketList(_ tickets: inout [EventTicket], with update: EventTicketSoldCountUpdate) -> Bool {
        guard let index = tickets.firstIndex(where: { $0.id == update.ticketId })
        else { return false }

        tickets[index] = ticket(tickets[index], applying: update)
        return true
    }

    private func ticket(_ ticket: EventTicket, applying update: EventTicketSoldCountUpdate) -> EventTicket {
        var ticket = ticket

        if let soldUnits = update.soldUnits {
            ticket.soldUnits = soldUnits
        }

        if let issuedUnits = update.issuedUnits {
            ticket.issuedUnits = issuedUnits
        }

        let remaining = max((ticket.issuedUnits ?? 0) - (ticket.soldUnits ?? 0), 0)
        if let selectedCount = ticket.selectedTicketCount,
           selectedCount > remaining {
            ticket.selectedTicketCount = remaining > 0 ? remaining : nil
        }

        return ticket
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
        reloadTicketRowIfNeeded(index)
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
        reloadTicketRowIfNeeded(index)
        updateContinueBtnState()
        updateContinueButtonForMode()
        updateCheckoutSummary()
    }

    private func reloadTicketRowIfNeeded(_ index: Int) {
        guard !isLoading,
              tickets.indices.contains(index),
              ticketTableView.numberOfRows(inSection: 0) > index
        else {
            UIView.performWithoutAnimation {
                ticketTableView.reloadData()
                updateTicketTableHeight()
            }
            return
        }

        UIView.performWithoutAnimation {
            ticketTableView.reloadRows(
                at: [IndexPath(row: index, section: 0)],
                with: .none
            )
            updateTicketTableHeight()
        }
    }

    private func visibleTicketCell(for ticket: EventTicket) -> TicketsTVC? {
        guard let ticketId = ticket.id else { return nil }

        if let ticketIndex = tickets.firstIndex(where: { $0.id == ticketId }) {
            return ticketTableView.cellForRow(
                at: IndexPath(row: ticketIndex, section: 0)
            ) as? TicketsTVC
        }

        for case let groupCell as GroupTicketTVC in groupTableView.visibleCells {
            if let ticketCell = groupCell.visibleTicketCell(for: ticketId) {
                return ticketCell
            }
        }

        return nil
    }

    private func handleRSVP(ticket: EventTicket, cell: TicketsTVC?) {

        guard !isCheckoutInProgress else { return }
        guard LoginRequiredCoordinator.isAuthenticated else {
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                guard let self else { return }
                self.handleRSVP(ticket: ticket, cell: self.visibleTicketCell(for: ticket))
            }
            return
        }
        guard !isTicketDisabledByLink(ticket),
              let event = event,
              let user = UserDefault.shared.user else { return }

        checkRSVPStock(event: event, user: user, ticket: ticket) { [weak self] isAvailable in
            guard isAvailable else { return }
            self?.selectRSVP(ticket: ticket, event: event, user: user)
        }
    }

    private func selectRSVP(ticket: EventTicket, event: Event, user: User) {
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

        if hasVisibleAddOnOptions() {
            switchToAddOnMode()
        } else {
            continueToCheckOutView.showLoader()
            setCheckoutInProgress(true)
            createCheckedBooking(
                event: event,
                user: user,
                tickets: selectedNormalTickets,
                payload: buildTicketsPayload(from: selectedNormalTickets)
            )
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
            refreshGroupTicketRow(groupIndex: groupIndex, ticketIndex: ticketIndex)
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
            refreshGroupTicketRow(groupIndex: groupIndex, ticketIndex: ticketIndex)
            return
        }
    }

    private func handleGroupRSVP(ticket: EventTicket, cell: TicketsTVC?) {

        guard !isCheckoutInProgress else { return }
        guard LoginRequiredCoordinator.isAuthenticated else {
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                guard let self else { return }
                self.handleGroupRSVP(ticket: ticket, cell: self.visibleTicketCell(for: ticket))
            }
            return
        }
        guard !isTicketDisabledByLink(ticket),
              let event = event,
              let ticketId = ticket.id,
              let user = UserDefault.shared.user else { return }

        checkRSVPStock(event: event, user: user, ticket: ticket) { [weak self] isAvailable in
            guard isAvailable else { return }
            self?.selectGroupRSVP(ticketId: ticketId, event: event, user: user)
        }
    }

    private func selectGroupRSVP(ticketId: String, event: Event, user: User) {
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

            expandedGroupIds.insert(groupedNormalTickets[groupIndex].groupId)

            let selected =
            groupedNormalTickets[groupIndex]
                .tickets[ticketIndex]

            selectedNormalTickets = [selected]

            if hasVisibleAddOnOptions() {
                switchToAddOnMode()
            } else {
                continueToCheckOutView.showLoader()
                setCheckoutInProgress(true)
                createCheckedBooking(
                    event: event,
                    user: user,
                    tickets: selectedNormalTickets,
                    payload: buildTicketsPayload(from: selectedNormalTickets)
                )
            }

            return
        }
    }

    private func updateCheckoutSummary() {
        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
        let currencyPosition = venueDetails?.venueSettings?.currencyPosition
        let count = checkoutTotalTicketCount

        continueToCheckOutView.updateSummary(
            currency: currency,
            currencyPosition: currencyPosition,
            count: count,
            subtotal: checkoutSubtotal,
            fees: checkoutExtraFees
        )
    }

    private func updateContinueBtnState(animated: Bool = true) {
        let shouldShow: Bool
        switch mode {
        case .normal:  shouldShow = totalSelectedTickets > 0
        case .addOn:   shouldShow = true
        }

        guard continueToCheckOutView.isHidden == shouldShow else { return }

        let shownBottom: CGFloat = 32

        continueToCheckOutView.isHidden = false
        continueButtonBottomConstraint.constant = shownBottom
        continueToCheckOutView.transform = shouldShow
        ? CGAffineTransform(translationX: 0, y: 40)
        : .identity
        updateScrollBottomInset(checkoutVisible: shouldShow)

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.continueToCheckOutView.alpha = shouldShow ? 1 : 0
            self.continueToCheckOutView.transform = shouldShow
            ? .identity
            : CGAffineTransform(translationX: 0, y: 40)
        } completion: { _ in
            self.continueToCheckOutView.isHidden = !shouldShow
            self.continueToCheckOutView.transform = .identity
            self.updateScrollBottomInset(checkoutVisible: shouldShow)
        }
    }
}

extension TicketSelectionViewController: CheckoutBarDelegate {

    func checkoutBarDidTapButton() {
        onClickContinueBtn(continueToCheckOutView as Any)
    }
}

extension TicketSelectionViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == ticketTableView {
            return isLoading ? shimmerRowCount : tickets.count
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
        if isLoading {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketSelectionShimmerCell.identifier,
                for: indexPath
            ) as? TicketSelectionShimmerCell else {
                return UITableViewCell()
            }

            cell.startShimmer()
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: TicketsTVC.identifier, for: indexPath) as? TicketsTVC else {
            return UITableViewCell()
        }

        cell.selectionStyle = .none

        guard tickets.indices.contains(indexPath.row) else {
            return cell
        }

        let ticket = tickets[indexPath.row]
        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
        let currencyPosition = venueDetails?.venueSettings?.currencyPosition
        let isExpanded = expandedTicketDescriptions.contains(ticket.id ?? "")

        cell.hideShimmer()
        cell.configure(
            ticket: ticket,
            currency: currency,
            currencyPosition: currencyPosition,
            whiteLabelColor: event?.resolvedWhiteLabelColor(venue: venueDetails),
            eventTicketSetting: event?.eventTicketSettings,
            isDescriptionExpanded: isExpanded,
            isLinkDisabled: isTicketDisabledByLink(ticket)
        )

        cell.onPlusTap = { [weak self] ticket in self?.handlePlus(ticket: ticket) }
        cell.onMinusTap = { [weak self] ticket in self?.handleMinus(ticket: ticket) }
        cell.onRSVPTap = { [weak self] ticket, cell in self?.handleRSVP(ticket: ticket, cell: cell) }
        cell.onDescriptionToggle = { [weak self, weak cell] in
            guard let self, let id = ticket.id else { return }
            if self.expandedTicketDescriptions.contains(id) {
                self.expandedTicketDescriptions.remove(id)
            } else {
                self.expandedTicketDescriptions.insert(id)
            }
            self.updateDescriptionRowHeight(in: tableView)
            cell?.removeDescriptionToggleControlAnimations()
        }

        return cell
    }

    private func groupTicketCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GroupTicketTVC.identifier, for: indexPath) as? GroupTicketTVC else {
            return UITableViewCell()
        }

        guard groupedNormalTickets.indices.contains(indexPath.row) else {
            return cell
        }

        let item = groupedNormalTickets[indexPath.row]
        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
        let currencyPosition = venueDetails?.venueSettings?.currencyPosition

        cell.selectionStyle = .none
        cell.configure(
            groupName: item.groupName,
            tickets: item.tickets,
            currency: currency,
            currencyPosition: currencyPosition,
            whiteLabelColor: event?.resolvedWhiteLabelColor(venue: venueDetails),
            eventTicketSetting: event?.eventTicketSettings,
            expandedTicketDescriptions: expandedTicketDescriptions,
            disabledTicketIds: disabledTicketIds,
            isExpanded: expandedGroupIds.contains(item.groupId),
            topSpacing: 0,
            bottomSpacing: indexPath.row == groupedNormalTickets.count - 1 ? 0 : groupRowSpacing
        )

        cell.onPlusTap = { [weak self] ticket in self?.handleGroupPlus(ticket: ticket) }
        cell.onMinusTap = { [weak self] ticket in self?.handleGroupMinus(ticket: ticket) }
        cell.onRSVPTap = { [weak self] ticket, cell in self?.handleGroupRSVP(ticket: ticket, cell: cell) }
        cell.onRowTap = { [weak self] ticket in self?.handleGroupPlus(ticket: ticket) }

        cell.onDescriptionToggle = { [weak self] ticket in
            guard let self, let id = ticket.id else { return }
            if self.expandedTicketDescriptions.contains(id) {
                self.expandedTicketDescriptions.remove(id)
            } else {
                self.expandedTicketDescriptions.insert(id)
            }
            self.updateDescriptionRowHeight(in: self.groupTableView)
            cell.visibleTicketCell(for: id)?.removeDescriptionToggleControlAnimations()
        }

        cell.onExpandChanged = { [weak self] isExpanded in
            guard let self else { return }
            if isExpanded {
                self.expandedGroupIds.insert(item.groupId)
            } else {
                self.expandedGroupIds.remove(item.groupId)
            }
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
                self.updateGroupTableHeightFromContent()
                self.view.layoutIfNeeded()
            }
        }

        return cell
    }

//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        .leastNonzeroMagnitude
//    }
//
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        .leastNonzeroMagnitude
//    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView == ticketTableView else { return }
        guard !isLoading else { return }
        guard tickets.indices.contains(indexPath.row) else { return }

        let ticket = tickets[indexPath.row]

        guard !isTicketDisabledByLink(ticket),
              (ticket.selectedTicketCount ?? 0) == 0 else {
            return
        }

        if isRSVPTicket(ticket),
           let cell = tableView.cellForRow(at: indexPath) as? TicketsTVC {
            AppHaptic.primaryAction()
            handleRSVP(ticket: ticket, cell: cell)
        } else {
            AppHaptic.stepperChanged()
            handlePlus(ticket: ticket)
        }
    }
    
    private func isRSVPTicket(_ ticket: EventTicket) -> Bool {
        let price = ticket.price ?? 0
        let extraFees = ticket.extraFees ?? 0
        return price == 0 && extraFees == 0
    }
}

private final class TicketSelectionShimmerCell: UITableViewCell {

    private let cardView = UIView()
    private let titleLine = ShimmerViewV3()
    private let priceLine = ShimmerViewV3()
    private let feeLine = ShimmerViewV3(frame: .zero, lighter: true)
    private let actionView = ShimmerViewV3(frame: .zero, lighter: true)

    private var shimmerViews: [ShimmerViewV3] {
        [
            titleLine,
            priceLine,
            feeLine,
            actionView
        ]
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        startShimmer()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow == nil {
            stopShimmer()
        } else {
            startShimmer()
        }
    }

    func startShimmer() {
        shimmerViews.forEach { $0.startShimmer() }
    }

    private func stopShimmer() {
        shimmerViews.forEach { $0.stopShimmer() }
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor(hex: "#6D6D6D", alpha: 0.18)
        cardView.layer.cornerRadius = 10
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        cardView.clipsToBounds = true

        contentView.addSubview(cardView)

        shimmerViews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
            $0.startShimmer()
        }

        titleLine.layer.cornerRadius = 6
        priceLine.layer.cornerRadius = 6
        feeLine.layer.cornerRadius = 5
        actionView.layer.cornerRadius = 16

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.heightAnchor.constraint(equalToConstant: 113),

            titleLine.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLine.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            titleLine.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.48),
            titleLine.heightAnchor.constraint(equalToConstant: 18),

            priceLine.leadingAnchor.constraint(equalTo: titleLine.leadingAnchor),
            priceLine.bottomAnchor.constraint(equalTo: feeLine.topAnchor, constant: -5),
            priceLine.widthAnchor.constraint(equalToConstant: 84),
            priceLine.heightAnchor.constraint(equalToConstant: 24),

            feeLine.topAnchor.constraint(equalTo: priceLine.bottomAnchor, constant: 12),
            feeLine.leadingAnchor.constraint(equalTo: priceLine.leadingAnchor),
            feeLine.widthAnchor.constraint(equalToConstant: 82),
            feeLine.heightAnchor.constraint(equalToConstant: 13),
            feeLine.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            actionView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            actionView.centerYAnchor.constraint(equalTo: priceLine.centerYAnchor),
            actionView.widthAnchor.constraint(equalToConstant: 58),
            actionView.heightAnchor.constraint(equalToConstant: 38)
        ])
    }
}

// MARK: - WebSocket

extension TicketSelectionViewController: WebSocketCallBackDelegate {

    func didUpdateEvent(eventId: String) {
        guard isCurrentEventUpdate(eventId) else { return }
        refreshEventDetailFromSocket()
    }

    func didUpdateEventTicketSoldCount(_ update: EventTicketSoldCountUpdate) {
        applySoldCountUpdate(update)
    }
}

private extension TicketSelectionViewController {

    func isCurrentEventUpdate(_ eventId: String) -> Bool {
        eventId == event?.uniqueId ||
        eventId == event?.id
    }

    func refreshEventDetailFromSocket() {
        guard let eventId = event?.uniqueId ?? event?.id else { return }

        let selectedCounts = selectedTicketCountsById()

        eventService.fetchV3EventDetail(
            eventId: eventId,
            venueTimeZone: venueDetails?.useTimezone,
            promotionLinkId: promotionLinkId,
            promotionLinkUniqueCode: promotionLinkUniqueCode
        ) { [weak self] isSuccess, _, detail, _ in
            guard let self,
                  isSuccess,
                  var refreshedEvent = detail?.event
            else { return }

            self.applySelectedCounts(selectedCounts, to: &refreshedEvent)
            self.event = refreshedEvent

            if let venue = refreshedEvent.venue {
                self.venueDetails = venue
                WebSocketWrapper.shared.updateSocketContext(venueId: venue.id)
            }

            self.applySelectedCounts(selectedCounts, to: &self.selectedNormalTickets)
            self.setupData()
            self.updateCheckoutSummary()
            self.updateContinueBtnState()
            self.updateContinueButtonForMode()
        }
    }

    func selectedTicketCountsById() -> [String: Int] {

        var selectedTickets: [EventTicket] = []

        selectedTickets += event?.eventTicket ?? []
        selectedTickets += event?.eventAddOnTicket ?? []
        selectedTickets += event?.protectedEventTicket ?? []
        selectedTickets += event?.protectedeventAddOnTicket ?? []
        selectedTickets += normalTickets
        selectedTickets += addOnTickets
        selectedTickets += selectedNormalTickets
        selectedTickets += groupedNormalTickets.flatMap { $0.tickets }

        return selectedTickets.reduce(into: [String: Int]()) { result, ticket in
            guard
                let id = ticket.id,
                let count = ticket.selectedTicketCount,
                count > 0
            else {
                return
            }

            result[id] = count
        }
    }

    func applySelectedCounts(_ counts: [String: Int], to event: inout Event) {
        applySelectedCounts(counts, to: &event.eventTicket)
        applySelectedCounts(counts, to: &event.eventAddOnTicket)
        applySelectedCounts(counts, to: &event.protectedEventTicket)
        applySelectedCounts(counts, to: &event.protectedeventAddOnTicket)
    }

    func applySelectedCounts(_ counts: [String: Int], to tickets: inout [EventTicket]?) {
        guard var updatedTickets = tickets else { return }
        applySelectedCounts(counts, to: &updatedTickets)
        tickets = updatedTickets
    }

    func applySelectedCounts(_ counts: [String: Int], to tickets: inout [EventTicket]) {
        for index in tickets.indices {
            guard let id = tickets[index].id else { continue }
            tickets[index].selectedTicketCount = counts[id]
        }
    }

    func registerSocketDelegate() {
        WebSocketWrapper.shared.updateSocketContext(venueId: venueDetails?.id ?? event?.venue?.id)
        WebSocketWrapper.shared.removeDelegate(self)
        WebSocketWrapper.shared.addDelegate(self) 
    }

    func unregisterSocketDelegate() {
        WebSocketWrapper.shared.removeDelegate(self)
    }
}
