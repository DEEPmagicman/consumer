//
//  EventDetailVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 11/04/23.
//

import UIKit
import MapKit

final class EventDetailVC: UIViewController {

    @IBOutlet weak var mainImg: UIImageView!
    @IBOutlet weak var venueTitleLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var timingLbl: UILabel!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var headerTitleLbl: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var ticketListTableView: UITableView!
    @IBOutlet weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet weak var artistTableView: UITableView!
    @IBOutlet weak var artistTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lineUpView: UIView!
    @IBOutlet weak var dressCodeView: UIView!
    @IBOutlet weak var dressCodeLbl: UILabel!
    @IBOutlet weak var detailLbl: UILabel!
    @IBOutlet weak var eventPolicyLbl: UILabel!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var zeroCaseView: UIView!
    @IBOutlet weak var continueBtnBGView: UIView!
    @IBOutlet weak var eventAddressView: UIView!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var organizerName: UILabel!
    @IBOutlet weak var organizerView: UIView!
    @IBOutlet weak var organizerLocation: UILabel!
    @IBOutlet weak var organizerLocationView: UIView!
    @IBOutlet weak var locationImage: UIImageView!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var descriptionText: UILabel!
    @IBOutlet weak var unLockTicketView: UIView!
    @IBOutlet weak var unLockBtn: UIButton!
    @IBOutlet weak var unLockTF: UITextField!
    @IBOutlet weak var invalidPasswordLbl: UILabel!
    
