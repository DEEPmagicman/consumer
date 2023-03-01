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
    
    var venueId = ""
    var isFromAppClip = false
    private var mvpDelegate = MVPPresenter()
    private var venueDetails: ClipVenue?
    var selectedTicket = -1
    var totalTicket = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backBtn.isHidden = isFromAppClip
        ticketTypeTableView.register(UINib(nibName: "ticketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "ticketTypeTableViewCell")
        ticketTypeTableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        WebSocketWrapper.shared.delegate.append(self)
        getVenueDetail()
        continueBtn.alpha = 0.5
        continueBtn.isUserInteractionEnabled = false
        self.continueBtn.setTitle("CONINTUE TO CHECKOUT", for: .normal)
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
                self.ticketTypeTableView.reloadData()
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
        self.getAUId(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0)
        let coordinate = CLLocationCoordinate2DMake(41.893482, -87.629860) // (21.2049,72.8411)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        mapItem.name = venueDetails?.name
        mapItem.openInMaps()
    }
    
     func getAUId(latitude: Double, longitude: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        options.size = CGSize(width: 1, height: 1)

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot else {
                if let error = error {
                    print("Error occurred during snapshot: \(error.localizedDescription)")
                }
                return
            }
            let coordinatePoint = snapshot.point(for: coordinate)
            let mapPoint = MKMapPoint(coordinate)
            let coordinateMapPoint = MKMapPoint(coordinate)
            let distance = mapPoint.distance(to: coordinateMapPoint)
            let auId = Int(round(distance))
            print("AUId: \(auId)")
        }
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
        locationLbl.text = venueDetails?.address
        infoLbl.text = "Entry tickets can be purchased in-person at \(venueDetails?.name ?? "") by scanning the banner located outside the venue.\nPrices shown here are subject to change. Up to date prices will be shown upon ticket purchase at the venue."
        infoLbl.highlightBold(["in-person"], size: 15, textColor: .white)
        if venueDetails?.bookingStatus == "OPEN" {
            liveLbl.text = "\(venueDetails?.bookingWaiting ?? "") Wait"
            liveLbl.textColor = UIColor(red: 0/255, green: 255/255, blue: 148/255, alpha: 1)
        } else {
            liveLbl.text = "CLOSED"
            liveLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
        }
        updatedAtLbl.text = "Updated: \(venueDetails?.updatedAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .hmma) ?? "")"
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: venueDetails?.name)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        Navigate.to.checkOutMvpVC(self, totalTicket: self.totalTicket, ticketPrice: venueDetails?.appClipTicket?[selectedTicket].price ?? 0, isGeneral: venueDetails?.appClipTicket?[selectedTicket].name == "GENERALTICKET", venueName: venueDetails?.name ?? "", appClipTicketId: venueDetails?.appClipTicket?[selectedTicket].id ?? "", venueId: self.venueId, ticketInfo: venueDetails?.appClipTicket?[selectedTicket].description ?? "",venueAttachment: venueDetails?.venueAttachment.first?.key ?? "", venueLogo: venueDetails?.logo?.key ?? "")
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
        if indexPath.row == (venueDetails?.appClipTicket?.count ?? 0) - 1 {
            cell.lineView.isHidden = true
        } else {
            cell.lineView.isHidden = false
        }
        if venueDetails?.bookingStatus == "OPEN" && venueDetails?.appClipTicket?[indexPath.row].status == "ENABLED" {
            cell.ticketPriceLbl.textColor = .white
            cell.ticketTypeLbl.textColor = .white
            if venueDetails?.appClipTicket?[indexPath.row].price ?? 0 < 5 {
                cell.sideArrow.isHidden = true
            } else {
                cell.sideArrow.isHidden = false
            }
        } else {
            cell.ticketPriceLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
            cell.ticketTypeLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
            cell.sideArrow.isHidden = true
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
        cell.selectionStyle = .none
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if venueDetails?.bookingStatus != "OPEN" || venueDetails?.appClipTicket?[indexPath.row].price ?? 0 < 5 { return }
        if venueDetails?.appClipTicket?[indexPath.row].status != "ENABLED" { return }
        if indexPath.row == self.selectedTicket { return }
        self.continueBtn.alpha = 1
        self.continueBtn.isUserInteractionEnabled = true
        self.selectedTicket = indexPath.row
        self.totalTicket = 1
        ticketTypeTableView.reloadData()
        let price = venueDetails?.appClipTicket?[selectedTicket].price ?? 0
        self.continueBtn.setTitle("CONINTUE TO CHECKOUT -  $\(totalTicket*price)", for: .normal)

    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if totalTicket > 1 {
            self.totalTicket -= 1
            self.ticketTypeTableView.reloadData()
            let price = venueDetails?.appClipTicket?[selectedTicket].price ?? 0
            self.continueBtn.setTitle("CONINTUE TO CHECKOUT -  $\(totalTicket*price)", for: .normal)
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        self.totalTicket += 1
        self.ticketTypeTableView.reloadData()
        let price = venueDetails?.appClipTicket?[selectedTicket].price ?? 0
        self.continueBtn.setTitle("CONINTUE TO CHECKOUT -  $\(totalTicket*price)", for: .normal)

    }
}

extension MVPVenueDetailVc: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        if self.venueId == uniqueId {
            getVenueDetail(withLoader: false)
        }
    }
}
