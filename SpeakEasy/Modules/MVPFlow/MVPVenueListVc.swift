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
        venueListTableView.setupPadding()
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
    
    @IBAction func onClickCityName(_ sender: Any) {
        Navigate.to.mvpCitySelection(self)
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
            if withLoader == false && self.navigationController?.viewControllers.last is MVPVenueListVc {
                Alert.showToast("Venue detail updated")
            }
            Loader.hide()
        }
    }
    
}

extension MVPVenueListVc: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
           return venueList.count
        } else {
           return venueList.count
        }
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = MVPVenueTypeHeaderView.instanceFromNib() as? MVPVenueTypeHeaderView
        if section == 0 {
            header?.openCloseLbl.text = "Venues in Chicago"
            header?.detailLbl.text = "Venues in your city."
        } else {
            header?.openCloseLbl.text = "Open Tonight"
            header?.detailLbl.text = "Venues that are currently open in your city."
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
}

extension MVPVenueListVc: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        from = 0
        hasMore = false
        venueList.removeAll()
        venueListTableView.reloadData()
        self.fetchAllVenueForMVP(withLoader: false)
    }
}

extension MVPVenueListVc: CitySelectionDelegate {
    func citySelected(city: String) {
        //TO DO: refresh screen(city vise)
        print("refresh")
    }
}
