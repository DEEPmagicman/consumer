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
    @IBOutlet weak var backgroundContainerView: UIView!
    @IBOutlet weak var navBarHiddenView: UIView!
    @IBOutlet weak var navVenueNameLbl: UILabel!
    @IBOutlet weak var navTimeLbl: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var ticketsSectionView: UIView!

    private let posterHeaderView = VenuePosterHeaderView()
    private let stickyTopBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let stickyTicketsTitleContainer = UIView()
    private let stickyTicketsTitleLabel = UILabel()

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
    private var tableViewHeightObserver: NSKeyValueObservation?
    private var lastTableContentHeight: CGFloat = 0
    private var lastScrollBottomInset: CGFloat = -1

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
        setupScreen()
        setupStickyTicketsTitle()
        setupPosterBackground()
        setupScrollBehavior()
        observeTableViewHeight()
        setupCoverTickets()
        getUpsellTickets()
        updateCheckoutState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableViewHeight(animated: false)
        updateScrollAllowance()
        updateStickyNavigation(for: scrollView.contentOffset.y)
    }

    deinit {
        tableViewHeightObserver?.invalidate()
    }
}

// MARK: - Setup

private extension CoverTicketListVC {

    func setupScrollBehavior() {
        scrollView.delegate = self
        scrollView.isScrollEnabled = true
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delaysContentTouches = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }

