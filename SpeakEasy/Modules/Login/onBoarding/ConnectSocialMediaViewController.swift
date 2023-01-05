//
//  ConnectSocialMediaViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 12/12/22.
//

import UIKit

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
    
    var spotifyConnect = false
    
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

    }
    
    @IBAction func onClickSkip(_ sender: Any) {
        let user = UserModel()
        AppStateManager.sharedInstance.loginUser(user: user)
    }
    
    @IBAction func onClickGetStarted(_ sender: Any) {
        let user = UserModel()
        AppStateManager.sharedInstance.loginUser(user: user)
    }
    
    @IBAction func onClickConnectWithSpotify(_ sender: Any) {
        Navigate.to.presentConfirmPopUp(self, text1: Constant.String.privetOrPublicInfo, text2: "@realamitpaul", text3: Constant.String.changesLaterInfo,isYesOrNoBtn: true)
        self.spotifyConnect = true
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
        self.spotifyPrivetLine.isHidden = false
        self.spotifyPublicLbl.textColor = UIColor(hex: "#4F4F4F")
        self.spotifyPublicLine.isHidden = true
    }
    
    @objc func onClickspotifypublicView () {
        self.spotifyPrivetLbl.textColor = UIColor(hex: "#4F4F4F")
        self.spotifyPrivetLine.isHidden = true
        self.spotifyPublicLbl.textColor = .white
        self.spotifyPublicLine.isHidden = false
    }
    
    @objc func onClickInstagramPrivet() {
        self.instagramPrivetLbl.textColor = .white
        self.instagramPrivetLine.isHidden = false
        self.instagramPublicLbl.textColor = UIColor(hex: "#4F4F4F")
        self.instagramPublicLine.isHidden = true
    }
    
    @objc func onClickInstagramPublic() {
        self.instagramPrivetLbl.textColor = UIColor(hex: "#4F4F4F")
        self.instagramPrivetLine.isHidden = true
        self.instagramPublicLbl.textColor = .white
        self.instagramPublicLine.isHidden = false
    }
    
}

extension ConnectSocialMediaViewController: ConfirmPopUpDelegate {
    func cancelDetail() {
        if spotifyConnect {
            self.spotifyConnected()
            self.spotifyPrivetLbl.textColor = .white
            self.spotifyPrivetLine.isHidden = false
            self.spotifyPublicLbl.textColor = UIColor(hex: "#4F4F4F")
            self.spotifyPublicLine.isHidden = true
        } else {
            self.instagramConnected()
            self.instagramPrivetLbl.textColor = .white
            self.instagramPrivetLine.isHidden = false
            self.instagramPublicLbl.textColor = UIColor(hex: "#4F4F4F")
            self.instagramPublicLine.isHidden = true
        }
    }
    
    func confirmDetail() {
        if spotifyConnect {
            self.spotifyConnected()
            self.spotifyPrivetLbl.textColor = UIColor(hex: "#4F4F4F")
            self.spotifyPrivetLine.isHidden = true
            self.spotifyPublicLbl.textColor = .white
            self.spotifyPublicLine.isHidden = false
        } else {
            self.instagramConnected()
            self.instagramPrivetLbl.textColor = UIColor(hex: "#4F4F4F")
            self.instagramPrivetLine.isHidden = true
            self.instagramPublicLbl.textColor = .white
            self.instagramPublicLine.isHidden = false
        }
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
            }
        }
    }
}

