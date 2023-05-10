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
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var dressCodeView: UIView!
    @IBOutlet weak var detailLbl: UILabel!
    @IBOutlet weak var eventPolicyLbl: UILabel!

    var eventId: String?
    var venueDetails: ClipVenue?
    var event: Event?

    override func viewDidLoad() {
        super.viewDidLoad()
        getEventDetail()
        setupData()
        headerTitleLbl.isHidden = true
        headerView.backgroundColor = .clear
        scrollView.delegate = self
        // TODO: add webSocket to sync tier left ticket
        // WebSocketWrapper.shared.delegate.append(self)
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(openFullImage))
        mainImg.isUserInteractionEnabled = true
        mainImg.addGestureRecognizer(tap1)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openAppleMap))
        mapView.addGestureRecognizer(tap)
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
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: venueDetails?.name)
        dateLbl.text = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD)
        timingLbl.text = "• \(event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma) ?? "") - \(event?.endDateTime?.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma) ?? "LATE")"
        continueBtn.setTitle("BUY NOW - STARTING AT $\(event?.lowestPriceTicket?.price ?? 0)", for: .normal)
    }
    
    private func getEventDetail() {
        EventPresenter.getEventDetail(eventId: eventId ?? "") { [weak self] isSuccess, errMsg, eventDetail in
            guard let self = self else {
                return
            }
            self.event = eventDetail
            self.setupData()
        }
    }
    
    @objc func openFullImage() {
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
            Navigate.to.loginMandatory(self)
            return
        }
        Navigate.to.selectTicket(self, venueDetail: venueDetails, event: event, type: .event)
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
