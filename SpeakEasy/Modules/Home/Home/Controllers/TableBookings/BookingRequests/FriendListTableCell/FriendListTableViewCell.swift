//
//  FriendListTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 10/01/23.
//

import UIKit

class FriendListTableViewCell: UITableViewCell {

    @IBOutlet weak var frdimageView: UIImageView!
    @IBOutlet weak var frdNameLbl: UILabel!
    @IBOutlet weak var frdInfoLbl: UILabel!
    @IBOutlet weak var addView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func setData(data: InviteFriendsModel) {
        self.frdimageView.image = UIImage(named: data.img)
        self.frdNameLbl.text = data.name
    }
    
}
