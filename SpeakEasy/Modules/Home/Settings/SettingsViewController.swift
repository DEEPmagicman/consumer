//
//  SettingsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit

final class SettingsViewController: UIViewController {

    @IBOutlet private weak var versionLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        versionLbl.text = "Version \(Bundle.main.releaseVersionNumber) (\(Bundle.main.buildVersionNumber))"
    }
    
    @IBAction func onClickCancel(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickPayment(_ sender: Any) {
        Navigate.to.paymentMethodsVc(self, selectedId: Constant.String.defaultSelectedPM, isEditable: true)
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
        guard let url = URL(string: APIBuilder.supportURL) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func onClickCustomerSupport(_ sender: Any) {
        guard let url = URL(string: APIBuilder.supportURL) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func onClickFeedback(_ sender: Any) {
        guard let url = URL(string: APIBuilder.supportURL) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func onClickPrivacy(_ sender: Any) {
        guard let url = URL(string: APIBuilder.privacyConsumerURL) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func onClickTermsOfService(_ sender: Any) {
        guard let url = URL(string: APIBuilder.termsConsumerURL) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func onClickLogOut(_ sender: Any) {
        UserDefault.shared.emptyData()
        AppDelegate.shared.changeRootViewController()
    }
}
