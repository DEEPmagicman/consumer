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

    @IBOutlet weak var cityNameLbl: UILabel!
    @IBOutlet weak var venueListTableView: UITableView!
    @IBOutlet weak var zeroCaseView: UIView!
        
    private var openVenueList = [ClipVenue]()
    private var closeVenueList = [ClipVenue]()
    private var openFrom = 0
    private var presenter = MVPPresenter()
    private var openHasMore = false
    private var closeFrom = 0
    private var closeHasMore = false
    private var refresh = UIRefreshControl()
    let locationManager = CLLocationManager()
    @IBOutlet weak var cityLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        venueListTableView.register(UINib(nibName: "VenueTableCell", bundle: nil), forCellReuseIdentifier: "VenueTableCell")
        fetchAllOpenVenueForMVP()
//        fetchAllCloseVenueForMVP()
        RemoteConfigHelper.shared.getRemoteConfigValues(showSoftUpdate: true)
        // foreground event
        NotificationCenter.default.addObserver(self, selector: #selector(checkForceUpdate), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // add these notification to prevent freeze on long Home button press and back
        NotificationCenter.default.addObserver(self, selector: #selector(checkForceUpdate), name: UIApplication.didBecomeActiveNotification, object: nil)
        refresh.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        venueListTableView.addSubview(refresh)
        WebSocketWrapper.shared.addDelegate(self) 
        venueListTableView.setupPadding()
        cityNameLbl.text = UserDefault.shared.localCity.uppercased()
        cityLbl.text = UserDefault.shared.localCity.uppercased()
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UserDefault.shared.selectedVenueId = nil
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
    }
    
    private func refreshData(withLoader: Bool = true) {
        openFrom = 0
        closeFrom = 0
        openHasMore = false
        closeHasMore = false
        fetchAllOpenVenueForMVP(withLoader: withLoader)
    }
    
    private func checkZeroViewCase() {
        zeroCaseView.isHidden = !(openVenueList.count == 0 && closeVenueList.count == 0)
    }
    
    @IBAction func onClickCityName(_ sender: Any) {
        Navigate.to.mvpCitySelection(self)
    }
    
    private func fetchAllOpenVenueForMVP(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        presenter.getVenueListForMVP(from: openFrom, status: VenueStatus.open.rawValue, city: nil) { [weak self] isSuccess, errMsg, openVenueList, hasMore in
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
                if !self.openHasMore {
                    self.fetchAllCloseVenueForMVP()
                }
                self.venueListTableView.reloadData()
                self.refresh.endRefreshing()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
            self.checkZeroViewCase()
            #if DEBUG
            if withLoader == false && self.navigationController?.viewControllers.last is MVPVenueListVc {
                Alert.showToast("Venue detail updated")
            }
            #endif
            Loader.hide()
        }
    }
    
    private func fetchAllCloseVenueForMVP(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        presenter.getVenueListForMVP(from: closeFrom, status: VenueStatus.close.rawValue, city: nil) { [weak self] isSuccess, errMsg, closeVenueList, hasMore in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                if self.closeFrom == 0 {
                    self.closeVenueList.removeAll()
                }
                for venue in closeVenueList {
                    self.openVenueList.append(venue)
                    self.closeVenueList.append(venue)
                }
                if hasMore {
                    self.closeFrom = self.closeVenueList.count
                }
                self.closeHasMore = hasMore
                self.venueListTableView.reloadData()
                self.refresh.endRefreshing()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
            self.checkZeroViewCase()
            #if DEBUG
            if withLoader == false && self.navigationController?.viewControllers.last is MVPVenueListVc {
                Alert.showToast("Venue detail updated")
            }
            #endif
            Loader.hide()
        }
    }
}

extension MVPVenueListVc: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return openVenueList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VenueTableCell", for: indexPath) as! VenueTableCell
        var data: ClipVenue?
        data = openVenueList[indexPath.row]
        if let data = data {
            cell.setData(data: data)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if openVenueList[indexPath.row].isDiscoveryClickable ?? true {
            Navigate.to.MVPVenueDetailViewController(self, venueId: openVenueList[indexPath.row].id, venueUniqueId: openVenueList[indexPath.row].uniqueId, venueTimeZone: openVenueList[indexPath.row].timezone ?? "")
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == openVenueList.count - 1 {
            if openHasMore {
                fetchAllOpenVenueForMVP()
            } else if closeHasMore {
                fetchAllCloseVenueForMVP()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return openVenueList.count == 0 ? 0 : 60
    }
}

extension MVPVenueListVc: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool) {
        refreshData(withLoader: false)
    }
}

extension MVPVenueListVc: CitySelectionDelegate {
    func citySelected(city: String) {
        refreshData()
        cityNameLbl.text = UserDefault.shared.localCity.uppercased()
        cityLbl.text = UserDefault.shared.localCity.uppercased()
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
        presenter.mvpCityListAPi { cityList, isSuccess, errMsg in
            if isSuccess {
                if let city = cityList.first(where: { $0.value == userCity }) {
                    UserDefault.shared.setPrimaryCity(city.value)
                    self.refreshData()
                    self.cityNameLbl.text = UserDefault.shared.localCity.uppercased()
                    self.cityLbl.text = UserDefault.shared.localCity.uppercased()
                }
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
}
