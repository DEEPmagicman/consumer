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
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var timingLbl: UILabel!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var headerVenueName: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var dressCodeView: UIView!
    @IBOutlet weak var venuePolicyView: UIView!
    
    var venueDetails: ClipVenue?

    override func viewDidLoad() {
        super.viewDidLoad()
        headerVenueName.isHidden = true
        headerView.backgroundColor = .clear
        scrollView.delegate = self
        // TODO: add webSocket to sync tier left ticket
        // WebSocketWrapper.shared.delegate.append(self)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openAppleMap))
        mapView.addGestureRecognizer(tap)
        setUpUI()
    }
    
    private func setUpUI() {
        mainImg.sd_setImage(with: URL(string: (venueDetails?.venueAttachment.first?.key ?? "").imageURL),completed: nil)
        titleLbl.text = "NIGHTMRE & DJ Diox XO DJ Heavy" // venueDetails?.name
        headerVenueName.text = venueDetails?.name
        locationLbl.text = venueDetails?.address
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0), with: venueDetails?.name)
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
        Navigate.to.selectTicket(self, venueId: "", venueDetail: venueDetails)
    }
}

extension EventDetailVC: UIScrollViewDelegate {
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
