//
//  DiscoverAllVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 24/12/25.
//

import UIKit
import Combine

final class DiscoverAllVC: UIViewController {
    
    @IBOutlet weak var tonightEventCollectionView: UICollectionView!
    @IBOutlet weak var venueListCollectionView: UICollectionView!
    @IBOutlet weak var allEventsCollectionView: UICollectionView!
    @IBOutlet weak var venueTitleLable: UILabel!
    
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
    }
    
    private func fetchAllOpenVenueForMVP(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        presenter.getVenueListForMVP(from: openFrom,status: VenueStatus.open.rawValue) { [weak self] isSuccess, errMsg, openVenueList, hasMore in
            guard let self = self else {
                Loader.hide()
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
            Loader.hide()
        }
    }
    
    private func fetchAllCloseVenueForMVP(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        presenter.getVenueListForMVP(from: closeFrom,status: VenueStatus.close.rawValue) { [weak self] isSuccess, errMsg, closeVenueList, hasMore in
            guard let self = self else {
                Loader.hide()
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
            Loader.hide()
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
        fetchAllOpenVenueForMVP()
    }

    @IBAction func onClickBookNow(_ sender: Any) {
        isTonightEventInitialLoading = true
        tonightEventCollectionView.reloadData()
        
        isVenueInitialLoading = true
        venueListCollectionView.reloadData()
        
        isAllEventInitialLoading = false
        allEventsCollectionView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.updateShimmerView()
        }
    }
   
    @IBAction func onClickVenueSeeAllBtn(_ sender: Any) {
        Navigate.to.eventDetailsVC(self)
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
            return isTonightEventInitialLoading ? 3 : 5
        case allEventsCollectionView:
            return isAllEventInitialLoading ? 3 : 5
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case tonightEventCollectionView:
            let cell: EventCVC = collectionView.dequeue(withIdentifier: EventCVC.identifier, for: indexPath)
            cell.shimmerView.isHidden = !isTonightEventInitialLoading
            cell.shimmerView?.startAnimating()
            return cell
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
}
