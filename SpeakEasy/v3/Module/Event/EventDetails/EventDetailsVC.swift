//
//  EventDetailsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 05/02/26.
//
// swiftlint: disable all

import UIKit
import MapKit
import YouTubeiOSPlayerHelper
import Hero
import MHLoadingButton

class EventDetailsVC: UIViewController {

    @IBOutlet weak var guestListCollectionView: UICollectionView!
    @IBOutlet weak var detailsLbl: UILabel!
    @IBOutlet weak var youTubePlayerView: UIView!
    @IBOutlet weak var imageListView: UIView!
    @IBOutlet weak var lineUpCollectionView: UICollectionView!
    @IBOutlet weak var policyLbl: UILabel!
    @IBOutlet weak var faqsTableView: UITableView!
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var venueAddressLbl: UILabel!
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
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
    private var playerView: YTPlayerView!
    private var isExpanded = false
    private var isPolicyLblExpanded = false
    private let collapsedLines = 5
    private var fullText = ""
    private var faqsTableObserver: NSKeyValueObservation?
    private var ticketTableObserver: NSKeyValueObservation?
    private var groupTableObserver: NSKeyValueObservation?
    private var additionalButtonsTableObserver: NSKeyValueObservation?

    var venueDetails: ClipVenue?
    var event: Event?
    var uniqueId: String? = ""
    var promoteId = ""
    var heroSuffix: String = ""
    private var eventTicketId = [String]()
    private var artists = [ArtistData]()

    private var tickets: [EventTicket] = []
    private var normalTickets: [EventTicket] = []
    private var groupedNormalTickets: [(groupName: String, tickets: [EventTicket])] = []
    private var expandedTicketDescriptions: Set<String> = []
    private var ticketLinks: [EventTicketLink] = []
    private var disabledTicketIds: Set<String> = []

    private var attendees: [Attendee] = []
    private var totalAttendees = 0
    private var skeletonView: SkeletonOverlayView?
    private var isLoading = false
    var heroIndex: Int = 0
    private var faqs: [EventFAQ] = []
    private var expandedFAQIndex: Int?
    private var autoScrollTimer: Timer?
    private var isEventDetailAPICalled = false
    private var isSaved: Bool = false
    private var isSaveLoading: Bool = false
    private let posterHeaderView = EventPosterHeaderView()
    private let collapseThreshold: CGFloat = 20
    private var isCollapsed = false
    private var galleryImageURLs: [String] = []
    private var galleryImageViews: [UIImageView] = []
    private var galleryOverlayView: UIView?
    private var galleryMoreLabel: UILabel?
    
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
        mainImg.sd_setImage(
            with: URL(string: imageURLString),
            placeholderImage: Constant.Icon.uploadImage
        )

        posterHeaderView.loadImage(from: imageURLString)
        setupMainImageStyle()
        scrollView.contentInsetAdjustmentBehavior = .never


        hero.isEnabled = true
        scrollView.delegate = self
        fetchSeatingAreas()
        getEventDetail()
        
        setupData()
        setupCollectionViews()
        setupTableView()
        startTicketTableObserver()
        startGroupTableObserver()
        startFAQsTableObserver()
        startAdditionalButtonsTableObserver()
        setupUI()
        setupSkeletonView()
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

