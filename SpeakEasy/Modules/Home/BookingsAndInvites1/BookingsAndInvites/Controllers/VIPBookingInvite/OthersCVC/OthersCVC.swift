//
//  OthersCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 02/09/2022.
//

import UIKit

class OthersCVC: UICollectionViewCell {

    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var imgVerified: UIImageView!
    @IBOutlet weak var lblUser: UILabelDeviceClass!
    @IBOutlet weak var lblPercentage: UILabelDeviceClass!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setData(userData: OthersInvites) {
        self.imgUser.image = userData.image
        self.lblUser.text = userData.name
        self.lblPercentage.text = userData.percentage
        if userData.isVerified! {
            self.imgVerified.isHidden = false
        }else{
            self.imgVerified.isHidden = true
        }
    }
}
