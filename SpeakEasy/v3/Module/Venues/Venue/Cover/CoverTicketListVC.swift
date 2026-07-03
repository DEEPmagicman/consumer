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
    @IBOutlet weak var followBtn: UIButton!
    @IBOutlet weak var followBtnLbl: UILabel!
    @IBOutlet weak var coverDisclaimerContainerView: UIView!
    @IBOutlet weak var coverDisclaimerLabel: UILabel!

    private let posterHeaderView = VenuePosterHeaderView()
    private let stickyTopBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let stickyTicketsTitleContainer = UIView()
    private let stickyTicketsTitleLabel = UILabel()
    private let directUpsellFooterView = UIView()
    private let directUpsellButton = UIButton(type: .system)
    private let venueService = VenueService()

    // MARK: - Public

    var venueDetails: ClipVenue?
    var doormanId = ""
    var onFollowStateChanged: ((ClipVenue, Bool) -> Void)?
    var shouldShowDirectUpsell = false

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
    private var isCheckoutNavigationInProgress = false
    private var isFreeBookingInProgress = false
    private var isSocketRefreshInProgress = false

    // MARK: - Follow State

    private var isFollowing = false
    private var isFollowLoading = false
    private var followedVenueId: String?
    private var hasLocalFollowState = false

    private let followActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = false
        indicator.alpha = 0
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

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

    private var selectedStepTitle: String {
        switch currentStep {
        case .coverTickets:
            return Constant.String.liveCoverTicket
        case .addOns:
            let title = venueDetails?.venueSettings?.addOnsBookingSettings?.pageTitle?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return title?.isEmpty == false ? title! : "Upsell Items"
        }
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
        setupTopBlurView()
        setupPosterBackground()
        setupScrollBehavior()
        observeTableViewHeight()
        setupCoverTickets()
        configureInitialFlowStep()
        getUpsellTickets()
        updateCheckoutState()
        setupFollowButtonAnimation()
        syncFollowState()
        updateFollowUI(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeaderView()
        updateTableViewHeight(animated: false)
        normalizeScrollInsets()
        updateStickyNavigation(for: scrollView.contentOffset.y)
        updateVenueLogoCornerRadius()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isCheckoutNavigationInProgress = false
        registerSocketDelegate()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterSocketDelegate()
    }

    deinit {
        tableViewHeightObserver?.invalidate()
    }

    @IBAction func onClickFollowBtn(_ sender: Any) {
        guard !isFollowLoading else { return }
        guard !UserDefault.shared.isGuest else { return }

        guard let venueUniqueId = venueDetails?.uniqueId,
              !venueUniqueId.isEmpty
        else { return }

        let previousState = isFollowing
        let previousFollowedVenueId = followedVenueId

        isFollowLoading = true
        isFollowing.toggle()
        animateFollowTap()
        updateFollowUI(animated: true)

        if isFollowing {
            followVenueAPI(
                venueUniqueId: venueUniqueId,
                previousState: previousState,
                previousFollowedVenueId: previousFollowedVenueId
            )
        } else {
            guard let followedVenueId, !followedVenueId.isEmpty else {
                isFollowLoading = false
                applyFollowState(
                    isFollowing: previousState,
                    followedVenueId: previousFollowedVenueId,
                    notify: false
                )
                return
            }

            unfollowVenueAPI(
                followedVenueId: followedVenueId,
                previousState: previousState,
                previousFollowedVenueId: previousFollowedVenueId
            )
        }
    }
}

// MARK: - Follow Implementation

private extension CoverTicketListVC {

    func syncFollowState() {
        followedVenueId = venueDetails?.venueFollowedId
        isFollowing = venueDetails?.isFollowing == true || followedVenueId != nil
    }

    func applyFollowState(
        isFollowing: Bool,
        followedVenueId: String?,
        notify: Bool,
        animated: Bool = true
    ) {
        self.isFollowing = isFollowing
        self.followedVenueId = followedVenueId
        venueDetails?.isFollowing = isFollowing
        venueDetails?.venueFollowedId = followedVenueId
        hasLocalFollowState = true
        updateFollowUI(animated: animated)

        if notify, let venue = venueDetails {
            onFollowStateChanged?(venue, isFollowing)
        }
    }

