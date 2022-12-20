//
//  SetLocationViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/12/22.
//

import UIKit
import CoreLocation

final class SetLocationViewController: UIViewController {
    
    let locationManager = CLLocationManager()


    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        

    }
    
    @IBAction func onClickuseCurrentlocation(_ sender: Any) {
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
//            locationManager.delegate = self
            self.locationManager.requestAlwaysAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func onClickSelectCity(_ sender: Any) {
        Navigate.to.selectCityVc(self)
    }
    
}

extension SetLocationViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        let city = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude).getCity { cityName in
            print("\(cityName)")
//            Navigate.to.selectCityVc(self)
        }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
}
