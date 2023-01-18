//
//  ConnectAccountViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import UIKit
import GoogleSignIn
import AuthenticationServices
import JWTDecode

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
        self.connectWithApple()
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
//                Alert.showAlertSheet(style: .alert, title: "user Not found", message: "")
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
    
    private func connectWithApple() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
}

extension ConnectAccountViewController: ASAuthorizationControllerDelegate{
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as?  ASAuthorizationAppleIDCredential {
    let userIdentifier = appleIDCredential.user
    let fullName = appleIDCredential.fullName
    let email = appleIDCredential.email
        if let identityTokenData = appleIDCredential.identityToken,
            let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
            do {
               let jwt = try decode(jwt: identityTokenString)
               let decodedBody = jwt.body as Dictionary<String, Any>
                self.onBoardingDelegate.socialMediaConnectAPi(email: decodedBody["email"] as! String, socialType: SocialType.apple.rawValue, socialId: identityTokenString) { isSuccess,errorMsg  in
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
