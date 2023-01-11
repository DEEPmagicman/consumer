//
//  InviteFriendsCostSplitTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 28/09/2022.
//

import UIKit

class InviteFriendsCostSplitTVC: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var costSpliteView: UIView!
    @IBOutlet weak var headerLbl: UILabelDeviceClass!
    
    var status: BookingStatusType?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    private func setUI() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.registerCells()
    }
    private func registerCells() {
        self.collectionView.register(UINib(nibName: "FriendsListCVC", bundle: nil), forCellWithReuseIdentifier: "FriendsListCVC")
        self.collectionView.register(UINib(nibName: "OthersCVC", bundle: nil), forCellWithReuseIdentifier: "OthersCVC")
    }
}

//MARK: CollectionView
extension InviteFriendsCostSplitTVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.status == .SubmitRequest || self.status == .BookingConfirmation {
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OthersCVC", for: indexPath) as! OthersCVC
            cell.imgVerified.isHidden = true
            if self.status == .BookingConfirmation {
                cell.paymentConfirmImg.isHidden = false
            } else {
                cell.paymentConfirmImg.isHidden = true
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendsListCVC", for: indexPath) as! FriendsListCVC
            return cell
        }
        
    }
}
extension InviteFriendsCostSplitTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize: CGSize = CGSize(width: 66, height: collectionView.frame.height)
            return cellSize
    }
}
