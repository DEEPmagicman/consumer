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
    private var gradient: CAGradientLayer?
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var artistHeightObservation: NSKeyValueObservation?
    private var isNotSellingStage = false
    private var maxTicket = 20
    private var totalPrice: Int {
        var total = 0
        event?.eventTicket?.forEach {
            if let quantity = $0.selectedTicketCount {
                total += (($0.price ?? 0) * quantity)
            }
        }
        return total
    }
    private var isMaxTicketReached: Bool {
        totalSelectedTickets >= maxTicket
    }
    private var totalSelectedTickets: Int {
        var total = 0
        event?.eventTicket?.forEach {
            if let quantity = $0.selectedTicketCount {
                total += quantity
            }
        }
        return total
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        gradient = mainImg.setGradientColor()
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gradient = mainImg.setGradientColor()
    }
    
    private func setupData() {
        mainImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        titleLbl.text = event?.title ?? "Untitle Event"
        headerTitleLbl.text = event?.title ?? "Untitle Event"
        venueTitleLbl.text = "\(venueDetails?.name ?? ""), \(venueDetails?.city ?? "")"
        venueNameLbl.text = "Venue - \(venueDetails?.name ?? "")"
        detailLbl.text = event?.description
        eventPolicyLbl.text = event?.disclaimer
        locationLbl.text = venueDetails?.address
        dressCodeLbl.text = venueDetails?.dressCode
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: venueDetails?.name)
        dateLbl.text = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: venueDetails?.useTimezone ?? "")
        timingLbl.text = "• \(event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: venueDetails?.useTimezone ?? "") ?? "") - \(event?.endDateTime?.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma, customTimeZone: venueDetails?.useTimezone ?? "") ?? "LATE")"
        artistTableView.reloadData()
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
            continueBtn.setTitle("BUY NOW - STARTING AT $\(event?.lowestPriceTicket?.price ?? 0)", for: .normal)
            isNotSellingStage = false
            updateContinueBtn(forceRemove: true)
        }
    }
    
    private func getEventDetail() {
        if eventId ?? "" == "" {
            zeroCaseView(isHidden: false)
            return
        }
        EventPresenter.getEventDetail(eventId: eventId ?? "", venueTimeZone: venueDetails?.useTimezone) { [weak self] isSuccess, errMsg, eventDetail in
            guard let self = self else {
                return
            }
            if eventDetail == nil {
                self.zeroCaseView(isHidden: false)
            } else {
                self.event = eventDetail
                if let venue = eventDetail?.venue {
                    self.venueDetails = venue
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
        Navigate.to.fullScreenImg(self, imgURL: (event?.flyer?.key ?? "").imageURL)
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
        let msgText = """
 Download Speakeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues.

 Link to App: https://apps.apple.com/us/app/speakeasy-go/id1642351956
 """
         Utility.main.shareSocialWith(text: msgText)
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
        if let selectedTickets = event?.eventTicket?.filter({ $0.selectedTicketCount != nil }) {
            Navigate.to.checkOutVC(self, venueName: venueDetails?.name ?? "", venueId: venueDetails?.id ?? "", uniqueId: venueDetails?.uniqueId ?? "", venueAttachment: venueDetails?.venueAttachment.first?.key ?? "", venueLogo: venueDetails?.logo?.key ?? "", selectedAppClipTickets: [], selectedEventTicket: selectedTickets, event: event, totalPrice: totalPrice, type: .singleTickedEvent)
            updateContinueBtn(forceRemove: true)
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
                self.event?.eventTicket?.indices.forEach {
                    self.event?.eventTicket?[$0].selectedTicketCount = nil
                }
                self.continueBtn.isHidden = true
                self.scrollViewBottomConstraint.constant = 30
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT", for: .normal)
                self.ticketListTableView.reloadData()
                return
            }
            self.continueBtn.isHidden = false
            self.continueBtn.setTitle("CONTINUE TO CHECKOUT -  $\(self.totalPrice)", for: .normal)
        }
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if let totalTicket = event?.eventTicket?[sender.tag].selectedTicketCount {
            if totalTicket > 1 {
                event?.eventTicket?[sender.tag].selectedTicketCount = totalTicket - 1
                ticketListTableView.reloadData()
                updateContinueBtn()
            } else if totalTicket == 1 {
                event?.eventTicket?[sender.tag].selectedTicketCount = nil
                ticketListTableView.reloadData()
                updateContinueBtn(forceRemove: (event?.eventTicket?.firstIndex(where: { $0.selectedTicketCount != nil })) == nil)
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if isMaxTicketReached {
            Alert.showToast("Max ticket selection reached")
            return
        }
        if let totalTicket = event?.eventTicket?[sender.tag].selectedTicketCount {
            if totalTicket < maxTicket {
                if let remaining = event?.eventTicket?[sender.tag].remainingQuantity, remaining > totalTicket {
                    event?.eventTicket?[sender.tag].selectedTicketCount = totalTicket + 1
                    ticketListTableView.reloadData()
                    updateContinueBtn()
                }
            } else {
                Alert.showToast("Max ticket selection reached")
            }
        }
    }
}

extension EventDetailVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case ticketListTableView:
            return event?.eventTicket?.count ?? 0
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
            cell.ticketTypeLbl.text = event?.eventTicket?[indexPath.row].tierName
            cell.infoLbl.text = event?.eventTicket?[indexPath.row].tierDescription
            cell.ticketPriceLbl.text = "$\(event?.eventTicket?[indexPath.row].price ?? 0)"
            cell.ticketPriceLbl.textColor = .white
            cell.ticketTypeLbl.textColor = .white
            if event?.eventTicket?[indexPath.row].selectedTicketCount ?? 0 >= 1 {
                cell.ticketPlusMinusView.isHidden = false
            } else {
                cell.ticketPlusMinusView.isHidden = true
            }
            if let remaining = event?.eventTicket?[indexPath.row].remainingQuantity, remaining <= 20 {
                cell.hotVenueLbl.isHidden = false
                if remaining == 0 {
                    cell.hotVenueLbl.text = "Sold out"
                } else {
                    cell.hotVenueLbl.text = "Only \(remaining) left"
                }
            } else {
                cell.hotVenueLbl.isHidden = true
            }
            cell.totalTicketLbl.text = "\(event?.eventTicket?[indexPath.row].selectedTicketCount ?? 0)"
            cell.minusBtn.tag = indexPath.row
            cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
            cell.plusBtn.tag = indexPath.row
            cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
            cell.plusBtn.alpha = isMaxTicketReached ? 0.5 : 1
            if let remaining = event?.eventTicket?[indexPath.row].remainingQuantity, let selectedTicket = event?.eventTicket?[indexPath.row].selectedTicketCount, remaining <= selectedTicket {
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
            if event?.eventTicket?[indexPath.row].sellingPaused == true {
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
            if event?.eventTicket?[indexPath.row].selectedTicketCount != nil { return }
            if isMaxTicketReached {
                Alert.showToast("Max ticket selection reached")
                return
            }
            if let startDate = event?.eventTicket?[indexPath.row].beginSale, (startDate.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date() {
                Alert.showAlertSheet(style: .alert, title: nil, message: String(format: Constant.String.ticketSellingWillStartAt, startDate.convertDateFormat(from: .yyyyMMddHHmmss, to: .MMMMddHHmm, useDayLightSavingTime: true, customTimeZone: venueDetails?.useTimezone ?? "")))
                return
            }
            
            if let remaining = event?.eventTicket?[indexPath.row].remainingQuantity, remaining >= 1 {
                event?.eventTicket?[indexPath.row].selectedTicketCount = 1
            } else {
                Alert.showToast("Sold out")
                return
            }
            
            continueBtn.isHidden = false
            scrollViewBottomConstraint.constant = 90
            ticketListTableView.reloadData()
            if totalSelectedTickets == 0 {
                updateContinueBtn(forceRemove: true)
            } else {
                updateContinueBtn()
            }
        case artistTableView:
            updateContinueBtn(forceRemove: true)
            Navigate.openInstagramForUsername(event?.artists?[indexPath.row].instagramUsername ?? "")
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
            if scrollView.contentOffset.y <= 0 {
                gradient?.frame = mainImg.bounds
            }
            headerTitleLbl.isHidden = true
            headerView.backgroundColor = .clear
        }
    }
}
