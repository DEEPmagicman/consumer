//
//  Splash.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

import UIKit

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
        self.view.layoutIfNeeded()
        UIView.animate(
            withDuration: 0.8,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                self.imgLogo.alpha = 0
                self.imgLogo.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            },
            completion: { _ in
                AppDelegate.shared.changeRootViewController()
            }
        )
    }
}
