//
//  NotificationPermissionViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/12/22.
//

import UIKit

class NotificationPermissionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func onClickTurnOnNotification(_ sender: Any) {
        
    }
    
    @IBAction func onClickSkip(_ sender: Any) {
        Navigate.to.welcomeItroduceVc(self)
    }
}
