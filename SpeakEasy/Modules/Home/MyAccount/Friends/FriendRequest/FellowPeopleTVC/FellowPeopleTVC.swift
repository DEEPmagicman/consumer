//
//  FellowPeopleTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 05/09/2022.
//

import UIKit

class FellowPeopleTVC: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var viewShowMore: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setUI()
        self.registerCell()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    private func setUI(){
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    private func registerCell(){
        collectionView.register(UINib(nibName: "SearchAndAddCVC", bundle: nil), forCellWithReuseIdentifier: "SearchAndAddCVC")
        
    }
    
}

//MARK: - UICollectionViewDataSource
extension FellowPeopleTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchAndAddCVC", for: indexPath)
        return cell
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension FellowPeopleTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = (collectionView.frame.width/2) - 6
        let height = (collectionView.frame.height/2) - 6
        let size = CGSize(width: width, height: height)
        return size
    }
}
