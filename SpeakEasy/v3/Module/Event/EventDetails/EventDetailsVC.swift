//
//  EventDetailsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 05/02/26.
//
// swiftlint: disable all

import UIKit
import CoreLocation
import GoogleMaps
import YouTubeiOSPlayerHelper
import MHLoadingButton
import SDWebImage

class EventDetailsVC: UIViewController {

    @IBOutlet weak var guestListCollectionView: UICollectionView!
    @IBOutlet weak var detailsLbl: UILabel!
    @IBOutlet weak var youTubePlayerView: UIView!
    @IBOutlet weak var imageListView: UIView!
    @IBOutlet weak var lineUpCollectionView: UICollectionView!
    @IBOutlet weak var policyLbl: UILabel!
    @IBOutlet weak var faqsTableView: UITableView!
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var venueAddressLbl: UILabel!
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueFooterBackgroundView: UIView!
    @IBOutlet weak var viewGuestListBtn: UIButton!
    @IBOutlet weak var viewMoreBtnView: UIView!
    @IBOutlet weak var viewMoreBtn: UIButton!
    @IBOutlet weak var mainImg: UIImageView!
    @IBOutlet weak var imageShadowView: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var venueTitleLbl: UILabel!
    @IBOutlet weak var pageTitleName: UILabel!
    @IBOutlet weak var timingLbl: UILabel!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var instaImageView: UIImageView!
    @IBOutlet weak var tikTokImageView: UIImageView!
    @IBOutlet weak var faceBookImageView: UIImageView!
    @IBOutlet weak var xImageView: UIImageView!
    @IBOutlet weak var youTubeImageView: UIImageView!
    @IBOutlet weak var websiteImageView: UIImageView!
    @IBOutlet weak var attendeesView: UIView!
    @IBOutlet weak var imageListHiddenView: UIView!
    @IBOutlet weak var lineUpHiddenView: UIView!
    @IBOutlet weak var vipTablesView: UIView!
    @IBOutlet weak var guestListTitleLbl: UILabel!
    @IBOutlet weak var youTubeSuperView: UIView!
    @IBOutlet weak var policyViewMoreBtnView: UIView!
    @IBOutlet weak var policyViewMoreBtn: UIButton!
    @IBOutlet weak var ticketHidenView: UIView!
    @IBOutlet weak var ticketTableView: UITableView!
    @IBOutlet weak var protectedTicketView: UIView!
    @IBOutlet weak var unLockTF: UITextField!
    @IBOutlet weak var unLockBtn: UIView!
    @IBOutlet weak var ticketTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var webSiteView: UIView!
    @IBOutlet weak var bottemButtonView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var detailsTitleLbl: UILabel!
    @IBOutlet weak var tableBookNowButtonView: UIView!
    @IBOutlet weak var policyView: UIView!
    @IBOutlet weak var eventAddressView: UIView!
    @IBOutlet weak var faqsTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var faqsView: UIView!
    @IBOutlet weak var lockIcon: UIImageView!
    @IBOutlet weak var buyNowBtnSuperView: UIView!
//    @IBOutlet weak var continueToCheckOutView: UIView!
    @IBOutlet weak var groupTableView: UITableView!
    @IBOutlet weak var groupTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var vipTableTitleLbl: UILabel!
    @IBOutlet weak var vipTableSubTitleLbl: UILabel!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var viewSkeleton: UIView!
    @IBOutlet weak var imageBackGroundView: UIView!
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var checkOutBtn: LoadingButton!
    @IBOutlet weak var imageListViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var additionalButtonsTableView: UITableView!
    @IBOutlet weak var additionalButtonsTableHeight: NSLayoutConstraint!
    @IBOutlet weak var checkOutBtnView: CheckoutBarView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var soldOutView: UIView!
    @IBOutlet weak var soldOutLbl: UILabel!
    
    private let eventDetailsSkeletonView = EventDetailsSkeletonView()
    private var imagePagerVC: ImagePagerVC?
    private let faqCount = 5
    private var playerView: YTPlayerView?
    private var isExpanded = false
    private var isPolicyLblExpanded = false
    private let collapsedLines = 5
    private let maxVisibleLineupArtists = 4
    private let lineupChipSize: CGFloat = 60
    private let lineupChipTargetSpacing: CGFloat = 12
    private let lineupChipMinimumSpacing: CGFloat = 4
    private let lineupChipTargetSideInset: CGFloat = 25
    private var lastLineupCollectionWidth: CGFloat = 0
    private var lastDetailsLabelWidth: CGFloat = 0
    private var lastPolicyLabelWidth: CGFloat = 0
    private var fullText = ""
    private var faqsTableObserver: NSKeyValueObservation?
    private var ticketTableObserver: NSKeyValueObservation?
    private var groupTableObserver: NSKeyValueObservation?
    private var additionalButtonsTableObserver: NSKeyValueObservation?
    private let eventTitleMarqueeLabel = PremiumMarqueeLabel()
    private let youTubeShimmerView = ShimmerViewV3(frame: .zero, lighter: true)
    private var isYouTubePlayerReady = false
    private var googleMapView: GMSMapView?

    var venueDetails: ClipVenue?
    var event: Event?
    var uniqueId: String? = ""
    var onSaveStateChanged: ((Event, Bool) -> Void)?
    var promoteId = ""
    var promotionLinkUniqueCode = ""
    var micrositeSlug = ""
    var shouldShowDisabledTicketButton = true
    private var eventTicketId = [String]()
    private var artists = [ArtistData]()

    private var tickets: [EventTicket] = []
    private var normalTickets: [EventTicket] = []
    private var groupedNormalTickets: [(groupId: String, groupName: String, tickets: [EventTicket])] = []
    private var expandedGroupIds: Set<String> = []
    private var expandedTicketDescriptions: Set<String> = []
    private var ticketLinks: [EventTicketLink] = []
    private var disabledTicketIds: Set<String> = []
    private var shouldClearInlineRSVPSelectionOnReturn = false
    private var isInlineRSVPStockCheckInProgress = false

    private var attendees: [Attendee] = []
    private var totalAttendees = 0
    private var totalTicketSold: Int?
    private var attendeeLeadName = "Someone"
    private var attendeesHasMore = false
    private var isFetchingMoreAttendees = false
    private var isGuestListLoading = false
    private let attendeesPageSize = 10
    private var skeletonView: SkeletonOverlayView?
    private var isLoading = false
    private var faqs: [EventFAQ] = []
    private var expandedFAQIndex: Int?
    private var autoScrollTimer: Timer?
    private var hasReleasedHeavyResources = false
    private var isBackNavigationInProgress = false
    private var isEventDetailAPICalled = false
    private var isSaved: Bool = false
    private var isSaveLoading: Bool = false
    private var shouldRefreshEventDetailOnReturn = false
    private var hasLoadedSeatingAreas = false
    private var didLoadSeatingAreasSuccessfully = false
    private var savedEventId: String?
    private var representedMainImageURLString: String?
    private var isLoadingMainImage = false
    private let posterHeaderView = EventPosterHeaderView()
    private let collapseThreshold: CGFloat = 20
    private let navInitialTopSpacing: CGFloat = 16
    private var isCollapsed = false
    private var galleryImageURLs: [String] = []
    private var galleryImageViews: [UIImageView] = []
    private var galleryOverlayView: UIView?
    private var galleryMoreLabel: UILabel?
    private var leftEdgeBackGesture: UIScreenEdgePanGestureRecognizer?
    
    private var eventService = EventService()
    private var paymentService = PaymentService()
    private var tableService = TableService()
    
//    private let skeletonView = EventDetailsSkeletonView()

    private var totalSelectedTickets: Int {
        let normalTotal = normalTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        let groupedTotal = groupedNormalTickets
            .flatMap { $0.tickets }
            .reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        return normalTotal + groupedTotal
    }
    
    private var allSelectedTickets: [EventTicket] {

        let normalSelected = normalTickets.filter {
            ($0.selectedTicketCount ?? 0) > 0
        }

        let groupedSelected = groupedNormalTickets
            .flatMap { $0.tickets }
            .filter { ($0.selectedTicketCount ?? 0) > 0 }

        return normalSelected + groupedSelected
    }

    private var visibleLineupItemCount: Int {
        guard !artists.isEmpty else { return 0 }

        let visibleArtistCount = min(artists.count, maxVisibleLineupArtists)
        return artists.count > maxVisibleLineupArtists
        ? visibleArtistCount + 1
        : visibleArtistCount
    }

    private var checkoutSubtotal: Double {

        allSelectedTickets.reduce(0) {
            $0 + (Double($1.selectedTicketCount ?? 0) * ($1.price ?? 0))
        }
    }

    private var checkoutFees: Double {

        allSelectedTickets.reduce(0) {
            $0 + (($1.extraFees ?? 0) * Double($1.selectedTicketCount ?? 0))
        }
    }
    
    private var seatingAreas: [SeatingArea] = []
    private var seatingAreasFilteredOut: [SeatingArea] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPosterHeaderView()
        let imageURLString = (event?.flyer?.key ?? "").imageURL

        loadMainImageIfNeeded(from: imageURLString)
        reloadPosterBackground()
        setupMainImageStyle()
        scrollView.contentInsetAdjustmentBehavior = .never

        scrollView.delegate = self
//        fetchSeatingAreas()
        getEventDetail()
        
        setupEventHeaderData()
        setupCollectionViews()
        setupTableView()
        startTicketTableObserver()
        startGroupTableObserver()
        startFAQsTableObserver()
        startAdditionalButtonsTableObserver()
        setupUI()
        setupUnlockButton()
        setupSkeletonView()
        setupTitleMarqueeLabel()
        setupYouTubeShimmerView()
        setupEventDetailsTypography()
        observeCanceledTransactionReturn()
        enableInteractiveSwipeBack()
        setupLeftEdgeBackGestureIfNeeded()
        showSkeleton()
        
        additionalButtonsTableView.delegate = self
        additionalButtonsTableView.dataSource = self

        additionalButtonsTableView.register(
            AdditionalButtonsTableViewCell.nib,
            forCellReuseIdentifier: AdditionalButtonsTableViewCell.identifier
        )

        additionalButtonsTableView.isScrollEnabled = false
        
        checkOutBtnView.delegate = self
        checkOutBtnView.setButtonTitle("Continue to Checkout")
        applyWhiteLabelTheme()
        configureCheckoutBarInitialState()
        registerSocketDelegate()
        updateCheckoutSummaryView()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isBackNavigationInProgress = false
        leftEdgeBackGesture?.isEnabled = true
        startAutoScrollIfNeeded()
        enableInteractiveSwipeBack()
        setupLeftEdgeBackGestureIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        updateNavPosition(for: scrollView.contentOffset.y)
        updateVenueLogoCornerRadius()

        clearInlineRSVPSelectionIfNeeded()
        refreshEventDetailOnReturnIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let collectionWidth = lineUpCollectionView.bounds.width
        if collectionWidth > 0,
           abs(collectionWidth - lastLineupCollectionWidth) > 0.5 {
            lastLineupCollectionWidth = collectionWidth
            lineUpCollectionView.collectionViewLayout.invalidateLayout()
        }

        updateExpandableTextForWidthChangesIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        view.layoutIfNeeded()
        stopAutoScroll()

