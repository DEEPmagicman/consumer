//
//  DiscoverAllVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 24/12/25.
//

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
    
    var isTonightEventInitialLoading = true
    var isAllEventInitialLoading = true
    var isVenueInitialLoading = true
    private var openVenueList = [ClipVenue]()
    private var closeVenueList = [ClipVenue]()
    private var openFrom = 0
    private var presenter = MVPPresenter()
    private var openHasMore = false
    private var closeFrom = 0
    private var closeHasMore = false
    private var tonightEventSkip = 0
    private var todaysEvents = [Event]()
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tonightEventCollectionView.register(EventCVC.nib, forCellWithReuseIdentifier: EventCVC.identifier)
        venueListCollectionView.register(VenueCVC.nib, forCellWithReuseIdentifier: VenueCVC.identifier)
        allEventsCollectionView.register(EventV2CVC.nib, forCellWithReuseIdentifier: EventV2CVC.identifier)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.updateShimmerView()
        }
        bindSelectedCity()
        getTonightEvent()
        hero.isEnabled = true
        navigationController?.hero.isEnabled = true
        navigationController?.hero.navigationAnimationType = .auto
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
    private func fetchAllOpenVenueForMVP(withLoader: Bool = true) {
        presenter.getVenueListForMVP(from: openFrom, status: VenueStatus.open.rawValue) { [weak self] isSuccess, errMsg, openVenueList, hasMore in
            guard let self = self else {
                return
            }
            if isSuccess {
                if self.openFrom == 0 {
                    self.openVenueList.removeAll()
                }
                for venue in openVenueList {
                    self.openVenueList.append(venue)
                }
                if hasMore {
                    self.openFrom = self.openVenueList.count
                }
                self.openHasMore = hasMore
                if !self.openHasMore {
                    self.fetchAllCloseVenueForMVP()
                }
                self.venueListCollectionView.reloadData()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
            #if DEBUG
            if withLoader == false && self.navigationController?.viewControllers.last is MVPVenueListVc {
                Alert.showToast("Venue detail updated")
            }
            #endif
        }
    }
    
    private func fetchAllCloseVenueForMVP(withLoader: Bool = true) {
        presenter.getVenueListForMVP(from: closeFrom, status: VenueStatus.close.rawValue) { [weak self] isSuccess, errMsg, closeVenueList, hasMore in
            guard let self = self else {
                return
            }
            if isSuccess {
                if self.closeFrom == 0 {
                    self.closeVenueList.removeAll()
                }
                for venue in closeVenueList {
                    self.openVenueList.append(venue)
                    self.closeVenueList.append(venue)
                }
                if hasMore {
                    self.closeFrom = self.closeVenueList.count
                }
                self.closeHasMore = hasMore
                self.venueListCollectionView.reloadData()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
            #if DEBUG
            if withLoader == false && self.navigationController?.viewControllers.last is MVPVenueListVc {
                Alert.showToast("Venue detail updated")
            }
            #endif
        }
    }
    
    private func getTonightEvent() {
        EventPresenter.getEvents(from: tonightEventSkip,venueId: "", time: "UPCOMING", city: UserDefault.shared.localCity) { [weak self] _, _, eventList, hasMore in
            guard let self = self else { return }
            
            if self.tonightEventSkip == 0 {
                self.todaysEvents.removeAll()
            }
            for event in eventList {
                self.todaysEvents.append(event)
            }
            if hasMore {
                self.tonightEventSkip = self.todaysEvents.count
            }
            isTonightEventInitialLoading = false
            if todaysEvents.isEmpty {
                self.todaysEventsView.isHidden = true
            } else {
                self.todaysEventsView.isHidden = false
            }
            self.tonightEventCollectionView.reloadData()
        }
    }
    
    private func updateShimmerView() {
        isTonightEventInitialLoading = false
        tonightEventCollectionView.reloadData()
        
        isVenueInitialLoading = false
        venueListCollectionView.reloadData()
        
        isAllEventInitialLoading = false
        allEventsCollectionView.reloadData()
    }
    
    private func bindSelectedCity() {
        UserDefault.shared.localCityPublisher
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.setVenueListForSelectedCity()
                self?.getTonightEvent()
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

    @IBAction func onClickBookNow(_ sender: Any) {
//        Navigate.to.premiumExperiencesVC(self)
    }
   
    @IBAction func onClickVenueSeeAllBtn(_ sender: Any) {
        Navigate.to.allVenueVC(self)
    }
}

extension DiscoverAllVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case venueListCollectionView:
            return isVenueInitialLoading
                        ? 3
                        : min(openVenueList.count, 5)
        case tonightEventCollectionView:
            return isTonightEventInitialLoading ? 3 : todaysEvents.count
        case allEventsCollectionView:
            return isAllEventInitialLoading ? 3 : 5
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case tonightEventCollectionView:
            if isTonightEventInitialLoading {
                let cell: EventCVC = collectionView.dequeue(withIdentifier: EventCVC.identifier, for: indexPath)
                cell.shimmerView.isHidden = !isTonightEventInitialLoading
                cell.shimmerView?.startAnimating()
                return cell
            } else {
                let cell: EventCVC = collectionView.dequeue(withIdentifier: EventCVC.identifier, for: indexPath)
                cell.shimmerView.isHidden = true

                let event = todaysEvents[indexPath.item]
                cell.setupData(event: event)
                cell.bgImage.hero.id = "event.image.\(event.id)"
                cell.eventTitleLbl.hero.id = "event.title.\(event.id)"
                return cell
            }
           
        case venueListCollectionView:
            let cell: VenueCVC = collectionView.dequeue(
                withIdentifier: VenueCVC.identifier,
                for: indexPath
            )

            if isVenueInitialLoading {
                cell.shimmerView.isHidden = false
                for view in cell.shimmerView.subviews where view is ShimmerView {
                    (view as? ShimmerView)?.startAnimating()
                }
            } else {
                cell.shimmerView.isHidden = true

                let venue = openVenueList[indexPath.item]
                cell.configure(with: venue) 
            }

            return cell
        case allEventsCollectionView:
            let cell: EventV2CVC = collectionView.dequeue(withIdentifier: EventV2CVC.identifier, for: indexPath)
            if isVenueInitialLoading {
                cell.shimmerView.isHidden = false
                for view in cell.shimmerView.subviews where view is ShimmerView {
                    (view as? ShimmerView)?.startAnimating()
                }
                return cell
            } else {
                cell.shimmerView.isHidden = true
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
               let selectedEvent = todaysEvents[indexPath.item]
               Navigate.eventDetailsVC(self, event: selectedEvent)

           case venueListCollectionView:
               if isVenueInitialLoading { return }

               let selectedVenue = openVenueList[indexPath.item]
               Navigate.to.venueVC(self, venueDetails: selectedVenue)

           case allEventsCollectionView:
               if isAllEventInitialLoading { return }

//               let selectedEvent = allEvents[indexPath.item]   // make sure this array exists
//               Navigate.to.eventDetailsVC(self, event: selectedEvent)

           default:
               break
           }
       }
}