    var eventId = ""
    var venueDetails: ClipVenue?
    var event: Event?
    var promoteId = ""
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var artistHeightObservation: NSKeyValueObservation?
    private var isTicketListLayoutUpdateInProgress = false
    private var isNotSellingStage = false
    private var maxTicket = 20
    private var activeTickets: [EventTicket]?
//    private var protectedTickets: [EventTicket]?
    private var totalPrice: Double {
        var total: Double = 0
        activeTickets?.forEach {
            if let quantity = $0.selectedTicketCount {
                if event?.upfront == true {
                    total += ($0.priceWithFees * Double(quantity))
                } else {
                    total += (Double($0.price ?? 0) * Double(quantity))
                }
            }
        }
        return total
    }
    private var isMaxTicketReached: Bool {
        totalSelectedTickets >= maxTicket
    }
    private var totalSelectedTickets: Int {
        var total = 0
        activeTickets?.forEach {
            if let quantity = $0.selectedTicketCount {
                total += quantity
            }
        }
        return total
    }
    private var selectedType: TicketPriceType = .FREE
    private var eventTicketId = [String]()
    private var artists = [ArtistData]()
    private enum TicketUnavailableState {
        case saleEnded
        case soldOut
        case salePaused
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        event?.eventTicket?.removeAll()
        getEventDetail()
        setupData()
        headerTitleLbl.isHidden = true
        headerView.backgroundColor = .clear
        scrollView.delegate = self
        // WebSocketWrapper.shared.delegate.append(self)
        updateContinueBtn(forceRemove: true)
        ticketListTableView.register(UINib(nibName: "TicketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "TicketTypeTableViewCell")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            guard !self.isTicketListLayoutUpdateInProgress else { return }
            self.updateTicketListHeightWithoutAnimation()
        }
        artistTableView.register(UINib(nibName: "ArtistListTVC", bundle: nil), forCellReuseIdentifier: "ArtistListTVC")
        artistHeightObservation = artistTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.artistTableViewHeight.constant = self.artistTableView.contentSize.height
            self.artistTableView.layoutIfNeeded()
        }
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(openFullImage))
        mainImg.isUserInteractionEnabled = true
        mainImg.addGestureRecognizer(tap1)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openAppleMap))
        mapView.addGestureRecognizer(tap)
        mapView.isScrollEnabled = false
        venueLogo.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL), completed: nil)
        WebSocketWrapper.shared.addDelegate(self) 
        unLockTF.addTarget(self, action: #selector(unLockPassword), for: .editingChanged)
        updateUnlockButtonState()
        continueBtn.isHidden = true
        continueBtnBGView.isHidden = true
        invalidPasswordLbl.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        WebSocketWrapper.shared.removeDelegate(self)
    }
    
    @objc func unLockPassword() {
        invalidPasswordLbl.isHidden = true
        updateUnlockButtonState()
    }

    private var unlockPassword: String {
        (unLockTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func updateUnlockButtonState() {
        let isEnabled = !unlockPassword.isEmpty
        unLockBtn.alpha = isEnabled ? 1 : 0.5
        unLockBtn.isEnabled = isEnabled
        unLockBtn.isUserInteractionEnabled = isEnabled
    }

    private func updateTicketListHeightWithoutAnimation() {
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ticketListHeight.constant = ticketListTableView.contentSize.height
        ticketListTableView.layoutIfNeeded()
        ticketListTableView.visibleCells
            .compactMap { $0 as? TicketTypeTableViewCell }
            .forEach { $0.removeTicketControlAnimations() }
        CATransaction.commit()
        UIView.setAnimationsEnabled(animationsEnabled)
    }

    private func reloadTicketListWithoutAnimation() {
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        isTicketListLayoutUpdateInProgress = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ticketListTableView.reloadData()
        ticketListTableView.layoutIfNeeded()
        ticketListHeight.constant = ticketListTableView.contentSize.height
        ticketListTableView.visibleCells
            .compactMap { $0 as? TicketTypeTableViewCell }
            .forEach { $0.removeTicketControlAnimations() }
        CATransaction.commit()
        isTicketListLayoutUpdateInProgress = false
        UIView.setAnimationsEnabled(animationsEnabled)
    }

    private func availableTickets(from tickets: [EventTicket]?) -> [EventTicket] {
        tickets?.filter {
            ($0.isDeleted == false) &&
            ($0.isMembersOnly != true) &&
            ($0.sellingPaused == false) &&
            (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date()) &&
            (remainingQuantity(for: $0) > 0)
        } ?? []
    }

    private func remainingQuantity(for ticket: EventTicket) -> Int {
        max((ticket.issuedUnits ?? 0) - (ticket.soldUnits ?? 0), 0)
    }

    private func isSaleEnded(_ ticket: EventTicket) -> Bool {
        (ticket.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) < Date()
    }

    private func unavailableState(for tickets: [EventTicket]?) -> TicketUnavailableState? {
        guard let tickets = tickets?.filter({
            $0.isDeleted == false &&
            $0.isMembersOnly != true
        }), !tickets.isEmpty else {
            return nil
        }

        let sellingTickets = tickets.filter { $0.sellingPaused == false }
        guard !sellingTickets.isEmpty else {
            return .salePaused
        }

        let allUnavailable = sellingTickets.allSatisfy {
            isSaleEnded($0) || remainingQuantity(for: $0) <= 0
        }

        guard allUnavailable else {
            return nil
        }

        return sellingTickets.contains(where: isSaleEnded) ? .saleEnded : .soldOut
    }

    private func updateUnlockTicketVisibility() {
        let protectedTickets: [EventTicket]
        if event?.eventTicketSettings?.isUpFront == true {
            protectedTickets = availableTickets(from: event?.modifiedPasswordProtectedTicket)
        } else {
            protectedTickets = availableTickets(from: event?.protectedEventTicket)
        }
        unLockTicketView.isHidden = protectedTickets.isEmpty
    }
    
    private func setupData() {
        mainImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        titleLbl.text = event?.title ?? "Untitle Event"
        headerTitleLbl.text = event?.title ?? "Untitle Event"
        venueTitleLbl.text = (event?.customVenue != nil && venueDetails?.venueSettings?.isOrganizer == true) ? "\(event?.customVenue?.name ?? "") by \(venueDetails?.name ?? "")" : "\(venueDetails?.name ?? ""), \(venueDetails?.city ?? "")"
        organizerName.text = "\(venueDetails?.name ?? "")"
        organizerLocation.text = venueDetails?.website ?? "" != "" ? venueDetails?.website : event?.customVenue?.address ?? ""
        dressCodeView.isHidden = venueDetails?.venueSettings?.isOrganizer == true
        descriptionView.isHidden = venueDetails?.venueSettings?.isOrganizer ?? false == false
        descriptionText.text = venueDetails?.description ?? "-"
        organizerView.isHidden = !(venueDetails?.venueSettings?.isOrganizer == true)
        detailLbl.text = event?.description.withEmptyPlaceHolder ?? Constant.String.dash
        eventPolicyLbl.text = event?.disclaimer?.withEmptyPlaceHolder ?? Constant.String.dash
        dressCodeLbl.text = venueDetails?.dressCode?.withEmptyPlaceHolder ?? Constant.String.dash
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: event?.customVenue?.name ?? "Partner")
        dateLbl.text = "\(event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, customTimeZone: venueDetails?.useTimezone ?? "") ?? ""),"
        timingLbl.text = "\(event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: venueDetails?.useTimezone ?? "") ?? "") - \(event?.endDateTime?.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: venueDetails?.useTimezone ?? "") ?? "LATE")"
        artistTableView.reloadData()
        if event?.eventTicketSettings?.isUpFront == true {
            activeTickets = availableTickets(from: event?.modifiedEventTicket)
        } else {
            activeTickets = availableTickets(from: event?.eventTicket)
        }
        updateUnlockTicketVisibility()
        if event?.eventTicket == nil {
            isNotSellingStage = false
            updateContinueBtn(forceRemove: true)
        } else {
            if let unavailableState = unavailableState(for: event?.eventTicket) {
                switch unavailableState {
                case .salePaused:
                    continueBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
                case .saleEnded:
                    continueBtn.setTitle(Constant.String.saleEnded.uppercased(), for: .normal)
                case .soldOut:
                    continueBtn.setTitle(Constant.String.soldOut.uppercased(), for: .normal)
                }
                isNotSellingStage = true
                updateContinueBtn()
            } else if event?.isPausedSellingAllTickets == true {
                continueBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
                isNotSellingStage = true
                updateContinueBtn()
            } else if event?.eventTicket?.count ?? 0 == 0 || activeTickets?.isEmpty == true {
                continueBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
                isNotSellingStage = true
                updateContinueBtn()
            } else {
                let currencySymbole = venueDetails?.venueSettings?.currencySymbol ?? "$"
                let currencyPosition = venueDetails?.venueSettings?.currencyPosition
                let lowestVisiblePrice = activeTickets?.min { ($0.price ?? 0) < ($1.price ?? 0) }?.price ?? 0
                
                continueBtn.setTitle("BUY NOW - STARTING AT \(CurrencyFormatter.amount(Double(lowestVisiblePrice), symbol: currencySymbole, position: currencyPosition))", for: .normal)
                isNotSellingStage = false
                updateContinueBtn(forceRemove: true)
            }
        }
        eventAddressView.isHidden = !(event?.showAddress ?? true) ? true : false
        if venueDetails?.venueSettings?.isOrganizer == true {
            venueNameLbl.text = event?.customVenue?.name ?? ""
            locationLbl.text = event?.customVenue?.address ?? "-"
            updateLocationOnMap(to: CLLocationCoordinate2D(latitude: event?.customVenue?.latitude ?? 0, longitude: event?.customVenue?.longitude ?? 0), with: event?.customVenue?.name ?? "Partner")
        } else {
            venueNameLbl.text = venueDetails?.name ?? ""
            locationLbl.text = venueDetails?.address ?? "-"
            updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: event?.customVenue?.name ?? "Partner")
        }
        if venueDetails?.website ?? "" != "" {
            locationImage.image = UIImage(named: "ic-link")
            let tap = UITapGestureRecognizer(target: self, action: #selector(onClickWebSite))
            organizerLocationView.addGestureRecognizer(tap)
        }
    }
    
    @objc func onClickWebSite() {
        if let url = URL(string: venueDetails?.website ?? "") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func getEventDetail() {
        if eventId  == "" {
            zeroCaseView(isHidden: false)
            return
        }
        if event == nil {
            view.alpha = 0
        }
        Loader.show()
        EventPresenter.getEventDetail(eventId: eventId, venueTimeZone: venueDetails?.useTimezone, promotionLinkId: promoteId) { [weak self] _, _, eventDetail, errCode in
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
                    self.zeroCaseView(isHidden: false)
                }
            } else {
                self.event = eventDetail
                if let venue = eventDetail?.venue {
                    self.venueDetails = venue
                    self.reloadTicketListWithoutAnimation()
                }
                
                self.eventTicketId.removeAll()
                let ticket = self.event?.eventTicket ?? []
                ticket.forEach({tic in
                    self.eventTicketId.append(tic.id ?? "")
                })
                self.artists = self.event?.eventHasArtist?.filter( { $0.artist.status == "ENABLED" }) ?? []
                self.setupData()
                self.zeroCaseView(isHidden: true)
            }
        }
    }
    
    private func zeroCaseView(isHidden: Bool) {
        zeroCaseView.isHidden = isHidden
        shareBtn.isHidden = !isHidden
    }
    
    @objc func openFullImage() {
        updateContinueBtn(forceRemove: true)
        Navigate.to.presentGSImageViewerController(self, imageView: mainImg)
//        Navigate.to.fullScreenImg(self, imgURL: (event?.flyer?.key ?? "").imageURL)
    }
    
    @objc func openAppleMap() {
        if venueDetails?.venueSettings?.isOrganizer == true {
            let coordinate = CLLocationCoordinate2DMake(event?.customVenue?.latitude ?? 0, event?.customVenue?.longitude ?? 0)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
            mapItem.name = event?.customVenue?.name ?? ""
            mapItem.openInMaps()
        } else {
            let coordinate = CLLocationCoordinate2DMake(venueDetails?.latitude ?? 0, venueDetails?.longitude ?? 0)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
            mapItem.name = venueDetails?.name
            mapItem.openInMaps()
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
    
    @IBAction func onClickShare(_ sender: Any) {
        Utility.main.shareSocialWith(text: String(format: APIBuilder.eventWebURL, venueDetails?.name.lowercased().replacingOccurrences(of: " ", with: "-") ?? "", event?.title.lowercased().replacingOccurrences(of: " ", with: "-") ?? "", eventId))
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickUnLock(_ sender: Any) {
        guard !unlockPassword.isEmpty else {
            updateUnlockButtonState()
            return
        }
        getTicketByPassWord()
    }
    
    private func getTicketByPassWord() {
        EventPresenter.getEventTicketByPassWord(eventId: eventId, venueTimeZone: venueDetails?.useTimezone, password: unlockPassword) { isSuccess, errMsg, ticket in
            if isSuccess {
                let tickets = self.availableTickets(from: ticket)
                guard !tickets.isEmpty else {
                    self.invalidPasswordLbl.isHidden = false
                    return
                }
                guard var event = self.event else {
                    return
                }
                self.invalidPasswordLbl.isHidden = true
                if event.eventTicket == nil {
                    event.eventTicket = []
                }
                for tics in tickets {
                    if self.eventTicketId.contains(where: { $0 == tics.id}) == false {
                        self.eventTicketId.append(tics.id ?? "")
                    }
                    if (event.eventTicket?.contains(where: { $0.id == tics.id }) ?? false) == false {
                        event.eventTicket?.append(tics)
                    }
                }
                let unlockedIds = Set(tickets.compactMap { $0.id })
                event.protectedEventTicket = event.protectedEventTicket?.filter { protectedTicket in
                    guard let id = protectedTicket.id else {
                        return true
                    }
                    return !unlockedIds.contains(id)
                }
                self.event = event
                self.updateUnlockTicketVisibility()
                self.unLockTF.text = ""
                self.unLockPassword()
                self.setupData()
                self.reloadTicketListWithoutAnimation()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
    
    @IBAction private func onClickContinue(_ sender: Any) {
        if UserDefault.shared.isGuest == true {
            updateContinueBtn(forceRemove: true)
            Navigate.to.loginMandatory(self)
            return
        }
        switch selectedType {
        case .FREE:
//            getEventQuestions()
            if let selectedTickets = activeTickets?.filter({ $0.selectedTicketCount ?? 0 != 0 }) {
                Navigate.to.eventFreeCheckoutVC(self, event: event, selectedEventTicket: selectedTickets, venueDetails: venueDetails)
            }
        case .PAID, .CUSTOM:
            if let selectedTickets = activeTickets?.filter({ $0.selectedTicketCount != nil }) {
                Navigate.to.checkOutVC(self, venue: venueDetails, selectedCoverTickets: [], selectedEventTicket: selectedTickets, selectedAddOnsItem: [], event: event, totalPrice: totalPrice, type: .singleTickedEvent, promoteId: promoteId)
                updateContinueBtn(forceRemove: true)
            }
        }
    }
    
//    private func getEventQuestions() {
//        Loader.show()
//        PaymentPresenter.getEventBookingQuestion(eventUniqueId: event?.uniqueId ?? "") { [weak self] isSuccess, errMsg, questions in
//            guard let self = self else { return }
//            if isSuccess {
//                if questions?.count == 0 {
//                    self.createFreeEventBooking()
//                } else {
//                    Loader.hide()
//                    if let selectedTickets = activeTickets?.filter({ $0.selectedTicketCount != nil }) {
//                        Navigate.to.checkOutVC(self, venue: venueDetails, selectedCoverTickets: [], selectedEventTicket: selectedTickets, selectedAddOnsItem: [], event: event, totalPrice: totalPrice, type: .singleTickedEvent, promoteId: promoteId)
//                        updateContinueBtn(forceRemove: true)
//                    }
//                }
//            } else {
//                Loader.show()
//                if errMsg != nil {
//                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
//                } else {
//                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
//                }
//            }
//        }
//    }
    
//    private func createFreeEventBooking() {
//        if let selectedTickets = activeTickets?.filter({ $0.selectedTicketCount != nil }) {
//            var tickets = [[String: Any]]()
//            selectedTickets.forEach {
//                tickets.append(["ticketId": $0.id ?? 0,
//                                "ticketQuantity": $0.selectedTicketCount ?? 0])
//            }
//            
//            PaymentPresenter.createEventFreeBooking(eventId: event?.id ?? "", phone: UserDefault.shared.user?.phone ?? "", userId: UserDefault.shared.user?.id ?? "", tickets: tickets) { [weak self] isSuccess, errMsg, id, massage  in
//                guard let self = self else {
//                    Loader.hide()
//                    return
//                }
//                Loader.hide()
//                if isSuccess, let id = id {
//                    Navigate.to.showQRCode(self, booking: nil, bookingId: id, type: .singleTickedEvent)
//                } else {
//                    Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
//                }
//            }
//        }
//    }
    
    func updateContinueBtn(forceRemove: Bool = false) {
        if isNotSellingStage {
            continueBtn.isUserInteractionEnabled = false
            continueBtn.backgroundColor = continueBtn.backgroundColor?.withAlphaComponent(0.5)
            continueBtn.isHidden = false
            continueBtnBGView.isHidden = false
            scrollViewBottomConstraint.constant = 90
            return
        }
        continueBtn.isUserInteractionEnabled = true
        continueBtn.backgroundColor = continueBtn.backgroundColor?.withAlphaComponent(1)
        continueBtnBGView.isHidden = true
        DispatchQueue.main.async {
            if forceRemove {
                self.activeTickets?.indices.forEach {
                    self.activeTickets?[$0].selectedTicketCount = nil
                }
                self.continueBtn.isHidden = true
                self.scrollViewBottomConstraint.constant = 30
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT", for: .normal)
                self.reloadTicketListWithoutAnimation()
                return
            }
            self.continueBtn.isHidden = false
            switch self.selectedType {
            case .FREE:
                self.continueBtn.setTitle("GET MY FREE TICKET", for: .normal)
            case .PAID, .CUSTOM:
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT", for: .normal)
            }
        }
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if let totalTicket = activeTickets?[sender.tag].selectedTicketCount {
            if totalTicket > 1 {
                activeTickets?[sender.tag].selectedTicketCount = totalTicket - 1
                reloadTicketListWithoutAnimation()
                updateContinueBtn()
            } else if totalTicket == 1 {
                activeTickets?[sender.tag].selectedTicketCount = nil
                reloadTicketListWithoutAnimation()
                updateContinueBtn(forceRemove: (activeTickets?.firstIndex(where: { $0.selectedTicketCount != nil })) == nil)
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if isMaxTicketReached {
            Alert.showToast("Max ticket selection reached")
            return
        }
        if let totalTicket = activeTickets?[sender.tag].selectedTicketCount {
            if totalTicket < maxTicket {
                if let remaining = activeTickets?[sender.tag].remainingQuantity, remaining > totalTicket {
                    activeTickets?[sender.tag].selectedTicketCount = totalTicket + 1
                    reloadTicketListWithoutAnimation()
                    updateContinueBtn()
                }
            } else {
                Alert.showToast("Max ticket selection reached")
            }
        }
    }
    
    private func forceRemoveFreeTicket() {
        self.activeTickets?.indices.forEach {
            if activeTickets?[$0].price ?? 0 == 0 {
                self.activeTickets?[$0].selectedTicketCount = nil
            }
        }
        selectedType = .PAID
    }

    private func forceRemovePaidTicket() {
        self.activeTickets?.indices.forEach {
            if activeTickets?[$0].price ?? 0 == 0 {
            } else {
                self.self.activeTickets?[$0].selectedTicketCount = nil
            }
        }
        selectedType = .FREE
    }
}

extension EventDetailVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case ticketListTableView:
            let tick = activeTickets?.filter({ $0.beginSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date() <= Date() })
            activeTickets = tick
            return activeTickets?.count ?? 0
        case artistTableView:
            lineUpView.isHidden = artists.count == 0
            return artists.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case ticketListTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TicketTypeTableViewCell", for: indexPath) as! TicketTypeTableViewCell
            cell.ticketTypeLbl.text = activeTickets?[indexPath.row].tierName
            cell.infoLbl.text = activeTickets?[indexPath.row].tierDescription
            if activeTickets?[indexPath.row].price ?? 0 == 0 {
                cell.ticketPriceLbl.text = "FREE"
                cell.plusBtn.alpha = 0.5
                cell.plusBtn.isUserInteractionEnabled = false
            } else {
                let currencySymbole = venueDetails?.venueSettings?.currencySymbol ?? "$"
                let currencyPosition = venueDetails?.venueSettings?.currencyPosition
                
                cell.ticketPriceLbl.text = CurrencyFormatter.amount(Double(activeTickets?[indexPath.row].price ?? 0), symbol: currencySymbole, position: currencyPosition)
                
//                cell.ticketPriceLbl.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\(event?.eventTicketSettings?.isUpFront == true ? (activeTickets?[indexPath.row].priceWithFees ?? 0).decimalFormat(true) : Double(activeTickets?[indexPath.row].price ?? 0).decimalFormat(true))"
                
                cell.plusBtn.alpha = isMaxTicketReached ? 0.5 : 1
                cell.plusBtn.isUserInteractionEnabled = true
            }
            cell.ticketPriceLbl.textColor = .white
            cell.ticketTypeLbl.textColor = .white
            if activeTickets?[indexPath.row].selectedTicketCount ?? 0 >= 1 {
                cell.ticketPlusMinusView.isHidden = false
            } else {
                cell.ticketPlusMinusView.isHidden = true
            }
            if let remaining = activeTickets?[indexPath.row].remainingQuantity, remaining <= 20 {
                cell.hotVenueLbl.isHidden = false
                if remaining == 0 {
                    cell.hotVenueLbl.text = "Sold out"
                } else {
                    cell.hotVenueLbl.text = "Only \(remaining) left"
                }
            } else {
                cell.hotVenueLbl.isHidden = true
            }
            cell.totalTicketLbl.text = "\(activeTickets?[indexPath.row].selectedTicketCount ?? 0)"
            cell.minusBtn.tag = indexPath.row
            cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
            cell.plusBtn.tag = indexPath.row
            cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
            
            if let remaining = activeTickets?[indexPath.row].remainingQuantity, let selectedTicket = activeTickets?[indexPath.row].selectedTicketCount, remaining <= selectedTicket {
                cell.plusBtn.alpha = 0.5
            }
            cell.selectionStyle = .none
            cell.layoutIfNeeded()
            return cell
        case artistTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ArtistListTVC", for: indexPath) as! ArtistListTVC
            cell.mainImg.sd_setImage(with: URL(string: (artists[indexPath.row].artist.artistImage?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            cell.nameLbl.text = artists[indexPath.row].artist.name
            cell.selectionStyle = .none
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case ticketListTableView:
            if activeTickets?[indexPath.row].sellingPaused == true {
                return 0
            }
        default:
            break
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case ticketListTableView:
            if activeTickets?[indexPath.row].selectedTicketCount != nil { return }
            if isMaxTicketReached {
                Alert.showToast("Max ticket selection reached")
                return
            }
            if let startDate = activeTickets?[indexPath.row].beginSale, (startDate.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date() {
                Alert.showAlertSheet(style: .alert, title: nil, message: String(format: Constant.String.ticketSellingWillStartAt, startDate.convertDateFormat(from: .yyyyMMddHHmmss, to: .MMMMddHHmm, useDayLightSavingTime: true, customTimeZone: venueDetails?.useTimezone ?? "")))
                return
            }
            
            if let remaining = activeTickets?[indexPath.row].remainingQuantity, remaining >= 1 {
                activeTickets?[indexPath.row].selectedTicketCount = 1
            } else {
                Alert.showToast("Sold out")
                return
            }
            
            continueBtn.isHidden = false
            scrollViewBottomConstraint.constant = 90
            if activeTickets?[indexPath.row].price ?? 0 == 0 {
                forceRemovePaidTicket()
            } else {
                forceRemoveFreeTicket()
            }
            reloadTicketListWithoutAnimation()
            if totalSelectedTickets == 0 {
                updateContinueBtn(forceRemove: true)
            } else {
                updateContinueBtn()
            }
        case artistTableView:
            updateContinueBtn(forceRemove: true)
            Navigate.externalURL(event?.eventHasArtist?[indexPath.row].artist.instagramUsername ?? "")
        default:
            break
        }
    }
}

extension EventDetailVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 350 {
            headerTitleLbl.isHidden = false
            headerView.backgroundColor = .black
        } else {
            headerTitleLbl.isHidden = true
            headerView.backgroundColor = .clear
        }
    }
}

extension EventDetailVC: UpdateDetailDelegate {
    func update() {
        Loader.show()
        event?.eventTicket?.removeAll()
        activeTickets?.removeAll()
        event?.protectedEventTicket?.removeAll()
        unLockTicketView.isHidden = true
        updateContinueBtn(forceRemove: true)
        getEventDetail()
    }
}

extension EventDetailVC: WebSocketCallBackDelegate {
    func didUpdateEvent(eventId: String) {
        update()
    }
}
