//
//  HeatMap.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 29/08/2022.
//

import UIKit
import CoreLocation
import GoogleMaps

class HeatMap: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
   
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (Constants.localizedCity == "Chicago") {
            self.setChicagoLocation()
        } else {
            self.setClevelandLocation()
        }
    }

}
extension HeatMap {
    private func setChicagoLocation(){
        let latitude = 41.8911987
        let longitude = -87.6267177
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        self.mapView.animate(toLocation: location)
        self.mapView.animate(toZoom: 12)
    }
    private func setClevelandLocation(){
        let latitude = 41.4993
        let longitude = -81.6944
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        self.mapView.animate(toLocation: location)
        self.mapView.animate(toZoom: 12)
    }
}
