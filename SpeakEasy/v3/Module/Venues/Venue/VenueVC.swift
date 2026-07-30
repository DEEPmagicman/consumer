import UIKit

//
//  VenueVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/03/26.
//

protocol ChildScrollDelegate: AnyObject {
    func childScrollViewDidScroll(_ scrollView: UIScrollView)
    var isHeaderFullyCollapsed: Bool { get }
}

final class VenueVC: UIViewController {

    @IBOutlet weak var venueView: UIView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var buyticketView: UIView!
    @IBOutlet weak var coverTicketView: UIView!
    @IBOutlet weak var coverTicketTitleLbl: UILabel!
    @IBOutlet weak var coverTicketDescriptionLbl: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tabView: UIView!
    @IBOutlet weak var followBtn: UIButton!
    @IBOutlet weak var followBtnLbl: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var venueCityLbl: UILabel!
        
    private let venueService = VenueService()
    private let posterHeaderView = VenuePosterHeaderView()
    private let navTitleStackView = UIStackView()
    private let navVenueNameLabel = PremiumMarqueeLabel()
    private let navVenueCityLabel = UILabel()
    private var navTitleWidthConstraint: NSLayoutConstraint?

    private let glassSegment = GlassSegmentView(titles: ["Events", "Premium", "Artists"])

    private let pageVC = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    private var tabControllers: [UIViewController] = []
    private var selectedIndex: Int = 0

    private weak var containerTopConstraint: NSLayoutConstraint?
    private var maxHeaderCollapseOffset: CGFloat = 0
    private var headerCollapseOffset: CGFloat = 0
    private var childScrollOffsets: [ObjectIdentifier: CGFloat] = [:]
    private var childPanTranslations: [ObjectIdentifier: CGFloat] = [:]
    private var registeredPanScrollIDs = Set<ObjectIdentifier>()
    private var isUpdatingChildScrollOffset = false
    private let stickySegmentTopSpacing: CGFloat = 64
    private let headerExpansionDragMultiplier: CGFloat = 2.0
    private let headerExpansionStartTolerance: CGFloat = 12
    private let headerFadeStartProgress: CGFloat = 0.12
    private let headerFadeEndProgress: CGFloat = 0.42
    private let navTitleFadeStartProgress: CGFloat = 0.52
    private let navTitleFadeEndProgress: CGFloat = 0.82
    private let headerSnapThresholdProgress: CGFloat = 0.5
    private let headerSnapVelocityThreshold: CGFloat = 160

    var venueDetails: ClipVenue?
    var uniqueId: String? = ""
    var venueTimeZone = ""
    var doormanId = ""
    var onFollowStateChanged: ((ClipVenue, Bool) -> Void)?
    var isPresentedPremium = false
    private var isFollowing = false
    private var isFollowLoading = false
    private var didAppearOnce = false
    private var isSocketRefreshInProgress = false
    private var hasAvailableUpsellTickets = false
    private var upsellAvailabilityVenueId: String?
    private var isVenueDetailsLoaded = false
    private var isUpsellAvailabilityLoaded = false
    private var isCoverTicketNavigationInProgress = false
    private var followedVenueId: String?
    private var hasLocalFollowState = false
    private var resolvedVenueTimeZone: String {
        venueTimeZone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? TimeZone.current.identifier
            : venueTimeZone
    }
    private lazy var leftEdgeBackGesture: UIScreenEdgePanGestureRecognizer = {
        let gesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleLeftEdgeBackGesture(_:))
        )
        gesture.edges = .left
        gesture.delegate = self
        return gesture
    }()
    private let followActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = false
        indicator.alpha = 0
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        captureContainerTopConstraint()
        setupFollowButtonAnimation()
        setupNavTitleView()
        setupPosterBackground()
        setUpData()
        setupTabsIfNeeded()
        getVenueDetails()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isCoverTicketNavigationInProgress = false
        setupLeftEdgeBackGestureIfNeeded()
        registerSocketDelegate()

        if didAppearOnce {
            refreshVenueFollowStateIfNeeded()
        } else {
            didAppearOnce = true
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterSocketDelegate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderCollapseMetrics()
        applyHeaderCollapse(animated: false)
    }

    private func getVenueDetails() {
        let venueUniqueId =
        (venueDetails?.uniqueId ?? uniqueId) ?? ""

        isVenueDetailsLoaded = false
        isUpsellAvailabilityLoaded = false
        hasAvailableUpsellTickets = false
        updateCoverTicketViewVisibility()

        venueService.fetchCoverVenueDetail(
            uniqueId: venueUniqueId,
            venueTimeZone: resolvedVenueTimeZone,
            doormanId: doormanId
        ) { [weak self] isSuccess, errMsg, venueDetail in
            guard let self = self else { return }

            if isSuccess, var venue = venueDetail {
                self.applyLocalFollowStateIfNeeded(to: &venue)
                self.venueDetails = venue
                self.isVenueDetailsLoaded = true
                self.isUpsellAvailabilityLoaded = false
                self.hasAvailableUpsellTickets = false
                self.upsellAvailabilityVenueId = nil
                WebSocketWrapper.shared.updateSocketContext(venueId: venue.id)
                self.setUpData()
                self.setupTabsIfNeeded()
            } else {
                self.isVenueDetailsLoaded = false
                self.isUpsellAvailabilityLoaded = true
                self.updateCoverTicketViewVisibility()
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? "Something went wrong",
                    message: ""
                )
            }
        }
    }

    private func setUpData() {
        venueName.text = displayVenueName
        updateNavTitleText()
        syncFollowState()
        updateFollowUI(animated: false)
        updateCoverTicketViewVisibility()
        updatePosterBackgroundImage()
        if isVenueDetailsLoaded {
            refreshUpsellAvailabilityIfNeeded()
        }

        let logoUrl = "\(SharedURL.amazonStorage)\(venueDetails?.logo?.key ?? "")"
        venueLogo.sd_setImage(with: URL(string: logoUrl), completed: nil)
        
        let displayCity = venueDetails?.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationText = displayCity?.isEmpty == false
            ? displayCity
            : venueDetails?.timezone
        venueCityLbl.text = locationText

//        if let url = URL(string: imageUrlString) {
//            bgImage.sd_setImage(with: url, placeholderImage: UIImage(named: "newSpeakeasy"))
//        } else {
//            bgImage.image = UIImage(named: "newSpeakeasy")
//        }
    }

    private func setupPosterBackground() {
        guard posterHeaderView.superview == nil else {
            updatePosterBackgroundImage()
            return
        }

        self.bgView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: self.bgView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: self.bgView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: self.bgView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: self.bgView.bottomAnchor)
        ])

