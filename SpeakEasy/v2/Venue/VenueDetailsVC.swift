//
//  VenueDetailsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 04/02/26.
//

import UIKit
import MapKit

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
    @IBOutlet weak var viewMoreLbl: UILabel!
    @IBOutlet weak var viewMoreLblHeight: NSLayoutConstraint!
    @IBOutlet weak var viewMoreBtn: UIButton!
    @IBOutlet weak var viewMoreBtnView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
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
        configureUI()
        getEvents()
    }
    
    private func configureUI() {
        setupSocialIcons()
        handleViewMore()
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
    }
    
    func setupSocialIcons() {
        for platform in socialPlatforms {
            
            guard let urlString = platform.urlString,
                  let url = URL(string: urlString),
                  !urlString.isEmpty else {
                platform.iconView.isHidden = true
                continue
            }
            
            platform.iconView.isHidden = false
            platform.iconView.isUserInteractionEnabled = true
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSocialTap(_:)))
            platform.iconView.addGestureRecognizer(tapGesture)
            
            platform.iconView.accessibilityHint = urlString
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
