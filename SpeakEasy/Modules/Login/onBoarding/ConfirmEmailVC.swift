//
//  ConfirmEmailVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 04/04/23.
//

import UIKit

final class ConfirmEmailVC: UIViewController {

    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var checkBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
        checkBtn.setImage(Constant.Icon.radioClick, for: .normal)
        checkBtn.setImage(Constant.Icon.radioIcon, for: .selected)
    }

    @IBAction func onClickCheckBtn(_ sender: UIButton) {
        sender.isSelected.toggle()
    }

    @IBAction func onClickCancelBtn(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func onClickContinueBtn(_ sender: Any) {
        
    }
}
