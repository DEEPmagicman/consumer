//
//  EventDetailsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 05/02/26.
//

import UIKit
import MapKit
import YouTubeiOSPlayerHelper

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
    @IBOutlet weak var linkView: UIView!
    @IBOutlet weak var guestListTitleLbl: UILabel!
    @IBOutlet weak var youTubeSuperView: UIView!
    @IBOutlet weak var policyViewMoreBtnView: UIView!
    @IBOutlet weak var policyViewMoreBtn: UIButton!
    
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
    
    private var attendees: [Attendee] = []
    private var totalAttendees = 0


    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViews()
        setupTableView()
        setupImagePager()
        getEventDetail()
    }
    
    
    private func getEventDetail() {
        guard let eventId  = self.event?.uniqueId else {
            return
        }
        Loader.show()
        EventPresenter.getEventDetail(eventId: eventId, venueTimeZone: venueDetails?.useTimezone, promotionLinkId: promoteId) { [weak self] isSuccess, errMsg, eventDetail, errCode in
            Loader.hide()
            guard let self = self else {
                return
            }
            self.view.alpha = 1
            if eventDetail == nil {
                if errCode == 404 && self.promoteId != "" {
                    self.promoteId = ""
                    self.getEventDetail()
                } else {
//                    self.zeroCaseView(isHidden: false)
                }
            } else {
                self.event = eventDetail
                if let venue = eventDetail?.venue {
                    self.venueDetails = venue
                }
                let ticket = self.event?.eventTicket ?? []
                ticket.forEach({tic in
                    self.eventTicketId.append(tic.id ?? "")
                })
                self.artists = self.event?.eventHasArtist?.filter( { $0.artist.status == "ENABLED" }) ?? []
                if self.artists.isEmpty {
                    self.lineUpHiddenView.isHidden = true
                } else {
                    self.lineUpHiddenView.isHidden = false
                }
              
                
                self.getEventAttendees()
                self.lineUpCollectionView.reloadData()
             
                if let show = self.event?.showEventAttendees {
                    print("Value from backend:", show)
                    
                    if show {
                        self.attendeesView.isHidden = false
                        self.getEventAttendees()
                    } else {
                        self.attendeesView.isHidden = true
                    }
                } else {
                    print("showEventAttendees is nil")
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
                self.attendees = data ?? []
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
    
    private func setupData() {
        mainImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        backGroundBlureImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        titleLbl.text = event?.title ?? "Untitle Event"
//        headerTitleLbl.text = event?.title ?? "Untitle Event"
        venueName.text = (event?.customVenue != nil && venueDetails?.venueSettings?.isOrganizer == true) ? "\(event?.customVenue?.name ?? "") by \(venueDetails?.name ?? "")" : "\(venueDetails?.name ?? ""), \(venueDetails?.city ?? "")"
        fullText = event?.description ?? ""
        setupExpandableLabel()
        setupPolicyExpandableLabel()
        venueNameLbl.text = "\(venueDetails?.name ?? "")"
        venueName.text = "\(venueDetails?.name ?? "")"
        venueAddressLbl.text = venueDetails?.address ?? ""
        venueTitleLbl.text = "\(venueDetails?.name ?? "")"
        
        if event?.isEnableOnlineTables ?? false {
            self.vipTablesView.isHidden = false
        } else {
            self.vipTablesView.isHidden = true
        }
        
        
        if let youtubeVideoLink = event?.youtubeVideoLink, !youtubeVideoLink.isEmpty {
            self.youTubeSuperView.isHidden = false
            self.youTubeSuperView.isHidden = false
            setupYouTubePlayer()
            if let id = extractVideoID(from: youtubeVideoLink) {
                playerView.load(withVideoId: id)
            }
        } else {
            self.youTubeSuperView.isHidden = true
        }
        
        venueLogoImg.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),completed: nil)
        venueLogo.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),completed: nil)
  
//        dressCodeView.isHidden = venueDetails?.venueSettings?.isOrganizer == true
//        descriptionView.isHidden = venueDetails?.venueSettings?.isOrganizer ?? false == false
//        descriptionText.text = venueDetails?.description ?? "-"
//        organizerView.isHidden = !(venueDetails?.venueSettings?.isOrganizer == true)
//        detailLbl.text = event?.description.withEmptyPlaceHolder ?? Constant.String.dash
//        eventPolicyLbl.text = event?.disclaimer?.withEmptyPlaceHolder ?? Constant.String.dash
//        dressCodeLbl.text = venueDetails?.dressCode?.withEmptyPlaceHolder ?? Constant.String.dash
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: event?.customVenue?.name ?? "Venue")
        
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
            
            let endTime = event?.endDateTime?.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            ) ?? "LATE"
            
            if !dateText.isEmpty && !startTime.isEmpty {
                timingLbl.text = "\(dateText) at \(startTime) - \(endTime)"
            } else {
                timingLbl.text = ""
            }
        }
        
        if let hexColor = event?.whiteLabelColor
        {
            let color = UIColor(hex: hexColor)
            timingLbl.textColor = color
            buyNowBtnView.backgroundColor = color
        } else {
            let color = UIColor(hex: "6D5EBD")
            buyNowBtnView.backgroundColor = color
        }
        setupSocialLinks()
