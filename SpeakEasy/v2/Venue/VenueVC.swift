//
//  VenueVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/03/26.
//

import UIKit

final class VenueVC: UIViewController {
    
    @IBOutlet weak var venueView: UIView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var bgImage: UIImageView!
    
    var header: VenueHeaderVC?
    var segmentedScrollView = SJSegmentedViewController()
    var presenter = MVPPresenter()
    
    var venueDetails: ClipVenue?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        venueName.text = venueDetails?.name ?? "Venue"
        let logoUrl = "\(SharedURL.amazonStorage)\(venueDetails?.logo?.key ?? "")"
        self.venueLogo.sd_setImage(with: URL( string: logoUrl), completed: nil)
        let imageUrlString = "\(SharedURL.amazonStorage)\(venueDetails?.venueAttachment?.first?.key ?? "")"
        if let url = URL(string: imageUrlString) {
            bgImage.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "newSpeakeasy")
            )
        } else {
            bgImage.image = UIImage(named: "newSpeakeasy")
        }
        
        setUpSegmentVC()
        getVenueDetails()
    }
    
    private func getVenueDetails() {
        presenter.getVenuesDetailForaMVP(
            venueId: venueDetails?.uniqueId ?? "",
            venueTimeZone: venueDetails?.useTimezone ?? "",
            doormanId: ""
        ) { [weak self] isSuccess, errMsg, venueDetail in
            
            guard let self = self else { return }
            
            if isSuccess, let venue = venueDetail {
                self.venueDetails = venue
                setUpSegmentVC()
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? "Something went wrong",
                    message: ""
                )
            }
        }
    }
    
    private func setUpSegmentVC() {
        let header = VenueHeaderVC(nibName: "VenueHeaderVC", bundle: nil)
        header.venueDetails = self.venueDetails
        self.header = header
        segmentedScrollView.headerViewHeight = 110
        
        segmentedScrollView.delegate = self
        segmentedScrollView.segmentBounces = false
        segmentedScrollView.scrollCallBackDelegate = self
        if let font = UIFont(name: "poppins-medium", size: 15) {
            segmentedScrollView.segmentTitleFont = font
        }
        segmentedScrollView.selectedSegmentViewHeight = 2
        segmentedScrollView.headerViewController = header
        
        let vc1 = VenueEventsVC(nibName: "VenueEventsVC", bundle: nil)
        vc1.title = "Events"
        vc1.venueId = venueDetails?.id ?? ""
        
        let vc2 = VenueExperiencesVC(nibName: "VenueExperiencesVC", bundle: nil)
        vc2.title = "Experiences"
        
        let vc3 = VenueDetailsVC(nibName: "VenueDetailsVC", bundle: nil)
        vc3.venueDetails = venueDetails
        vc3.title = "Details"
        segmentedScrollView.segmentControllers = [vc1, vc2, vc3]
        segmentedScrollView.segmentShadow = SJShadow(offset: CGSize(width: 0, height: 0), color: .white, radius: 0, opacity: 0.4)
        
        segmentedScrollView.headerViewOffsetHeight = 0
        segmentedScrollView.segmentedScrollView.backgroundColor = .clear
        segmentedScrollView.segmentTitleColor = UIColor(hex: "#A1A1A1")
        segmentedScrollView.segmentSelectedTitleColor = .white
        segmentedScrollView.segmentBackgroundColor = .clear
        segmentedScrollView.selectedSegmentViewColor = .green
        venueView.addSubview(segmentedScrollView.view)
        addChild(segmentedScrollView)
        segmentedScrollView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedScrollView.view.leadingAnchor.constraint(equalTo: venueView.leadingAnchor),
            segmentedScrollView.view.trailingAnchor.constraint(equalTo: venueView.trailingAnchor),
            segmentedScrollView.view.topAnchor.constraint(equalTo: venueView.topAnchor),
            segmentedScrollView.view.bottomAnchor.constraint(equalTo: venueView.bottomAnchor)
        ])
        segmentedScrollView.segmentedScrollView.backgroundColor = .clear
        segmentedScrollView.didMove(toParent: self)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
}

extension VenueVC: SJSegmentedViewControllerDelegate, ScrollCallBackDelegate {
    func didMoveToPage(_ controller: UIViewController, segment: SJSegmentTab?, index: Int) {
        
    }
    
    func onChangeScrollListener(lastContentOffset: CGFloat, offSet: CGFloat) {
        
    }
}
