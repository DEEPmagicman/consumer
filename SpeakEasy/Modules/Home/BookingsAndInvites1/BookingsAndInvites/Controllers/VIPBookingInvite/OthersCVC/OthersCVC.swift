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
    @IBOutlet weak var paymentConfirmImg: UIImageView!
    
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
    
    func setFriendData(data: InviteFriendsModel? = nil, isGuest: Bool) {
        if isGuest {
            self.imgUser.image = Constant.Icon.maleIdentify
            self.lblUser.text = "Guest"
            self.lblPercentage.text = "FREE"
        } else {
            self.imgUser.image = UIImage(named: data?.img ?? "")
            self.lblUser.text = data?.name
            self.lblPercentage.text = "10%"
        }
        self.imgVerified.isHidden = true
    }
}
