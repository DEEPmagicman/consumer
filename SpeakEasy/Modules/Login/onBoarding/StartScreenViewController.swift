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

//    var player: AVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // background event
//           NotificationCenter.default.addObserver(self, selector: #selector(setPlayerLayerToNil), name: UIApplication.didEnterBackgroundNotification, object: nil)
//
//           // foreground event
//           NotificationCenter.default.addObserver(self, selector: #selector(reinitializePlayerLayer), name: UIApplication.willEnterForegroundNotification, object: nil)
//
//          // add these 2 notifications to prevent freeze on long Home button press and back
//           NotificationCenter.default.addObserver(self, selector: #selector(setPlayerLayerToNil), name: UIApplication.willResignActiveNotification, object: nil)
//
//           NotificationCenter.default.addObserver(self, selector: #selector(reinitializePlayerLayer), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if UserDefault.shared.isMvp ?? false {
            self.signInBtn.isHidden = true
            self.continueAsGuestBtn.isHidden = true
            self.createAccountBtn.setTitle("Browse as Guest", for: .normal)
            self.createAccountBtn.backgroundColor = UIColor(hex: "#0B78FF")
            self.byTappingInfoLbl.text = "By tapping ‘CONTINUE AS GUEST’, you attest that you are over the age of 21. This information cannot be changed later."
            self.bgImageView.image = UIImage(named: "mvpBg-img")
        } else {
            self.byTappingInfoLbl.highlightBold(["Terms of Service","Privacy Policy","Cookies Policy."], size: 12, textColor: .white, addUnderLine: true)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickInfoLabel(_:)))
            byTappingInfoLbl.addGestureRecognizer(tapGesture)
            byTappingInfoLbl.isUserInteractionEnabled = true
//            playBackgroundVideo()
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
    
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
//
//    @objc func setPlayerLayerToNil() {
//        player?.pause()
//    }
//
//    @objc func reinitializePlayerLayer() {
//        player?.play()
//    }
//
//    private func playBackgroundVideo() {
//        if let filePath = Bundle.main.path(forResource: "bgvideo", ofType:"mov") {
//            let filePathUrl = NSURL.fileURL(withPath: filePath)
//            player = AVPlayer(url: filePathUrl)
//            player?.volume = 0
//            let playerLayer = AVPlayerLayer(player: player)
//            playerLayer.frame = self.bgImageView.bounds
//            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil) { [weak self] (_) in
//                self?.player?.seek(to: CMTime.zero)
//                self?.player?.play()
//            }
//            self.bgImageView.layer.addSublayer(playerLayer)
//            player?.play()
//        }
//    }
    
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
