//
//  VIPTableBookingTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/5/22.
//

import UIKit

class VIPTableBookingCalenderTVC: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var viewSeeAll: UIView!
    @IBOutlet weak var btnSeeAll: UIButton!
    @IBOutlet weak var viewSeperator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.registerCell()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    var arrayAssociatedEvent: [TopEventDataSet] = []
    
    func setData(seeAll: Bool){
        self.viewSeperator.isHidden = seeAll
        self.viewSeeAll.isHidden = !seeAll
    }
    
    func setTableSelectionData(seeAll: Bool){
        self.viewSeperator.isHidden = !seeAll
        self.viewSeeAll.isHidden = !seeAll
    }
}
//MARK: - Helper methods
extension VIPTableBookingCalenderTVC {
    private func registerCell(){
        self.collectionView.register(UINib(nibName: "EventCVC", bundle: nil), forCellWithReuseIdentifier: "EventCVC")
    }
}
//MARK: - UICollectionViewDataSource
extension VIPTableBookingCalenderTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrayAssociatedEvent.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EventCVC", for: indexPath) as! EventCVC
        
        let data = self.arrayAssociatedEvent[indexPath.item]
        cell.setData(data: data)
        
        return cell
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension VIPTableBookingCalenderTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 2.5
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}
