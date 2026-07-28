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
    private let contentStack = UIStackView()
    private let buttonStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPermissionUI()
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

    private func setupPermissionUI() {
        view.subviews.forEach { $0.isHidden = true }
        view.backgroundColor = AppColor.primaryBlackColor
        view.applyScreenBgGradient(direction: .topToBottom)

        let iconView = UIImageView(image: UIImage(named: "locationPermisionIcon"))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Find the best\nevents around you"
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.font = Constant.Font.geistMedium(size: 32)

        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.text = "Stay updated on the events, partners, reservations, and live experiences happening around you."
        bodyLabel.textAlignment = .center
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.58)
        bodyLabel.numberOfLines = 0
        bodyLabel.font = Constant.Font.geistRegular(size: 13)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 22
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(bodyLabel)
        view.addSubview(contentStack)

        let enableButton = makePermissionButton(
            title: "Enable location",
            titleColor: .black,
            backgroundColor: .white,
            action: #selector(onEnableLocationPressed)
        )

        let notNowButton = makePermissionButton(
            title: "Not now",
            titleColor: .white,
            backgroundColor: UIColor.white.withAlphaComponent(0.10),
            action: #selector(onNotNowPressed)
        )

        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .vertical
        buttonStack.spacing = 14
        buttonStack.addArrangedSubview(enableButton)
        buttonStack.addArrangedSubview(notNowButton)
        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 65),
            iconView.heightAnchor.constraint(equalToConstant: 65),

            contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -52),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),

            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: contentStack.widthAnchor),
            bodyLabel.widthAnchor.constraint(lessThanOrEqualTo: contentStack.widthAnchor),

            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            enableButton.heightAnchor.constraint(equalToConstant: 56),
            notNowButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func makePermissionButton(
        title: String,
        titleColor: UIColor,
        backgroundColor: UIColor,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = Constant.Font.geistMedium(size: 17)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 28
        button.layer.cornerCurve = .continuous
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func onEnableLocationPressed() {
        requestCurrentLocation()
    }

    @objc private func onNotNowPressed() {
        Navigate.to.selectCityVc(self)
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
