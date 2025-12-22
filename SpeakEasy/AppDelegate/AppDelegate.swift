//
//  AppDelegate.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

import UIKit
import IQKeyboardManagerSwift
import Firebase
import LGSideMenuController

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var application: UIApplication?
    static let shared: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var guestUserLastNavigation: (NavigationDestination, String) = (.appLaunch, "")
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let incomingURL = userActivity.webpageURL else {
            return true
        }
//        handleForURL(incomingURL)
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        self.application = application
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        RemoteConfigHelper.shared.getRemoteConfigValues()
        window = UIWindow(frame:UIScreen.main.bounds)
        launchApplication()
//        Bundle.FlagIcons = Bundle(for: type(of: self))
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
    
    func showMaintenanceVC() {
        let vc = MaintenanceVC(nibName: "MaintenanceVC", bundle: nil)
        self.window?.rootViewController = vc
    }
}
//MARK: - Application flow
extension AppDelegate {
    private func launchApplication() {
        let controller = Splash()
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
    }
    
    func changeRootViewController(forceCreateAccount: Bool = false) {
        if UserDefault.shared.isLoggedIn == true {
            if UserDefault.shared.user?.isProfileCompleted == true || UserDefault.shared.isGuest == true {
                setRootVC()
            } else if UserDefault.shared.user?.isSocial == true {
                showNameVC()
            } else {
                showOnboarding(isNavigateToDetail: true)
            }
        } else {
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
        if isNavigateToDetail {
//            Navigate.to.connectAccountVc(controller)
            Navigate.to.enterNameVc(controller)
        } else if forceCreateAccount {
            Navigate.to.enterPhoneNumVc(controller)
        }
    }
    
    func showNameVC() {
        let controller = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.getIdentifier(StartScreenViewController.self)) as! StartScreenViewController
        let tutorialNavigation = UINavigationController(rootViewController: controller)
        tutorialNavigation.navigationBar.isHidden = true
        tutorialNavigation.modalTransitionStyle = .crossDissolve
        tutorialNavigation.modalPresentationStyle = .overCurrentContext
        Navigate.to.enterNameVc(controller)
        self.window?.rootViewController = tutorialNavigation
    }
    
//    private func handleForURL(_ url: URL) {
//        
//        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let queryItems = components.queryItems, let value = queryItems.first(where: { $0.name == "bid" })?.value {
//            if url.absoluteString.contains("event") {
//                setRootVC(.booking, id: value)
//                return
//            }
//        }
//        
//        if url.absoluteString.contains("event") {
//            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let queryItems = components.queryItems {
//                if let value = queryItems.first(where: { $0.name == "eid" })?.value {
//                    setRootVC(.event, id: value, link: url.absoluteString)
//                    return
//                }
//                if let inviteId = queryItems.first(where: { $0.name == "L" })?.value {
//                    setRootVC(.inviteLink, id: inviteId, link: url.absoluteString)
//                    return
//                }
//                let promoteId = queryItems.first(where: { $0.name == "promoteId" })?.value
//                let bookingId = queryItems.first(where: { $0.name == "bookingId" })?.value
//                if let bookingId = bookingId {
//                    setRootVC(.booking, id: bookingId)
//                } else {
//                    setRootVC(.event, id: url.lastPathComponent, promoteId: promoteId ?? "", link: url.absoluteString)
//                }
//            } else {
//                setRootVC(.event, id: url.lastPathComponent, link: url.absoluteString)
//            }
//            return
//        }
//        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
//            return
//        }
//        
//        if let value = queryItems.first(where: { $0.name == "vid" })?.value {
//            if value.contains("VN") {
//                setRootVC(.venue, id: value)
//            } else {
//                VenuePresenter.getDeepLinkData(value) { isSuccess, errMsg, doormanId, venueId in
//                    if isSuccess, let value = venueId, let doormanId = doormanId {
//                        self.setRootVC(.venue, id: value, doormanId: doormanId)
//                    } else {
//                        self.setRootVC()
//                    }
//                    return
//                }
//            }
//            return
//        }
//        
//        if let value = queryItems.first(where: { $0.name == "iid" })?.value {
//            setRootVC(.inviteLink, id: value)
//            return
//        }
//        
//        if let value = queryItems.first(where: { $0.name == "bid" })?.value {
//            setRootVC(.addOns, id: value)
//            return
//        }
//        
//        if let value = queryItems.first(where: { $0.name == "pid" })?.value {
//            let eventId = queryItems.first(where: { $0.name == "eid" })?.value ?? ""
//            setRootVC(.event, id: eventId, promoteId: value, link: url.absoluteString)
//            return
//        }
//        
//        if let value = queryItems.first(where: { $0.name == "eid" })?.value {
//            setRootVC(.event, id: value, link: url.absoluteString)
//            return
//        }
//        
//        if let value = queryItems.first(where: { $0.name == "aid" })?.value {
//            setRootVC(.addOns, addOnsId: value, isOnlyAddOnAvailable: true)
//            return
//        }
//        
//        if let value = queryItems.first(where: { $0.name == "v" })?.value {
//            if value.contains("VN") {
//                setRootVC(.venue, id: value)
//            } else {
//                VenuePresenter.getDeepLinkData(value) { isSuccess, errMsg, doormanId, venueId in
//                    if isSuccess, let value = venueId, let doormanId = doormanId {
//                        self.setRootVC(.venue, id: value, doormanId: doormanId)
//                    } else {
//                        self.setRootVC()
//                    }
//                    return
//                }
//            }
//            return
//        }
//        if let venue = queryItems.first(where: { $0.name == "venueId" })?.value {
//            setRootVC(.venue, id: venue)
//            return
//        }
//        if let inviteId = queryItems.first(where: { $0.name == "L" })?.value {
//            setRootVC(.inviteLink, id: inviteId, link: url.absoluteString)
//            return
//        }
//    }
    
