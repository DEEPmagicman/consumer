//
//  WelcomeViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/12/22.
//

import UIKit

final class WelcomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
  
    @IBAction func onClickContinue(_ sender: Any) {
        Navigate.to.enterNameVc(self)
    }
    
}
