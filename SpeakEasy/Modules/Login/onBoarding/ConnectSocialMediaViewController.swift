//
//  ConnectSocialMediaViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 12/12/22.
//

import UIKit
import WebKit

final class ConnectSocialMediaViewController: UIViewController {

    @IBOutlet weak var connectSpotifyBtn: UIButton!
    @IBOutlet weak var connectedSpotifyView: UIView!
    @IBOutlet weak var connectInstagramBtn: UIButton!
    @IBOutlet weak var connectedInstagramView: UIView!
    @IBOutlet weak var getStartedBtn: UIButton!
    @IBOutlet weak var spotifyPrivetView: UIView!
    @IBOutlet weak var spotifyPublicView: UIView!
    @IBOutlet weak var spotifyPrivetLbl: UILabelDeviceClass!
    @IBOutlet weak var spotifyPrivetLine: UIView!
    @IBOutlet weak var spotifyPublicLbl: UILabelDeviceClass!
    @IBOutlet weak var spotifyPublicLine: UIView!
    @IBOutlet weak var instagramPrivetView: UIView!
    @IBOutlet weak var instagramPublicView: UIView!
    @IBOutlet weak var instagramPrivetLbl: UILabelDeviceClass!
    @IBOutlet weak var instagramPrivetLine: UIView!
    @IBOutlet weak var instagramPublicLbl: UILabelDeviceClass!
    @IBOutlet weak var instagramPublicLine: UIView!
    @IBOutlet weak var skipBtn: UIButton!
    
    var spotifyConnect = false
    var webView = WKWebView()
    var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.connectSpotifyBtn.isHidden = false
        self.connectedSpotifyView.isHidden = true
        if UserDefault.shared.user?.instagramToken != "" && UserDefault.shared.user?.instagramToken != nil {
            self.connectInstagramBtn.isHidden = true
            self.connectedInstagramView.isHidden = false
            self.getStartedBtn.isHidden = false
        } else {
            self.connectInstagramBtn.isHidden = false
            self.connectedInstagramView.isHidden = true
            self.getStartedBtn.isHidden = true
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickspotifypublicView))
        self.spotifyPublicView.addGestureRecognizer(tap)
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onClickspotifyPrivetView))
        self.spotifyPrivetView.addGestureRecognizer(tap1)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(onClickInstagramPrivet))
        self.instagramPrivetView.addGestureRecognizer(tap2)
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(onClickInstagramPublic))
        self.instagramPublicView.addGestureRecognizer(tap3)

        self.skipBtn.isHidden = false
    }
    
    @IBAction func onClickSkip(_ sender: Any) {
        Navigate.to.tutorialVc(self)
    }
    
    @IBAction func onClickGetStarted(_ sender: Any) {
        Navigate.to.tutorialVc(self)
    }
    
    @IBAction func onClickConnectWithSpotify(_ sender: Any) {
        spotifyAuthVC()
    }
    
    @IBAction func onClickConnectWithInstagram(_ sender: Any) {
        Navigate.to.instagramWebView(self)
    }
    
    func spotifyConnected() {
        self.connectSpotifyBtn.isHidden = true
        self.connectedSpotifyView.isHidden = false
        self.getStartedBtn.isHidden = false
    }
    
    func instagramConnected() {
        self.connectInstagramBtn.isHidden = true
        self.connectedInstagramView.isHidden = false
        self.getStartedBtn.isHidden = false
    }
    
    @objc func onClickspotifyPrivetView () {
        self.spotifyPrivetLbl.textColor = .white
        self.spotifyPrivetLbl.isShadowed = true
        self.spotifyPublicLbl.isShadowed = false
        self.spotifyPrivetLine.isHidden = false
        self.spotifyPublicLbl.textColor = Global.APP_COLOR_DARK_GREY
        self.spotifyPublicLine.isHidden = true
        self.spotifyPrivetLbl.layoutSubviews()
        self.spotifyPublicLbl.layoutSubviews()
    }
    
    @objc func onClickspotifypublicView () {
        self.spotifyPrivetLbl.textColor = Global.APP_COLOR_DARK_GREY
        self.spotifyPrivetLine.isHidden = true
        self.spotifyPublicLbl.textColor = .white
        self.spotifyPublicLine.isHidden = false
        self.spotifyPrivetLbl.isShadowed = false
        self.spotifyPublicLbl.isShadowed = true
        self.spotifyPrivetLbl.layoutSubviews()
        self.spotifyPublicLbl.layoutSubviews()
    }
    
    @objc func onClickInstagramPrivet() {
        self.instagramPrivetLbl.textColor = .white
        self.instagramPrivetLine.isHidden = false
        self.instagramPublicLbl.textColor = Global.APP_COLOR_DARK_GREY
        self.instagramPublicLine.isHidden = true
        self.instagramPrivetLbl.isShadowed = true
        self.instagramPublicLbl.isShadowed = false
    }
    
    @objc func onClickInstagramPublic() {
        self.instagramPrivetLbl.textColor = Global.APP_COLOR_DARK_GREY
        self.instagramPrivetLine.isHidden = true
        self.instagramPublicLbl.textColor = .white
        self.instagramPublicLine.isHidden = false
        self.instagramPrivetLbl.isShadowed = false
        self.instagramPublicLbl.isShadowed = true
    }
    
    func spotifyAuthVC() {
        
        // Create Spotify Auth ViewController
        let spotifyVC = UIViewController()
        // Create WebView
        let webView = WKWebView()
        webView.navigationDelegate = self
        spotifyVC.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: spotifyVC.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: spotifyVC.view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: spotifyVC.view.bottomAnchor),
            webView.trailingAnchor.constraint(equalTo: spotifyVC.view.trailingAnchor)
        ])
        
        let authURLFull = APIBuilder.spotifyAuthUrl
        
        let urlRequest = URLRequest.init(url: URL.init(string: authURLFull)!)
        webView.load(urlRequest)
        
        // Create Navigation Controller
        let navController = UINavigationController(rootViewController: spotifyVC)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelAction))
        spotifyVC.navigationItem.leftBarButtonItem = cancelButton
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAction))
        spotifyVC.navigationItem.rightBarButtonItem = refreshButton
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navController.navigationBar.titleTextAttributes = textAttributes
        spotifyVC.navigationItem.title = "spotify.com"
        navController.navigationBar.isTranslucent = false
        navController.navigationBar.tintColor = UIColor.white
        navController.navigationBar.barTintColor = UIColor.black
        navController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        navController.modalTransitionStyle = .coverVertical
        
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc func cancelAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func refreshAction() {
        self.webView.reload()
    }

}

