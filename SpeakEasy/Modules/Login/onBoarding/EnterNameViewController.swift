//
//  EnterNameViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import UIKit

class EnterNameViewController: UIViewController {

    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var nikNameTextField: UITextField!
    @IBOutlet weak var ContinueBtn: UIButton!
    @IBOutlet weak var firstNameAndLastNameInfo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        firstNameAndLastNameInfo.highlightBold(["Why?"], size: 15, textColor: Constant.Color.primaryColor)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        let name = "Legal name: \(firstNameTextField.text ?? "") \nNickname: \(nikNameTextField.text ?? "")"
        Navigate.to.presentConfirmPopUp(self,text1: Constant.String.confirmInfo,text2: name,text3: Constant.String.nameNote)
    }

}

extension EnterNameViewController: ConfirmPopUpDelegate {
    func confirmDetail() {
        Navigate.to.connectAccountVc(self)
    }
    
}
