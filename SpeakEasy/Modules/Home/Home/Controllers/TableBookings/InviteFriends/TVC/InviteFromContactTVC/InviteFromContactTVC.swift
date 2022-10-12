//
//  InviteFromContactTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 06/09/2022.
//

import UIKit

class InviteFromContactTVC: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
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
        collectionView.register(UINib(nibName: "InviteFromContactCVC", bundle: nil), forCellWithReuseIdentifier: "InviteFromContactCVC")
        
    }
    
}

//MARK: - UICollectionViewDataSource
extension InviteFromContactTVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InviteFromContactCVC", for: indexPath)
        return cell
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension InviteFromContactTVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = (collectionView.frame.width/2) - 6
        let height = (collectionView.frame.height/2) - 6
        let size = CGSize(width: width, height: height)
        return size
    }
}
