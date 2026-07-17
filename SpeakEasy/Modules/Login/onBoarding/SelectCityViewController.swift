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
    var userLocationCoordinate: CLLocationCoordinate2D?
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
                self.selectCityTableView.reloadData()
                self.resolveDetectedCityIfNeeded(cityList)
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
            locationManager.delegate = self

            guard CLLocationManager.locationServicesEnabled() else {
                showManualCitySelectionMessage()
                return
            }

            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()

            case .authorizedAlways, .authorizedWhenInUse:
                startUpdatingCurrentLocation()

            case .denied, .restricted:
                showManualCitySelectionMessage()

            @unknown default:
                showManualCitySelectionMessage()
            }
        }
    }
    
     func onClickContinue() {
         Loader.show()
        presenter.editUserProfileApi(city: self.selectedCity, isProfileCompleted: true) { [weak self] isSuccess, errorMsg  in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                UserDefault.shared.user?.city = self.selectedCity
                UserDefault.shared.setPrimaryCity(self.selectedCity)
                UserDefault.shared.filterCity = nil
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

    private func resolveDetectedCityIfNeeded(_ cityList: [MVPCity]) {
        let detectedCity = userLocationCity
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !detectedCity.isEmpty else { return }

        if let exactCity = cityList.first(where: {
            $0.value.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(detectedCity) == .orderedSame
        }) {
            selectedCity = exactCity.value
            onClickContinue()
            return
        }

        guard let coordinate = userLocationCoordinate else {
            showManualCitySelectionMessage()
            return
        }

        let userLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        selectNearestSupportedCity(
            to: userLocation,
            from: cityList
        ) { [weak self] nearestCity in
            guard let self else { return }

            if let nearestCity {
                self.selectedCity = nearestCity.value
                self.onClickContinue()
            } else {
                self.showManualCitySelectionMessage()
            }
        }
    }

    private func showManualCitySelectionMessage() {
        selectCityInfoLbl.text = "Select your primary location manually."
    }

    private func startUpdatingCurrentLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }

    private func selectNearestSupportedCity(
        to userLocation: CLLocation,
        from cityList: [MVPCity],
        completion: @escaping (MVPCity?) -> Void
    ) {
        guard !cityList.isEmpty else {
            completion(nil)
            return
        }

        let geocoder = CLGeocoder()
        var index = 0
        var nearestCity: MVPCity?
        var nearestDistance = CLLocationDistance.greatestFiniteMagnitude

        func geocodeNextCity() {
            guard index < cityList.count else {
                completion(nearestCity)
                return
            }

            let city = cityList[index]
            index += 1

            geocoder.geocodeAddressString(city.value) { placemarks, _ in
                if let location = placemarks?.first?.location {
                    let distance = userLocation.distance(from: location)
                    if distance < nearestDistance {
                        nearestDistance = distance
                        nearestCity = city
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    geocodeNextCity()
                }
            }
        }

        geocodeNextCity()
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
    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        switch status {
        case .denied, .restricted:
            showManualCitySelectionMessage()

        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingCurrentLocation()

        case .notDetermined:
            break

        @unknown default:
            showManualCitySelectionMessage()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        let city = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude).getCity { [weak self] cityName in
            guard let self = self else { return }
            self.locationManager.delegate = nil
            self.locationManager.stopUpdatingLocation()
            self.userLocationCity = cityName
            self.userLocationCoordinate = locValue
            self.fetchCityList()
        }
    }
}
