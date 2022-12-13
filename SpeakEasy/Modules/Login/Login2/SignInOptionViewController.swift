//
//  SignInOptionViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 13/12/22.
//

import UIKit
import AVFoundation

class SignInOptionViewController: UIViewController {

    @IBOutlet weak var bgImageView: UIImageView!
    
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        playBackgoundVideo()
    }
    
    private func playBackgoundVideo() {
        if let filePath = Bundle.main.path(forResource: "video", ofType:"mov") {
            let filePathUrl = NSURL.fileURL(withPath: filePath)
            player = AVPlayer(url: filePathUrl)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.bgImageView.bounds
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil) { (_) in
                self.player?.seek(to: CMTime.zero)
                self.player?.play()
            }
            self.bgImageView.layer.addSublayer(playerLayer)
            player?.play()
        }
    }
    
    @IBAction func onClickSignInWithApple(_ sender: Any) {
        
    }
    
    @IBAction func onClickSignInWithGoogle(_ sender: Any) {
        
    }
    
    @IBAction func onClickSignInwithEmail(_ sender: Any) {
        Navigate.to.loginWithEmailVc(self)
    }
    
    @IBAction func onClickSignInwithPhoneNum(_ sender: Any) {
        Navigate.to.loginWithPhoneNumberVc(self)
    }
    
    @IBAction func omClickback(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}
