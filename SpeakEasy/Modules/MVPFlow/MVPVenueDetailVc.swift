//
//  MVPVenueDetailVc.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit
import SDWebImage
import MapKit
import MHLoadingButton

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
    @IBOutlet weak var continueBtn: LoadingButton!
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
    @IBOutlet weak var venuePageTitleView: UIView!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var VIPTableView: UIView!
    @IBOutlet weak var showMoreUpcoming: UIView!
    @IBOutlet weak var showMoreTonightView: UIView!
    @IBOutlet weak var winstonHouseNoticeView: UIView!
    @IBOutlet weak var venueDetailsView: UIView!
    @IBOutlet weak var organizerView: UIView!
    @IBOutlet weak var organizerVenueName: UILabel!
    @IBOutlet weak var organizerVenueAddress: UILabel!
    @IBOutlet weak var organizerVenueLogo: UIImageView!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var descriptionText: UILabel!
    @IBOutlet weak var organizerVenueAddressView: UIView!
    @IBOutlet weak var locationImg: UIImageView!
    @IBOutlet weak var continueBtnView: UIView!
    @IBOutlet weak var addOnsView: UIView!
    @IBOutlet weak var buyUpsellBtn: UIButton!
    @IBOutlet weak var checkOutIndicator: UIActivityIndicatorView!
    @IBOutlet weak var stackViewBottomConstraint: NSLayoutConstraint!
    
    var venueId = ""
    var venueUniqueId = ""
    var venueTimeZone = ""
    var isFromAppClip = false
    var doormanId = ""
    private let presenter = MVPPresenter()
    private var venueDetails: ClipVenue?
    private var maxTicket = 20
    private var selectedType: TicketPriceType = .FREE
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var hoursHeightObservation: NSKeyValueObservation?
    private var upcomingHeightObservation: NSKeyValueObservation?
    private var todaysEventHeightObservation: NSKeyValueObservation?
    private var venueImgHeightObservation: NSKeyValueObservation?
    private var from = 0
    private var hasMore = false
    private var totalPrice: Double {
        var total = 0.0
        if venueDetails?.venueSettings?.coverTicketSettings?.isUpFront == true {
            venueDetails?.modifiedCoverTicket.forEach {
                if let quantity = $0.selectedQuantity {
                    total += ($0.price * Double(quantity))
                }
            }
        } else {
            venueDetails?.coverTicket?.forEach {
                if let quantity = $0.selectedQuantity {
                    total += ($0.price * Double(quantity))
                }
            }
        }
        return total
    }
    private var isMaxTicketReached: Bool {
        var total = 0
        venueDetails?.coverTicket?.forEach {
            if let quantity = $0.selectedQuantity {
                total += quantity
            }
        }
        return total >= maxTicket
    }
    var customPaidTicket: CoverTicket? {
        venueDetails?.coverTicket?.first(where: { $0.isCustom == true && $0.price > 0 && $0.selectedQuantity ?? 0 != 0 })
    }
    var defaultPaidTicket: CoverTicket? {
        venueDetails?.coverTicket?.first(where: { $0.isCustom == false && $0.price > 0 && $0.selectedQuantity ?? 0 != 0  })
    }
    var barTabTicket: CoverTicket? {
        venueDetails?.coverTicket?.first(where: { $0.isBarTicket == true && $0.selectedQuantity ?? 0 != 0  })
    }
    
    private var events = [Event]()
    private var todaysEvents = [Event]()
    private var gradient: CAGradientLayer?
    private var tonightEventSkip = 0
    private var upcomingEventSkip = 0
    private var hasManyTonightEvent = false
    private var hasManyUpcomingEvent = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WebSocketWrapper.shared.disConnect()
        UserDefault.shared.selectedVenueId = venueId
        WebSocketWrapper.shared.connect()
        
        addOnsView.isHidden = true
        gradient = venueBgImg.setGradientColor()
        venueImgHeightObservation = venueBgImg.observe(\.bounds, options: []) { [weak self] _, _ in
            self?.gradient = self?.venueBgImg.setGradientColor()
        }
        headerVenueName.isHidden = true
        headerView.backgroundColor = .clear
        scrollView.delegate = self
        backBtn.isHidden = isFromAppClip
        ticketTypeTableView.register(UINib(nibName: "TicketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "TicketTypeTableViewCell")
        ticketListHeightObservation = ticketTypeTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.tableViewHeight.constant = self.ticketTypeTableView.contentSize.height
            self.ticketTypeTableView.layoutIfNeeded()
        }
        WebSocketWrapper.shared.delegate.append(self)
        getVenueDetail()
        updateContinueBtn(forceRemove: true)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openAppleMap))
        mapView.addGestureRecognizer(tap)
        mapView.isScrollEnabled = false
        openingHoursTableView.register(UINib(nibName: "HoursTVC", bundle: nil), forCellReuseIdentifier: "HoursTVC")
        hoursHeightObservation = openingHoursTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.openingTableHeight.constant = self.openingHoursTableView.contentSize.height
            self.openingHoursTableView.layoutIfNeeded()
        }
        upcomingTableView.register(UINib(nibName: "PurchaseDetailsTVC", bundle: nil), forCellReuseIdentifier: "PurchaseDetailsTVC")
        upcomingHeightObservation = upcomingTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.upcomingTableHeight.constant = self.upcomingTableView.contentSize.height
            self.upcomingTableView.layoutIfNeeded()
        }
        todaysEventTableView.register(UINib(nibName: "PurchaseDetailsTVC", bundle: nil), forCellReuseIdentifier: "PurchaseDetailsTVC")
        todaysEventHeightObservation = todaysEventTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.todaysEventTableHeight.constant = self.todaysEventTableView.contentSize.height
            self.todaysEventTableView.layoutIfNeeded()
        }
        checkOutIndicator.startAnimating()
        checkOutIndicator.isHidden = true
        tonightView.isHidden = true
        
        continueBtn.bgColor = UIColor(red: 0.96, green: 0.51, blue: 1.00, alpha: 1.00)
        continueBtn.indicator = MaterialLoadingIndicator(color: .black)
    }
    
    private func getVenueDetail(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        presenter.getVenuesDetailForaMVP(venueId: venueUniqueId, venueTimeZone: venueTimeZone, doormanId: doormanId) { [weak self] isSuccess, errMsg, venueDetail in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                self.venueDetails = venueDetail
                if let venueId = venueDetail?.id {
                    self.venueId = venueId
                }
                self.venueDetails?.coverTicket?.removeAll(where: { $0.price == 0 && $0.isBarTicket == true })
                self.setUpUI()
                self.ticketTypeTableView.reloadData()
                self.openingHoursTableView.reloadData()
                self.updateContinueBtn(forceRemove: true)
                self.updateCloseViewVisibility()
                if self.isFromAppClip && venueDetail?.name == "Winston House" {
                    self.venuePageView.isHidden = true
                    self.venuePageTitleView.isHidden = true
                    self.winstonHouseNoticeView.isHidden = false
                }
                self.zeroCaseView(isHidden: true)
            } else {
                self.zeroCaseView(isHidden: false)
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
//            self.getTonightEvent()
            self.getUpcomingEvent()
            #if DEBUG
            if withLoader == false && self.navigationController?.viewControllers.last is MVPVenueDetailVc {
                Alert.showToast("Venue detail updated")
            }
            #endif
            Loader.hide()
        }
    }
    
    private func getTonightEvent() {
        Loader.show()
        EventPresenter.getEvents(from: tonightEventSkip,venueId: venueId, time: "TODAY", venueTimeZone: venueDetails?.useTimezone) { [weak self] _, _, eventList, hasMore in
            Loader.hide()
            guard let self = self else { return }
            
            if self.tonightEventSkip == 0 {
                self.todaysEvents.removeAll()
            }
            for event in eventList {
                self.todaysEvents.append(event)
            }
            if hasMore {
                self.tonightEventSkip = self.todaysEvents.count
            }
//            self.showMoreTonightView.isHidden = hasMore ? false : true
            self.todaysEventTableView.reloadData()
            self.updateCloseViewVisibility()
            Loader.hide()
        }
    }
    
    private func getUpcomingEvent() {
        Loader.show()
        EventPresenter.getEvents(from: upcomingEventSkip, venueId: venueId, time: "UPCOMING", venueTimeZone: venueDetails?.useTimezone) { [weak self] _, _, eventList, hasMore in
            Loader.hide()
            guard let self = self else { return }
            
            if self.upcomingEventSkip == 0 {
                self.events.removeAll()
            }
            for event in eventList {
                self.events.append(event)
            }
            if hasMore {
                self.upcomingEventSkip = self.events.count
            }
            self.showMoreUpcoming.isHidden = hasMore ? false : true
            self.upcomingTableView.reloadData()
            self.upcomingSectionView.isHidden = eventList.count == 0
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !WebSocketWrapper.shared.isSocketConnected { return }
        WebSocketWrapper.shared.disConnect()
        UserDefault.shared.selectedVenueId = venueId
        WebSocketWrapper.shared.connect()
    }
    
    private func setUpUI() {
        venueBgImg.sd_setImage(with: URL(string: (venueDetails?.venueAttachment?.first?.key ?? "").imageURL), completed: nil)
        getUpsellTicket()
        logoImg.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL), completed: nil)
        venueLogo.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL), completed: nil)
        organizerVenueLogo.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL), completed: nil)
        venueTitleNameLbl.text = venueDetails?.name
        cityNameLbl.text = venueDetails?.city
        headerVenueName.text = venueDetails?.name
        locationLbl.text = venueDetails?.address
        organizerVenueName.text = venueDetails?.name
        organizerVenueAddress.text = venueDetails?.website ?? "" != "" ? venueDetails?.website : venueDetails?.address ?? ""
        descriptionText.text = venueDetails?.description
        dressCodeLbl.text = venueDetails?.dressCode?.withEmptyPlaceHolder ?? Constant.String.dash
        venueNameLbl.text = venueDetails?.name ?? ""
        venuePolicyLbl.text = String(format: Constant.String.venuePolicy, venueDetails?.name ?? "venue")
        if venueDetails?.venueSettings?.bookingStatus == "OPEN" {
            liveLbl.text = venueDetails?.displayWaitTime
            liveLbl.textColor = UIColor(red: 0/255, green: 255/255, blue: 148/255, alpha: 1)
            updatedAtLbl.isHidden = false
            liveLbl.font = UIFont(name: "Poppins-SemiBold", size: 16)
            toNightLbl.alpha = 1
        } else {
            toNightLbl.alpha = 0.5
            updatedAtLbl.isHidden = true
            liveLbl.text = "CLOSED"
            addOnsView.isHidden = true
            liveLbl.font = UIFont(name: "Poppins-SemiBold", size: 18)
            liveLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
        }
        if venueDetails?.coverTicket?.allSatisfy({ ticket in
            ticket.status == "DISABLED"
        }) == true {
            updateCloseViewVisibility()
//            tonightView.isHidden = true
            venuePageView.isHidden = true
            venuePageTitleView.isHidden = true
        } else {
            venuePageView.isHidden = false
//            tonightView.isHidden = false
            closeTicketView.isHidden = true
            venuePageTitleView.isHidden = false
        }
        updatedAtLbl.text = venueDetails?.updatedAt.displayUpdatedAgo(from: .yyyyMMddTHHmmssSSSz, to: .hmmA) ?? ""
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: venueDetails?.name)
        if venueDetails?.venueSettings?.isOrganizer == true {
            cityNameLbl.isHidden = true
            openingHoursView.isHidden = true
            dressCodeView.isHidden = true
            organizerView.isHidden = false
            venueDetailsView.isHidden = true
            descriptionView.isHidden = false
        }
        if venueDetails?.website ?? "" != "" {
            locationImg.image = UIImage(named: "ic-link")
            let tap = UITapGestureRecognizer(target: self, action: #selector(onClickWebSite))
            organizerVenueAddressView.addGestureRecognizer(tap)
        }
        buyUpsellBtn.setTitle(venueDetails?.venueSettings?.addOnsBookingSettings?.pageTitle ?? "Buy Upsell", for: .normal)
        if let color = self.venueDetails?.venueSettings?.whiteLabelColor {
            continueBtn.bgColor = UIColor(hex: color)
        }
    }
    
    @objc func onClickWebSite() {
        if let url = URL(string: venueDetails?.website ?? "") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func getUpsellTicket() {
        MVPPresenter.getUpSellItem(skip: 0, doormanId: doormanId, venueId: venueId) {[weak self] isSuccess, errMsg, upSellItem, _, _ in
            guard let self = self else { return }
            Loader.hide()
            if isSuccess {
                if venueDetails?.venueSettings?.bookingStatus == "OPEN" {
                    self.addOnsView.isHidden = upSellItem.count == 0
                }
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
    
    private func updateCloseViewVisibility() {
        if (events.count == 0 && todaysEvents.count == 0 &&
            (venueDetails?.coverTicket?.allSatisfy({ ticket in
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
    
    @IBAction func onClickBuyUpSell(_ sender: Any) {
        forceRemoveFreeTicket()
        forceRemoveCustomTicket()
        forceRemovePaidTicket()
        forceRemoveBarTabTicket()
        Navigate.to.upSellTicketVC(self, upSellTicket: [], hasMany: false, venueDetails: venueDetails, doormanId: doormanId)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        if UserDefault.shared.isGuest == true {
            Navigate.to.login(forceCreateAccount: true)
            return
        }
        if let selected = venueDetails?.coverTicket?.filter({ $0.selectedQuantity != nil }), selected.first?.isBarTicket == true {
            if let selectedTickets = venueDetails?.coverTicket?.filter({ $0.selectedQuantity != nil }) {
                Navigate.to.barTabCheckoutVC(self, selectedTicket: selectedTickets, venueDetails: venueDetails)
                self.updateContinueBtn(forceRemove: true)
            }
        } else if let selected = venueDetails?.coverTicket?.filter({ $0.selectedQuantity != nil }), selected.count > 0 {
            getUpSellItems()
        } else {
            Navigate.externalURL(String(format: SharedURL.tableBookingURL, "\(venueId)" ))
        }
    }
    
    private func selectedTickets() {
        if let selectedTickets = venueDetails?.coverTicket?.filter({ $0.selectedQuantity != nil }) {
            Navigate.to.checkOutVC(self, venue: venueDetails, selectedCoverTickets: selectedTickets, selectedEventTicket: [], selectedAddOnsItem: [], totalPrice: Double(totalPrice), type: .appClip)
            updateContinueBtn(forceRemove: true)
        }
    }
    
    private func getUpSellItems() {
        if addOnsView.isHidden == true && selectedType == .FREE {
            createFreeBooking()
        } else {
            checkOutIndicator.isHidden = false
            continueBtn.setTitle("", for: .normal)
            MVPPresenter.getUpSellItem(skip: 0, doormanId: doormanId, venueId: venueId) {[weak self] isSuccess, errMsg, upSellItem, hasMore, total in
                guard let self = self else { return }
                if isSuccess {
                    if total != 0 {
                        Navigate.to.upSellTicketVC(self, upSellTicket: upSellItem, hasMany: hasMore, venueDetails: self.venueDetails, doormanId: self.doormanId, bookingType: selectedType)
                        self.updateContinueBtn(forceRemove: true)
                    } else {
                        self.selectedTickets()
                    }
                } else {
                    Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
    
    private func createFreeBooking() {
        if let selectedTickets = venueDetails?.coverTicket?.filter({ $0.selectedQuantity != nil }) {
            var tickets = [[String: Any]]()
            selectedTickets.forEach {
                tickets.append(["ticketId": $0.id,
                                "ticketQuantity": $0.selectedQuantity ?? 0])
            }
            continueBtn.showLoader(userInteraction: false)
            self.view.isUserInteractionEnabled = false
            PaymentPresenter.createCoverFreeBooking(coverTickets: tickets, venueId: venueDetails?.id ?? "") { [weak self] isSuccess, errMsg, id, _ in
                guard let self = self else { return }
                self.continueBtn.hideLoader()
                self.view.isUserInteractionEnabled = true
                if isSuccess, let id = id {
                    Navigate.to.scanQR(self, bookingId: id, venueId: venueDetails?.id ?? "", addOnsBookingId: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
    
    @IBAction func onClickShare(_ sender: Any) {
        let msgText = "Check out \(venueDetails?.name ?? "Venue") on Speakeasy. \(String(format: APIBuilder.venueWebURL, venueDetails?.name.lowercased().replacingOccurrences(of: " ", with: "-") ?? "Venue", venueUniqueId)) Download the app to directly connect with your favorite venues & never miss out! \(SharedURL.appStoreURL)"
         Utility.main.shareSocialWith(text: msgText)
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onCLickShowMoreUpcoming(_ sender: Any) {
        getUpcomingEvent()
    }
    
    @IBAction func onClickShowMoreTonightEvent(_ sender: Any) {
        getTonightEvent()
    }
}

extension MVPVenueDetailVc: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case ticketTypeTableView:
            return venueDetails?.coverTicket?.count ?? 0
        case openingHoursTableView:
            openingHoursView.isHidden = (venueDetails?.openHours.count == 0 || venueDetails?.venueSettings?.isOrganizer == true)
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
            let cell: TicketTypeTableViewCell = tableView.dequeue(withIdentifier: TicketTypeTableViewCell.identifier, for: indexPath)
            let ticket = venueDetails?.coverTicket?[indexPath.row]
            cell.ticketTypeLbl.text = ticket?.customName ?? "" == "" ? ticket?.name : ticket?.customName
            cell.infoLbl.text = ticket?.description
            cell.plusBtn.alpha = isMaxTicketReached ? 0.5 : 1
            let currencySymbol = venueDetails?.venueSettings?.currencySymbol
            let currencyPosition = venueDetails?.venueSettings?.currencyPosition
            
            if ticket?.price ?? 0 < 2 && ticket?.name.lowercased().contains("general") == true {
                cell.ticketPriceLbl.text = "FREE"
            } else if ticket?.isCustom == true && ticket?.price ?? 0 == 0 {
                cell.ticketPriceLbl.text = "FREE"
            } else {
                if venueDetails?.venueSettings?.coverTicketSettings?.isUpFront == true {
                    if venueDetails?.modifiedCoverTicket[indexPath.row].isCustom == true {
                        cell.ticketPriceLbl.text = CurrencyFormatter.amount(
                            Double(ticket?.price ?? 0),
                            symbol: currencySymbol,
                            position: currencyPosition
                        )
                    } else {
                        cell.ticketPriceLbl.text = CurrencyFormatter.amount(
                            Double(venueDetails?.modifiedCoverTicket[indexPath.row].price ?? 0),
                            symbol: currencySymbol,
                            position: currencyPosition
                        )
                    }
                } else {
                    cell.ticketPriceLbl.text = CurrencyFormatter.amount(
                        Double(ticket?.price ?? 0),
                        symbol: currencySymbol,
                        position: currencyPosition
                    )
                }
                cell.plusBtn.isUserInteractionEnabled = true
            }
            if ticket?.extraFees ?? 0 > 0 {
                cell.lblExtraFeesValue.isHidden = false
                let fees = CurrencyFormatter.amount(
                    ticket?.extraFees ?? 0,
                    symbol: currencySymbol,
                    position: currencyPosition
                )

                cell.lblExtraFeesValue.text = "(Incl. \(fees) in fees)"
            } else {
                cell.lblExtraFeesValue.isHidden = true
            }
            if venueDetails?.venueSettings?.bookingStatus == "OPEN" && ticket?.status == "ENABLED" {
                cell.ticketPriceLbl.textColor = .white
                cell.ticketTypeLbl.textColor = .white
            } else {
                cell.ticketPriceLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
                cell.ticketTypeLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
            }
            if ticket?.selectedQuantity ?? 0 >= 1 {
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
            cell.totalTicketLbl.text = "\(ticket?.selectedQuantity ?? 0)"
            
            cell.selectionStyle = .none
            cell.layoutIfNeeded()
            return cell
        case openingHoursTableView:
            let cell: HoursTVC = tableView.dequeue(withIdentifier: HoursTVC.identifier, for: indexPath)
            cell.setData(venueDetails?.openHours[indexPath.row], timezone: venueDetails?.useTimezone ?? "")
            return cell
        case upcomingTableView:
            let cell: PurchaseDetailsTVC = tableView.dequeue(withIdentifier: PurchaseDetailsTVC.identifier, for: indexPath)
            let event = self.events[indexPath.row]
            cell.bgImage.sd_setImage(with: URL(string: (event.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            cell.eventNameLbl.text = event.title
            
            cell.dateLbl.text = event.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .DD)
            cell.monthLbl.text = event.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .MMM)
            
            if event.isPausedSellingAllTickets {
                cell.ticketCountLbl.text = Constant.String.salePaused.uppercased()
            } else if event.isSoldOutAllTickets {
                cell.ticketCountLbl.text = Constant.String.soldOut.uppercased()
            } else if event.eventTicket?.count ?? 0 == 0 {
                cell.ticketCountLbl.text = Constant.String.salePaused.uppercased()
            } else {
                if event.lowestPriceTicket?.price ?? 0 == 0 {
                    cell.ticketCountLbl.text = "FREE"
                } else {
                    let currencySymbol = venueDetails?.venueSettings?.currencySymbol
                    let currencyPosition = venueDetails?.venueSettings?.currencyPosition
                    cell.ticketCountLbl.text = "\(CurrencyFormatter.amount(Double(event.lowestPriceTicket?.price ?? 0), symbol: currencySymbol, position: currencyPosition))+"
                }
                cell.blurView.backgroundColor  = UIColor(red: 0.96, green: 0.51, blue: 1, alpha: 0.75)
            }
            cell.cityNameLbl.text = venueDetails?.name
            cell.imageWidth.constant = 0
            cell.setUI()
            cell.layoutIfNeeded()
            return cell
        case todaysEventTableView:
            let cell: PurchaseDetailsTVC = tableView.dequeue(withIdentifier: PurchaseDetailsTVC.identifier, for: indexPath)
            let event = self.todaysEvents[indexPath.row]
            cell.bgImage.sd_setImage(with: URL(string: (event.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            cell.eventNameLbl.text = event.title
            cell.dateLbl.text = event.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .DD)
            cell.monthLbl.text = event.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .MMM)
            if event.isPausedSellingAllTickets {
                cell.ticketCountLbl.text = Constant.String.salePaused.uppercased()
            } else if event.isSoldOutAllTickets {
                cell.ticketCountLbl.text = Constant.String.soldOut.uppercased()
            } else if event.eventTicket?.count ?? 0 == 0 {
                cell.ticketCountLbl.text = Constant.String.salePaused.uppercased()
            } else {
                if event.lowestPriceTicket?.price ?? 0 == 0 {
                    cell.ticketCountLbl.text = "FREE"
                } else {
                    let currencySymbol = venueDetails?.venueSettings?.currencySymbol
                    let currencyPosition = venueDetails?.venueSettings?.currencyPosition
                    
                    cell.ticketCountLbl.text = "\(CurrencyFormatter.amount(Double(event.lowestPriceTicket?.price ?? 0), symbol: currencySymbol, position: currencyPosition))+"
                }
                cell.blurView.backgroundColor  = UIColor(red: 0.96, green: 0.51, blue: 1, alpha: 0.75)
            }
            cell.cityNameLbl.text = (event.customVenue != nil && venueDetails?.venueSettings?.isOrganizer == true) ? "\(event.customVenue?.name ?? "")" : "\(venueDetails?.name ?? "")"
            cell.imageWidth.constant = 0
            cell.setUI()
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case ticketTypeTableView:
            if venueDetails?.venueSettings?.bookingStatus != "OPEN" { return }
            if venueDetails?.coverTicket?[indexPath.row].status != "ENABLED" { return }
            if venueDetails?.coverTicket?[indexPath.row].selectedQuantity != nil { return }
            if isMaxTicketReached {
                Alert.showToast("Max ticket selection reached")
                return
            }
            VIPTableView.isHidden = true
            stackViewBottomConstraint.constant = 30
            continueBtnView.isHidden = false
            scrollViewBottomConstraint.constant = 30
            venueDetails?.coverTicket?[indexPath.row].selectedQuantity = 1
            
            let selectedTicket = venueDetails?.coverTicket?[indexPath.row]
            if selectedTicket?.isBarTicket == true {
                if customPaidTicket != nil {
                    forceRemoveCustomTicket()
                }
                if defaultPaidTicket != nil {
                    forceRemovePaidTicket()
                }
            } else if selectedTicket?.isCustom == false {
                if selectedTicket?.price ?? 0 >= 2 {
                    if customPaidTicket != nil {
                        forceRemoveCustomTicket()
                    }
                    if barTabTicket != nil {
                        forceRemoveBarTabTicket()
                    }
                }
            } else if selectedTicket?.isCustom == true {
                if selectedTicket?.price ?? 0 > 0 {
                    if defaultPaidTicket != nil {
                        forceRemovePaidTicket()
                    }
                    if barTabTicket != nil {
                        forceRemoveBarTabTicket()
                    }
                    selectedType = .PAID
                }
            }
            selectedType = (defaultPaidTicket == nil && customPaidTicket == nil) ? .FREE : .PAID
            ticketTypeTableView.reloadData()
            updateContinueBtn()
        case upcomingTableView:
            updateContinueBtn(forceRemove: true)
            Navigate.externalURL(String(format: APIBuilder.eventLink, events[indexPath.row].uniqueId ?? ""))
        case todaysEventTableView:
            updateContinueBtn(forceRemove: true)
            Navigate.to.eventDetail(self, eventId: todaysEvents[indexPath.row].uniqueId ?? "", venueDetail: venueDetails, event: todaysEvents[indexPath.row])
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case ticketTypeTableView:
            if venueDetails?.coverTicket?[indexPath.row].status == "DISABLED" {
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
        if let totalTicket = venueDetails?.coverTicket?[sender.tag].selectedQuantity {
            if totalTicket > 1 {
                venueDetails?.coverTicket?[sender.tag].selectedQuantity = totalTicket - 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else if totalTicket == 1 {
                venueDetails?.coverTicket?[sender.tag].selectedQuantity = nil
                ticketTypeTableView.reloadData()
                selectedType = (defaultPaidTicket == nil && customPaidTicket == nil) ? .FREE : .PAID
                updateContinueBtn(forceRemove: (venueDetails?.coverTicket?.firstIndex(where: { $0.selectedQuantity != nil })) == nil)
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if isMaxTicketReached {
            Alert.showToast("Max ticket selection reached")
            return
        }
        if let totalTicket = venueDetails?.coverTicket?[sender.tag].selectedQuantity {
            if totalTicket < maxTicket {
                venueDetails?.coverTicket?[sender.tag].selectedQuantity = totalTicket + 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else {
                Alert.showToast("Max ticket selection reached")
            }
        }
    }
    
    func updateContinueBtn(forceRemove: Bool = false) {
        self.checkOutIndicator.isHidden = true
        DispatchQueue.main.async {
            if forceRemove {
                self.venueDetails?.coverTicket?.indices.forEach {
                    self.venueDetails?.coverTicket?[$0].selectedQuantity = nil
                }
                    self.scrollViewBottomConstraint.constant = 70
                    self.VIPTableView.isHidden = true
                    self.stackViewBottomConstraint.constant = 30
                    self.continueBtnView.isHidden = true
//                }
                self.ticketTypeTableView.reloadData()
                return
            }
            self.continueBtnView.isHidden = false
            self.VIPTableView.isHidden = true
            self.stackViewBottomConstraint.constant = 30
            switch self.selectedType {
            case .FREE:
                if self.addOnsView.isHidden == true {
                    self.continueBtn.setTitle("GET MY FREE TICKET", for: .normal)
                } else {
                    self.continueBtn.setTitle("CONTINUE TO CHECKOUT", for: .normal)
                }
            case .PAID, .CUSTOM:
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT", for: .normal)
            }
        }
    }
    
    private func forceRemoveFreeTicket() {
        self.venueDetails?.coverTicket?.indices.forEach {
            if venueDetails?.coverTicket?[$0].price ?? 0 < 2 && venueDetails?.coverTicket?[$0].name.lowercased().contains("general") == true {
                self.venueDetails?.coverTicket?[$0].selectedQuantity = nil
            }
        }
    }

    private func forceRemovePaidTicket() {
        self.venueDetails?.coverTicket?.indices.forEach {
            if (venueDetails?.coverTicket?[$0].price ?? 0 < 2 && venueDetails?.coverTicket?[$0].name.lowercased().contains("general") == true) || (venueDetails?.coverTicket?[$0].isBarTicket ?? false == true) {
            } else if venueDetails?.coverTicket?[$0].isCustom ?? false != true {
                self.venueDetails?.coverTicket?[$0].selectedQuantity = nil
            }
        }
    }
    
    private func forceRemoveCustomTicket() {
        self.venueDetails?.coverTicket?.indices.forEach {
            if venueDetails?.coverTicket?[$0].isCustom == true {
                self.venueDetails?.coverTicket?[$0].selectedQuantity = nil
            }
        }
    }
    
    private func forceRemoveBarTabTicket() {
        self.venueDetails?.coverTicket?.indices.forEach {
            if venueDetails?.coverTicket?[$0].isBarTicket == true {
                self.venueDetails?.coverTicket?[$0].selectedQuantity = nil
            }
        }
    }
    
}

extension MVPVenueDetailVc: WebSocketCallBackDelegate {
    
    func updateTicketPrice(ticket: [CoverTicket]) {
        if ticket.first?.venueId == self.venueId {
            getVenueDetail(withLoader: false)
            updateContinueBtn(forceRemove: true)
            ticketTypeTableView.reloadData()
        }
    }
    
    func updateVenueStatus(venueId: String, venueStatus: String) {
        if self.venueId == venueId {
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
    
    func updateAddOnsTicketPrice(ticket: [UpSellTicket]) {
        getUpsellTicket()
    }
}

extension MVPVenueDetailVc: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 220 {
            headerVenueName.isHidden = false
            headerView.backgroundColor = .black
        } else {
            headerVenueName.isHidden = true
            headerView.backgroundColor = .clear
        }
    }
}

extension MVPVenueDetailVc: UpdateDetailDelegate {
    func update() {
        updateContinueBtn(forceRemove: true)
    }
}