    func setupFollowButtonAnimation() {
        guard let followContainer = followBtn?.superview else { return }

        followBtnLbl?.numberOfLines = 1
        followBtnLbl?.lineBreakMode = .byClipping
        followBtnLbl?.setContentCompressionResistancePriority(.required, for: .horizontal)
        followBtnLbl?.setContentHuggingPriority(.required, for: .horizontal)

        guard followActivityIndicator.superview == nil else { return }

        followContainer.addSubview(followActivityIndicator)

        NSLayoutConstraint.activate([
            followActivityIndicator.centerXAnchor.constraint(equalTo: followContainer.centerXAnchor),
            followActivityIndicator.centerYAnchor.constraint(equalTo: followContainer.centerYAnchor)
        ])
    }

    func updateFollowUI(animated: Bool = true) {
        let newTitle = isFollowing ? "Following" : "Follow"
        let textChanged = followBtnLbl?.text != newTitle

        followBtn?.isUserInteractionEnabled = !isFollowLoading

        let applyTitle = {
            self.followBtnLbl?.text = newTitle
            self.followBtnLbl?.alpha = self.isFollowLoading ? 0 : 1
            self.followActivityIndicator.alpha = self.isFollowLoading ? 1 : 0
            self.followBtn?.superview?.layoutIfNeeded()
        }

        if isFollowLoading {
            followActivityIndicator.startAnimating()
        } else {
            followActivityIndicator.stopAnimating()
        }

        guard animated else {
            applyTitle()
            if !isFollowLoading {
                followActivityIndicator.stopAnimating()
            }
            return
        }

        let completion: (Bool) -> Void = { [weak self] _ in
            guard let self else { return }
            if !self.isFollowLoading {
                self.followActivityIndicator.stopAnimating()
            }
        }

        if textChanged {
            UIView.transition(
                with: followBtnLbl,
                duration: 0.18,
                options: [.transitionCrossDissolve, .beginFromCurrentState],
                animations: applyTitle,
                completion: completion
            )
        } else {
            UIView.animate(
                withDuration: 0.18,
                delay: 0,
                options: [.curveEaseOut, .beginFromCurrentState],
                animations: applyTitle,
                completion: completion
            )
        }
    }

    func animateFollowTap() {
        guard let followContainer = followBtn?.superview else { return }

        UIView.animate(
            withDuration: 0.08,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState],
            animations: {
                followContainer.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.22,
                    delay: 0,
                    usingSpringWithDamping: 0.74,
                    initialSpringVelocity: 0.6,
                    options: [.curveEaseOut, .beginFromCurrentState],
                    animations: {
                        followContainer.transform = .identity
                    }
                )
            }
        )
    }

    func followVenueAPI(
        venueUniqueId: String,
        previousState: Bool,
        previousFollowedVenueId: String?
    ) {
        venueService.followVenue(uniqueId: venueUniqueId) { [weak self] isSuccess, _, relation in
            guard let self else { return }
            self.isFollowLoading = false

            guard isSuccess,
                  let id = relation?.id,
                  !id.isEmpty
            else {
                self.applyFollowState(
                    isFollowing: previousState,
                    followedVenueId: previousFollowedVenueId,
                    notify: false
                )
                return
            }

            self.applyFollowState(
                isFollowing: true,
                followedVenueId: id,
                notify: true
            )
        }
    }

    func unfollowVenueAPI(
        followedVenueId: String,
        previousState: Bool,
        previousFollowedVenueId: String?
    ) {
        venueService.unfollowVenue(followedVenueId: followedVenueId) { [weak self] isSuccess, _, _ in
            guard let self else { return }
            self.isFollowLoading = false

            guard isSuccess else {
                self.applyFollowState(
                    isFollowing: previousState,
                    followedVenueId: previousFollowedVenueId,
                    notify: false
                )
                return
            }

            self.applyFollowState(
                isFollowing: false,
                followedVenueId: nil,
                notify: true
            )
        }
    }
}

// MARK: - Setup

private extension CoverTicketListVC {

    func registerSocketDelegate() {
        WebSocketWrapper.shared.removeDelegate(self)
        WebSocketWrapper.shared.addDelegate(self) 
    }

