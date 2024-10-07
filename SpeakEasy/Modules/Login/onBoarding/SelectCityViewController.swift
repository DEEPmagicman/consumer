//
//  SelectCityViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 12/12/22.
//

import UIKit
import CoreLocation

final class SelectCityViewController: UIViewController {

    @IBOutlet weak var selectCityInfoLbl: UILabel!
    @IBOutlet weak var selectCityTableView: UITableView!
    
    private let locationManager = CLLocationManager()
    var userLocationCity = ""
    private var arrCityList = [MVPCity]()
    private var displayList = [MVPCity]()
    private var selectedCity = ""
    private var presenter = OnBoardingPresenter()
    private var mvpPresenter = MVPPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectCityTableView.register(UINib(nibName: "CitySelectionTableCell", bundle: nil), forCellReuseIdentifier: "CitySelectionTableCell")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickEnableLocation(_:)))
        selectCityInfoLbl.addGestureRecognizer(tapGesture)
        selectCityInfoLbl.isUserInteractionEnabled = true
        
        fetchCityList()
    }
    
    private func fetchCityList() {
        mvpPresenter.mvpCityListAPi { [weak self] cityList, isSuccess, errMsg in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                self.arrCityList = cityList
                self.displayList = cityList
                if self.userLocationCity != "", cityList.contains(where: { list in
                    list.value == self.userLocationCity
                }) {
                    self.selectedCity = self.userLocationCity
                    self.onClickContinue()
                }
                self.selectCityTableView.reloadData()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
    
    @objc private func onClickEnableLocation(_ sender: UITapGestureRecognizer) {
        guard let range = selectCityInfoLbl.text?.range(of: Constant.String.enableLocationServices)?.nsRange else {
            return
        }
        if sender.didTapAttributedTextInLabel(label: selectCityInfoLbl, inRange: range) {
            locationManager.requestWhenInUseAuthorization()
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.requestAlwaysAuthorization()
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.startUpdatingLocation()
            }
        }
    }
    
     func onClickContinue() {
        presenter.editUserProfileApi(city: self.selectedCity, isProfileCompleted: true) { [weak self] isSuccess,errorMsg  in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                UserDefault.shared.user?.city = self.selectedCity
                UserDefault.shared.localCity = self.selectedCity
                UserDefault.shared.isLoggedIn = true
                UserDefault.shared.user?.isProfileCompleted = true
                AppDelegate.shared.changeRootViewController()
            } else {
                if errorMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            Loader.hide()
        }
    }
}

extension SelectCityViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CitySelectionTableCell", for: indexPath) as? CitySelectionTableCell
        let data = displayList[indexPath.row]
        cell?.lblCity.text = data.value
        cell?.imgCity.isHidden = true
        if data.value == selectedCity {
            cell?.contentView.backgroundColor = Constant.Color.customGray.withAlphaComponent(0.5)
        } else {
            cell?.containtView.backgroundColor = .clear
            cell?.contentView.backgroundColor = .clear
        }
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCity = displayList[indexPath.row].value
        selectCityTableView.reloadData()
        onClickContinue()
//        continueBtn.isUserInteractionEnabled = true
//        continueBtn.alpha = 1
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if indexPath.row == displayList.count - 1 {
//            if self.hasMore {
//                self.fetchCityList()
//            }
//        }
//    }
}

extension SelectCityViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        let city = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude).getCity { [weak self] cityName in
            guard let self = self else { return }
            self.locationManager.delegate = nil
            self.locationManager.stopUpdatingHeading()
            self.userLocationCity = cityName
            self.fetchCityList()
        }
    }
}
