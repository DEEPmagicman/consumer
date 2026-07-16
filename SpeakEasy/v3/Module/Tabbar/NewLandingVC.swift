//
//  NewLandingVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//

import UIKit
import SDWebImage
import CoreLocation

final class NewLandingVC: UIViewController {

    private let bgView = UIView()

    private let profileTapButton = UIButton(type: .system)
    private let avatarContainer = UIView()
    private let imageView = UIImageView()
    private let firstNameLetter = UILabel()
    private let signInIconView = UIImageView()
    private let pageTitleLbl = UILabel()
    private let mapIconView = UIImageView()

    private let contentContainer = UIView()
    private let customTabBar = FloatingCustomTabBar()

    private lazy var discoverVC: DiscoverVC = {
        StoryboardAndXibManager.StoryBoard.discover.instantiateVC(DiscoverVC.self)
    }()

    private lazy var experiencesVC: PremiumExpVC = PremiumExpVC()

    private lazy var searchVC: PremiumSearchVC = PremiumSearchVC()
    
    private lazy var myOrdersVC: MyOrdersVC = MyOrdersVC()

    private lazy var tabs: [UIViewController] = [
        discoverVC,
        experiencesVC,
        myOrdersVC,
        searchVC
    ]

    private var selectedIndex = 0
    private var currentVC: UIViewController?
    private var systemTabVC: UITabBarController?
    private let locationManager = CLLocationManager()
    private let venueService = VenueService()
    private var didRunLocationBootstrap = false
    private var pendingLocationPurpose: LocationBootstrapPurpose?
    private weak var locationPromptVC: LocationPermissionPromptVC?

    override func viewDidLoad() {
        super.viewDidLoad()

       if AppDesign.useModernIOS26Design {
           setupSystemLanding()
       } else {
           setupCustomLanding()
       }

        setupUserData()
        observeProfileUpdate()
        observePremiumTabRequests()
        observeDiscoverTabRequests()
        locationManager.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        runLocationBootstrapIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        bgView.applyScreenBgGradient()
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        firstNameLetter.layer.cornerRadius = firstNameLetter.bounds.height / 2
        firstNameLetter.clipsToBounds = true
        avatarContainer.layer.cornerRadius = avatarContainer.bounds.height / 2
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - iOS 26 System Tab
    private func setupSystemLanding() {
        setupCommonBackground()
//        setupHeader()

        let tabVC = UITabBarController()
        systemTabVC = tabVC

        let discover = makeSystemNav(
            root: discoverVC,
            title: "Discover",
            image: UIImage(resource: .discoverIconV3)
        )

        let experiences = makeSystemNav(
            root: experiencesVC,
            title: "Premium",
            image: UIImage(resource: .experiencesIcon)
        )

        let orders = makeSystemNav(
            root: myOrdersVC,
            title: "Orders",
            image: UIImage(resource: .ordersIcon)
        )
        
        let search = makeSystemNav(
            root: searchVC,
            title: "Search",
            image: UIImage(resource: .searchIconV3)
        )

        tabVC.viewControllers = [discover, experiences, orders, search]
        tabVC.selectedIndex = 0
        if #available(iOS 26.0, *) {
            tabVC.delegate = self
        } else {
            // Fallback on earlier versions
        }
        
        let selectedColor = UIColor(hex: "#8CB7FF")
        let normalColor = UIColor(hex: "#D1D1D1")
        tabVC.tabBar.tintColor = selectedColor
        tabVC.tabBar.unselectedItemTintColor = normalColor

        addChild(tabVC)
        tabVC.view.backgroundColor = .clear
        tabVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabVC.view)

        NSLayoutConstraint.activate([
            tabVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            tabVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tabVC.didMove(toParent: self)
    }

//    @available(iOS 26.0, *)
    private func makeSystemNav(
        root: UIViewController,
        title: String,
        image: UIImage?
    ) -> UINavigationController {
        root.title = title

        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.isHidden = true
        nav.delegate = self
        
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: image,
            selectedImage: image
        )

        return nav
    }

    // MARK: - iOS 16/17/18 Custom Tab

    private func setupCustomLanding() {
        setupCommonBackground()
        setupCustomContent()
        setupCustomTabBar()
        selectTab(index: 0)
    }
    
    private func setupCommonBackground() {
        view.backgroundColor = AppColor.primaryBlackColor

        bgView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(bgView, at: 0)

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: view.topAnchor),
            bgView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCustomContent() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupCustomTabBar() {
        customTabBar.delegate = self
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTabBar)

        let isSmallDevice = UIScreen.main.bounds.width <= 375
        let tabHeight: CGFloat = isSmallDevice ? 56 : 64
        let sidePadding: CGFloat = isSmallDevice ? 14 : 24