        if isLeavingScreenPermanently {
            releaseHeavyResources()
        }
    }
    
    deinit {
        releaseHeavyResources()
        unregisterSocketDelegate()
        ticketTableObserver?.invalidate()
        groupTableObserver?.invalidate()
        faqsTableObserver?.invalidate()
        additionalButtonsTableObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)

        if isViewLoaded {
            scrollView.delegate = nil
            guestListCollectionView.delegate = nil
            guestListCollectionView.dataSource = nil
            lineUpCollectionView.delegate = nil
            lineUpCollectionView.dataSource = nil
            faqsTableView.delegate = nil
            faqsTableView.dataSource = nil
            ticketTableView.delegate = nil
            ticketTableView.dataSource = nil
            groupTableView.delegate = nil
            groupTableView.dataSource = nil
            additionalButtonsTableView.delegate = nil
            additionalButtonsTableView.dataSource = nil
            checkOutBtnView.delegate = nil
        }
    }

    private var isLeavingScreenPermanently: Bool {
        if transitionCoordinator?.isCancelled == true {
            return false
        }

        if isBeingDismissed ||
            navigationController?.isBeingDismissed == true ||
            parent?.isBeingDismissed == true ||
            presentingViewController?.isBeingDismissed == true {
            return true
        }

        guard let navigationController else {
            return false
        }

        return !isSelfOrAncestorInNavigationStack(navigationController)
    }

    private func isSelfOrAncestorInNavigationStack(
        _ navigationController: UINavigationController
    ) -> Bool {
        var viewController: UIViewController? = self

        while let currentViewController = viewController {
            if navigationController.viewControllers.contains(where: { $0 === currentViewController }) {
                return true
            }

            viewController = currentViewController.parent
        }

        return false
    }

    private func releaseHeavyResources() {
        guard isViewLoaded, !hasReleasedHeavyResources else { return }
        hasReleasedHeavyResources = true
        unregisterSocketDelegate()
        stopAutoScroll()
        eventDetailsSkeletonView.releaseResources()
        youTubeShimmerView.stopShimmer()
        youTubeShimmerView.layer.removeAllAnimations()
        tearDownYouTubePlayer()
        tearDownGoogleMapView()
        tearDownImagePager()
        posterHeaderView.cancelImageLoad()
        cancelImageLoads()
        imageListView.subviews.forEach { $0.removeFromSuperview() }
        galleryImageURLs.removeAll()
        galleryImageViews.removeAll()
        galleryOverlayView?.removeFromSuperview()
        galleryOverlayView = nil
        galleryMoreLabel = nil
        detachDelegatesAndTargets()
        clearEventDetailState()
        SDImageCache.shared.clearMemory()
    }

    private func cancelImageLoads() {
        representedMainImageURLString = nil
        isLoadingMainImage = false
        mainImg.sd_cancelCurrentImageLoad()
        mainImg.image = nil
        venueLogo.sd_cancelCurrentImageLoad()
        venueLogo.image = nil
        venueLogoImg.sd_cancelCurrentImageLoad()
        venueLogoImg.image = nil
        cancelImageLoads(in: imageListView)
    }

    private func cancelImageLoads(in view: UIView) {
        if let imageView = view as? UIImageView {
            imageView.sd_cancelCurrentImageLoad()
            imageView.image = nil
        }

        view.subviews.forEach { cancelImageLoads(in: $0) }
    }

    private func loadMainImageIfNeeded(from imageURLString: String) {
        let normalizedURLString = imageURLString.trimmingCharacters(in: .whitespacesAndNewlines)

        if representedMainImageURLString == normalizedURLString,
           isLoadingMainImage || mainImg.image != nil {
            return
        }

        mainImg.sd_cancelCurrentImageLoad()
        representedMainImageURLString = normalizedURLString

        guard !normalizedURLString.isEmpty, let url = URL(string: normalizedURLString) else {
            isLoadingMainImage = false
            mainImg.image = Constant.Icon.uploadImage
            return
        }

        isLoadingMainImage = true
        let requestedURLString = normalizedURLString
        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: max(mainImg.bounds.width, UIScreen.main.bounds.width) * scale,
            height: max(mainImg.bounds.height, 260) * scale
        )

        mainImg.sd_setImage(
            with: url,
            placeholderImage: mainImg.image ?? Constant.Icon.uploadImage,
            options: [
                .continueInBackground,
                .scaleDownLargeImages
            ],
            context: [
                .imageThumbnailPixelSize: NSValue(cgSize: targetSize)
            ],
            progress: nil,
            completed: { [weak self] image, _, _, _ in
                guard let self,
                      self.representedMainImageURLString == requestedURLString else {
                    return
                }

                self.isLoadingMainImage = false

                if image == nil {
                    self.representedMainImageURLString = nil
                }
            }
        )
    }

    private func tearDownImagePager() {
        guard let imagePagerVC else { return }

        imagePagerVC.releaseResources()
        imagePagerVC.willMove(toParent: nil)
        imagePagerVC.view.removeFromSuperview()
        imagePagerVC.removeFromParent()
        self.imagePagerVC = nil
    }

    private func tearDownYouTubePlayer() {
        guard let playerView else { return }

        playerView.stopVideo()
        playerView.delegate = nil
        playerView.removeFromSuperview()
        self.playerView = nil
        isYouTubePlayerReady = false
    }

    private func tearDownGoogleMapView() {
        guard let googleMapView else { return }

        googleMapView.delegate = nil
        googleMapView.clear()
        googleMapView.removeFromSuperview()
        self.googleMapView = nil
    }

    private func detachDelegatesAndTargets() {
        scrollView.delegate = nil
        guestListCollectionView.delegate = nil
        guestListCollectionView.dataSource = nil
        lineUpCollectionView.delegate = nil
        lineUpCollectionView.dataSource = nil
        faqsTableView.delegate = nil
        faqsTableView.dataSource = nil
        ticketTableView.delegate = nil
        ticketTableView.dataSource = nil
        groupTableView.delegate = nil
        groupTableView.dataSource = nil
        additionalButtonsTableView.delegate = nil
        additionalButtonsTableView.dataSource = nil
        checkOutBtnView.delegate = nil

        if navigationController?.interactivePopGestureRecognizer?.delegate === self {
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }

        detachLeftEdgeBackGesture()
        unLockTF.removeTarget(
            self,
            action: #selector(unLockPasswordDidChange),
            for: .editingChanged
        )

        unLockBtn.gestureRecognizers?.forEach {
            unLockBtn.removeGestureRecognizer($0)
        }

        [
            instaImageView,
            tikTokImageView,
            faceBookImageView,
            xImageView,
            youTubeImageView,
            websiteImageView
        ].forEach { imageView in
            imageView?.gestureRecognizers?.forEach {
                imageView?.removeGestureRecognizer($0)
            }
        }
    }

    private func detachLeftEdgeBackGesture() {
        guard let leftEdgeBackGesture else { return }

        leftEdgeBackGesture.isEnabled = false
        leftEdgeBackGesture.delegate = nil
        leftEdgeBackGesture.removeTarget(
            self,
            action: #selector(handleLeftEdgeBackGesture(_:))
        )
        leftEdgeBackGesture.view?.removeGestureRecognizer(leftEdgeBackGesture)
        self.leftEdgeBackGesture = nil
    }

    private func clearEventDetailState() {
        onSaveStateChanged = nil
        event = nil
        venueDetails = nil
        eventTicketId.removeAll()
        artists.removeAll()
        tickets.removeAll()
        normalTickets.removeAll()
        groupedNormalTickets.removeAll()
        expandedGroupIds.removeAll()
        expandedTicketDescriptions.removeAll()
        ticketLinks.removeAll()
        disabledTicketIds.removeAll()
        attendees.removeAll()
        totalAttendees = 0
        totalTicketSold = nil
        attendeesHasMore = false
        faqs.removeAll()
        expandedFAQIndex = nil
        seatingAreas.removeAll()
        seatingAreasFilteredOut.removeAll()
        galleryImageURLs.removeAll()
        galleryImageViews.removeAll()
        savedEventId = nil
    }

    private func startFAQsTableObserver() {
        faqsTableObserver?.invalidate()

        faqsTableObserver = faqsTableView.observe(\.contentSize, options: [.new]) { [weak self] tableView, _ in
            guard let self = self else { return }
            self.faqsTableViewHeight.constant = tableView.contentSize.height
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupPosterHeaderView() {
        posterHeaderView.applyBackgroundStyle(.softColorWash)
        imageBackGroundView.backgroundColor = UIColor(hex: "#121212")
        imageBackGroundView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: imageBackGroundView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: imageBackGroundView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: imageBackGroundView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: imageBackGroundView.bottomAnchor)
        ])
    }

    private var whiteLabelAccentColor: UIColor {
        UIColor(hex: Event.normalizedHexColor(event?.whiteLabelColor))
    }

    private var eventBackgroundImageURLString: String {
        let key = [
            event?.flyer?.key,
            venueDetails?.venueAttachment?.first?.key,
            event?.venue?.venueAttachment?.first?.key,
            venueDetails?.logo?.key,
            event?.venue?.logo?.key
        ]
            .compactMap {
                $0?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .first { !$0.isEmpty } ?? ""

        return key.imageURL
    }

    private func reloadPosterBackground() {
        posterHeaderView.loadImage(from: eventBackgroundImageURLString)
    }

    private func applyWhiteLabelTheme() {
        let color = whiteLabelAccentColor
        let textColor = color.suitableTextColor()

        timingLbl.textColor = color
        webSiteView.borderColor = color
        checkOutBtn.backgroundColor = color
        checkOutBtn.bgColor = color
        checkOutBtn.setTitleColor(textColor, for: .normal)
        checkOutBtn.indicator = MaterialLoadingIndicator(color: textColor)
        checkOutBtnView.applyAccentColor(color)
    }

    private func startTicketTableObserver() {
        ticketTableObserver?.invalidate()

        ticketTableObserver = ticketTableView.observe(\.contentSize, options: [.new]) { [weak self] tableView, _ in
            guard let self = self else { return }
            self.ticketTableHeightConstraint.constant =
            tableView.isHidden ? 0 : tableView.contentSize.height
            self.view.layoutIfNeeded()
        }
    }

    private func startGroupTableObserver() {
        groupTableObserver?.invalidate()

        groupTableObserver = groupTableView.observe(\.contentSize, options: [.new]) { [weak self] tableView, _ in
            guard let self = self else { return }
            self.groupTableViewHeight.constant =
            tableView.isHidden ? 0 : tableView.contentSize.height
            self.view.layoutIfNeeded()
        }
    }

    private func setupUnlockButton() {
        unLockTF.addTarget(self, action: #selector(unLockPasswordDidChange), for: .editingChanged)

        if let button = unLockBtn as? UIButton {
            button.addTarget(self, action: #selector(onClickUnLockBtn(_:)), for: .touchUpInside)
        } else {
            let tap = UITapGestureRecognizer(target: self, action: #selector(onClickUnLockBtn(_:)))
            unLockBtn.addGestureRecognizer(tap)
        }

        updateUnlockButtonState()
    }

    private var unlockCode: String {
        (unLockTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @objc private func unLockPasswordDidChange() {
        updateUnlockButtonState()
    }

    private func updateUnlockButtonState() {
        let isEnabled = !unlockCode.isEmpty
        unLockBtn.alpha = isEnabled ? 1 : 0.5
        unLockBtn.isUserInteractionEnabled = isEnabled
        lockIcon.alpha = isEnabled ? 1 : 0.65

        lockIcon.image = UIImage(named: isEnabled ? "unLockIcon" : "lockIcon")
        lockIcon.tintColor = nil
    }
    
    private func startAdditionalButtonsTableObserver() {

        additionalButtonsTableObserver?.invalidate()

        additionalButtonsTableObserver = additionalButtonsTableView.observe(
            \.contentSize,
             options: [.new]
        ) { [weak self] tableView, _ in

            guard let self = self else { return }

            self.additionalButtonsTableHeight.constant =
            tableView.isHidden ? 0 : tableView.contentSize.height
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupSkeletonView() {
        viewSkeleton.isHidden = true
//        viewSkeleton.backgroundColor = UIColor(hex: "#111111")

        eventDetailsSkeletonView.translatesAutoresizingMaskIntoConstraints = false
        viewSkeleton.addSubview(eventDetailsSkeletonView)

        NSLayoutConstraint.activate([
            eventDetailsSkeletonView.topAnchor.constraint(equalTo: viewSkeleton.topAnchor),
            eventDetailsSkeletonView.leadingAnchor.constraint(equalTo: viewSkeleton.leadingAnchor),
            eventDetailsSkeletonView.trailingAnchor.constraint(equalTo: viewSkeleton.trailingAnchor),
            eventDetailsSkeletonView.bottomAnchor.constraint(equalTo: viewSkeleton.bottomAnchor)
        ])
    }
    
    private func showSkeleton() {
        view.layoutIfNeeded()
        viewSkeleton.isHidden = false
        contentStackView.isHidden = true
        eventDetailsSkeletonView.startShimmer()
        scrollView.isScrollEnabled = false
    }
    
    private func hideSkeleton() {
        eventDetailsSkeletonView.stopShimmer()
        viewSkeleton.isHidden = true
        contentStackView.isHidden = false
        scrollView.isScrollEnabled = true
    }

    private func setupTicketTable() {
        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        ticketTableView.register(TicketsTVC.nib, forCellReuseIdentifier: TicketsTVC.identifier)
        ticketTableView.isScrollEnabled = false
    }
    
    private func setupUI() {
        savedEventId = event?.savedEventId
        isSaved =
        event?.hasSavedEvent == true ||
        savedEventId != nil
        updateSaveUI()
        setupVenueInfoPanel()
    }

    private func setupVenueInfoPanel() {
        venueFooterBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        venueFooterBackgroundView.layer.cornerRadius = 20
        venueFooterBackgroundView.clipsToBounds = true
    }
    
    private func updateSaveUI() {
        let imageName = isSaved ? "savedIcon" : "unSavedIcon"
        
        saveBtn.setImage(UIImage(named: imageName), for: .normal)
        saveBtn.tintColor =  .white
        saveBtn.alpha = isSaveLoading ? 0.65 : 1
        saveBtn.isUserInteractionEnabled = !isSaveLoading
    }

    private func setupEventDetailsTypography() {
        titleLbl.font = Constant.Font.geistMedium(size: 20)
        eventTitleMarqueeLabel.font = Constant.Font.geistMedium(size: 18)
        venueTitleLbl.font = Constant.Font.geistMedium(size: 12)
        venueTitleLbl.isUserInteractionEnabled = true
        venueTitleLbl.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(onClickVenueTitle(_:))
            )
        )
        venueName.font = Constant.Font.geistMedium(size: 14)
        venueName.textAlignment = .center
        venueNameLbl.font = Constant.Font.geistMedium(size: 18)
        updateVenueLogoCornerRadius()
    }

    private func updateVenueLogoCornerRadius() {
        venueLogoImg.layer.cornerRadius = min(
            venueLogoImg.bounds.width,
            venueLogoImg.bounds.height
        ) / 2
        venueLogoImg.clipsToBounds = true
    }

    private func enableInteractiveSwipeBack() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    private func setupLeftEdgeBackGestureIfNeeded() {
        guard isPresentedAsRootNavigationScreen,
              leftEdgeBackGesture?.view == nil
        else {
            return
        }

        let gesture = leftEdgeBackGesture ?? UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleLeftEdgeBackGesture(_:))
        )
        gesture.edges = .left
        gesture.delegate = self
        gesture.isEnabled = true
        leftEdgeBackGesture = gesture

        view.addGestureRecognizer(gesture)
    }

    private var isPresentedAsRootNavigationScreen: Bool {
        guard let navigationController else { return false }
        return navigationController.viewControllers.first === self &&
            navigationController.presentingViewController != nil
    }

    private func handleBackNavigation() {
        guard !isBackNavigationInProgress,
              !hasReleasedHeavyResources else {
            return
        }

        isBackNavigationInProgress = true
        leftEdgeBackGesture?.isEnabled = false

        Navigate.to.back(self)
    }

    @objc private func handleLeftEdgeBackGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard gesture.state == .ended else { return }

        let translationX = gesture.translation(in: view).x
        let velocityX = gesture.velocity(in: view).x

        guard translationX > 70 || velocityX > 450 else { return }

        handleBackNavigation()
    }

    private func setupTitleMarqueeLabel() {
        pageTitleName.font = Constant.Font.geistMedium(size: 18)
        pageTitleName.textColor = AppColor.primaryWhiteColor
        eventTitleMarqueeLabel.install(over: pageTitleName, height: 30)
        eventTitleMarqueeLabel.animationDelay = 1.4
    }

    private func setupYouTubeShimmerView() {
        guard youTubeShimmerView.superview == nil else { return }

        youTubeShimmerView.translatesAutoresizingMaskIntoConstraints = false
        youTubeShimmerView.layer.cornerRadius = 12
        youTubeShimmerView.isHidden = true
        youTubePlayerView.addSubview(youTubeShimmerView)

        NSLayoutConstraint.activate([
            youTubeShimmerView.topAnchor.constraint(equalTo: youTubePlayerView.topAnchor),
            youTubeShimmerView.leadingAnchor.constraint(equalTo: youTubePlayerView.leadingAnchor),
            youTubeShimmerView.trailingAnchor.constraint(equalTo: youTubePlayerView.trailingAnchor),
            youTubeShimmerView.bottomAnchor.constraint(equalTo: youTubePlayerView.bottomAnchor)
        ])
    }

    private func showYouTubeShimmer() {
        isYouTubePlayerReady = false
        youTubeShimmerView.isHidden = false
        youTubeShimmerView.alpha = 1
        youTubeShimmerView.startShimmer()
        youTubePlayerView.bringSubviewToFront(youTubeShimmerView)
    }

    private func hideYouTubeShimmer() {
        guard !youTubeShimmerView.isHidden else { return }

        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            self.youTubeShimmerView.alpha = 0
        } completion: { _ in
            self.youTubeShimmerView.stopShimmer()
            self.youTubeShimmerView.layer.removeAllAnimations()
            self.youTubeShimmerView.isHidden = true
            self.youTubeShimmerView.alpha = 1
        }
    }

    private func setSection(
        _ sectionView: UIView,
        hidden: Bool,
        animated: Bool = true
    ) {
        if sectionView.isHidden == hidden {
            sectionView.alpha = hidden ? 0 : 1
            return
        }

        let shouldAnimate =
        animated &&
        view.window != nil &&
        !contentStackView.isHidden

        guard shouldAnimate else {
            sectionView.alpha = hidden ? 0 : 1
            sectionView.isHidden = hidden
            return
        }

        view.layoutIfNeeded()

        if !hidden {
            sectionView.alpha = 0
            sectionView.isHidden = false
        }

        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            sectionView.alpha = hidden ? 0 : 1
            self.view.layoutIfNeeded()
        } completion: { _ in
            sectionView.isHidden = hidden
            sectionView.alpha = hidden ? 0 : 1
            self.contentStackView.layoutIfNeeded()
        }
    }

    private func setVIPTablesView(
        hidden: Bool,
        animated: Bool = true
    ) {
        let leadingOffset: CGFloat =
        UIView.userInterfaceLayoutDirection(
            for: vipTablesView.semanticContentAttribute
        ) == .rightToLeft ? 50 : -50

        if vipTablesView.isHidden == hidden {
            vipTablesView.alpha = hidden ? 0 : 1
            vipTablesView.transform = .identity
            return
        }

        let shouldAnimate =
        animated &&
        view.window != nil &&
        !contentStackView.isHidden

        guard shouldAnimate else {
            vipTablesView.alpha = hidden ? 0 : 1
            vipTablesView.transform = .identity
            vipTablesView.isHidden = hidden
            return
        }

        view.layoutIfNeeded()

        if !hidden {
            vipTablesView.alpha = 0
            vipTablesView.transform =
            CGAffineTransform(translationX: leadingOffset, y: 0)
            vipTablesView.isHidden = false
            contentStackView.layoutIfNeeded()
        }

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.vipTablesView.alpha = hidden ? 0 : 1
            self.vipTablesView.transform =
            hidden ? CGAffineTransform(translationX: leadingOffset, y: 0) : .identity
        } completion: { _ in
            self.vipTablesView.isHidden = hidden
            self.vipTablesView.alpha = hidden ? 0 : 1
            self.vipTablesView.transform = .identity
            self.contentStackView.layoutIfNeeded()
        }
    }

    private func setTicketListView(hidden: Bool) {
        ticketHidenView.layer.removeAllAnimations()
        ticketHidenView.alpha = hidden ? 0 : 1
        ticketHidenView.transform = .identity
        ticketHidenView.isHidden = hidden
        contentStackView.layoutIfNeeded()
    }

    
    
    private func setupMainImageStyle() {
        imageShadowView.clipsToBounds = false
        imageShadowView.layer.masksToBounds = false
        imageShadowView.layer.cornerRadius = 8

        imageShadowView.layer.shadowColor = UIColor.white.cgColor
        imageShadowView.layer.shadowOpacity = 0.35
        imageShadowView.layer.shadowRadius = 18
        imageShadowView.layer.shadowOffset = CGSize(width: 0, height: 12)

        mainImg.clipsToBounds = true
        mainImg.layer.masksToBounds = true
        mainImg.layer.cornerRadius = 8
        mainImg.contentMode = .scaleAspectFill
    }
    
    
    func updateLineUpView() {
        let shouldHide = artists.isEmpty
        lineUpCollectionView.collectionViewLayout.invalidateLayout()
        lineUpCollectionView.reloadData()
        
        if shouldHide {
            UIView.animate(withDuration: 0.3, animations: {
                self.lineUpHiddenView.alpha = 0
                self.lineUpHiddenView.transform = CGAffineTransform(translationX: 0, y: -10)
            }) { _ in
                self.lineUpHiddenView.isHidden = true
            }
        } else {
            self.lineUpHiddenView.isHidden = false
            self.lineUpHiddenView.alpha = 0
            self.lineUpHiddenView.transform = CGAffineTransform(translationX: 0, y: -10)

            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                self.lineUpHiddenView.alpha = 1
                self.lineUpHiddenView.transform = .identity
            }, completion: nil)
        }
    }
    
    func updateAttendeesView(animated: Bool = true) {
        let shouldHide = attendees.isEmpty && !isGuestListLoading
        
        if shouldHide {
            guard !attendeesView.isHidden else { return }
            
            UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
                self.attendeesView.alpha = 0
                self.attendeesView.transform = CGAffineTransform(translationX: 0, y: -10)
            }) { _ in
                self.attendeesView.isHidden = true
            }
            
        } else {
            guard attendeesView.isHidden else { return }
            
            attendeesView.isHidden = false
            attendeesView.alpha = 0
            attendeesView.transform = CGAffineTransform(translationX: 0, y: -10)
            
            UIView.animate(withDuration: animated ? 0.3 : 0.0,
                           delay: 0,
                           options: [.curveEaseOut],
                           animations: {
                self.attendeesView.alpha = 1
                self.attendeesView.transform = .identity
            })
        }
    }

    private func getEventDetail(showLoading: Bool = true) {
        guard !isEventDetailAPICalled else { return }

        guard let eventId = self.event?.uniqueId ?? self.uniqueId else {
            isEventDetailAPICalled = false
            return
        }

        if showLoading {
            showSkeleton()
        }

        eventService.fetchV3EventDetail(
            eventId: eventId,
            venueTimeZone: TimeZone.current.identifier,
            promotionLinkId: promoteId,
            promotionLinkUniqueCode: promotionLinkUniqueCode,
            micrositeSlug: micrositeSlug
        ) { [weak self] _, _, detail, errCode in

            guard let self = self else { return }

            self.view.alpha = 1
            self.isEventDetailAPICalled = true

            guard let detail else {
                if errCode == 404 && (self.promoteId != "" || self.promotionLinkUniqueCode != "") {
                    self.promoteId = ""
                    self.promotionLinkUniqueCode = ""
                    self.isEventDetailAPICalled = false
                    self.getEventDetail()
                    return
                }

                self.hideSkeleton()
                return
            }

            self.applyEventDetailBundle(detail)
            if let show = self.event?.showEventAttendees {
                self.attendeesView.isHidden = !show
                if show, self.attendees.isEmpty {
                    self.getEventAttendees()
                }
            } else {
                self.attendeesView.isHidden = true
            }
        }

        /*
        Old detail API flow is kept here for reference while the new
        /consumer/event/{uniqueId} response owns all detail data.

        eventService.fetchEventDetail(
            eventId: eventId,
            venueTimeZone: venueDetails?.useTimezone,
            promotionLinkId: promoteId
        ) { [weak self] _, _, eventDetail, errCode in

            guard let self = self else { return }

            self.view.alpha = 1
            self.isEventDetailAPICalled = true

            if eventDetail == nil {
                if errCode == 404 && self.promoteId != "" {
                    self.promoteId = ""
                    self.getEventDetail()
                }
                return
            }

            self.event = eventDetail

            if let venue = eventDetail?.venue {
                self.venueDetails = venue
                WebSocketWrapper.shared.updateSocketContext(venueId: venue.id)
            }

            self.eventTicketId.removeAll()
            let ticket = self.event?.eventTicket ?? []
            ticket.forEach { tic in
                self.eventTicketId.append(tic.id ?? "")
            }

            self.lineUpCollectionView.reloadData()

            if let show = self.event?.showEventAttendees {
                self.attendeesView.isHidden = !show
                if show {
                    self.getEventAttendees()
                }
            } else {
                self.attendeesView.isHidden = true
            }

            self.artists = self.event?.eventHasArtist?.filter({ $0.artist.status == "ENABLED" }) ?? []

            self.updateLineUpView()
            self.getEventFAQs()
            self.getTicketLinksAndRefresh()
        }
        */
    }

    private func applyEventDetailBundle(
        _ detail: EventDetailBundle
    ) {

        let currentSavedEventId =
        savedEventId ?? event?.savedEventId

        let currentIsSaved =
        isSaved || event?.hasSavedEvent == true

        let detailHasSavedState =
        detail.event.hasSavedEvent != nil ||
        detail.event.savedEventId != nil

        event = detail.event
        applyVenueWhiteLabelColorIfNeeded(from: detail.event.venue)

        if !detailHasSavedState,
           let currentSavedEventId {
            event?.savedEventId = currentSavedEventId
        }

        if !detailHasSavedState,
           currentIsSaved {
            event?.hasSavedEvent = true
        }

        if let venue = detail.event.venue {
            venueDetails = venue
            WebSocketWrapper.shared.updateSocketContext(venueId: venue.id)
        }

        savedEventId = event?.savedEventId
        isSaved =
        event?.hasSavedEvent == true ||
        savedEventId != nil
        updateSaveUI()
        setupTicketsButton()

        eventTicketId =
        detail.event.eventTicket?
            .compactMap { $0.id } ?? []

        if let seatingAreas = detail.seatingAreas {
            applySeatingAreas(seatingAreas)
        }

        ticketLinks = detail.ticketLinks

        faqs = detail.faqs
        expandedFAQIndex = nil
        faqsView.isHidden = faqs.isEmpty
        faqsTableView.reloadData()
        faqsTableView.layoutIfNeeded()
        faqsTableViewHeight.constant =
        faqsTableView.contentSize.height

        artists =
        event?.eventHasArtist?
            .filter { $0.artist.status == "ENABLED" } ?? []

        lineUpCollectionView.reloadData()
        updateLineUpView()

        applyAttendees(
            detail.attendees,
            total: detail.totalAttendees,
            totalTicketSold: detail.totalTicketSold ?? detail.event.totalTicketSold
        )

        setupData()
        hideSkeleton()
        showContinueBtn()
        loadInitialSeatingAreas()
    }

    private func applyVenueWhiteLabelColorIfNeeded(from venue: ClipVenue?) {
        guard Event.normalizedHexColor(event?.whiteLabelColor, fallback: "").isEmpty else { return }

//        let venueColor = Event.normalizedHexColor(venue?.venueSettings?.whiteLabelColor, fallback: "")
//        guard !venueColor.isEmpty else { return }
//
//        event?.whiteLabelColor = venueColor
    }

    private func applyAttendees(
        _ list: [Attendee]?,
        total: Int? = nil,
        totalTicketSold: Int? = nil
    ) {
        isGuestListLoading = false

        guard event?.showEventAttendees == true,
              let list
        else {

            attendees = []
            totalAttendees = 0
            self.totalTicketSold = totalTicketSold
            attendeeLeadName = "Someone"
            attendeesHasMore = false
            guestListTitleLbl.text = ""
            guestListCollectionView.reloadData()
            updateAttendeesView()
            return
        }

        attendeeLeadName = displayNameForAttendee(list.first)
        attendees = sortAttendeesImageFirst(list)

        totalAttendees = max(total ?? attendees.count, attendees.count)
        self.totalTicketSold = totalTicketSold ?? self.totalTicketSold
        attendeesHasMore = totalAttendees > attendees.count
        guestListCollectionView.reloadData()
        updateAttendeesView()
        updateGuestListTitle()
    }

    private func setGuestListLoading(_ loading: Bool) {
        guard isGuestListLoading != loading else { return }

        isGuestListLoading = loading

        if loading {
            guestListTitleLbl.text = "Guest list"
            attendeesView.isHidden = false
            attendeesView.alpha = 1
            attendeesView.transform = .identity
        } else if attendees.isEmpty {
            guestListTitleLbl.text = ""
        }

        guestListCollectionView.reloadData()
        updateAttendeesView(animated: !loading)
    }

    private func updateGuestListTitle() {
        guard !attendees.isEmpty else {
            guestListTitleLbl.text = ""
            return
        }

        let count = max(totalTicketSold ?? totalAttendees, attendees.count)

        if count == 1 {
            guestListTitleLbl.text = "\(attendeeLeadName) is going"
        } else if count == 2 {
            guestListTitleLbl.text = "\(attendeeLeadName) and 1 other going"
        } else if count < 10 {
            guestListTitleLbl.text = "\(attendeeLeadName) and \(count - 1) others going"
        } else {
            guestListTitleLbl.text = "\(attendeeLeadName) +\(count - 1) going"
        }
    }
    
    private func updateCheckoutSummaryView() {

        let selectedNormalTickets =
        normalTickets.filter {
            ($0.selectedTicketCount ?? 0) > 0
        }

        let selectedGroupedTickets =
        groupedNormalTickets
            .flatMap { $0.tickets }
            .filter {
                ($0.selectedTicketCount ?? 0) > 0
            }

        let selectedTickets =
        selectedNormalTickets + selectedGroupedTickets

        let totalCount =
        selectedTickets.reduce(0) {
            $0 + ($1.selectedTicketCount ?? 0)
        }

        guard totalCount > 0 else {

            hideCheckoutBar()
            return
        }

        let subtotal =
        selectedTickets.reduce(0.0) {

            $0 +
            (
                Double($1.selectedTicketCount ?? 0)
                *
                ($1.price ?? 0)
            )
        }

        let fees =
        selectedTickets.reduce(0.0) {

            $0 +
            (
                ($1.extraFees ?? 0)
                *
                Double($1.selectedTicketCount ?? 0)
            )
        }

        let currency =
        venueDetails?.venueSettings?.currencySymbol ?? "$"
        let currencyPosition =
        venueDetails?.venueSettings?.currencyPosition
        checkOutBtnView.updateSummary(
            currency: currency,
            currencyPosition: currencyPosition,
            count: totalCount,
            subtotal: subtotal ,
            fees: fees
        )

        checkOutBtnView.setButtonTitle(
            "Continue to Checkout"
        )

        showCheckoutBar()
    }
    
    private func showContinueBtn() {
        guard !shouldHideBottomTicketButton() else {
            hideBottomTicketButton()
            return
        }

        if event?.eventTicketSettings?.showTicketListingOnMainScreen ?? false {
            buyNowBtnSuperView.isHidden = true
        } else {
            guard buyNowBtnSuperView.isHidden else {
                return
            }

            buyNowBtnSuperView.isHidden = false

            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.6
            ) {

                self.buyNowBtnSuperView.alpha = 1

                self.buyNowBtnSuperView.transform = .identity
            }
        }

    }

    private func shouldHideBottomTicketButton() -> Bool {
        guard !shouldShowDisabledTicketButton else { return false }
        guard let event else { return false }

        if event.isPausedSellingAllTickets == true ||
            event.isSaleEndedAllTickets == true ||
            event.isSoldOutAllTickets == true {
            return true
        }

        return event.eventTicket?.isEmpty != false
    }

    private func hideBottomTicketButton() {
        buyNowBtnSuperView.layer.removeAllAnimations()
        buyNowBtnSuperView.alpha = 0
        buyNowBtnSuperView.transform = CGAffineTransform(
            translationX: 0,
            y: 120
        )
        buyNowBtnSuperView.isHidden = true
        hideCheckoutBarImmediately()
    }

    private func applyDisabledBottomTicketButtonVisibility() {
        if shouldShowDisabledTicketButton {
            showContinueBtn()
        } else {
            hideBottomTicketButton()
        }
    }
    
    private func showCheckoutBar() {

        guard checkOutBtnView.isHidden || checkOutBtnView.alpha < 1 else {
            return
        }

        checkOutBtnView.layer.removeAllAnimations()
        checkOutBtnView.isHidden = false

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.6
        ) {

            self.checkOutBtnView.alpha = 1

            self.checkOutBtnView.transform = .identity
        }
    }

    private func hideCheckoutBar() {

        guard !checkOutBtnView.isHidden else {
            configureCheckoutBarInitialState()
            return
        }

        checkOutBtnView.layer.removeAllAnimations()
        UIView.animate(
            withDuration: 0.25,
            animations: {

                self.checkOutBtnView.alpha = 0

                self.checkOutBtnView.transform =
                CGAffineTransform(
                    translationX: 0,
                    y: 120
                )

            }) { _ in

                self.checkOutBtnView.isHidden = true
            }
    }

    private func configureCheckoutBarInitialState() {
        checkOutBtnView.layer.removeAllAnimations()
        checkOutBtnView.hideLoader()
        checkOutBtnView.alpha = 0
        checkOutBtnView.transform = CGAffineTransform(
            translationX: 0,
            y: 120
        )
        checkOutBtnView.isHidden = true
    }

    private func clearInlineRSVPSelectionIfNeeded() {
        guard shouldClearInlineRSVPSelectionOnReturn else { return }
        shouldClearInlineRSVPSelectionOnReturn = false
        clearInlineTicketSelections()
        hideCheckoutBarImmediately()
    }

    private func observeCanceledTransactionReturn() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCanceledTransactionReturn(_:)),
            name: .eventTransactionDidCancelAndReturnToDetails,
            object: nil
        )
    }

    @objc private func handleCanceledTransactionReturn(
        _ notification: Notification
    ) {
        let returnedEventId =
        notification.userInfo?["eventId"] as? String

        if let returnedEventId,
           !returnedEventId.isEmpty {

            let currentEventIds = [
                event?.uniqueId,
                uniqueId,
                event?.id
            ]
            .compactMap { $0 }

            guard currentEventIds.contains(returnedEventId) else { return }
        }

        shouldRefreshEventDetailOnReturn = true
        shouldClearInlineRSVPSelectionOnReturn = true
    }

    private func refreshEventDetailOnReturnIfNeeded() {
        guard shouldRefreshEventDetailOnReturn else { return }

        shouldRefreshEventDetailOnReturn = false
        isEventDetailAPICalled = false
        hasLoadedSeatingAreas = false
        didLoadSeatingAreasSuccessfully = false
        applySeatingAreas([])
        hideCheckoutBarImmediately()
        setupData()
        getEventDetail(showLoading: false)
    }

    private func clearInlineTicketSelections() {
        normalTickets.indices.forEach {
            normalTickets[$0].selectedTicketCount = nil
        }

        for groupIndex in groupedNormalTickets.indices {
            for ticketIndex in groupedNormalTickets[groupIndex].tickets.indices {
                groupedNormalTickets[groupIndex].tickets[ticketIndex].selectedTicketCount = nil
            }
        }

        if var updatedEvent = event {
            updatedEvent.eventTicket = clearingSelectedCounts(in: updatedEvent.eventTicket)
            updatedEvent.protectedEventTicket = clearingSelectedCounts(in: updatedEvent.protectedEventTicket)
            event = updatedEvent
        }

        tickets = normalTickets
        ticketTableView.reloadData()
        groupTableView.reloadData()
        updateTicketTableHeight()
        updateGroupTableHeight()
        updateContinueBtnState()
        updateCheckoutSummaryView()
    }

    private func hideCheckoutBarImmediately() {
        configureCheckoutBarInitialState()
    }

    private func clearingSelectedCounts(in tickets: [EventTicket]?) -> [EventTicket]? {
        guard var updatedTickets = tickets else { return nil }

        for index in updatedTickets.indices {
            updatedTickets[index].selectedTicketCount = nil
        }

        return updatedTickets
    }
    
    private func applySeatingAreas(
        _ list: [SeatingArea]
    ) {
        let filtered = filterSeatingAreas(list)
        seatingAreas = list
        seatingAreasFilteredOut = filtered.visible
    }

    private func loadInitialSeatingAreas() {
        guard event != nil else { return }

        hasLoadedSeatingAreas = false
        didLoadSeatingAreasSuccessfully = false
        applySeatingAreas([])
        setupData()

        fetchSeatingAreas { [weak self] success, _, list in
            DispatchQueue.main.async {
                guard let self else { return }

                self.hasLoadedSeatingAreas = true
                self.didLoadSeatingAreasSuccessfully = success

                if !success || list.isEmpty {
                    self.applySeatingAreas([])
                }

                self.setupData()
            }
        }
    }

    private func fetchSeatingAreas(
        completion: ((Bool, String?, [SeatingArea]) -> Void)? = nil
    ) {
        guard let event else {
            completion?(false, Constant.String.somethingWrong, [])
            return
        }

        tableService.fetchSeatingAreas(
            eventId: event.id,
            skip: 0
        ) { [weak self] isSuccess, errMsg, list, _ in
            
            guard let self else { return }

            if isSuccess {
                self.applySeatingAreas(list)
                completion?(true, nil, list)
            } else {
                print(errMsg ?? "")
                completion?(false, errMsg, [])
            }
        }
    }

    private func getEventAttendees() {
        guard let eventId = self.event?.uniqueId else {
            return
        }

        guard !isFetchingMoreAttendees else { return }
        isFetchingMoreAttendees = true
        setGuestListLoading(true)

        eventService.fetchEventAttendees(
            eventId: eventId,
            skip: 0,
            take: attendeesPageSize
        ) { [weak self] success, _, data, total, totalTicketSold, hasMore, _ in
            guard let self = self else { return }
            self.isFetchingMoreAttendees = false

            if success {
                self.applyAttendees(
                    data,
                    total: total,
                    totalTicketSold: totalTicketSold
                )
                self.attendeesHasMore = hasMore || self.totalAttendees > self.attendees.count
            } else {
                self.setGuestListLoading(false)
            }
        }
    }

    private func getEventFAQs() {
        guard let eventId = event?.uniqueId else { return }

        eventService.fetchEventFAQs(eventId: eventId) { [weak self] isSuccess, _, faqs, _ in
            guard let self = self else { return }

            if isSuccess {
                self.faqs = faqs ?? []
                self.faqsView.isHidden = self.faqs.isEmpty
                self.faqsTableView.reloadData()
                self.faqsTableView.layoutIfNeeded()
                self.faqsTableViewHeight.constant = self.faqsTableView.contentSize.height
            } else {
                self.faqsView.isHidden = true
            }
        }
    }

    private func getTicketLinksAndRefresh() {
        guard let eventId = event?.uniqueId else {
            setupData()
            hideSkeleton()
            return
        }

        eventService.fetchTicketLinks(eventId: eventId) { [weak self] isSuccess, _, links in
            guard let self = self else { return }

            if isSuccess {
                self.ticketLinks = links ?? []
            } else {
                self.ticketLinks = []
            }

            self.setupData()
            hideSkeleton()
            showContinueBtn()
        }
    }

    private func venueNow() -> Date {
        let tz = venueDetails?.useTimezone ?? TimeZone.current.identifier
        let timeZone = TimeZone(identifier: tz) ?? .current

        let formatter = DateFormatter()
        formatter.dateFormat = DateFormat.yyyyMMddHHmmss.rawValue
        formatter.timeZone = timeZone

        return formatter.date(from: formatter.string(from: Date())) ?? Date()
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
        let now = venueNow()
        guard let startSaleDate = ticketDate(ticket.beginSale) else {
            return true
        }
        return now >= startSaleDate
    }

    private func isTicketSaleNotEnded(_ ticket: EventTicket) -> Bool {
        let now = venueNow()
        guard let endSaleDate = ticketDate(ticket.endSale) else {
            return true
        }
        return now <= endSaleDate
    }

    private func isTicketSaleEnded(_ ticket: EventTicket) -> Bool {
        let now = venueNow()
        guard let endSaleDate = ticketDate(ticket.endSale) else {
            return false
        }
        return now > endSaleDate
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



    private func isTicketDisabledByLink(_ ticket: EventTicket) -> Bool {
        guard let id = ticket.id else { return false }
        return disabledTicketIds.contains(id)
    }

    private func sortAttendeesImageFirst(_ list: [Attendee]) -> [Attendee] {
        let withImage = list.filter { $0.hasImage }
        let withoutImage = list.filter { !$0.hasImage }
        return withImage + withoutImage
    }

    private func displayNameForAttendee(_ attendee: Attendee?) -> String {
        let firstName = attendee?.firstName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !firstName.isEmpty {
            return firstName
        }

        let fullName = attendee?.fullName ?? ""
        return fullName.isEmpty ? "Someone" : fullName
    }
    
    private func setupEventHeaderData() {
        guard let event = event else { return }
        titleLbl.text = event.title
        eventTitleMarqueeLabel.setText(event.title)
        if let imageUrlString = event.venue?.logo?.key.imageURL,
           let url = URL(string: imageUrlString) {
            let scale = UIScreen.main.scale
            let targetSize = CGSize(
                width: max(venueLogo.bounds.width, 72) * scale,
                height: max(venueLogo.bounds.height, 72) * scale
            )

            venueLogo.sd_setImage(
                with: url,
                placeholderImage: nil,
                options: [.continueInBackground, .scaleDownLargeImages],
                context: [.imageThumbnailPixelSize: NSValue(cgSize: targetSize)]
            )
            
        } else {
            venueLogo.isHidden = true
        }
        venueTitleLbl.text = event.displayVenueName.uppercased()
        pageTitleName.text = event.title
        
        applyWhiteLabelTheme()

        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            timingLbl.text = customText
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

            if !dateText.isEmpty && !startTime.isEmpty {
                let hideEnd = event.hideEventEnd == true
                let hasEndTime = !(event.endDateTime?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

                if hideEnd || !hasEndTime {
                    timingLbl.text = "\(dateText) at \(startTime)"
                } else {
                    let endTime = event.endDateTime?.convertDateFormat(
                        from: .yyyyMMddHHmmss,
                        to: .hmma,
                        customTimeZone: timezone
                    ) ?? ""

                    timingLbl.text = "\(dateText) at \(startTime) - \(endTime)"
                }
            } else {
                timingLbl.text = ""
            }
        }
    }
    

    private func setupData() {
        guard let event = event else { return }

        disabledTicketIds.removeAll()

        titleLbl.text = event.title
        let flyerImageURLString = (event.flyer?.key ?? "").imageURL
        loadMainImageIfNeeded(from: flyerImageURLString)
        reloadPosterBackground()
        
        titleLbl.text = event.title
        eventTitleMarqueeLabel.setText(event.title)
        fullText = event.description
        setupExpandableLabel()
        setupPolicyExpandableLabel()
        venueName.text = venueFooterTitle(for: event)
        
        venueNameLbl.text = event.displayVenueNameOrFallback(venueDetails?.name ?? "")
        eventAddressView.isHidden = !(event.showAddress ?? true)
        pageTitleName.text = event.title
        let addressComponents: [String]

        if let custom = event.customVenue,
           venueDetails?.venueSettings?.isOrganizer == true {
            
            addressComponents = [
                custom.address,
                custom.city,
                custom.pinCode
            ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
             .filter { !$0.isEmpty }
            
        } else {
            
            addressComponents = [
                venueDetails?.address,
                venueDetails?.city,
                venueDetails?.pinCode
            ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
             .filter { !$0.isEmpty }
        }

        venueAddressLbl.text = addressComponents.joined(separator: ", ")
        venueTitleLbl.text = venueDetails?.name.uppercased() ?? ""

        let additionalButtons = enabledAdditionalButtons
        additionalButtonsTableView.isHidden = additionalButtons.isEmpty
        additionalButtonsTableView.reloadData()
        additionalButtonsTableHeight.constant = additionalButtons.isEmpty ? 0 : additionalButtonsTableView.contentSize.height
        setSection(webSiteView, hidden: additionalButtons.isEmpty)
        
        configureVIPTablesView()
        setupGalleryGrid()

        let showInlineTickets = event.eventTicketSettings?.showTicketListingOnMainScreen ?? false

        if showInlineTickets {
            setupInlineTicketData()
        } else {
            tickets = []
            normalTickets = []
            groupedNormalTickets = []
            ticketTableView.isHidden = true
            groupTableView.isHidden = true
            ticketTableView.reloadData()
            groupTableView.reloadData()
            ticketTableHeightConstraint.constant = 0
            groupTableViewHeight.constant = 0
            protectedTicketView.isHidden = true
            lockIcon.isHidden = true
            setTicketListView(hidden: true)
        }

        if let youtubeVideoLink = event.youtubeVideoLink, !youtubeVideoLink.isEmpty {
            youTubeSuperView.isHidden = false
            setupYouTubePlayer()
            if let id = extractVideoID(from: youtubeVideoLink) {
                showYouTubeShimmer()
                playerView?.load(
                    withVideoId: id,
                    playerVars: youtubePlayerVars()
                )
            } else {
                hideYouTubeShimmer()
            }
        } else {
            hideYouTubeShimmer()
            tearDownYouTubePlayer()
            youTubeSuperView.isHidden = true
        }

        let logoScale = UIScreen.main.scale
        let compactLogoSize = CGSize(
            width: max(venueLogoImg.bounds.width, 80) * logoScale,
            height: max(venueLogoImg.bounds.height, 80) * logoScale
        )

        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: nil,
            options: [.continueInBackground, .scaleDownLargeImages],
            context: [.imageThumbnailPixelSize: NSValue(cgSize: compactLogoSize)]
        )
        
        if let imageUrlString = venueDetails?.logo?.key.imageURL,
           let url = URL(string: imageUrlString) {

            let shouldAnimate = (venueLogo.image == nil)
            let navLogoSize = CGSize(
                width: max(venueLogo.bounds.width, 72) * logoScale,
                height: max(venueLogo.bounds.height, 72) * logoScale
            )

            venueLogo.sd_setImage(
                with: url,
                placeholderImage: nil,
                options: [.continueInBackground, .scaleDownLargeImages],
                context: [.imageThumbnailPixelSize: NSValue(cgSize: navLogoSize)], progress: nil,
                completed: { [weak self] _, _, _, _ in
                    guard let self = self else { return }

                    if shouldAnimate {
                        self.venueLogo.alpha = 0
                        self.venueLogo.transform = CGAffineTransform(translationX: -50, y: 0)

                        UIView.animate(
                            withDuration: 0.4,
                            delay: 0,
                            options: [.curveEaseOut]
                        ) {
                            self.venueLogo.isHidden = false
                            self.venueLogo.alpha = 1
                            self.venueLogo.transform = .identity
                        }
                    } else {
                        self.venueLogo.isHidden = false
                        self.venueLogo.alpha = 1
                        self.venueLogo.transform = .identity
                    }
                }
            )
        } else {
            venueLogo.isHidden = true
        }
        
        
        let coordinate: CLLocationCoordinate2D?
        let title: String
        let mapImageURL: String?
        let mapSearchQuery: String?

        if let custom = event.customVenue {
//            , venueDetails?.venueSettings?.isOrganizer == true {
            
            coordinate = CLLocationCoordinate2D.valid(
                latitude: Double(custom.lat ?? "") ?? 0,
                longitude: Double(custom.lng ?? "") ?? 0
            )
            
            title = custom.name ?? "Venue"
            mapSearchQuery = addressSearchQuery(
                components: [
                    custom.address,
                    custom.city,
                    custom.pinCode,
                    custom.region,
                    custom.country
                ]
            )
            let mapImageKey = event.flyer?.key ?? ""
            mapImageURL = mapImageKey.isEmpty ? nil : mapImageKey.imageURL
            
        } else {
            
            coordinate = CLLocationCoordinate2D.valid(
                latitude: venueDetails?.latitude ?? 0,
                longitude: venueDetails?.longitude ?? 0
            )
            
            title = venueDetails?.name ?? "Venue"
            mapSearchQuery = addressSearchQuery(
                components: [
                    venueDetails?.address,
                    venueDetails?.city,
                    venueDetails?.pinCode ?? venueDetails?.code
                ]
            )
            let mapImageKey = venueDetails?.venueAttachment?.first?.key ?? venueDetails?.logo?.key ?? event.flyer?.key ?? ""
            mapImageURL = mapImageKey.isEmpty ? nil : mapImageKey.imageURL
        }

        if let coordinate {
            updateLocationOnMap(
                to: coordinate,
                with: title,
                imageURL: mapImageURL,
                searchQuery: mapSearchQuery
            )
        } else {
            mapView.isHidden = true
            eventAddressView.isHidden = true
        }

        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            timingLbl.text = customText
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

            if !dateText.isEmpty && !startTime.isEmpty {
                let hideEnd = event.hideEventEnd == true
                let hasEndTime = !(event.endDateTime?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

                if hideEnd || !hasEndTime {
                    timingLbl.text = "\(dateText) at \(startTime)"
                } else {
                    let endTime = event.endDateTime?.convertDateFormat(
                        from: .yyyyMMddHHmmss,
                        to: .hmma,
                        customTimeZone: timezone
                    ) ?? ""

                    timingLbl.text = "\(dateText) at \(startTime) - \(endTime)"
                }
            } else {
                timingLbl.text = ""
            }
        }

        applyWhiteLabelTheme()

        setupSocialLinks()

//        if event.eventTicket == nil {
//        } else {
//            let eventTicketSettings = event.eventTicketSettings
//
//            if event.isPausedSellingAllTickets == true {
//                checkOutBtn.setTitle("Tickets from Free", for: .normal)
////                buyNowBtnView.isUserInteractionEnabled = true
//
//            } else if event.isSaleEndedAllTickets == true {
//                checkOutBtn.setTitle(eventTicketSettings?.saleEndedText ?? "It was a great time!", for: .normal)
//
//                if eventTicketSettings?.isSaleEndedTextEnabled == true {
////                    buyNowBtnLbl.text = Constant.String.saleEnded.uppercased()
//                } else {
////                    buyNowBtnLbl.text = Constant.String.saleEnded.uppercased()
//                }
//
////                buyNowBtnLbl.textColor = .black
////                buyNowBtnView.isUserInteractionEnabled = false
////                buyNowBtnView.backgroundColor = UIColor.lightGray
//
//            } else if event.isSoldOutAllTickets == true {
//                if eventTicketSettings?.isSoldOutTextEnabled == true {
//                    checkOutBtn.setTitle(eventTicketSettings?.soldOutText ?? "It was a great time!", for: .normal)
////                    buyNowBtnLbl.text = Constant.String.saleEnded.uppercased()
//                } else {
//                    checkOutBtn.setTitle("It was a great time!", for: .normal)
////                    buyNowBtnLbl.text = Constant.String.saleEnded.uppercased()
//                }
//
////                buyNowBtnLbl.textColor = .black
////                buyNowBtnView.isUserInteractionEnabled = false
////                buyNowBtnView.backgroundColor = UIColor.lightGray
//
//            } else if event.eventTicket?.count ?? 0 == 0 {
//                checkOutBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
////                buyNowBtnLbl.text = Constant.String.salePaused.uppercased()
////                buyNowBtnView.isUserInteractionEnabled = false
//
//            } else {
//                let lowestPrice = event.lowestPriceTicket?.price ?? 0
//                let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
//
//                if lowestPrice == 0 {
//                    checkOutBtn.setTitle("Tickets from Free", for: .normal)
//                } else {
//                    checkOutBtn.setTitle("Tickets from \(currency)\(Double(lowestPrice).decimalFormat(true))", for: .normal)
//                }
//            }
//        }
    }

    private func venueFooterTitle(for event: Event) -> String {
        if event.customVenue != nil && venueDetails?.venueSettings?.isOrganizer == true {
            let customVenueName = event.customVenue?.name?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let organizerName = venueDetails?.name
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if !customVenueName.isEmpty && !organizerName.isEmpty {
                return "\(customVenueName) by \(organizerName)"
            }

            return customVenueName.isEmpty ? organizerName : customVenueName
        }

        let name = venueDetails?.name
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let city = venueDetails?.city
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return [name, city]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
    
    
    
    private func setupTicketsButton() {
        guard let event = event else { return }

        let settings = event.eventTicketSettings
        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
        let currencyPosition = venueDetails?.venueSettings?.currencyPosition

        // Reset state
        soldOutView.isHidden = true
        soldOutLbl.text = ""
        checkOutBtn.isEnabled = true
        checkOutBtn.isUserInteractionEnabled = true

      

        if event.isPausedSellingAllTickets == true {
//            checkOutBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
            checkOutBtn.setTitle("Check back later", for: .normal)
            checkOutBtn.isEnabled = false
            checkOutBtn.isUserInteractionEnabled = false
            soldOutView.isHidden = false
            soldOutLbl.text = Constant.String.salePaused.uppercased()
            applyDisabledBottomTicketButtonVisibility()
            return
        }

        if event.isSaleEndedAllTickets == true {
            let title = settings?.isSaleEndedTextEnabled == true
                ? (settings?.saleEndedText ?? "It was a great time!")
                : "It was a great time!"
            checkOutBtn.setTitle(title, for: .normal)
            checkOutBtn.isEnabled = false
            checkOutBtn.isUserInteractionEnabled = false
            soldOutView.isHidden = false
            soldOutLbl.text = Constant.String.saleEnded.uppercased()
            applyDisabledBottomTicketButtonVisibility()
            return
        }

        if event.isSoldOutAllTickets == true {
            let title = settings?.isSoldOutTextEnabled == true
                ? (settings?.soldOutText ?? "Sorry, you missed it!")
                : "Sorry, you missed it!"
            checkOutBtn.setTitle(title, for: .normal)
            checkOutBtn.isEnabled = false
            checkOutBtn.isUserInteractionEnabled = false
            soldOutView.isHidden = false
            soldOutLbl.text = Constant.String.soldOut.uppercased()
            applyDisabledBottomTicketButtonVisibility()
            return
        }
        
        guard let tickets = event.eventTicket, !tickets.isEmpty else {
            checkOutBtn.setTitle("Check back later", for: .normal)
            checkOutBtn.isEnabled = false
            checkOutBtn.isUserInteractionEnabled = false
            soldOutView.isHidden = false
            soldOutLbl.text = Constant.String.salePaused.uppercased()
            applyDisabledBottomTicketButtonVisibility()
            return
        }

        // Normal — tickets available
        let lowestPrice = event.lowestPriceTicket?.price ?? 0
        let title = lowestPrice == 0
            ? "Tickets from Free"
            : "Tickets from \(CurrencyFormatter.amount(Double(lowestPrice), symbol: currency, position: currencyPosition))"
        checkOutBtn.setTitle(title, for: .normal)
        checkOutBtn.isEnabled = true
        checkOutBtn.isUserInteractionEnabled = true
        soldOutView.isHidden = true
    }
    
    private func configureVIPTablesView() {
        
        let isOnlineTablesEnabled = event?.isEnableOnlineTables
        let isReservationRequestEnabled = event?.isEnableReservationRequest
        let is3DMapEnabled = event?.isEnable3DMap
        let hasAnySeatingAreas = !seatingAreas.isEmpty
        let hasSeatingAreas = !seatingAreasFilteredOut.isEmpty

        guard
            isEventDetailAPICalled,
            hasLoadedSeatingAreas
        else {
            setVIPTablesView(hidden: true)
            return
        }

        if isReservationRequestEnabled ?? false {
            setVIPTablesView(hidden: false)
            configureVIPTablesText(defaultSubtitle: (
                is3DMapEnabled ?? false && hasSeatingAreas
            )
            ? "Reservation requests available. 3D map available."
            : "Reservation requests available.")
            return
        }

        guard
            didLoadSeatingAreasSuccessfully,
            hasAnySeatingAreas
        else {
            setVIPTablesView(hidden: true)
            return
        }
        
        let shouldShowVIPTablesView: Bool = {
            // Show online tables only if seating areas exist
            if isOnlineTablesEnabled ?? false && hasSeatingAreas {
                return true
            }
            
            return false
        }()
        
        setVIPTablesView(hidden: !shouldShowVIPTablesView)
        
        // MARK: - Subtitle

        if isOnlineTablesEnabled ?? false {
            
            configureVIPTablesText(defaultSubtitle: (
                is3DMapEnabled ?? false && hasSeatingAreas
            )
            ? "Ideal for larger groups. 3D map available."
            : "Ideal for larger groups.")
            
            return
        }
        
        configureVIPTablesText(defaultSubtitle: nil)
    }

    private func configureVIPTablesText(defaultSubtitle: String?) {
        vipTableTitleLbl.text = customVIPTableTitle ?? "VIP Tables"
        vipTableSubTitleLbl.text = customVIPTableDescription ?? defaultSubtitle
    }

    private var customVIPTableTitle: String? {
        customVIPTableText(event?.eventSettings?.customVipTableTitle)
    }

    private var customVIPTableDescription: String? {
        customVIPTableText(event?.eventSettings?.customVipTableDescription)
    }

    private func customVIPTableText(_ text: String?) -> String? {
        guard event?.eventSettings?.isCustomVipTableEnabled == true else {
            return nil
        }

        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private let navBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    private func updateNavPosition(for offsetY: CGFloat) {
        let navOffset = min(max(offsetY, 0), navInitialTopSpacing)
        navBarView.transform = CGAffineTransform(
            translationX: 0,
            y: -navOffset
        )
    }

    func applyNavAppearance(collapsed: Bool) {
        if collapsed {
            navBarView.backgroundColor = .clear

            if navBlurView.superview == nil {
                navBlurView.translatesAutoresizingMaskIntoConstraints = false
                navBarView.insertSubview(navBlurView, at: 0) // behind all nav content

                NSLayoutConstraint.activate([
                    navBlurView.topAnchor.constraint(equalTo: navBarView.topAnchor),
                    navBlurView.leadingAnchor.constraint(equalTo: navBarView.leadingAnchor),
                    navBlurView.trailingAnchor.constraint(equalTo: navBarView.trailingAnchor),
                    navBlurView.bottomAnchor.constraint(equalTo: navBarView.bottomAnchor)
                ])
            }

            navBlurView.isHidden = false

        } else {
            navBarView.backgroundColor = .clear
            navBlurView.isHidden = true
        }
    }

    private func addressSearchQuery(
        components: [String?]
    ) -> String? {
        let parts =
        components
            .compactMap {
                $0?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }

    private func makeGroupedTickets(from list: [EventTicket]) -> (nonGrouped: [EventTicket], grouped: [(groupId: String, groupName: String, tickets: [EventTicket])]) {
        var nonGrouped: [EventTicket] = []
        var groupOrder: [String] = []
        var groupedMap: [String: (groupId: String, groupName: String, tickets: [EventTicket])] = [:]

        for ticket in list {
            if let group = ticket.eventTicketGroupHasTicket?.eventTicketGroup,
               let groupId = group.id,
               !groupId.isEmpty {

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

        return (nonGrouped, groupOrder.compactMap { groupedMap[$0] })
    }

    private func setupInlineTicketData() {
        guard let event else { return }

        disabledTicketIds.removeAll()

        let visibleNormalTickets = filterAvailableTickets(event.eventTicket ?? [])
        let normalSplit = makeGroupedTickets(from: visibleNormalTickets)

        normalTickets = normalSplit.nonGrouped
        groupedNormalTickets = normalSplit.grouped
        expandedGroupIds = expandedGroupIds.intersection(
            Set(groupedNormalTickets.map { $0.groupId })
        )
        tickets = normalTickets

        let protectedVisibleCandidates = filterAvailableTickets(event.protectedEventTicket ?? [])
        protectedTicketView.isHidden = protectedVisibleCandidates.isEmpty
        lockIcon.isHidden = protectedVisibleCandidates.isEmpty

        ticketTableView.isHidden = normalTickets.isEmpty
        groupTableView.isHidden = groupedNormalTickets.isEmpty

        ticketTableView.reloadData()
        groupTableView.reloadData()
        updateTicketTableHeight()
        updateGroupTableHeight()

        let hasInlineContent =
        !normalTickets.isEmpty ||
        !groupedNormalTickets.isEmpty ||
        !protectedVisibleCandidates.isEmpty

        setTicketListView(hidden: !hasInlineContent)
        updateContinueBtnState()
    }

    private func updateTicketTableHeight() {
        ticketTableView.layoutIfNeeded()
        ticketTableHeightConstraint.constant =
        ticketTableView.isHidden ? 0 : ticketTableView.contentSize.height
    }

    private func updateGroupTableHeight() {
        groupTableView.layoutIfNeeded()
        groupTableViewHeight.constant =
        groupTableView.isHidden ? 0 : groupTableView.contentSize.height
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

            updateGroupTableHeight()
            return
        }

        UIView.performWithoutAnimation {
            groupTableView.reloadRows(at: [groupIndexPath], with: .none)
            groupTableView.layoutIfNeeded()
        }
        updateGroupTableHeight()
    }

    private func syncUpdatedTicketToEvent(_ updatedTicket: EventTicket) {
        guard let id = updatedTicket.id else { return }

        if let idx = normalTickets.firstIndex(where: { $0.id == id }) {
            normalTickets[idx] = updatedTicket
        }

        for groupIndex in groupedNormalTickets.indices {
            if let ticketIndex = groupedNormalTickets[groupIndex].tickets.firstIndex(where: { $0.id == id }) {
                groupedNormalTickets[groupIndex].tickets[ticketIndex] = updatedTicket
            }
        }

        if let idx = tickets.firstIndex(where: { $0.id == id }) {
            tickets[idx] = updatedTicket
        }

        if var updatedEvent = event {
            if let idx = updatedEvent.eventTicket?.firstIndex(where: { $0.id == id }) {
                updatedEvent.eventTicket?[idx] = updatedTicket
            }

            if let idx = updatedEvent.protectedEventTicket?.firstIndex(where: { $0.id == id }) {
                updatedEvent.protectedEventTicket?[idx] = updatedTicket
            }

            event = updatedEvent
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

        guard didUpdate else { return }

        setupTicketsButton()
        setupInlineTicketData()
        updateCheckoutSummaryView()
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
        (event?.protectedEventTicket?.contains { $0.id == id } == true)
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
        guard !isTicketDisabledByLink(ticket) else { return }
        guard let index = tickets.firstIndex(where: { $0.id == ticket.id }) else { return }

        let currentTicket = tickets[index]
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
            var updatedTicket = currentTicket
            updatedTicket.selectedTicketCount = nextCount
            syncUpdatedTicketToEvent(updatedTicket)
            AppHaptic.stepperChanged()

            ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            updateContinueBtnState()
            updateTicketTableHeight()
            updateCheckoutSummaryView()
        } else {
            AppHaptic.warning()
            Alert.showToast("Max tickets selected: create a separate order to purchase more.")
        }
    }

    private func handleMinus(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket) else { return }
        guard let index = tickets.firstIndex(where: { $0.id == ticket.id }) else { return }

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

        var updatedTicket = currentTicket
        updatedTicket.selectedTicketCount = nextCount > 0 ? nextCount : nil
        syncUpdatedTicketToEvent(updatedTicket)
        AppHaptic.stepperChanged()

        ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        updateContinueBtnState()
        updateTicketTableHeight()
        updateCheckoutSummaryView()
    }

    private func selectOnlyInlineTicket(
        _ ticket: EventTicket,
        shouldUpdateCheckoutBar: Bool = true
    ) -> EventTicket? {
        guard let ticketId = ticket.id else { return nil }

        normalTickets.indices.forEach {
            normalTickets[$0].selectedTicketCount = nil
        }

        for groupIndex in groupedNormalTickets.indices {
            for ticketIndex in groupedNormalTickets[groupIndex].tickets.indices {
                groupedNormalTickets[groupIndex].tickets[ticketIndex].selectedTicketCount = nil
            }
        }

        var selectedTicket: EventTicket?

        if let index = normalTickets.firstIndex(where: { $0.id == ticketId }) {
            normalTickets[index].selectedTicketCount = 1
            selectedTicket = normalTickets[index]
        }

        for groupIndex in groupedNormalTickets.indices {
            guard let ticketIndex = groupedNormalTickets[groupIndex]
                .tickets
                .firstIndex(where: { $0.id == ticketId })
            else { continue }

            groupedNormalTickets[groupIndex].tickets[ticketIndex].selectedTicketCount = 1
            selectedTicket = groupedNormalTickets[groupIndex].tickets[ticketIndex]
            break
        }

        guard let selectedTicket else { return nil }

        syncUpdatedTicketToEvent(selectedTicket)
        tickets = normalTickets
        ticketTableView.reloadData()
        groupTableView.reloadData()
        updateTicketTableHeight()
        updateGroupTableHeight()
        updateContinueBtnState()
        if shouldUpdateCheckoutBar {
            updateCheckoutSummaryView()
        } else {
            hideCheckoutBarImmediately()
        }

        return selectedTicket
    }

    private func hasVisibleAddOnOptions(for event: Event) -> Bool {
        !filterAvailableTickets(event.eventAddOnTicket ?? []).isEmpty ||
        !filterAvailableTickets(event.protectedeventAddOnTicket ?? []).isEmpty
    }

    private func handleRSVP(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket) else { return }
        checkInlineRSVPStock(ticket: ticket) { [weak self] in
            self?.continueInlineRSVP(ticket: ticket)
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
                var updatedTicket = currentTicket
                updatedTicket.selectedTicketCount = nextCount
                syncUpdatedTicketToEvent(updatedTicket)
                AppHaptic.stepperChanged()

                updateContinueBtnState()
                refreshGroupTicketRow(groupIndex: groupIndex, ticketIndex: ticketIndex)
                updateCheckoutSummaryView()
            } else {
                AppHaptic.warning()
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

            var updatedTicket = currentTicket
            updatedTicket.selectedTicketCount = nextCount > 0 ? nextCount : nil
            syncUpdatedTicketToEvent(updatedTicket)
            AppHaptic.stepperChanged()

            updateContinueBtnState()
            refreshGroupTicketRow(groupIndex: groupIndex, ticketIndex: ticketIndex)
            updateCheckoutSummaryView()
            return
        }
    }

    private func handleGroupRSVP(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket) else { return }
        checkInlineRSVPStock(ticket: ticket) { [weak self] in
            self?.continueInlineRSVP(ticket: ticket)
        }
    }

    private func checkInlineRSVPStock(
        ticket: EventTicket,
        completion: @escaping () -> Void
    ) {
        guard LoginRequiredCoordinator.isAuthenticated else {
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                self?.checkInlineRSVPStock(ticket: ticket, completion: completion)
            }
            return
        }

        guard let user = UserDefault.shared.user,
              let event,
              let ticketId = ticket.id else { return }

        guard !isInlineRSVPStockCheckInProgress else { return }
        isInlineRSVPStockCheckInProgress = true
        hideCheckoutBarImmediately()

        let payload: [[String: Any]] = [
            [
                "ticketId": ticketId,
                "ticketQuantity": 1,
                "ticketPrice": ticket.price ?? 0
            ]
        ]

        paymentService.checkEventTicketStock(
            eventId: event.id,
            code: user.code,
            phone: user.phone,
            gender: user.gender,
            userId: user.id,
            tickets: payload
        ) { [weak self] isAvailable, errMsg in
            DispatchQueue.main.async {
                guard let self else { return }

                self.isInlineRSVPStockCheckInProgress = false

                guard isAvailable else {
                    self.hideCheckoutBarImmediately()
                    Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                    return
                }

                completion()
            }
        }
    }

    private func continueInlineRSVP(ticket: EventTicket) {
        guard let event,
              let selectedTicket = selectOnlyInlineTicket(
                ticket,
                shouldUpdateCheckoutBar: false
              ) else { return }

        shouldClearInlineRSVPSelectionOnReturn = true

        if hasVisibleAddOnOptions(for: event) {
            Navigate.to.ticketSelectionVc(
                self,
                event: event,
                mode: .addOn,
                selectedNormalTickets: [selectedTicket],
                promotionLinkId: promoteId,
                promotionLinkUniqueCode: promotionLinkUniqueCode
            )
            return
        }

        createInlineOrderBookingAndCheckout(selectedTickets: [selectedTicket])
    }

    private func updateContinueBtnState() {
//        continueToCheckOutView.isHidden = totalSelectedTickets == 0
    }
    
    private func showGuestListPopup() {
        guard !attendees.isEmpty else { return }

        let vc = GuestListPopupVC()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.attendees = attendees
        vc.eventId = event?.uniqueId
        vc.totalAttendees = max(totalAttendees, attendees.count)
        vc.totalTicketSold = totalTicketSold
        vc.hasMore = attendeesHasMore || totalAttendees > attendees.count
        present(vc, animated: false)
    }

    private func isLineupMoreItem(at indexPath: IndexPath) -> Bool {
        artists.count > maxVisibleLineupArtists &&
        indexPath.item == maxVisibleLineupArtists
    }

    private func showLineupSheet() {
        guard artists.count > maxVisibleLineupArtists else { return }

        let vc = EventLineupBottomSheetVC()
        vc.artists = artists
        vc.modalPresentationStyle = .formSheet
        vc.modalTransitionStyle = .coverVertical

        present(vc, animated: true)
    }

    private func lineupChipSpacing(for collectionView: UICollectionView) -> CGFloat {
        lineupChipLayoutMetrics(for: collectionView).spacing
    }

    private func lineupChipSideInset(for collectionView: UICollectionView) -> CGFloat {
        lineupChipLayoutMetrics(for: collectionView).sideInset
    }

    private func lineupChipLayoutMetrics(for collectionView: UICollectionView) -> (sideInset: CGFloat, spacing: CGFloat) {
        let itemCount = max(visibleLineupItemCount, 1)
        let availableWidth = collectionView.bounds.width
        let alignedSideInset = lineupChipAlignedSideInset(for: collectionView)
        let itemTotalWidth = CGFloat(itemCount) * lineupChipSize

        guard itemCount > 1 else {
            let sideInset = min(alignedSideInset, max(0, (availableWidth - itemTotalWidth) / 2))
            return (sideInset, 0)
        }

        let spacingSlots = CGFloat(itemCount - 1)

        if itemCount == maxVisibleLineupArtists + 1 {
            let spacingForBalancedGutters =
            (availableWidth - itemTotalWidth - (alignedSideInset * 2)) / spacingSlots

            if spacingForBalancedGutters >= lineupChipMinimumSpacing {
                return (alignedSideInset, spacingForBalancedGutters)
            }

            let compactContentWidth = itemTotalWidth + (lineupChipMinimumSpacing * spacingSlots)
            let compactSideInset = max(0, (availableWidth - compactContentWidth) / 2)
            return (compactSideInset, lineupChipMinimumSpacing)
        }

        let maxSpacingForAlignedInsets =
        (availableWidth - itemTotalWidth - (alignedSideInset * 2)) / spacingSlots
        let spacing = min(lineupChipTargetSpacing, max(lineupChipMinimumSpacing, maxSpacingForAlignedInsets))
        let contentWidth = itemTotalWidth + (spacing * spacingSlots)
        let sideInset = min(alignedSideInset, max(0, (availableWidth - contentWidth) / 2))

        return (sideInset, spacing)
    }

    private func lineupChipAlignedSideInset(for collectionView: UICollectionView) -> CGFloat {
        let titleAlignmentInset = max(0, -collectionView.frame.minX)
        return titleAlignmentInset > 0 ? titleAlignmentInset : lineupChipTargetSideInset
    }
    
    private func showIntsaPopup() {
        let vc = InstagramUsernamePopupVC()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.onSubmitUsername = { [weak self] profileData in
            guard let self = self else { return }
            if let data = profileData {
                showInstagramProfileFoundPopup(instagramProfile: data)
            }
        }
        present(vc, animated: false)
    }
    
    private func showInstagramProfileFoundPopup(instagramProfile: InstagramProfile) {
        let vc = InstagramProfileFoundPopupVC()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.imageURL = instagramProfile.profilePictureKey
        vc.instaProfileData = instagramProfile
        present(vc, animated: false)
    }

    @IBAction func onClickInlineContinue(_ sender: Any) {
        guard let event else { return }

     
        let selectedNormal = normalTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
        let selectedGrouped = groupedNormalTickets
            .flatMap { $0.tickets }
            .filter { ($0.selectedTicketCount ?? 0) > 0 }

        let selected = selectedNormal + selectedGrouped
        guard !selected.isEmpty else {
            AppHaptic.warning()
            return
        }

        AppHaptic.primaryAction()

        if hasVisibleAddOnOptions(for: event) {
            shouldClearInlineRSVPSelectionOnReturn = true
            Navigate.to.ticketSelectionVc(
                self,
                event: event,
                mode: .addOn,
                selectedNormalTickets: selected,
                promotionLinkId: promoteId,
                promotionLinkUniqueCode: promotionLinkUniqueCode
            )
            return
        }

        createInlineOrderBookingAndCheckout(selectedTickets: selected)
    }

    private func createInlineOrderBookingAndCheckout(selectedTickets: [EventTicket]) {
        guard LoginRequiredCoordinator.isAuthenticated else {
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                self?.createInlineOrderBookingAndCheckout(selectedTickets: selectedTickets)
            }
            return
        }

        guard let user = UserDefault.shared.user,
              let event else { return }

        checkOutBtnView.showLoader()

        let payload: [[String: Any]] = selectedTickets.map {
            [
                "ticketId": $0.id ?? "",
                "ticketQuantity": $0.selectedTicketCount ?? 0,
                "ticketPrice": $0.price ?? 0
            ]
        }

        paymentService.createEventBooking(
            eventId: event.id,
            code: user.code,
            phone: user.phone,
            gender: user.gender,
            userId: user.id,
            tickets: payload,
            promotionLinkId: promoteId,
            promotionLinkUniqueCode: promotionLinkUniqueCode
        ) { [weak self] isSuccess, errMsg, bookingId, _ in
            guard let self else { return }

            self.checkOutBtnView.hideLoader()
            if isSuccess {
                AppHaptic.success()
                self.shouldClearInlineRSVPSelectionOnReturn = true
                Navigate.orderListVC(
                    self,
                    event: event,
                    selectedTickets: selectedTickets,
                    bookingId: bookingId,
                    paymentMethod: nil,
                    venueDetails: self.venueDetails,
                    promotionLinkId: promoteId,
                    promotionLinkUniqueCode: promotionLinkUniqueCode
                )
            } else {
                AppHaptic.error()
                Alert.showToast(errMsg ?? "Something went wrong")
            }
        }
    }
    
    @IBAction func onClickVenueTitle(_ sender: Any) {
        AppHaptic.cardOpen()
        Navigate.to.venueVC(self, venueDetails: self.venueDetails)
    }

    private func createInlineBookingAndCheckout(selectedTickets: [EventTicket]) {
        guard LoginRequiredCoordinator.isAuthenticated else {
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                self?.createInlineBookingAndCheckout(selectedTickets: selectedTickets)
            }
            return
        }

        guard let user = UserDefault.shared.user else { return }
        guard let event = event else { return }

        checkOutBtn.showLoader(userInteraction: false)

        let ticketsPayload = selectedTickets.map {
            [
                "ticketId": ($0.id ?? "") ?? "",
                "ticketQuantity": $0.selectedTicketCount ?? 0,
                "ticketPrice": $0.price ?? 0
            ]
        }


        paymentService.createEventBooking(
            eventId: event.id,
            code: user.code,
            phone: user.phone,
            gender: user.gender,
            userId: user.id,
            tickets: ticketsPayload,
            promotionLinkId: promoteId,
            promotionLinkUniqueCode: promotionLinkUniqueCode
        ) { [weak self] isSuccess, errMsg, id, _ in
            guard let self else { return }
            self.checkOutBtn.hideLoader()


            if isSuccess {
                AppHaptic.success()
                self.shouldClearInlineRSVPSelectionOnReturn = true
                Navigate.to.ticketCheckoutVC(
                    self,
                    event: event,
                    selectedTickets: selectedTickets,
                    bookingId: id,
                    promotionLinkId: promoteId,
                    promotionLinkUniqueCode: promotionLinkUniqueCode
                )
            } else {
                AppHaptic.error()
                Alert.showToast(errMsg ?? "Somthing went wrong")
            }
        }
    }

    private func configureSocialIcon(_ imageView: UIImageView, url: String?) {
        imageView.gestureRecognizers?.forEach { imageView.removeGestureRecognizer($0) }

        guard let link = url,
              !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let validURL = URL(string: link) else {
            imageView.isHidden = true
            return
        }

        imageView.isHidden = false
        imageView.isUserInteractionEnabled = true
        imageView.accessibilityHint = validURL.absoluteString

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSocialTap(_:)))
        imageView.addGestureRecognizer(tap)
    }

    private func setupSocialLinks() {
        let websiteUrl = event?.venue?.venueSettings?.websiteUrl
        let instagramUrl = event?.venue?.venueSettings?.instagramUrl
        let tiktokUrl = event?.venue?.venueSettings?.tiktokUrl
        let facebookUrl = event?.venue?.venueSettings?.facebookUrl
        let xUrl = event?.venue?.venueSettings?.xUrl
        let youtubeUrl = event?.venue?.venueSettings?.youtubeUrl

        configureSocialIcon(websiteImageView, url: websiteUrl)
        configureSocialIcon(instaImageView, url: instagramUrl)
        configureSocialIcon(tikTokImageView, url: tiktokUrl)
        configureSocialIcon(faceBookImageView, url: facebookUrl)
        configureSocialIcon(xImageView, url: xUrl)
        configureSocialIcon(youTubeImageView, url: youtubeUrl)
    }

    @IBAction func onClickViewMoreBtn(_ sender: Any) {
        AppHaptic.selectionChanged()
        isExpanded.toggle()
        updateDescriptionExpansionVisibility()

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func onClickPolicyViewMoreBtn(_ sender: Any) {
        AppHaptic.selectionChanged()
        isPolicyLblExpanded.toggle()
        updatePolicyExpansionVisibility()

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func onClickBuyNow(_ sender: Any) {
        if let event = self.event {
            AppHaptic.primaryAction()
            Navigate.to.ticketSelectionVc(
                self,
                event: event,
                mode: .normal,
                promotionLinkId: promoteId,
                promotionLinkUniqueCode: promotionLinkUniqueCode
            )
        }
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        handleBackNavigation()
    }

    @IBAction func onClickShareBtn(_ sender: Any) {}

    @IBAction func onClickVIPtable(_ sender: Any) {
        if event?.isEnableReservationRequest == true {
            guard hasLoadedSeatingAreas else {
                AppHaptic.warning()
                return
            }

            AppHaptic.cardOpen()
            openPremiumEventContainer(with: seatingAreas)
            return
        }

        guard didLoadSeatingAreasSuccessfully,
              !seatingAreas.isEmpty else {
            AppHaptic.warning()
            return
        }

        AppHaptic.cardOpen()
        openPremiumEventContainer(with: seatingAreas)
    }

    private func openPremiumEventContainer(with seatingAreas: [SeatingArea]) {
        guard let event = self.event else { return }

        Navigate.to.premiumEventContainerVC(
            self,
            event: event,
            seatingAreas: seatingAreas,
            promotionLinkId: promoteId,
            promotionLinkUniqueCode: promotionLinkUniqueCode
        )
    }
    
    @IBAction func onClickShare(_ sender: Any) {
        AppHaptic.navigation()
        let venue = venueDetails?.name
              .lowercased()
              .replacingOccurrences(of: " ", with: "-") ?? ""
          
          let eventName = event?.title
              .lowercased()
              .replacingOccurrences(of: " ", with: "-") ?? ""
          
          let eventId = event?.uniqueId ?? event?.id ?? ""
          
          let url = String(format: APIBuilder.eventWebURL, venue, eventName, eventId)
          
          Utility.main.shareSocialWith(text: url)
    }

    @IBAction func onClickWebSiteLinkView(_ sender: Any) {
        guard let button = enabledAdditionalButtons.first else { return }
        AppHaptic.navigation()
        openAdditionalButton(button)
    }
        
    @IBAction func onClickViewGuestListBtn(_ sender: Any) {
        AppHaptic.cardOpen()
        LoginRequiredCoordinator.perform(from: self) { [weak self] in
            self?.showGuestListForAuthenticatedUser()
        }
    }

    private func showGuestListForAuthenticatedUser() {
        if let _ = UserDefault.shared.user?.instagramUserId {
            showGuestListPopup()
        } else {
            showIntsaPopup()
        }
    }

    @IBAction func onClickUnLockBtn(_ sender: Any) {
        let code = unlockCode
        guard !code.isEmpty else {
            AppHaptic.warning()
            return
        }
        guard var event = event else { return }

        let protectedList = event.protectedEventTicket ?? []

        let alreadyUnlocked = (event.eventTicket ?? []).contains { ticket in
            let pass = ticket.eventTicketHasPassword?.password ?? ""
            return pass.caseInsensitiveCompare(code) == .orderedSame
        }

        if alreadyUnlocked {
            AppHaptic.warning()
            Alert.showToast("Tickets already unlocked", vc: self)
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
            AppHaptic.error()
            Alert.showToast("Invalid password. Please try again.", vc: self)
            return
        }

        let validUnlockedTickets = filterAvailableTickets(matchedTickets)

        if event.eventTicket == nil {
            event.eventTicket = []
        }

        for ticket in validUnlockedTickets where !(event.eventTicket?.contains(where: { $0.id == ticket.id }) ?? false) {
            event.eventTicket?.append(ticket)
        }

        let unlockedIds = Set(validUnlockedTickets.compactMap { $0.id })
        event.protectedEventTicket = protectedList.filter { ticket in
            guard let id = ticket.id else { return true }
            return !unlockedIds.contains(id)
        }

        self.event = event
        unLockTF.text = ""
        updateUnlockButtonState()

        setupData()
        AppHaptic.success()
    }
    
    
    @IBAction func onClickSaveBtn(_ sender: Any) {
        guard !isSaveLoading else { return }

        guard LoginRequiredCoordinator.isAuthenticated else {
            AppHaptic.warning()
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                self?.onClickSaveBtn(sender)
            }
            return
        }

        guard let eventUniqueId =
                event?.uniqueId,
              !eventUniqueId.isEmpty
        else {
            return
        }
        
        let previousState = isSaved
        let previousSavedEventId = savedEventId

        isSaveLoading = true
        isSaved.toggle()
        updateSaveUI()
        AppHaptic.selectionChanged()
        
        if isSaved {
            saveEventAPI(
                eventUniqueId: eventUniqueId,
                previousState: previousState,
                previousSavedEventId: previousSavedEventId
            )
        } else {
            guard let savedEventId,
                  !savedEventId.isEmpty
            else {
                resolveAndUnsaveEventAPI(
                    previousState: previousState,
                    previousSavedEventId: previousSavedEventId
                )
                return
            }

            unsaveEventAPI(
                savedEventId: savedEventId,
                previousState: previousState,
                previousSavedEventId: previousSavedEventId
            )
        }
    }

    private func saveEventAPI(
        eventUniqueId: String,
        previousState: Bool,
        previousSavedEventId: String?
    ) {

        eventService.saveEvent(
            uniqueId: eventUniqueId
        ) { [weak self] isSuccess, _, savedEvent in

            guard let self else { return }

            self.isSaveLoading = false

            guard isSuccess,
                  let id = savedEvent?.id,
                  !id.isEmpty
            else {

                self.rollbackSaveState(
                    previousState: previousState,
                    previousSavedEventId: previousSavedEventId
                )
                return
            }

            self.savedEventId = id
            self.event?.savedEventId = id
            self.event?.hasSavedEvent = true
            self.isSaved = true
            self.updateSaveUI()
            AppHaptic.success()
            if let event = self.event {
                self.onSaveStateChanged?(event, true)
            }
        }
    }

    private func unsaveEventAPI(
        savedEventId: String,
        previousState: Bool,
        previousSavedEventId: String?
    ) {

        eventService.unsaveEvent(
            savedEventId: savedEventId
        ) { [weak self] isSuccess, _, _ in

            guard let self else { return }

            self.isSaveLoading = false

            guard isSuccess else {
                self.rollbackSaveState(
                    previousState: previousState,
                    previousSavedEventId: previousSavedEventId
                )
                return
            }

            self.savedEventId = nil
            self.event?.savedEventId = nil
            self.event?.hasSavedEvent = false
            self.isSaved = false
            self.updateSaveUI()
            AppHaptic.success()
            if let event = self.event {
                self.onSaveStateChanged?(event, false)
            }
        }
    }

    private func resolveAndUnsaveEventAPI(
        previousState: Bool,
        previousSavedEventId: String?
    ) {
        
        if let savedEventId = self.event?.consumerSavedEvents?.id {
            
            self.unsaveEventAPI(
                savedEventId: savedEventId,
                previousState: previousState,
                previousSavedEventId: previousSavedEventId
            )
        }
    }

    private func rollbackSaveState(
        previousState: Bool,
        previousSavedEventId: String?
    ) {

        isSaveLoading = false
        isSaved = previousState
        savedEventId = previousSavedEventId
        event?.hasSavedEvent = previousState
        event?.savedEventId = previousSavedEventId
        updateSaveUI()
        AppHaptic.error()
    }
    
    
    @IBAction func onClickVenueImage(_ sender: Any) {
        AppHaptic.cardOpen()
        Navigate.to.venueVC(self, venueDetails: self.venueDetails)
    }
    
//    private func saveVenueAPI(venueId: String, previousState: Bool) {
//        APIManager.shared.saveVenue(venueId: venueId) { [weak self] success in
//            guard let self = self else { return }
//            self.isSaveLoading = false
//
//            if !success {
//                self.isSaved = previousState
//                self.updateSaveUI()
//            }
//        }
//    }
//
//    private func unsaveVenueAPI(venueId: String, previousState: Bool) {
//        APIManager.shared.unsaveVenue(venueId: venueId) { [weak self] success in
//            guard let self = self else { return }
//            self.isSaveLoading = false
//
//            if !success {
//                self.isSaved = previousState
//                self.updateSaveUI()
//            }
//        }
//    }
    
    @objc private func toggleDescription() {
        AppHaptic.selectionChanged()
        isExpanded.toggle()

        if isExpanded {
            detailsLbl.numberOfLines = 0
        } else {
            detailsLbl.numberOfLines = collapsedLines
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func handleSocialTap(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }

        var selectedURL: String?

        let websiteUrl = event?.venue?.venueSettings?.websiteUrl
        let instagramUrl = event?.venue?.venueSettings?.instagramUrl
        let tiktokUrl = event?.venue?.venueSettings?.tiktokUrl
        let facebookUrl = event?.venue?.venueSettings?.facebookUrl
        let xUrl = event?.venue?.venueSettings?.xUrl
        let youtubeUrl = event?.venue?.venueSettings?.youtubeUrl

        switch view {
        case websiteImageView:
            selectedURL = websiteUrl
        case instaImageView:
            selectedURL = instagramUrl
        case tikTokImageView:
            selectedURL = tiktokUrl
        case faceBookImageView:
            selectedURL = facebookUrl
        case xImageView:
            selectedURL = xUrl
        case youTubeImageView:
            selectedURL = youtubeUrl
        default:
            break
        }

        if let link = selectedURL,
           let url = URL(string: link) {
            AppHaptic.navigation()
            UIApplication.shared.open(url)
        }
    }

    private func setupExpandableLabel() {
        guard let html = event?.description,
              let attributed = html.htmlToAttributedString else { return }

        let mutable = NSMutableAttributedString(attributedString: attributed)

        mutable.trimTrailingWhitespaceAndNewlines()
        mutable.forceSystemFont15()
        mutable.addAttribute(.foregroundColor,
                             value: UIColor.label,
                             range: NSRange(location: 0, length: mutable.length))

        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 0
        style.paragraphSpacingBefore = 0
        style.lineSpacing = 0
        mutable.addAttribute(.paragraphStyle,
                             value: style,
                             range: NSRange(location: 0, length: mutable.length))

        addDetectedPlainLinks(to: mutable)
        let hasLinks = applyHTMLLinkStyle(to: mutable, linkColor: .white)

        detailsLbl.attributedText = mutable
        detailsLbl.numberOfLines = collapsedLines
        configureHTMLLinkTapIfNeeded(on: detailsLbl, hasLinks: hasLinks)
        isExpanded = false

        view.layoutIfNeeded()
        updateDescriptionExpansionVisibility()
    }

    private func setupPolicyExpandableLabel() {
        guard let html = event?.disclaimer,
              let attributed = html.htmlToAttributedString else {
            self.policyView.isHidden = true
            return
        }

        self.policyView.isHidden = false
        let mutable = NSMutableAttributedString(attributedString: attributed)

        mutable.trimTrailingWhitespaceAndNewlines()
        mutable.forceSystemFont15()
        mutable.addAttribute(.foregroundColor,
                             value: UIColor.label,
                             range: NSRange(location: 0, length: mutable.length))

        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 0
        style.paragraphSpacingBefore = 0
        style.lineSpacing = 0
        mutable.addAttribute(.paragraphStyle,
                             value: style,
                             range: NSRange(location: 0, length: mutable.length))

        addDetectedPlainLinks(to: mutable)
        let hasLinks = applyHTMLLinkStyle(to: mutable, linkColor: .white)

        policyLbl.attributedText = mutable
        policyLbl.numberOfLines = collapsedLines
        configureHTMLLinkTapIfNeeded(on: policyLbl, hasLinks: hasLinks)
        isPolicyLblExpanded = false

        view.layoutIfNeeded()
        updatePolicyExpansionVisibility()
    }

    private func addDetectedPlainLinks(to mutable: NSMutableAttributedString) {
        guard mutable.length > 0,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return
        }

        let fullRange = NSRange(location: 0, length: mutable.length)
        detector.enumerateMatches(in: mutable.string, options: [], range: fullRange) { match, _, _ in
            guard let match,
                  match.range.length > 0,
                  let url = match.url,
                  mutable.attribute(.link, at: match.range.location, effectiveRange: nil) == nil else {
                return
            }

            mutable.addAttribute(.link, value: url, range: match.range)
        }
    }

    @discardableResult
    private func applyHTMLLinkStyle(to mutable: NSMutableAttributedString,
                                    linkColor: UIColor) -> Bool {
        var hasLinks = false
        let fullRange = NSRange(location: 0, length: mutable.length)

        mutable.enumerateAttribute(.link, in: fullRange, options: []) { value, range, _ in
            guard value != nil else { return }

            hasLinks = true

            let currentFont = mutable.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont
            let linkFont = Constant.Font.geistSemiBold(size: currentFont?.pointSize ?? 15)

            mutable.removeAttribute(.foregroundColor, range: range)
            mutable.removeAttribute(.font, range: range)
            mutable.addAttributes([
                .foregroundColor: linkColor,
                .font: linkFont,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: linkColor
            ], range: range)
        }

        return hasLinks
    }

    private func configureHTMLLinkTapIfNeeded(on label: UILabel, hasLinks: Bool) {
        label.tintColor = .white
        label.isUserInteractionEnabled = hasLinks

        guard hasLinks,
              label.gestureRecognizers?.contains(where: { $0.name == "EventDetailsHTMLLinkTap" }) != true else {
            return
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleHTMLLabelTap(_:)))
        tap.name = "EventDetailsHTMLLinkTap"
        label.addGestureRecognizer(tap)
    }

    @objc private func handleHTMLLabelTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel,
              let url = htmlLinkURL(from: gesture, in: label) else {
            return
        }

        AppHaptic.navigation()
        UIApplication.shared.open(url)
    }

    private func htmlLinkURL(from gesture: UITapGestureRecognizer, in label: UILabel) -> URL? {
        guard let attributedText = label.attributedText,
              attributedText.length > 0,
              label.bounds.width > 0,
              label.bounds.height > 0 else {
            return nil
        }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)

        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let touchLocation = gesture.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textOffset = CGPoint(
            x: (label.bounds.width - textBoundingBox.width) * horizontalTextOffsetFactor(for: label) - textBoundingBox.origin.x,
            y: (label.bounds.height - textBoundingBox.height) * 0.5 - textBoundingBox.origin.y
        )
        let locationInTextContainer = CGPoint(
            x: touchLocation.x - textOffset.x,
            y: touchLocation.y - textOffset.y
        )

        guard locationInTextContainer.x >= 0,
              locationInTextContainer.y >= 0 else {
            return nil
        }

        let glyphIndex = layoutManager.glyphIndex(for: locationInTextContainer, in: textContainer)
        guard glyphIndex < layoutManager.numberOfGlyphs else { return nil }

        let glyphRange = NSRange(location: glyphIndex, length: 1)
        let glyphRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        guard glyphRect.insetBy(dx: -8, dy: -8).contains(locationInTextContainer) else {
            return nil
        }

        let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
        guard characterIndex < attributedText.length else { return nil }

        let linkValue = attributedText.attribute(.link, at: characterIndex, effectiveRange: nil)
        return normalizedHTMLLinkURL(from: linkValue)
    }

    private func horizontalTextOffsetFactor(for label: UILabel) -> CGFloat {
        switch label.textAlignment {
        case .center:
            return 0.5
        case .right:
            return 1
        default:
            return 0
        }
    }

    private func normalizedHTMLLinkURL(from value: Any?) -> URL? {
        let rawLink: String

        if let url = value as? URL {
            rawLink = url.absoluteString
        } else if let string = value as? String {
            rawLink = string
        } else {
            return nil
        }

        return normalizedAdditionalButtonURL(from: rawLink.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func checkIfTextNeedsExpansion() {
        updateDescriptionExpansionVisibility()
    }

    private func checkIfPolicyTextNeedsExpansion() {
        updatePolicyExpansionVisibility()
    }

    private func updateDescriptionExpansionVisibility() {
        updateExpansionVisibility(
            for: detailsLbl,
            toggleContainer: viewMoreBtnView,
            toggleButton: viewMoreBtn,
            isExpanded: isExpanded
        )
    }

    private func updatePolicyExpansionVisibility() {
        updateExpansionVisibility(
            for: policyLbl,
            toggleContainer: policyViewMoreBtnView,
            toggleButton: policyViewMoreBtn,
            isExpanded: isPolicyLblExpanded
        )
    }

    private func updateExpansionVisibility(
        for label: UILabel,
        toggleContainer: UIView,
        toggleButton: UIButton,
        isExpanded: Bool
    ) {
        let width = label.bounds.width > 0 ? label.bounds.width : label.frame.width
        guard width > 0,
              hasExpandableText(in: label) else {
            label.numberOfLines = 0
            toggleContainer.isHidden = true
            return
        }

        let fullHeight = fittingHeight(for: label, numberOfLines: 0, width: width)
        let collapsedHeight = fittingHeight(for: label, numberOfLines: collapsedLines, width: width)
        let needsExpansion = fullHeight > collapsedHeight + 1

        label.numberOfLines = needsExpansion && !isExpanded ? collapsedLines : 0
        toggleContainer.isHidden = !needsExpansion
        toggleButton.setTitle(isExpanded ? "Read Less" : "Read More", for: .normal)
    }

    private func fittingHeight(for label: UILabel, numberOfLines: Int, width: CGFloat) -> CGFloat {
        let previousNumberOfLines = label.numberOfLines
        let previousPreferredMaxLayoutWidth = label.preferredMaxLayoutWidth

        label.numberOfLines = numberOfLines
        label.preferredMaxLayoutWidth = width
        let height = label.sizeThatFits(
            CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        ).height

        label.numberOfLines = previousNumberOfLines
        label.preferredMaxLayoutWidth = previousPreferredMaxLayoutWidth

        return ceil(height)
    }

    private func hasExpandableText(in label: UILabel) -> Bool {
        if let attributedText = label.attributedText {
            return attributedText.length > 0 &&
            !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return !(label.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private func updateExpandableTextForWidthChangesIfNeeded() {
        let detailsWidth = detailsLbl.bounds.width
        if detailsWidth > 0,
           abs(detailsWidth - lastDetailsLabelWidth) > 0.5 {
            lastDetailsLabelWidth = detailsWidth
            updateDescriptionExpansionVisibility()
        }

        let policyWidth = policyLbl.bounds.width
        if !policyView.isHidden,
           policyWidth > 0,
           abs(policyWidth - lastPolicyLabelWidth) > 0.5 {
            lastPolicyLabelWidth = policyWidth
            updatePolicyExpansionVisibility()
        }
    }

    func updateLocationOnMap(
        to coordinate: CLLocationCoordinate2D,
        with title: String?,
        imageURL: String?,
        searchQuery: String? = nil
    ) {
        mapView.isHidden = false
        let googleMapView = configuredGoogleMapView(center: coordinate)
        googleMapView.clear()
        
        let imageUrl =  "\(SharedURL.amazonStorage)\(venueDetails?.venueAttachment?.first?.key ?? "")"
        

        let point = EventDetailsMapAnnotation(
            coordinate: coordinate,
            title: title,
            imageURL: imageURL,
            searchQuery: searchQuery
        )
        
     
        let venueLogoKey = venueDetails?.logo?.key ?? ""
        let venueLogoURL = venueLogoKey.isEmpty ? nil : venueLogoKey.imageURL
        let marker = GMSMarker(position: point.coordinate)
        marker.title = point.title
        marker.iconView = EventDetailsLocationMarkerView(
            backgroundImageURL: imageUrl,
            logoImageURL: venueLogoURL
        )
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        marker.userData = point
        marker.map = googleMapView

        googleMapView.moveCamera(GMSCameraUpdate.setTarget(coordinate, zoom: 14))

        mapView.layer.cornerRadius = 16
        mapView.clipsToBounds = true
    }

    private func configuredGoogleMapView(center coordinate: CLLocationCoordinate2D) -> GMSMapView {
        if let googleMapView {
            return googleMapView
        }

        let camera = GMSCameraPosition(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            zoom: 14
        )
        let options = GMSMapViewOptions()
        options.frame = mapView.bounds
        options.camera = camera
        options.backgroundColor = .black

        let googleMapView = GMSMapView(options: options)
        googleMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        googleMapView.settings.compassButton = false
        googleMapView.settings.myLocationButton = false
        googleMapView.settings.rotateGestures = false
        googleMapView.settings.tiltGestures = false
        googleMapView.delegate = self
        googleMapView.mapStyle = try? GMSMapStyle(
            jsonString: Self.googleDarkMapStyle(showPointsOfInterest: false)
        )

        mapView.addSubview(googleMapView)
        self.googleMapView = googleMapView
        return googleMapView
    }

    private func openLocationInGoogleMaps(
        coordinate: CLLocationCoordinate2D,
        query: String? = nil
    ) {
        let trimmedQuery =
        query?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let mapQuery =
        trimmedQuery?.isEmpty == false
        ? trimmedQuery!
        : "\(coordinate.latitude),\(coordinate.longitude)"

        var components = URLComponents(
            string: "https://www.google.com/maps/search/"
        )
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(
                name: "query",
                value: mapQuery
            )
        ]

        guard let url = components?.url else { return }
        AppHaptic.navigation()
        UIApplication.shared.open(url)
    }

    private static func googleDarkMapStyle(showPointsOfInterest: Bool) -> String {
        let poiVisibility = showPointsOfInterest ? "simplified" : "off"

        return """
        [
          { "elementType": "geometry", "stylers": [{ "color": "#242424" }] },
          { "elementType": "labels.icon", "stylers": [{ "visibility": "off" }] },
          { "elementType": "labels.text.fill", "stylers": [{ "color": "#8f8f8f" }] },
          { "elementType": "labels.text.stroke", "stylers": [{ "color": "#101010" }] },
          { "featureType": "administrative", "elementType": "geometry", "stylers": [{ "color": "#3a3a3a" }] },
          { "featureType": "landscape", "elementType": "geometry", "stylers": [{ "color": "#222222" }] },
          { "featureType": "poi", "stylers": [{ "visibility": "\(poiVisibility)" }] },
          { "featureType": "poi", "elementType": "geometry", "stylers": [{ "color": "#262626" }] },
          { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [{ "color": "#787878" }] },
          { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#343434" }] },
          { "featureType": "road", "elementType": "geometry.stroke", "stylers": [{ "color": "#1a1a1a" }] },
          { "featureType": "road", "elementType": "labels.text.fill", "stylers": [{ "color": "#8a8a8a" }] },
          { "featureType": "road.highway", "elementType": "geometry", "stylers": [{ "color": "#2c2c2c" }] },
          { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{ "color": "#111111" }] },
          { "featureType": "transit", "elementType": "geometry", "stylers": [{ "color": "#272727" }] },
          { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#111111" }] },
          { "featureType": "water", "elementType": "labels.text.fill", "stylers": [{ "color": "#555555" }] }
        ]
        """
    }
}

extension EventDetailsVC: GMSMapViewDelegate {

    func mapView(
        _ mapView: GMSMapView,
        didTap marker: GMSMarker
    ) -> Bool {

        if let point = marker.userData as? EventDetailsMapAnnotation {
            openLocationInGoogleMaps(
                coordinate: point.coordinate,
                query: point.searchQuery
            )
        } else {
            openLocationInGoogleMaps(
                coordinate: marker.position
            )
        }

        return true
    }
}

class ImagePageVC: UIViewController {

    var imageURL: String = ""
    private let imageView = UIImageView()

    deinit {
        imageView.sd_cancelCurrentImageLoad()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)

        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: max(view.bounds.width, UIScreen.main.bounds.width) * scale,
            height: max(view.bounds.height, UIScreen.main.bounds.height) * scale
        )

        imageView.sd_setImage(
            with: URL(string: imageURL),
            placeholderImage: Constant.Icon.uploadImage,
            options: [.continueInBackground, .scaleDownLargeImages],
            context: [.imageThumbnailPixelSize: NSValue(cgSize: targetSize)]
        )
    }
}

extension EventDetailsVC {

    func setupCollectionViews() {
        guestListCollectionView.delegate = self
        guestListCollectionView.dataSource = self
        guestListCollectionView.register(
            EventGuestListCVC.nib,
            forCellWithReuseIdentifier: EventGuestListCVC.identifier
        )

        if let layout = guestListCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }

        lineUpCollectionView.delegate = self
        lineUpCollectionView.dataSource = self
        lineUpCollectionView.register(
            EventLineUpCVC.nib,
            forCellWithReuseIdentifier: EventLineUpCVC.identifier
        )

        if let layout = lineUpCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = lineupChipTargetSpacing
            layout.minimumInteritemSpacing = lineupChipTargetSpacing
            layout.sectionInset = UIEdgeInsets(
                top: 0,
                left: lineupChipTargetSideInset,
                bottom: 0,
                right: lineupChipTargetSideInset
            )
        }

        lineUpCollectionView.isScrollEnabled = false
    }

    func setupTableView() {
        faqsTableView.delegate = self
        faqsTableView.dataSource = self
        faqsTableView.register(
            FAQsTableViewCell.nib,
            forCellReuseIdentifier: FAQsTableViewCell.identifier
        )
        faqsTableView.tableFooterView = UIView()
        faqsTableView.isScrollEnabled = false

        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        ticketTableView.register(
            TicketsTVC.nib,
            forCellReuseIdentifier: TicketsTVC.identifier
        )
        ticketTableView.isScrollEnabled = false

        groupTableView.delegate = self
        groupTableView.dataSource = self
        groupTableView.register(
            GroupTicketTVC.nib,
            forCellReuseIdentifier: GroupTicketTVC.identifier
        )
        groupTableView.isScrollEnabled = false
        groupTableView.separatorStyle = .none
        groupTableView.backgroundColor = .clear
    }
}

