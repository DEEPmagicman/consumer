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
        connectWithApple()
    }
    
    @IBAction func onClickConnectWithGoogle(_ sender: Any) {
        connectWithGoogle()
    }
    
    @IBAction func onClickSkip(_ sender: Any) {
        Navigate.to.enterNameVc(self)
    }
    
    func connectWithGoogle() {
        let clientId = Constant.String.googleClientId
        
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
            
            if let error = error {
                print(error)
                return
            }
            guard let email = user?.profile?.email,
                  let idToken = user?.authentication.idToken else {
                return
            }
            
            //devide token
            let tokenParts = idToken.components(separatedBy: ".")
            let firstPart = tokenParts[0]

            self.onBoardingDelegate.socialMediaConnectAPi(email: email, socialType: SocialType.google.rawValue, socialId:firstPart ) { [weak self] isSuccess, errorMsg  in
                guard let self = self else { return }
                
                if isSuccess {
                    UserDefault.shared.user?.email = email
                    Navigate.to.enterNameVc(self)
                } else {
                    if errorMsg != nil {
                        Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                    } else {
                        Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                    }
                }
            }
        }
    }
    
    private func connectWithApple() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = UUID().uuidString
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
}

extension ConnectAccountViewController: ASAuthorizationControllerDelegate{
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as?  ASAuthorizationAppleIDCredential {
        let fullName = appleIDCredential.fullName
        if UserDefault.shared.user?.firstName == "" {
            UserDefault.shared.user?.firstName = fullName?.givenName ?? ""
            UserDefault.shared.user?.lastName = fullName?.familyName ?? ""
        }
        if let identityTokenData = appleIDCredential.identityToken,
            let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
            do {
               let jwt = try decode(jwt: identityTokenString)
               let decodedBody = jwt.body as Dictionary<String, Any>
                self.onBoardingDelegate.socialMediaConnectAPi(email: decodedBody["email"] as! String, socialType: SocialType.apple.rawValue, socialId: identityTokenString, nonce: decodedBody["nonce"] as? String, firstName: UserDefault.shared.user?.firstName ?? "", lastName: UserDefault.shared.user?.lastName ?? "") { [weak self] isSuccess,errorMsg  in
                    guard let self = self else {
                        Loader.hide()
                        return
                    }
                    if isSuccess {
                        UserDefault.shared.user?.email = decodedBody["email"] as? String ?? ""
                        Navigate.to.enterNameVc(self)
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
