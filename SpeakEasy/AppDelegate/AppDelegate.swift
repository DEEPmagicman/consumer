//
//  AppDelegate.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

import UIKit
import GoogleMaps
import IQKeyboardManagerSwift
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var application: UIApplication?
    static let shared: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    private var venueId = ""
    private var isAppClipSet = false
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let incomingURL = userActivity.webpageURL, let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
            return true
        }
        if let venue = queryItems.first(where: { $0.name == "v" })?.value {
            venueId = venue
            setAppClipNavigation()
            return true
        }
        if let venue = queryItems.first(where: { $0.name == "venueId" })?.value {
            venueId = venue
            setAppClipNavigation()
            return true
        }
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefault.shared.isMvp = false
        FirebaseApp.configure()
        self.application = application
        GMSServices.provideAPIKey(Constants.apiKey)
        
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
        // TODO: remove mvp flow
        if UserDefault.shared.isMvp == true {
            showMVP()
            return
        }
        if UserDefault.shared.isLoggedIn == true {
            if UserDefault.shared.user?.isProfileCompleted == true || UserDefault.shared.isGuest == true {
                showHome(selectedIndex: 0)
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
    
    private func setAppClipNavigation() {
        ReachabilityManager.shared.startMonitoring()
        if venueId != "" {
            let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPVenueDetailVc.self)
            vc.venueId = venueId
            vc.isFromAppClip = true
            let navigation = UINavigationController(rootViewController: vc)
            navigation.navigationBar.isHidden = true
            navigation.modalTransitionStyle = .crossDissolve
            navigation.modalPresentationStyle = .overCurrentContext
            self.window?.rootViewController = navigation
            isAppClipSet = true
        }
    }
    
    func showMVP() {
        ReachabilityManager.shared.startMonitoring()
        if isAppClipSet { return }
        if UserDefault.shared.hasVisitedStartingPage {
            let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPVenueListVc.self)
            let navigation = UINavigationController(rootViewController: vc)
            navigation.navigationBar.isHidden = true
            navigation.modalTransitionStyle = .crossDissolve
            navigation.modalPresentationStyle = .overCurrentContext
            self.window?.rootViewController = navigation
            return
        }
        let controller = StoryboardAndXibManager.StoryBoard.home.instantiateViewController(withIdentifier: IdentifierHelper.getIdentifier(MVPStartScreenVC.self)) as! MVPStartScreenVC
        let navigation = UINavigationController(rootViewController: controller)
        navigation.navigationBar.isHidden = true
        navigation.modalTransitionStyle = .crossDissolve
        navigation.modalPresentationStyle = .overCurrentContext
        self.window?.rootViewController = navigation
    }

//    func showLogin() {
//        let controller = LogIn()
//        controller.isHeroEnabled = true
//        controller.modalTransitionStyle = .crossDissolve
//        controller.modalPresentationStyle = .overCurrentContext
//        self.window?.rootViewController = controller
//    }

//    public func showHome(selectedIndex: Int) {
//        let tabBarController = UITabBarController()
//        let home = Home()
//        home.tabBarItem.image              = UIImage(named :"Home")?.withRenderingMode(.alwaysOriginal)
//        home.tabBarItem.selectedImage      = UIImage(named :"HomeSelected")?.withRenderingMode(.alwaysOriginal)
//        let homeNavigation = UINavigationController(rootViewController: home)
//        homeNavigation.navigationBar.isHidden = true
//
//        let bookingsAndInvites = BookingsAndInvites()
//        bookingsAndInvites.tabBarItem.image               = UIImage(named :"BookingsAndInvites")?.withRenderingMode(.alwaysOriginal)
//        bookingsAndInvites.tabBarItem.selectedImage       = UIImage(named :"BookingsAndInvitesSelected")?.withRenderingMode(.alwaysOriginal)
//        let bookingsAndInvitesNavigation = UINavigationController(rootViewController: bookingsAndInvites)
//        bookingsAndInvitesNavigation.navigationBar.isHidden = true
//
//        let accessPass = Wallet()
//        accessPass.tabBarItem.image               = UIImage(named :"AccessPass")?.withRenderingMode(.alwaysOriginal)
//        accessPass.tabBarItem.selectedImage       = UIImage(named :"AccessPassSelected")?.withRenderingMode(.alwaysOriginal)
//        let accessPassNavigation = UINavigationController(rootViewController: accessPass)
//        accessPassNavigation.navigationBar.isHidden = true
//
//        let statusAndRewards = StatusAndRewards()
//        statusAndRewards.tabBarItem.image         = UIImage(named :"StatusAndRewards")?.withRenderingMode(.alwaysOriginal)
//        statusAndRewards.tabBarItem.selectedImage = UIImage(named :"StatusAndRewardsSelected")?.withRenderingMode(.alwaysOriginal)
//        let statusAndRewardsNavigation = UINavigationController(rootViewController: statusAndRewards)
//        statusAndRewardsNavigation.navigationBar.isHidden = true
//
//        let myAccount = MyAccount()
//        myAccount.tabBarItem.image         = UIImage(named :"MyAccount")?.withRenderingMode(.alwaysOriginal)
//        myAccount.tabBarItem.selectedImage = UIImage(named :"MyAccountSelected")?.withRenderingMode(.alwaysOriginal)
//        let myAccountNavigation = UINavigationController(rootViewController: myAccount)
//        myAccountNavigation.navigationBar.isHidden = true
//
//        tabBarController.viewControllers = [homeNavigation,bookingsAndInvitesNavigation,accessPassNavigation,statusAndRewardsNavigation,myAccountNavigation]
//
//        tabBarController.selectedIndex = selectedIndex
//
//        tabBarController.tabBar.isTranslucent = false
//
//        tabBarController.tabBarItem.imageInsets = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: 0)
//        let tabBarControllerNavigation = UINavigationController(rootViewController: tabBarController)
//        tabBarControllerNavigation.navigationBar.isHidden = true
//        self.window?.rootViewController = tabBarControllerNavigation
//    }
    
    public func showHome(selectedIndex: Int) {
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
        
        tabBarController.selectedIndex = selectedIndex
        
        tabBarController.tabBar.isTranslucent = false
        
        tabBarController.tabBarItem.imageInsets = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: 0)
        let tabBarControllerNavigation = UINavigationController(rootViewController: tabBarController)
        tabBarControllerNavigation.navigationBar.isHidden = true
        self.window?.rootViewController = tabBarControllerNavigation
    }
}