//        artistTableView.reloadData()
//        if event?.eventTicketSettings?.isUpFront == true {
//            activeTickets = event?.modifiedEventTicket.filter { ($0.isDeleted == false) && ($0.sellingPaused == false) && (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date()) && ($0.issuedUnits ?? 0 >= $0.soldUnits ?? 0)} ?? []
//        } else {
//            activeTickets = event?.eventTicket?.filter { ($0.isDeleted == false) && ($0.sellingPaused == false) && (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date()) && ($0.issuedUnits ?? 0 >= $0.soldUnits ?? 0)} ?? []
//        }
        
        var filteredProtectedTickets = [EventTicket]()
        if event?.eventTicketSettings?.isUpFront == true {
            filteredProtectedTickets = event?.modifiedPasswordProtectedTicket.filter { ($0.isDeleted == false) && ($0.sellingPaused == false) && (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date()) && ($0.issuedUnits ?? 0 >= $0.soldUnits ?? 0)} ?? []
        } else {
            filteredProtectedTickets = event?.protectedEventTicket?.filter { ($0.isDeleted == false) && ($0.sellingPaused == false) && (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date()) && ($0.issuedUnits ?? 0 >= $0.soldUnits ?? 0)} ?? []
        }
//            if activeTickets == nil {
//              activeTickets = filteredProtectedTickets
//            } else {
//              filteredProtectedTickets.forEach { tic in
//                if activeTickets?.contains(where: { $0.id == tic.id }) ?? false == false {
//                  activeTickets?.append(tic)
//                }
//              }
//            }
//            filteredProtectedTickets.forEach { tic in
//              if event?.eventTicket?.contains(where: { $0.id == tic.id }) ?? false == false {
//                event?.eventTicket?.append(tic)
//              }
//            }
        if event?.eventTicket == nil {
        } else {
            if event?.isPausedSellingAllTickets == true {
                ticketsTitleLbl.text = "Tickets from Free"
                buyNowBtnView.isUserInteractionEnabled = true
            } else if event?.isSoldOutAllTickets == true {
                ticketsTitleLbl.text = "It was a great time!"
                buyNowBtnLbl.text = Constant.String.saleEnded.uppercased()
                buyNowBtnView.isUserInteractionEnabled = false
                buyNowBtnView.backgroundColor = UIColor.lightGray
            } else if event?.eventTicket?.count ?? 0 == 0 {
                ticketsTitleLbl.text = Constant.String.salePaused.uppercased()
                buyNowBtnLbl.text = Constant.String.salePaused.uppercased()
                
                
//                isNotSellingStage = true
//                updateContinueBtn()
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
        
        
        
//        eventAddressView.isHidden = !(event?.showAddress ?? true) ? true : false
//        if venueDetails?.venueSettings?.isOrganizer == true {
//            venueNameLbl.text = event?.customVenue?.name ?? ""
//            locationLbl.text = event?.customVenue?.address ?? "-"
//            updateLocationOnMap(to: CLLocationCoordinate2D(latitude: event?.customVenue?.latitude ?? 0, longitude: event?.customVenue?.longitude ?? 0), with: event?.customVenue?.name ?? "Venue")
//        } else {
//            venueNameLbl.text = venueDetails?.name ?? ""
//            locationLbl.text = venueDetails?.address ?? "-"
//            updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: event?.customVenue?.name ?? "Venue")
//        }
//        if venueDetails?.website ?? "" != "" {
//            locationImage.image = UIImage(named: "ic-link")
//            let tap = UITapGestureRecognizer(target: self, action: #selector(onClickWebSite))
//            organizerLocationView.addGestureRecognizer(tap)
//        }
        
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
          updateSwipeButtons()
        
    }
    

    @IBAction func onClickRightSwipeBtn(_ sender: Any) {
        imagePagerVC?.moveNext()
        updateSwipeButtons()
        
    }
    @IBAction func onClickBuyNow(_ sender: Any) {
        if let event = self.event {
            Navigate.to.ticketSelectionVc(self, event: event)
        }
    }
    
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickShareBtn(_ sender: Any) {
        
    }
    
    
    @IBAction func onClickVIPtable(_ sender: Any) {
        if let event = self.event {
            Navigate.to.tableCheckOutVC(self, event: event)
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
        mutable.addAttribute(
            .foregroundColor,
            value: UIColor.label,
            range: NSRange(location: 0, length: mutable.length)
        )

        detailsLbl.attributedText = mutable
        detailsLbl.numberOfLines = collapsedLines

        viewMoreBtn.setTitle("View More", for: .normal)

        DispatchQueue.main.async {
            self.checkIfTextNeedsExpansion()
        }
    }
    
    private func setupPolicyExpandableLabel() {

        guard let html = event?.disclaimer,
              let attributed = html.htmlToAttributedString else { return }

        let mutable = NSMutableAttributedString(attributedString: attributed)
        mutable.addAttribute(
            .foregroundColor,
            value: UIColor.label,
            range: NSRange(location: 0, length: mutable.length)
        )

        policyLbl.attributedText = mutable
        policyLbl.numberOfLines = collapsedLines

        policyViewMoreBtn.setTitle("View More", for: .normal)

        DispatchQueue.main.async {
            self.checkIfPolicyTextNeedsExpansion()
        }
    }
    
    private func updateSwipeButtons() {

        guard let pager = imagePagerVC else { return }

        leftSwipeBtn.isHidden = pager.currentIndex == 0
        rightSwipeBtn.isHidden = pager.currentIndex == pager.imageURLs.count - 1
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
        let point = MKPointAnnotation()
        point.title = title
        point.coordinate = coordinate
        point.accessibilityNavigationStyle = .separate
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(point)
        let viewRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        mapView.setRegion(viewRegion, animated: true)
    }
}


import UIKit

class ImagePageVC: UIViewController {

    private let imageView = UIImageView()
    var imageURL: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }

    private func setupUI() {
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)
    }

    private func loadImage() {
        guard let imageURL,
              let url = URL(string: imageURL) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }.resume()
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

        // Lineup
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
            return attendees.count
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
            let attendee = attendees[indexPath.item]
        }
        
        else if collectionView == lineUpCollectionView {
            
            let artistData = artists[indexPath.item]
            
            print("Selected Artist:", artistData.artist.name)
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
        return faqCount
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: FAQsTableViewCell.identifier,
            for: indexPath
        ) as! FAQsTableViewCell
        return cell
    }
}