        customTabBar.configure(items: [
            FloatingTabItem(title: "Discover", icon: UIImage(resource: .discoverIconV3)),
            FloatingTabItem(title: "Premium", icon: UIImage(resource: .experiencesIcon)),
            FloatingTabItem(title: "Orders", icon: UIImage(resource: .ordersIcon)),
            FloatingTabItem(title: "Search", icon: UIImage(resource: .searchIconV3))
        ])

        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sidePadding),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sidePadding),
            customTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -2),
            customTabBar.heightAnchor.constraint(equalToConstant: tabHeight)
        ])
    }

    private func selectTab(index: Int) {
        guard index >= 0, index < tabs.count else { return }
        guard selectedIndex != index || currentVC == nil else { return }

        let oldVC = currentVC
        let newVC = tabs[index]

        addChild(newVC)
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(newVC.view)

        NSLayoutConstraint.activate([
            newVC.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            newVC.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        newVC.view.alpha = 0
        newVC.view.transform = CGAffineTransform(translationX: index > selectedIndex ? 20 : -20, y: 0)

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            newVC.view.alpha = 1
            newVC.view.transform = .identity
            oldVC?.view.alpha = 0
            oldVC?.view.transform = CGAffineTransform(translationX: index > self.selectedIndex ? -20 : 20, y: 0)
        } completion: { _ in
            oldVC?.willMove(toParent: nil)
            oldVC?.view.removeFromSuperview()
            oldVC?.removeFromParent()
            newVC.didMove(toParent: self)
        }

        currentVC = newVC
        selectedIndex = index
        customTabBar.setSelected(index: index)
    }

    // MARK: - User

    private func observeProfileUpdate() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onProfileUpdated),
            name: .userProfileDidUpdate,
            object: nil
        )
    }

    private func observePremiumTabRequests() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onOpenPremiumTabRequest(_:)),
            name: .openPremiumTabFromDiscover,
            object: nil
        )
    }

    private func observeDiscoverTabRequests() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onOpenDiscoverTabRequest),
            name: .openDiscoverTab,
            object: nil
        )
    }

    @objc private func onProfileUpdated() {
        setupUserData()
    }

    @objc private func onOpenPremiumTabRequest(_ notification: Notification) {
        let city = notification.userInfo?["city"] as? String
        experiencesVC.applyCity(city)

        if let systemTabVC {
            systemTabVC.selectedIndex = 1
        } else {
            selectTab(index: 1)
        }
    }

    @objc private func onOpenDiscoverTabRequest() {
        showDiscoverTab()
    }

    func showDiscoverTab() {
        if let systemTabVC {
            systemTabVC.selectedIndex = 0
        } else {
            selectTab(index: 0)
        }
    }

    private func setupUserData() {
        guard let user = UserDefault.shared.user else {
            imageView.isHidden = true
            firstNameLetter.isHidden = true
            signInIconView.isHidden = false
            pageTitleLbl.text = "Sign in"
            return
        }

        let imageUrl = user.image.key
        let firstLetter = user.firstName.first ?? Character("P")

        signInIconView.isHidden = true
        pageTitleLbl.text = user.firstName.isEmpty ? "Profile" : user.firstName

        if !imageUrl.isEmpty {
            imageView.isHidden = false
            firstNameLetter.isHidden = true
            imageView.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(resource: .profileIcon)
            )
        } else {
            imageView.isHidden = false
            if let _ = user.firstName.first {
                imageView.image = UIImage(resource: .signInBgIcon)
                firstNameLetter.isHidden = false
            } else {
                imageView.image = UIImage(resource: .profileIcon)
                firstNameLetter.isHidden = true
            }
            firstNameLetter.text = String(firstLetter).uppercased()
        }
    }
    
    @objc private func onClickProfile() {
        AppHaptic.navigation()
        LoginRequiredCoordinator.perform(from: self) { [weak self] in
            guard let self else { return }
            Navigate.to.profileMenuVC(self)
        }
    }

    @objc private func onClickMap() {
        AppHaptic.navigation()
        Navigate.to.gotoMapVC(self)
    }
}

private enum LocationBootstrapPurpose {
    case primary
    case filter
}

private extension NewLandingVC {
    func runLocationBootstrapIfNeeded() {
        guard !didRunLocationBootstrap else { return }

        didRunLocationBootstrap = true
        evaluateLocationBootstrap()
    }

