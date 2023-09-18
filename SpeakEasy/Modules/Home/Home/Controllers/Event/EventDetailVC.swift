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

    var eventId: String?
    var venueDetails: ClipVenue?
    var event: Event?
    var promoteId = ""
    var isDiscounted: String? = nil
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var artistHeightObservation: NSKeyValueObservation?
    private var isNotSellingStage = false
    private var maxTicket = 20
    private var activeTickets: [EventTicket]?
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

    override func viewDidLoad() {
        super.viewDidLoad()
        getEventDetail()
        setupData()
        headerTitleLbl.isHidden = true
        headerView.backgroundColor = .clear
        scrollView.delegate = self
        // TODO: add webSocket to sync tier left ticket
        // WebSocketWrapper.shared.delegate.append(self)
        updateContinueBtn(forceRemove: true)
        ticketListTableView.register(UINib(nibName: "ticketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "ticketTypeTableViewCell")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
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
    }
    
    private func setupData() {
        mainImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        titleLbl.text = event?.title ?? "Untitle Event"
        headerTitleLbl.text = event?.title ?? "Untitle Event"
        venueTitleLbl.text = "\(venueDetails?.name ?? ""), \(venueDetails?.city ?? "")"
        venueNameLbl.text = "Venue - \(venueDetails?.name ?? "")"
        detailLbl.text = event?.description.withEmptyPlaceHolder ?? Constant.String.dash
        eventPolicyLbl.text = event?.disclaimer?.withEmptyPlaceHolder ?? Constant.String.dash
        locationLbl.text = venueDetails?.address
        dressCodeLbl.text = venueDetails?.dressCode?.withEmptyPlaceHolder ?? Constant.String.dash
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: venueDetails?.name)
        dateLbl.text = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: venueDetails?.useTimezone ?? "")
        timingLbl.text = "• \(event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: venueDetails?.useTimezone ?? "") ?? "") - \(event?.endDateTime?.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: venueDetails?.useTimezone ?? "") ?? "LATE")"
        artistTableView.reloadData()
        activeTickets = event?.eventTicket?.filter { ($0.isDeleted == false) && ($0.sellingPaused == false) && (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date()) && ($0.issuedUnits ?? 0 >= $0.soldUnits ?? 0)} ?? []
        if event?.eventTicket == nil {
            isNotSellingStage = false
            updateContinueBtn(forceRemove: true)
        } else {
            if event?.isPausedSellingAllTickets == true {
                continueBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
                isNotSellingStage = true
                updateContinueBtn()
            } else if event?.isSoldOutAllTickets == true {
                continueBtn.setTitle(Constant.String.soldOut.uppercased(), for: .normal)
                isNotSellingStage = true
                updateContinueBtn()
            } else if event?.eventTicket?.count ?? 0 == 0 {
                continueBtn.setTitle(Constant.String.salePaused.uppercased(), for: .normal)
                isNotSellingStage = true
                updateContinueBtn()
            } else {
                continueBtn.setTitle("BUY NOW - STARTING AT \(venueDetails?.venueSettings?.currencySymbol ?? "$")\(event?.lowestPriceTicket?.price ?? 0)", for: .normal)
                isNotSellingStage = false
                updateContinueBtn(forceRemove: true)
            }
        }
    }
    
    private func getEventDetail() {
        if eventId ?? "" == "" {
            zeroCaseView(isHidden: false)
            return
        }
        if event == nil {
            view.alpha = 0
            Loader.show()
        }
        EventPresenter.getEventDetail(eventId: eventId ?? "", venueTimeZone: venueDetails?.useTimezone, promotionLinkId: promoteId, isDiscounted: isDiscounted) { [weak self] isSuccess, errMsg, eventDetail, errCode in
            guard let self = self else {
                return
            }
            self.view.alpha = 1
            Loader.hide()
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
                    self.ticketListTableView.reloadData()
                }
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
        // TODO: check and remove full screen vc
//        Navigate.to.fullScreenImg(self, imgURL: (event?.flyer?.key ?? "").imageURL)
    }
    
    @objc func openAppleMap() {
        let coordinate = CLLocationCoordinate2DMake(venueDetails?.latitude ?? 0, venueDetails?.longitude ?? 0)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        mapItem.name = venueDetails?.name
        mapItem.openInMaps()
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
        Utility.main.shareSocialWith(text: String(format: APIBuilder.eventWebURL, eventId ?? ""))
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction private func onClickContinue(_ sender: Any) {
        if UserDefault.shared.isGuest == true {
            updateContinueBtn(forceRemove: true)
            Navigate.to.loginMandatory(self)
            return
        }
        switch selectedType {
        case .FREE:
            createFreeEventBooking()
        case .PAID:
            if let selectedTickets = activeTickets?.filter({ $0.selectedTicketCount != nil }) {
                Navigate.to.checkOutVC(self, venue: venueDetails, selectedAppClipTickets: [], selectedEventTicket: selectedTickets, event: event, totalPrice: totalPrice, type: .singleTickedEvent, promoteId: promoteId)
                updateContinueBtn(forceRemove: true)
            }
        }
    }
    
    private func createFreeEventBooking() {
        if let selectedTickets = activeTickets?.filter({ $0.selectedTicketCount != nil }) {
            var tickets = [[String: Any]]()
            selectedTickets.forEach {
                tickets.append(["ticketId": $0.id,
                                "ticketQuantity": $0.selectedTicketCount ?? 0])
            }
            Loader.show()
            PaymentPresenter.createEventFreeBooking(eventId: event?.id ?? "", phone: UserDefault.shared.user?.phone ?? "", userId: UserDefault.shared.user?.id ?? "", tickets: tickets) { [weak self] isSuccess, errMsg, id in
                guard let self = self else {
                    Loader.hide()
                    return
                }
                Loader.hide()
                if isSuccess, let id = id {
                    Navigate.to.QRCode(self, booking: nil, bookingId: id, type: .singleTickedEvent)
                } else {
                    Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
    
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
                self.ticketListTableView.reloadData()
                return
            }
            self.continueBtn.isHidden = false
            switch self.selectedType {
            case .FREE:
                self.continueBtn.setTitle("GET MY FREE TICKET", for: .normal)
            case .PAID:
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT -  \(self.venueDetails?.venueSettings?.currencySymbol ?? "$")\(String(format: "%.2f", self.totalPrice))", for: .normal)
            }
        }
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if let totalTicket = activeTickets?[sender.tag].selectedTicketCount {
            if totalTicket > 1 {
                activeTickets?[sender.tag].selectedTicketCount = totalTicket - 1
                ticketListTableView.reloadData()
                updateContinueBtn()
            } else if totalTicket == 1 {
                activeTickets?[sender.tag].selectedTicketCount = nil
                ticketListTableView.reloadData()
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
                    ticketListTableView.reloadData()
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
            return activeTickets?.count ?? 0
        case artistTableView:
            lineUpView.isHidden = event?.artists?.count ?? 0 == 0
            return event?.artists?.count ?? 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case ticketListTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTypeTableViewCell", for: indexPath) as! ticketTypeTableViewCell
            cell.ticketTypeLbl.text = activeTickets?[indexPath.row].tierName
            cell.infoLbl.text = activeTickets?[indexPath.row].tierDescription
            if activeTickets?[indexPath.row].price ?? 0 == 0 {
                cell.ticketPriceLbl.text = "FREE"
                cell.plusBtn.alpha = 0.5
                cell.plusBtn.isUserInteractionEnabled = false
            } else {
                cell.ticketPriceLbl.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\(String(format: "%.2f", event?.upfront == true ? activeTickets?[indexPath.row].priceWithFees ?? 0 : Double(activeTickets?[indexPath.row].price ?? 0)))"
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
            cell.mainImg.sd_setImage(with: URL(string: (event?.artists?[indexPath.row].image?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            cell.nameLbl.text = event?.artists?[indexPath.row].name
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
            ticketListTableView.reloadData()
            if totalSelectedTickets == 0 {
                updateContinueBtn(forceRemove: true)
            } else {
                updateContinueBtn()
            }
        case artistTableView:
            updateContinueBtn(forceRemove: true)
            Navigate.externalURL(event?.artists?[indexPath.row].instagramUsername ?? "")
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
        getEventDetail()
    }
}
