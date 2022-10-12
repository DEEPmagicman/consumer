//
//  TableBookingInviteFriendsCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 07/09/2022.
//

import UIKit

class TableBookingInviteFriendsTVC: UITableViewCell {

    @IBOutlet weak var stackCollectionView: UIStackView!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var arrInvitedFriends : [InviteFriendsModel] = []
    var tableViewReference: UITableView?
    
    var didEmptyArrClosure: (()->Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setUI()
        self.registerCell()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    private func setUI(){
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionViewHeightManage()
    }
    private func registerCell(){
        collectionView.register(UINib(nibName: "InviteFriendsCVC", bundle: nil), forCellWithReuseIdentifier: "InviteFriendsCVC")
    }
    func collectionViewHeightManage() {
        self.tableViewReference?.beginUpdates()
        self.collectionViewHeight.constant = self.arrInvitedFriends.count == 0 ? 0 : 90
        self.stackCollectionView.isHidden = self.arrInvitedFriends.count == 0 ? true : false
        self.layoutIfNeeded()
        self.tableViewReference?.endUpdates()
    }
}

//MARK: - UICollectionViewDataSource
extension TableBookingInviteFriendsTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrInvitedFriends.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InviteFriendsCVC", for: indexPath) as! InviteFriendsCVC
        cell.btnDelete.tag = indexPath.item
        cell.btnDelete.addTarget(self, action: #selector(self.onBtnDelete(_:)), for: .touchUpInside)
        
        let data = self.arrInvitedFriends[indexPath.item]
        cell.setData(data: data)
        return cell
    }
    @objc func onBtnDelete(_ sender: UIButton) {
        self.arrInvitedFriends.remove(at: sender.tag)
        if self.arrInvitedFriends.count == 0 {
            self.didEmptyArrClosure?()
        }
        self.collectionView.reloadData()
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension TableBookingInviteFriendsTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = (collectionView.frame.width/5)
        let height = 90.0
        let size = CGSize(width: width, height: height)
        return size
    }
}
