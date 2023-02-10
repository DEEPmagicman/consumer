//
//  MVPVenueListVc.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit

class MVPVenueListVc: UIViewController {

    @IBOutlet weak var cityNameLbl: UILabelDeviceClass!
    @IBOutlet weak var venueListTableView: UITableView!
        
    var venueList = [ClipVenue]()
    var from = 0
    var venueListDelegate = MVPPresenter()
    var hasMore = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.venueListTableView.register(UINib(nibName: "venueTableCell", bundle: nil), forCellReuseIdentifier: "venueTableCell")
        fetchAllvenueForMvp()
    }
    
    @IBAction func onClickSetting(_ sender: Any) {
        Navigate.to.MVPSettingVC(self)
    }
    
    private func fetchAllvenueForMvp() {
        venueListDelegate.getVenueListForMvp(from: from) { isSuccess, errMsg, venueList, hasMore in
            if isSuccess {
                for venue in venueList {
                    self.venueList.append(venue)
                }
                if hasMore {
                    self.from = self.venueList.count
                    self.fetchAllvenueForMvp()
                }
                self.hasMore = hasMore
                self.venueListTableView.reloadData()
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            Loader.hide()
        }
    }
    
}

extension MVPVenueListVc: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.venueList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "venueTableCell", for: indexPath) as! venueTableCell
               let data = self.venueList[indexPath.row]
            cell.setData(data: data)
            return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Navigate.to.MVPVenueDetailViewController(self,venueId: self.venueList[indexPath.row].uniqueId)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == venueList.count - 1 {
            if self.hasMore {
                self.fetchAllvenueForMvp()
            }
        }
    }
}
