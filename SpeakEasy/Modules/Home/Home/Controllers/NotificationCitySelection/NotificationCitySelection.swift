//
//  NotificationCitySelection.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/30/22.
//

import UIKit

class NotificationCitySelection: UIViewController {

    @IBOutlet weak var tableViewReward: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell()
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func registerCell() {
        self.tableViewReward.register(UINib(nibName: "NotificationCitySelectionTVC", bundle: nil), forCellReuseIdentifier: "NotificationCitySelectionTVC")
    }
}



extension NotificationCitySelection: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableViewReward.dequeueReusableCell(withIdentifier: "NotificationCitySelectionTVC", for: indexPath) as? NotificationCitySelectionTVC else { return UITableViewCell() }
//        cell.setDat(data: true)
        return cell
    }
    
}

extension NotificationCitySelection: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = NotificationCitySelectionHeaderView.instanceFromNib() as! NotificationCitySelectionHeaderView
        header.setData(section: section)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
}
