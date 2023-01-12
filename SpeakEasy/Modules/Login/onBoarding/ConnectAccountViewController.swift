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
         let clientId = Constant.String.googleClientId
        
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
            self.onBoardingDelegate.socialMediaConnectAPi(email: email, socialType: SocialType.google.rawValue, socialId: idToken) { isSuccess,errorMsg  in
                if isSuccess {
                    Navigate.to.dateOfBirthVc(self)
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
}
