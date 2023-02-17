//
//  MVPVenueListVc.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit

final class MVPVenueListVc: UIViewController {

    @IBOutlet weak var cityNameLbl: UILabelDeviceClass!
    @IBOutlet weak var venueListTableView: UITableView!
        
    private var venueList = [ClipVenue]()
    private var from = 0
    private var venueListDelegate = MVPPresenter()
    private var hasMore = false
    private var refresh = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        venueListTableView.register(UINib(nibName: "venueTableCell", bundle: nil), forCellReuseIdentifier: "venueTableCell")
        fetchAllVenueForMVP()
        
        refresh.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        venueListTableView.addSubview(refresh)
        WebSocketWrapper.shared.delegate.append(self)
    }
    
    @objc private func refresh(_ sender: AnyObject) {
        from = 0
        hasMore = false
        venueList.removeAll()
        fetchAllVenueForMVP()
    }
    
    @IBAction private func onClickSetting(_ sender: Any) {
        Navigate.to.MVPSettingVC(self)
    }
    
    private func fetchAllVenueForMVP(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        venueListDelegate.getVenueListForMVP(from: from) { [weak self] isSuccess, errMsg, venueList, hasMore in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                for venue in venueList {
                    self.venueList.append(venue)
                }
                if hasMore {
                    self.from = self.venueList.count
                }
                self.hasMore = hasMore
                self.venueListTableView.reloadData()
                self.refresh.endRefreshing()
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
                fetchAllVenueForMVP()
            }
        }
    }
}

extension MVPVenueListVc: webSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        from = 0
        hasMore = false
        venueList.removeAll()
        venueListTableView.reloadData()
        self.fetchAllVenueForMVP(withLoader: false)
    }
}
