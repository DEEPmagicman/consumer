import UIKit
import Combine
import Hero

final class DiscoverAllVC: UIViewController {
    
    @IBOutlet weak var tonightEventCollectionView: UICollectionView!
    @IBOutlet weak var venueListCollectionView: UICollectionView!
    @IBOutlet weak var allEventsCollectionView: UICollectionView!
    @IBOutlet weak var venueTitleLable: UILabel!
    @IBOutlet weak var todaysEventsView: UIView!
    @IBOutlet weak var premiumExperiencesView: UIView!
    @IBOutlet weak var premiumExerienceParentView: UIView!
    @IBOutlet weak var eventsInCityTitleLbl: UILabel!
    @IBOutlet weak var eventsInCityView: UIView!
    
    // MARK: - Loading States
    var isTonightEventInitialLoading = true
    var isAllEventInitialLoading = true
    var isVenueInitialLoading = true
    
    // MARK: - Venue
    private var openVenueList = [ClipVenue]()
    private var closeVenueList = [ClipVenue]()
    private var openFrom = 0
    private var closeFrom = 0
    private var openHasMore = false
    private var closeHasMore = false
    
    // MARK: - Tonight Events
    private var tonightEventSkip = 0
    private var todaysEvents = [Event]()
    
    // MARK: - All Events
    private var allEventSkip = 0
    private var allEvents = [Event]()
    private var allEventHasMore = false
    
    private var presenter = MVPPresenter()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
        bindSelectedCity()
        setupHero()
        setVenueListForSelectedCity()
        
        getTonightEvent()
        getAllEvents()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.updateShimmerView()
        }
        
        premiumExperiencesView.setHorizontalGradientColor(
            colors: [
                UIColor(hex: "#292929").withAlphaComponent(0.1).cgColor,
                UIColor(hex: "#FFCE51").withAlphaComponent(0.1).cgColor
            ]
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        premiumExperiencesView.setHorizontalGradientColor(
            colors: [
                UIColor(hex: "#292929").withAlphaComponent(0.1).cgColor,
                UIColor(hex: "#FFCE51").withAlphaComponent(0.1).cgColor
            ]
        )
    }
    
    // MARK: - Setup
    private func registerCells() {
        tonightEventCollectionView.register(EventCVC.nib, forCellWithReuseIdentifier: EventCVC.identifier)
        venueListCollectionView.register(VenueCVC.nib, forCellWithReuseIdentifier: VenueCVC.identifier)
        allEventsCollectionView.register(EventV2CVC.nib, forCellWithReuseIdentifier: EventV2CVC.identifier)
    }
    
    private func setupHero() {
        hero.isEnabled = true
        navigationController?.hero.isEnabled = true
        navigationController?.hero.navigationAnimationType = .auto
    }
    
    // MARK: - API CALLS
    
    private func getTonightEvent() {
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
            
            self.isTonightEventInitialLoading = false
            
            self.todaysEventsView.isHidden = self.todaysEvents.isEmpty
            
            self.tonightEventCollectionView.reloadData()
        }
    }
    
    private func getAllEvents() {
        EventPresenter.getEvents(
            from: allEventSkip,
            venueId: "",
            time: "UPCOMING",
            city: UserDefault.shared.localCity
        ) { [weak self] _, _, eventList, hasMore in
            
            guard let self = self else { return }
            
            if self.allEventSkip == 0 {
                self.allEvents.removeAll()
            }
            
            self.allEvents.append(contentsOf: eventList)
            
            if hasMore {
                self.allEventSkip = self.allEvents.count
            }
            
            self.allEventHasMore = hasMore
            self.isAllEventInitialLoading = false
            self.eventsInCityView.isHidden = self.allEvents.isEmpty
            
            self.allEventsCollectionView.reloadData()
        }
    }
    
    private func fetchAllOpenVenueForMVP() {
        presenter.getVenueListForMVP(from: openFrom, status: VenueStatus.open.rawValue) { [weak self] isSuccess, errMsg, venues, hasMore in
            
            guard let self = self else { return }
            
            if isSuccess {
                if self.openFrom == 0 { self.openVenueList.removeAll() }
                
                self.openVenueList.append(contentsOf: venues)
                
                if hasMore {
                    self.openFrom = self.openVenueList.count
                }
                
                self.openHasMore = hasMore
                
                if !hasMore {
                    self.fetchAllCloseVenueForMVP()
                }
                
                self.isVenueInitialLoading = false
                self.venueListCollectionView.reloadData()
                
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? "Something went wrong", message: "")
            }
        }
    }
    
    private func fetchAllCloseVenueForMVP() {
        presenter.getVenueListForMVP(from: closeFrom, status: VenueStatus.close.rawValue) { [weak self] isSuccess, errMsg, venues, hasMore in
            
            guard let self = self else { return }
            
            if isSuccess {
                if self.closeFrom == 0 { self.closeVenueList.removeAll() }
                
                self.closeVenueList.append(contentsOf: venues)
                self.openVenueList.append(contentsOf: venues)
                
                if hasMore {
                    self.closeFrom = self.closeVenueList.count
                }
                
                self.closeHasMore = hasMore
                self.isVenueInitialLoading = false
                
                self.venueListCollectionView.reloadData()
                
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? "Something went wrong", message: "")
            }
        }
    }
    
    // MARK: - Refresh
    
    private func refreshAllList() {
        isTonightEventInitialLoading = true
        isAllEventInitialLoading = true
        isVenueInitialLoading = true
        
        todaysEvents.removeAll()
        allEvents.removeAll()
        openVenueList.removeAll()
        closeVenueList.removeAll()
        
        tonightEventSkip = 0
        allEventSkip = 0
        
        tonightEventCollectionView.reloadData()
        allEventsCollectionView.reloadData()
        venueListCollectionView.reloadData()
        
        getTonightEvent()
        getAllEvents()
        fetchAllOpenVenueForMVP()
    }
    
    private func updateShimmerView() {
        isTonightEventInitialLoading = false
        isAllEventInitialLoading = false
        isVenueInitialLoading = false
        
        tonightEventCollectionView.reloadData()
        allEventsCollectionView.reloadData()
        venueListCollectionView.reloadData()
    }
    
    // MARK: - City Binding
    
    private func bindSelectedCity() {
        UserDefault.shared.localCityPublisher
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.setVenueListForSelectedCity()
                self?.refreshAllList()
            }
            .store(in: &cancellables)
    }
    
    private func resolvedCity() -> String {
        let city = UserDefault.shared.localCity.trimmingCharacters(in: .whitespacesAndNewlines)
        return city.isEmpty ? "New York" : city
    }
    
    private func setVenueListForSelectedCity() {
        let city = resolvedCity()
        venueTitleLable.text = "Venues in \(city)"
        eventsInCityTitleLbl.text = "Events in \(city)"
        fetchAllOpenVenueForMVP()
    }
    
    // MARK: - Actions

    @IBAction func onClickBookNow(_ sender: Any) {
        Navigate.to.premiumExperiencesVC(self)
    }

    @IBAction func onClickVenueSeeAllBtn(_ sender: Any) {
        Navigate.to.allVenueVC(self)
    }

    @IBAction func onClickDiscoverSeeAllBtn(_ sender: Any) {
        Navigate.to.eventsListVC(self, screenType: .discoverExperiences)
    }

    @IBAction func onClickEventsSeeAllBtn(_ sender: Any) {
        Navigate.to.eventsListVC(self, screenType: .allEvents)
    }
}

