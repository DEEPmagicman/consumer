//
//  NotificationPermissionViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/12/22.
//

import UIKit

final class NotificationPermissionViewController: UIViewController, UNUserNotificationCenterDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func onClickTurnOnNotification(_ sender: Any) {
        allowNotification()
    }
    
    private func allowNotification() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { _, _ in
                    DispatchQueue.main.async {
                        Navigate.to.welcomeItroduceVc(self)
                    }
                }
            )
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.application?.registerUserNotificationSettings(settings)
            }
        }
    }
    
    @IBAction func onClickSkip(_ sender: Any) {
        Navigate.to.welcomeItroduceVc(self)
    }
}
