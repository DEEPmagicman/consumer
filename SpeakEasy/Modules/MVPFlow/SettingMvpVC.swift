//
//  SettingMvpVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 10/02/23.
//

import UIKit

final class SettingMvpVC: UIViewController {

    @IBOutlet private weak var customerSuportView: UIView!
    @IBOutlet private weak var privacyPolicyView: UIView!
    @IBOutlet private weak var termsConditonView: UIView!
    @IBOutlet private weak var versionLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onClickCustomerSupport))
        customerSuportView.addGestureRecognizer(tap1)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(onClickPrivacyPolicy))
        privacyPolicyView.addGestureRecognizer(tap2)
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(onClickTermsConditions))
        termsConditonView.addGestureRecognizer(tap3)
        
        versionLbl.text = "Version \(Bundle.main.releaseVersionNumber) (\(Bundle.main.buildVersionNumber))"
    }

    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func onClickCustomerSupport() {
        guard let url = URL(string: "https://speakeasygo.com/support") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @objc private func onClickPrivacyPolicy() {
        guard let url = URL(string: "https://speakeasygo.com/privacy-consumer") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @objc private func onClickTermsConditions() {
        guard let url = URL(string: "https://speakeasygo.com/terms-consumer") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
