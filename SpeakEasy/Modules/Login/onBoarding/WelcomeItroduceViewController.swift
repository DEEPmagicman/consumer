//
//  WelcomeItroduceViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/12/22.
//

import UIKit

final class WelcomeItroduceViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        Navigate.to.setLocationVc(self)
    }
    

}
