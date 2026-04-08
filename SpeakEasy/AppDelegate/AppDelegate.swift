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
import LGSideMenuController

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var application: UIApplication?
    static let shared: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var guestUserLastNavigation: (NavigationDestination, String) = (.appLaunch, "")
    var pendingDeepLink: (NavigationDestination, String, String?, String?, String?)?
    
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
        self.application = application
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        RemoteConfigHelper.shared.getRemoteConfigValues()
        window = UIWindow(frame: UIScreen.main.bounds)
        launchApplication()
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
            Navigate.to.signUpViewControllerVc(controller)
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
        Navigate.to.signUpViewControllerVc(controller)
        self.window?.rootViewController = tutorialNavigation
    }
    
    private func handleForURL(_ url: URL) {
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return }
        
        if let value = queryItems.first(where: { $0.name == "eid" })?.value {
            pendingDeepLink = (.event, value, nil, nil, url.absoluteString)
            changeRootViewController()
            return
        }
        
        if let value = queryItems.first(where: { $0.name == "vid" })?.value {
            pendingDeepLink = (.venue, value, nil, nil, nil)
            changeRootViewController()
            return
        }
        
        if let value = queryItems.first(where: { $0.name == "bid" })?.value {
            pendingDeepLink = (.booking, value, nil, nil, nil)
            changeRootViewController()
            return
        }
        
        if let value = queryItems.first(where: { $0.name == "iid" })?.value {
            pendingDeepLink = (.inviteLink, value, nil, nil, nil)
            changeRootViewController()
            return
        }
    }
    
    private func setRootVC() {
        ReachabilityManager.shared.startMonitoring()
        
        let vc = AppDelegate.gotoTab
        let navigation = UINavigationController(rootViewController: vc)
        navigation.navigationBar.isHidden = true
        self.window?.rootViewController = navigation
        self.window?.makeKeyAndVisible()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.handlePendingDeepLink()
        }
    }
    
    private func handlePendingDeepLink() {
        
        guard let deepLink = pendingDeepLink else { return }
        pendingDeepLink = nil
        
        guard let rootNav = window?.rootViewController as? UINavigationController,
              let sideMenu = rootNav.viewControllers.first as? LGSideMenuController,
              let rootVC = sideMenu.rootViewController as? LandingVC else { return }
        
        switch deepLink.0 {
        case .event:
            let vc = EventDetailsVC(nibName: "EventDetailsVC", bundle: nil)
            vc.uniqueId = deepLink.1
            rootVC.navigationController?.pushViewController(vc, animated: true)
            
        case .venue:
            let vc = VenueVC(nibName: "VenueVC", bundle: nil)
            vc.uniqueId = deepLink.1
            rootVC.navigationController?.pushViewController(vc, animated: true)
        case .booking:
            Navigate.to.showQRCode(rootVC, booking: nil, bookingId: deepLink.1, type: .singleTickedEvent)
        case .inviteLink:
            Navigate.to.inviteVC(rootVC, inviteId: deepLink.1)
        default:
            break
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