        updateCheckoutSummaryView()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAutoScrollIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
               self.mainImg.hero.id  = nil
               self.titleLbl.hero.id   = nil
           }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        hero.isEnabled = true
        navigationController?.hero.isEnabled = true
        mainImg.hero.id = "event.image.\(event?.id ?? "").\(heroSuffix)"
        titleLbl.hero.id = "event.title.\(event?.id ?? "").\(heroSuffix)"
    }

    deinit {
        ticketTableObserver?.invalidate()
        groupTableObserver?.invalidate()
        faqsTableObserver?.invalidate()
        stopAutoScroll()
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
        imageBackGroundView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: imageBackGroundView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: imageBackGroundView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: imageBackGroundView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: imageBackGroundView.bottomAnchor)
        ])
    }

    private func startTicketTableObserver() {
        ticketTableObserver?.invalidate()

        ticketTableObserver = ticketTableView.observe(\.contentSize, options: [.new]) { [weak self] tableView, _ in
            guard let self = self else { return }
            self.ticketTableHeightConstraint.constant = tableView.contentSize.height
            self.view.layoutIfNeeded()
        }
    }

    private func startGroupTableObserver() {
        groupTableObserver?.invalidate()

        groupTableObserver = groupTableView.observe(\.contentSize, options: [.new]) { [weak self] tableView, _ in
            guard let self = self else { return }
            self.groupTableViewHeight.constant = tableView.contentSize.height
            self.view.layoutIfNeeded()
        }
    }
    
    private func startAdditionalButtonsTableObserver() {

        additionalButtonsTableObserver?.invalidate()

        additionalButtonsTableObserver = additionalButtonsTableView.observe(
            \.contentSize,
             options: [.new]
        ) { [weak self] tableView, _ in

            guard let self = self else { return }

            self.additionalButtonsTableHeight.constant = tableView.contentSize.height
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
        isSaved = venueDetails?.isSaved ?? false
        updateSaveUI()
    }
    
    private func updateSaveUI() {
        let imageName = isSaved ? "ic-bookmark" : "ic-bookmark"
        
        saveBtn.setImage(UIImage(named: imageName), for: .normal)
        saveBtn.tintColor =  .white
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
        let shouldHide = attendees.isEmpty
        
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

    private func getEventDetail() {
        guard !isEventDetailAPICalled else { return }

        guard let eventId = self.event?.uniqueId ?? self.uniqueId else {
            isEventDetailAPICalled = false
            return
        }

        showSkeleton()

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

        checkOutBtnView.updateSummary(
            currency: currency,
            count: totalCount,
            subtotal: subtotal + fees,
            fees: fees
        )

        checkOutBtnView.setButtonTitle(
            "Continue to Checkout"
        )

        showCheckoutBar()
    }
    
    private func showContinueBtn() {
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
    
    private func showCheckoutBar() {

        guard checkOutBtnView.isHidden else {
            return
        }

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
            return
        }

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
    
    private func fetchSeatingAreas() {

        tableService.fetchSeatingAreas(
            eventId: event?.id ?? "",
            skip: 0
        ) { [weak self] isSuccess, errMsg, list, _ in
            
            guard let self else { return }

            if isSuccess {
                let filtered = self.filterSeatingAreas(list)
                self.seatingAreas = list
                self.seatingAreasFilteredOut = filtered.visible
            } else {
                print(errMsg ?? "")
            }
        }
    }

    private func getEventAttendees() {
        guard let eventId = self.event?.uniqueId else {
            return
        }

        eventService.fetchEventAttendees(eventId: eventId) { [weak self] success, _, data, _ in
            guard let self = self else { return }

            if success {
                self.attendees = self.sortAttendeesImageFirst(data ?? [])
                self.totalAttendees = self.attendees.count

                self.guestListCollectionView.reloadData()
                self.updateAttendeesView()

                if let firstAttendee = self.attendees.first {
                    let firstName = firstAttendee.firstName ?? ""
                    let count = self.attendees.count

                    if count == 1 {
                        self.guestListTitleLbl.text = "\(firstName) is going"
                    } else if count > 1 {
                        let othersCount = count - 1
                        let otherText = othersCount == 1 ? "other" : "others"
                        self.guestListTitleLbl.text = "\(firstName) and \(othersCount) \(otherText) going"
                    }
                } else {
                    self.guestListTitleLbl.text = ""
                }
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

    private func setupData() {
        guard let event = event else { return }

        disabledTicketIds.removeAll()

        mainImg.sd_setImage(with: URL(string: (event.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        titleLbl.text = event.title
        fullText = event.description
        setupExpandableLabel()
        setupPolicyExpandableLabel()
        venueName.text = (event.customVenue != nil && venueDetails?.venueSettings?.isOrganizer == true)
            ? "\(event.customVenue?.name ?? "") by \(venueDetails?.name ?? "")".uppercased()
            : "\(venueDetails?.name ?? ""), \(venueDetails?.city ?? "")".uppercased()
        
        venueNameLbl.text = (event.customVenue != nil && venueDetails?.venueSettings?.isOrganizer == true)
        ? "\(event.customVenue?.name ?? event.venue?.name ?? "")".uppercased()
        : "\(venueDetails?.name ?? "")".uppercased()
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

        webSiteView.isHidden = event.additionalButtons?.isEmpty ?? true
        
        configureVIPTablesView()
        setupGalleryGrid()

        let showInlineTickets = event.eventTicketSettings?.showTicketListingOnMainScreen ?? false
        ticketHidenView.isHidden = !showInlineTickets

        if showInlineTickets {
            setupInlineTicketData()
        } else {
            tickets = []
            normalTickets = []
            groupedNormalTickets = []
            ticketTableView.reloadData()
            groupTableView.reloadData()
            ticketTableHeightConstraint.constant = 0
            groupTableViewHeight.constant = 0
            protectedTicketView.isHidden = true
        }

        if let youtubeVideoLink = event.youtubeVideoLink, !youtubeVideoLink.isEmpty {
            youTubeSuperView.isHidden = false
            setupYouTubePlayer()
            if let id = extractVideoID(from: youtubeVideoLink) {
                playerView.load(withVideoId: id)
            }
        } else {
            youTubeSuperView.isHidden = true
        }

        venueLogoImg.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL), completed: nil)
        
        
        if let imageUrlString = venueDetails?.logo?.key.imageURL,
           let url = URL(string: imageUrlString) {
            
            venueLogo.sd_setImage(with: url) { [weak self] _, _, _, _ in
                guard let self = self else { return }

                self.venueLogo.alpha = 0
                self.venueLogo.transform = CGAffineTransform(translationX: -50, y: 0)

                UIView.animate(withDuration: 0.4,
                               delay: 0,
                               options: [.curveEaseOut],
                               animations: {
                    self.venueLogo.isHidden = false
                    self.venueLogo.alpha = 1
                    self.venueLogo.transform = .identity
                }, completion: nil)
            }
        } else {
            venueLogo.isHidden = true
        }
        
        
        let coordinate: CLLocationCoordinate2D
        let title: String

        if let custom = event.customVenue,
           venueDetails?.venueSettings?.isOrganizer == true {
            
            coordinate = CLLocationCoordinate2D(
                latitude: Double(custom.lat ?? "") ?? 0,
                longitude: Double(custom.lng ?? "") ?? 0
            )
            
            title = custom.name ?? "Venue"
            
        } else {
            
            coordinate = CLLocationCoordinate2D(
                latitude: venueDetails?.latitude ?? 0,
                longitude: venueDetails?.longitude ?? 0
            )
            
            title = venueDetails?.name ?? "Venue"
        }

        updateLocationOnMap(to: coordinate, with: title)

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

        if let hexColor = event.whiteLabelColor {
            let color = UIColor(hex: hexColor)
            timingLbl.textColor = color
            checkOutBtn.backgroundColor = color
//            buyNowBtnLbl.textColor = color.suitableTextColor()
            webSiteView.borderColor = color
            checkOutBtn.indicator = MaterialLoadingIndicator(color: .black)
//            checkOutBtn.bgColor = color
//            checkOutBtn.setTitleColor(color.suitableTextColor(), for: .normal)
            
        }

        setupSocialLinks()
        setupTicketsButton()

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
    
    
    
    private func setupTicketsButton() {
        guard let event = event else { return }

        let settings = event.eventTicketSettings
        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"

        // Reset state
        soldOutView.isHidden = true
        soldOutLbl.text = ""
        checkOutBtn.isEnabled = true
        checkOutBtn.isUserInteractionEnabled = true

        guard let tickets = event.eventTicket, !tickets.isEmpty else {
            checkOutBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
            checkOutBtn.isEnabled = false
            checkOutBtn.isUserInteractionEnabled = false
            soldOutView.isHidden = false
            soldOutLbl.text = Constant.String.salePaused.uppercased()
            return
        }

        if event.isPausedSellingAllTickets == true {
            checkOutBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
            checkOutBtn.isEnabled = false
            checkOutBtn.isUserInteractionEnabled = false
            soldOutView.isHidden = false
            soldOutLbl.text = Constant.String.salePaused.uppercased()
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
            return
        }

        if event.isSoldOutAllTickets == true {
            let title = settings?.isSoldOutTextEnabled == true
                ? (settings?.soldOutText ?? "Sold Out!")
                : "Sold Out!"
            checkOutBtn.setTitle(title, for: .normal)
            checkOutBtn.isEnabled = false
            checkOutBtn.isUserInteractionEnabled = false
            soldOutView.isHidden = false
            soldOutLbl.text = Constant.String.soldOut.uppercased()
            return
        }

        // Normal — tickets available
        let lowestPrice = event.lowestPriceTicket?.price ?? 0
        let title = lowestPrice == 0
            ? "Tickets from Free"
            : "Tickets from \(currency)\(Double(lowestPrice).decimalFormat(true))"
        checkOutBtn.setTitle(title, for: .normal)
        checkOutBtn.isEnabled = true
        checkOutBtn.isUserInteractionEnabled = true
        soldOutView.isHidden = true
    }
    
    private func configureVIPTablesView() {
        
        let isOnlineTablesEnabled = event?.isEnableOnlineTables
        let isReservationRequestEnabled = event?.isEnableReservationRequest
        let is3DMapEnabled = event?.isEnable3DMap
        let hasSeatingAreas = !seatingAreasFilteredOut.isEmpty
    
        
        let shouldShowVIPTablesView: Bool = {
            if isReservationRequestEnabled ?? false {
                return true
            }
            
            // Show online tables only if seating areas exist
            if isOnlineTablesEnabled ?? false && hasSeatingAreas {
                return true
            }
            
            return false
        }()
        
        vipTablesView.isHidden = !(shouldShowVIPTablesView && isEventDetailAPICalled)
        
        // MARK: - Subtitle
        
        if isReservationRequestEnabled ?? false {
            
            vipTableSubTitleLbl.text = (
                is3DMapEnabled ?? false && hasSeatingAreas
            )
            ? "Reservation requests available. 3D map available."
            : "Reservation requests available."
            
            return
        }
        
        if isOnlineTablesEnabled ?? false {
            
            vipTableSubTitleLbl.text = (
                is3DMapEnabled ?? false && hasSeatingAreas
            )
            ? "Ideal for larger groups. 3D map available."
            : "Ideal for larger groups."
            
            return
        }
        
        vipTableSubTitleLbl.text = nil
    }
    
    private let navBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

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

        return (nonGrouped, Array(groupedMap.values))
    }

    private func setupInlineTicketData() {
        guard let event else { return }

        disabledTicketIds.removeAll()

        let visibleNormalTickets = filterAvailableTickets(event.eventTicket ?? [])
        let normalSplit = makeGroupedTickets(from: visibleNormalTickets)

        normalTickets = normalSplit.nonGrouped
        groupedNormalTickets = normalSplit.grouped
        tickets = normalTickets

        let protectedVisibleCandidates = filterAvailableTickets(event.protectedEventTicket ?? [])
        protectedTicketView.isHidden = protectedVisibleCandidates.isEmpty
        lockIcon.isHidden = protectedVisibleCandidates.isEmpty

        groupTableView.isHidden = groupedNormalTickets.isEmpty

        ticketTableView.reloadData()
        groupTableView.reloadData()
        updateTicketTableHeight()
        updateGroupTableHeight()
        updateContinueBtnState()
    }

    private func updateTicketTableHeight() {
        ticketTableView.layoutIfNeeded()
        ticketTableHeightConstraint.constant = ticketTableView.contentSize.height
    }

    private func updateGroupTableHeight() {
        groupTableView.layoutIfNeeded()
        groupTableViewHeight.constant = groupTableView.contentSize.height
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

        if let idx = event?.eventTicket?.firstIndex(where: { $0.id == id }) {
            event?.eventTicket?[idx] = updatedTicket
        }

        if let idx = event?.protectedEventTicket?.firstIndex(where: { $0.id == id }) {
            event?.protectedEventTicket?[idx] = updatedTicket
        }
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

            ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            updateContinueBtnState()
            updateTicketTableHeight()
            updateCheckoutSummaryView()
        } else {
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

        ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        updateContinueBtnState()
        updateTicketTableHeight()
        updateCheckoutSummaryView()
    }

    private func handleRSVP(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket) else { return }
        guard let event else { return }

        let hasAddOn = !(event.eventAddOnTicket?.isEmpty ?? true)
        if hasAddOn {
            Navigate.to.ticketSelectionVc(self, event: event, mode: .addOn)
            return
        }

        var selectedTicket = ticket
        if (selectedTicket.selectedTicketCount ?? 0) == 0 {
            selectedTicket.selectedTicketCount = 1
        }

        createInlineBookingAndCheckout(selectedTickets: [selectedTicket])
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

                updateContinueBtnState()
                updateGroupTableHeight()
                groupTableView.reloadData()
                updateCheckoutSummaryView()
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

            var updatedTicket = currentTicket
            updatedTicket.selectedTicketCount = nextCount > 0 ? nextCount : nil
            syncUpdatedTicketToEvent(updatedTicket)

            updateContinueBtnState()
            updateGroupTableHeight()
            groupTableView.reloadData()
            updateCheckoutSummaryView()
            return
        }
    }

    private func handleGroupRSVP(ticket: EventTicket) {
        guard !isTicketDisabledByLink(ticket) else { return }
        guard let event else { return }

        let hasAddOn = !(event.eventAddOnTicket?.isEmpty ?? true)
        if hasAddOn {
            Navigate.to.ticketSelectionVc(self, event: event, mode: .addOn)
            return
        }

        var selectedTicket = ticket
        if (selectedTicket.selectedTicketCount ?? 0) == 0 {
            selectedTicket.selectedTicketCount = 1
        }

        createInlineBookingAndCheckout(selectedTickets: [selectedTicket])
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
        present(vc, animated: false)
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
        guard !selected.isEmpty else { return }

        let hasAddOn = !(event.eventAddOnTicket?.isEmpty ?? true)
        if hasAddOn {
            Navigate.to.ticketSelectionVc(self, event: event, mode: .addOn)
            return
        }

        createInlineBookingAndCheckout(selectedTickets: selected)
    }
    
    @IBAction func onClickVenueTitle(_ sender: Any) {
        Navigate.to.venueVC(self, venueDetails: self.venueDetails)
    }

    private func createInlineBookingAndCheckout(selectedTickets: [EventTicket]) {
        checkOutBtn.showLoader(userInteraction: false)
        
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
                    self?.createInlineBookingAndCheckout(selectedTickets: selectedTickets)
                }
            }
            return
        }

        guard let event = event else { return }

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
            tickets: ticketsPayload
        ) { [weak self] isSuccess, errMsg, id, _ in
            guard let self = self else { return }
            checkOutBtn.hideLoader()


            if isSuccess {
                Navigate.to.ticketCheckoutVC(
                    self,
                    event: event,
                    selectedTickets: selectedTickets,
                    bookingId: id
                )
            } else {
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
        isExpanded.toggle()

        if isExpanded {
            detailsLbl.numberOfLines = 0
            viewMoreBtn.setTitle("Read Less", for: .normal)
        } else {
            detailsLbl.numberOfLines = collapsedLines
            viewMoreBtn.setTitle("Read More", for: .normal)
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func onClickPolicyViewMoreBtn(_ sender: Any) {
        isPolicyLblExpanded.toggle()

        if isPolicyLblExpanded {
            policyLbl.numberOfLines = 0
            policyViewMoreBtn.setTitle("Read Less", for: .normal)
        } else {
            policyLbl.numberOfLines = collapsedLines
            policyViewMoreBtn.setTitle("Read More", for: .normal)
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func onClickBuyNow(_ sender: Any) {
        if let event = self.event {
            Navigate.to.ticketSelectionVc(self, event: event, mode: .normal)
        }
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickShareBtn(_ sender: Any) {}

    @IBAction func onClickVIPtable(_ sender: Any) {
        if let event = self.event {
            Navigate.to.tableCheckOutVC(self, event: event, seatingAreas: self.seatingAreas, seatingAreasFilteredOut: seatingAreasFilteredOut)
        }
    }
    
    @IBAction func onClickShare(_ sender: Any) {
        let venue = venueDetails?.name
              .lowercased()
              .replacingOccurrences(of: " ", with: "-") ?? ""
          
          let eventName = event?.title
              .lowercased()
              .replacingOccurrences(of: " ", with: "-") ?? ""
          
          let eventId = event?.uniqueId ?? event?.id ?? ""
          
          let url = "https://dev-consumer.speakeasygo.com/\(venue)/\(eventName)?eid=\(eventId)"
          
          Utility.main.shareSocialWith(text: url)
    }

    @IBAction func onClickWebSiteLinkView(_ sender: Any) {
        if let button = event?.additionalButtons?.first(where: { $0.isEnable }),
           let url = URL(string: button.link) {
            UIApplication.shared.open(url)
        }
    }
        
    @IBAction func onClickViewGuestListBtn(_ sender: Any) {
        if UserDefault.shared.isLoggedIn ??  false {
            if let _ = UserDefault.shared.user?.instagramUserId  {
                showGuestListPopup()
            } else {
                showIntsaPopup()
            }
          
        } else {
            Alert.showToast("please login ot purches ticket for view gurst list")
        }
        
    }

    @IBAction func onClickUnLockBtn(_ sender: Any) {
        let code = (unLockTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        guard var event = event else { return }

        let protectedList = event.protectedEventTicket ?? []

        let alreadyUnlocked = (event.eventTicket ?? []).contains { ticket in
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

        setupData()
    }
    
    
    @IBAction func onClickSaveBtn(_ sender: Any) {
        guard !isSaveLoading else { return }
        guard let venueId = event?.id else { return }
        
//        isSaveLoading = true
        
        let previousState = isSaved
        isSaved.toggle()
        updateSaveUI()
        
        if isSaved {
//            saveVenueAPI(venueId: venueId, previousState: previousState)
        } else {
//            unsaveVenueAPI(venueId: venueId, previousState: previousState)
        }
    }
    
    
    @IBAction func onClickVenueImage(_ sender: Any) {
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

        detailsLbl.attributedText = mutable
        detailsLbl.numberOfLines = collapsedLines
        viewMoreBtn.setTitle("Read More", for: .normal)

        view.layoutIfNeeded()
        checkIfTextNeedsExpansion()
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

        policyLbl.attributedText = mutable
        policyLbl.numberOfLines = collapsedLines
        policyViewMoreBtn.setTitle("Read More", for: .normal)

        view.layoutIfNeeded()
        checkIfPolicyTextNeedsExpansion()
    }

    private func checkIfTextNeedsExpansion() {
        detailsLbl.numberOfLines = 0

        let fullHeight = detailsLbl.sizeThatFits(
            CGSize(width: detailsLbl.frame.width,
                   height: CGFloat.greatestFiniteMagnitude)
        ).height

        let maxCollapsedHeight = detailsLbl.font.lineHeight * CGFloat(collapsedLines)

        if fullHeight > maxCollapsedHeight {
            detailsLbl.numberOfLines = collapsedLines
            viewMoreBtnView.isHidden = false
        } else {
            detailsLbl.numberOfLines = 0
            viewMoreBtnView.isHidden = true
        }
    }

    private func checkIfPolicyTextNeedsExpansion() {
        policyLbl.numberOfLines = 0

        let fullHeight = policyLbl.sizeThatFits(
            CGSize(width: policyLbl.frame.width,
                   height: CGFloat.greatestFiniteMagnitude)
        ).height

        let maxCollapsedHeight = policyLbl.font.lineHeight * CGFloat(collapsedLines)

        if fullHeight > maxCollapsedHeight {
            policyLbl.numberOfLines = collapsedLines
            policyViewMoreBtnView.isHidden = false
        } else {
            policyLbl.numberOfLines = 0
            policyViewMoreBtnView.isHidden = true
        }
    }

    func updateLocationOnMap(to coordinate: CLLocationCoordinate2D, with title: String?) {
        mapView.delegate = self
        if #available(iOS 16.0, *) {
            let config = MKStandardMapConfiguration(elevationStyle: .flat)
            config.emphasisStyle = .muted
            config.pointOfInterestFilter = .excludingAll
            mapView.preferredConfiguration = config
        } else {
            mapView.mapType = .mutedStandard
            mapView.pointOfInterestFilter = .excludingAll
        }

        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsTraffic = false
        mapView.showsBuildings = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.removeAnnotations(mapView.annotations)

        let point = MKPointAnnotation()
        point.title = title
        point.coordinate = coordinate
        mapView.addAnnotation(point)

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )

        mapView.setRegion(region, animated: false)
        mapView.layer.cornerRadius = 16
        mapView.clipsToBounds = true
    }
}

class ImagePageVC: UIViewController {

    var imageURL: String = ""
    private let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)

        imageView.sd_setImage(with: URL(string: imageURL))
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
        }
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
    }
}

extension EventDetailsVC: UICollectionViewDelegate,
                          UICollectionViewDataSource,
                          UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {

        if collectionView == guestListCollectionView {
            return min(attendees.count, 6)
        } else {
            return artists.count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == guestListCollectionView {
            let cell: EventGuestListCVC = collectionView.dequeue(withIdentifier: EventGuestListCVC.identifier, for: indexPath)
            let attendee = attendees[indexPath.item]
            cell.configure(with: attendee)
            return cell
        } else if collectionView == lineUpCollectionView {
            let cell: EventLineUpCVC = collectionView.dequeue(withIdentifier: EventLineUpCVC.identifier, for: indexPath)
            let artist = artists[indexPath.item]
            cell.configure(with: artist)
            return cell
        }

        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        if collectionView == guestListCollectionView {
            _ = attendees[indexPath.item]
        } else if collectionView == lineUpCollectionView {
            let artistData = artists[indexPath.item]
            let webUrl = artistData.artist.instagramUsername
            if !webUrl.isEmpty, let url = URL(string: webUrl) {
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
            return CGSize(width: 105, height: 120)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
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
            return event?.additionalButtons?.filter({ $0.isEnable }).count ?? 0
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
            let isExpanded = expandedTicketDescriptions.contains(ticket.id ?? "")

            cell.configure(
                ticket: ticket,
                currency: currency,
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

            cell.configure(
                groupName: item.groupName,
                tickets: item.tickets,
                currency: currency,
                whiteLabelColor: event?.whiteLabelColor,
                eventTicketSetting: event?.eventTicketSettings,
                expandedTicketDescriptions: expandedTicketDescriptions,
                disabledTicketIds: disabledTicketIds
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

            let buttons = event?.additionalButtons?.filter({ $0.isEnable }) ?? []
            let item = buttons[indexPath.row]

            cell.selectionStyle = .none

            cell.webSiteTitleLbl.text = item.title
//            cell.webSiteDiscriptionLbl.text = item.

            let tintColor = UIColor(
                hex: event?.whiteLabelColor ?? "#FFFFFF"
            )

            cell.linkImageView.image = UIImage(named: "ic_link")?.withRenderingMode(.alwaysTemplate)
            cell.linkImageView.tintColor = tintColor

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
        if tableView == faqsTableView {
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
        playerView = YTPlayerView()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.delegate = self

        youTubePlayerView.addSubview(playerView)

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: youTubePlayerView.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: youTubePlayerView.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: youTubePlayerView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: youTubePlayerView.trailingAnchor)
        ])

        let videoID = "dQw4w9WgXcQ"

        playerView.load(
            withVideoId: videoID,
            playerVars: [
                "playsinline": 1,
                "autoplay": 0,
                "controls": 1,
                "modestbranding": 1,
                "rel": 0
            ]
        )
    }

    func extractVideoID(from url: String) -> String? {
        return URLComponents(string: url)?
            .queryItems?
            .first(where: { $0.name == "v" })?
            .value
    }
}

extension EventDetailsVC: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let id = "venuePin"

        var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)

        if view == nil {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
        }

        view?.annotation = annotation

        if let marker = view as? MKMarkerAnnotationView {
            marker.markerTintColor = .systemBlue
            marker.titleVisibility = .hidden
        }

        return view
    }
}


final class EventDetailsSkeletonView: UIView {

    private var allShimmerViews: [ShimmerView] = []
    private var didSetup = false

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !didSetup, bounds.width > 0 else { return }
        didSetup = true
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        let W = bounds.width
        let pad: CGFloat = 16
        var y: CGFloat = 16

        // ─────────────────────────────
        // 1. VIP Banner
        // ─────────────────────────────

        let bannerWidth = W - pad * 2
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

        make(CGRect(x: pad, y: y, width: W * 0.7, height: 10), corner: 5)
        y += 16
        make(CGRect(x: pad, y: y, width: W * 0.5, height: 10), corner: 5)

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

        make(CGRect(x: W - pad - 80, y: y + 8, width: 80, height: 10), corner: 5)

        y += avatarSize + 24
        
        // ─────────────────────────────
        // 5. CONTINUE BUTTON SKELETON
        // ─────────────────────────────

        let continueBtnHeight: CGFloat = 44

        make(
            CGRect(
                x: 16,
                y: y,
                width: W - 32,
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
    }

    // MARK: - Helpers (same as Home)

    private func make(_ frame: CGRect, corner: CGFloat = 8) {
        let sv = ShimmerView(frame: frame)
        sv.layer.cornerRadius = corner
        sv.clipsToBounds = true
        addSubview(sv)
        allShimmerViews.append(sv)
    }

    private func makeLighter(_ frame: CGRect, corner: CGFloat = 6) {
        let sv = ShimmerView(frame: frame, lighter: true)
        sv.layer.cornerRadius = corner
        sv.clipsToBounds = true
        addSubview(sv)
        allShimmerViews.append(sv)
    }

    // MARK: - Control

    func startShimmer() {
        isHidden = false
        allShimmerViews.forEach { $0.startAnimating() }
    }

    func stopShimmer() {
        allShimmerViews.forEach { $0.stopAnimating() }
        isHidden = true
    }
}

final class EventPosterHeaderView: UIView {
    
    private let screenBackgroundColor = UIColor(hex: "#121212")
    
    private let backgroundImageView = UIImageView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let darkOverlayView = UIView()
    
    private let bottomGradientView = UIView()
    private let bottomGradientLayer = CAGradientLayer()
    
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
        backgroundImageView.alpha = 0.75
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundImageView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor, constant: -30),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -30),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 30),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 20)
        ])
        
        blurView.alpha = 0.90
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        darkOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
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
        
        bottomGradientLayer.colors = [
            UIColor.clear.cgColor,             // top — fully transparent
            UIColor.clear.cgColor,             // stays clear through middle
            UIColor.black.withAlphaComponent(0.60).cgColor, // starts bleeding in
            UIColor.black.cgColor              // bottom — solid black
        ]
        
        bottomGradientLayer.locations = [0.0, 0.50, 0.75, 1.0]
        bottomGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0) // top
        bottomGradientLayer.endPoint  = CGPoint(x: 0.5, y: 1.0) // bottom
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bottomGradientLayer.frame = bottomGradientView.bounds
    }
    
    func setBackgroundImage(_ image: UIImage?) {
        backgroundImageView.image = image
    }
    
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard
                error == nil,
                let self,
                let data,
                let image = UIImage(data: data)
            else { return }
            
            DispatchQueue.main.async {
                self.setBackgroundImage(image)
            }
        }.resume()
    }
}

