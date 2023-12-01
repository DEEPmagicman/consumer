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
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var animateLayoutView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logoTopConstraint.constant = (UIScreen.main.bounds.height / 2) - 52
        animateLayoutView.isHidden = true
        byTappingInfoLbl.highlightBold(["Terms of Service", "Privacy Policy", "Cookies Policy"], size: 12, textColor: .white, addUnderLine: true)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickInfoLabel(_:)))
        byTappingInfoLbl.addGestureRecognizer(tapGesture)
        byTappingInfoLbl.isUserInteractionEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateImage()
    }
    
    private func animateImage() {
        self.animateLayoutView.isHidden = false
        UIView.animate(withDuration: 2.0) {
            self.logoTopConstraint.constant = 72
            self.animateLayoutView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.animateLayoutView.isHidden = true
        }
    }
    
    @objc private func onClickInfoLabel(_ sender: UITapGestureRecognizer) {
        if let range = byTappingInfoLbl.text?.range(of: "Terms of Service")?.nsRange, sender.didTapAttributedTextInLabel(label: byTappingInfoLbl, inRange: range) {
            Navigate.externalURL(APIBuilder.termsConsumerURL)
        }
        
        if let range = byTappingInfoLbl.text?.range(of: "Privacy Policy")?.nsRange, sender.didTapAttributedTextInLabel(label: byTappingInfoLbl, inRange: range) {
            Navigate.externalURL(APIBuilder.privacyConsumerURL)
        }
        
        if let range = byTappingInfoLbl.text?.range(of: "Cookies Policy")?.nsRange, sender.didTapAttributedTextInLabel(label: byTappingInfoLbl, inRange: range) {
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
