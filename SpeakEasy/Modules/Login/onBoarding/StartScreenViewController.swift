//
//  StartScreenViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit
import AVFoundation

final class StartScreenViewController: UIViewController {
    
    @IBOutlet weak var byTappingInfoLbl: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        byTappingInfoLbl.highlightBold(["Terms of Service", "Privacy Policy"], size: 12, textColor: .white, addUnderLine: true)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickInfoLabel(_:)))
        byTappingInfoLbl.addGestureRecognizer(tapGesture)
        byTappingInfoLbl.isUserInteractionEnabled = true
    } 
    
    @objc private func onClickInfoLabel(_ sender: UITapGestureRecognizer) {
        if let range = byTappingInfoLbl.text?.range(of: "Terms of Service")?.nsRange, sender.didTapAttributedTextInLabel(label: byTappingInfoLbl, inRange: range) {
            Navigate.externalURL(APIBuilder.termsConsumerURL)
        }
        
        if let range = byTappingInfoLbl.text?.range(of: "Privacy Policy")?.nsRange, sender.didTapAttributedTextInLabel(label: byTappingInfoLbl, inRange: range) {
            Navigate.externalURL(APIBuilder.privacyConsumerURL)
        }
    }
    
    @IBAction func onClickCreateAccount(_ sender: Any) {
        Navigate.to.enterPhoneNumVc(self)
    }
    
    @IBAction func onClickSignIn(_ sender: Any) {
        Navigate.to.signInOptionVc(self)
    }
    
    @IBAction func onClickAsGuest(_ sender: Any) {
        UserDefault.shared.isGuest = true
        UserDefault.shared.isLoggedIn = true
        AppDelegate.shared.changeRootViewController()
    }
}
