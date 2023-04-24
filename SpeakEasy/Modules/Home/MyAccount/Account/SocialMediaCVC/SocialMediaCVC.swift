//
//  SocialMediaCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 28/08/2022.
//

import UIKit

class SocialMediaCVC: UICollectionViewCell {

    @IBOutlet weak var imgSocialLink: UIImageView!
    @IBOutlet weak var lblUsername: UILabelDeviceClass!
    
    func setData(socialLink: UIImage?) {
        self.imgSocialLink.image = socialLink
//        self.lblUsername.text = userName
    }
}
