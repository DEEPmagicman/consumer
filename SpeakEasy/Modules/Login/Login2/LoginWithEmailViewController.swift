//
//  LoginWithEmailViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 13/12/22.
//

import UIKit

class LoginWithEmailViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    

    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        Navigate.to.enterEmailPassVc(self)
    }
    
}
