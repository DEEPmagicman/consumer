//
//  Splash.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

import UIKit
import Hero

class Splash: UIViewController {

    @IBOutlet weak var imgLogo: UIImageView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.animateLogo()
    }
}
//MARK: - Present Tutorial
extension Splash {
    private func presentTutorials(){
        let controller = Tutorials()
        let rootController = UINavigationController(rootViewController: controller)
        rootController.isHeroEnabled = true
        rootController.navigationBar.isHidden = true
        rootController.modalTransitionStyle = .crossDissolve
        rootController.modalPresentationStyle = .overCurrentContext
        self.present(rootController, animated: true, completion: nil)
    }
}
//MARK: - Animate Logo
extension Splash {
    private func animateLogo(){
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
