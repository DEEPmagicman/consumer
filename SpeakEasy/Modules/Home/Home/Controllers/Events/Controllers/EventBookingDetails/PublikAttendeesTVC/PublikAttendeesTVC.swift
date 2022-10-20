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
    var isTicketPurchased = true
    private var userCount = 17
    private var artistCount = 1
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var blurViewTopConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpUI()
        collectionView.addObserver(self, forKeyPath: "contentSize", options: [], context: nil)
        setBlurView()
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
    
    private func setBlurView() {
        self.blurView.isHidden = isTicketPurchased

        if self.artistCount%4 == 0 {
            self.blurViewTopConstraint.constant = CGFloat(111*(artistCount/4))
        } else {
            self.blurViewTopConstraint.constant = CGFloat(111*(artistCount/4 + 1))
        }
    }
}

extension PublikAttendeesTVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let cellCount = userCount + artistCount
        return isTicketPurchased ? cellCount : cellCount + (cellCount%4 != 0 ? (4-(cellCount%4)) : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PublikAttendeesProfileCVC", for: indexPath) as! PublikAttendeesProfileCVC
        if indexPath.row < artistCount {
            cell.profileImgMark.image = UIImage(named: "purpul_Check")
            cell.hideUserProfileView.isHidden = true
        } else {
            cell.profileImgMark.image = UIImage(named: "blueCheck")
            if isTicketPurchased {
                cell.hideUserProfileView.isHidden = true
            } else {
                cell.hideUserProfileView.isHidden = false
                cell.profileImg.alpha = 0.5
                cell.profileImgMark.alpha = 0.5
                cell.profileName.alpha = 0.2
                
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row < artistCount {
            self.eventDetailDelegate?.onClickArtistProfile()
        } else {
            if isTicketPurchased {
                self.eventDetailDelegate?.onClickUserProfile()
            }
        }
    }
}

extension PublikAttendeesTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var width = 93.0
        
        if collectionView.frame.width/5 >= 93.0 {
             width = collectionView.frame.width/5
        } else if collectionView.frame.width/4 >= 93.0 {
             width = collectionView.frame.width/4
        } else if collectionView.frame.width/3 >= 93.0 {
             width = collectionView.frame.width/3
        }
        let cellSize: CGSize = CGSize(width: width, height:111.0)
            return cellSize
    }
}
