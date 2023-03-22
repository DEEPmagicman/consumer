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
    @IBOutlet weak var contectNoLbl: UILabel!
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
    
    var venueId = ""
    var isFromAppClip = false
    private var mvpDelegate = MVPPresenter()
    private var venueDetails: ClipVenue?
    var selectedTicket = -1
    var totalTicket = 1
    private var maxTicket = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.headerVenueName.isHidden = true
        self.headerView.backgroundColor = .clear
        scrollView.delegate = self
        backBtn.isHidden = isFromAppClip
        ticketTypeTableView.register(UINib(nibName: "ticketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "ticketTypeTableViewCell")
        ticketTypeTableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        WebSocketWrapper.shared.delegate.append(self)
        getVenueDetail()
        updateContinueBtn(forceRemove: true)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openAppleMap))
        self.mapView.addGestureRecognizer(tap)
    }
    
    func getVenueDetail(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        mvpDelegate.getVenuesDetailForaMVP(venueId: self.venueId) { [weak self] isSuccess, errMsg, venueDetail in
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
    
    func updateLocationOnMap(to coordinate: CLLocationCoordinate2D, with title: String?) {
        let point = MKPointAnnotation()
        point.title = title
        point.coordinate = coordinate
        point.accessibilityNavigationStyle = .separate
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotation(point)
        let viewRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        self.mapView.setRegion(viewRegion, animated: true)
    }
    
    @objc func openAppleMap() {
        let coordinate = CLLocationCoordinate2DMake(venueDetails?.latitude ?? 0, venueDetails?.longitude ?? 0)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        mapItem.name = venueDetails?.name
        mapItem.openInMaps()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        tableViewHeight.constant = ticketTypeTableView.contentSize.height
    }
    
    private func setUpUI() {
        let imgStr = "https://speakeasy-storage.s3.amazonaws.com/\(venueDetails?.venueAttachment.first?.key ?? "")"
        let logoStr = "https://speakeasy-storage.s3.amazonaws.com/\(venueDetails?.logo?.key ?? "")"
        venueBgImg.sd_setImage(with: URL(string: imgStr),completed: nil)
        logoImg.sd_setImage(with: URL(string: logoStr),completed: nil)
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
        Navigate.to.checkOutMvpVC(self, totalTicket: self.totalTicket, ticketPrice: venueDetails?.appClipTicket?[selectedTicket].price ?? 0, isGeneral: venueDetails?.appClipTicket?[selectedTicket].name == "GENERALTICKET", venueName: venueDetails?.name ?? "", appClipTicketId: venueDetails?.appClipTicket?[selectedTicket].id ?? "", venueId: self.venueId, ticketInfo: venueDetails?.appClipTicket?[selectedTicket].description ?? "",venueAttachment: venueDetails?.venueAttachment.first?.key ?? "", venueLogo: venueDetails?.logo?.key ?? "")
    }
    
    @IBAction func onClickShare(_ sender: Any) {
        let msgText = """
 Download Speaskeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues.

 Link to App: https://apps.apple.com/us/app/speakeasy-go/id1642351956
 """
         Utility.main.shareSocialWith(text: msgText)
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension MVPVenueDetailVc: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        venueDetails?.appClipTicket?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        if indexPath.row == selectedTicket {
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
        cell.totalTicketLbl.text = "\(totalTicket)"
        cell.plusBtn.alpha = totalTicket == maxTicket ? 0.5 : 1
        cell.selectionStyle = .none
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if venueDetails?.bookingStatus != "OPEN" || venueDetails?.appClipTicket?[indexPath.row].price ?? 0 < 5 { return }
        if venueDetails?.appClipTicket?[indexPath.row].status != "ENABLED" { return }
        if indexPath.row == self.selectedTicket { return }
        continueBtn.isHidden = false
        scrollViewBottomConstraint.constant = 90
        selectedTicket = indexPath.row
        totalTicket = 1
        ticketTypeTableView.reloadData()
        updateContinueBtn()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if venueDetails?.appClipTicket?[indexPath.row].status == "DISABLED" {
            return 0
        }
        return UITableView.automaticDimension
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if totalTicket > 1 {
            self.totalTicket -= 1
            self.ticketTypeTableView.reloadData()
            updateContinueBtn()
        } else if totalTicket == 1 {
            self.selectedTicket = -1
            self.ticketTypeTableView.reloadData()
            updateContinueBtn(forceRemove: true)
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if totalTicket < maxTicket {
            self.totalTicket += 1
            self.ticketTypeTableView.reloadData()
            updateContinueBtn()
        }
    }
    
    func updateContinueBtn(forceRemove: Bool = false) {
        DispatchQueue.main.async {
            if forceRemove {
                self.continueBtn.isHidden = true
                self.scrollViewBottomConstraint.constant = 30
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT", for: .normal)
                self.selectedTicket = -1
                self.totalTicket = 1
                self.ticketTypeTableView.reloadData()
                return
            }
            self.continueBtn.isHidden = false
            let price = self.venueDetails?.appClipTicket?[self.selectedTicket].price ?? 0
            self.continueBtn.setTitle("CONTINUE TO CHECKOUT -  $\(self.totalTicket*price)", for: .normal)
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
            self.headerVenueName.isHidden = false
            self.headerView.backgroundColor = .black
        } else  {
            self.headerVenueName.isHidden = true
            self.headerView.backgroundColor = .clear
        }
    }
}
