//
//  Splash.swift
//  SpeakEasy
//
//  Created by M.Usman Bin Rehan on 7/1/22.
//

import UIKit
import Lottie

final class Splash: UIViewController {
    
    private enum Animation {
        static let endFrame: AnimationFrameTime = 176
        static let speed: CGFloat = 1.35
    }
    
    private let animationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "Splash")
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.animationSpeed = Animation.speed
        animationView.backgroundBehavior = .pauseAndRestore
        return animationView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        setupUI()
        playSplashAnimation()
    }
    
    private func setupUI() {
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func playSplashAnimation() {
        guard animationView.animation != nil else {
            finishSplashIfNeeded()
            return
        }
        
        animationView.play(fromFrame: 0, toFrame: Animation.endFrame, loopMode: .playOnce) { [weak self] _ in
            self?.finishSplashIfNeeded()
        }
    }

    private func finishSplashIfNeeded() {
        guard AppDelegate.shared.window?.rootViewController === self else { return }
        AppDelegate.shared.changeRootViewController()
    }
}
