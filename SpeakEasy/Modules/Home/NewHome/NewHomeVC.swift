//
//  NewHomeVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 24/02/23.
//

import UIKit

class NewHomeVC: UIViewController {

    @IBOutlet weak var eventListTableView: UITableView!
    @IBOutlet weak var cityNameLbl: UILabelDeviceClass!
    
    private var venueList = [ClipVenue]()
    private var from = 0
    private var venueListDelegate = MVPPresenter()
    private var hasMore = false
    private var refresh = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        eventListTableView.register(UINib(nibName: "venueTableCell", bundle: nil), forCellReuseIdentifier: "venueTableCell")
    }

    @IBAction func onClickCityName(_ sender: Any) {
        Navigate.to.homeCitySelection(self)
    }
}

extension NewHomeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        venueList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "venueTableCell", for: indexPath) as! venueTableCell
        let data = venueList[indexPath.row]
        cell.setData(data: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Navigate.to.MVPVenueDetailViewController(self,venueId: self.venueList[indexPath.row].uniqueId)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == venueList.count - 1 {
            if hasMore {
//                fetchAllVenueForMVP()
            }
        }
    }
}