extension EventDetailsVC: UICollectionViewDelegate,
                          UICollectionViewDataSource,
                          UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {

        if collectionView == guestListCollectionView {
            if isGuestListLoading {
                return 6
            }

            return min(attendees.count, 6)
        } else {
            return visibleLineupItemCount
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == guestListCollectionView {
            let cell: EventGuestListCVC = collectionView.dequeue(withIdentifier: EventGuestListCVC.identifier, for: indexPath)

            if isGuestListLoading {
                cell.configureSkeleton()
                return cell
            }

            let attendee = attendees[indexPath.item]
            cell.configure(with: attendee)
            return cell
        } else if collectionView == lineUpCollectionView {
            let cell: EventLineUpCVC = collectionView.dequeue(withIdentifier: EventLineUpCVC.identifier, for: indexPath)

            if isLineupMoreItem(at: indexPath) {
                cell.configureMore()
                return cell
            }

            guard artists.indices.contains(indexPath.item) else { return cell }

            let artist = artists[indexPath.item]
            cell.configure(with: artist)
            return cell
        }

        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        if collectionView == guestListCollectionView {
            guard !isGuestListLoading,
                  attendees.indices.contains(indexPath.item)
            else { return }

            _ = attendees[indexPath.item]
        } else if collectionView == lineUpCollectionView {
            if isLineupMoreItem(at: indexPath) {
                showLineupSheet()
                return
            }

            guard artists.indices.contains(indexPath.item) else { return }

            let artistData = artists[indexPath.item]
            let webUrl = artistData.artist.instagramUsername
            if !webUrl.isEmpty, let url = URL(string: webUrl) {
                AppHaptic.navigation()
                UIApplication.shared.open(url)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        if collectionView == guestListCollectionView {
            return CGSize(width: 40, height: 40)
        } else {
            return CGSize(width: lineupChipSize, height: 100)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == lineUpCollectionView {
            return lineupChipSpacing(for: collectionView)
        }

        return 12
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {

        if collectionView == lineUpCollectionView {
            let inset = lineupChipSideInset(for: collectionView)
            return UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        }

        return .zero
    }
}

extension EventDetailsVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {

        if tableView == ticketTableView {
            return tickets.count
        }

        if tableView == groupTableView {
            return groupedNormalTickets.count
        }

        if tableView == faqsTableView {
            return faqs.count
        }
        
        if tableView == additionalButtonsTableView {
            return enabledAdditionalButtons.count
        }

        return 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if tableView == ticketTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketsTVC.identifier,
                for: indexPath
            ) as? TicketsTVC else {
                return UITableViewCell()
            }

            cell.selectionStyle = .none
            cell.hideShimmer()
            cell.isFromGroupTicket = false

            let ticket = tickets[indexPath.row]
            let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
            let currencyPosition = venueDetails?.venueSettings?.currencyPosition
            let isExpanded = expandedTicketDescriptions.contains(ticket.id ?? "")

            cell.configure(
                ticket: ticket,
                currency: currency,
                currencyPosition: currencyPosition,
                whiteLabelColor: event?.whiteLabelColor,
                eventTicketSetting: event?.eventTicketSettings,
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
                self?.handleRSVP(ticket: ticket)
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
                self.updateTicketTableHeight()
            }

            return cell
        }

        if tableView == groupTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GroupTicketTVC.identifier,
                for: indexPath
            ) as? GroupTicketTVC else {
                return UITableViewCell()
            }

            let item = groupedNormalTickets[indexPath.row]
            let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"
            let currencyPosition = venueDetails?.venueSettings?.currencyPosition
            
            cell.configure(
                groupName: item.groupName,
                tickets: item.tickets,
                currency: currency,
                currencyPosition: currencyPosition,
                whiteLabelColor: event?.whiteLabelColor,
                eventTicketSetting: event?.eventTicketSettings,
                expandedTicketDescriptions: expandedTicketDescriptions,
                disabledTicketIds: disabledTicketIds,
                isExpanded: expandedGroupIds.contains(item.groupId),
                topSpacing: indexPath.row == 0 ? 0 : 16
            )

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

            cell.onExpandChanged = { [weak self] isExpanded in
                guard let self = self else { return }

                if isExpanded {
                    self.expandedGroupIds.insert(item.groupId)
                } else {
                    self.expandedGroupIds.remove(item.groupId)
                }
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
        
        if tableView == additionalButtonsTableView {

            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AdditionalButtonsTableViewCell.identifier,
                for: indexPath
            ) as? AdditionalButtonsTableViewCell else {
                return UITableViewCell()
            }

            let buttons = enabledAdditionalButtons
            let item = buttons[indexPath.row]

            cell.selectionStyle = .none

            let tintColor = UIColor(hex: Event.normalizedHexColor(event?.whiteLabelColor))

            cell.configure(with: item, tintColor: tintColor)
            cell.onTap = { [weak self] in
                self?.openAdditionalButton(item)
            }

            return cell
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FAQsTableViewCell.identifier,
            for: indexPath
        ) as? FAQsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none

        let faq = faqs[indexPath.row]
        let isExpanded = expandedFAQIndex == indexPath.row

        cell.configure(
            title: faq.title ?? "",
            content: faq.content?.fromHTML ?? "",
            isExpanded: isExpanded
        )

        cell.onToggle = { [weak self] in
            guard let self = self else { return }

            let previousExpandedIndex = self.expandedFAQIndex

            if self.expandedFAQIndex == indexPath.row {
                self.expandedFAQIndex = nil
            } else {
                self.expandedFAQIndex = indexPath.row
            }

            var indexPaths: [IndexPath] = [indexPath]

            if let previousExpandedIndex,
               previousExpandedIndex != indexPath.row {
                indexPaths.append(IndexPath(row: previousExpandedIndex, section: 0))
            }

            UIView.performWithoutAnimation {
                self.faqsTableView.reloadRows(at: indexPaths, with: .none)
            }

            self.faqsTableView.beginUpdates()
            self.faqsTableView.endUpdates()

            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseInOut, .allowUserInteraction]
            ) {
                self.faqsTableView.layoutIfNeeded()
                self.faqsTableViewHeight.constant = self.faqsTableView.contentSize.height
                self.view.layoutIfNeeded()
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == additionalButtonsTableView {
            let buttons = enabledAdditionalButtons
            guard buttons.indices.contains(indexPath.row) else { return }
            AppHaptic.navigation()
            openAdditionalButton(buttons[indexPath.row])
            return
        }

        if tableView == faqsTableView {
            AppHaptic.selectionChanged()
            if expandedFAQIndex == indexPath.row {
                expandedFAQIndex = nil
            } else {
                expandedFAQIndex = indexPath.row
            }

            tableView.reloadData()
            return
        }

        guard tableView == ticketTableView else { return }

          let ticket = tickets[indexPath.row]
          if ticket.price == 0 {
              return
          }

          guard !isTicketDisabledByLink(ticket) else { return }

          let currentCount = ticket.selectedTicketCount ?? 0
          guard currentCount == 0 else { return }

          handlePlus(ticket: ticket)
    }
}

