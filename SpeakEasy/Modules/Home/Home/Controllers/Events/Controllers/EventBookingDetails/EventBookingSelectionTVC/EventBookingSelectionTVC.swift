//
//  EventBookingSelectionTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/3/22.
//

import UIKit
import Foundation

class EventBookingSelectionTVC: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    var selectedTabAt : ((Int)->Void)?
    var arrayHeaders = [EventHeaderOptions(label: Strings.TICKETS.text, isSelected: true),EventHeaderOptions(label: Strings.VIP_TABLE_BOOKING.text, isSelected: false),EventHeaderOptions(label: Strings.PUBLIK_ATTENDEES.text, isSelected: false)]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
//MARK: - Helper Methods
extension EventBookingSelectionTVC {
    func setUI(){
       registerCell()
        collectionView.dataSource = self
        collectionView.delegate = self
   }
   private func registerCell(){
       self.collectionView.register(UINib(nibName: "EventOptionCVC", bundle: nil), forCellWithReuseIdentifier: "EventOptionCVC")
   }
}

extension EventBookingSelectionTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrayHeaders.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EventOptionCVC", for: indexPath) as! EventOptionCVC
         let data = self.arrayHeaders[indexPath.row]
            cell.setData(data: data)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.arrayHeaders[indexPath.item].isSelected {
            return
        }
        else {
            for index in 0..<self.arrayHeaders.count {
                self.arrayHeaders[index].isSelected = false
            }
            self.arrayHeaders[indexPath.item].isSelected = true
            self.selectedTabAt?(indexPath.item)
        }
        DispatchQueue.main.async {
            collectionView.reloadData()
        }
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension EventBookingSelectionTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "semiBold", fontSize: 15.0)

        let tabOption = self.arrayHeaders[indexPath.item].label
        let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 40.0
        let height = collectionView.frame.height
            let size = CGSize(width: width, height: height)
            return size
    }
}
