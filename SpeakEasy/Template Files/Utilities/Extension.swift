//
//  Extension.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/12/22.
//

import Foundation
import CoreLocation


extension CLLocation {
  func getCity(completion: @escaping (String) -> Void) {
    let locationManager = CLLocationManager()
    locationManager.getPlace(for: self) { placeMark in
      guard let placeMark = placeMark else {
          completion("")
        return
      }
      if let town = placeMark.locality, let country = placeMark.country, let state = placeMark.administrativeArea {
        completion("\(town), \(state), \(country)")
      } else {
        completion("")
      }
    }
  }
}

extension CLLocationManager {
  func getPlace(for location: CLLocation,
         completion: @escaping (CLPlacemark?) -> Void) {
    let geocoder = CLGeocoder()
    geocoder.reverseGeocodeLocation(location) { placemarks, error in
      guard error == nil else {
        print("*** Error in \(#function): \(error?.localizedDescription ?? "")")
        completion(nil)
        return
      }
      guard let placemark = placemarks?.first else {
        print("*** Error in \(#function): placemark is nil")
        completion(nil)
        return
      }
      completion(placemark)
    }
  }
}

extension String {
    var isValidEmail: Bool {
        let regularExpressionForEmail = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let testEmail = NSPredicate(format:"SELF MATCHES %@", regularExpressionForEmail)
        return testEmail.evaluate(with: self)
    }
}

extension Int {
    // For reducing value as per scale down value
    var scaledValue: Int {
        self / FixValue.scale
    }
}
