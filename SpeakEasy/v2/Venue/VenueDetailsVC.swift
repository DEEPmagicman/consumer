//
//  VenueDetailsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 04/02/26.
//

import UIKit
import MapKit

final class VenueDetailsVC: UIViewController, SJSegmentedViewControllerViewSource {
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var venueAboutLbl: UILabel!
    @IBOutlet weak var viewMoreLbl: UILabel!
    @IBOutlet weak var viewMoreLblHeight: NSLayoutConstraint!
    @IBOutlet weak var viewMoreBtn: UIButton!
    @IBOutlet weak var viewMoreBtnView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    var venueDetails: ClipVenue?
    private var ticketListHeightObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocationOnMap(
            to: CLLocationCoordinate2D(latitude: venueDetails?.latitude ?? 0, longitude: venueDetails?.longitude ?? 0),
            with: venueDetails?.name ?? "Venue"
        )
        handleViewMore()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VenueEventTVC.nib, forCellReuseIdentifier: VenueEventTVC.identifier)
        ticketListHeightObservation = tableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.tableViewHeight.constant = self.tableView.contentSize.height
            self.tableView.layoutIfNeeded()
        }
    }
    
    func updateLocationOnMap(to coordinate: CLLocationCoordinate2D, with title: String?) {
        mapView.delegate = self
        if #available(iOS 16.0, *) {
            let config = MKStandardMapConfiguration(elevationStyle: .flat)
            config.emphasisStyle = .muted
            config.pointOfInterestFilter = .excludingAll
            mapView.preferredConfiguration = config
        } else {
            mapView.mapType = .mutedStandard
            mapView.pointOfInterestFilter = .excludingAll
        }

        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsTraffic = false
        mapView.showsBuildings = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.removeAnnotations(mapView.annotations)

        let point = MKPointAnnotation()
        point.title = title
        point.coordinate = coordinate
        mapView.addAnnotation(point)

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )

        mapView.setRegion(region, animated: false)
        mapView.layer.cornerRadius = 16
        mapView.clipsToBounds = true
    }
    
    @IBAction func onClickViewMore(_ sender: UIButton) {
        viewMoreBtn.isSelected = true
        handleViewMore()
    }
    
    private func handleViewMore() {
        venueAboutLbl.text = venueDetails?.description ?? ""
        view.layoutIfNeeded()
        let lines = numberOfLines(for: venueAboutLbl)
        venueAboutLbl.numberOfLines = viewMoreBtn.isSelected ? lines : min(lines, 3)
        viewMoreBtnView.isHidden = viewMoreBtn.isSelected ? true : lines <= 3
        viewMoreLblHeight.constant = CGFloat(venueAboutLbl.numberOfLines * 20)
    }
    
    func numberOfLines(for label: UILabel) -> Int {
        guard let text = label.text, let font = label.font else { return 0 }
        let maxSize = CGSize(width: label.frame.width, height: .greatestFiniteMagnitude)
        let textHeight = text.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
    
    func viewForSegmentControllerToObserveContentOffsetChange() -> UIView {
        mainScrollView
    }
}

extension VenueDetailsVC: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let id = "venuePin"

        var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)

        if view == nil {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
        }

        view?.annotation = annotation

        if let marker = view as? MKMarkerAnnotationView {
            marker.markerTintColor = .systemBlue
            marker.titleVisibility = .hidden
        }

        return view
    }
}

extension VenueDetailsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: VenueEventTVC = tableView.dequeue(withIdentifier: VenueEventTVC.identifier, for: indexPath)
        return cell
    }
}
