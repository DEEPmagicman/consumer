//
//  AllEventsTVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
// AllEventDataSet

import UIKit

class AllEventsTVC: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var viewSeeAll: UIView!
//    @IBOutlet weak var btnSeeAll: UIButton!
    @IBOutlet weak var viewSeperator: UIView!
    @IBOutlet weak var btnSeeAll: UIButton!
    
    var arrayFeaturedEvents = [
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG1"), lblPerformerName: "Ferreck Dawn", lblVenueName: "SPYBAR CHICAGO", lblEventDate: "Saturday, June 18"),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG2"), lblPerformerName: "Valentino Khan", lblVenueName: "Soundbar", lblEventDate: "Saturday, July 9"),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG3"), lblPerformerName: "Nathan Scott", lblVenueName: "TAO Chicago", lblEventDate: "Thursday, July 7")
    ]
    var arrayFilteredFeaturedEvents = [TopEventDataSet]()
    
    var arrayUpcomingEvents = [
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG1"), lblPerformerName: "NGHTMRE", lblVenueName: "TAO Chicago",  lblEventDate: "Saturday, July 2"),
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG2"), lblPerformerName: "Navic", lblVenueName: "Soundbar",  lblEventDate: "Thursday, June 7"),
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG3"), lblPerformerName: "DJ Daily", lblVenueName: "Bounce Chicago",  lblEventDate: "Friday, July 24")
    ]
    
    var arrayGeneralAdmission = [
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG1"), lblPerformerName: "TAO Fridays", lblVenueName: "TAO Chicago",  lblEventDate: "Friday, July 1"),
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG2"), lblPerformerName: "Bonce Thrusdays", lblVenueName: "Bounce Chicago",  lblEventDate: "Thursday, June 7"),
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG3"), lblPerformerName: "Sundown Sundaze", lblVenueName: "PRYSM Chicago",  lblEventDate: "Sunday, July 3")
    ]
    
    var searchText = ""
    var isFilter = false
    var hasEvents: ((Bool)->Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.registerCell()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    func setData(seeAll: Bool){
        
        self.viewSeperator.isHidden = seeAll
        self.viewSeeAll.isHidden = !seeAll
        self.btnSeeAll.isHidden = !seeAll
    }
}
//MARK: - Helper methods
extension AllEventsTVC{
    private func registerCell(){
        self.collectionView.register(UINib(nibName: "EventCVC", bundle: nil), forCellWithReuseIdentifier: "EventCVC")
    }
    func searchEvent(){
        if self.searchText.isEmpty{
            self.isFilter = false
        }
        else{
            self.isFilter = true
            self.arrayFilteredFeaturedEvents = self.arrayFeaturedEvents.filter{($0.lblPerformerName ?? "").localizedCaseInsensitiveContains(self.searchText)}
        }
        
        self.collectionView.reloadData()
        
        self.hasEvents?(!self.arrayFilteredFeaturedEvents.isEmpty)
    }
}
extension AllEventsTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.isFilter {
        case true:
            return self.arrayFilteredFeaturedEvents.count
        case false:
            return self.arrayFeaturedEvents.count
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EventCVC", for: indexPath) as! EventCVC
        
        switch self.tag {
        case 0:
            switch self.isFilter {
            case true:
                let data = self.arrayFilteredFeaturedEvents[indexPath.item]
                cell.setData(data: data)
            case false:
                let data = self.arrayFeaturedEvents[indexPath.item]
                cell.setData(data: data)
            }
        case 1:
            let data = self.arrayUpcomingEvents[indexPath.item]
            cell.setData(data: data)
        case 2:
            let data = self.arrayGeneralAdmission[indexPath.item]
            cell.setData(data: data)
        default:
            break
        }
        
        return cell
    }
}
extension AllEventsTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 3.0
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}
