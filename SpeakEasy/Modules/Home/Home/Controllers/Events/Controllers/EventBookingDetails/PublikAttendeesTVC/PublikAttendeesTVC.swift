//
//  PublikAttendeesTVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 14/10/22.
//

import UIKit

protocol PublikAttendeesTVCDelegate: AnyObject {
    func refreshTableViewIfNeeded()
}

class PublikAttendeesTVC: UITableViewCell {
    
    var eventDetailDelegate: EventDetailsDelegate?
    weak var delegate: PublikAttendeesTVCDelegate?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        setUpUI()
        collectionView.addObserver(self, forKeyPath: "contentSize", options: [], context: nil)
    }
    
    func setUpUI() {
        registerCell()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    private func registerCell() {
        self.collectionView.register(UINib(nibName: "PublikAttendeesProfileCVC", bundle: nil), forCellWithReuseIdentifier: "PublikAttendeesProfileCVC")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        collectionViewHeightConstraint.constant = collectionView.contentSize.height
        delegate?.refreshTableViewIfNeeded()
    }
}

extension PublikAttendeesTVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        17
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
