//
//  ConnectAccountViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 08/12/22.
//

import MHLoadingButton
import UIKit
import GoogleSignIn
import AuthenticationServices
import JWTDecode

enum SocialType: String {
    case google = "GOOGLE"
    case apple = "APPLE"
}

final class ConnectAccountViewController: UIViewController {
    
    @IBOutlet weak var googleLoginButton: LoadingButton!
    @IBOutlet weak var appleLoginButton: LoadingButton!
    
    var onBoardingDelegate = OnBoardingPresenter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        googleLoginButton.bgColor = .black
        googleLoginButton.indicator = MaterialLoadingIndicator(color: .white)
        appleLoginButton.bgColor = .white
        appleLoginButton.indicator = MaterialLoadingIndicator(color: .black)
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
                Alert.showAlertSheet(style: .alert, title: error.localizedDescription, message: "")
                return
            }
            
            guard let email = user?.profile?.email,
                  let idToken = user?.authentication.idToken else {
                return
            }
            
            // devide token
            let tokenParts = idToken.components(separatedBy: ".")
            let firstPart = tokenParts[0]
            
            self.googleLoginButton.showLoader(userInteraction: false)
            self.view.isUserInteractionEnabled = false
            self.onBoardingDelegate.socialMediaConnectAPi(email: email, socialType: SocialType.google.rawValue, socialId: firstPart ) { [weak self] isSuccess, errorMsg  in
                
                guard let self = self else { return }
                
                self.googleLoginButton.hideLoader()
                self.view.isUserInteractionEnabled = true
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

extension ConnectAccountViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as?  ASAuthorizationAppleIDCredential else {
            Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
            return
        }
        
        let fullName = appleIDCredential.fullName
        if UserDefault.shared.user?.firstName == "" {
            UserDefault.shared.user?.firstName = fullName?.givenName ?? ""
            UserDefault.shared.user?.lastName = fullName?.familyName ?? ""
        }
        
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
            Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
            return
        }
        
        do {
            let jwt = try decode(jwt: identityTokenString)
            let decodedBody = jwt.body as [String: Any]
            
            self.appleLoginButton.showLoader(userInteraction: false)
            self.view.isUserInteractionEnabled = false
            self.onBoardingDelegate.socialMediaConnectAPi(email: decodedBody["email"] as! String, socialType: SocialType.apple.rawValue, socialId: identityTokenString, nonce: decodedBody["nonce"] as? String, firstName: UserDefault.shared.user?.firstName ?? "", lastName: UserDefault.shared.user?.lastName ?? "") { [weak self] isSuccess, errorMsg  in
                guard let self = self else { return }
                
                self.appleLoginButton.hideLoader()
                self.view.isUserInteractionEnabled = true
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
            }
            print("Decoded email: "+(decodedBody["email"] as? String ?? "n/a")   )
        } catch {
            print("decoding failed")
            self.appleLoginButton.hideLoader()
            self.view.isUserInteractionEnabled = true
            Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Alert.showAlertSheet(style: .alert, title: error.localizedDescription, message: "")
        self.appleLoginButton.hideLoader()
        self.view.isUserInteractionEnabled = true
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
