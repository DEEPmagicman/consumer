//
//  SignInOptionViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 13/12/22.
//

import UIKit
import AVFoundation
import GoogleSignIn
import AuthenticationServices
import JWTDecode

class SignInOptionViewController: UIViewController {

    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var byTappingInfoLbl: UILabel!
    
    var player: AVPlayer?
    var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
//        playBackgoundVideo()
        self.byTappingInfoLbl.highlightBold(["Terms of Service","Privacy Policy","Cookies Policy."], size: 15, textColor: .white, addUnderLine: true)
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
        connectWithApple()
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
//                Alert.showAlertSheet(style: .alert, title: "user Not found", message: "")
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
                        Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                    }
                }
                Loader.hide()
            }
        }
    }
    
    private func connectWithApple() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
}

extension SignInOptionViewController: ASAuthorizationControllerDelegate{
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as?  ASAuthorizationAppleIDCredential {
    let userIdentifier = appleIDCredential.user
    let fullName = appleIDCredential.fullName
    let email = appleIDCredential.email
    print("User id is \(userIdentifier) \n Full Name is \(String(describing: fullName)) \n Email id is \(String(describing: email))")
        if let identityTokenData = appleIDCredential.identityToken,
            let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
            print("Identity Token \(identityTokenString)")
            do {
               let jwt = try decode(jwt: identityTokenString)
               let decodedBody = jwt.body as Dictionary<String, Any>
                self.onBoardingDelegate.socialMediaLoginAPi(email: decodedBody["email"] as! String, socialType: SocialType.apple.rawValue, socialId: identityTokenString) { isSuccess,errorMsg  in
                    if isSuccess {
                        let user = UserModel()
                        AppStateManager.sharedInstance.loginUser(user: user)
                    } else {
                        if errorMsg != nil {
                            Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                        } else {
                            Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                        }
                    }
                    Loader.hide()
                }
               print(decodedBody)
               print("Decoded email: "+(decodedBody["email"] as? String ?? "n/a")   )
            } catch {
               print("decoding failed")
            }
        }
    }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