    func unregisterSocketDelegate() {
        WebSocketWrapper.shared.removeDelegate(self)
    }

    func setupScrollBehavior() {
        scrollView.delegate = self
        scrollView.isScrollEnabled = true
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
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
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false
        tableView.alwaysBounceVertical = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220

        tableView.register(
            TicketsTVC.nib,
            forCellReuseIdentifier: TicketsTVC.identifier
        )
        setupCoverDisclaimerHeader()
        setupDirectUpsellFooter()
    }

    func setupScreen() {
        styleVenueHeader()

        let logoUrl = "\(SharedURL.amazonStorage)\(venueDetails?.logo?.key ?? "")"
        venueImage.sd_setImage(with: URL(string: logoUrl), completed: nil)

        venueName.text = venueDetails?.name ?? ""
        let displayCity = venueDetails?.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationText = displayCity?.isEmpty == false
            ? displayCity
            : venueDetails?.timezone
        timeLbl.text = locationText
        navVenueNameLbl.text = venueDetails?.name ?? ""
        navTimeLbl.text = locationText

        navBarHiddenView.isHidden = true
        navBarHiddenView.alpha = 0
        continueToCheckoutBtn.isHidden = true
        continueToCheckoutBtn.alpha = 0
        continueToCheckoutBtn.delegate = self
        updateTicketsTitle()
    }

    func styleVenueHeader() {
        headerView.clipsToBounds = false
        venueImage.contentMode = .scaleAspectFit
        venueImage.clipsToBounds = true

        [venueName, navVenueNameLbl].forEach {
            $0?.numberOfLines = 1
            $0?.lineBreakMode = .byTruncatingTail
            $0?.adjustsFontSizeToFitWidth = true
            $0?.minimumScaleFactor = 0.75
        }

        [timeLbl, navTimeLbl].forEach {
            $0?.numberOfLines = 1
            $0?.lineBreakMode = .byTruncatingTail
            $0?.adjustsFontSizeToFitWidth = true
            $0?.minimumScaleFactor = 0.8
        }
    }

    func updateVenueLogoCornerRadius() {
        venueImage.layer.cornerRadius = min(
            venueImage.bounds.width,
            venueImage.bounds.height
        ) / 2
    }

    func setupCoverTickets() {
        let selectedTicketIds = Set(selectedCoverTickets.map { $0.id })

        guard let list = venueDetails?.coverTicket else {
            coverTickets = []
            coverTicketCount.removeAll()
            tableView.reloadData()
            updateCheckoutState()
            return
        }

        coverTickets = list.filter {
            !($0.isDeleted ?? false) &&
            $0.status == "ENABLED"
        }

        if !selectedTicketIds.isEmpty {
            var remappedCounts: [Int: Int] = [:]
            coverTickets.enumerated().forEach { index, ticket in
                guard selectedTicketIds.contains(ticket.id) else { return }
                remappedCounts[index] = selectedCoverTickets.first(where: { $0.id == ticket.id })?.selectedQuantity ?? 0
            }
            coverTicketCount = remappedCounts.filter { $0.value > 0 }
        } else {
            coverTicketCount.removeAll()
        }

        tableView.reloadData()
        updateCheckoutState()
    }

    func configureInitialFlowStep() {
        currentStep = .coverTickets
        updateTicketsTitle()
    }

    func updateTicketsTitle() {
        ticketsTitleLbl.text = selectedStepTitle
        updateTableHeaderView()
        updateDirectUpsellFooterVisibility()
    }

    func setupCoverDisclaimerHeader() {
        tableView.tableHeaderView = nil
        coverDisclaimerContainerView.backgroundColor = .clear
        coverDisclaimerContainerView.layer.cornerRadius = 8
        coverDisclaimerContainerView.layer.borderWidth = 1
        let tintColor = UIColor(
            hex: venueDetails?.venueSettings?.whiteLabelColor ?? "#FFFFFF"
        )
        coverDisclaimerContainerView.borderColor = tintColor
        coverDisclaimerContainerView.clipsToBounds = true

        coverDisclaimerLabel.font = Constant.Font.geistRegular(size: 13)
        coverDisclaimerLabel.textColor = UIColor.white.withAlphaComponent(0.86)
        coverDisclaimerLabel.numberOfLines = 0
        coverDisclaimerLabel.lineBreakMode = .byWordWrapping
        coverDisclaimerContainerView.isHidden = true
    }

