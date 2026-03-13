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
    @IBOutlet weak var continueToCheckOutBtn: UIButton!
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
    @IBOutlet weak var venueLogoShimmerView: ShimmerView!
    @IBOutlet weak var ticketShimmerView: ShimmerView!
    @IBOutlet weak var ticketTitleShimmerView: ShimmerView!
    @IBOutlet weak var buyNowBtnShimmerView: ShimmerView!
    @IBOutlet weak var ticketTitleStackShimmerView: UIStackView!
    @IBOutlet weak var ticketTitleStackView: UIStackView!
    @IBOutlet weak var eventAddressView: UIView!
    
    
    private var imagePagerVC: ImagePagerVC?
    private let faqCount = 5
    private var playerView: YTPlayerView!
    private var isExpanded = false
    private var isPolicyLblExpanded = false
    private let collapsedLines = 3
    private var fullText = ""
    var venueDetails: ClipVenue?
    var event: Event?
    var promoteId = ""
    private var eventTicketId = [String]()
    private var artists = [ArtistData]()

    // MARK: - Ticket only (inline listing)
    private var tickets: [EventTicket] = []
    private var normalTickets: [EventTicket] = []

    private var attendees: [Attendee] = []
    private var totalAttendees = 0
    private var ticketTableObserver: NSKeyValueObservation?
    private var skeletonView: SkeletonOverlayView?
    private var isLoading = false
    var heroIndex: Int = 0


    override func viewDidLoad() {
        super.viewDidLoad()
        buyNowBtnView.layer.cornerRadius = buyNowBtnView.frame.height / 2
        
        hero.isEnabled = true
        setupData()
        setupCollectionViews()
        setupTableView()
        setupImagePager()
        getEventDetail()
        startTicketTableObserver()
    
        
        hero.isEnabled = true
        navigationController?.hero.isEnabled = true
        mainImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
      
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
        buyNowBtnShimmerView.cornerRadius = 30
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
        guard let eventId  = self.event?.uniqueId else {
            return
        }
        showSkeleton()
        EventPresenter.getEventDetail(eventId: eventId, venueTimeZone: venueDetails?.useTimezone, promotionLinkId: promoteId) { [weak self] isSuccess, errMsg, eventDetail, errCode in
            self?.hideSkeleton()
            guard let self = self else {
                return
            }
            self.view.alpha = 1
            if eventDetail == nil {
                if errCode == 404 && self.promoteId != "" {
                    self.promoteId = ""
                    self.getEventDetail()
                } else {
                    // zero case
                }
            } else {
                self.event = eventDetail
                if let venue = eventDetail?.venue {
                    self.venueDetails = venue
                }

                let ticket = self.event?.eventTicket ?? []
                ticket.forEach({ tic in
                    self.eventTicketId.append(tic.id ?? "")
                })

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

                self.setupData()
            }
        }
    }

    private func getEventAttendees() {

        guard let eventId  = self.event?.uniqueId else {
            return
        }
        EventPresenter.getEventAttendees(eventId: eventId) { [weak self] success, message, data, code in

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
    
    private func startTicketTableObserver() {
        ticketTableObserver?.invalidate()

        ticketTableObserver = ticketTableView.observe(\.contentSize, options: [.new]) { [weak self] tableView, _ in
            guard let self else { return }
            self.ticketTableHeightConstraint.constant = tableView.contentSize.height
            self.view.layoutIfNeeded()
        }
    }

    private func stopTicketTableObserver() {
        ticketTableObserver?.invalidate()
        ticketTableObserver = nil
    }

    private func sortAttendeesImageFirst(_ list: [Attendee]) -> [Attendee] {
        let withImage = list.filter { $0.hasImage }
        let withoutImage = list.filter { !$0.hasImage }
        return withImage + withoutImage
    }

    private func setupData() {
        mainImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        backGroundBlureImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        titleLbl.text = event?.title ?? "Untitle Event"
        venueName.text = (event?.customVenue != nil && venueDetails?.venueSettings?.isOrganizer == true)
            ? "\(event?.customVenue?.name ?? "") by \(venueDetails?.name ?? "")"
            : "\(venueDetails?.name ?? ""), \(venueDetails?.city ?? "")"
        fullText = event?.description ?? ""
        setupExpandableLabel()
        setupPolicyExpandableLabel()
        venueNameLbl.text = "\(venueDetails?.name ?? "")"
        venueName.text = "\(venueDetails?.name ?? "")"
        eventAddressView.isHidden = !(event?.showAddress ?? true) ? true : false
        let addressComponents = [
            venueDetails?.address,
            venueDetails?.city,
            venueDetails?.pinCode
        ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
         .filter { !$0.isEmpty }
        venueAddressLbl.text = addressComponents.joined(separator: ", ")
        venueTitleLbl.text = "\(venueDetails?.name ?? "")"

        if event?.isEnableOnlineTables ?? false {
            self.vipTablesView.isHidden = false
        } else {
            self.vipTablesView.isHidden = true
        }
        
        if let button = event?.additionalButtons?.first(where: { $0.isEnable }) {
            self.webSiteTitleLbl.text = button.title
            self.webSiteView.isHidden = false
        } else {
            self.webSiteView.isHidden = true
        }
        setupImagePager()

        // ✅ Ticket-only: inline list enable/disable
        let showInlineTickets = event?.eventTicketSettings?.showTicketListingOnMainScreen ?? false
        ticketHidenView.isHidden = !showInlineTickets

        if showInlineTickets {
            setupTicketTable()
            setupInlineTicketData()
        }

        if let youtubeVideoLink = event?.youtubeVideoLink, !youtubeVideoLink.isEmpty {
            self.youTubeSuperView.isHidden = false
            setupYouTubePlayer()
            if let id = extractVideoID(from: youtubeVideoLink) {
                playerView.load(withVideoId: id)
            }
        } else {
            self.youTubeSuperView.isHidden = true
        }

        venueLogoImg.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL), completed: nil)
        venueLogo.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL), completed: nil)
        updateLocationOnMap(
            to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0),
            with: event?.customVenue?.name ?? "Venue"
        )

        if let customText = event?.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

            timingLbl.text = customText

        } else {

            let timezone = venueDetails?.useTimezone ?? ""

            let dateText = event?.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .EEEMMMD,
                customTimeZone: timezone
            ) ?? ""

            let startTime = event?.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            ) ?? ""

            if !dateText.isEmpty && !startTime.isEmpty {

                let hideEnd = event?.hideEventEnd == true
                let hasEndTime = !(event?.endDateTime?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

                if hideEnd || !hasEndTime {
                    timingLbl.text = "\(dateText) at \(startTime)"
                } else {

                    let endTime = event?.endDateTime?.convertDateFormat(
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

        if let hexColor = event?.whiteLabelColor {
            let color = UIColor(hex: hexColor)
            timingLbl.textColor = color
            buyNowBtnView.backgroundColor = color
            webSiteView.borderColor = color
        } else {
            let color = UIColor(hex: "6D5EBD")
            buyNowBtnView.backgroundColor = color
            webSiteView.borderColor = color
        }

        setupSocialLinks()

        // (your existing ticket header text logic kept as-is)
        if event?.eventTicket == nil {
        } else {
            if event?.isPausedSellingAllTickets == true {
                ticketsTitleLbl.text = "Tickets from Free"
                buyNowBtnView.isUserInteractionEnabled = true
            } else if event?.isSoldOutAllTickets == true {
                ticketsTitleLbl.text = "It was a great time!"
                buyNowBtnLbl.text = Constant.String.saleEnded.uppercased()
                buyNowBtnLbl.textColor = .black
                buyNowBtnView.isUserInteractionEnabled = false
                buyNowBtnView.backgroundColor = UIColor.lightGray
            } else if event?.eventTicket?.count ?? 0 == 0 {
                ticketsTitleLbl.text = Constant.String.salePaused.uppercased()
                buyNowBtnLbl.text = Constant.String.salePaused.uppercased()
            } else {
                let lowestPrice = event?.lowestPriceTicket?.price ?? 0
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

    // MARK: - Ticket only
    private func setupInlineTicketData() {
        guard let event else { return }

        func filterAvailable(_ list: [EventTicket]) -> [EventTicket] {
            list.filter { t in
                let remaining = t.remainingQuantity ?? 0
                let isNotDeleted = t.isDeleted == false
                let isNotPaused = t.sellingPaused == false
                return remaining > 0 && isNotDeleted && isNotPaused
            }
        }

        normalTickets = filterAvailable(event.eventTicket ?? [])
        tickets = normalTickets

        ticketTableView.reloadData()
        updateTicketTableHeight()
        updateContinueBtnState()
    }

    private func updateTicketTableHeight() {
        ticketTableView.layoutIfNeeded()
        ticketTableHeightConstraint.constant = ticketTableView.contentSize.height
    }

    private func handlePlus(ticket: EventTicket) {
        guard let index = tickets.firstIndex(where: { $0.id == ticket.id }) else { return }

        let total = tickets[index].selectedTicketCount ?? 0
        let issuedUnits = tickets[index].issuedUnits ?? 0

        if total < issuedUnits,
           let remaining = tickets[index].remainingQuantity,
           remaining > total {

            tickets[index].selectedTicketCount = total + 1

            // keep normalTickets in sync by id (safe)
            if let idx = normalTickets.firstIndex(where: { $0.id == tickets[index].id }) {
                normalTickets[idx] = tickets[index]
            }

            ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            updateContinueBtnState()
            updateTicketTableHeight()
        }
    }

    private func handleMinus(ticket: EventTicket) {
        guard let index = tickets.firstIndex(where: { $0.id == ticket.id }) else { return }

        let total = tickets[index].selectedTicketCount ?? 0

        if total > 1 {
            tickets[index].selectedTicketCount = total - 1
        } else {
            tickets[index].selectedTicketCount = nil
        }

        if let idx = normalTickets.firstIndex(where: { $0.id == tickets[index].id }) {
            normalTickets[idx] = tickets[index]
        }

        ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        updateContinueBtnState()
        updateTicketTableHeight()
    }

    // ✅ Ticket-only: RSVP handler required because you call it from cell closures
    private func handleRSVP(ticket: EventTicket) {
        guard let event else { return }

        let hasAddOn = !(event.eventAddOnTicket?.isEmpty ?? true)
        if hasAddOn {
            Navigate.to.ticketSelectionVc(self, event: event)
            return
        }

        Navigate.to.ticketCheckoutVC(
            self,
            event: event,
            selectedTickets: [ticket],
            bookingId: nil
        )
    }

    private func updateContinueBtnState() {
        let totalSelected = normalTickets.reduce(0) { $0 + ($1.selectedTicketCount ?? 0) }
        continueToCheckOutBtn.isHidden = totalSelected == 0
    }

    @IBAction func onClickInlineContinue(_ sender: Any) {
        guard let event else { return }

        let selected = normalTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
        guard !selected.isEmpty else { return }

        // ✅ You said: if add-on exists -> go TicketSelection screen (don’t handle add-on inline)
        let hasAddOn = !(event.eventAddOnTicket?.isEmpty ?? true)
        if hasAddOn {
            Navigate.to.ticketSelectionVc(self, event: event)
            return
        }

        Navigate.to.ticketCheckoutVC(
            self,
            event: event,
            selectedTickets: selected,
            bookingId: nil
        )
    }

    // MARK: - Social (unchanged)
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

    // MARK: - Actions (unchanged)
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
            Navigate.to.ticketSelectionVc(self, event: event)
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
            var config = MKStandardMapConfiguration(elevationStyle: .flat)
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

// MARK: - ImagePageVC (unchanged)
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

// MARK: - Setup collections/tables (unchanged)
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
        faqsTableView.estimatedRowHeight = 80
        faqsTableView.rowHeight = UITableView.automaticDimension
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

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EventGuestListCVC.identifier,
                for: indexPath
            ) as! EventGuestListCVC

            let attendee = attendees[indexPath.item]
            cell.configure(with: attendee)

            return cell
        } else if collectionView == lineUpCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EventLineUpCVC.identifier,
                for: indexPath
            ) as! EventLineUpCVC
            let artists = artists[indexPath.item]
            cell.configure(with: artists)
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
            if !webUrl.isEmpty {
                if let url = URL(string: webUrl) {
                    UIApplication.shared.open(url)
                }
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
        if tableView == faqsTableView {
            return faqCount
        }
        return 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if tableView == ticketTableView {

            let cell = tableView.dequeueReusableCell(
                withIdentifier: TicketsTVC.identifier,
                for: indexPath
            ) as! TicketsTVC

            cell.selectionStyle = .none

            let ticket = tickets[indexPath.row]
            let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"

            cell.configure(
                ticket: ticket,
                currency: currency,
                whiteLabelColor: event?.whiteLabelColor, eventTicketSetting: self.event?.eventTicketSettings
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

            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: FAQsTableViewCell.identifier,
            for: indexPath
        ) as! FAQsTableViewCell

        return cell
    }
}

// MARK: - Image pager (only tiny compile-safe identity checks)
extension EventDetailsVC {

    func setupImagePager() {

        let gallery = (event?.eventGallery ?? [])
            .filter { $0.status == "ENABLED" && $0.isDeleted == false }

        let images = gallery.map { $0.key.imageURL }

        guard !images.isEmpty else {
            imageListHiddenView.isHidden = true
            return
        }

        imageListHiddenView.isHidden = false

        if let pagerVC = imagePagerVC {
            pagerVC.setImages(images)
            return
        }

        let pagerVC = ImagePagerVC(transitionStyle: .scroll,
                                   navigationOrientation: .horizontal)
        pagerVC.setImages(images)

        addChild(pagerVC)
        pagerVC.view.frame = imageListView.bounds
        pagerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageListView.addSubview(pagerVC.view)
        pagerVC.didMove(toParent: self)

        imagePagerVC = pagerVC
    }
}



class ImagePagerVC: UIPageViewController {
    
    var imageURLs: [String] = []
    private var pages: [ImagePageVC] = []
    private(set) var currentIndex = 0
    private var isTransitioning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
    }
    
    func setImages(_ urls: [String]) {
        imageURLs = urls
        buildPages()
        
        currentIndex = 0
        if let firstVC = pages.first {
            setViewControllers([firstVC], direction: .forward, animated: false)
        }
    }
    
    private func syncCurrentIndexFromVisible() {
        guard let visible = viewControllers?.first as? ImagePageVC,
              let idx = pages.firstIndex(where: { $0 === visible }) else { return }
        currentIndex = idx
    }
    
    private func buildPages() {
        pages = imageURLs.map { url in
              let vc = ImagePageVC()
              vc.imageURL = url
              return vc
          }

          currentIndex = 0
          guard let first = pages.first else { return }   
          setViewControllers([first], direction: .forward, animated: false)
    }
    
    func moveNext() {
        guard pages.count > 1, !isTransitioning else { return }
        syncCurrentIndexFromVisible()

        let nextIndex = (currentIndex + 1) % pages.count
        isTransitioning = true
        setViewControllers([pages[nextIndex]], direction: .forward, animated: true) { [weak self] finished in
            guard let self else { return }
            self.isTransitioning = false
            if finished { self.currentIndex = nextIndex }
        }
    }

    func movePrevious() {
        guard pages.count > 1, !isTransitioning else { return }
        syncCurrentIndexFromVisible()

        let prevIndex = (currentIndex - 1 + pages.count) % pages.count
        isTransitioning = true
        setViewControllers([pages[prevIndex]], direction: .reverse, animated: true) { [weak self] finished in
            guard let self else { return }
            self.isTransitioning = false
            if finished { self.currentIndex = prevIndex }
        }
    }
}

extension ImagePagerVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard pages.count > 1,
              let vc = viewController as? ImagePageVC,
              let index = pages.firstIndex(where: { $0 === vc }) else { return nil }

        let prev = (index - 1 + pages.count) % pages.count
        return pages[prev]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard pages.count > 1,
              let vc = viewController as? ImagePageVC,
              let index = pages.firstIndex(where: { $0 === vc }) else { return nil }

        let next = (index + 1) % pages.count
        return pages[next]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        isTransitioning = true
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {

        isTransitioning = false

        guard completed,
              let visible = viewControllers?.first as? ImagePageVC,
              let idx = pages.firstIndex(where: { $0 === visible }) else { return }

        currentIndex = idx
    }
}
// MARK: - YouTube (unchanged)
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


extension NSMutableAttributedString {
    func trimTrailingWhitespaceAndNewlines() {
        let ws = CharacterSet.whitespacesAndNewlines
        while length > 0 {
            let lastRange = NSRange(location: length - 1, length: 1)
            let lastChar = (string as NSString).substring(with: lastRange)
            if lastChar.rangeOfCharacter(from: ws) != nil {
                deleteCharacters(in: lastRange)
            } else {
                break
            }
        }
    }
    
    func forceSystemFont15() {
         let base = UIFont.systemFont(ofSize: 15)

         enumerateAttribute(.font, in: NSRange(location: 0, length: length)) { value, range, _ in
             // keep bold/italic traits if HTML had them
             let traits = (value as? UIFont)?.fontDescriptor.symbolicTraits ?? []
             let descriptor = base.fontDescriptor.withSymbolicTraits(traits) ?? base.fontDescriptor
             let newFont = UIFont(descriptor: descriptor, size: 15)
             self.addAttribute(.font, value: newFont, range: range)
         }
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

