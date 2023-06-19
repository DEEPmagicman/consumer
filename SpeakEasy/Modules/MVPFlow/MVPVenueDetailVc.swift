//
//  MVPVenueDetailVc.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit
import SDWebImage
import MapKit

final class MVPVenueDetailVc: UIViewController {

    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var venueBgImg: UIImageView!
    @IBOutlet weak var venueTitleNameLbl: UILabel!
    @IBOutlet weak var cityNameLbl: UILabel!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var logoImg: UIImageView!
    @IBOutlet weak var ticketTypeTableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var liveLbl: UILabel!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var updatedAtLbl: UILabel!
    @IBOutlet weak var headerVenueName: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toNightLbl: UILabel!
    @IBOutlet weak var venuePageView: UIView!
    @IBOutlet weak var todaysEventsView: UIView!
    @IBOutlet weak var todaysEventTableView: UITableView!
    @IBOutlet weak var todaysEventTableHeight: NSLayoutConstraint!
    @IBOutlet weak var closeTicketView: UIView!
    @IBOutlet weak var tonightView: UIView!
    @IBOutlet weak var openingHoursView: UIView!
    @IBOutlet weak var dressCodeView: UIView!
    @IBOutlet weak var dressCodeLbl: UILabel!
    @IBOutlet weak var venuePolicyView: UIView!
    @IBOutlet weak var upcomingSectionView: UIView!
    @IBOutlet weak var openingTableHeight: NSLayoutConstraint!
    @IBOutlet weak var openingHoursTableView: UITableView!
    @IBOutlet weak var upcomingTableView: UITableView!
    @IBOutlet weak var upcomingTableHeight: NSLayoutConstraint!
    @IBOutlet weak var venuePolicyLbl: UILabel!
    @IBOutlet private weak var zeroCaseView: UIView!