private extension EventDetailsVC {

    var enabledAdditionalButtons: [AdditionalButton] {
        event?.additionalButtons?.filter { button in
            button.isEnable &&
            !button.link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } ?? []
    }

    func openAdditionalButton(_ button: AdditionalButton) {
        let link = button.link.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = normalizedAdditionalButtonURL(from: link) else {
            AppHaptic.error()
            Alert.showToast("Invalid link")
            return
        }

        AppHaptic.navigation()
        UIApplication.shared.open(url)
    }

    func normalizedAdditionalButtonURL(from link: String) -> URL? {
        guard !link.isEmpty else { return nil }

        if let url = URL(string: link),
           url.scheme != nil {
            return url
        }

        return URL(string: "https://\(link)")
    }
}

extension EventDetailsVC {
    
    func setupImagePager() {
        let gallery = (event?.eventGallery ?? [])
            .filter { $0.status == "ENABLED" && $0.isDeleted == false }
        
        let images = gallery.map { $0.key.imageURL }
        
        guard !images.isEmpty else {
            imageListHiddenView.isHidden = true
            stopAutoScroll()
            return
        }
        
        imageListHiddenView.isHidden = false
        
        if let pagerVC = imagePagerVC {
            pagerVC.setImages(images)
            startAutoScrollIfNeeded()
            return
        }
        
        let pagerVC = ImagePagerVC(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pagerVC.setImages(images)
        
        addChild(pagerVC)
        pagerVC.view.frame = imageListView.bounds
        pagerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageListView.addSubview(pagerVC.view)
        pagerVC.didMove(toParent: self)
        
        imagePagerVC = pagerVC
        
        startAutoScrollIfNeeded()
    }
    
    private func startAutoScrollIfNeeded() {
        stopAutoScroll()

        guard let pagerVC = imagePagerVC,
              pagerVC.imageURLs.count > 1 else { return }

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self,
                      let pager = self.imagePagerVC else { return }

                pager.moveNext()
            }
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
}

extension EventDetailsVC: YTPlayerViewDelegate {

