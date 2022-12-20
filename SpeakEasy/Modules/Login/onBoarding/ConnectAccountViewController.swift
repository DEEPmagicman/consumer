//
//  ConnectAccountViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import UIKit

final class ConnectAccountViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func onClickConnectWithApple(_ sender: Any) {
        
    }
    
    @IBAction func onClickConnectWithGoogle(_ sender: Any) {
        
    }
    
    @IBAction func onClickSkip(_ sender: Any) {
        Navigate.to.addEmailVc(self)
    }
}