extension ConnectSocialMediaViewController: ConfirmPopUpDelegate {
    func cancelDetail() {
        if spotifyConnect {
            self.spotifyConnected()
            self.onClickspotifyPrivetView()
        } else {
            self.instagramConnected()
            self.onClickInstagramPrivet()
        }
        self.skipBtn.isHidden = true
    }
    
    func confirmDetail() {
        if spotifyConnect {
            self.spotifyConnected()
            self.onClickspotifypublicView()
        } else {
            self.instagramConnected()
            self.onClickInstagramPublic()
        }
        self.skipBtn.isHidden = true
    }
}

extension ConnectSocialMediaViewController: InstagramConnectedDelegate {
    func instaConnect() {
        let tokan = UserDefault.shared.user?.instagramToken ?? ""
        InstagramManager.urlExecute(url: String(format: APIBuilder.INSTAGRAMUSERNAME, tokan)) { respons,isSuccess  in
            if isSuccess {
                if let response = respons as? NSDictionary {
                    let data = response["data"] as? NSArray
                    let val = data?[0] as? [String : String]
                    UserDefault.shared.user?.instaUserName = val?["username"] ?? ""
                } else { return }
                Navigate.to.presentConfirmPopUp(self, text1: Constant.String.privetOrPublicInfo, text2: "@\(UserDefault.shared.user?.instaUserName ?? "@realamitpaul")", text3: Constant.String.changesLaterInfo,isYesOrNoBtn: true)
                self.spotifyConnect = false
                self.onBoardingDelegate.editUserProfileApi(instagramToken: tokan) { isSuccess, errorMsg in
                    if isSuccess {
                        print(tokan)
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
}

extension ConnectSocialMediaViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        RequestForCallbackURL(request: navigationAction.request)
        decisionHandler(.allow)
    }

    func RequestForCallbackURL(request: URLRequest) {
        // Get the access token string after the '#access_token=' and before '&token_type='
        let requestURLString = (request.url?.absoluteString)! as String
        if requestURLString.hasPrefix(APIBuilder.REDIRECT_URI) {
            if requestURLString.contains("#access_token=") {
                if let range = requestURLString.range(of: "=") {
                    let spotifAcTok = requestURLString[range.upperBound...]
                    if let range = spotifAcTok.range(of: "&token_type=") {
                        let spotifAcTokFinal = spotifAcTok[..<range.lowerBound]
                        handleAuth(spotifyAccessToken: String(spotifAcTokFinal))
                    }
                }
            }
        }
    }
    
    func handleAuth(spotifyAccessToken: String) {
            fetchSpotifyProfile(accessToken: spotifyAccessToken)
            // Close Spotify Auth ViewController after getting Access Token
            self.dismiss(animated: true, completion: nil)
        }

        func fetchSpotifyProfile(accessToken: String) {
            let tokenURLFull = APIBuilder.spotifyURL
            let verify: NSURL = NSURL(string: tokenURLFull)!
            let request: NSMutableURLRequest = NSMutableURLRequest(url: verify as URL)
            request.addValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                if error == nil {
                    let result = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]
                    
                    let spotifyId: String! = (result?["id"] as! String)
                    let spotifyDisplayName: String! = (result?["display_name"] as! String)
                    //Spotify Email
//                    let spotifyEmail: String! = (result?["email"] as! String)
                    //Spotify Profile Avatar URL
//                    let spotifyAvatarURL: String!
//                    let spotifyProfilePicArray = result?["images"] as? [AnyObject]
//                    if (spotifyProfilePicArray?.count)! > 0 {
//                        spotifyAvatarURL = spotifyProfilePicArray![0]["url"] as? String
//                    } else {
//                        spotifyAvatarURL = "Not exists"
//                    }
                    DispatchQueue.main.async {
                        UserDefault.shared.user?.spotifyId = spotifyId
                        Navigate.to.presentConfirmPopUp(self, text1: Constant.String.privetOrPublicInfo, text2: spotifyDisplayName ?? "@realamitpaul", text3: Constant.String.changesLaterInfo,isYesOrNoBtn: true)
                        self.spotifyConnect = true
                        self.onBoardingDelegate.editUserProfileApi(spotifyToken: accessToken) { isSuccess, errorMsg in
                            if isSuccess {
                                print(accessToken)
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
            task.resume()
        }
}
