//
//  ViewEventTicketConfirmTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/4/22.
//

import UIKit

class ViewEventTicketConfirmTVC: UITableViewCell {

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
extension ViewEventTicketConfirmTVC {
    func setUI() {
       registerCell()
        collectionView.dataSource = self
        collectionView.delegate = self
   }
   private func registerCell() {
       self.collectionView.register(UINib(nibName: "ViewEventTicketConfirmCVC", bundle: nil), forCellWithReuseIdentifier: "ViewEventTicketConfirmCVC")
   }
}

//MARK: - UICollectionViewDataSource
extension ViewEventTicketConfirmTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ViewEventTicketConfirmCVC", for: indexPath)
        return cell
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension ViewEventTicketConfirmTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.frame.width/5
        let height = 80.0
        let size = CGSize(width: width, height: height)
        return size
    }
}
