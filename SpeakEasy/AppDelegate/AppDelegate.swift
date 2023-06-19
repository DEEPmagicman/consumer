//
//  AppDelegate.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

import UIKit
import IQKeyboardManagerSwift
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var application: UIApplication?
    static let shared: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    private var venueUniqueId = ""
    private var isAppClipSet = false
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let incomingURL = userActivity.webpageURL else {
            return true
        }
        handleForURL(incomingURL)
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        self.application = application
        
        IQKeyboardManager.shared.enable = true
        
        window = UIWindow(frame:UIScreen.main.bounds)
        launchApplication()
        Bundle.FlagIcons = Bundle(for: type(of: self))
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}
//MARK: - Application flow
extension AppDelegate {
    private func launchApplication() {
        let controller = Splash()
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
    }

    func changeRootViewController() {
        if UserDefault.shared.isLoggedIn == true {
            if UserDefault.shared.user?.isProfileCompleted == true || UserDefault.shared.isGuest == true {
                setRootVC()
            } else {
                showOnboarding(isNavigateToDetail: true)
            }
        } else {
            showOnboarding()
        }
    }
    
    func showOnboarding(isNavigateToDetail: Bool = false) {
        let controller = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.getIdentifier(StartScreenViewController.self)) as! StartScreenViewController
        let tutorialNavigation = UINavigationController(rootViewController: controller)
        tutorialNavigation.navigationBar.isHidden = true
        tutorialNavigation.modalTransitionStyle = .crossDissolve
        tutorialNavigation.modalPresentationStyle = .overCurrentContext
        self.window?.rootViewController = tutorialNavigation
        if isNavigateToDetail, let vc = self.window?.rootViewController {
            Navigate.to.connectAccountVc(vc)
        }
    }
    
    private func handleForURL(_ url: URL) {
        if url.absoluteString.contains("event") {
            setRootVC(.event, id: url.lastPathComponent)
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
            return
        }
        if let venue = queryItems.first(where: { $0.name == "v" })?.value {
            venueUniqueId = venue
            setRootVC(.venue)
            return
        }
        if let venue = queryItems.first(where: { $0.name == "venueId" })?.value {
            venueUniqueId = venue
            setRootVC(.venue)
            return
        }
    }

    private func setRootVC(_ forType: NavigationDestination = .appLaunch, id: String = "") {
        let tabBarController = UITabBarController()
        ReachabilityManager.shared.startMonitoring()
        let home = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPVenueListVc.self)
        home.tabBarItem.image              = UIImage(named :"Home")?.withRenderingMode(.alwaysOriginal)
        home.tabBarItem.selectedImage      = UIImage(named :"HomeSelected")?.withRenderingMode(.alwaysOriginal)
        let homeNavigation = UINavigationController(rootViewController: home)
        homeNavigation.navigationBar.isHidden = true
        var myAccount = UIViewController()
        if UserDefault.shared.isGuest == true {
            myAccount = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPStartScreenVC.self)
        } else {
            myAccount = StoryboardAndXibManager.StoryBoard.account.instantiateVC(AccountVC.self)
        }
        myAccount.tabBarItem.image         = UIImage(named :"MyAccount")?.withRenderingMode(.alwaysOriginal)
        myAccount.tabBarItem.selectedImage = UIImage(named :"MyAccountSelected")?.withRenderingMode(.alwaysOriginal)
        let myAccountNavigation = UINavigationController(rootViewController: myAccount)
        myAccountNavigation.navigationBar.isHidden = true

        tabBarController.viewControllers = [homeNavigation,myAccountNavigation]
        
        tabBarController.selectedIndex = 0
        
        tabBarController.tabBar.isTranslucent = false
        
        tabBarController.tabBarItem.imageInsets = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: 0)
        let tabBarControllerNavigation = UINavigationController(rootViewController: tabBarController)
        tabBarControllerNavigation.navigationBar.isHidden = true
        self.window?.rootViewController = tabBarControllerNavigation
        
        switch forType {
        case .appLaunch:
            break
        case .venue:
            if venueUniqueId != "" {
                let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPVenueDetailVc.self)
                vc.venueUniqueId = venueUniqueId
                vc.isFromAppClip = true
                isAppClipSet = true
                home.navigationController?.pushViewController(vc, animated: false)
            }
        case .event:
            let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(EventDetailVC.self)
            vc.eventId = id
            homeNavigation.navigationController?.pushViewController(vc, animated: false)
        }
    }
}
