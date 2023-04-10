//
//  NotificationViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit

final class NotificationViewController: UIViewController {

    @IBOutlet private weak var notificationBtn: UIButton!

    private var isNotificationOn = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notificationOnOff(notificationOn: isNotificationOn)
    }
    
    private func notificationOnOff(notificationOn: Bool) {
        if notificationOn {
            notificationBtn.setTitleColor(Constant.Color.primaryBlue, for: .normal)
            notificationBtn.backgroundColor = .white
            notificationBtn.setTitle("Turn off Notifications", for: .normal)
        } else {
            notificationBtn.setTitleColor(.white, for: .normal)
            notificationBtn.backgroundColor = Constant.Color.primaryBlue
            notificationBtn.setTitle("Allow Notifications", for: .normal)
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickNotification(_ sender: Any) {
        isNotificationOn.toggle()
        notificationOnOff(notificationOn: isNotificationOn)
    }
}