        tableView.isScrollEnabled = false
        tableView.alwaysBounceVertical = false
    }

    func setupPosterBackground() {
        backgroundContainerView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: backgroundContainerView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: backgroundContainerView.bottomAnchor)
        ])

        let imageUrlString = "\(SharedURL.amazonStorage)\(venueDetails?.venueAttachment?.first?.key ?? "")"
        posterHeaderView.loadImage(from: imageUrlString)
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false           // outer scrollView handles scrolling
        tableView.alwaysBounceVertical = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220

        tableView.register(
            TicketsTVC.nib,
            forCellReuseIdentifier: TicketsTVC.identifier
        )
    }

    func setupScreen() {
        let logoUrl = "\(SharedURL.amazonStorage)\(venueDetails?.logo?.key ?? "")"
        venueImage.sd_setImage(with: URL(string: logoUrl), completed: nil)

        venueName.text = venueDetails?.name ?? ""
        timeLbl.text = venueDetails?.timezone
        navVenueNameLbl.text = venueDetails?.name ?? ""
        navTimeLbl.text = venueDetails?.timezone

        if let hexColor = venueDetails?.venueSettings?.whiteLabelColor {
            timeLbl.textColor = UIColor(hex: hexColor)
            navTimeLbl.textColor = UIColor(hex: hexColor)
        }

        navBarHiddenView.isHidden = true
        navBarHiddenView.alpha = 0
        continueToCheckoutBtn.isHidden = true
        continueToCheckoutBtn.alpha = 0
        continueToCheckoutBtn.delegate = self
    }

    func setupStickyTicketsTitle() {
        stickyTopBlurView.translatesAutoresizingMaskIntoConstraints = false
        stickyTopBlurView.isHidden = true
        stickyTopBlurView.alpha = 0
        stickyTopBlurView.isUserInteractionEnabled = false

        stickyTicketsTitleContainer.translatesAutoresizingMaskIntoConstraints = false
//        stickyTicketsTitleContainer.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        stickyTicketsTitleContainer.isHidden = true
        stickyTicketsTitleContainer.alpha = 0
        stickyTicketsTitleContainer.isUserInteractionEnabled = false

        stickyTicketsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stickyTicketsTitleLabel.textAlignment = ticketsTitleLbl.textAlignment
        stickyTicketsTitleLabel.lineBreakMode = ticketsTitleLbl.lineBreakMode
        stickyTicketsTitleLabel.numberOfLines = ticketsTitleLbl.numberOfLines
        stickyTicketsTitleContainer.addSubview(stickyTicketsTitleLabel)

        view.insertSubview(stickyTopBlurView, aboveSubview: scrollView)
        view.insertSubview(stickyTicketsTitleContainer, aboveSubview: stickyTopBlurView)

        NSLayoutConstraint.activate([
            stickyTopBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            stickyTopBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickyTopBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stickyTopBlurView.bottomAnchor.constraint(equalTo: stickyTicketsTitleContainer.bottomAnchor, constant: 16),

            stickyTicketsTitleContainer.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stickyTicketsTitleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickyTicketsTitleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stickyTicketsTitleContainer.heightAnchor.constraint(equalTo: ticketsTitleLbl.heightAnchor),

            stickyTicketsTitleLabel.topAnchor.constraint(equalTo: stickyTicketsTitleContainer.topAnchor),
            stickyTicketsTitleLabel.leadingAnchor.constraint(equalTo: stickyTicketsTitleContainer.leadingAnchor, constant: 20),
            stickyTicketsTitleLabel.trailingAnchor.constraint(equalTo: stickyTicketsTitleContainer.trailingAnchor, constant: -20),
            stickyTicketsTitleLabel.bottomAnchor.constraint(equalTo: stickyTicketsTitleContainer.bottomAnchor)
        ])

        syncStickyTicketsTitle()
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

    // MARK: - KVO: auto-resize tableView height as cells load/expand

    func observeTableViewHeight() {
        tableViewHeightObserver = tableView.observe(
            \.contentSize,
            options: [.new]
        ) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateTableViewHeight(animated: true)
            }
        }
    }

    func updateTableViewHeight(animated: Bool) {
        tableView.layoutIfNeeded()

        let contentHeight = ceil(tableView.contentSize.height)
        guard contentHeight > 0 else { return }
        guard abs(contentHeight - lastTableContentHeight) > 1 ||
              abs(tableViewHeight.constant - contentHeight) > 1 else {
            return
        }

        lastTableContentHeight = contentHeight
        tableViewHeight.constant = contentHeight

        let updates = { self.view.layoutIfNeeded() }
        if animated {
            UIView.animate(withDuration: 0.2) {
                updates()
                self.updateScrollAllowance()
            }
        } else {
            updates()
            updateScrollAllowance()
        }
    }

    func updateScrollAllowance() {
        guard scrollView.bounds.height > 0 else { return }

        let sectionOrigin = ticketsSectionView.convert(CGPoint.zero, to: scrollView)
        let targetOffset = max(scrollView.contentOffset.y + sectionOrigin.y, 0)
        let requiredBottomInset = max(0, targetOffset + scrollView.bounds.height - scrollView.contentSize.height)
        let bottomInset = ceil(requiredBottomInset)

        guard abs(bottomInset - lastScrollBottomInset) > 1 else { return }

        lastScrollBottomInset = bottomInset
        scrollView.contentInset.bottom = bottomInset
        scrollView.scrollIndicatorInsets.bottom = bottomInset
    }

    func refreshScrollLayout(animated: Bool) {
        tableView.layoutIfNeeded()
        view.setNeedsLayout()

        let updates = {
            self.view.layoutIfNeeded()
            self.updateScrollAllowance()
            self.updateStickyNavigation(for: self.scrollView.contentOffset.y)
            self.updateStickyTicketsTitle()
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: updates)
        } else {
            updates()
        }
    }

    func refreshScrollLayoutAfterUpdates() {
        refreshScrollLayout(animated: false)
        DispatchQueue.main.async { [weak self] in
            self?.refreshScrollLayout(animated: false)
        }
    }

    func updateStickyNavigation(for offset: CGFloat) {
        let headerHeight = max(headerView.bounds.height, 1)
        let navHeight = max(navBarHiddenView.bounds.height, 1)
        let threshold = max(headerHeight - navHeight, 1)
        let progress = min(max(offset / threshold, 0), 1)

        navBarHiddenView.isHidden = progress <= 0.01
        navBarHiddenView.alpha = progress
        headerView.alpha = 1 - progress
        updateStickyTicketsTitle()
    }

    func syncStickyTicketsTitle() {
        stickyTicketsTitleLabel.text = ticketsTitleLbl.text
        stickyTicketsTitleLabel.font = ticketsTitleLbl.font
        stickyTicketsTitleLabel.textColor = ticketsTitleLbl.textColor
    }

    func updateStickyTicketsTitle() {
        syncStickyTicketsTitle()

        let titleFrame = ticketsTitleLbl.convert(ticketsTitleLbl.bounds, to: view)
        let shouldStick = titleFrame.minY <= scrollView.frame.minY

        stickyTicketsTitleContainer.isHidden = !shouldStick
        stickyTicketsTitleContainer.alpha = shouldStick ? 1 : 0
        stickyTopBlurView.isHidden = !shouldStick
        stickyTopBlurView.alpha = shouldStick ? 1 : 0
        ticketsTitleLbl.alpha = shouldStick ? 0 : 1
    }
}

// MARK: - UIScrollViewDelegate (scroll-driven nav collapse)

