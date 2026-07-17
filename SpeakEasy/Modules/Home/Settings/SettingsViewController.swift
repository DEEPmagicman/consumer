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
        Navigate.externalURL(APIBuilder.supportURL)
    }
    
    @IBAction func onClickCustomerSupport(_ sender: Any) {
        Navigate.externalURL(APIBuilder.supportURL)
    }
    
    @IBAction func onClickFeedback(_ sender: Any) {
        Navigate.externalURL(APIBuilder.supportURL)
    }
    
    @IBAction func onClickPrivacy(_ sender: Any) {
        Navigate.externalURL(APIBuilder.privacyConsumerURL)
    }
    
    @IBAction func onClickTermsOfService(_ sender: Any) {
        Navigate.externalURL(APIBuilder.termsConsumerURL)
    }
    
    @IBAction func onClickLogOut(_ sender: Any) {
        let okAction = UIAlertAction(title: "Yes", style: .default) {
            _ in
            UserDefault.shared.emptyData()
            AppDelegate.shared.changeRootViewController()
            OnBoardingPresenter.logout { _, _ in
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            _ in
        }
        Alert.showAlertSheet(style: .alert, title: "", message: "Are you sure you want to log out?", actions: [okAction, cancelAction])
    }
    
    @IBAction func onClickCreateAccount(_ sender: Any) {
        Navigate.externalURL("https://calendly.com/speakeasygo/discovery?month=2025-08")
    }
}
