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
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var timingLbl: UILabel!
    
    
    
    
    private var imagePagerVC: ImagePagerVC?
    private let lineUpCount = 6
    private let faqCount = 5
    private var playerView: YTPlayerView!
    private var youtubeVideoLink = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    private var isExpanded = false
    private let collapsedLines = 3
    private var fullText = """
    This is a long dummy event description for testing purposes
    """
    var eventId = "EVE-GLHDR1"
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
        setupYouTubePlayer()
        if let id = extractVideoID(from: youtubeVideoLink) {
            playerView.load(withVideoId: id)
        }
        setupExpandableLabel()
        getEventDetail()
        getEventAttendees()

    }
    
    
    private func getEventDetail() {
        if eventId  == "" {
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
                self.setupData()
            }
        }
    }
    
    private func getEventAttendees() {

        EventPresenter.getEventAttendees(eventId: eventId) { [weak self] success, message, data, code in

            guard let self = self else { return }

            if success {
                self.attendees = data ?? []
                self.totalAttendees = data?.count ?? 0
                self.guestListCollectionView.reloadData()
            } else {
                print("Attendees error:", message ?? "")
            }
        }
    }
    
    private func setupData() {
        mainImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        titleLbl.text = event?.title ?? "Untitle Event"
//        headerTitleLbl.text = event?.title ?? "Untitle Event"
        venueName.text = (event?.customVenue != nil && venueDetails?.venueSettings?.isOrganizer == true) ? "\(event?.customVenue?.name ?? "") by \(venueDetails?.name ?? "")" : "\(venueDetails?.name ?? ""), \(venueDetails?.city ?? "")"
//        organizerName.text = "\(venueDetails?.name ?? "")"
//        organizerLocation.text = venueDetails?.website ?? "" != "" ? venueDetails?.website : event?.customVenue?.address ?? ""
//        dressCodeView.isHidden = venueDetails?.venueSettings?.isOrganizer == true
//        descriptionView.isHidden = venueDetails?.venueSettings?.isOrganizer ?? false == false
//        descriptionText.text = venueDetails?.description ?? "-"
//        organizerView.isHidden = !(venueDetails?.venueSettings?.isOrganizer == true)
//        detailLbl.text = event?.description.withEmptyPlaceHolder ?? Constant.String.dash
//        eventPolicyLbl.text = event?.disclaimer?.withEmptyPlaceHolder ?? Constant.String.dash
//        dressCodeLbl.text = venueDetails?.dressCode?.withEmptyPlaceHolder ?? Constant.String.dash
//        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: event?.customVenue?.name ?? "Venue")
//        dateLbl.text = "\(event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, customTimeZone: venueDetails?.useTimezone ?? "") ?? ""),"
//        timingLbl.text = "\(event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: venueDetails?.useTimezone ?? "") ?? "") - \(event?.endDateTime?.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: venueDetails?.useTimezone ?? "") ?? "LATE")"
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
            filteredProtectedTickets = event?.passwordProtrectedTickets?.filter { ($0.isDeleted == false) && ($0.sellingPaused == false) && (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date()) && ($0.issuedUnits ?? 0 >= $0.soldUnits ?? 0)} ?? []
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
//        if event?.eventTicket == nil {
//            isNotSellingStage = false
//            updateContinueBtn(forceRemove: true)
//        } else {
//            if event?.isPausedSellingAllTickets == true {
//                continueBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
//                isNotSellingStage = true
//                updateContinueBtn()
//            } else if event?.isSoldOutAllTickets == true {
//                continueBtn.setTitle(Constant.String.soldOut.uppercased(), for: .normal)
//                isNotSellingStage = true
//                updateContinueBtn()
//            } else if event?.eventTicket?.count ?? 0 == 0 {
//                continueBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
//                isNotSellingStage = true
//                updateContinueBtn()
//            } else {
//                continueBtn.setTitle("BUY NOW - STARTING AT \(venueDetails?.venueSettings?.currencySymbol ?? "$")\(Double(event?.lowestPriceTicket?.price ?? 0).decimalFormat(true))", for: .normal)
//                isNotSellingStage = false
//                updateContinueBtn(forceRemove: true)
//            }
//        }
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
    
    @IBAction func onClickLeftSwipeBtn(_ sender: Any) {
        imagePagerVC?.movePrevious()
          updateSwipeButtons()
        
    }
    

    @IBAction func onClickRightSwipeBtn(_ sender: Any) {
        imagePagerVC?.moveNext()
        updateSwipeButtons()
        
    }
    @IBAction func onClickBuyNow(_ sender: Any) {
        Navigate.to.ticketSelectionVc(self)
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
    
    private func setupExpandableLabel() {

        detailsLbl.text = fullText
        detailsLbl.numberOfLines = collapsedLines

        viewMoreBtn.setTitle("View More", for: .normal)
        DispatchQueue.main.async {
            self.checkIfTextNeedsExpansion()
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
            return lineUpCount
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
        }


        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: EventLineUpCVC.identifier,
            for: indexPath
        ) as! EventLineUpCVC
        return cell
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