    func updateTableHeaderView() {
        tableView.tableHeaderView = nil

        switch currentStep {
        case .coverTickets:
            updateCoverDisclaimerView()
        case .addOns:
            coverDisclaimerContainerView.isHidden = true
        }
    }

    func updateCoverDisclaimerView() {
        let text = venueDetails?.venueSettings?.coverDisclaimerText?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard venueDetails?.venueSettings?.showCoverDisclaimer == true,
              !text.isEmpty else {
            coverDisclaimerContainerView.isHidden = true
            return
        }

        coverDisclaimerLabel.text = text
        coverDisclaimerContainerView.isHidden = false
    }

    func setupDirectUpsellFooter() {
        directUpsellFooterView.backgroundColor = .clear
        directUpsellFooterView.frame = CGRect(
            x: 0,
            y: 0,
            width: tableView.bounds.width,
            height: 56
        )

        directUpsellButton.titleLabel?.font = Constant.Font.geistRegular(size: 15)
        directUpsellButton.setTitleColor(.white, for: .normal)
        directUpsellButton.contentHorizontalAlignment = .center
        directUpsellButton.addTarget(self, action: #selector(onClickDirectUpsellButton), for: .touchUpInside)

        if directUpsellButton.superview == nil {
            directUpsellButton.translatesAutoresizingMaskIntoConstraints = false
            directUpsellFooterView.addSubview(directUpsellButton)

            NSLayoutConstraint.activate([
                directUpsellButton.topAnchor.constraint(equalTo: directUpsellFooterView.topAnchor, constant: 8),
                directUpsellButton.leadingAnchor.constraint(equalTo: directUpsellFooterView.leadingAnchor, constant: 20),
                directUpsellButton.trailingAnchor.constraint(equalTo: directUpsellFooterView.trailingAnchor, constant: -20),
                directUpsellButton.heightAnchor.constraint(equalToConstant: 36)
            ])
        }

        updateDirectUpsellFooterVisibility()
    }

    func updateDirectUpsellFooterVisibility() {
        let shouldShow = currentStep == .coverTickets && hasAnyUpsell
        guard shouldShow else {
            tableView.tableFooterView = nil
            return
        }

        let title = venueDetails?.venueSettings?.addOnsBookingSettings?.pageTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let buttonTitle = title?.isEmpty == false
            ? "Buy \(title!)"
            : "Buy upsell tickets"

        let attributedTitle = NSAttributedString(
            string: buttonTitle,
            attributes: [
                .font: Constant.Font.geistRegular(size: 15),
                .foregroundColor: UIColor.white,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        directUpsellButton.setAttributedTitle(attributedTitle, for: .normal)

        directUpsellFooterView.frame.size = CGSize(
            width: tableView.bounds.width,
            height: 56
        )
        tableView.tableFooterView = directUpsellFooterView
    }

    func setupTopBlurView() {
        stickyTopBlurView.translatesAutoresizingMaskIntoConstraints = false
        stickyTopBlurView.isHidden = true
        stickyTopBlurView.alpha = 0
        stickyTopBlurView.isUserInteractionEnabled = false

        view.insertSubview(stickyTopBlurView, aboveSubview: scrollView)

        NSLayoutConstraint.activate([
            stickyTopBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            stickyTopBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickyTopBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stickyTopBlurView.bottomAnchor.constraint(equalTo: navBarHiddenView.bottomAnchor, constant: 10)
        ])
    }

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
                self.normalizeScrollInsets()
            }
        } else {
            updates()
            normalizeScrollInsets()
        }
    }

    func normalizeScrollInsets() {
        let bottomInset: CGFloat = 0
        scrollView.contentInset.bottom = bottomInset
        scrollView.scrollIndicatorInsets.bottom = bottomInset
        clampScrollOffsetIfNeeded()
    }

