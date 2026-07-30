//
//  AppDelegate.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

// swiftlint: disable all
import UIKit
import IQKeyboardManagerSwift
import Firebase
import GoogleMaps
import LGSideMenuController

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    typealias PendingDeepLink = (
        destination: NavigationDestination,
        id: String,
        secondaryId: String?,
        tertiaryId: String?,
        micrositeSlug: String?,
        sourceURL: String?
    )

    var window: UIWindow?
    var application: UIApplication?
    static let shared: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var guestUserLastNavigation: (NavigationDestination, String) = (.appLaunch, "")
    var pendingDeepLink: PendingDeepLink?

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        guard let incomingURL = userActivity.webpageURL else {
            return false
        }

        handleForURL(incomingURL)
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        handleForURL(url)
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        UINavigationController.installDuplicatePushGuard()
        UIViewController.installDuplicatePresentationGuard()
        configureGoogleMaps()
        self.application = application

        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        UserDefault.shared.selectedVenueId = nil
        if AppDesign.useModernIOS26Design {
            IQKeyboardManager.shared.enableAutoToolbar = false
            GlobalTextFieldHandler.shared.setup()
        }
        RemoteConfigHelper.shared.getRemoteConfigValues()
        window = UIWindow(frame: UIScreen.main.bounds)

        // isVersionV3 is true for new v3 version design
        UserDefault.shared.isVersionV3 = true
        launchApplication()
        return true
    }

    private func configureGoogleMaps() {
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: path),
            let apiKey = plist["API_KEY"] as? String,
            apiKey.isEmpty == false
        else {
            return
        }

        GMSServices.provideAPIKey(apiKey)
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }

    func showMaintenanceVC() {
        let vc = MaintenanceVC(nibName: "MaintenanceVC", bundle: nil)
        self.window?.rootViewController = vc
    }
}

extension AppDelegate {

    private func launchApplication() {
        let controller = Splash()
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
        ThemeManager.shared.apply(theme: ThemeManager.shared.current)
    }

    func changeRootViewController(forceCreateAccount: Bool = false) {
        if UserDefault.shared.isLoggedIn == true {
            if UserDefault.shared.user?.isProfileCompleted == true || UserDefault.shared.isGuest == true {
                setRootVC()
            } else if UserDefault.shared.isVersionV3 == true {
                setRootVC()
            } else if UserDefault.shared.user?.isSocial == true && UserDefault.shared.isVersionV3 == false {
                showNameVC()
            } else {
                if UserDefault.shared.isVersionV3 == true {
                    UserDefault.shared.isGuest = true
                    setRootVC()
                    return
                }
                showOnboarding(isNavigateToDetail: true)
            }
        } else {
            if UserDefault.shared.isVersionV3 == true {
                UserDefault.shared.isGuest = true
                setRootVC()
                return
            }
            showOnboarding(forceCreateAccount: forceCreateAccount)
        }
    }

