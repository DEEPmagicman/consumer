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
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var createAccountBtn: UIButton!
    @IBOutlet weak var signInBtn: UIButton!
    @IBOutlet weak var continueAsGuestBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserDefault.shared.isMvp ?? false {
            self.signInBtn.isHidden = true
            self.continueAsGuestBtn.isHidden = true
            self.createAccountBtn.setTitle("Browse as Guest", for: .normal)
            self.createAccountBtn.backgroundColor = UIColor(hex: "#0B78FF")
            self.byTappingInfoLbl.text = "By tapping ‘CONTINUE AS GUEST’, you attest that you are over the age of 21. This information cannot be changed later."
            self.bgImageView.image = UIImage(named: "mvpBg-img")
        } else {
            self.byTappingInfoLbl.highlightBold(["Terms of Service", "Privacy Policy"], size: 12, textColor: .white, addUnderLine: true)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickInfoLabel(_:)))
            byTappingInfoLbl.addGestureRecognizer(tapGesture)
            byTappingInfoLbl.isUserInteractionEnabled = true
        }
    } 
    
    @objc private func onClickInfoLabel(_ sender: UITapGestureRecognizer) {
        if let range = byTappingInfoLbl.text?.range(of: "Terms of Service")?.nsRange, sender.didTapAttributedTextInLabel(label: byTappingInfoLbl, inRange: range) {
            guard let url = URL(string: "https://speakeasygo.com/terms-consumer") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        if let range = byTappingInfoLbl.text?.range(of: "Privacy Policy")?.nsRange, sender.didTapAttributedTextInLabel(label: byTappingInfoLbl, inRange: range) {
            guard let url = URL(string: "https://speakeasygo.com/privacy-consumer") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func onClickCreateAccount(_ sender: Any) {
        if UserDefault.shared.isMvp ?? false {
            Navigate.to.MVPVenueListViewController(self)
        } else {
            UserDefault.shared.isGuest = false
            Navigate.to.enterPhoneNumVc(self)
        }
    }
    
    @IBAction func onClickSignIn(_ sender: Any) {
        UserDefault.shared.isGuest = false
        Navigate.to.signInOptionVc(self)
    }
    
    @IBAction func onClickAsGuest(_ sender: Any) {
        UserDefault.shared.isGuest = true
        UserDefault.shared.isLoggedIn = true
        AppDelegate.shared.changeRootViewController()
    }
}
