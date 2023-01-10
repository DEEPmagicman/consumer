//
//  InviteFriendsPopUp.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 10/01/23.
//

import UIKit

protocol InvitedFriendDelegate {
    func invitedFrd(frdArray: [InviteFriendsModel])
}

class InviteFriendsPopUp: UIViewController {

    @IBOutlet weak var invitedFrdCollectionView: UICollectionView!
    @IBOutlet weak var searchfrdTextField: UITextField!
    @IBOutlet weak var inviteFriendTableView: UITableView!
    
    var arrOfFriends = [
        InviteFriendsModel(name: "Henry", img: "henry"),
        InviteFriendsModel(name: "Paul", img: "paul"),
        InviteFriendsModel(name: "Abby", img: "abby"),
        InviteFriendsModel(name: "Madison", img: "madison"),
        InviteFriendsModel(name: "Ben", img: "Friend")
    ]
    var selectedFriend = [InviteFriendsModel]()
    var invitedFrdDelegate: InvitedFriendDelegate?
    var guest = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.invitedFrdCollectionView.register(UINib(nibName: "InviteFriendsCVC", bundle: nil), forCellWithReuseIdentifier: "InviteFriendsCVC")
        self.inviteFriendTableView.register(UINib(nibName: "FriendListTableViewCell", bundle: nil), forCellReuseIdentifier: "FriendListTableViewCell")
    }
    
    @IBAction func onClickCancel(_ sender: Any) {
        self.invitedFrdDelegate?.invitedFrd(frdArray: self.selectedFriend)
        self.dismiss(animated: true, completion: nil)
    }
}

extension InviteFriendsPopUp: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedFriend.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InviteFriendsCVC", for: indexPath) as! InviteFriendsCVC
        cell.setData(data: selectedFriend[indexPath.row])
        cell.btnDelete.tag = indexPath.row
        cell.btnDelete.addTarget(self, action: #selector(removeFriend(_:)), for: .touchUpInside)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = 66.0
        let height = 90.0
        let size = CGSize(width: width, height: height)
        return size
    }
    
    @objc func removeFriend(_ sender: UIButton) {
//        self.arrOfFriends.append(selectedFriend[sender.tag])
        self.selectedFriend.remove(at: sender.tag)
        self.invitedFrdCollectionView.reloadData()
        self.inviteFriendTableView.reloadData()
    }

}

extension InviteFriendsPopUp: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrOfFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendListTableViewCell", for: indexPath) as! FriendListTableViewCell
        cell.setData(data: arrOfFriends[indexPath.row])
        cell.addView.tag = indexPath.row
        let tap = UITapGestureRecognizer(target: self, action: #selector(addFriend(_:)))
        cell.addView.addGestureRecognizer(tap)
        
        return cell
    }
    
    @objc func addFriend(_ sender: UITapGestureRecognizer) {
        if (self.selectedFriend.count + self.guest) < 5 {
            self.selectedFriend.append(arrOfFriends[sender.view!.tag])
//            self.arrOfFriends.remove(at: sender.view!.tag)
            self.invitedFrdCollectionView.reloadData()
            self.inviteFriendTableView.reloadData()
        } else {
            Alert.showAlertSheet(style: .alert, title: Constant.String.max5FrdString, message: "")
        }
    }
    
    
}
