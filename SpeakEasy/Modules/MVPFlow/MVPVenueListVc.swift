//
//  MVPVenueListVc.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

enum VenueStatus: String {
    case open = "OPEN"
    case close = "CLOSE"
}

import UIKit
import CoreLocation

final class MVPVenueListVc: UIViewController {

    @IBOutlet weak var cityNameLbl: UILabelDeviceClass!
    @IBOutlet weak var venueListTableView: UITableView!
        
    private var openVenueList = [ClipVenue]()
    private var closeVenueList = [ClipVenue]()
    private var openFrom = 0
    private var venueListDelegate = MVPPresenter()
    private var openHasMore = false
    private var closeFrom = 0
    private var closeHasMore = false
    private var refresh = UIRefreshControl()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        venueListTableView.register(UINib(nibName: "venueTableCell", bundle: nil), forCellReuseIdentifier: "venueTableCell")
        fetchAllOpenVenueForMVP()
        fetchAllCloseVenueForMVP()
        RemoteConfigHelper.shared.getRemoteConfigValues(showSoftUpdate: true)
        // foreground event
        NotificationCenter.default.addObserver(self, selector: #selector(checkForceUpdate), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // add these notification to prevent freeze on long Home button press and back
        NotificationCenter.default.addObserver(self, selector: #selector(checkForceUpdate), name: UIApplication.didBecomeActiveNotification, object: nil)
        refresh.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        venueListTableView.addSubview(refresh)
        WebSocketWrapper.shared.delegate.append(self)
        venueListTableView.setupPadding()
        cityNameLbl.text = UserDefault.shared.localCity
        
        if UserDefault.shared.defaultCitySelected == false {
            self.locationManager.requestWhenInUseAuthorization()
            DispatchQueue.global().async {
                if CLLocationManager.locationServicesEnabled() {
                    self.locationManager.requestAlwaysAuthorization()
                    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                    self.locationManager.startUpdatingLocation()
                }
            }
        }
    }
    
    @objc private func checkForceUpdate() {
        RemoteConfigHelper.shared.getRemoteConfigValues()
    }
    
    @objc private func refresh(_ sender: AnyObject) {
        openFrom = 0
        closeFrom = 0
        openHasMore = false
        closeHasMore = false
        fetchAllOpenVenueForMVP()
        fetchAllCloseVenueForMVP()
    }
    
    private func refreshData(withLoader: Bool = true) {
        openFrom = 0
        closeFrom = 0
        openHasMore = false
        closeHasMore = false
        fetchAllOpenVenueForMVP(withLoader: withLoader)
        fetchAllCloseVenueForMVP(withLoader: withLoader)
    }
    
    @IBAction func onClickCityName(_ sender: Any) {
        Navigate.to.mvpCitySelection(self)
    }
    
    private func fetchAllOpenVenueForMVP(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        venueListDelegate.getVenueListForMVP(from: openFrom,status: VenueStatus.open.rawValue) { [weak self] isSuccess, errMsg, openVenueList, hasMore in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                if self.openFrom == 0 {
                    self.openVenueList.removeAll()
                }
                for venue in openVenueList {
                    self.openVenueList.append(venue)
                }
                if hasMore {
                    self.openFrom = self.openVenueList.count
                }
                self.openHasMore = hasMore
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
    
    private func fetchAllCloseVenueForMVP(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        venueListDelegate.getVenueListForMVP(from: closeFrom,status: VenueStatus.close.rawValue) { [weak self] isSuccess, errMsg, closeVenueList, hasMore in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                if self.closeFrom == 0 {
                    self.closeVenueList.removeAll()
                }
                for venue in closeVenueList {
                    self.closeVenueList.append(venue)
                }
                if hasMore {
                    self.closeFrom = self.closeVenueList.count
                }
                self.closeHasMore = hasMore
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
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
           return openVenueList.count
        } else {
           return closeVenueList.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "venueTableCell", for: indexPath) as! venueTableCell
        var data: ClipVenue?
        if indexPath.section == 0 {
            data = openVenueList[indexPath.row]
            cell.coverLbl.isHidden = false
            cell.updatedAtLbl.isHidden = false
        } else {
            data = closeVenueList[indexPath.row]
            cell.coverLbl.isHidden = true
            cell.updatedAtLbl.isHidden = true
        }
        if let data = data {
            cell.setData(data: data)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            Navigate.to.MVPVenueDetailViewController(self, venueId: openVenueList[indexPath.row].id, venueUniqueId: openVenueList[indexPath.row].uniqueId)
        } else {
            Navigate.to.MVPVenueDetailViewController(self, venueId: closeVenueList[indexPath.row].id, venueUniqueId: closeVenueList[indexPath.row].uniqueId)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == openVenueList.count - 1 {
                if openHasMore {
                    fetchAllOpenVenueForMVP()
                }
            }
        } else {
            if indexPath.row == closeVenueList.count - 1 {
                if closeHasMore {
                    fetchAllCloseVenueForMVP()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = MVPVenueTypeHeaderView.instanceFromNib() as? MVPVenueTypeHeaderView
        if section == 0 {
            header?.openCloseLbl.text = "Open Tonight"
            header?.detailLbl.text = "Venues that are currently open in your city."
        } else {
            header?.openCloseLbl.text = "Venues in \(UserDefault.shared.localCity)"
            header?.detailLbl.text = "Venues in your city."
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if openVenueList.count == 0 {
                return 0
            } else {
                return 60
            }
        } else {
            if closeVenueList.count == 0 {
                return 0
            } else {
                return 60
            }
        }
    }
}

extension MVPVenueListVc: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        refreshData(withLoader: false)
    }
}

extension MVPVenueListVc: CitySelectionDelegate {
    func citySelected(city: String) {
        refreshData()
        cityNameLbl.text = UserDefault.shared.localCity
    }
}

extension MVPVenueListVc: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if UserDefault.shared.defaultCitySelected == true { return }
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        let city = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude).getCity { cityName in
            if cityName == UserDefault.shared.localCity {
                return
            }
            self.locationManager.delegate = nil
            self.fetchCityList(userCity: cityName)
        }
    }
    
    private func fetchCityList(userCity: String) {
        self.venueListDelegate.mvpCityListAPi() { cityList, isSuccess in
            if isSuccess {
                if let city = cityList.first(where: { $0.value == userCity }) {
                    UserDefault.shared.localCity = city.value
                    self.refreshData()
                    self.cityNameLbl.text = UserDefault.shared.localCity
                }
            } else {
                Alert.showAlertSheet(style: .alert, title: "city Not Found", message: "")
            }
        }
    }
}
