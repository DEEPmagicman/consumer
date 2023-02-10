//
//  SettingMvpVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 10/02/23.
//

import UIKit

class SettingMvpVC: UIViewController {

    @IBOutlet weak var customerSuportView: UIView!
    @IBOutlet weak var privacyPolicyView: UIView!
    @IBOutlet weak var termsConditonView: UIView!
    @IBOutlet weak var versionLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onClickCustomerSuppert))
        self.customerSuportView.addGestureRecognizer(tap1)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(onClickPrivacyPolicy))
        self.privacyPolicyView.addGestureRecognizer(tap2)
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(onClickTermsConditions))
        self.termsConditonView.addGestureRecognizer(tap3)
        
        versionLbl.text = "Version \(Bundle.main.releaseVersionNumber) (\(Bundle.main.buildVersionNumber))"
    }

    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onClickCustomerSuppert() {
        guard let url = URL(string: "https://www.hackingwithswift.com") else { return }
         UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @objc func onClickPrivacyPolicy() {
        guard let url = URL(string: "Google.com") else { return }
         UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @objc func onClickTermsConditions() {
        guard let url = URL(string: "google.com") else { return }
         UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension Bundle {
  var releaseVersionNumber: String {
    return infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
  }
  var buildVersionNumber: String {
    return infoDictionary?["CFBundleVersion"] as? String ?? ""
  }
}

