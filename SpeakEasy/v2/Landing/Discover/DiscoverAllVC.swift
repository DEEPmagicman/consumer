//
//  DiscoverAllVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 24/12/25.
//

import UIKit

final class DiscoverAllVC: UIViewController {
    
    @IBOutlet weak var tonightEventCollectionView: UICollectionView!
    @IBOutlet weak var venueListCollectionView: UICollectionView!
    @IBOutlet weak var allEventsCollectionView: UICollectionView!
    
    var isTonightEventInitialLoading = true
    var isAllEventInitialLoading = true
    var isVenueInitialLoading = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tonightEventCollectionView.register(EventCVC.nib, forCellWithReuseIdentifier: EventCVC.identifier)
        venueListCollectionView.register(VenueCVC.nib, forCellWithReuseIdentifier: VenueCVC.identifier)
        allEventsCollectionView.register(EventV2CVC.nib, forCellWithReuseIdentifier: EventV2CVC.identifier)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.updateShimmerView()
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
}

extension DiscoverAllVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case tonightEventCollectionView:
            return isTonightEventInitialLoading ? 3 : 5
        case venueListCollectionView:
            return isVenueInitialLoading ? 3 : 5
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
            let cell: VenueCVC = collectionView.dequeue(withIdentifier: VenueCVC.identifier, for: indexPath)
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
