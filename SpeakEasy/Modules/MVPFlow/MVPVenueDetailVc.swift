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
    @IBOutlet weak var venueTitleNameLbl: UILabelDeviceClass!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var logoImg: UIImageView!
    @IBOutlet weak var ticketTypeTableView: UITableView!
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var liveLbl: UILabel!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var updatedAtLbl: UILabel!
    @IBOutlet weak var headerVenueName: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toNightLbl: UILabel!
    @IBOutlet weak var venuePageView: UIView!
    @IBOutlet weak var closeTicketView: UIView!
    @IBOutlet weak var openingHoursView: UIView!
    @IBOutlet weak var vibeView: UIView!
    @IBOutlet weak var dressCodeView: UIView!
    @IBOutlet weak var venuePolicyView: UIView!
    @IBOutlet weak var upcomingSectionView: UIView!
    @IBOutlet weak var vibesCollectionView: UICollectionView!
    @IBOutlet weak var vibeCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var openingTableHeight: NSLayoutConstraint!
    @IBOutlet weak var openingHoursTableView: UITableView!
    @IBOutlet weak var upcomingTableView: UITableView!
    @IBOutlet weak var upcomingTableHeight: NSLayoutConstraint!

    var venueId = ""
    var isFromAppClip = false
    private let presenter = MVPPresenter()
    private var venueDetails: ClipVenue?
    private var maxTicket = 10
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var vibeHeightObservation: NSKeyValueObservation?
    private var hoursHeightObservation: NSKeyValueObservation?
    private var upcomingHeightObservation: NSKeyValueObservation?
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
    private let demoVibes = Array(repeating: "VIP Bottle Service", count: 6)
    private let demoHours = Constants.taoHours
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        getEvents()
        updateContinueBtn(forceRemove: true)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openAppleMap))
        self.mapView.addGestureRecognizer(tap)
        vibesCollectionView.register(UINib(nibName: "VibesCVC", bundle: nil), forCellWithReuseIdentifier: "VibesCVC")
        vibeHeightObservation = vibesCollectionView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.vibeCollectionHeight.constant = self.vibesCollectionView.contentSize.height
            self.vibesCollectionView.layoutIfNeeded()
        }
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
    }
    
    private func getVenueDetail(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        presenter.getVenuesDetailForaMVP(venueId: venueId) { [weak self] isSuccess, errMsg, venueDetail in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                self.venueDetails = venueDetail
                self.setUpUI()
                self.updateContinueBtn(forceRemove: true)
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            if withLoader == false && self.navigationController?.viewControllers.last is MVPVenueDetailVc {
                Alert.showToast("Venue detail updated")
            }
            Loader.hide()
        }
    }
    
    private func getEvents() {
        Loader.show()
        // TODO: add pagination + venue wise
        EventPresenter.getEvents(venueId: venueId) { [weak self] isSuccess, errMsg, eventList, hasMore in
            guard let self = self else {
                Loader.hide()
                return
            }
            self.events = eventList
            self.upcomingSectionView.isHidden = eventList.count == 0
            self.upcomingTableView.reloadData()
            self.hasMore = hasMore
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
        headerVenueName.text = venueDetails?.name
        locationLbl.text = venueDetails?.address
        infoLbl.text = "Entry tickets can be purchased in-person at \(venueDetails?.name ?? "") by scanning the banner located outside the venue.\nPrices shown here are subject to change. Up to date prices will be shown upon ticket purchase at the venue."
        infoLbl.highlightBold(["in-person"], size: 15, textColor: .white)
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
            closeTicketView.isHidden = false
            venuePageView.isHidden = true
        } else {
            venuePageView.isHidden = false
            closeTicketView.isHidden = true
        }
        updatedAtLbl.text = "Updated: \(venueDetails?.updatedAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .hmma) ?? "")"
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: venueDetails?.name)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        if let selectedTickets = venueDetails?.appClipTicket?.filter({ $0.selectedQuantity != nil }) {
            Navigate.to.checkOutVC(self, venueName: venueDetails?.name ?? "", venueId: self.venueId, venueAttachment: venueDetails?.venueAttachment.first?.key ?? "", venueLogo: venueDetails?.logo?.key ?? "", selectedTickets: selectedTickets, totalPrice: totalPrice)
        }
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
}

extension MVPVenueDetailVc: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case ticketTypeTableView:
            return venueDetails?.appClipTicket?.count ?? 0
        case openingHoursTableView:
            return demoHours.count
        case upcomingTableView:
            return events.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case ticketTypeTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTypeTableViewCell", for: indexPath) as! ticketTypeTableViewCell
            cell.ticketTypeLbl.text = venueDetails?.appClipTicket?[indexPath.row].name == "GENERALTICKET" ? "General Admission" : "VIP Skip the Line"
            cell.infoLbl.text = venueDetails?.appClipTicket?[indexPath.row].description
            if venueDetails?.appClipTicket?[indexPath.row].price ?? 0 >= 5 {
                cell.ticketPriceLbl.text = "$\(venueDetails?.appClipTicket?[indexPath.row].price ?? 0)"
            } else {
                cell.ticketPriceLbl.text = "FREE"
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
            cell.setData(data: demoHours[indexPath.row])
            return cell
        case upcomingTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailTVC", for: indexPath) as! DetailTVC
            cell.upcomingImage.sd_setImage(with: URL(string: (events[indexPath.row].flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            cell.nameLbl.text = events[indexPath.row].title
            cell.dateLbl.text = events[indexPath.row].startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD)
            cell.priceLbl.text = "Starting at $\(events[indexPath.row].lowestPriceTicket?.price ?? 0)"
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case ticketTypeTableView:
            if venueDetails?.bookingStatus != "OPEN" || venueDetails?.appClipTicket?[indexPath.row].price ?? 0 < 5 { return }
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
        if self.venueId == uniqueId {
            getVenueDetail(withLoader: false)
        }
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

extension MVPVenueDetailVc: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        demoVibes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = vibesCollectionView.dequeueReusableCell(withReuseIdentifier: "VibesCVC", for: indexPath) as! VibesCVC
        cell.lblVibes.text = demoVibes[indexPath.row]
        return cell
    }
}

extension MVPVenueDetailVc: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = demoVibes[indexPath.item].size(withAttributes:[.font: UIFont(name: "Poppins-Regular", size: 15) ?? UIFont.systemFont(ofSize:15.0)]).width + 16
        let size = CGSize(width: width, height: 40.0)
        return size
    }
}
