//
//  Splash.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

import UIKit

final class Splash: UIViewController {
    
    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(resource: .appLogo))
            iv.contentMode = .scaleAspectFit
            iv.alpha = 0
            iv.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            return iv
        }()

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = AppColor.background
            setupUI()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            startAnimation()
        }

        private func setupUI() {
            view.addSubview(logoImageView)
            logoImageView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                logoImageView.widthAnchor.constraint(equalToConstant: 120),
                logoImageView.heightAnchor.constraint(equalToConstant: 120)
            ])
        }
}

//MARK: - Animate Logo
extension Splash {
    
    private func startAnimation() {
        
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                self.logoImageView.alpha = 1
                self.logoImageView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            },
            completion: { _ in
                
                UIView.animate(
                    withDuration: 0.4,
                    delay: 0,
                    options: [.curveEaseInOut],
                    animations: {
                        self.logoImageView.transform = CGAffineTransform.identity
                            .rotated(by: CGFloat.pi / 180 * 3)
                    },
                    completion: { _ in
                        self.exitAnimation()
                    }
                )
            }
        )
    }
    
    private func exitAnimation() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                self.logoImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            },
            completion: { _ in
                AppDelegate.shared.changeRootViewController()
            }
        )
    }
}