    func clampScrollOffsetIfNeeded() {
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

    func refreshScrollLayout(animated: Bool) {
        tableView.layoutIfNeeded()
        view.setNeedsLayout()

        let updates = {
            self.updateTableHeaderView()
            self.view.layoutIfNeeded()
            self.normalizeScrollInsets()
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

    func settleStickyNavigation() {
        let headerHeight = max(headerView.bounds.height, 1)
        let navHeight = max(navBarHiddenView.bounds.height, 1)
        let threshold = max(headerHeight - navHeight, 1)
        let progress = min(max(scrollView.contentOffset.y / threshold, 0), 1)
        let shouldCollapse = progress >= 0.5
        let targetAlpha: CGFloat = shouldCollapse ? 1 : 0

        navBarHiddenView.isHidden = targetAlpha == 0

        UIView.animate(
            withDuration: 0.18,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.navBarHiddenView.alpha = targetAlpha
            self.headerView.alpha = 1 - targetAlpha
        } completion: { _ in
            self.navBarHiddenView.isHidden = targetAlpha == 0
            self.updateStickyTicketsTitle()
        }
    }

    func syncStickyTicketsTitle() {
        stickyTicketsTitleLabel.text = ticketsTitleLbl.text
        stickyTicketsTitleLabel.font = ticketsTitleLbl.font
        stickyTicketsTitleLabel.textColor = ticketsTitleLbl.textColor
    }

    func updateStickyTicketsTitle() {
        stickyTicketsTitleContainer.isHidden = true
        stickyTicketsTitleContainer.alpha = 0
        stickyTopBlurView.isHidden = navBarHiddenView.isHidden
        stickyTopBlurView.alpha = navBarHiddenView.alpha
        ticketsTitleLbl.alpha = 1
    }
}

// MARK: - UIScrollViewDelegate

extension CoverTicketListVC: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        updateStickyNavigation(for: max(scrollView.contentOffset.y, 0))
    }

    func scrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate decelerate: Bool
    ) {
        guard scrollView === self.scrollView, !decelerate else { return }
        settleStickyNavigation()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        settleStickyNavigation()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        settleStickyNavigation()
    }
}

// MARK: - API

private extension CoverTicketListVC {

