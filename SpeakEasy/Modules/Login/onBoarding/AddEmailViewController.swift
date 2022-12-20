//
//  AddEmailViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import UIKit

final class AddEmailViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var radioBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.radioBtn.isSelected = false
    }
    
    @IBAction func onClickRedioBtn(_ sender: Any) {
        if self.radioBtn.isSelected {
            self.radioBtn.setImage(Constant.Icon.radioIcon, for: .normal)
            self.radioBtn.isSelected = false
        } else {
            self.radioBtn.setImage(Constant.Icon.radioClick, for: .normal)
            self.radioBtn.isSelected = true
        }
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        Navigate.to.createPasswordVc(self)
    }
}
