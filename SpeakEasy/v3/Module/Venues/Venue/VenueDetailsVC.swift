//
//  VenueDetailsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 04/02/26.
//

import UIKit
import MapKit
import CoreLocation

struct SocialPlatform {
    let iconView: UIImageView
    let urlString: String?
}

final class VenueDetailsVC: UIViewController, SJSegmentedViewControllerViewSource {
    
    @IBOutlet weak var tiktokIcon: UIImageView!
    @IBOutlet weak var youtubeIcon: UIImageView!
    @IBOutlet weak var xIcon: UIImageView!
    @IBOutlet weak var fbIcon: UIImageView!
    @IBOutlet weak var websiteIcon: UIImageView!
    @IBOutlet weak var instaIcon: UIImageView!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var venueAboutLbl: UILabel!
    @IBOutlet weak var viewMoreBtn: UIButton!
    @IBOutlet weak var viewMoreBtnView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var distanceTime: UILabel!
    @IBOutlet weak var etaDistanceLbl: UILabel!
    @IBOutlet weak var addressTwoLbl: UILabel!
    @IBOutlet weak var socialStackView: UIStackView!
    @IBOutlet weak var distanceView: UIView!
    
    var venueDetails: ClipVenue? {
        didSet {
            if isViewLoaded {
                configureUI()
            }
        }
    }
    
    private var events: [Event] = []
    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var page = 1
    private var isExpanded = false
    private let collapsedLines = 3
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?
    
    private var ticketListHeightObservation: NSKeyValueObservation?
    
