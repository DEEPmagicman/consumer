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
    
    var arrayHotVenueEvents = [
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG1"), lblPerformerName: "TAO Chicago", imgBrandLogo: UIImage(named:"VenueTao"), isLive: true, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 4:00 AM"),
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG2"), lblPerformerName: "The Underground", imgBrandLogo: UIImage(named:"HotVenueBrandLogo3"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 3:00 AM"),
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG3"), lblPerformerName: "Studio Paris", imgBrandLogo: UIImage(named:"HotVenueBrandLogo2"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 11:00 PM"),
    ]
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
            self.arrayFilteredHotVenueEvents = self.arrayHotVenueEvents.filter{($0.lblPerformerName ?? "").localizedCaseInsensitiveContains(searchText)}
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
            return self.arrayHotVenueEvents.count
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
            let data = self.arrayHotVenueEvents[indexPath.item]
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
        self.delegate?.didSelect()
    }
}

protocol VenueDetailProtocol {
    func didSelect()
}
