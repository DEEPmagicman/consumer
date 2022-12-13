//
//  StartScreenViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit

class StartScreenViewController: UIViewController {
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
//        Navigate.to.notificationPermissionVc(self)
    }
    
    @IBAction func onClickCreateAccount(_ sender: Any) {
        Navigate.to.enterPhoneNumVc(self)
    }
    
    @IBAction func onClickSignIn(_ sender: Any) {
        Navigate.to.signInOptionVc(self)
    }
    
    @IBAction func onClickAsGuest(_ sender: Any) {
        
    }
}
