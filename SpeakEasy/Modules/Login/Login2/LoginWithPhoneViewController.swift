//
//  LoginWithPhoneViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 13/12/22.
//

import UIKit

class LoginWithPhoneViewController: UIViewController {

    @IBOutlet weak var contryNameLbl: UILabelDeviceClass!
    @IBOutlet weak var contryCodeLbl: UILabelDeviceClass!
    @IBOutlet weak var phoneNumTextField: UITextFieldDeviceClass!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func onClickContryCode(_ sender: Any) {
        let controller = MICountryPicker()
        controller.delegate = self
        controller.showCallingCodes = true
        self.present(controller, animated: true, completion: nil)
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
//        Navigate.to.enterVerificationCodeVc(self,isFromLogin: true)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension LoginWithPhoneViewController: MICountryPickerDelegate{
    func countryPicker(_ picker: MICountryPicker, didSelectCountryWithName name: String, code: String) {
        self.dismiss(animated: true, completion: nil)
    }
    func countryPicker(_ picker: MICountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String) {
        self.contryNameLbl.text = name
        self.contryCodeLbl.text = dialCode
    }
}
