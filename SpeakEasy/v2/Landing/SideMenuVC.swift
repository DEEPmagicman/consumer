//
//  SideMenuVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 22/12/25.
//

import UIKit
import LGSideMenuController

final class SideMenuVC: UIViewController {
      
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userProfilePic: UIImageView!
    @IBOutlet weak var userNameFirstLetter: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUserData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        userProfilePic.layer.cornerRadius = userProfilePic.frame.height / 2
        userProfilePic.clipsToBounds = true
        userNameFirstLetter.layer.cornerRadius = userNameFirstLetter.frame.height / 2
        userNameFirstLetter.clipsToBounds = true
    }
    
    @IBAction func onClickProfileBtn(_ sender: Any) {
        sideMenuController?.hideLeftView(animated: true, completion: { [weak self] in
            guard let self = self else { return }
//            Navigate.to.profileVC(self)
        })
        
    }
    
    @IBAction func onClickSettingBtn(_ sender: Any) {
        
        sideMenuController?.hideLeftView(animated: true, completion: { [weak self] in
            guard let self = self else { return }
            Navigate.to.settingsVc(self)
        })
    }
    
    @IBAction func onClickNotificationBtn(_ sender: Any) {
        sideMenuController?.hideLeftView(animated: true, completion: { [weak self] in
            guard let self = self else { return }
            Navigate.to.notificationVc(self)
        })
    }
    
    private func setupUserData() {
        
        guard let user = UserDefault.shared.user else { return }
        
        let fullName = "\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespaces)
        let imageUrl = user.image.key
        userName.text = fullName
        
        if !imageUrl.isEmpty {
            userProfilePic.isHidden = false
            userNameFirstLetter.isHidden = true
            
            userProfilePic.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(named: "placeholder")
            )
            
        } else {
            
            userProfilePic.isHidden = true
            userNameFirstLetter.isHidden = false
            let firstLetter = user.firstName.first ?? Character("")
            userNameFirstLetter.text = String(firstLetter).uppercased()
            userNameFirstLetter.textAlignment = .center
        }
    }
}
