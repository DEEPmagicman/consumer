//
//  SignUpDetailsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 28/02/26.
//

import UIKit

class SignUpDetailsViewController: UIViewController {
    
    @IBOutlet weak var firstNameTextFeild: PhoneNumberTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        self.dismiss(animated: false)
    }
    
    @IBAction func onClickSignUpBtn(_ sender: Any) {
        Navigate.to.loginPopUpVc(self)
    }
}
