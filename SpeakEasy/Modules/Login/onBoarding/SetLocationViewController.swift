//
//  SetLocationViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/12/22.
//

import UIKit
import CoreLocation

final class SetLocationViewController: UIViewController {
    
    private let locationManager = CLLocationManager()
    private var didRequestLocationOnAppear = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !didRequestLocationOnAppear else { return }
        didRequestLocationOnAppear = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.requestCurrentLocation()
        }
    }
    
    @IBAction func onClickuseCurrentlocation(_ sender: Any) {
        requestCurrentLocation()
    }

    @IBAction func onClickSelectCity(_ sender: Any) {
        Navigate.to.selectCityVc(self)
    }

    private func requestCurrentLocation() {
        locationManager.delegate = self

        guard CLLocationManager.locationServicesEnabled() else {
            Navigate.to.selectCityVc(self)
            return
        }

        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()

        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingCurrentLocation()

        case .denied, .restricted:
            Navigate.to.selectCityVc(self)

        @unknown default:
            Navigate.to.selectCityVc(self)
        }
    }
}

extension SetLocationViewController: CLLocationManagerDelegate {
    private func startUpdatingCurrentLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        switch status {
        case .denied, .restricted:
            Navigate.to.selectCityVc(self)

        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingCurrentLocation()

        case .notDetermined:
            break

        @unknown default:
            Navigate.to.selectCityVc(self)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        let city = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude).getCity { [weak self] cityName in
            guard let self = self else { return }
            self.locationManager.delegate = nil
            self.locationManager.stopUpdatingLocation()
            Navigate.to.selectCityVc(
                self,
                userLocationCity: cityName,
                userLocationCoordinate: locValue
            )
        }
    }
}
