//
//  TableBookingDetailsCell.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 09/01/23.
//

import UIKit

final class TableBookingDetailsCell: UITableViewCell {

    @IBOutlet weak var bottleMenuBtn: UIButtonDeviceClass!
    @IBOutlet weak var viewInviteFrdCollection: UIView!
    @IBOutlet weak var searchFrdView: UIView!
    @IBOutlet weak var inviteFrdCollectionView: UICollectionView!
    @IBOutlet weak var searcFrdBtn: UIButton!
    @IBOutlet weak var maleGuestCountLbl: UILabelDeviceClass!
    @IBOutlet weak var femaleGuestCountLbl: UILabelDeviceClass!
    @IBOutlet weak var femaleGuestMinusBtn: UIButton!
    @IBOutlet weak var femaleGuestPlusBtn: UIButton!
    @IBOutlet weak var maleMinusBtn: UIButton!
    @IBOutlet weak var malePlusBtn: UIButton!
    @IBOutlet weak var itsOnMeView: UIView!
    @IBOutlet weak var equalSplitView: UIView!
    @IBOutlet weak var customSplitView: UIView!
    @IBOutlet weak var itsOnMeLbl: UILabel!
    @IBOutlet weak var itsOnMeInfoLbl: UILabel!
    @IBOutlet weak var equalSplitLbl: UILabel!
    @IBOutlet weak var equalSplitInfoLbl: UILabel!
    @IBOutlet weak var customSplitLbl: UILabel!
    @IBOutlet weak var customSplitInfoLbl: UILabel!
    @IBOutlet weak var editFriendListBtn: UIButton!
    
    var arrOthersInvite = [OthersInvites(image: UIImage(named: "user1-others"), name: "You", percentage: "50%", isVerified: false), OthersInvites(image: UIImage(named: "user2-others"), name: "Henry", percentage: "0%", isVerified: true), OthersInvites(image: UIImage(named: "user3-others"), name: "Abby", percentage: "0%", isVerified: true), OthersInvites(image: UIImage(named: "user4-others"), name: "Madison", percentage: "0%", isVerified: false)]
    
    var arrOfFriends = [
        InviteFriendsModel(name: "Henry", img: "henry"),
        InviteFriendsModel(name: "Paul", img: "paul"),
        InviteFriendsModel(name: "Abby", img: "abby"),
        InviteFriendsModel(name: "Madison", img: "madison"),
        InviteFriendsModel(name: "Ben", img: "Friend")
    ]
    var invitedFrd = [InviteFriendsModel]()
    var guest = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if self.invitedFrd.count + self.guest == 0 {
            self.searchFrdView.isHidden = false
            self.viewInviteFrdCollection.isHidden = true
        } else {
            self.searchFrdView.isHidden = true
            self.viewInviteFrdCollection.isHidden = false
        }

        self.inviteFrdCollectionView.delegate = self
        self.inviteFrdCollectionView.dataSource = self
        self.inviteFrdCollectionView.register(UINib(nibName: "OthersCVC", bundle: nil), forCellWithReuseIdentifier: "OthersCVC")
    }
    
    func setGuestdata(noOfMale: Int,noOfFemale: Int) {
        self.femaleGuestCountLbl.text = "\(noOfFemale)"
        self.maleGuestCountLbl.text = "\(noOfMale)"
    }
    
    func setCostSpliteView(costType: costSpliteType) {
        if costType == .itsMe {
            self.itsOnMeView.backgroundColor = Constant.Color.selectedDrinkColor
            self.itsOnMeLbl.textColor = .white
            self.itsOnMeInfoLbl.textColor = .white
            self.equalSplitView.backgroundColor = .white
            self.equalSplitLbl.textColor = Constant.Color.selectedDrinkColor
            self.equalSplitInfoLbl.textColor = Constant.Color.selectedDrinkColor
            self.customSplitView.backgroundColor = .white
            self.customSplitLbl.textColor = Constant.Color.selectedDrinkColor
            self.customSplitInfoLbl.textColor = Constant.Color.selectedDrinkColor
        } else if costType == .EqualSplite {
            self.itsOnMeView.backgroundColor = .white
            self.itsOnMeLbl.textColor = Constant.Color.selectedDrinkColor
            self.itsOnMeInfoLbl.textColor = Constant.Color.selectedDrinkColor
            self.equalSplitView.backgroundColor = Constant.Color.selectedDrinkColor
            self.equalSplitLbl.textColor = .white
            self.equalSplitInfoLbl.textColor = .white
            self.customSplitView.backgroundColor = .white
            self.customSplitLbl.textColor = Constant.Color.selectedDrinkColor
            self.customSplitInfoLbl.textColor = Constant.Color.selectedDrinkColor
        } else if costType == .customSplite {
            self.itsOnMeView.backgroundColor = .white
            self.itsOnMeLbl.textColor = Constant.Color.selectedDrinkColor
            self.itsOnMeInfoLbl.textColor = Constant.Color.selectedDrinkColor
            self.equalSplitView.backgroundColor = .white
            self.equalSplitLbl.textColor = Constant.Color.selectedDrinkColor
            self.equalSplitInfoLbl.textColor = Constant.Color.selectedDrinkColor
            self.customSplitView.backgroundColor = Constant.Color.selectedDrinkColor
            self.customSplitLbl.textColor = .white
            self.customSplitInfoLbl.textColor = .white
        }
        
        if self.invitedFrd.count + self.guest == 0 {
            self.searchFrdView.isHidden = false
            self.viewInviteFrdCollection.isHidden = true
        } else {
            self.searchFrdView.isHidden = true
            self.viewInviteFrdCollection.isHidden = false
        }
    }
    
}

extension TableBookingDetailsCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return invitedFrd.count + guest
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OthersCVC", for: indexPath) as! OthersCVC
        if indexPath.row < invitedFrd.count {
            cell.setFriendData(data: invitedFrd[indexPath.row], isGuest: false)
        } else {
            cell.setFriendData(isGuest: true)
        }
        return cell
    }
}

extension TableBookingDetailsCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize: CGSize = CGSize(width: 66, height: 100)
        return cellSize
    }
}

//extension TableBookingDetailsCell: InvitedFriendDelegate {
//    func invitedFrd(frdArray: [InviteFriendsModel]) {
//        self.invitedFrd = frdArray
//        self.inviteFrdCollectionView.reloadData()
//       
//    }
//}
