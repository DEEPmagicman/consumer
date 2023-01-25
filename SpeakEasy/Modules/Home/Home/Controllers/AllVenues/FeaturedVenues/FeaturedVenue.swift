//
//  FeaturedVenue.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 16/09/2022.
//

import UIKit

class FeaturedVenue: BaseController {

    @IBOutlet weak var tableView: UITableView!
    
    
    var arrayRemainingHotVenueEvents = [
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenueRemainingBG1"), lblPerformerName: "Bounce Sporting Club", imgBrandLogo: UIImage(named:"HotVenueRemainingLogo1"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 2:00 AM"),
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenueRemainingBG2"), lblPerformerName: "PRYSM Chicago", imgBrandLogo: UIImage(named:"HotVenueRemainingLogo2"), isLive: true, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 4:00 AM"),
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenueRemainingBG3"), lblPerformerName: "RocBar", imgBrandLogo: UIImage(named:"HotVenueRemainingLogo3"), isLive: true, isFavourite: false, lblEventFees: "$35", lblEventWaitingTime: "15 mins", lblEventClosingTime: "Closes 3:00 AM"),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
    }
}
extension FeaturedVenue {
    private func setUI(){
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        } else {
            // Fallback on earlier versions
        }
        self.registerCells()
    }
    private func registerCells(){
        self.tableView.register(UINib(nibName: "VenueTVC", bundle: nil), forCellReuseIdentifier: "VenueTVC")
    }
}
extension FeaturedVenue: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrayRemainingHotVenueEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VenueTVC", for: indexPath) as! VenueTVC
        let data = self.arrayRemainingHotVenueEvents[indexPath.row]
        cell.selectionStyle = .none
        cell.setData(data: data)
        cell.setData(seeAll: false)
        return cell
    }
}

extension FeaturedVenue: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
//            let height = tableView.frame.height * 0.45
//            return height
            return UITableView.automaticDimension
        default:
            return UITableView.automaticDimension
        }
    }
}
extension FeaturedVenue: VenueDetailProtocol {
    func didSelect(index: Int) {
        Utility.main.topViewController()?.navigationController?.pushViewController(VenueDetails(), animated: true)
    }
}