    func evaluateLocationBootstrap() {
        guard presentedViewController == nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.evaluateLocationBootstrap()
            }
            return
        }

        let status = locationManager.authorizationStatus

        if !UserDefault.shared.hasPrimaryLocation {
            switch status {
            case .notDetermined:
                presentLocationPermissionPrompt()
            case .authorizedAlways, .authorizedWhenInUse:
                requestCurrentLocation(for: .primary)
            case .denied, .restricted:
                presentManualPrimaryCitySelectionIfNeeded()
            @unknown default:
                presentManualPrimaryCitySelectionIfNeeded()
            }

            return
        }

        guard UserDefault.shared.filterCity == nil else { return }

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            requestCurrentLocation(for: .filter)
        default:
            break
        }
    }

    func presentLocationPermissionPrompt() {
        guard presentedViewController == nil else { return }

        let prompt = LocationPermissionPromptVC()
        prompt.modalPresentationStyle = .fullScreen
        prompt.onEnable = { [weak self] in
            guard let self else { return }
            self.pendingLocationPurpose = .primary
            self.locationManager.requestWhenInUseAuthorization()
        }
        prompt.onDismiss = { [weak self] in
            self?.dismissLocationPromptThenShowManualCity()
        }

        locationPromptVC = prompt
        present(prompt, animated: true)
    }

    func dismissLocationPromptThenShowManualCity() {
        let completion: () -> Void = { [weak self] in
            self?.presentManualPrimaryCitySelectionIfNeeded()
        }

        if let locationPromptVC {
            locationPromptVC.dismiss(animated: true, completion: completion)
        } else {
            completion()
        }
    }

    func presentManualPrimaryCitySelectionIfNeeded() {
        guard !UserDefault.shared.hasPrimaryLocation else { return }
        guard presentedViewController == nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.presentManualPrimaryCitySelectionIfNeeded()
            }
            return
        }

        let vc = SelectLocationVC(
            nibName: "SelectLocationVC",
            bundle: nil
        )
        vc.mode = .updatePrimaryLocation
        vc.isInitialPrimarySelection = true
        vc.persistsFilterSelection = false
        vc.onSelectPrimaryCity = { [weak self] _ in
            self?.refreshCityDrivenScreens()
        }

        present(vc, animated: true)
    }
    
    func requestCurrentLocation(for purpose: LocationBootstrapPurpose) {

        switch locationManager.authorizationStatus {

        case .authorizedAlways, .authorizedWhenInUse:
            pendingLocationPurpose = purpose

            if let cachedLocation = recentCachedLocation() {
                pendingLocationPurpose = nil
                resolveCity(for: cachedLocation, purpose: purpose)
            } else {
                locationManager.requestLocation()
            }

        case .denied, .restricted:
            if purpose == .primary {
                presentManualPrimaryCitySelectionIfNeeded()
            }

        case .notDetermined:
            pendingLocationPurpose = purpose
            locationManager.requestWhenInUseAuthorization()

        @unknown default:
            break
        }
    }
    
    func recentCachedLocation() -> CLLocation? {
        guard let location = locationManager.location else {
            return nil
        }

        let isRecent = abs(location.timestamp.timeIntervalSinceNow) <= 300
        let isUsableAccuracy = location.horizontalAccuracy >= 0 &&
            location.horizontalAccuracy <= 3_000

        return isRecent && isUsableAccuracy ? location : nil
    }

    func resolveCity(for location: CLLocation, purpose: LocationBootstrapPurpose) {
        venueService.fetchCityList { [weak self] cityList, isSuccess, _ in
            guard let self else { return }

            guard isSuccess,
                  !cityList.isEmpty else {
                if purpose == .primary {
                    self.presentManualPrimaryCitySelectionIfNeeded()
                }
                return
            }

            self.resolveCity(
                from: location,
                cityList: cityList
            ) { [weak self] city in
                self?.applyResolvedCity(city, purpose: purpose)
            }
        }
    }

    func resolveCity(
        from location: CLLocation,
        cityList: [MVPCity],
        completion: @escaping (MVPCity?) -> Void
    ) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            let placemark = placemarks?.first
            let matchedCity =
                MVPCity.matching(locality: placemark?.locality, in: cityList)
                ?? MVPCity.matching(locality: placemark?.subAdministrativeArea, in: cityList)
                ?? MVPCity.matching(locality: placemark?.administrativeArea, in: cityList)
                ?? MVPCity.nearest(to: location, in: cityList)

            DispatchQueue.main.async {
                completion(matchedCity)
            }
        }
    }

    func applyResolvedCity(_ city: MVPCity?, purpose: LocationBootstrapPurpose) {
        guard let cityName = city?.value
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !cityName.isEmpty else {
            if purpose == .primary {
                presentManualPrimaryCitySelectionIfNeeded()
            }
            return
        }

        switch purpose {
        case .primary:
            UserDefault.shared.setPrimaryCity(cityName)
            clearMatchingFilterCity(cityName)

        case .filter:
            guard UserDefault.shared.filterCity == nil else { return }

            if UserDefault.shared.isPrimaryCity(cityName) {
                UserDefault.shared.filterCity = nil
            } else {
                UserDefault.shared.filterCity = cityName
            }
        }

        refreshCityDrivenScreens()
    }

    func clearMatchingFilterCity(_ cityName: String) {
        if UserDefault.shared.normalizedCity(UserDefault.shared.filterCity) ==
            UserDefault.shared.normalizedCity(cityName) {
            UserDefault.shared.filterCity = nil
        }
    }

    func refreshCityDrivenScreens() {
        discoverVC.refreshLocationFromDefaults()
        experiencesVC.applyCity(UserDefault.shared.activeCity)
    }
}