//        posterHeaderView.configure(style: .gradientImage)
        updatePosterBackgroundImage()
    }

    private func updatePosterBackgroundImage() {
        let imageKey = venueDetails?.venueAttachment?.first?.key ?? ""
        let imageUrlString = imageKey.isEmpty ? "" : "\(SharedURL.amazonStorage)\(imageKey)"
        posterHeaderView.loadImage(from: imageUrlString)
    }

    private func setUpTabs() {
        createTabControllers()
        setupPageVC()
        setupGlassSegment()

        view.bringSubviewToFront(tabView)
    }

    private func setupTabsIfNeeded() {
        guard tabControllers.isEmpty else { return }
        guard venueDetails?.id.isEmpty == false else { return }
        setUpTabs()
    }

    private func createTabControllers() {
        let vc1 = VenueEventsVC(nibName: "VenueEventsVC", bundle: nil)
        vc1.title = "Events"
        vc1.venueId = venueDetails?.id ?? ""
        vc1.scrollDelegate = self

        let vc2 = VenueExperiencesVC(nibName: "VenueExperiencesVC", bundle: nil)
        vc2.title = "Premium"
        vc2.venueId = venueDetails?.id ?? ""
        vc2.scrollDelegate = self

        let vc3 = ArtistsVC(nibName: "ArtistsVC", bundle: nil)
        vc3.title = "Artists"
        vc3.venueId = venueDetails?.id ?? ""
        vc3.scrollDelegate = self

        tabControllers = [vc1, vc2, vc3]
    }

    private func setupGlassSegment() {
        glassSegment.translatesAutoresizingMaskIntoConstraints = false
        glassSegment.isUserInteractionEnabled = true
        glassSegment.setSelectedIndex(0, animated: false)

        tabView.isUserInteractionEnabled = true
        tabView.clipsToBounds = false

        tabView.subviews.forEach { $0.removeFromSuperview() }
        tabView.addSubview(glassSegment)

        NSLayoutConstraint.activate([
            glassSegment.leadingAnchor.constraint(equalTo: tabView.leadingAnchor),
            glassSegment.trailingAnchor.constraint(equalTo: tabView.trailingAnchor),
            glassSegment.topAnchor.constraint(equalTo: tabView.topAnchor),
            glassSegment.bottomAnchor.constraint(equalTo: tabView.bottomAnchor)
        ])

        glassSegment.onIndexChanged = { [weak self] index in
            self?.moveToPage(index)
        }

        view.bringSubviewToFront(tabView)
    }

    private func setupPageVC() {
        guard let firstVC = tabControllers.first else { return }

        addChild(pageVC)
        containerView.addSubview(pageVC.view)

        pageVC.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pageVC.view.leadingAnchor.constraint(equalTo: venueView.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: venueView.trailingAnchor),
            pageVC.view.topAnchor.constraint(equalTo: venueView.topAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: venueView.bottomAnchor)
        ])

        pageVC.didMove(toParent: self)

        pageVC.dataSource = self
        pageVC.delegate = self

        pageVC.setViewControllers(
            [firstVC],
            direction: .forward,
            animated: false
        )
        resetTrackedOffset(for: firstVC)
    }

    private func moveToPage(_ index: Int) {
        guard index >= 0, index < tabControllers.count else { return }
        guard index != selectedIndex else { return }

        let direction: UIPageViewController.NavigationDirection = index > selectedIndex ? .forward : .reverse

        pageVC.setViewControllers(
            [tabControllers[index]],
            direction: direction,
            animated: true
        ) { [weak self] completed in
            guard let self = self else { return }

            if completed {
                self.selectedIndex = index
                self.glassSegment.setSelectedIndex(index, animated: true)
                self.resetTrackedOffset(for: self.tabControllers[index])
            }
        }
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        handleBackNavigation()
    }

    private func handleBackNavigation() {
        if isPresentedPremium {
            dismissPremium()
            return
        }

        Navigate.to.back(self)
    }

    private func setupLeftEdgeBackGestureIfNeeded() {
        guard isPresentedPremium,
              leftEdgeBackGesture.view == nil
        else {
            return
        }

        view.addGestureRecognizer(leftEdgeBackGesture)
    }

    @objc private func handleLeftEdgeBackGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard gesture.state == .ended else { return }

        let translationX = gesture.translation(in: view).x
        let velocityX = gesture.velocity(in: view).x

        guard translationX > 70 || velocityX > 450 else { return }

        handleBackNavigation()
    }

    @IBAction func onClickShare(_ sender: Any) {
        let msgText = "Check out \(venueDetails?.name ?? "Partner") on Speakeasy. \(String(format: APIBuilder.venueWebURL, venueDetails?.name.lowercased().replacingOccurrences(of: " ", with: "-") ?? "Partner", venueDetails?.uniqueId ?? "")) Download the app to directly connect with your favorite partners & never miss out! \(SharedURL.appStoreURL)"
        Utility.main.shareSocialWith(text: msgText)
    }

    @IBAction func onClickBuyTicket(_ sender: Any) {
        openCoverTicketList()
    }

    func openCoverTicketList() {
        guard isCoverTicketNavigationReady,
              !isCoverTicketNavigationInProgress
        else { return }

        isCoverTicketNavigationInProgress = true
        Navigate.to.coverTicketListVC(
            self,
            venueDetails: venueDetails,
            doormanId: doormanId,
            shouldShowDirectUpsell: !hasAvailableTickets && hasAvailableUpsellTickets
        )
    }

    @IBAction func onClickFollowBtn(_ sender: Any) {
        guard !isFollowLoading else { return }
        guard LoginRequiredCoordinator.isAuthenticated else {
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                self?.onClickFollowBtn(sender)
            }
            return
        }

        guard let venueUniqueId =
                venueDetails?.uniqueId,
              !venueUniqueId.isEmpty
        else {
            return
        }

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
            guard let followedVenueId,
                  !followedVenueId.isEmpty
            else {
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

// MARK: - WebSocket
extension VenueVC: WebSocketCallBackDelegate {

    func updateTicketPrice(ticket: [CoverTicket]) {
        guard isCurrentVenueCoverTicketUpdate(ticket) else { return }
        refreshVenueFromSocket(resetTickets: true)
    }

    func updateAddOnsTicketPrice(ticket: [UpSellTicket]) {
        guard isCurrentVenueAddOnUpdate(ticket) else { return }
        refreshVenueFromSocket(resetTickets: false)
    }

    func updateVenueStatus(venueId: String, venueStatus: String) {
        guard venueDetails?.id == venueId else { return }
        refreshVenueFromSocket(resetTickets: true)
    }

    func didGenderWiseTicketChange(venueId: String, uniqueId: String) {
        guard venueDetails?.id == venueId || venueDetails?.uniqueId == uniqueId else { return }
        refreshVenueFromSocket(resetTickets: true)
    }

    func didUpdateEvent(eventId: String) {
        refreshVenueEventTabs()
    }

    func didUpdateEventTicket(ticket: EventTicket) {
        refreshVenueEventTabs()
    }
}

// MARK: - Sticky Header Coordination
private extension VenueVC {

    func registerSocketDelegate() {
        WebSocketWrapper.shared.updateSocketContext(venueId: venueDetails?.id)
        WebSocketWrapper.shared.removeDelegate(self)
        WebSocketWrapper.shared.addDelegate(self) 
    }

    func unregisterSocketDelegate() {
        WebSocketWrapper.shared.removeDelegate(self)
    }

    func refreshVenueFromSocket(resetTickets: Bool) {
        guard !isSocketRefreshInProgress else { return }

        let venueUniqueId = (venueDetails?.uniqueId ?? uniqueId) ?? ""
        guard !venueUniqueId.isEmpty else { return }

        isSocketRefreshInProgress = true
        isVenueDetailsLoaded = false
        isUpsellAvailabilityLoaded = false
        hasAvailableUpsellTickets = false
        updateCoverTicketViewVisibility()

        venueService.fetchCoverVenueDetail(
            uniqueId: venueUniqueId,
            venueTimeZone: resolvedVenueTimeZone,
            doormanId: doormanId
        ) { [weak self] isSuccess, _, venueDetail in
            guard let self else { return }

            self.isSocketRefreshInProgress = false

            guard isSuccess, let venueDetail else { return }

            var refreshedVenue = venueDetail
            self.applyLocalFollowStateIfNeeded(to: &refreshedVenue)
            self.venueDetails = refreshedVenue
            self.isVenueDetailsLoaded = true
            self.isUpsellAvailabilityLoaded = false
            self.hasAvailableUpsellTickets = false
            self.upsellAvailabilityVenueId = nil
            WebSocketWrapper.shared.updateSocketContext(venueId: refreshedVenue.id)
            self.setUpData()

            if resetTickets {
                self.refreshVenueEventTabs()
            }
        }
    }

    func refreshVenueEventTabs() {
        tabControllers.forEach { controller in
            if let eventsVC = controller as? VenueEventsVC {
                eventsVC.refreshFromSocket()
            } else if let experiencesVC = controller as? VenueExperiencesVC {
                experiencesVC.refreshFromSocket()
            }
        }
    }

    func isCurrentVenueCoverTicketUpdate(_ tickets: [CoverTicket]) -> Bool {
        let currentVenueId = venueDetails?.id ?? ""
        guard !currentVenueId.isEmpty else { return false }
        return tickets.contains { $0.venueId == currentVenueId }
    }

    func isCurrentVenueAddOnUpdate(_ tickets: [UpSellTicket]) -> Bool {
        let currentVenueId = venueDetails?.id ?? ""
        guard !currentVenueId.isEmpty else { return false }
        return tickets.contains { $0.addOns?.venueId == currentVenueId }
    }

    func syncFollowState() {
        followedVenueId =
        venueDetails?.venueFollowedId

        isFollowing =
        venueDetails?.isFollowing == true ||
        followedVenueId != nil
    }

    func applyLocalFollowStateIfNeeded(to venue: inout ClipVenue) {
        guard hasLocalFollowState, isFollowLoading else { return }

        venue.isFollowing = isFollowing
        venue.venueFollowedId = followedVenueId
    }

    func refreshVenueFollowStateIfNeeded() {
        guard !isFollowLoading else { return }

        let venueUniqueId = (venueDetails?.uniqueId ?? uniqueId) ?? ""
        guard !venueUniqueId.isEmpty else { return }

        venueService.fetchCoverVenueDetail(
            uniqueId: venueUniqueId,
            venueTimeZone: resolvedVenueTimeZone,
            doormanId: doormanId
        ) { [weak self] isSuccess, _, venueDetail in
            guard let self,
                  isSuccess,
                  var venueDetail
            else { return }

            self.applyLocalFollowStateIfNeeded(to: &venueDetail)
            self.venueDetails = venueDetail
            WebSocketWrapper.shared.updateSocketContext(venueId: venueDetail.id)
            self.syncFollowState()
            self.updateFollowUI(animated: true)
            self.updateCoverTicketViewVisibility()

            if let venue = self.venueDetails {
                self.onFollowStateChanged?(venue, self.isFollowing)
            }
        }
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

        let animations = {
            applyTitle()
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
                animations: animations,
                completion: completion
            )
        } else {
            UIView.animate(
                withDuration: 0.18,
                delay: 0,
                options: [.curveEaseOut, .beginFromCurrentState],
                animations: animations,
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

    var displayVenueName: String {
        let name = (venueDetails?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Partner" : name
    }

    var displayVenueCity: String {
        return (venueDetails?.city ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasAvailableTickets: Bool {
        let tickets = venueDetails?.coverTicket ?? []
        return tickets.contains {
            !($0.isDeleted ?? false) &&
            $0.status == "ENABLED"
        }
    }

    var isCoverTicketNavigationReady: Bool {
        isVenueDetailsLoaded &&
        isUpsellAvailabilityLoaded &&
        (hasAvailableTickets || hasAvailableUpsellTickets)
    }

    func updateCoverTicketViewVisibility() {
        coverTicketView.isHidden = !isCoverTicketNavigationReady
        coverTicketView.isUserInteractionEnabled = isCoverTicketNavigationReady
        view.setNeedsLayout()
    }

    func refreshUpsellAvailabilityIfNeeded(force: Bool = false) {
        guard isVenueDetailsLoaded else {
            isUpsellAvailabilityLoaded = false
            updateCoverTicketViewVisibility()
            return
        }

        guard let venueId = venueDetails?.id, !venueId.isEmpty else {
            isUpsellAvailabilityLoaded = true
            hasAvailableUpsellTickets = false
            updateCoverTicketViewVisibility()
            return
        }

        guard force || upsellAvailabilityVenueId != venueId else { return }

        isUpsellAvailabilityLoaded = false
        upsellAvailabilityVenueId = venueId
        updateCoverTicketViewVisibility()

        venueService.fetchUpSellItems(skip: 0, venueId: venueId) { [weak self] isSuccess, _, upSellItems, _, _ in
            guard let self else { return }
            guard self.venueDetails?.id == venueId else { return }

            self.hasAvailableUpsellTickets = isSuccess && upSellItems.contains {
                !$0.isDeleted && $0.status == "ENABLED" && $0.addOns?.isDeleted == false && $0.addOns?.status == "ENABLED"
            }
            self.isUpsellAvailabilityLoaded = true
            self.updateCoverTicketViewVisibility()
        }
    }

    func setupNavTitleView() {
        navTitleStackView.axis = .vertical
        navTitleStackView.alignment = .center
        navTitleStackView.distribution = .fill
        navTitleStackView.spacing = 1
        navTitleStackView.alpha = 0
        navTitleStackView.isUserInteractionEnabled = false
        navTitleStackView.translatesAutoresizingMaskIntoConstraints = false

        navVenueNameLabel.font = Constant.Font.geistMedium(size: 20)
        navVenueNameLabel.textColor = .white
        navVenueNameLabel.animationSpeed = 25
        navVenueNameLabel.animationDelay = 1.2
        navVenueNameLabel.trailingSpacing = 48
        navVenueNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        navVenueNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        navVenueCityLabel.font = Constant.Font.geistMedium(size: 12)
        navVenueCityLabel.textColor = UIColor(hex: "#A1A1A1")
        navVenueCityLabel.textAlignment = .center
        navVenueCityLabel.numberOfLines = 1
        navVenueCityLabel.lineBreakMode = .byTruncatingTail
        navVenueCityLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        navTitleStackView.addArrangedSubview(navVenueNameLabel)
        navTitleStackView.addArrangedSubview(navVenueCityLabel)
        view.addSubview(navTitleStackView)

        let titleWidthConstraint = navTitleStackView.widthAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.widthAnchor,
            constant: -144
        )
        navTitleWidthConstraint = titleWidthConstraint

        NSLayoutConstraint.activate([
            navTitleStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            navTitleStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36),
            navTitleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 72),
            navTitleStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -72),
            titleWidthConstraint,
            navVenueNameLabel.widthAnchor.constraint(equalTo: navTitleStackView.widthAnchor),
            navVenueNameLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func updateNavTitleText() {
        navVenueNameLabel.setText(displayVenueName)
        navVenueCityLabel.text = displayVenueCity
        navVenueCityLabel.isHidden = displayVenueCity.isEmpty
        navTitleStackView.setNeedsLayout()
        navVenueNameLabel.setNeedsLayout()
    }

    func captureContainerTopConstraint() {
        containerTopConstraint = view.constraints.first(where: { constraint in
            guard let firstView = constraint.firstItem as? UIView else { return false }
            return firstView === containerView && constraint.firstAttribute == .top
        })
    }

    func updateHeaderCollapseMetrics() {
        let tabFrame = tabView.convert(tabView.bounds, to: view)
        let stickyTopY = view.safeAreaInsets.top + stickySegmentTopSpacing
        let newMaxOffset = max(0, tabFrame.minY - stickyTopY + headerCollapseOffset)

        guard abs(newMaxOffset - maxHeaderCollapseOffset) > 0.5 else { return }

        maxHeaderCollapseOffset = newMaxOffset
        headerCollapseOffset = min(headerCollapseOffset, maxHeaderCollapseOffset)
    }

    func applyHeaderCollapse(animated: Bool) {
        headerCollapseOffset = min(max(headerCollapseOffset, 0), maxHeaderCollapseOffset)
        containerTopConstraint?.constant = -headerCollapseOffset

        let progress: CGFloat
        if maxHeaderCollapseOffset > 0 {
            progress = min(1, max(0, headerCollapseOffset / maxHeaderCollapseOffset))
        } else {
            progress = 0
        }

        let visibleAlpha = headerContentAlpha(for: progress)
        containerView.subviews.forEach { subview in
            if subview === buyticketView || subview === venueView {
                return
            }

            if pageVC.isViewLoaded, subview === pageVC.view {
                return
            }

            subview.alpha = visibleAlpha
        }
        updateBuyTicketHeaderAlpha(visibleAlpha)
        updateNavTitleAlpha(navTitleAlpha(for: progress))

        let updates = {
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                options: [.curveEaseOut, .beginFromCurrentState],
                animations: updates
            )
        } else {
            updates()
        }
    }

    func updateBuyTicketHeaderAlpha(_ alpha: CGFloat) {
        buyticketView.subviews.forEach { subview in
            if let stackView = subview as? UIStackView {
                stackView.arrangedSubviews.forEach { arrangedSubview in
                    guard arrangedSubview !== tabView else { return }
                    arrangedSubview.alpha = alpha
                }
            } else if subview !== tabView {
                subview.alpha = alpha
            }
        }
    }

    func updateNavTitleAlpha(_ alpha: CGFloat) {
        navTitleStackView.alpha = alpha
        view.bringSubviewToFront(navTitleStackView)
    }

    func headerContentAlpha(for progress: CGFloat) -> CGFloat {
        return 1 - smoothProgress(
            progress,
            start: headerFadeStartProgress,
            end: headerFadeEndProgress
        )
    }

    func navTitleAlpha(for progress: CGFloat) -> CGFloat {
        return smoothProgress(
            progress,
            start: navTitleFadeStartProgress,
            end: navTitleFadeEndProgress
        )
    }

    func smoothProgress(_ value: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        guard end > start else { return value >= end ? 1 : 0 }

        let normalized = min(1, max(0, (value - start) / (end - start)))
        return normalized * normalized * (3 - 2 * normalized)
    }

    func resetTrackedOffset(for viewController: UIViewController) {
        guard let scrollView = observedScrollView(for: viewController) else { return }
        let scrollID = ObjectIdentifier(scrollView)
        childScrollOffsets[scrollID] = scrollView.contentOffset.y
        childPanTranslations.removeValue(forKey: scrollID)
        registerPanHandlerIfNeeded(for: scrollView, scrollID: scrollID)
    }

    func observedScrollView(for viewController: UIViewController) -> UIScrollView? {
        guard viewController.isViewLoaded else { return nil }

        if let eventsVC = viewController as? VenueEventsVC {
            return eventsVC.collectionView
        }

        if let experiencesVC = viewController as? VenueExperiencesVC {
            return experiencesVC.collectionView
        }

        if let artistsVC = viewController as? ArtistsVC {
            return artistsVC.tableView
        }

        return nil
    }
}

// MARK: - ChildScrollDelegate
extension VenueVC: ChildScrollDelegate {

    var isHeaderFullyCollapsed: Bool {
        return headerCollapseOffset >= maxHeaderCollapseOffset - 0.5
    }

    func childScrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isUpdatingChildScrollOffset else { return }
        guard maxHeaderCollapseOffset > 0 else { return }

        let scrollID = ObjectIdentifier(scrollView)
        registerPanHandlerIfNeeded(for: scrollView, scrollID: scrollID)

        let currentOffsetY = scrollView.contentOffset.y
        let previousOffsetY = childScrollOffsets[scrollID] ?? currentOffsetY
        let deltaY = currentOffsetY - previousOffsetY
        let topOffsetY = topContentOffsetY(for: scrollView)

        childScrollOffsets[scrollID] = currentOffsetY

        guard abs(deltaY) > 0.1 else { return }

        if deltaY > 0, headerCollapseOffset < maxHeaderCollapseOffset {
            consumeUpwardScroll(deltaY, from: scrollView, scrollID: scrollID, topOffsetY: topOffsetY)
        }
    }

    private func consumeUpwardScroll(
        _ deltaY: CGFloat,
        from scrollView: UIScrollView,
        scrollID: ObjectIdentifier,
        topOffsetY: CGFloat
    ) {
        let consumed = min(deltaY, maxHeaderCollapseOffset - headerCollapseOffset)
        guard consumed > 0 else { return }

        headerCollapseOffset = min(maxHeaderCollapseOffset, headerCollapseOffset + consumed)
        applyHeaderCollapse(animated: false)
        let targetOffsetY = max(topOffsetY, scrollView.contentOffset.y - consumed)
        set(scrollView, contentOffsetY: targetOffsetY, scrollID: scrollID)
    }

    private func consumeDownwardScroll(
        _ deltaY: CGFloat,
        from scrollView: UIScrollView,
        scrollID: ObjectIdentifier,
        topOffsetY: CGFloat
    ) {
        let consumed = min(deltaY, headerCollapseOffset)
        guard consumed > 0 else { return }

        headerCollapseOffset = max(0, headerCollapseOffset - consumed)
        applyHeaderCollapse(animated: false)
        set(scrollView, contentOffsetY: topOffsetY, scrollID: scrollID)
    }

    private func set(
        _ scrollView: UIScrollView,
        contentOffsetY: CGFloat,
        scrollID: ObjectIdentifier
    ) {
        isUpdatingChildScrollOffset = true
        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: contentOffsetY),
            animated: false
        )
        isUpdatingChildScrollOffset = false
        childScrollOffsets[scrollID] = scrollView.contentOffset.y
    }

    private func topContentOffsetY(for scrollView: UIScrollView) -> CGFloat {
        return -scrollView.adjustedContentInset.top
    }

    private func settleHeaderAfterScrollEnds(
        for scrollView: UIScrollView,
        scrollID: ObjectIdentifier,
        velocityY: CGFloat
    ) {
        guard maxHeaderCollapseOffset > 0 else { return }
        guard headerCollapseOffset > 0,
              headerCollapseOffset < maxHeaderCollapseOffset
        else {
            return
        }

        let progress = headerCollapseOffset / maxHeaderCollapseOffset
        let shouldCollapse: Bool

        if abs(velocityY) >= headerSnapVelocityThreshold {
            shouldCollapse = velocityY < 0
        } else {
            shouldCollapse = progress >= headerSnapThresholdProgress
        }

        let targetOffset = shouldCollapse ? maxHeaderCollapseOffset : 0
        headerCollapseOffset = targetOffset
        set(scrollView, contentOffsetY: topContentOffsetY(for: scrollView), scrollID: scrollID)
        applyHeaderCollapse(animated: true)
    }

    func registerPanHandlerIfNeeded(for scrollView: UIScrollView, scrollID: ObjectIdentifier) {
        guard !registeredPanScrollIDs.contains(scrollID) else { return }

        registeredPanScrollIDs.insert(scrollID)
        scrollView.panGestureRecognizer.addTarget(
            self,
            action: #selector(handleChildPan(_:))
        )
    }

    @objc func handleChildPan(_ gesture: UIPanGestureRecognizer) {
        guard let scrollView = gesture.view as? UIScrollView else { return }

        let scrollID = ObjectIdentifier(scrollView)

        if gesture.state == .ended ||
            gesture.state == .cancelled ||
            gesture.state == .failed {
            settleHeaderAfterScrollEnds(
                for: scrollView,
                scrollID: scrollID,
                velocityY: gesture.velocity(in: view).y
            )
            childPanTranslations.removeValue(forKey: scrollID)
            return
        }

        guard !isUpdatingChildScrollOffset else { return }

        let currentTranslationY = gesture.translation(in: view).y
        let topOffsetY = topContentOffsetY(for: scrollView)

        guard headerCollapseOffset > 0 else {
            childPanTranslations[scrollID] = currentTranslationY
            return
        }

        switch gesture.state {
        case .began:
            childPanTranslations[scrollID] = currentTranslationY

        case .changed:
            guard scrollView.contentOffset.y <= topOffsetY + headerExpansionStartTolerance else {
                childPanTranslations[scrollID] = currentTranslationY
                return
            }

            let previousTranslationY = childPanTranslations[scrollID] ?? currentTranslationY
            let deltaY = currentTranslationY - previousTranslationY

            childPanTranslations[scrollID] = currentTranslationY

            guard deltaY > 0 else { return }

            consumeDownwardScroll(
                deltaY * headerExpansionDragMultiplier,
                from: scrollView,
                scrollID: scrollID,
                topOffsetY: topOffsetY
            )

        default:
            childPanTranslations.removeValue(forKey: scrollID)
        }
    }
}

// MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate
extension VenueVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = tabControllers.firstIndex(of: viewController),
              index > 0
        else {
            return nil
        }

        return tabControllers[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = tabControllers.firstIndex(of: viewController),
              index < tabControllers.count - 1
        else {
            return nil
        }

        return tabControllers[index + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first,
              let index = tabControllers.firstIndex(of: currentVC)
        else {
            return
        }

        selectedIndex = index
        glassSegment.setSelectedIndex(index, animated: true)
        resetTrackedOffset(for: currentVC)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension VenueVC: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === leftEdgeBackGesture {
            return isPresentedPremium
        }

        return true
    }
}

// MARK: - GlassSegmentView

final class GlassSegmentView: UIControl {

    var onIndexChanged: ((Int) -> Void)?
    private(set) var selectedIndex: Int = 0

    private let glassBackground = LiquidGlassBackgroundView(
        cornerRadius: 24,
        fillColor: UIColor.black.withAlphaComponent(0.18),
        borderColor: UIColor.white.withAlphaComponent(0.2),
        borderWidth: 0.8
    )
    private let selectedView = LiquidGlassBackgroundView(
        cornerRadius: 20,
        fillColor: .clear,
        borderColor: UIColor.white.withAlphaComponent(0.2),
        borderWidth: 0.8
    )
    private let selectedGradientLayer = CAGradientLayer()

    private var labels: [UILabel] = []
    private var selectedLeading: NSLayoutConstraint!
    private var selectedWidth: NSLayoutConstraint!
    private var titles: [String] = []

    init(titles: [String]) {
        self.titles = titles
        super.init(frame: .zero)
        setupUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        glassBackground.layer.cornerRadius = bounds.height / 2
        selectedView.layer.cornerRadius = selectedView.bounds.height / 2
        selectedGradientLayer.frame = selectedView.bounds
        selectedGradientLayer.cornerRadius = selectedView.bounds.height / 2

        updateSelectedPosition(animated: false)
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        glassBackground.translatesAutoresizingMaskIntoConstraints = false
        glassBackground.isUserInteractionEnabled = false
        glassBackground.clipsToBounds = true
        insertSubview(glassBackground, at: 0)

        NSLayoutConstraint.activate([
            glassBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassBackground.topAnchor.constraint(equalTo: topAnchor),
            glassBackground.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        selectedView.translatesAutoresizingMaskIntoConstraints = false
        selectedView.isUserInteractionEnabled = false
        selectedView.clipsToBounds = true

        selectedGradientLayer.colors = [
            UIColor.white.withAlphaComponent(0.18).cgColor,
            UIColor.white.withAlphaComponent(0.08).cgColor
        ]
        selectedGradientLayer.locations = [0, 1]
        selectedGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        selectedGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        selectedGradientLayer.masksToBounds = true
        selectedView.layer.insertSublayer(selectedGradientLayer, at: 0)

        addSubview(selectedView)

        setupLabels()
        setupConstraints()

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
    }

    private func setupLabels() {
        for title in titles {
            let lbl = UILabel()
            lbl.text = title
            lbl.textAlignment = .center
            lbl.font = Constant.Font.geistMedium(size: 14)
            lbl.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.95)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.isUserInteractionEnabled = false
            addSubview(lbl)
            labels.append(lbl)
        }
    }

    private func setupConstraints() {
        guard !labels.isEmpty else { return }

        let count = CGFloat(labels.count)

        selectedLeading = selectedView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
        selectedWidth = selectedView.widthAnchor.constraint(equalToConstant: 100)

        NSLayoutConstraint.activate([
            selectedLeading,
            selectedWidth,
            selectedView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            selectedView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])

        for (i, lbl) in labels.enumerated() {
            NSLayoutConstraint.activate([
                lbl.topAnchor.constraint(equalTo: topAnchor),
                lbl.bottomAnchor.constraint(equalTo: bottomAnchor),
                lbl.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1 / count)
            ])

            if i == 0 {
                lbl.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                lbl.leadingAnchor.constraint(equalTo: labels[i - 1].trailingAnchor).isActive = true
            }
        }

        updateLabelAlpha()
    }

    func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard index >= 0, index < labels.count else { return }

        selectedIndex = index
        updateSelectedPosition(animated: animated)
        updateLabelAlpha()
    }

    private func updateSelectedPosition(animated: Bool) {
        guard bounds.width > 0, !labels.isEmpty else { return }

        let count = CGFloat(labels.count)
        let slot = bounds.width / count

        selectedLeading.constant = slot * CGFloat(selectedIndex) + 4
        selectedWidth.constant = slot - 8

        let animations = {
            self.layoutIfNeeded()
            self.updateLabelStyle()
            self.selectedGradientLayer.frame = self.selectedView.bounds
            self.selectedGradientLayer.cornerRadius = self.selectedView.bounds.height / 2
        }

        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.5,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: animations
            )
        } else {
            animations()
        }
    }

    private func updateLabelAlpha() {
        updateLabelStyle()
    }

    private func updateLabelStyle() {
        for (i, lbl) in labels.enumerated() {
            let isSelected = i == selectedIndex
            lbl.alpha = isSelected ? 1.0 : 0.72
            lbl.font = isSelected
                ? Constant.Font.geistMedium(size: 14)
                : Constant.Font.geistRegular(size: 14)
        }
    }

    @objc private func onTap(_ gesture: UITapGestureRecognizer) {
        guard bounds.width > 0, !labels.isEmpty else { return }

        let x = gesture.location(in: self).x
        let index = Int(x / (bounds.width / CGFloat(labels.count)))
        let clamped = max(0, min(index, labels.count - 1))

        guard clamped != selectedIndex else { return }

        onIndexChanged?(clamped)
    }}
