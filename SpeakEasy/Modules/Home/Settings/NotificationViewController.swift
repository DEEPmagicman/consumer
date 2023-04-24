//
//  NotificationViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit

class NotificationViewController: UIViewController {

    @IBOutlet weak var notificationBtn: UIButton!
    private var notificationOn = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notificationOnOff(notificationOn: notificationOn)
    }
    
    func notificationOnOff(notificationOn: Bool) {
        if notificationOn {
            notificationBtn.setTitleColor(.white, for: .normal)
            notificationBtn.backgroundColor = .black
            notificationBtn.borderColor = .white
            notificationBtn.borderWidth = 1
            notificationBtn.setTitle("Turn off Notifications", for: .normal)
        } else {
            notificationBtn.backgroundColor = .white
            notificationBtn.borderWidth = 0
            notificationBtn.setTitle("Turn on Notifications", for: .normal)
            notificationBtn.setTitleColor(.black, for: .normal)
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickNotification(_ sender: Any) {
        notificationOnOff(notificationOn: !notificationOn)
        notificationOn = !notificationOn
    }
}