    func setupYouTubePlayer() {
        if let playerView {
            playerView.delegate = self
            return
        }

        let playerView = YTPlayerView()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.delegate = self

        youTubePlayerView.addSubview(playerView)
        self.playerView = playerView

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: youTubePlayerView.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: youTubePlayerView.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: youTubePlayerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: youTubePlayerView.trailingAnchor)
        ])
        youTubePlayerView.bringSubviewToFront(youTubeShimmerView)
    }

    func youtubePlayerVars() -> [AnyHashable: Any] {
        [
            "playsinline": 1,
            "autoplay": 0,
            "controls": 1,
            "modestbranding": 1,
            "rel": 0
        ]
    }

    func extractVideoID(from url: String) -> String? {
        guard let components = URLComponents(string: url) else {
            return nil
        }

        if let id = components.queryItems?
            .first(where: { $0.name == "v" })?
            .value,
           !id.isEmpty {
            return id
        }

        let pathComponents = components.path
            .split(separator: "/")
            .map(String.init)

        if components.host?.contains("youtu.be") == true {
            return pathComponents.first
        }

        if let markerIndex = pathComponents.firstIndex(where: {
            $0 == "embed" || $0 == "shorts"
        }),
           pathComponents.indices.contains(markerIndex + 1) {
            return pathComponents[markerIndex + 1]
        }

        return nil
    }

    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        isYouTubePlayerReady = true
        hideYouTubeShimmer()
    }

    func playerView(
        _ playerView: YTPlayerView,
        receivedError error: YTPlayerError
    ) {
        hideYouTubeShimmer()
    }
}

