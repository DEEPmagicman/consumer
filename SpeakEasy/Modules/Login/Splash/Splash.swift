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
            finishSplashIfNeeded()
            return
        }
        
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        splashImageView.image = SDAnimatedImage(data: data!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.finishSplashIfNeeded()
        }
    }

    private func finishSplashIfNeeded() {
        guard AppDelegate.shared.window?.rootViewController === self else { return }
        AppDelegate.shared.changeRootViewController()
    }
}
