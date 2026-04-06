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
    private var shimmerView: VenueShimmerView?
    
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
        
//        setUpSegmentVC()
        showShimmer()
        getVenueDetails()
    }
    
    private func showShimmer() {
        let shimmer = VenueShimmerView(frame: view.bounds)
        view.addSubview(shimmer)
        shimmer.start()
        self.shimmerView = shimmer
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
                self.shimmerView?.stop()
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
        segmentedScrollView.headerViewHeight = header.headerHeight
        
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



final class VenueShimmerView: UIView {
    
    private var shimmerViews: [ShimmerView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func makeShimmer(_ frame: CGRect, corner: CGFloat = 8) -> ShimmerView {
        let view = ShimmerView(frame: frame)
        view.layer.cornerRadius = corner
        view.clipsToBounds = true
        addSubview(view)
        shimmerViews.append(view)
        return view
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        let width = UIScreen.main.bounds.width
        
        // 🔹 Follow button
        makeShimmer(CGRect(x: width/2 - 60, y: 240, width: 120, height: 36), corner: 18)
        
        // 🔹 Ticket card
        makeShimmer(CGRect(x: 16, y: 300, width: width - 32, height: 60), corner: 12)
        
        // 🔹 Tabs (3)
        for i in 0..<3 {
            makeShimmer(CGRect(x: 20 + (i * 120), y: 380, width: 80, height: 20))
        }
        
        // 🔹 Event list (5 rows)
        var y: CGFloat = 420
        for _ in 0..<5 {
            
            // image
            makeShimmer(CGRect(x: 16, y: y, width: 80, height: 80), corner: 12)
            
            // title
            makeShimmer(CGRect(x: 110, y: y + 10, width: width - 140, height: 16))
            
            // subtitle
            makeShimmer(CGRect(x: 110, y: y + 35, width: width - 180, height: 14))
            
            // location
            makeShimmer(CGRect(x: 110, y: y + 55, width: width - 200, height: 14))
            
            y += 100
        }
    }
    
    func start() {
        shimmerViews.forEach { $0.startAnimating() }
    }
    
    func stop() {
        shimmerViews.forEach { $0.stopAnimating() }
        removeFromSuperview()
    }
}
