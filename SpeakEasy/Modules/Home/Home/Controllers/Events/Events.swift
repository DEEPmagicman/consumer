//
//  Events.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit

struct TopEventDataSet {
    var imgEventCover: UIImage?
    var lblPerformerName: String? = ""
    var lblVenueName: String? = ""
    var imgBrandLogo: UIImage?
    var lblEventDate: String? = ""
    var currentLiveEventFires: UIStackView?
    var isLive: Bool? = false
}

class Events: BaseController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var arrayHeaders = [HeaderOption(label: Strings.TOP_EVENTS.text, icon: UIImage(named: "EventsTabSelected")),
                        HeaderOption(label: Strings.FEATURED_EVENTS.text, icon: nil),
                        HeaderOption(label: Strings.UPCOMING.text, icon: nil),
                        HeaderOption(label: Strings.GENERAL_ADMISSION.text, icon: nil)]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        // Do any additional setup after loading the view.
    }
}
extension Events {
    private func setUI(){
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        } else {
            // Fallback on earlier versions
        }
        self.registerCells()
    }
    private func registerCells(){
        self.tableView.register(UINib(nibName: "TopEventsTVC", bundle: nil), forCellReuseIdentifier: "TopEventsTVC")
        self.tableView.register(UINib(nibName: "AllEventsTVC", bundle: nil), forCellReuseIdentifier: "AllEventsTVC")
    }
}
extension Events: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.arrayHeaders.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopEventsTVC", for: indexPath) as! TopEventsTVC
            cell.selectedTopEvent = { index in
                Utility.main.topViewController()?.navigationController?.pushViewController(EventBookingDetails(), animated: true)
            }
            return cell
        default:
            if indexPath.section == self.arrayHeaders.count - 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AllEventsTVC", for: indexPath) as! AllEventsTVC
                cell.setData(seeAll: true)
                cell.tag = indexPath.section - 1
                cell.btnSeeAll.addTarget(self, action: #selector(self.onBtnSeeAll(_:)), for: .touchUpInside)
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AllEventsTVC", for: indexPath) as! AllEventsTVC
                cell.setData(seeAll: false)
                cell.tag = indexPath.section - 1
                return cell
            }
        }
    }
    @objc func onBtnSeeAll(_ sender: UIButton) {
        self.pushToAllEvents()
    }
    
}
extension Events: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            let height = tableView.frame.height * 0.5
            return height
        default:
            let height = tableView.frame.height * 0.34
            
            if indexPath.section == self.arrayHeaders.count - 1 {
                return height + 60.0
            }
            else {
                return height
            }
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52.0
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = HeaderView.instanceFromNib() as! HeaderView
        let data = self.arrayHeaders[section]
        header.setData(data: data)
        return header
    }
}
