//
//  SettingsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var logoutBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefault.shared.isGuest == true {
            logoutBtn.setAttributedTitle(NSAttributedString(string: "Log In", attributes: [
                NSAttributedString.Key.underlineStyle: NSUnderlineStyle.thick.rawValue
                ]), for: .normal)
        }
    }
    
    @IBAction func onClickCancel(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickPayment(_ sender: Any) {
        Navigate.to.paymentMethodsVc(self)
    }
    
    @IBAction func onClickPersonalInfo(_ sender: Any) {
        Navigate.to.personalInformationVc(self)
    }
    
    @IBAction func onClickPurchases(_ sender: Any) {
        Navigate.to.pastPurchasesVisitsVc(self)
    }
    
    @IBAction func onClickNotifications(_ sender: Any) {
        Navigate.to.notificationVc(self)
    }
    
    @IBAction func onClickDelete(_ sender: Any) {
        Navigate.to.deleteAccountVc(self)
    }
    
    @IBAction func onClickFAQ(_ sender: Any) {
        
    }
    
    @IBAction func onClickCustomerSupport(_ sender: Any) {
        
    }
    
    @IBAction func onClickFeedback(_ sender: Any) {
        
    }
    
    @IBAction func onClickPrivacy(_ sender: Any) {
        
    }
    
    @IBAction func onClickTermsOfService(_ sender: Any) {
    }
    
    @IBAction func onClickLogOut(_ sender: Any) {
        UserDefault.shared.isLoggedIn = false
        UserDefault.shared.isGuest = false
        AppDelegate.shared.changeRootViewController()
    }
}
