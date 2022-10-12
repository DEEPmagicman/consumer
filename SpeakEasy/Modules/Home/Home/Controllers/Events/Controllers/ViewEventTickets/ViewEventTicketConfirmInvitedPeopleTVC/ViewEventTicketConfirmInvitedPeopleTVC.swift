//
//  ViewEventTicketConfirmInvitedPeopleTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 14/09/2022.
//

import UIKit

class ViewEventTicketConfirmInvitedPeopleTVC: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}

//MARK: - Helper Methods
extension ViewEventTicketConfirmInvitedPeopleTVC {
    func setUI() {
       registerCell()
        collectionView.dataSource = self
        collectionView.delegate = self
   }
   private func registerCell() {
       self.collectionView.register(UINib(nibName: "FriendsListCVC", bundle: nil), forCellWithReuseIdentifier: "FriendsListCVC")
   }
}

//MARK: - UICollectionViewDataSource
extension ViewEventTicketConfirmInvitedPeopleTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendsListCVC", for: indexPath) as! FriendsListCVC
        return cell
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension ViewEventTicketConfirmInvitedPeopleTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let length = collectionView.frame.height
        let size = CGSize(width: length, height: length)
        return size
    }
}