extension CoverTicketListVC: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        updateStickyNavigation(for: max(scrollView.contentOffset.y, 0))
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
        case "SAME_PRICE":     return 1
        case "FREE":           return 0
        case "DIFFRENT_PRICE": return 0.5
        case "TAO_PRICING":    return 0.5
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
        let isCurrentlyVisible = !continueToCheckoutBtn.isHidden && continueToCheckoutBtn.alpha == 1
        if show == isCurrentlyVisible { return }

        if show {
            continueToCheckoutBtn.isHidden = false
            continueToCheckoutBtn.alpha = 0
            continueToCheckoutBtn.transform = CGAffineTransform(translationX: 0, y: 80)
            refreshScrollLayoutAfterUpdates()

            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.6,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                self.continueToCheckoutBtn.alpha = 1
                self.continueToCheckoutBtn.transform = .identity
                self.view.layoutIfNeeded()
                self.updateScrollAllowance()
            } completion: { _ in
                self.refreshScrollLayoutAfterUpdates()
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
                self.refreshScrollLayoutAfterUpdates()
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
        // Restore nav bar appearance before popping
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        Navigate.to.back(self)
    }

    private func onClickContinueBtn() {
        if UserDefault.shared.user == nil {
            Navigate.to.openPhoneLoginPopup(self) { [weak self] in
                guard let self else { return }
                self.continueFlow()
            }
            return
        }
        continueFlow()
    }

    private func continueFlow() {
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
            ["ticketId": $0.id, "ticketQuantity": $0.selectedQuantity ?? 0]
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
        refreshScrollLayoutAfterUpdates()
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
        refreshScrollLayoutAfterUpdates()
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
            ? (ticket.customName ?? ticket.name)
            : (ticket.name)

            cell.configure(
                coverTicketName: name,
                description: ticket.description,
                price: ticket.price,
                extraFees: ticket.extraFees,
                selectedCount: count,
                currency: currency,
                whiteLabelColor: whiteLabelColor,
                isDescriptionExpanded: expandedIndexSet.contains(ticket.id),
                onPlus: { [weak self] in self?.plusBtnClicked(at: indexPath) },
                onMinus: { [weak self] in self?.minusBtnClicked(at: indexPath) }
            )

            cell.onDescriptionToggle = { [weak self] in
                guard let self else { return }
                let id = ticket.id
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
                isDescriptionExpanded: expandedIndexSet.contains(ticket.id),
                onPlus: { [weak self] in self?.plusBtnClicked(at: indexPath) },
                onMinus: { [weak self] in self?.minusBtnClicked(at: indexPath) }
            )

            cell.onDescriptionToggle = { [weak self] in
                guard let self else { return }
                let id = ticket.id
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
        refreshScrollLayoutAfterUpdates()
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

// MARK: - CheckoutBarDelegate

extension CoverTicketListVC: CheckoutBarDelegate {

    func checkoutBarDidTapButton() {
        onClickContinueBtn()
    }
}

import UIKit

final class VenuePosterHeaderView: UIView {

    private let screenBackgroundColor = UIColor(hex: "#121212")
    private let backgroundImageView = UIImageView()
    private let bottomGradientView = UIView()
    private let bottomGradientLayer = CAGradientLayer()
    private let placeholderImage = UIImage(named: "newSpeakeasy")
    private var currentImageURLString: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = screenBackgroundColor
        clipsToBounds = true
        setupBackground()
        setupBottomGradient()
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.backgroundColor = screenBackgroundColor
        backgroundImageView.image = placeholderImage
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5)
        ])
    }

    private func setupBottomGradient() {
        bottomGradientView.isUserInteractionEnabled = false
        bottomGradientView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomGradientView)

        NSLayoutConstraint.activate([
            bottomGradientView.topAnchor.constraint(equalTo: topAnchor),
            bottomGradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomGradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomGradientView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        bottomGradientView.layer.addSublayer(bottomGradientLayer)

        bottomGradientLayer.colors = [
            UIColor.clear.withAlphaComponent(0.25).cgColor,
            UIColor.black.withAlphaComponent(0.65).cgColor,
            UIColor.black.withAlphaComponent(0.85).cgColor,
            UIColor.black.cgColor,
            UIColor.black.cgColor
        ]
        bottomGradientLayer.locations = [0.0, 0.30, 0.42, 0.50, 0.60]
        bottomGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        bottomGradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bottomGradientLayer.frame = bottomGradientView.bounds
    }

    func setBackgroundImage(_ image: UIImage?) {
        backgroundImageView.image = image ?? placeholderImage
    }

    func loadImage(from urlString: String) {
        let trimmedURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURLString.isEmpty, let url = URL(string: trimmedURLString) else {
            currentImageURLString = nil
            backgroundImageView.sd_cancelCurrentImageLoad()
            setBackgroundImage(placeholderImage)
            return
        }

        guard currentImageURLString != trimmedURLString else { return }

        currentImageURLString = trimmedURLString
        let currentImage = backgroundImageView.image ?? placeholderImage

        backgroundImageView.sd_setImage(
            with: url,
            placeholderImage: currentImage
        ) { [weak self] image, _, cacheType, completedURL in
            guard let self else { return }
            guard completedURL?.absoluteString == self.currentImageURLString else { return }

            guard cacheType == .none else {
                self.setBackgroundImage(image)
                return
            }

            UIView.transition(
                with: self.backgroundImageView,
                duration: 0.25,
                options: [.transitionCrossDissolve, .allowUserInteraction],
                animations: {
                    self.setBackgroundImage(image)
                }
            )
        }
    }
}