    func showOnboarding(isNavigateToDetail: Bool = false, forceCreateAccount: Bool = false) {
        let controller = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.getIdentifier(StartScreenViewController.self)) as! StartScreenViewController
        let tutorialNavigation = UINavigationController(rootViewController: controller)
        tutorialNavigation.navigationBar.isHidden = true
        tutorialNavigation.modalTransitionStyle = .crossDissolve
        tutorialNavigation.modalPresentationStyle = .overCurrentContext
        self.window?.rootViewController = tutorialNavigation
        Navigate.to.openPhoneLoginPopup(controller)

//        if isNavigateToDetail {
//            Navigate.to.signUpViewControllerVc(controller)
//        } else if forceCreateAccount {
//            Navigate.to.enterPhoneNumVc(controller)
//        }
    }

    func showNameVC() {
        let controller = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.getIdentifier(StartScreenViewController.self)) as! StartScreenViewController
        let tutorialNavigation = UINavigationController(rootViewController: controller)
        tutorialNavigation.navigationBar.isHidden = true
        tutorialNavigation.modalTransitionStyle = .crossDissolve
        tutorialNavigation.modalPresentationStyle = .overCurrentContext
        Navigate.to.signUpViewControllerVc(controller)
        self.window?.rootViewController = tutorialNavigation
    }

    private func handleForURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        let queryItems = components.queryItems ?? []

        if let value = value(for: ["v"], in: queryItems) {
            queueVenueIdentifier(value)
            return
        }

        if let value = value(for: ["vid"], in: queryItems) {
            queueVenueIdentifier(value)
            return
        }

        if let value = value(for: ["venueId"], in: queryItems) {
            queueDeepLink(.venue, id: value)
            return
        }

        if let eventId = value(for: ["eid", "eventId"], in: queryItems) {
            queueDeepLink(
                .event,
                id: eventId,
                secondaryId: value(for: ["pid", "promotionLinkId", "promoteId"], in: queryItems),
                tertiaryId: value(for: ["t", "ts", "promotionLinkUniqueCode"], in: queryItems),
                micrositeSlug: value(for: ["micrositeSlug"], in: queryItems),
                sourceURL: url.absoluteString
            )
            return
        }

        if let value = value(for: ["bid", "bookingId"], in: queryItems) {
            queueDeepLink(.booking, id: value)
            return
        }

        if let value = value(for: ["aid", "addOnsBookingId"], in: queryItems) {
            queueDeepLink(.addOns, id: value)
            return
        }

        if let value = value(for: ["iid", "L", "inviteId"], in: queryItems) {
            queueDeepLink(.inviteLink, id: value)
            return
        }

        if let eventId = pathValue(after: "event", in: components) {
            queueDeepLink(
                .event,
                id: eventId,
                secondaryId: value(for: ["pid", "promotionLinkId", "promoteId"], in: queryItems),
                tertiaryId: value(for: ["t", "ts", "promotionLinkUniqueCode"], in: queryItems),
                micrositeSlug: value(for: ["micrositeSlug"], in: queryItems),
                sourceURL: url.absoluteString
            )
            return
        }
    }

    func setRootVC() {
        ReachabilityManager.shared.startMonitoring()

        var navigation = UINavigationController()

        if UserDefault.shared.isVersionV3 == true {
            let vc = NewLandingVC()
            navigation = UINavigationController(rootViewController: vc)
        } else {
            let vc = AppDelegate.gotoTab
            navigation = UINavigationController(rootViewController: vc)
        }
//
        navigation.navigationBar.isHidden = true
        setRootViewController(navigation)
        self.window?.makeKeyAndVisible()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.handlePendingDeepLink()
        }
    }

    func setRootViewController(
        _ viewController: UIViewController,
        duration: TimeInterval = 0.3
    ) {

        guard let window = self.window else { return }

        UIView.transition(
            with: window,
            duration: duration,
            options: [.transitionCrossDissolve, .allowAnimatedContent],
            animations: {
                window.rootViewController = viewController
            }
        )
    }
    
    @discardableResult
    private func handlePendingDeepLink() -> Bool {
        guard let deepLink = pendingDeepLink,
              let rootNav = window?.rootViewController as? UINavigationController else { return false }

        if rootNav.viewControllers.first is NewLandingVC {
            pendingDeepLink = nil
            handleV3DeepLink(deepLink, rootNav: rootNav)
            return true
        }

        guard let sideMenu = rootNav.viewControllers.first as? LGSideMenuController,
              let rootVC = sideMenu.rootViewController as? LandingVC else { return false }

        pendingDeepLink = nil
        handleV2DeepLink(deepLink, rootVC: rootVC, rootNav: rootNav)
        return true
    }

    private func value(for names: [String], in queryItems: [URLQueryItem]) -> String? {
        let lowercasedNames = names.map { $0.lowercased() }
        return queryItems.compactMap { item -> String? in
            guard lowercasedNames.contains(item.name.lowercased()) else { return nil }
            let value = item.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty ? nil : value
        }.first
    }

    private func queueVenueIdentifier(_ value: String) {
        if value.uppercased().hasPrefix("DL") {
            queueDeepLink(.venueDeepLink, id: value)
        } else {
            queueDeepLink(.venue, id: value)
        }
    }

    private func queueDeepLink(
        _ destination: NavigationDestination,
        id: String,
        secondaryId: String? = nil,
        tertiaryId: String? = nil,
        micrositeSlug: String? = nil,
        sourceURL: String? = nil
    ) {
        let trimmedId = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedId.isEmpty == false else { return }
        pendingDeepLink = (
            destination: destination,
            id: trimmedId,
            secondaryId: secondaryId,
            tertiaryId: tertiaryId,
            micrositeSlug: micrositeSlug,
            sourceURL: sourceURL
        )

        if handlePendingDeepLink() {
            return
        }

        changeRootViewController()
    }

    private func pathValue(after marker: String, in components: URLComponents) -> String? {
        let pathComponents = components.path
            .split(separator: "/")
            .map { String($0) }

        guard let index = pathComponents.firstIndex(where: { $0.lowercased() == marker.lowercased() }),
              pathComponents.indices.contains(index + 1) else { return nil }

        let rawValue = pathComponents[index + 1]
        let value = rawValue.removingPercentEncoding ?? rawValue
        return value.isEmpty ? nil : value
    }

    private func handleV3DeepLink(
        _ deepLink: PendingDeepLink,
        rootNav: UINavigationController
    ) {
        rootNav.dismiss(animated: false)
        rootNav.popToRootViewController(animated: false)

        guard let sender = rootNav.topViewController else { return }

        switch deepLink.destination {
        case .event:
            let vc = EventDetailsVC(nibName: "EventDetailsVC", bundle: nil)
            vc.uniqueId = deepLink.id
            vc.promoteId = deepLink.secondaryId ?? ""
            vc.promotionLinkUniqueCode = deepLink.tertiaryId ?? ""
            vc.micrositeSlug = deepLink.micrositeSlug ?? ""
            rootNav.pushViewController(vc, animated: true)

        case .venue:
            let vc = VenueVC(nibName: "VenueVC", bundle: nil)
            vc.uniqueId = deepLink.id
            rootNav.pushViewController(vc, animated: true)

        case .venueDeepLink:
            resolveVenueDeepLink(deepLink.id, rootNav: rootNav)

        case .booking:
            Navigate.to.scanQR(sender, bookingId: deepLink.id, addOnsBookingId: "")

        case .addOns:
            Navigate.to.scanQR(
                sender,
                isAddOnsAvailable: true,
                bookingId: "",
                isOnlyAddOnAvailable: true,
                addOnsBookingId: deepLink.id
            )

        case .inviteLink:
            Navigate.to.inviteVC(sender, inviteId: deepLink.id)

        default:
            break
        }
    }

    private func handleV2DeepLink(
        _ deepLink: PendingDeepLink,
        rootVC: LandingVC,
        rootNav: UINavigationController
    ) {
        let navigationController = rootVC.navigationController ?? rootNav
        let sender = navigationController.topViewController ?? rootVC

        switch deepLink.destination {
        case .event:
            let vc = EventDetailsVC(nibName: "EventDetailsVC", bundle: nil)
            vc.uniqueId = deepLink.id
            vc.promoteId = deepLink.secondaryId ?? ""
            vc.promotionLinkUniqueCode = deepLink.tertiaryId ?? ""
            vc.micrositeSlug = deepLink.micrositeSlug ?? ""
            navigationController.pushViewController(vc, animated: true)

        case .venue:
            let vc = VenueVC(nibName: "VenueVC", bundle: nil)
            vc.uniqueId = deepLink.id
            navigationController.pushViewController(vc, animated: true)

        case .venueDeepLink:
            resolveVenueDeepLink(deepLink.id, rootNav: navigationController)

        case .booking:
            Navigate.to.scanQR(sender, bookingId: deepLink.id, addOnsBookingId: "")

        case .addOns:
            Navigate.to.scanQR(
                sender,
                isAddOnsAvailable: true,
                bookingId: "",
                isOnlyAddOnAvailable: true,
                addOnsBookingId: deepLink.id
            )

        case .inviteLink:
            Navigate.to.inviteVC(sender, inviteId: deepLink.id)

        default:
            break
        }
    }

    private func resolveVenueDeepLink(_ id: String, rootNav: UINavigationController) {
        let service = VenueService()

        service.fetchDeepLinkData(id: id) { [weak rootNav] isSuccess, errMsg, doormanId, venueId in
            guard let rootNav else { return }

            guard isSuccess,
                  let venueId = venueId?.trimmingCharacters(in: .whitespacesAndNewlines),
                  venueId.isEmpty == false
            else {
                DispatchQueue.main.async {
                    Alert.showAlertSheet(
                        style: .alert,
                        title: errMsg ?? "Unable to open this link",
                        message: ""
                    )
                }
                return
            }

            service.fetchVenueDetail(
                venueId: venueId,
                venueTimeZone: TimeZone.current.identifier,
                doormanId: doormanId ?? ""
            ) { [weak rootNav] isSuccess, _, venue in
                DispatchQueue.main.async {
                    guard let rootNav else { return }

                    let vc = VenueVC(nibName: "VenueVC", bundle: nil)
                    vc.venueDetails = isSuccess ? venue : nil
                    vc.uniqueId = venue?.uniqueId ?? venueId
                    vc.doormanId = doormanId ?? ""
                    rootNav.pushViewController(vc, animated: true)
                }
            }
        }
    }

    private func setGuestUserLastNavigation(_ sender: UIViewController) {
        if guestUserLastNavigation.0 == .inviteLink {
            inviteLinkNav(sender, id: guestUserLastNavigation.1)
        }
    }

    private func inviteLinkNav(_ sender: UIViewController, id: String) {
        Navigate.to.inviteVC(sender, inviteId: id)
        if UserDefault.shared.isGuest == true {
            guestUserLastNavigation = (.inviteLink, id)
        } else {
            guestUserLastNavigation = (.appLaunch, "")
        }
    }

    static var gotoSignUp: UIViewController {
        let signUp = StoryboardAndXibManager.StoryBoard.signUp
            .instantiateVC(withIdentifier: VerifyNumberViewController.self)
        return signUp
    }

    static var gotoTab: UIViewController {
        let rootScreen = StoryboardAndXibManager.StoryBoard.landing.instantiateVC(withIdentifier: LandingVC.self)
        let root = StoryboardAndXibManager.StoryBoard.landing.instantiateInitialViewController()
        let sideMenu = SideMenuVC(nibName: "SideMenuVC", bundle: nil)

        let sideMenuController = LGSideMenuController(rootViewController: root,
                                                      leftViewController: sideMenu,
                                                      rightViewController: nil)

        sideMenuController.isLeftViewSwipeGestureEnabled = false
        sideMenuController.isRightViewSwipeGestureEnabled = false
        sideMenuController.rightViewPresentationStyle = .slideAbove
        sideMenuController.leftViewCoverBlurEffect = UIBlurEffect(style: .dark)
        sideMenuController.modalPresentationStyle = .overFullScreen

        let screenWidth: CGFloat = UIScreen.main.bounds.size.width - 100
        sideMenuController.leftViewWidth = screenWidth
        sideMenuController.rootViewController = rootScreen
        sideMenuController.rootViewController?.sideMenuController?.rootViewCoverBlurEffect = UIBlurEffect(style: .dark)

        return sideMenuController
    }
}

extension UIStoryboard {
    func instantiateVC<T: UIViewController>(withIdentifier id: T.Type) -> T {
        guard let controller = self.instantiateViewController(withIdentifier: String(describing: id)) as? T else {
            fatalError("could not cast UIViewController")
        }
        return controller
    }
}