extension EventDetailsVC: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === navigationController?.interactivePopGestureRecognizer {
            return (navigationController?.viewControllers.count ?? 0) > 1
        }

        if let leftEdgeBackGesture,
           gestureRecognizer === leftEdgeBackGesture {
            return isPresentedAsRootNavigationScreen &&
                !isBackNavigationInProgress &&
                !hasReleasedHeavyResources
        }

        return true
    }
}

private final class EventDetailsMapAnnotation: NSObject {

    let coordinate: CLLocationCoordinate2D
    let title: String?
    let imageURL: String?
    let searchQuery: String?

    init(
        coordinate: CLLocationCoordinate2D,
        title: String?,
        imageURL: String?,
        searchQuery: String?
    ) {
        self.coordinate = coordinate
        self.title = title
        self.imageURL = imageURL
        self.searchQuery = searchQuery
        super.init()
    }
}

private final class EventDetailsLocationMarkerView: UIView {

    private enum Layout {
        static let markerSize: CGFloat = 40
        static let logoSize: CGFloat = 30
    }

    private let backgroundImageView = UIImageView()
    private let dimView = UIView()
    private let logoContainerView = UIView()
    private let logoImageView = UIImageView()

    init(
        backgroundImageURL: String?,
        logoImageURL: String?
    ) {
        super.init(
            frame: CGRect(
                x: 0,
                y: 0,
                width: Layout.markerSize,
                height: Layout.markerSize
            )
        )
        setup()
        configure(
            backgroundImageURL: backgroundImageURL,
            logoImageURL: logoImageURL
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)

        backgroundImageView.frame = bounds
        backgroundImageView.clipsToBounds = true
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.layer.cornerRadius = Layout.markerSize / 2
        backgroundImageView.image = UIImage(named: "newSpeakeasy")
        addSubview(backgroundImageView)

        dimView.frame = bounds
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dimView.clipsToBounds = true
        dimView.layer.cornerRadius = Layout.markerSize / 2
        addSubview(dimView)

        logoContainerView.frame = CGRect(
            x: (Layout.markerSize - Layout.logoSize) / 2,
            y: (Layout.markerSize - Layout.logoSize) / 2,
            width: Layout.logoSize,
            height: Layout.logoSize
        )
//        logoContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.34)
//        logoContainerView.layer.cornerRadius = Layout.logoSize / 2
//        logoContainerView.clipsToBounds = true
        addSubview(logoContainerView)

        logoImageView.frame = logoContainerView.bounds.insetBy(dx: 3, dy: 3)
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(named: "newSpeakeasy")
        logoContainerView.addSubview(logoImageView)
    }

