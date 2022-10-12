//
//  NotificationVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/30/22.
//

import UIKit
struct CitySelection {
        
        var name : String
        var img : String
    }
    
class NotificationVC: UIViewController {

    var arrCitySelection = [CitySelection(name: "New York, NY", img: "New York, NY"),
                            CitySelection(name: "Miami, FL", img: "Miami, FL"),
                            CitySelection(name: "Las Vegas, NV", img: "Las Vegas, NV"),
                            CitySelection(name: "Los Angeles, CA", img: "Los Angeles, CA"),
                            CitySelection(name: "Boston, MA", img: "Boston, MA"),
                            CitySelection(name: "San Francisco, CA", img: "San Francisco, CA"),
                            CitySelection(name: "Atlanta, GA", img: "Atlanta, GA"),
                            CitySelection(name: "Tampa, FL", img: "Tampa, FL"),]
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell()
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func registerCell() {
        self.tableView.register(UINib(nibName: "NotificationTVC", bundle: nil), forCellReuseIdentifier: "NotificationTVC")
    }
}
//MARK: - UITableViewDelegate
extension NotificationVC: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = self.tableView else {return}
        
        let visibleCells = tableView.visibleCells

        if visibleCells.count == 0 {
            return
        }

        guard let topCell = visibleCells.first else {
            return
        }

        for cell in visibleCells {
            cell.contentView.alpha = 1.0
        }

        let cellHeight = topCell.frame.size.height - 1
        let tableViewTopPosition = tableView.frame.origin.y
        
        let topCellPositionInTableView = tableView.rectForRow(at: tableView.indexPath(for: topCell)!)

        let topCellPosition = tableView.convert(topCellPositionInTableView, to: tableView.superview).origin.y

        let modifier: CGFloat = 2.5
        let topCellOpacity = 1.5 - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier

        topCell.contentView.alpha = topCellOpacity
    }
}
//MARK: - UITableViewDataSource
extension NotificationVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrCitySelection.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationTVC", for: indexPath) as? NotificationTVC else { return UITableViewCell() }
        let data = self.arrCitySelection[indexPath.row]
        cell.setData(data: data)
        return cell
    }
}