    func refreshVenueFromSocket(clearSelection: Bool) {
        guard !isSocketRefreshInProgress else { return }

        let venueUniqueId = venueDetails?.uniqueId ?? ""
        guard !venueUniqueId.isEmpty else { return }

        isSocketRefreshInProgress = true

        venueService.fetchCoverVenueDetail(
            uniqueId: venueUniqueId,
            venueTimeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, _, venueDetail in
            guard let self else { return }

            self.isSocketRefreshInProgress = false

            guard isSuccess, let venueDetail else { return }

            self.venueDetails = venueDetail
            self.setupScreen()

            if clearSelection {
                self.coverTicketCount.removeAll()
                self.upSellTicketCount.removeAll()
                self.currentStep = .coverTickets
            }

            self.setupCoverTickets()
            self.getUpsellTickets()
            self.updateCheckoutState()
            self.refreshScrollLayoutAfterUpdates()
        }
    }

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
                self.upSellTickets = upSellItem.filter {
                    !$0.isDeleted &&
                    $0.status == "ENABLED" &&
                    $0.addOns?.isDeleted == false &&
                    $0.addOns?.status == "ENABLED"
                }
            } else {
                self.upSellTickets = []
                if let errMsg, !errMsg.isEmpty {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                }
            }

            if self.shouldShowDirectUpsell && self.upSellTickets.isEmpty && !self.coverTickets.isEmpty {
                self.currentStep = .coverTickets
            }

            self.tableView.reloadData()
            self.updateTicketsTitle()
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
        let shouldShow = totalSelectedCount > 0

        let subtotal =
            selectedCoverTickets.reduce(0.0) {
                $0 + ($1.price * Double($1.selectedQuantity ?? 0))
            }
            +
            selectedAddOns.reduce(0.0) {
                $0 + ($1.price * Double($1.selectedQuantity ?? 0))
            }

        let currencySymbole = venueDetails?.venueSettings?.currencySymbol ?? "$"
        let currencyPosition = venueDetails?.venueSettings?.currencyPosition
        
        continueToCheckoutBtn.updateSummary(
            currency: currencySymbole,
            currencyPosition: currencyPosition,
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
                self.normalizeScrollInsets()
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
        updateTicketsTitle()
        tableView.reloadData()
        updateCheckoutState()
    }

    func proceedToFinalCheckout() {
        guard !isCheckoutNavigationInProgress else { return }
        guard !selectedCoverTickets.isEmpty || !selectedAddOns.isEmpty else { return }

        isCheckoutNavigationInProgress = true
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
        if currentStep == .addOns && !shouldShowDirectUpsell {
            currentStep = .coverTickets
            expandedIndexSet.removeAll()
            updateTicketsTitle()
            tableView.reloadData()
            updateCheckoutState()
            return
        }
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        Navigate.to.back(self)
    }

    @IBAction func onClickShare(_ sender: Any) {
        let venueName = venueDetails?.name ?? "Venue"
        let slug = venueName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        let venueUrl = String(
            format: APIBuilder.venueWebURL,
            slug,
            venueDetails?.uniqueId ?? ""
        )
        let msgText = "Check out \(venueName) on Speakeasy. \(venueUrl) Download the app to directly connect with your favorite venues & never miss out! \(SharedURL.appStoreURL)"
        Utility.main.shareSocialWith(text: msgText)
    }

    private func onClickContinueBtn() {
        guard !isCheckoutNavigationInProgress else { return }

        if UserDefault.shared.user == nil {
            Navigate.to.openPhoneLoginPopup(self) { [weak self] in
                guard let self else { return }
                self.continueFlow()
            }
            return
        }
        continueFlow()
    }

    @objc private func onClickDirectUpsellButton() {
        guard hasAnyUpsell else { return }
        moveToAddOnStep()
    }

    private func continueFlow() {
        guard !selectedCoverTickets.isEmpty || !selectedAddOns.isEmpty else { return }

        switch currentStep {
        case .coverTickets:
            hasAnyUpsell ? moveToAddOnStep() : proceedToFinalCheckout()
        case .addOns:
            proceedToFinalCheckout()
        }
    }

    private func createFreeBooking() {
        guard !isFreeBookingInProgress else { return }
        guard !selectedCoverTickets.isEmpty else { return }

        let tickets: [[String: Any]] = selectedCoverTickets.map {
            ["ticketId": $0.id, "ticketQuantity": $0.selectedQuantity ?? 0]
        }

        isFreeBookingInProgress = true
        view.isUserInteractionEnabled = false

        PaymentPresenter.createCoverFreeBooking(
            coverTickets: tickets,
            venueId: venueDetails?.id ?? ""
        ) { [weak self] isSuccess, errMsg, id, _ in
            guard let self else { return }

            if isSuccess, let id {
                Navigate.to.scanQR(
                    self,
                    bookingId: id,
                    addOnsBookingId: "",
                    venueName: venueDetails?.name ?? "",
                    shouldPushFromVenueFlow: true
                )
            } else {
                self.isCheckoutNavigationInProgress = false
                self.isFreeBookingInProgress = false
                self.view.isUserInteractionEnabled = true
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }

    private func applyCoverSelectionExclusivity(for index: Int) {
        guard coverTickets.indices.contains(index) else { return }

        let isCustomTicket = coverTickets[index].isCustom == true

        Array(coverTicketCount.keys).forEach { selectedIndex in
            guard coverTickets.indices.contains(selectedIndex),
                  selectedIndex != index
            else { return }

            let selectedIsCustom = coverTickets[selectedIndex].isCustom == true
            if selectedIsCustom != isCustomTicket {
                coverTicketCount.removeValue(forKey: selectedIndex)
            }
        }
    }

    private func incrementCoverTicket(at indexPath: IndexPath) {
        guard isVenueOpen else { return }
        guard indexPath.row < coverTickets.count else { return }
        guard coverTickets[indexPath.row].status == "ENABLED" else { return }

        applyCoverSelectionExclusivity(for: indexPath.row)
        guard canSelectMoreTickets() else { return }

        coverTicketCount[indexPath.row] = (coverTicketCount[indexPath.row] ?? 0) + 1
        updateCheckoutState()
        tableView.reloadData()
        refreshScrollLayoutAfterUpdates()
    }

    private func plusBtnClicked(at indexPath: IndexPath) {
        switch currentStep {
        case .coverTickets:
            incrementCoverTicket(at: indexPath)
            return

        case .addOns:
            guard isVenueOpen else { return }
            guard canSelectMoreTickets() else { return }
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
            guard indexPath.row < coverTickets.count else { return }
            let current = coverTicketCount[indexPath.row] ?? 0
            let newCount = max(0, current - 1)
            if newCount > 0 {
                coverTicketCount[indexPath.row] = newCount
            } else {
                coverTicketCount.removeValue(forKey: indexPath.row)
            }

        case .addOns:
            guard indexPath.row < upSellTickets.count else { return }
            let current = upSellTicketCount[indexPath.row] ?? 0
            let newCount = max(0, current - 1)
            if newCount > 0 {
                upSellTicketCount[indexPath.row] = newCount
            } else {
                upSellTicketCount.removeValue(forKey: indexPath.row)
            }
        }

        updateCheckoutState()
        tableView.reloadRows(at: [indexPath], with: .none)
        refreshScrollLayoutAfterUpdates()
    }
}

// MARK: - UITableViewDataSource

extension CoverTicketListVC: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentStep {
        case .coverTickets: return coverTickets.count
        case .addOns:       return upSellTickets.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TicketsTVC.identifier,
            for: indexPath
        ) as? TicketsTVC else { return UITableViewCell() }

        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
        let currencyPosition = venueDetails?.venueSettings?.currencyPosition
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
                currencyPosition: currencyPosition,
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
                currencyPosition: currencyPosition,
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

        cell.onPlusTap  = { [weak self] _ in self?.plusBtnClicked(at: indexPath) }
        cell.onMinusTap = { [weak self] _ in self?.minusBtnClicked(at: indexPath) }
        cell.onRSVPTap  = nil

        return cell
    }
}

