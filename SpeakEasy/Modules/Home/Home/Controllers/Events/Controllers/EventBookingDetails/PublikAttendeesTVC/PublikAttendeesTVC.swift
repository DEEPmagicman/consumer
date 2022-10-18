//
//  PublikAttendeesTVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 14/10/22.
//

import Foundation
import UIKit

class PublikAttendeesTVC: UITableViewCell {
    
    var eventDetailDelegate: EventDetailsDelegate?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpUI()
    }
    
    func setUpUI() {
        registerCell()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    private func registerCell() {
        self.collectionView.register(UINib(nibName: "PublikAttendeesProfileCVC", bundle: nil), forCellWithReuseIdentifier: "PublikAttendeesProfileCVC")
    }
}

extension PublikAttendeesTVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PublikAttendeesProfileCVC", for: indexPath) as! PublikAttendeesProfileCVC
        if indexPath.row == 0 {
            cell.profileImgMark.image = UIImage(named: "purpul_Check")
        } else {
            cell.profileImgMark.image = UIImage(named: "blueCheck")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.eventDetailDelegate?.onClickArtistProfile()
        } else {
            self.eventDetailDelegate?.onClickUserProfile()
        }
    }
    
}
