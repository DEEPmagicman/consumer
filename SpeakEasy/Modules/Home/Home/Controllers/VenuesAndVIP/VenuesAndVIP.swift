//
//  VenuesAndVIP.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit

struct VenuesVIPEventDataSet {
    var imgEventCover: UIImage?
    var lblPerformerName: String? = ""
    var imgBrandLogo: UIImage?
    var isLive: Bool? = false
    var isFavourite: Bool? = false
    var lblEventFees: String? = ""
    var lblEventWaitingTime: String? = ""
    var lblEventClosingTime: String? = ""
}

class VenuesAndVIP: BaseController {

    @IBOutlet weak var tableView: UITableView!
    
    var arrayHeaders = [HeaderOption(label: Strings.HOT_VENUES.text, icon: UIImage(named: "EventsTabSelected"))]
    
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
extension VenuesAndVIP {
    private func setUI(){
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        } else {
            // Fallback on earlier versions
        }
        self.registerCells()
    }
    private func registerCells(){
        self.tableView.register(UINib(nibName: "HotVenuesTVC", bundle: nil), forCellReuseIdentifier: "HotVenuesTVC")
        self.tableView.register(UINib(nibName: "VenueTVC", bundle: nil), forCellReuseIdentifier: "VenueTVC")
    }
}
extension VenuesAndVIP: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.arrayHeaders.count + 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return 3
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HotVenuesTVC", for: indexPath) as! HotVenuesTVC
            cell.delegate = self
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "VenueTVC", for: indexPath) as! VenueTVC
            if indexPath.row == 2 {
                let data = self.arrayRemainingHotVenueEvents[indexPath.row]
                cell.setData(data: data)
                cell.setData(seeAll: true)
                cell.btnSeeAll.addTarget(self, action: #selector(self.onBtnSeeAll(_:)), for: .touchUpInside)
            }
            else {
                let data = self.arrayRemainingHotVenueEvents[indexPath.row]
                cell.setData(data: data)
                cell.setData(seeAll: false)
            }
            return cell
        }
    }
    @objc func onBtnSeeAll(_ sender: UIButton) {
        self.pushToAllVenues()
    }
}
extension VenuesAndVIP: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            let height = tableView.frame.height * 0.575
            return height
        default:
            return UITableView.automaticDimension
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 52.0
        }
        else {
            return 0.0
        }
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let header = HeaderView.instanceFromNib() as! HeaderView
            let data = self.arrayHeaders[section]
            header.setData(data: data)
            return header
        }
        else {
            return nil
        }
    }
}
extension VenuesAndVIP: VenueDetailProtocol {
    func didSelect() {
        Utility.main.topViewController()?.navigationController?.pushViewController(VenueDetails(), animated: true)
    }
}
