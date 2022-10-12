//
//  SearchFriendsCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 06/09/2022.
//

import UIKit
 
class FriendTVC: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    var didSelectFriend: ((InviteFriendsModel)->Void)?
    
    var arrOfFriends: [InviteFriendsModel] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.registerCell()
        self.setUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    private func setUI(){
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    private func registerCell(){
        collectionView.register(UINib(nibName: "FriendCVC", bundle: nil), forCellWithReuseIdentifier: "FriendCVC")
    }
    
}

//MARK: - UICollectionViewDataSource
extension FriendTVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrOfFriends.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendCVC", for: indexPath) as! FriendCVC
        
        let data = self.arrOfFriends[indexPath.row]
        cell.setData(data: data)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let friend = self.arrOfFriends[indexPath.item] //.remove(at: indexPath.item)
        self.didSelectFriend?(friend)
        self.collectionView.reloadData()
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension FriendTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = (collectionView.frame.width/3) - 18
        let height = (collectionView.frame.height/3) * 1.5
        let size = CGSize(width: width, height: height)
        return size
    }
}
