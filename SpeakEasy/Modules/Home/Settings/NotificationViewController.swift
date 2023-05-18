//
//  NotificationViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit

final class NotificationViewController: UIViewController, UNUserNotificationCenterDelegate {

    @IBOutlet private weak var notificationBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notificationOnOff(notificationOn: UserDefault.shared.isNotificationOn)
    }
    
    private func notificationOnOff(notificationOn: Bool) {
        DispatchQueue.main.async {
            if notificationOn {
                self.notificationBtn.setTitleColor(Constant.Color.primaryBlue, for: .normal)
                self.notificationBtn.backgroundColor = .white
                self.notificationBtn.setTitle("Turn off Notifications", for: .normal)
            } else {
                self.notificationBtn.setTitleColor(.white, for: .normal)
                self.notificationBtn.backgroundColor = Constant.Color.primaryBlue
                self.notificationBtn.setTitle("Allow Notifications", for: .normal)
            }
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickNotification(_ sender: Any) {
        if UserDefault.shared.isNotificationOn == false {
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().delegate = self
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: { isAllowed, _ in
                        UserDefault.shared.isNotificationOn = isAllowed
                        self.notificationOnOff(notificationOn: UserDefault.shared.isNotificationOn)
                    }
                )
            } else {
                let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    appDelegate.application?.registerUserNotificationSettings(settings)
                }
                UserDefault.shared.isNotificationOn = true
                notificationOnOff(notificationOn: UserDefault.shared.isNotificationOn)
            }
        } else {
            UIApplication.shared.unregisterForRemoteNotifications()
            UserDefault.shared.isNotificationOn = false
            notificationOnOff(notificationOn: UserDefault.shared.isNotificationOn)
        }
    }
}