    private func configure(
        backgroundImageURL: String?,
        logoImageURL: String?
    ) {
        let scale = UIScreen.main.scale
        let backgroundSize = CGSize(
            width: Layout.markerSize * scale,
            height: Layout.markerSize * scale
        )
        let logoSize = CGSize(
            width: Layout.logoSize * scale,
            height: Layout.logoSize * scale
        )

        backgroundImageView.sd_setImage(
            with: URL(string: backgroundImageURL ?? ""),
            placeholderImage: UIImage(named: "newSpeakeasy"),
            options: [.continueInBackground, .scaleDownLargeImages],
            context: [.imageThumbnailPixelSize: NSValue(cgSize: backgroundSize)]
        )

        logoImageView.sd_setImage(
            with: URL(string: logoImageURL ?? ""),
            placeholderImage: UIImage(named: "newSpeakeasy"),
            options: [.continueInBackground, .scaleDownLargeImages],
            context: [.imageThumbnailPixelSize: NSValue(cgSize: logoSize)]
        )
    }

    deinit {
        backgroundImageView.sd_cancelCurrentImageLoad()
        logoImageView.sd_cancelCurrentImageLoad()
    }
}

private extension CLLocationCoordinate2D {
    static func valid(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees
    ) -> CLLocationCoordinate2D? {
        guard CLLocationCoordinate2DIsValid(
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        ) else {
            return nil
        }

        guard latitude != 0 || longitude != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


final class EventDetailsSkeletonView: UIView {

    private var allShimmerViews: [ShimmerViewV3] = []
    private var lastLayoutWidth: CGFloat = 0
    private var isShimmering = false

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }
        guard abs(bounds.width - lastLayoutWidth) > 1 else { return }
        lastLayoutWidth = bounds.width
        setupUI()
    }