extension EventDetailsVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        
        let shouldCollapse = scrollView.contentOffset.y > collapseThreshold
        
        if shouldCollapse != isCollapsed {
            isCollapsed = shouldCollapse
            applyNavAppearance(collapsed: shouldCollapse)
        }
    }
}

private extension EventDetailsVC {

    func setupGalleryGrid() {
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

            imageView.sd_setImage(
                with: URL(string: galleryImageURLs[index]),
                placeholderImage: Constant.Icon.uploadImage
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
        imageView.sd_setImage(
            with: URL(string: urlString),
            placeholderImage: Constant.Icon.uploadImage
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
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

        guard let user = UserDefault.shared.user else {
            Navigate.to.openPhoneLoginPopup(self)
            return
        }

        guard let event = event else {
            return
        }
        
        checkOutBtnView.showLoader()

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

        guard !selectedTickets.isEmpty else {
            Alert.showToast(
                "Please select at least one ticket"
            )
            checkOutBtnView.hideLoader()
            return
        }

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
            tickets: payload
        ) { [weak self]
            isSuccess,
            errMsg,
            bookingId,
            _ in

            guard let self else { return }

            self.checkOutBtnView.hideLoader()

            if isSuccess {

                Navigate.to.paymentVc(
                    self,
                    event: event,
                    selectedTickets: selectedTickets,
                    bookingId: bookingId
                )

            } else {

                Alert.showToast(
                    errMsg ?? "Something went wrong"
                )
            }
        }
    }
}
