//
//  ConnectAccountViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import UIKit
import GoogleSignIn

enum SocialType: String {
    case google = "GOOGLE"
    case apple = "APPLE"
}

final class ConnectAccountViewController: UIViewController {
    
    var onBoardingDelegate = OnBoardingPresenter()

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func onClickConnectWithApple(_ sender: Any) {
        Navigate.to.dateOfBirthVc(self)
    }
    
    @IBAction func onClickConnectWithGoogle(_ sender: Any) {
        connectWithGoogle()
    }
    
    @IBAction func onClickSkip(_ sender: Any) {
        Navigate.to.addEmailVc(self)
    }
    
    func connectWithGoogle() {
         let clientId =  "971202288158-r8r0iep0ignr8nub82bijdfu488b1lqc.apps.googleusercontent.com"
        
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
            self.onBoardingDelegate.socialMediaConnectAPi(email: email, socialType: SocialType.google.rawValue, socialId: idToken) { isSuccess in
                if isSuccess {
                    Navigate.to.dateOfBirthVc(self)
                } else {
                    Alert.showAlertSheet(style: .alert, title: "google account not update", message: "")
                }
                Loader.hide()
            }
        }
    }
}
