//
//  TopEventsTVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit

protocol didSelectEvents {
    
    func selectEvent()
}

class TopEventsTVC: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
        
    var selectedTopEvent: ((Int)->Void)?

    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.registerCell()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
}
//MARK: - Helper methods
extension TopEventsTVC{
    private func registerCell(){
        self.collectionView.register(UINib(nibName: "TopEventCVC", bundle: nil), forCellWithReuseIdentifier: "TopEventCVC")
    }
}
extension TopEventsTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if Constants.localizedCity == "Chicago" {
            return Constants.arrayTopEventsChicago.count
        }else {
            return Constants.arrayTopEventsCleveland.count
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopEventCVC", for: indexPath) as! TopEventCVC
        let data: TopEventDataSet!
        
        if Constants.localizedCity == "Chicago" {
            data = Constants.arrayTopEventsChicago[indexPath.item]
        }else {
            data = Constants.arrayTopEventsCleveland[indexPath.item]
        }
        cell.setData(data: data)
        return cell
    }
}
extension TopEventsTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width * 0.65
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}
extension TopEventsTVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedTopEvent?(indexPath.item)
    }
}
