//
//  VIPTableBookingCalendar.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/5/22.
//

import UIKit

class VIPTableBookingCalendar: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var arrayHeaders = [HeaderOption(label: "Associated Event", icon: nil)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onBtnTableAvailable(_ sender: UIButtonDeviceClass) {
        self.navigationController?.pushViewController(TableSelection(), animated: true)
    }
}
//MARK: - Helper Methods
extension VIPTableBookingCalendar {
    private func setUI(){
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        } else {
            // Fallback on earlier versions
        }
        self.registerCells()
    }
    private func registerCells(){
        self.tableView.register(UINib(nibName: "VIPTableBookingCalenderTVC", bundle: nil), forCellReuseIdentifier: "VIPTableBookingCalenderTVC")
        self.tableView.register(UINib(nibName: "BookingCalenderTVC", bundle: nil), forCellReuseIdentifier: "BookingCalenderTVC")
    }
}
//MARK: - UITableViewDataSource
extension VIPTableBookingCalendar: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2//self.arrayHeaders.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookingCalenderTVC", for: indexPath) as! BookingCalenderTVC
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "VIPTableBookingCalenderTVC", for: indexPath) as! VIPTableBookingCalenderTVC
            cell.setTableSelectionData(seeAll: false)
            return cell
        }
    }
}
//MARK: - UITableViewDelegate
extension VIPTableBookingCalendar: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            let height = tableView.frame.height * 0.6
            return height
        default:
            let height = tableView.frame.height * 0.38
            return height
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 50.0
        }else {
            return 0.0
        }
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let header = VIPTableBookingHeaderView.instanceFromNib() as! VIPTableBookingHeaderView
            let data = self.arrayHeaders[section - 1]
            header.setData(data: data)
            return header
        }else{
            return nil
        }
    }
}
