//
//  DiscoverVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 22/12/25.
//

import UIKit

final class DiscoverVC: UIViewController {
    
    @IBOutlet weak var tonightEventCollectionView: UICollectionView!
    @IBOutlet weak var venueListCollectionView: UICollectionView!
    @IBOutlet weak var allEventsCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tonightEventCollectionView.register(EventCVC.nib, forCellWithReuseIdentifier: EventCVC.identifier)
        venueListCollectionView.register(VenueCVC.nib, forCellWithReuseIdentifier: VenueCVC.identifier)
        allEventsCollectionView.register(EventV2CVC.nib, forCellWithReuseIdentifier: EventV2CVC.identifier)
    }
    
    @IBAction func onClickCity(_ sender: Any) {
        Navigate.to.selectLocationVC(self)
    }
    
    @IBAction func onClickDate(_ sender: Any) {
        Navigate.to.dateRangeSelectionVC(self)
    }
}

extension DiscoverVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case tonightEventCollectionView:
            return 5
        case venueListCollectionView:
            return 5
        case allEventsCollectionView:
            return 5
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case tonightEventCollectionView:
            let cell: EventCVC = collectionView.dequeue(withIdentifier: EventCVC.identifier, for: indexPath)
            return cell
        case venueListCollectionView:
            let cell: VenueCVC = collectionView.dequeue(withIdentifier: VenueCVC.identifier, for: indexPath)
            return cell
        case allEventsCollectionView:
            let cell: EventV2CVC = collectionView.dequeue(withIdentifier: EventV2CVC.identifier, for: indexPath)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
}

extension DiscoverVC: SelectedDateDelegate {
    func selectedDateRange(startDate: String?, endDate: String?) {
        print("-=-=-= \(startDate ?? "")")
        print("-=-=-= \(endDate ?? "")")
//        if startDate == endDate {
//            fromDate = startDate
//            toDate = nil
//        } else {
//            fromDate = startDate
//            toDate = endDate
//        }
//        self.tableView.reloadData()
    }
}
