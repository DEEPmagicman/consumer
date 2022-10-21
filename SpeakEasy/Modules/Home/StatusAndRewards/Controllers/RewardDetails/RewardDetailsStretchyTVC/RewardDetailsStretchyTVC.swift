//
//  RewardDetailsStretchyTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/30/22.
//

import UIKit

class RewardDetailsStretchyTVC: UITableViewCell {
    
    @IBOutlet weak var EventCollectionView: UICollectionView!
    @IBOutlet weak var discountLbl: UILabelDeviceClass!
    @IBOutlet weak var guestView: UIStackView!
    
    var arrayEvents = [
        TopEventDataSet(imgEventCover: UIImage(named: "TopEventBG1"), lblPerformerName: "Steve Aoki", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Tonight!", currentLiveEventFires: nil, isLive: true)
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.EventCollectionView.isHidden = true
        self.EventCollectionView.delegate = self
        self.EventCollectionView.dataSource = self
        self.EventCollectionView.register(UINib(nibName: "TopEventCVC", bundle: nil), forCellWithReuseIdentifier: "TopEventCVC")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension RewardDetailsStretchyTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrayEvents.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopEventCVC", for: indexPath) as! TopEventCVC
        let data = self.arrayEvents[indexPath.item]
        cell.setData(data: data)
        return cell
    }
}
extension RewardDetailsStretchyTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width * 0.65
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}
