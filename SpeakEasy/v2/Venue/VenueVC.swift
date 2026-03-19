//
//  VenueVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/03/26.
//

import UIKit

final class VenueVC: UIViewController {
    
    @IBOutlet weak var venueView: UIView!
    
    var header: VenueHeaderVC?
    var segmentedScrollView = SJSegmentedViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSegmentVC()
    }
    
    private func setUpSegmentVC() {
        let header = VenueHeaderVC(nibName: "VenueHeaderVC", bundle: nil)
        self.header = header
        segmentedScrollView.headerViewHeight = 245
        
        segmentedScrollView.delegate = self
        segmentedScrollView.segmentBounces = false
        segmentedScrollView.scrollCallBackDelegate = self
        if let font = UIFont(name: "poppins-medium", size: 15) {
            segmentedScrollView.segmentTitleFont = font
        }
        segmentedScrollView.selectedSegmentViewHeight = 4
        segmentedScrollView.headerViewController = header
        
        let vc1 = VenueEventsVC(nibName: "VenueEventsVC", bundle: nil)
        vc1.title = "Events"
        
        let vc2 = VenueDetailsVC(nibName: "VenueDetailsVC", bundle: nil)
        vc2.title = "Details"
        segmentedScrollView.segmentControllers = [vc1, vc2]
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
        segmentedScrollView.segmentedScrollView.backgroundColor = .red
        segmentedScrollView.selectedSegmentViewHeight = 0.5
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