// MARK: - CollectionView

extension DiscoverAllVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
        case venueListCollectionView:
            return isVenueInitialLoading ? 3 : min(openVenueList.count, 5)
            
        case tonightEventCollectionView:
            return isTonightEventInitialLoading ? 3 : todaysEvents.count
            
        case allEventsCollectionView:
            return isAllEventInitialLoading ? 3 : allEvents.count
            
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
            
        case tonightEventCollectionView:
            let cell: EventCVC = collectionView.dequeue(withIdentifier: EventCVC.identifier, for: indexPath)
            
            if isTonightEventInitialLoading {
                cell.shimmerView.isHidden = false
                cell.shimmerView.startAnimating()
            } else {
                cell.shimmerView.isHidden = true
                let event = todaysEvents[indexPath.item]
                cell.setupData(event: event)
            }
            return cell
            
        case venueListCollectionView:
            let cell: VenueCVC = collectionView.dequeue(withIdentifier: VenueCVC.identifier, for: indexPath)
            
            if isVenueInitialLoading {
                cell.shimmerView.isHidden = false
            } else {
                cell.shimmerView.isHidden = true
                let venue = openVenueList[indexPath.item]
                cell.configure(with: venue)
            }
            return cell
            
        case allEventsCollectionView:
            let cell: EventV2CVC = collectionView.dequeue(withIdentifier: EventV2CVC.identifier, for: indexPath)
            
            if isAllEventInitialLoading {
                cell.shimmerView.isHidden = false
            } else {
                cell.shimmerView.isHidden = true
                let event = allEvents[indexPath.item]
                cell.setupData(event: event)
            }
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch collectionView {
            
        case tonightEventCollectionView:
            if isTonightEventInitialLoading { return }
            Navigate.eventDetailsVC(self, event: todaysEvents[indexPath.item])
            
        case venueListCollectionView:
            if isVenueInitialLoading { return }
            Navigate.to.venueVC(self, venueDetails: openVenueList[indexPath.item])
            
        case allEventsCollectionView:
            if isAllEventInitialLoading { return }
            Navigate.eventDetailsVC(self, event: allEvents[indexPath.item])
            
        default:
            break
        }
    }
}
