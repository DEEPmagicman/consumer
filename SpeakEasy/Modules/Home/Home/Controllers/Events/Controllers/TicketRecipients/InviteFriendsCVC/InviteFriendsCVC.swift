//
//  InviteFriendsCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 03/09/2022.
//

import UIKit

class InviteFriendsCVC: UICollectionViewCell {

    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblName: UILabelDeviceClass!
    @IBOutlet weak var btnDelete: UIButton!

    func setData(data: InviteFriendsModel) {
        self.lblName.text = data.name
        self.imgUser.image = UIImage(named: data.img)
        
    }

}