    var socialPlatforms: [SocialPlatform] {
        return [
            SocialPlatform(iconView: fbIcon, urlString: venueDetails?.venueSettings?.facebookUrl),
            SocialPlatform(iconView: instaIcon, urlString: venueDetails?.venueSettings?.instagramUrl),
            SocialPlatform(iconView: xIcon, urlString: venueDetails?.venueSettings?.xUrl),
            SocialPlatform(iconView: youtubeIcon, urlString: venueDetails?.venueSettings?.youtubeUrl),
            SocialPlatform(iconView: tiktokIcon, urlString: venueDetails?.venueSettings?.tiktokUrl),
            SocialPlatform(iconView: websiteIcon, urlString: venueDetails?.venueSettings?.websiteUrl)
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VenueEventTVC.nib, forCellReuseIdentifier: VenueEventTVC.identifier)
        ticketListHeightObservation = tableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.tableViewHeight.constant = self.tableView.contentSize.height
            self.tableView.layoutIfNeeded()
        }
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        configureUI()
        getEvents()
    }
    
    private func configureUI() {
        setupSocialIcons()
        setupExpandableLabel()
        updateLocationOnMap(
            to: CLLocationCoordinate2D(
                latitude: venueDetails?.latitude ?? 0,
                longitude: venueDetails?.longitude ?? 0
            ),
            with: venueDetails?.name ?? "Venue"
        )
        
        let parts = [
            venueDetails?.address,
            venueDetails?.city,
            venueDetails?.code
        ].compactMap { $0 }

        addressLbl.text = parts.joined(separator: ", ")
        addressTwoLbl.text = parts.joined(separator: ", ")
    }
    
    func setupSocialIcons() {
        var hasVisibleIcons = false
        
        for platform in socialPlatforms {
            
            guard let urlString = platform.urlString,
                  let url = URL(string: urlString),
                  !urlString.isEmpty else {
                platform.iconView.isHidden = true
                continue
            }
            
            hasVisibleIcons = true
            
            platform.iconView.isHidden = false
            platform.iconView.isUserInteractionEnabled = true
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSocialTap(_:)))
            platform.iconView.addGestureRecognizer(tapGesture)
            
            platform.iconView.accessibilityHint = urlString
        }
        socialStackView.isHidden = !hasVisibleIcons
    }
    
    private func updateDistanceAndETA() {
        distanceView.isHidden = true
        
        guard let userLocation = userLocation,
              let lat = venueDetails?.latitude,
              let lon = venueDetails?.longitude else {
            return
        }

        let venueLocation = CLLocation(latitude: lat, longitude: lon)
        let distanceMiles = userLocation.distance(from: venueLocation) / 1609.34

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: venueLocation.coordinate))
        request.transportType = .automobile

        MKDirections(request: request).calculate { response, _ in
            guard let route = response?.routes.first else {
                DispatchQueue.main.async {
                    self.distanceView.isHidden = true
                }
                return
            }

            let etaMinutes = Int(route.expectedTravelTime / 60)
            let arrivalDate = Date().addingTimeInterval(route.expectedTravelTime)

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let arrivalTime = formatter.string(from: arrivalDate)

            DispatchQueue.main.async {
                self.distanceView.isHidden = false
                
                self.distanceTime.text = "\(etaMinutes) min"
                
                switch etaMinutes {
                case 0...10:
                    self.distanceTime.textColor = .systemGreen
                case 11...20:
                    self.distanceTime.textColor = .systemOrange
                default:
                    self.distanceTime.textColor = .systemRed
                }
                self.etaDistanceLbl.text = "\(arrivalTime) ETA - \(String(format: "%.1f", distanceMiles)) miles away"
            }
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
    
    func getEvents() {
        
        guard !isLoading else { return }
        guard hasMore else { return }
        
        isLoading = true
        
        VenuePresenter.getEventVenues(
            venueId: venueDetails?.id ?? "",
            skip: page, time: "PAST"
        ) { [weak self] isSuccess, errMsg, list, hasMore in
            
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if isSuccess {
                self.events.append(contentsOf: list)
                self.hasMore = hasMore
                
                if hasMore {
                    self.page += 1
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                print(errMsg ?? "Error")
            }
        }
    }
    
    @objc func handleSocialTap(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view as? UIImageView,
              let urlString = view.accessibilityHint,
              let url = URL(string: urlString) else { return }
        
        UIApplication.shared.open(url)
    }
    
    @IBAction func onClickViewMore(_ sender: Any) {
        isExpanded.toggle()

        venueAboutLbl.font = UIFont(name: "Inter-Regular", size: 16) ?? .systemFont(ofSize: 16)

        if isExpanded {
            venueAboutLbl.numberOfLines = 0
            viewMoreBtn.setTitle("View Less", for: .normal)
        } else {
            venueAboutLbl.numberOfLines = collapsedLines
            viewMoreBtn.setTitle("View More", for: .normal)
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func onClickSeeAllBtn(_ sender: Any) {
        
    }
    
    private func setupExpandableLabel() {
        
        venueAboutLbl.text = venueDetails?.description
        venueAboutLbl.font = UIFont(name: "Inter-Regular", size: 16) ?? .systemFont(ofSize: 16)
        
        venueAboutLbl.numberOfLines = collapsedLines
        venueAboutLbl.lineBreakMode = .byTruncatingTail
        
        viewMoreBtn.setTitle("View More", for: .normal)

        view.layoutIfNeeded()
        checkIfTextNeedsExpansion()
    }
    
    private func checkIfTextNeedsExpansion() {
        
        let width = venueAboutLbl.frame.width
        guard width > 0 else { return }
        
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        
        venueAboutLbl.numberOfLines = 0
        let fullHeight = venueAboutLbl.sizeThatFits(size).height
        
        venueAboutLbl.numberOfLines = collapsedLines
        let collapsedHeight = venueAboutLbl.sizeThatFits(size).height
        
        viewMoreBtnView.isHidden = fullHeight <= collapsedHeight + 1
        venueAboutLbl.numberOfLines = isExpanded ? 0 : collapsedLines
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
        events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: VenueEventTVC = tableView.dequeue(withIdentifier: VenueEventTVC.identifier, for: indexPath)
        
        let event = events[indexPath.row]
        cell.configure(with: event)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.row == events.count - 3 {
//            getEvents()
        }
    }
//    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        
//        let offsetY = scrollView.contentOffset.y
//        let contentHeight = scrollView.contentSize.height
//        let height = scrollView.frame.size.height
//        
//        if offsetY > contentHeight - height - 100 {
//            getEvents()
//        }
//    }
}

extension VenueDetailsVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        updateDistanceAndETA()
    }
}