    var venueId = ""
    var venueUniqueId = ""
    var isFromAppClip = false
    private let presenter = MVPPresenter()
    private var venueDetails: ClipVenue?
    private var maxTicket = 20
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var hoursHeightObservation: NSKeyValueObservation?
    private var upcomingHeightObservation: NSKeyValueObservation?
    private var todaysEventHeightObservation: NSKeyValueObservation?
    private var from = 0
    private var hasMore = false
    private var totalPrice: Int {
        var total = 0
        venueDetails?.appClipTicket?.forEach {
            if let quantity = $0.selectedQuantity {
                total += ($0.price * quantity)
            }
        }
        return total
    }
    private var isMaxTicketReached: Bool {
        var total = 0
        venueDetails?.appClipTicket?.forEach {
            if let quantity = $0.selectedQuantity {
                total += quantity
            }
        }
        return total >= maxTicket
    }
    private var events = [Event]()
    private var todaysEvents = [Event]()
    private var gradient: CAGradientLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gradient = venueBgImg.setGradientColor()
        headerVenueName.isHidden = true
        headerView.backgroundColor = .clear
        scrollView.delegate = self
        backBtn.isHidden = isFromAppClip
        ticketTypeTableView.register(UINib(nibName: "ticketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "ticketTypeTableViewCell")
        ticketListHeightObservation = ticketTypeTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.tableViewHeight.constant = self.ticketTypeTableView.contentSize.height
            self.ticketTypeTableView.layoutIfNeeded()
        }
        WebSocketWrapper.shared.delegate.append(self)
        getVenueDetail()
        updateContinueBtn(forceRemove: true)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openAppleMap))
        self.mapView.addGestureRecognizer(tap)
        openingHoursTableView.register(UINib(nibName: "HoursTVC", bundle: nil), forCellReuseIdentifier: "HoursTVC")
        hoursHeightObservation = openingHoursTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.openingTableHeight.constant = self.openingHoursTableView.contentSize.height
            self.openingHoursTableView.layoutIfNeeded()
        }
        upcomingTableView.register(UINib(nibName: "DetailTVC", bundle: nil), forCellReuseIdentifier: "DetailTVC")
        upcomingHeightObservation = upcomingTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.upcomingTableHeight.constant = self.upcomingTableView.contentSize.height
            self.upcomingTableView.layoutIfNeeded()
        }
        todaysEventTableView.register(UINib(nibName: "DetailTVC", bundle: nil), forCellReuseIdentifier: "DetailTVC")
        todaysEventHeightObservation = todaysEventTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.todaysEventTableHeight.constant = self.todaysEventTableView.contentSize.height
            self.todaysEventTableView.layoutIfNeeded()
        }
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        gradient = venueBgImg.setGradientColor()
//    }
    
    private func getVenueDetail(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        presenter.getVenuesDetailForaMVP(venueId: venueUniqueId) { [weak self] isSuccess, errMsg, venueDetail in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                self.venueDetails = venueDetail
                self.setUpUI()
                self.ticketTypeTableView.reloadData()
                self.openingHoursTableView.reloadData()
                self.updateContinueBtn(forceRemove: true)
                self.updateCloseViewVisibility()
                self.zeroCaseView(isHidden: true)
            } else {
                self.zeroCaseView(isHidden: false)
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
            self.getEvents()
            #if DEBUG
            if withLoader == false && self.navigationController?.viewControllers.last is MVPVenueDetailVc {
                Alert.showToast("Venue detail updated")
            }
            #endif
            Loader.hide()
        }
    }
    
    private func getEvents() {
        Loader.show()
        // TODO: add pagination
        EventPresenter.getEvents(venueId: venueId, venueTimeZone: venueDetails?.useTimezone) { [weak self] isSuccess, errMsg, eventList, hasMore in
            guard let self = self else {
                Loader.hide()
                return
            }
            self.events = eventList
            self.upcomingSectionView.isHidden = eventList.count == 0
            self.upcomingTableView.reloadData()
            self.hasMore = hasMore
            self.updateCloseViewVisibility()
            Loader.hide()
        }
        EventPresenter.getEvents(venueId: venueId, time: "TODAY", venueTimeZone: venueDetails?.useTimezone) { [weak self] isSuccess, errMsg, eventList, hasMore in
            guard let self = self else {
                Loader.hide()
                return
            }
            self.todaysEvents = eventList
            self.todaysEventTableView.reloadData()
            self.updateCloseViewVisibility()
            Loader.hide()
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
    
    @objc func openAppleMap() {
        let coordinate = CLLocationCoordinate2DMake(venueDetails?.latitude ?? 0, venueDetails?.longitude ?? 0)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        mapItem.name = venueDetails?.name
        mapItem.openInMaps()
    }
    
    private func setUpUI() {
        venueBgImg.sd_setImage(with: URL(string: (venueDetails?.venueAttachment.first?.key ?? "").imageURL),completed: nil)
        logoImg.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),completed: nil)
        venueTitleNameLbl.text = venueDetails?.name
        cityNameLbl.text = venueDetails?.city
        headerVenueName.text = venueDetails?.name
        locationLbl.text = venueDetails?.address
        dressCodeLbl.text = venueDetails?.dressCode?.withEmptyPlaceHolder ?? Constant.String.dash
        venueNameLbl.text = "Venue - \(venueDetails?.name ?? "")"
        venuePolicyLbl.text = String(format: Constant.String.venuePolicy, venueDetails?.name ?? "venue")
        if venueDetails?.bookingStatus == "OPEN" {
            liveLbl.text = venueDetails?.displayWaitTime
            liveLbl.textColor = UIColor(red: 0/255, green: 255/255, blue: 148/255, alpha: 1)
            updatedAtLbl.isHidden = false
            liveLbl.font = UIFont(name: "Poppins-SemiBold", size: 16)
            toNightLbl.alpha = 1
        } else {
            toNightLbl.alpha = 0.5
            updatedAtLbl.isHidden = true
            liveLbl.text = "CLOSED"
            liveLbl.font = UIFont(name: "Poppins-SemiBold", size: 18)
            liveLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
        }
        if venueDetails?.appClipTicket?.allSatisfy({ ticket in
            ticket.status == "DISABLED"
        }) == true {
            updateCloseViewVisibility()
            tonightView.isHidden = true
            venuePageView.isHidden = true
        } else {
            venuePageView.isHidden = false
            tonightView.isHidden = false
            closeTicketView.isHidden = true
        }
        updatedAtLbl.text = venueDetails?.updatedAt.displayUpdatedAgo(from: .yyyyMMddTHHmmssSSSz, to: .hmm_a) ?? ""
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: venueDetails?.name)
    }
    
    private func updateCloseViewVisibility() {
        if (events.count == 0 && todaysEvents.count == 0 && (venueDetails?.appClipTicket?.allSatisfy({ ticket in
            ticket.status == "DISABLED"
        }) == true)) {
            closeTicketView.isHidden = false
        } else {
            closeTicketView.isHidden = true
        }
    }
    
    private func zeroCaseView(isHidden: Bool) {
        zeroCaseView.isHidden = isHidden
        shareBtn.isHidden = !isHidden
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        if UserDefault.shared.isGuest == true {
            Navigate.to.loginMandatory(self)
            return
        }
        if let selectedTickets = venueDetails?.appClipTicket?.filter({ $0.selectedQuantity != nil }) {
            Navigate.to.checkOutVC(self, venue: venueDetails, selectedAppClipTickets: selectedTickets, selectedEventTicket: [], totalPrice: totalPrice, type: .appClip)
        }
    }
    
    @IBAction func onClickShare(_ sender: Any) {
        let msgText = """
 Download Speakeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues.

 Link to venue: \(String(format: APIBuilder.venueWebURL, venueUniqueId))
 """
         Utility.main.shareSocialWith(text: msgText)
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
}