    private func setRootVC(_ forType: NavigationDestination = .appLaunch, id: String = "", promoteId: String = "", doormanId: String = "", addOnsId: String = "", isOnlyAddOnAvailable: Bool = false, link: String? = nil) {
//        let tabBarController = UITabBarController()
        ReachabilityManager.shared.startMonitoring()
//        let home = StoryboardAndXibManager.StoryBoard.landing.instantiateVC(LandingVC.self)
//        home.tabBarItem.image              = UIImage(named :"ic-home")?.withRenderingMode(.alwaysOriginal)
//        home.tabBarItem.selectedImage      = UIImage(named :"ic-home1")?.withRenderingMode(.alwaysTemplate)
//        home.tabBarItem.standardAppearance?.selectionIndicatorTintColor = .white
//        home.tabBarItem.imageInsets = UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0)
//        let homeNavigation = UINavigationController(rootViewController: home)
//        homeNavigation.navigationBar.isHidden = true
//        var myAccount = UIViewController()
//        if UserDefault.shared.isGuest == true {
//            myAccount = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPStartScreenVC.self)
//        } else {
//            myAccount = StoryboardAndXibManager.StoryBoard.account.instantiateVC(AccountVC.self)
//        }
//        myAccount.tabBarItem.image         = UIImage(named :"ic-person")?.withRenderingMode(.alwaysOriginal)
//        myAccount.tabBarItem.selectedImage = UIImage(named :"ic-person1")?.withRenderingMode(.alwaysTemplate)
//        myAccount.tabBarItem.standardAppearance?.selectionIndicatorTintColor = .red
//        UITabBar.appearance().tintColor = .white
//        myAccount.tabBarItem.imageInsets = UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0)
//        let myAccountNavigation = UINavigationController(rootViewController: myAccount)
//        myAccountNavigation.navigationBar.isHidden = true
        
//        tabBarController.viewControllers = [homeNavigation,myAccountNavigation]
//        
//        tabBarController.selectedIndex = 0
//        
//        tabBarController.tabBar.isTranslucent = false
//        
//        tabBarController.tabBarItem.imageInsets = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: 0)
//        let tabBarControllerNavigation = UINavigationController(rootViewController: tabBarController)
//        tabBarControllerNavigation.navigationBar.isHidden = true
//        let navigationController: UINavigationController = StoryboardAndXibManager.StoryBoard.landing.instantiateViewController(withIdentifier: IdentifierHelper.getIdentifier(UINavigationController.self)) as! UINavigationController
//        navigationController.navigationBar.isHidden = true
//        self.window?.rootViewController = navigationController
        
        let vc = AppDelegate.gotoTab
        let navigation = UINavigationController(rootViewController: vc)
        navigation.navigationBar.isHidden = true
        self.window?.rootViewController = navigation
        
//        switch forType {
//        case .appLaunch:
//            if UserDefault.shared.isGuest == false {
//                setGuestUserLastNavigation(home)
//            }
//        case .venue:
//            let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPVenueDetailVc.self)
//            vc.venueUniqueId = id
//            vc.isFromAppClip = true
//            vc.doormanId = doormanId
//            home.navigationController?.pushViewController(vc, animated: false)
//        case .event:
//            if let url = link {
//                Navigate.externalURL(url)
//            }
//            
////            Navigate.to.eventDetail(home, eventId: id, venueDetail: nil, event: nil, promoteId: promoteId)
//        case .inviteLink:
//            if let url = link {
//                Navigate.externalURL(url)
//            }
////            inviteLinkNav(home, id: id)
//        case .booking:
//            Navigate.to.showQRCode(home, booking: nil, bookingId: id, type: .singleTickedEvent)
//        case .addOns:
//            Navigate.to.scanQR(home, isAddOnsAvailable: true, bookingId: id, isOnlyAddOnAvailable: isOnlyAddOnAvailable, addOnsBookingId: addOnsId, venueName: "")
//        }
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