    private func setupUI() {
        allShimmerViews.forEach { $0.removeFromSuperview() }
        allShimmerViews.removeAll()

        backgroundColor = .clear

        let W = bounds.width
        let pad: CGFloat = 16
        let contentWidth = max(0, W - pad * 2)
        var y: CGFloat = 0

        // ─────────────────────────────
        // 1. VIP Banner
        // ─────────────────────────────

        let bannerWidth = contentWidth
        let bannerHeight: CGFloat = 60

        make(
            CGRect(x: pad, y: y, width: bannerWidth, height: bannerHeight),
            corner: 10
        )

        makeLighter(
            CGRect(x: pad + 12, y: y + 12, width: 81, height: 19),
            corner: 9
        )

        makeLighter(
            CGRect(x: pad + 12, y: y + 34, width: 130, height: 12),
            corner: 6
        )

        let buttonWidth: CGFloat = 91
        let buttonHeight: CGFloat = 31

        makeLighter(
            CGRect(
                x: pad + bannerWidth - 12 - buttonWidth,
                y: y + (bannerHeight - buttonHeight) / 2,
                width: buttonWidth,
                height: buttonHeight
            ),
            corner: 15
        )

        y += bannerHeight + 24
        // ─────────────────────────────
        // 2. DETAILS SECTION
        // ─────────────────────────────
        make(CGRect(x: pad, y: y, width: 80, height: 14), corner: 6)
        y += 24

        make(CGRect(x: pad, y: y, width: contentWidth * 0.7, height: 10), corner: 5)
        y += 16
        make(CGRect(x: pad, y: y, width: contentWidth * 0.5, height: 10), corner: 5)

        y += 28
//
//        make(CGRect(x: pad, y: y, width: 60, height: 12), corner: 6)
//        y += 20
//
//        make(CGRect(x: pad, y: y, width: W * 0.4, height: 10), corner: 5)
//
//        y += 32

        // ─────────────────────────────
        // 3. GUEST LIST
        // ─────────────────────────────
        let avatarSize: CGFloat = 26

        for i in 0..<3 {
            make(CGRect(
                x: pad + CGFloat(i) * (avatarSize + 8),
                y: y,
                width: avatarSize,
                height: avatarSize
            ), corner: avatarSize/2)
        }

        make(CGRect(x: pad + contentWidth - 80, y: y + 8, width: 80, height: 10), corner: 5)

        y += avatarSize + 24
        
        // ─────────────────────────────
        // 5. CONTINUE BUTTON SKELETON
        // ─────────────────────────────

        let continueBtnHeight: CGFloat = 44

        make(
            CGRect(
                x: pad,
                y: y,
                width: contentWidth,
                height: continueBtnHeight
            ),
            corner: 22
        )

        y += continueBtnHeight + 33

        // ─────────────────────────────
        // 4. DESCRIPTION
        // ─────────────────────────────
//        make(CGRect(x: pad, y: y, width: W * 0.9, height: 10), corner: 5)
//        y += 16
//        make(CGRect(x: pad, y: y, width: W * 0.8, height: 10), corner: 5)
//        y += 16
//        make(CGRect(x: pad, y: y, width: W * 0.6, height: 10), corner: 5)
//
//        y += 30

//        // ─────────────────────────────
//        // 5. BOTTOM BAR (PRICE + BUTTON)
//        // ─────────────────────────────
//        make(CGRect(x: pad, y: y, width: 100, height: 10), corner: 5)
//        make(CGRect(x: pad, y: y + 14, width: 70, height: 8), corner: 5)
//
//        make(CGRect(x: W - pad - 80, y: y, width: 80, height: 30), corner: 15)

        if isShimmering {
            allShimmerViews.forEach { $0.startShimmer() }
        }
    }

    // MARK: - Helpers (same as Home)

    private func make(_ frame: CGRect, corner: CGFloat = 8) {
        let sv = ShimmerViewV3(frame: frame)
        sv.layer.cornerRadius = corner
        sv.clipsToBounds = true
        addSubview(sv)
        allShimmerViews.append(sv)
    }

    private func makeLighter(_ frame: CGRect, corner: CGFloat = 6) {
        let sv = ShimmerViewV3(frame: frame, lighter: true)
        sv.layer.cornerRadius = corner
        sv.clipsToBounds = true
        addSubview(sv)
        allShimmerViews.append(sv)
    }

    // MARK: - Control

    func startShimmer() {
        isShimmering = true
        isHidden = false
        allShimmerViews.forEach { $0.startShimmer() }
    }

    func stopShimmer() {
        isShimmering = false
        allShimmerViews.forEach { $0.stopShimmer() }
        isHidden = true
    }

    func releaseResources() {
        stopShimmer()
        allShimmerViews.forEach { $0.removeFromSuperview() }
        allShimmerViews.removeAll()
        lastLayoutWidth = 0
    }
}

final class EventPosterHeaderView: UIView {

    enum BackgroundStyle {
        case standard
        case abstractColorWash
        case softColorWash
    }

    private let screenBackgroundColor = UIColor(hex: "#121212")

    private let backgroundImageView = UIImageView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let darkOverlayView = UIView()
    private var representedImageURLString: String?
    private var isLoadingImage = false

    private let bottomGradientView = UIView()
    private let bottomGradientLayer = CAGradientLayer()
    private var backgroundStyle: BackgroundStyle = .abstractColorWash

    private var imageAlpha: CGFloat {
        switch backgroundStyle {
        case .standard:
            return 0.75
        case .abstractColorWash:
            return 0.78
        case .softColorWash:
            return 0.92
        }
    }

    private var blurAlpha: CGFloat {
        switch backgroundStyle {
        case .standard:
            return 0.90
        case .abstractColorWash:
            return 1.0
        case .softColorWash:
            return 0.82
        }
    }

    private var overlayAlpha: CGFloat {
        switch backgroundStyle {
        case .standard:
            return 0.35
        case .abstractColorWash:
            return 0.46
        case .softColorWash:
            return 0.22
        }
    }

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
        
        setupBlurredBackground()
        setupBottomGradient()
    }
    
    private func setupBlurredBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.alpha = imageAlpha
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundImageView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor, constant: -30),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -30),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 30),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 20)
        ])
        
        blurView.alpha = blurAlpha
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        darkOverlayView.backgroundColor = UIColor.black.withAlphaComponent(overlayAlpha)
        darkOverlayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(darkOverlayView)
        
        NSLayoutConstraint.activate([
            darkOverlayView.topAnchor.constraint(equalTo: topAnchor),
            darkOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            darkOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            darkOverlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupBottomGradient() {
        bottomGradientView.isUserInteractionEnabled = false
        bottomGradientView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomGradientView)
        
        NSLayoutConstraint.activate([
            bottomGradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomGradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomGradientView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomGradientView.topAnchor.constraint(equalTo: topAnchor) // full screen
        ])

        bottomGradientView.layer.addSublayer(bottomGradientLayer)
        updateBottomGradient()
    }

    private func updateBottomGradient() {
        switch backgroundStyle {
        case .softColorWash:
            bottomGradientLayer.colors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.24).cgColor,
                UIColor.black.withAlphaComponent(0.78).cgColor,
                UIColor.black.cgColor
            ]
            bottomGradientLayer.locations = [0.0, 0.48, 0.78, 1.0]
        case .abstractColorWash:
            bottomGradientLayer.colors = [
                UIColor.clear.cgColor,
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.76).cgColor,
                UIColor.black.cgColor
            ]
            bottomGradientLayer.locations = [0.0, 0.42, 0.70, 1.0]
        case .standard:
            bottomGradientLayer.colors = [
                UIColor.clear.cgColor,
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.60).cgColor,
                UIColor.black.cgColor
            ]
            bottomGradientLayer.locations = [0.0, 0.50, 0.75, 1.0]
        }

        bottomGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        bottomGradientLayer.endPoint  = CGPoint(x: 0.5, y: 1.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bottomGradientLayer.frame = bottomGradientView.bounds
    }
    
    func setBackgroundImage(_ image: UIImage?) {
        backgroundImageView.image = image
    }
    
    func applyBackgroundStyle(_ style: BackgroundStyle) {
        backgroundStyle = style
        backgroundImageView.alpha = imageAlpha
        blurView.alpha = blurAlpha
        darkOverlayView.backgroundColor = UIColor.black.withAlphaComponent(overlayAlpha)
        updateBottomGradient()
    }

    func loadImage(from urlString: String) {
        let normalizedURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        if representedImageURLString == normalizedURLString,
           isLoadingImage || backgroundImageView.image != nil {
            return
        }

        backgroundImageView.sd_cancelCurrentImageLoad()
        representedImageURLString = normalizedURLString

        guard !normalizedURLString.isEmpty, let url = URL(string: normalizedURLString) else {
            isLoadingImage = false
            setBackgroundImage(nil)
            return
        }

        isLoadingImage = true
        let requestedURLString = normalizedURLString
        let shouldAnimate = backgroundImageView.image == nil
        let scale = UIScreen.main.scale
        let targetSize: CGSize

        switch backgroundStyle {
        case .standard:
            targetSize = CGSize(
                width: max(bounds.width, UIScreen.main.bounds.width) * scale,
                height: max(bounds.height, 360) * scale
            )
        case .abstractColorWash:
            targetSize = CGSize(
                width: 12,
                height: 20
            )
        case .softColorWash:
            targetSize = CGSize(
                width: 32,
                height: 56
            )
        }

        backgroundImageView.alpha = shouldAnimate ? 0 : imageAlpha

        backgroundImageView.sd_setImage(
            with: url,
            placeholderImage: backgroundImageView.image,
            options: [.continueInBackground, .highPriority, .scaleDownLargeImages],
            context: [.imageThumbnailPixelSize: NSValue(cgSize: targetSize)], progress: nil,
            completed: { [weak self] image, _, _, _ in
                guard let self,
                      self.representedImageURLString == requestedURLString else {
                    return
                }

                self.isLoadingImage = false

                guard image != nil else {
                    self.representedImageURLString = nil
                    self.backgroundImageView.alpha = self.imageAlpha
                    return
                }

                guard shouldAnimate else {
                    self.backgroundImageView.alpha = self.imageAlpha
                    return
                }

                UIView.animate(
                    withDuration: 0.22,
                    delay: 0,
                    options: [.curveEaseOut]
                ) {
                    self.backgroundImageView.alpha = self.imageAlpha
                }
            }
        )
    }

    func cancelImageLoad() {
        representedImageURLString = nil
        isLoadingImage = false
        backgroundImageView.sd_cancelCurrentImageLoad()
        backgroundImageView.layer.removeAllAnimations()
        backgroundImageView.image = nil
    }

    deinit {
        cancelImageLoad()
    }
}

extension EventDetailsVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }

        updateNavPosition(for: scrollView.contentOffset.y)
        
        let shouldCollapse = scrollView.contentOffset.y > collapseThreshold
        
        if shouldCollapse != isCollapsed {
            isCollapsed = shouldCollapse
            applyNavAppearance(collapsed: shouldCollapse)
        }
    }
}

private extension EventDetailsVC {

    func setupGalleryGrid() {
        cancelImageLoads(in: imageListView)
        imageListView.subviews.forEach { $0.removeFromSuperview() }

        let gallery = (event?.eventGallery ?? [])
            .filter { $0.status == "ENABLED" && $0.isDeleted == false }

        galleryImageURLs = gallery.map { $0.key.imageURL }

        guard !galleryImageURLs.isEmpty else {
            imageListHiddenView.isHidden = true
            imageListViewHeightConstraint.constant = 0
            return
        }

        imageListHiddenView.isHidden = false

        view.layoutIfNeeded()
        imageListView.layoutIfNeeded()

        let spacing: CGFloat = 10
        let visibleCount = min(galleryImageURLs.count, 4)

        let itemWidth = floor((imageListView.bounds.width - spacing) / 2)
        let itemHeight = itemWidth

        let rowCount = ceil(CGFloat(visibleCount) / 2)
        imageListViewHeightConstraint.constant =
            (rowCount * itemHeight) + ((rowCount - 1) * spacing)

        for index in 0..<visibleCount {
            let row = CGFloat(index / 2)
            let column = CGFloat(index % 2)

            let x = column * (itemWidth + spacing)
            let y = row * (itemHeight + spacing)

            let imageContainer = UIView(frame: CGRect(
                x: x,
                y: y,
                width: itemWidth,
                height: itemHeight
            ))

            imageContainer.clipsToBounds = true
            imageContainer.layer.cornerRadius = 16
            imageContainer.tag = index
            imageContainer.isUserInteractionEnabled = true

            let imageView = UIImageView(frame: imageContainer.bounds)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            let scale = UIScreen.main.scale
            let targetSize = CGSize(
                width: itemWidth * scale,
                height: itemHeight * scale
            )

            imageView.sd_setImage(
                with: URL(string: galleryImageURLs[index]),
                placeholderImage: Constant.Icon.uploadImage,
                options: [.continueInBackground, .scaleDownLargeImages],
                context: [.imageThumbnailPixelSize: NSValue(cgSize: targetSize)]
            )

            imageContainer.addSubview(imageView)

            if index == 3 && galleryImageURLs.count > 4 {
                addViewMoreButton(to: imageContainer, moreCount: galleryImageURLs.count - 4)
            }

            let tap = UITapGestureRecognizer(
                target: self,
                action: #selector(onGalleryImageTap(_:))
            )
            imageContainer.addGestureRecognizer(tap)

            imageListView.addSubview(imageContainer)
        }

        view.layoutIfNeeded()
    }

    func addViewMoreButton(to parentView: UIView, moreCount: Int) {
        let buttonView = UIView()
        buttonView.backgroundColor = UIColor.white
        buttonView.layer.borderWidth = 1
        buttonView.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        buttonView.layer.cornerRadius = 18
        buttonView.clipsToBounds = true
        buttonView.translatesAutoresizingMaskIntoConstraints = false

        parentView.addSubview(buttonView)

        NSLayoutConstraint.activate([
            buttonView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -12),
            buttonView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -10),
            buttonView.heightAnchor.constraint(equalToConstant: 36),
            buttonView.widthAnchor.constraint(greaterThanOrEqualToConstant: 86)
        ])

        let label = UILabel()
        label.text = "+\(moreCount) more"
        label.textColor = .black
        label.font = Constant.Font.geistSemiBold(size: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        buttonView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: buttonView.topAnchor),
            label.leadingAnchor.constraint(equalTo: buttonView.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: buttonView.trailingAnchor, constant: -14),
            label.bottomAnchor.constraint(equalTo: buttonView.bottomAnchor)
        ])
    }

    @objc func onGalleryImageTap(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }

        AppHaptic.cardOpen()
        if index == 3 && galleryImageURLs.count > 4 {
            openGalleryScreen(selectedIndex: index)
        } else {
            openImagePreview(selectedIndex: index)
        }
    }

    func openGalleryScreen(selectedIndex: Int) {
        let vc = EventGalleryVC()
        vc.imageURLs = galleryImageURLs
        vc.selectedIndex = selectedIndex
        navigationController?.pushViewController(vc, animated: true)
    }

    func openImagePreview(selectedIndex: Int) {
        let vc = EventGalleryVC()
        vc.imageURLs = galleryImageURLs
        vc.selectedIndex = selectedIndex
        navigationController?.pushViewController(vc, animated: true)
    }
}

import UIKit

final class EventGalleryImageCell: UICollectionViewCell {

    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 16

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(urlString: String) {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: max(bounds.width, 160) * scale,
            height: max(bounds.height, 160) * scale
        )

        imageView.sd_setImage(
            with: URL(string: urlString),
            placeholderImage: Constant.Icon.uploadImage,
            options: [.continueInBackground, .scaleDownLargeImages],
            context: [.imageThumbnailPixelSize: NSValue(cgSize: targetSize)]
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
    }

    deinit {
        imageView.sd_cancelCurrentImageLoad()
    }
}

final class EventGalleryVC: UIViewController {

    var imageURLs: [String] = []
    var selectedIndex: Int = 0
    var galleryTitle: String = "Gallery"

    private let backBtn = AppIconButton()
    private let titleLabel = UILabel()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.register(EventGalleryImageCell.self, forCellWithReuseIdentifier: EventGalleryImageCell.identifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    deinit {
        imageURLs.removeAll()

        if isViewLoaded {
            collectionView.delegate = nil
            collectionView.dataSource = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        scrollToSelectedIndex()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    private func setupUI() {
        setupNav()
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
    }

    private func setupNav() {
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 14
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)

        titleLabel.text = galleryTitle
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.widthAnchor.constraint(equalToConstant: 40),
            backBtn.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            collectionView.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func scrollToSelectedIndex() {
        guard selectedIndex < imageURLs.count else { return }
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        }
    }

    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }
}

extension EventGalleryVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: EventGalleryImageCell.identifier,
            for: indexPath
        ) as? EventGalleryImageCell else {
            return UICollectionViewCell()
        }
        cell.configure(urlString: imageURLs[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let spacing: CGFloat = 10
        let sidePadding: CGFloat = 16
        let itemWidth = floor((collectionView.bounds.width - sidePadding * 2 - spacing) / 2)
        return CGSize(width: itemWidth, height: itemWidth)
    }
}

extension EventDetailsVC: CheckoutBarDelegate {

    func checkoutBarDidTapButton() {

        guard LoginRequiredCoordinator.isAuthenticated else {
            AppHaptic.warning()
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                self?.checkoutBarDidTapButton()
            }
            return
        }

        guard let user = UserDefault.shared.user else { return }
        guard let event else { return }

        let selectedNormalTickets = normalTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
        let selectedGroupedTickets = groupedNormalTickets
            .flatMap { $0.tickets }
            .filter { ($0.selectedTicketCount ?? 0) > 0 }
        let selectedTickets = selectedNormalTickets + selectedGroupedTickets

        guard !selectedTickets.isEmpty else {
            AppHaptic.warning()
            Alert.showToast("Please select at least one ticket")
            return
        }

        AppHaptic.primaryAction()

        if hasVisibleAddOnOptions(for: event) {
            shouldClearInlineRSVPSelectionOnReturn = true
            Navigate.to.ticketSelectionVc(
                self,
                event: event,
                mode: .addOn,
                selectedNormalTickets: selectedTickets,
                promotionLinkId: promoteId,
                promotionLinkUniqueCode: promotionLinkUniqueCode
            )
            return
        }

        checkOutBtnView.showLoader()

        let payload: [[String: Any]] = selectedTickets.map {
            ["ticketId": $0.id ?? "", "ticketQuantity": $0.selectedTicketCount ?? 0, "ticketPrice": $0.price ?? 0]
        }

        paymentService.createEventBooking(
            eventId: event.id,
            code: user.code,
            phone: user.phone,
            gender: user.gender,
            userId: user.id,
            tickets: payload,
            promotionLinkId: promoteId,
            promotionLinkUniqueCode: promotionLinkUniqueCode
        ) { [weak self] isSuccess, errMsg, bookingId, _ in
            guard let self else { return }

            self.checkOutBtnView.hideLoader()
            if isSuccess {
                AppHaptic.success()
                self.shouldClearInlineRSVPSelectionOnReturn = true
                Navigate.orderListVC(
                    self,
                    event: event,
                    selectedTickets: selectedTickets,
                    bookingId: bookingId,
                    paymentMethod: nil,
                    venueDetails: venueDetails,
                    promotionLinkId: promoteId,
                    promotionLinkUniqueCode: promotionLinkUniqueCode
                )
            } else {
                AppHaptic.error()
                Alert.showToast(errMsg ?? "Something went wrong")
            }
        }
    }
}

// MARK: - WebSocket

extension EventDetailsVC: WebSocketCallBackDelegate {

    func didUpdateEvent(eventId: String) {
        guard isCurrentEventUpdate(eventId) else { return }
        refreshEventDetailFromSocket()
    }

    func didUpdateEventTicketSoldCount(_ update: EventTicketSoldCountUpdate) {
        applySoldCountUpdate(update)
    }
}

private extension EventDetailsVC {

    func isCurrentEventUpdate(_ eventId: String) -> Bool {
        eventId == event?.uniqueId ||
        eventId == event?.id ||
        eventId == uniqueId
    }

    func refreshEventDetailFromSocket() {
        isEventDetailAPICalled = false
        getEventDetail(showLoading: false)
    }

    func registerSocketDelegate() {
        if let venueId = venueDetails?.id ?? event?.venue?.id {
            WebSocketWrapper.shared.updateSocketContext(venueId: venueId)
        }

        WebSocketWrapper.shared.removeDelegate(self)
        WebSocketWrapper.shared.addDelegate(self)
    }

    func unregisterSocketDelegate() {
        WebSocketWrapper.shared.removeDelegate(self)
    }
}
