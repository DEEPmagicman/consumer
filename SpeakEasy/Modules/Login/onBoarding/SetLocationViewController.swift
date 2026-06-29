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

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onClickuseCurrentlocation(_ sender: Any) {
        locationManager.delegate = self

        guard CLLocationManager.locationServicesEnabled() else {
            showLocationServicesAlert()
            return
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()

        case .denied, .restricted:
            showLocationPermissionAlert()

        @unknown default:
            break
        }
    }
    
    @IBAction func onClickSelectCity(_ sender: Any) {
        Navigate.to.selectCityVc(self)
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "Location Permission Required",
            message: "Please enable Location permission from Settings to use your current location.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        })

        present(alert, animated: true)
    }
    
    private func showLocationServicesAlert() {
        let alert = UIAlertController(
            title: "Location Services Disabled",
            message: "Please enable Location Services from Settings.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension SetLocationViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        manager.stopUpdatingLocation()
        manager.delegate = nil
        
        location.getCity { [weak self] cityName in
            guard let self = self else { return }
            Navigate.to.selectCityVc(self, userLocationCity: cityName)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.startUpdatingLocation()

        case .denied, .restricted:
            showLocationPermissionAlert()

        default:
            break
        }
    }
}
