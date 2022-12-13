//
//  ResetPasswordViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 13/12/22.
//

import UIKit

class ResetPasswordViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onClickSendResetLink(_ sender: Any) {
        
    }
    
}
