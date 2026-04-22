//
//  EventsListVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 08/04/26.
//

import UIKit
import Hero

enum EventsScreenType {
    case allEvents
    case discoverExperiences
    
    var title: String {
        switch self {
        case .allEvents:
            return "All Events"
        case .discoverExperiences:
            return "Discover Experiences"
        }
    }
}

class EventsListVC: UIViewController {
    
    @IBOutlet weak var eventCollectionView: UICollectionView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var navTitleLbl: UILabel!
    @IBOutlet weak var navTitleBgView: UIView!
    @IBOutlet weak var bgViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var screenTitleLabel: UILabel!
    @IBOutlet weak var dateBtn: UIView!
    @IBOutlet weak var filterLbl: UILabel!
    
    private var todaysEvents = [Event]()
    private var tonightEventSkip = 0
    private var hasMore = false
    private var isInitialLoading = true
    
    private var isCollapsed = false
    private let collapseThreshold: CGFloat = 120
    var screenType: EventsScreenType = .allEvents
    private let dropDown = DropDown()
    private var selectedFilter = "Date"
    private let filterOptions = ["Date", "Nearest", "Newest"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        getEvents()
        
        hero.isEnabled = true
        navigationController?.hero.isEnabled = true
        navigationController?.hero.navigationAnimationType = .auto
        scrollView.contentInsetAdjustmentBehavior = .never
        
        scrollView.delegate = self
        screenTitleLabel.text = screenType.title
        navTitleLbl.text = screenType.title
        setupDropDown()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        updateCollectionViewHeight()
    }
    
    private func setupCollectionView() {
        eventCollectionView.delegate = self
        eventCollectionView.dataSource = self
        eventCollectionView.backgroundColor = .clear
        eventCollectionView.isScrollEnabled = false
        eventCollectionView.register(EventV2CVC.nib, forCellWithReuseIdentifier: EventV2CVC.identifier)
        
        if let layout = eventCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 16
            layout.minimumInteritemSpacing = 12
            layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
    
    func setupDropDown() {

        dropDownLayout(dropDown: dropDown)
    }

    private func getEvents() {
        EventPresenter.getEvents(
            from: tonightEventSkip,
            venueId: "",
            time: "UPCOMING",
            city: UserDefault.shared.localCity
        ) { [weak self] _, _, eventList, hasMore in
            guard let self = self else { return }
            
            if self.tonightEventSkip == 0 {
                self.todaysEvents.removeAll()
            }
            
            self.todaysEvents.append(contentsOf: eventList)
            
            if hasMore {
                self.tonightEventSkip = self.todaysEvents.count
            }
            
            self.hasMore = hasMore
            self.isInitialLoading = false
            self.eventCollectionView.reloadData()
            self.updateCollectionViewHeight()
        }
    }
    
    private func dropDownLayout(dropDown: DropDown) {

        dropDown.cellHeight = 40
        dropDown.backgroundColor = UIColor(hex: "#282828")
        dropDown.textColor = .white
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        
        DropDown.appearance().setupCornerRadius(10)
        
        dropDown.anchorView = nil   // 👉 set dynamically on click
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y: 45)
        
        dropDown.dataSource = filterOptions
        dropDown.selectionBackgroundColor = .clear
        dropDown.selectionAction = { [weak self] index, item in
            guard let self = self else { return }
            
            self.selectedFilter = item
            print("Selected:", item)
            
            self.applyFilter(type: item)
        }
    }
    
    private func updateCollectionViewHeight() {
        eventCollectionView.layoutIfNeeded()
        collectionViewHeight.constant = eventCollectionView.collectionViewLayout.collectionViewContentSize.height
    }
    
    private func applyNavAppearance(collapsed: Bool) {
        navTitleLbl.alpha = collapsed ? 1 : 0
        navTitleLbl.isHidden = collapsed ? false : true
        backGroundView.alpha = collapsed ? 0 : 1
        bgViewHeight.constant = collapsed ? 0 : 298
        navTitleBgView.backgroundColor = collapsed ? UIColor(hex: "#282828") : .clear
    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickDateBtn(_ sender: Any) {
        dropDown.anchorView = dateBtn
        dropDown.width = dateBtn.frame.width
        
        dropDown.show()
    }
    
    func applyFilter(type: String) {

        switch type {
            
        case "Date":
            filterLbl.text = type
            print("Sort by Date")
            
        case "Nearest":
            filterLbl.text = type
            print("Sort by Nearest")
            
        case "Newest":
            filterLbl.text = type
            print("Sort by Newest")
            
        default:
            break
        }
        dropDown.hide() 
        eventCollectionView.reloadData()
    }
}

extension EventsListVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isInitialLoading ? 10 : todaysEvents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: EventV2CVC = collectionView.dequeue(
            withIdentifier: EventV2CVC.identifier,
            for: indexPath
        )

        if isInitialLoading {
            cell.shimmerView.isHidden = false
            for view in cell.shimmerView.subviews where view is ShimmerView {
                (view as? ShimmerView)?.startAnimating()
            }
        } else {
            cell.shimmerView.isHidden = true

            let event = todaysEvents[indexPath.item]
            cell.setupData(event: event)
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isInitialLoading { return }
        
        let selectedEvent = todaysEvents[indexPath.item]
        Navigate.eventDetailsVC(self, event: selectedEvent)
    }
}

extension EventsListVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding: CGFloat = 16 + 16 + 12
        let width = (collectionView.bounds.width - padding) / 2
        
        return CGSize(width: width, height: 240)
    }
}

extension EventsListVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        
        let shouldCollapse = scrollView.contentOffset.y > collapseThreshold
        
        if shouldCollapse != isCollapsed {
            isCollapsed = shouldCollapse
            applyNavAppearance(collapsed: shouldCollapse)
        }
    }
}
