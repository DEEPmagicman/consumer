//
//  Splash.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

import UIKit
import SDWebImage

final class Splash: UIViewController {

    private let splashImageView: SDAnimatedImageView = {
        let imageView = SDAnimatedImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppColor.background
        setupUI()
        loadGIF()
    }

    private func setupUI() {
        view.addSubview(splashImageView)
        splashImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            splashImageView.topAnchor.constraint(equalTo: view.topAnchor),
            splashImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splashImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splashImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadGIF() {
        guard let path = Bundle.main.path(forResource: "SplashAnimation", ofType: "gif") else {
            AppDelegate.shared.changeRootViewController()
            return
        }

        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        splashImageView.image = SDAnimatedImage(data: data)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            AppDelegate.shared.changeRootViewController()
        }
    }
}

//final class Splash: UIViewController {
//    
//    private let logoImageView: UIImageView = {
//        let iv = UIImageView(image: UIImage(resource: .appLogo))
//            iv.contentMode = .scaleAspectFit
//            iv.alpha = 0
//            iv.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
//            return iv
//        }()
//
//        override func viewDidLoad() {
//            super.viewDidLoad()
//            view.backgroundColor = AppColor.background
//            setupUI()
//        }
//
//        override func viewDidAppear(_ animated: Bool) {
//            super.viewDidAppear(animated)
//            startAnimation()
//        }
//
//        private func setupUI() {
//            view.addSubview(logoImageView)
//            logoImageView.translatesAutoresizingMaskIntoConstraints = false
//
//            NSLayoutConstraint.activate([
//                logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//                logoImageView.widthAnchor.constraint(equalToConstant: 110),
//                logoImageView.heightAnchor.constraint(equalToConstant: 110)
//            ])
//        }
//}
//
//// MARK: - Animate Logo
//extension Splash {
//    
//    private func startAnimation() {
//        
//        UIView.animate(
//            withDuration: 0.6,
//            delay: 0,
//            options: [.curveEaseOut],
//            animations: {
//                self.logoImageView.alpha = 1
//                self.logoImageView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
//            },
//            completion: { _ in
//                
//                UIView.animate(
//                    withDuration: 0.4,
//                    delay: 0,
//                    options: [.curveEaseInOut],
//                    animations: {
//                        self.logoImageView.transform = CGAffineTransform.identity
//                            .rotated(by: CGFloat.pi / 180 * 3)
//                    },
//                    completion: { _ in
//                        self.exitAnimation()
//                    }
//                )
//            }
//        )
//    }
//    
//    private func exitAnimation() {
//        UIView.animate(
//            withDuration: 0.55,
//            delay: 0,
//            options: [.curveEaseIn],
//            animations: {
//                self.logoImageView.transform = CGAffineTransform(
//                    scaleX: 50,
//                    y: 50
//                )
//            }
//        )
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
//            AppDelegate.shared.changeRootViewController()
//        }
//    }
//}
