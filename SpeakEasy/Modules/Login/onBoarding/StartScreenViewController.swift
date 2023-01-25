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
    var player: AVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // background event
           NotificationCenter.default.addObserver(self, selector: #selector(setPlayerLayerToNil), name: UIApplication.didEnterBackgroundNotification, object: nil)

           // foreground event
           NotificationCenter.default.addObserver(self, selector: #selector(reinitializePlayerLayer), name: UIApplication.willEnterForegroundNotification, object: nil)

          // add these 2 notifications to prevent freeze on long Home button press and back
           NotificationCenter.default.addObserver(self, selector: #selector(setPlayerLayerToNil), name: UIApplication.willResignActiveNotification, object: nil)

           NotificationCenter.default.addObserver(self, selector: #selector(reinitializePlayerLayer), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        playBackgoundVideo()
        self.byTappingInfoLbl.highlightBold(["Terms of Service","Privacy Policy","Cookies Policy."], size: 15, textColor: .white, addUnderLine: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func setPlayerLayerToNil(){
        player?.pause()
    }
    
    @objc func reinitializePlayerLayer(){
        player?.play()
    }
    
    private func playBackgoundVideo() {
        if let filePath = Bundle.main.path(forResource: "video", ofType:"mp4") {
            let filePathUrl = NSURL.fileURL(withPath: filePath)
            player = AVPlayer(url: filePathUrl)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.bgImageView.bounds
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil) { [weak self] (_) in
                self?.player?.seek(to: CMTime.zero)
                self?.player?.play()
            }
            self.bgImageView.layer.addSublayer(playerLayer)
            player?.play()
        }
    }
    
    @IBAction func onClickCreateAccount(_ sender: Any) {
        UserDefault.shared.isGuest = false
        Navigate.to.enterPhoneNumVc(self)
    }
    
    @IBAction func onClickSignIn(_ sender: Any) {
        UserDefault.shared.isGuest = false
        Navigate.to.signInOptionVc(self)
    }
    
    @IBAction func onClickAsGuest(_ sender: Any) {
        UserDefault.shared.isGuest = true
        Navigate.to.presentConfirmPopUp(self, text1: Constant.String.confirm21YearText, text2: "", text3: Constant.String.over21Info, isFromLoginasGuest: true)
    }
}

extension StartScreenViewController: ConfirmPopUpDelegate {
    func cancelDetail() {
        
    }
    
    func confirmDetail() {
        UserDefault.shared.isLoggedIn = true
        AppDelegate.shared.changeRootViewController()
    }
}
