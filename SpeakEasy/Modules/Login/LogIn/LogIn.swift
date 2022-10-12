//
//  LogIn.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/29/22.
//

import UIKit
import RealmSwift

class LogIn: BaseController {

    @IBOutlet weak var lblCountry: UILabelDeviceClass!
    @IBOutlet weak var lblCode: UILabelDeviceClass!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func onBtnLogin(_ sender: UIButton) {
        let user = UserModel()
        AppStateManager.sharedInstance.loginUser(user: user)
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnCode(_ sender: UIButton) {
        let controller = MICountryPicker()
        controller.delegate = self
        controller.showCallingCodes = true
        self.present(controller, animated: true, completion: nil)
    }
}

//MARK:- MICountryPickerDelegate
extension LogIn: MICountryPickerDelegate{
    func countryPicker(_ picker: MICountryPicker, didSelectCountryWithName name: String, code: String) {
        self.dismiss(animated: true, completion: nil)
    }
    func countryPicker(_ picker: MICountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String) {
        self.lblCountry.text = name
        self.lblCode.text = dialCode
    }
}

