//
//  MVPStartScreenVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 17/02/23.
//

import UIKit
import AVFoundation

final class MVPStartScreenVC: UIViewController {
    
    @IBOutlet weak var bgImageView: UIImageView!
    
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playBackgroundVideo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // background event
        NotificationCenter.default.addObserver(self, selector: #selector(setPlayerLayerToNil), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // foreground event
        NotificationCenter.default.addObserver(self, selector: #selector(reinitializePlayerLayer), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // add these 2 notifications to prevent freeze on long Home button press and back
        NotificationCenter.default.addObserver(self, selector: #selector(setPlayerLayerToNil), name: UIApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reinitializePlayerLayer), name: UIApplication.didBecomeActiveNotification, object: nil)
        player?.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player?.pause()
        NotificationCenter.default.removeObserver(self)
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
    
    private func playBackgroundVideo() {
        if let filePath = Bundle.main.path(forResource: "bgvideo", ofType:"mov") {
            let filePathUrl = NSURL.fileURL(withPath: filePath)
            player = AVPlayer(url: filePathUrl)
            player?.volume = 0
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

    @IBAction func onClickBtn(_ sender: Any) {
        UserDefault.shared.emptyData()
        AppDelegate.shared.changeRootViewController()
    }
}
