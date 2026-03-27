//
//  EventDetailsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 05/02/26.
//

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
    @IBOutlet weak var leftSwipeBtn: UIButton!
    @IBOutlet weak var rightSwipeBtn: UIButton!
    @IBOutlet weak var mainImg: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var venueTitleLbl: UILabel!
    @IBOutlet weak var timingLbl: UILabel!
    @IBOutlet weak var buyNowBtnView: UIView!
    @IBOutlet weak var backGroundBlureImg: UIImageView!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var instaImageView: UIImageView!
    @IBOutlet weak var tikTokImageView: UIImageView!
    @IBOutlet weak var faceBookImageView: UIImageView!
    @IBOutlet weak var xImageView: UIImageView!
    @IBOutlet weak var youTubeImageView: UIImageView!
    @IBOutlet weak var websiteImageView: UIImageView!
    @IBOutlet weak var ticketsTitleLbl: UILabel!
    @IBOutlet weak var noHiddenFeesLbl: UILabel!
    @IBOutlet weak var buyNowBtnLbl: UILabel!
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
    @IBOutlet weak var webSiteTitleLbl: UILabel!
    @IBOutlet weak var bottemButtonView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var detailsTitleLbl: UILabel!
    @IBOutlet weak var tableBookNowButtonView: UIView!
    @IBOutlet weak var policyView: UIView!
    @IBOutlet weak var ticketShimmerView: ShimmerView!
    @IBOutlet weak var ticketTitleShimmerView: ShimmerView!
    @IBOutlet weak var buyNowBtnShimmerView: ShimmerView!
    @IBOutlet weak var ticketTitleStackShimmerView: UIStackView!
    @IBOutlet weak var ticketTitleStackView: UIStackView!
    @IBOutlet weak var eventAddressView: UIView!
    @IBOutlet weak var faqsTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var faqsView: UIView!
    @IBOutlet weak var lockIcon: UIImageView!
    @IBOutlet weak var buyNowBtnSuperView: UIView!
    @IBOutlet weak var continueToCheckOutView: UIView!
    @IBOutlet weak var groupTableView: UITableView!
    @IBOutlet weak var groupTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var continueToCheckOutBtn: LoadingButton!
    
    private var imagePagerVC: ImagePagerVC?
    private let faqCount = 5
    private var playerView: YTPlayerView!
    private var isExpanded = false
    private var isPolicyLblExpanded = false
    private let collapsedLines = 3
    private var fullText = ""
    private var faqsTableObserver: NSKeyValueObservation?
    private var ticketTableObserver: NSKeyValueObservation?
    private var groupTableObserver: NSKeyValueObservation?

    var venueDetails: ClipVenue?
    var event: Event?
    var promoteId = ""
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

    private var totalSelectedTickets: Int {
        let normalTotal = normalTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        let groupedTotal = groupedNormalTickets
            .flatMap { $0.tickets }
            .reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        return normalTotal + groupedTotal
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buyNowBtnView.layer.cornerRadius = buyNowBtnView.frame.height / 2

        hero.isEnabled = true
        navigationController?.hero.isEnabled = true
        mainImg.hero.id = "event.image.\(heroIndex)"
          titleLbl.hero.id = "event.title.\(heroIndex)"
        
        setupData()
        setupCollectionViews()
        setupTableView()
        setupImagePager()
        startTicketTableObserver()
        startGroupTableObserver()
        startFAQsTableObserver()

        mainImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)

        getEventDetail()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAutoScrollIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.layoutIfNeeded() 
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

    private func setupTicketTable() {
        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        ticketTableView.register(TicketsTVC.nib, forCellReuseIdentifier: TicketsTVC.identifier)
        ticketTableView.isScrollEnabled = false
    }

    func showSkeleton() {
        view.layoutIfNeeded()

        ticketShimmerView.isHidden = false
        ticketTitleShimmerView.isHidden = false
        buyNowBtnShimmerView.isHidden = false
//        buyNowBtnShimmerView.cornerRadius = 30
        ticketTitleStackShimmerView.isHidden = false
        ticketTitleStackView.isHidden = true

        ticketShimmerView.startAnimating()
        ticketTitleShimmerView.startAnimating()
        buyNowBtnShimmerView.startAnimating()
    }

    func hideSkeleton() {
        ticketShimmerView.stopAnimating()
        ticketTitleShimmerView.stopAnimating()
        buyNowBtnShimmerView.stopAnimating()

        ticketShimmerView.isHidden = true
        ticketTitleShimmerView.isHidden = true
        buyNowBtnShimmerView.isHidden = true
        ticketTitleStackShimmerView.isHidden = true
        ticketTitleStackView.isHidden = false
    }

    private func getEventDetail() {
        guard let eventId = self.event?.uniqueId else {
            return
        }

        showSkeleton()

        EventPresenter.getEventDetail(
            eventId: eventId,
            venueTimeZone: venueDetails?.useTimezone,
            promotionLinkId: promoteId
        ) { [weak self] _, _, eventDetail, errCode in
            self?.hideSkeleton()

            guard let self = self else { return }
            self.view.alpha = 1

            if eventDetail == nil {
                if errCode == 404 && self.promoteId != "" {
                    self.promoteId = ""
                    self.getEventDetail()
                } else {
                    // zero case
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

            self.artists = self.event?.eventHasArtist?.filter({ $0.artist.status == "ENABLED" }) ?? []
            self.lineUpHiddenView.isHidden = self.artists.isEmpty
            self.lineUpCollectionView.reloadData()

            if let show = self.event?.showEventAttendees {
                if show {
                    self.attendeesView.isHidden = false
                    self.getEventAttendees()
                } else {
                    self.attendeesView.isHidden = true
                }
            } else {
                self.attendeesView.isHidden = true
            }

            self.getEventFAQs()
            self.getTicketLinksAndRefresh()
        }
    }

    private func getEventAttendees() {
        guard let eventId = self.event?.uniqueId else {
            return
        }

        EventPresenter.getEventAttendees(eventId: eventId) { [weak self] success, _, data, _ in
            guard let self = self else { return }

            if success {
                self.attendees = self.sortAttendeesImageFirst(data ?? [])
                self.totalAttendees = self.attendees.count

                self.guestListCollectionView.reloadData()
                self.attendeesView.isHidden = self.attendees.isEmpty

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

        EventPresenter.getEventFAQs(eventId: eventId) { [weak self] isSuccess, _, faqs, _ in
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
            return
        }

        EventPresenter.getTicketLinks(eventId: eventId) { [weak self] isSuccess, _, links in
            guard let self = self else { return }

            if isSuccess {
                self.ticketLinks = links ?? []
            } else {
                self.ticketLinks = []
            }

            self.setupData()
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
        backGroundBlureImg.sd_setImage(with: URL(string: (event.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        titleLbl.text = event.title
        venueName.text = (event.customVenue != nil && venueDetails?.venueSettings?.isOrganizer == true)
            ? "\(event.customVenue?.name ?? "") by \(venueDetails?.name ?? "")"
            : "\(venueDetails?.name ?? ""), \(venueDetails?.city ?? "")"
        fullText = event.description
        setupExpandableLabel()
        setupPolicyExpandableLabel()
        venueNameLbl.text = venueDetails?.name ?? ""
        venueName.text = venueDetails?.name ?? ""
        eventAddressView.isHidden = !(event.showAddress ?? true)

        let addressComponents = [
            venueDetails?.address,
            venueDetails?.city,
            venueDetails?.pinCode
        ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        venueAddressLbl.text = addressComponents.joined(separator: ", ")
        venueTitleLbl.text = venueDetails?.name ?? ""

        if event.eventTicketSettings?.showTicketListingOnMainScreen ?? false {
            buyNowBtnSuperView.isHidden = true
            continueToCheckOutView.isHidden = true
        } else {
            buyNowBtnSuperView.isHidden = false
            continueToCheckOutView.isHidden = true
        }

        vipTablesView.isHidden = !(event.isEnableOnlineTables)

        if let button = event.additionalButtons?.first(where: { $0.isEnable }) {
            webSiteTitleLbl.text = button.title
            webSiteView.isHidden = false
        } else {
            webSiteView.isHidden = true
        }

        setupImagePager()

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

        updateLocationOnMap(
            to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0),
            with: event.customVenue?.name ?? "Venue"
        )

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
            buyNowBtnView.backgroundColor = color
            webSiteView.borderColor = color
            continueToCheckOutBtn.indicator = MaterialLoadingIndicator(color: .white)
            continueToCheckOutBtn.bgColor = color
            
        } else {
            let color = UIColor(hex: "6D5EBD")
            buyNowBtnView.backgroundColor = color
            webSiteView.borderColor = color
            continueToCheckOutBtn.backgroundColor = color
            continueToCheckOutBtn.indicator = MaterialLoadingIndicator(color: .white)
            continueToCheckOutBtn.bgColor = continueToCheckOutBtn.backgroundColor ?? .orange
        }

        setupSocialLinks()

        if event.eventTicket == nil {
        } else {
            if event.isPausedSellingAllTickets == true {
                ticketsTitleLbl.text = "Tickets from Free"
                buyNowBtnView.isUserInteractionEnabled = true
            } else if event.isSoldOutAllTickets == true {
                ticketsTitleLbl.text = "It was a great time!"
                buyNowBtnLbl.text = Constant.String.saleEnded.uppercased()
                buyNowBtnLbl.textColor = .black
                buyNowBtnView.isUserInteractionEnabled = false
                buyNowBtnView.backgroundColor = UIColor.lightGray
            } else if event.eventTicket?.count ?? 0 == 0 {
                ticketsTitleLbl.text = Constant.String.salePaused.uppercased()
                buyNowBtnLbl.text = Constant.String.salePaused.uppercased()
            } else {
                let lowestPrice = event.lowestPriceTicket?.price ?? 0
                let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"

                if lowestPrice == 0 {
                    ticketsTitleLbl.text = "Tickets from Free"
                } else {
                    ticketsTitleLbl.text = "Tickets from \(currency)\(Double(lowestPrice).decimalFormat(true))"
                }

                buyNowBtnLbl.text = "Buy Now"
                buyNowBtnView.layer.cornerRadius = buyNowBtnView.frame.height / 2
                buyNowBtnView.clipsToBounds = true
                noHiddenFeesLbl.isHidden = false
            }
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
        continueToCheckOutView.isHidden = totalSelectedTickets == 0
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
    
    private func createInlineBookingAndCheckout(selectedTickets: [EventTicket]) {
        continueToCheckOutBtn.showLoader(userInteraction: false)
        
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
            viewMoreBtn.setTitle("View Less", for: .normal)
        } else {
            detailsLbl.numberOfLines = collapsedLines
            viewMoreBtn.setTitle("View More", for: .normal)
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func onClickPolicyViewMoreBtn(_ sender: Any) {
        isPolicyLblExpanded.toggle()

        if isPolicyLblExpanded {
            policyLbl.numberOfLines = 0
            policyViewMoreBtn.setTitle("View Less", for: .normal)
        } else {
            policyLbl.numberOfLines = collapsedLines
            policyViewMoreBtn.setTitle("View More", for: .normal)
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func onClickLeftSwipeBtn(_ sender: Any) {
        imagePagerVC?.movePrevious()
    }

    @IBAction func onClickRightSwipeBtn(_ sender: Any) {
        imagePagerVC?.moveNext()
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
            Navigate.to.tableCheckOutVC(self, event: event)
        }
    }

    @IBAction func onClickWebSiteLinkView(_ sender: Any) {
        if let button = event?.additionalButtons?.first(where: { $0.isEnable }),
           let url = URL(string: button.link) {
            UIApplication.shared.open(url)
        }
    }
        
    @IBAction func onClickViewGuestListBtn(_ sender: Any) {
        if UserDefault.shared.isLoggedIn ??  false {
            if let intsaGramId = UserDefault.shared.user?.instagramUserId  {
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
        detailsLbl.font = .systemFont(ofSize: 15)
        viewMoreBtn.setTitle("View More", for: .normal)

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
        policyViewMoreBtn.setTitle("View More", for: .normal)

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
            return CGSize(width: 140, height: 180)
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

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FAQsTableViewCell.identifier,
            for: indexPath
        ) as? FAQsTableViewCell else {
            return UITableViewCell()
        }

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
