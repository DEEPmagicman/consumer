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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.animateLogo()
    }
}

//MARK: - Animate Logo
extension Splash {
    private func animateLogo() {
        UIView.animate(withDuration: 1.0, animations: {() -> Void in
            self.imgLogo?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }, completion: {(_ finished: Bool) -> Void in
            UIView.animate(withDuration: 1.0, animations: {() -> Void in
                self.imgLogo?.transform = CGAffineTransform(scaleX: 1, y: 1)
            }) { _ in
                sleep(1)
                AppDelegate.shared.changeRootViewController()
            }
        })
    }
}