extension MVPVenueDetailVc: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case ticketTypeTableView:
            return venueDetails?.appClipTicket?.count ?? 0
        case openingHoursTableView:
            openingHoursView.isHidden = venueDetails?.openHours.count == 0
            return venueDetails?.openHours.count ?? 0
        case upcomingTableView:
            upcomingSectionView.isHidden = events.count == 0
            return events.count
        case todaysEventTableView:
            todaysEventsView.isHidden = todaysEvents.count == 0
            return todaysEvents.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case ticketTypeTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTypeTableViewCell", for: indexPath) as! ticketTypeTableViewCell
            cell.ticketTypeLbl.text = venueDetails?.appClipTicket?[indexPath.row].name
            cell.infoLbl.text = venueDetails?.appClipTicket?[indexPath.row].description
            if venueDetails?.appClipTicket?[indexPath.row].price ?? 0 < 5 && venueDetails?.appClipTicket?[indexPath.row].name.lowercased().contains("general") == true {
                cell.ticketPriceLbl.text = "FREE"
            } else {
                cell.ticketPriceLbl.text = "$\(venueDetails?.appClipTicket?[indexPath.row].price ?? 0)"
            }
            if venueDetails?.bookingStatus == "OPEN" && venueDetails?.appClipTicket?[indexPath.row].status == "ENABLED" {
                cell.ticketPriceLbl.textColor = .white
                cell.ticketTypeLbl.textColor = .white
            } else {
                cell.ticketPriceLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
                cell.ticketTypeLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
            }
            if venueDetails?.appClipTicket?[indexPath.row].selectedQuantity ?? 0 >= 1 {
                cell.ticketPlusMinusView.isHidden = false
            } else {
                cell.ticketPlusMinusView.isHidden = true
            }
            if venueDetails?.checkInUser ?? 0 > 100 {
                cell.hotVenueLbl.isHidden = false
            } else {
                cell.hotVenueLbl.isHidden = true
            }
            cell.minusBtn.tag = indexPath.row
            cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
            cell.plusBtn.tag = indexPath.row
            cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
            cell.totalTicketLbl.text = "\(venueDetails?.appClipTicket?[indexPath.row].selectedQuantity ?? 0)"
            cell.plusBtn.alpha = isMaxTicketReached ? 0.5 : 1
            cell.selectionStyle = .none
            cell.layoutIfNeeded()
            return cell
        case openingHoursTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HoursTVC", for: indexPath) as! HoursTVC
            cell.setData(venueDetails?.openHours[indexPath.row], timezone: venueDetails?.useTimezone ?? "")
            return cell
        case upcomingTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailTVC", for: indexPath) as! DetailTVC
            let event = self.events[indexPath.row]
            cell.upcomingImage.sd_setImage(with: URL(string: (event.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            cell.nameLbl.text = event.title
            cell.dateLbl.text = event.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: venueDetails?.useTimezone ?? "")
            if event.isPausedSellingAllTickets {
                cell.priceLbl.text = Constant.String.salePaused
            } else if event.isSoldOutAllTickets {
                cell.priceLbl.text = Constant.String.soldOut
            } else if event.eventTicket?.count ?? 0 == 0 {
                cell.priceLbl.text = Constant.String.salePaused
            } else {
                cell.priceLbl.text = "Starting at $\(event.lowestPriceTicket?.price ?? 0)"
            }
            return cell
        case todaysEventTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailTVC", for: indexPath) as! DetailTVC
            let event = self.todaysEvents[indexPath.row]
            cell.upcomingImage.sd_setImage(with: URL(string: (event.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            cell.nameLbl.text = event.title
            cell.dateLbl.text = event.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: venueDetails?.useTimezone ?? "")
            if event.isPausedSellingAllTickets {
                cell.priceLbl.text = Constant.String.salePaused
            } else if event.isSoldOutAllTickets {
                cell.priceLbl.text = Constant.String.soldOut
            } else if event.eventTicket?.count ?? 0 == 0 {
                cell.priceLbl.text = Constant.String.salePaused
            } else {
                cell.priceLbl.text = "Starting at $\(event.lowestPriceTicket?.price ?? 0)"
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case ticketTypeTableView:
            if venueDetails?.bookingStatus != "OPEN" || venueDetails?.appClipTicket?[indexPath.row].price ?? 0 < 5 { return }
            if venueDetails?.appClipTicket?[indexPath.row].price ?? 0 < 5 && venueDetails?.appClipTicket?[indexPath.row].name.lowercased().contains("general") == true { return }
            if venueDetails?.appClipTicket?[indexPath.row].status != "ENABLED" { return }
            if venueDetails?.appClipTicket?[indexPath.row].selectedQuantity != nil { return }
            if isMaxTicketReached {
                Alert.showToast("Max ticket selection reached")
                return
            }
            continueBtn.isHidden = false
            scrollViewBottomConstraint.constant = 90
            venueDetails?.appClipTicket?[indexPath.row].selectedQuantity = 1
            ticketTypeTableView.reloadData()
            updateContinueBtn()
        case upcomingTableView:
            updateContinueBtn(forceRemove: true)
            Navigate.to.eventDetail(self, eventId: events[indexPath.row].eventId ?? "", venueDetail: venueDetails, event: events[indexPath.row])
        case todaysEventTableView:
            updateContinueBtn(forceRemove: true)
            Navigate.to.eventDetail(self, eventId: todaysEvents[indexPath.row].eventId ?? "", venueDetail: venueDetails, event: todaysEvents[indexPath.row])
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case ticketTypeTableView:
            if venueDetails?.appClipTicket?[indexPath.row].status == "DISABLED" {
                return 0
            }
            return UITableView.automaticDimension
        case openingHoursTableView:
            return UITableView.automaticDimension
        default:
            return UITableView.automaticDimension
        }
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if let totalTicket = venueDetails?.appClipTicket?[sender.tag].selectedQuantity {
            if totalTicket > 1 {
                venueDetails?.appClipTicket?[sender.tag].selectedQuantity = totalTicket - 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else if totalTicket == 1 {
                venueDetails?.appClipTicket?[sender.tag].selectedQuantity = nil
                ticketTypeTableView.reloadData()
                updateContinueBtn(forceRemove: (venueDetails?.appClipTicket?.firstIndex(where: { $0.selectedQuantity != nil })) == nil)
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if isMaxTicketReached {
            Alert.showToast("Max ticket selection reached")
            return
        }
        if let totalTicket = venueDetails?.appClipTicket?[sender.tag].selectedQuantity {
            if totalTicket < maxTicket {
                venueDetails?.appClipTicket?[sender.tag].selectedQuantity = totalTicket + 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else {
                Alert.showToast("Max ticket selection reached")
            }
        }
    }
    
    func updateContinueBtn(forceRemove: Bool = false) {
        DispatchQueue.main.async {
            if forceRemove {
                self.venueDetails?.appClipTicket?.indices.forEach {
                    self.venueDetails?.appClipTicket?[$0].selectedQuantity = nil
                }
                self.continueBtn.isHidden = true
                self.scrollViewBottomConstraint.constant = 30
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT", for: .normal)
                self.ticketTypeTableView.reloadData()
                return
            }
            self.continueBtn.isHidden = false
            self.continueBtn.setTitle("CONTINUE TO CHECKOUT -  $\(self.totalPrice)", for: .normal)
        }
    }
}

extension MVPVenueDetailVc: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        if self.venueUniqueId == uniqueId {
            getVenueDetail(withLoader: false)
            updateContinueBtn(forceRemove: true)
        }
    }
    
    func didGenderWiseTicketChange(venueId: String, uniqueId: String) {
        if self.venueUniqueId == uniqueId {
            getVenueDetail(withLoader: false)
            updateContinueBtn(forceRemove: true)
        }
    }
}

extension MVPVenueDetailVc: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 220 {
            headerVenueName.isHidden = false
            headerView.backgroundColor = .black
        } else {
//            if scrollView.contentOffset.y <= 0 {
//                gradient?.frame = venueBgImg.bounds
//            }
            headerVenueName.isHidden = true
            headerView.backgroundColor = .clear
        }
    }
}
