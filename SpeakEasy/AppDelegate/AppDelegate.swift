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
    var guestUserLastNavigation: (NavigationDestination, String) = (.appLaunch, "")
    
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
            Navigate.to.connectAccountVc(controller)
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
    
    private func handleForURL(_ url: URL) {
        if url.absoluteString.contains("event") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let queryItems = components.queryItems {
                if let inviteId = queryItems.first(where: { $0.name == "L" })?.value {
                    setRootVC(.inviteLink, id: inviteId)
                    return
                }
                let promoteId = queryItems.first(where: { $0.name == "promoteId" })?.value
                let bookingId = queryItems.first(where: { $0.name == "bookingId" })?.value
                if let bookingId = bookingId {
                    setRootVC(.booking, id: bookingId)
                } else {
                    setRootVC(.event, id: url.lastPathComponent, promoteId: promoteId ?? "")
                }
            } else {
                setRootVC(.event, id: url.lastPathComponent)
            }
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
            return
        }
        if let venue = queryItems.first(where: { $0.name == "v" })?.value {
            setRootVC(.venue, id: venue)
            return
        }
        if let venue = queryItems.first(where: { $0.name == "venueId" })?.value {
            setRootVC(.venue, id: venue)
            return
        }
        if let inviteId = queryItems.first(where: { $0.name == "L" })?.value {
            setRootVC(.inviteLink, id: inviteId)
            return
        }
    }

    private func setRootVC(_ forType: NavigationDestination = .appLaunch, id: String = "", promoteId: String = "") {
        let tabBarController = UITabBarController()
        ReachabilityManager.shared.startMonitoring()
        let home = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPVenueListVc.self)
        home.tabBarItem.image              = UIImage(named :"ic-home")?.withRenderingMode(.alwaysOriginal)
        home.tabBarItem.selectedImage      = UIImage(named :"ic-home1")?.withRenderingMode(.alwaysTemplate)
        home.tabBarItem.standardAppearance?.selectionIndicatorTintColor = .white
        home.tabBarItem.imageInsets = UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0)
        let homeNavigation = UINavigationController(rootViewController: home)
        homeNavigation.navigationBar.isHidden = true
        var myAccount = UIViewController()
        if UserDefault.shared.isGuest == true {
            myAccount = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPStartScreenVC.self)
        } else {
            myAccount = StoryboardAndXibManager.StoryBoard.account.instantiateVC(AccountVC.self)
        }
        myAccount.tabBarItem.image         = UIImage(named :"ic-person")?.withRenderingMode(.alwaysOriginal)
        myAccount.tabBarItem.selectedImage = UIImage(named :"ic-person1")?.withRenderingMode(.alwaysTemplate)
        myAccount.tabBarItem.standardAppearance?.selectionIndicatorTintColor = .red
        UITabBar.appearance().tintColor = .white
        myAccount.tabBarItem.imageInsets = UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0)
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
            if UserDefault.shared.isGuest == false {
                setGuestUserLastNavigation(home)
            }
        case .venue:
            let vc = StoryboardAndXibManager.StoryBoard.home.instantiateVC(MVPVenueDetailVc.self)
            vc.venueUniqueId = id
            vc.isFromAppClip = true
            home.navigationController?.pushViewController(vc, animated: false)
        case .event:
            Navigate.to.eventDetail(home, eventId: id, venueDetail: nil, event: nil, promoteId: promoteId)
        case .inviteLink:
            inviteLinkNav(home, id: id)
        case .booking:
            Navigate.to.showQRCode(home, booking: nil, bookingId: id, type: .singleTickedEvent)
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
}
