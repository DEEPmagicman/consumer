//
//  Splash.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

import UIKit
import Hero

final class Splash: UIViewController {

    @IBOutlet weak var imgLogo: UIImageView!
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logoTopConstraint.constant = (UIScreen.main.bounds.height / 2) - 52
        self.animateLogo()
    }
}

//MARK: - Animate Logo
extension Splash {
    private func animateLogo() {
        UIView.animate(withDuration: 1.0, animations: {() -> Void in
        }, completion: {(_ finished: Bool) -> Void in
                sleep(1)
                AppDelegate.shared.changeRootViewController()
        })
    }
}