extension EventDetailsVC {

    func setupImagePager() {

        let images = [
            "https://picsum.photos/800/600?1",
            "https://picsum.photos/800/600?2",
            "https://picsum.photos/800/600?3"
        ]

        let pagerVC = ImagePagerVC(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pagerVC.imageURLs = images

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

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        setupPages()
    }

    private func setupPages() {
        pages = imageURLs.map { url in
            let vc = ImagePageVC()
            vc.imageURL = url
            return vc
        }

        if let firstVC = pages.first {
            setViewControllers([firstVC], direction: .forward, animated: false)
        }
    }

    func moveNext() {
        guard currentIndex < pages.count - 1 else { return }
        currentIndex += 1
        setViewControllers([pages[currentIndex]], direction: .forward, animated: true)
    }

    func movePrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        setViewControllers([pages[currentIndex]], direction: .reverse, animated: true)
    }
}

extension ImagePagerVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let vc = viewController as? ImagePageVC,
              let index = pages.firstIndex(of: vc),
              index > 0 else { return nil }

        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {

        guard let vc = viewController as? ImagePageVC,
              let index = pages.firstIndex(of: vc),
              index < pages.count - 1 else { return nil }

        return pages[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {

        guard completed,
              let visibleVC = viewControllers?.first,
              let index = pages.firstIndex(of: visibleVC as! ImagePageVC) else { return }

        currentIndex = index
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

