//
//  AppDelegate.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

import UIKit
import GoogleMaps
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var application: UIApplication?
    static let shared: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefault.shared.isMvp = false
        self.application = application
        GMSServices.provideAPIKey(Constants.apiKey)
        
        IQKeyboardManager.shared.enable = true
        
        window = UIWindow(frame:UIScreen.main.bounds)
        launchApplication()
        UIImage(named: "", in: Bundle.FlagIcons, compatibleWith: nil)
        return true
    }
}
//MARK: - Application flow
extension AppDelegate {
    private func launchApplication(){
        let controller = Splash()
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
    }
    func changeRootViewController(){
        if UserDefault.shared.isLoggedIn == true {
            self.showHome(selectedIndex: 0)
        } else {
            self.showOnboarding()
        }
    }
    
    func showOnboarding() {
//        let controller = StartScreenViewController()
        let controller = StoryboardAndXibManager.StoryBoard.onBoarding.instantiateViewController(withIdentifier: IdentifierHelper.getIdentifier(StartScreenViewController.self)) as! StartScreenViewController

//        controller.isHeroEnabled = true
        let tutorialNavigation = UINavigationController(rootViewController: controller)
        tutorialNavigation.navigationBar.isHidden = true
        tutorialNavigation.modalTransitionStyle = .crossDissolve
        tutorialNavigation.modalPresentationStyle = .overCurrentContext
        self.window?.rootViewController = tutorialNavigation

    }
    
    func showTutorials(){
        let controller = Tutorials()
        controller.isHeroEnabled = true
        let tutorialNavigation = UINavigationController(rootViewController: controller)
        tutorialNavigation.navigationBar.isHidden = true
        tutorialNavigation.modalTransitionStyle = .crossDissolve
        tutorialNavigation.modalPresentationStyle = .overCurrentContext
        self.window?.rootViewController = tutorialNavigation

        
//        UIView.transition(with: self.window!, duration: 0.5, options: .transitionFlipFromLeft, animations: {
//        }, completion: nil)
    }
    func showLogin(){
        let controller = LogIn()
        controller.isHeroEnabled = true
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .overCurrentContext
        self.window?.rootViewController = controller
    }
    public func showHome(selectedIndex: Int){
        let tabBarController = UITabBarController()

        let home = Home()
        home.tabBarItem.image              = UIImage(named :"Home")?.withRenderingMode(.alwaysOriginal)
        home.tabBarItem.selectedImage      = UIImage(named :"HomeSelected")?.withRenderingMode(.alwaysOriginal)
        let homeNavigation = UINavigationController(rootViewController: home)
        homeNavigation.navigationBar.isHidden = true

        let bookingsAndInvites = BookingsAndInvites()
        bookingsAndInvites.tabBarItem.image               = UIImage(named :"BookingsAndInvites")?.withRenderingMode(.alwaysOriginal)
        bookingsAndInvites.tabBarItem.selectedImage       = UIImage(named :"BookingsAndInvitesSelected")?.withRenderingMode(.alwaysOriginal)
        let bookingsAndInvitesNavigation = UINavigationController(rootViewController: bookingsAndInvites)
        bookingsAndInvitesNavigation.navigationBar.isHidden = true

        let accessPass = Wallet()
        accessPass.tabBarItem.image               = UIImage(named :"AccessPass")?.withRenderingMode(.alwaysOriginal)
        accessPass.tabBarItem.selectedImage       = UIImage(named :"AccessPassSelected")?.withRenderingMode(.alwaysOriginal)
        let accessPassNavigation = UINavigationController(rootViewController: accessPass)
        accessPassNavigation.navigationBar.isHidden = true

        let statusAndRewards = StatusAndRewards()
        statusAndRewards.tabBarItem.image         = UIImage(named :"StatusAndRewards")?.withRenderingMode(.alwaysOriginal)
        statusAndRewards.tabBarItem.selectedImage = UIImage(named :"StatusAndRewardsSelected")?.withRenderingMode(.alwaysOriginal)
        let statusAndRewardsNavigation = UINavigationController(rootViewController: statusAndRewards)
        statusAndRewardsNavigation.navigationBar.isHidden = true
        
        let myAccount = MyAccount()
        myAccount.tabBarItem.image         = UIImage(named :"MyAccount")?.withRenderingMode(.alwaysOriginal)
        myAccount.tabBarItem.selectedImage = UIImage(named :"MyAccountSelected")?.withRenderingMode(.alwaysOriginal)
        let myAccountNavigation = UINavigationController(rootViewController: myAccount)
        myAccountNavigation.navigationBar.isHidden = true

        tabBarController.viewControllers = [homeNavigation,bookingsAndInvitesNavigation,accessPassNavigation,statusAndRewardsNavigation,myAccountNavigation]
        
        tabBarController.selectedIndex = selectedIndex
        
        tabBarController.tabBar.isTranslucent = false
        
        tabBarController.tabBarItem.imageInsets = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: 0)
        let tabBarControllerNavigation = UINavigationController(rootViewController: tabBarController)
        tabBarControllerNavigation.navigationBar.isHidden = true
        self.window?.rootViewController = tabBarControllerNavigation

    }
}