// MARK: - UITableViewDelegate

extension CoverTicketListVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isVenueOpen else { return }

        switch currentStep {
        case .coverTickets:
            incrementCoverTicket(at: indexPath)
            return

        case .addOns:
            guard canSelectMoreTickets() else { return }
            guard indexPath.row < upSellTickets.count else { return }
            upSellTicketCount[indexPath.row] = (upSellTicketCount[indexPath.row] ?? 0) + 1
        }

        updateCheckoutState()
        tableView.reloadRows(at: [indexPath], with: .none)
        refreshScrollLayoutAfterUpdates()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        220
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { nil }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
}

// MARK: - CheckoutBarDelegate

extension CoverTicketListVC: CheckoutBarDelegate {

    func checkoutBarDidTapButton() {
        onClickContinueBtn()
    }
}

// MARK: - WebSocket

extension CoverTicketListVC: WebSocketCallBackDelegate {

    func updateTicketPrice(ticket: [CoverTicket]) {
        guard isCurrentVenueCoverTicketUpdate(ticket) else { return }
        refreshVenueFromSocket(clearSelection: true)
    }

    func updateAddOnsTicketPrice(ticket: [UpSellTicket]) {
        guard isCurrentVenueAddOnUpdate(ticket) else { return }
        refreshVenueFromSocket(clearSelection: currentStep == .addOns)
    }

    func updateVenueStatus(venueId: String, venueStatus: String) {
        guard venueDetails?.id == venueId else { return }
        refreshVenueFromSocket(clearSelection: true)
    }

    func didGenderWiseTicketChange(venueId: String, uniqueId: String) {
        guard venueDetails?.id == venueId || venueDetails?.uniqueId == uniqueId else { return }
        refreshVenueFromSocket(clearSelection: true)
    }

    private func isCurrentVenueCoverTicketUpdate(_ tickets: [CoverTicket]) -> Bool {
        let currentVenueId = venueDetails?.id ?? ""
        guard !currentVenueId.isEmpty else { return false }
        return tickets.contains { $0.venueId == currentVenueId }
    }

    private func isCurrentVenueAddOnUpdate(_ tickets: [UpSellTicket]) -> Bool {
        let currentVenueId = venueDetails?.id ?? ""
        guard !currentVenueId.isEmpty else { return false }
        return tickets.contains { $0.addOns?.venueId == currentVenueId }
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
