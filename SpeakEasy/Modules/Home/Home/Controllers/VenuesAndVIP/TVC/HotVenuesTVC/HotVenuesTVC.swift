//
//  HotVenuesTVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 29/08/2022.
//

import UIKit

class HotVenuesTVC: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    var delegate: VenueDetailProtocol?
    

    var arrayFilteredHotVenueEvents = [VenuesVIPEventDataSet]()
    
    var searchText = ""
    var isFilter = false
    var hasVenues: ((Bool)->Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.registerCell()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
}
//MARK: - Helper methods
extension HotVenuesTVC{
    private func registerCell(){
        self.collectionView.register(UINib(nibName: "HotVenueCVC", bundle: nil), forCellWithReuseIdentifier: "HotVenueCVC")
    }
    func searchVenue(){
        if self.searchText.isEmpty{
            self.isFilter = false
        }
        else{
            self.isFilter = true
            self.arrayFilteredHotVenueEvents = Constants.arrayHotVenueEvents.filter{($0.lblPerformerName ?? "").localizedCaseInsensitiveContains(searchText)}
        }
        
        self.collectionView.reloadData()
        
        self.hasVenues?(!self.arrayFilteredHotVenueEvents.isEmpty)
    }
}
extension HotVenuesTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.isFilter {
        case true:
            return self.arrayFilteredHotVenueEvents.count
        case false:
            return Constants.arrayHotVenueEvents.count
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch self.isFilter {
        case true:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HotVenueCVC", for: indexPath) as! HotVenueCVC
            let data = self.arrayFilteredHotVenueEvents[indexPath.item]
            cell.setData(data: data)
            return cell
        case false:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HotVenueCVC", for: indexPath) as! HotVenueCVC
            let data = Constants.arrayHotVenueEvents[indexPath.item]
            cell.setData(data: data)
            return cell
        }
    }
}
extension HotVenuesTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width * 0.675
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.didSelect(index: indexPath.row)
    }
}

protocol VenueDetailProtocol {
    func didSelect(index: Int)
}