extension NewLandingVC: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard pendingLocationPurpose == .primary else { return }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationPromptVC?.dismiss(animated: true) { [weak self] in
                self?.requestCurrentLocation(for: .primary)
            }
        case .denied, .restricted:
            pendingLocationPurpose = nil
            dismissLocationPromptThenShowManualCity()
        default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let purpose = pendingLocationPurpose,
              let location = locations.last else {
            return
        }

        pendingLocationPurpose = nil
        resolveCity(for: location, purpose: purpose)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        let purpose = pendingLocationPurpose
        pendingLocationPurpose = nil

        if purpose == .primary {
            presentManualPrimaryCitySelectionIfNeeded()
        }
    }
}

private final class LocationPermissionPromptVC: UIViewController {
    var onEnable: (() -> Void)?
    var onDismiss: (() -> Void)?

    private let gradientView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        gradientView.applyScreenBgGradient(direction: .topToBottom)
    }

    private func setupUI() {
        view.backgroundColor = AppColor.primaryBlackColor

        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView)

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(onClickDismiss), for: .touchUpInside)
        view.addSubview(closeButton)

        let iconView = UIImageView(image: UIImage(named: "locationPermisionIcon"))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Find better\nexperiences near you"
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.font = Constant.Font.geistMedium(size: 32)

        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.text = "Stay updated on the events, venues, reservations, and live experiences happening near you."
        bodyLabel.textAlignment = .center
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.58)
        bodyLabel.numberOfLines = 0
        bodyLabel.font = Constant.Font.geistRegular(size: 13)

        let centerStack = UIStackView(arrangedSubviews: [
            iconView,
            titleLabel,
            bodyLabel
        ])
        centerStack.translatesAutoresizingMaskIntoConstraints = false
        centerStack.axis = .vertical
        centerStack.alignment = .center
        centerStack.spacing = 22
        view.addSubview(centerStack)

        let enableButton = UIButton(type: .system)
        enableButton.translatesAutoresizingMaskIntoConstraints = false
        enableButton.setTitle("Enable location", for: .normal)
        enableButton.setTitleColor(.black, for: .normal)
        enableButton.titleLabel?.font = Constant.Font.geistMedium(size: 17)
        enableButton.backgroundColor = .white
        enableButton.layer.cornerRadius = 28
        enableButton.layer.cornerCurve = .continuous
        enableButton.addTarget(self, action: #selector(onClickEnable), for: .touchUpInside)

        let notNowButton = UIButton(type: .system)
        notNowButton.translatesAutoresizingMaskIntoConstraints = false
        notNowButton.setTitle("Not now", for: .normal)
        notNowButton.setTitleColor(.white, for: .normal)
        notNowButton.titleLabel?.font = Constant.Font.geistMedium(size: 17)
        notNowButton.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        notNowButton.layer.cornerRadius = 28
        notNowButton.layer.cornerCurve = .continuous
        notNowButton.addTarget(self, action: #selector(onClickDismiss), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [
            enableButton,
            notNowButton
        ])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .vertical
        buttonStack.spacing = 14
        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            iconView.widthAnchor.constraint(equalToConstant: 65),
            iconView.heightAnchor.constraint(equalToConstant: 65),

            centerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -46),
            centerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            centerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),

            bodyLabel.widthAnchor.constraint(lessThanOrEqualTo: centerStack.widthAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: centerStack.widthAnchor),

            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            enableButton.heightAnchor.constraint(equalToConstant: 56),
            notNowButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    @objc private func onClickEnable() {
        AppHaptic.primaryAction()
        onEnable?()
    }

    @objc private func onClickDismiss() {
        AppHaptic.navigation()
        onDismiss?()
    }
}

@available(iOS 26.0, *)
extension NewLandingVC: UITabBarControllerDelegate {}

extension NewLandingVC: FloatingCustomTabBarDelegate {
    func floatingCustomTabBar(_ tabBar: FloatingCustomTabBar, didSelect index: Int) {
        selectTab(index: index)
    }
}

extension NewLandingVC: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        
        let isRoot = navigationController.viewControllers.count <= 1
        
        systemTabVC?.tabBar.isHidden = !isRoot
    }
    
}
