//
//  SignInOptionViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 13/12/22.
//

import UIKit
import AVFoundation
import GoogleSignIn

class SignInOptionViewController: UIViewController {

    @IBOutlet weak var bgImageView: UIImageView!
    
    var player: AVPlayer?
    var onBoardingDelegate = OnBoardingPresenter()
    
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
        connectWithGoogle()
    }
    
    @IBAction func onClickSignInwithEmail(_ sender: Any) {
        Navigate.to.loginWithEmailVc(self)
    }
    
    @IBAction func onClickSignInwithPhoneNum(_ sender: Any) {
//        Navigate.to.loginWithPhoneNumberVc(self)
        Navigate.to.enterPhoneNumVc(self,isFromLogin: true)
    }
    
    @IBAction func omClickback(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func connectWithGoogle() {
        let clientId =  Constant.String.googleClientId
        
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
            
            if let error = error {
                Alert.showAlertSheet(style: .alert, title: "user Not found", message: "")
                print(error)
                return
            }
            guard let email = user?.profile?.email,
                  let idToken = user?.authentication.idToken
            else {
                return
            }
            self.onBoardingDelegate.socialMediaLoginAPi(email: email, socialType: SocialType.google.rawValue, socialId: idToken) { isSuccess,errorMsg  in
                if isSuccess {
                    let user = UserModel()
                    AppStateManager.sharedInstance.loginUser(user: user)
                } else {
                    if errorMsg != nil {
                        Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                    } else {
                        Alert.showAlertSheet(style: .alert, title: Constant.String.somthingWrong, message: "")
                    }
                }
                Loader.hide()
            }
        }
    }
    
}
