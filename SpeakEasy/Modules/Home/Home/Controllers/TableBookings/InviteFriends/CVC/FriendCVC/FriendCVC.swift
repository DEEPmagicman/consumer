//
//  FriendCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 06/09/2022.
//

import UIKit

class FriendCVC: UICollectionViewCell {

    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblName: UILabelDeviceClass!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setData(data: InviteFriendsModel) {
        self.lblName.text = data.name
        self.imgUser.image = UIImage(named: data.img)
    }
}
