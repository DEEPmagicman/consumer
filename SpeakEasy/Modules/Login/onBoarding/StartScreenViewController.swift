//
//  StartScreenViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/12/22.
//

import UIKit

final class StartScreenViewController: UIViewController {
    
    @IBOutlet weak var byTappingInfoLbl: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
//        Navigate.to.notificationPermissionVc(self)
        
        self.byTappingInfoLbl.highlightBold(["Terms of Service","Privacy Policy","Cookies Policy."], size: 15, textColor: .white, addUnderLine: true)
    }
    
    @IBAction func onClickCreateAccount(_ sender: Any) {
        Navigate.to.enterPhoneNumVc(self)
    }
    
    @IBAction func onClickSignIn(_ sender: Any) {
        Navigate.to.signInOptionVc(self)
    }
    
    @IBAction func onClickAsGuest(_ sender: Any) {
        Navigate.to.presentConfirmPopUp(self, text1: Constant.String.confirm21YearText, text2: "", text3: Constant.String.over21Info)
    }
}

extension StartScreenViewController: ConfirmPopUpDelegate {
    func cancelDetail() {
        
    }
    
    func confirmDetail() {
        let user = UserModel()
        AppStateManager.sharedInstance.loginUser(user: user)
    }
}
