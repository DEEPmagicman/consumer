//
//  DateSelectionTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 24/12/25.
//

import UIKit

class DateSelectionTVC: UITableViewCell {

    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var eventCollectionView: UICollectionView!
    @IBOutlet weak var eventCollectionViewHeight: NSLayoutConstraint!
    
    private var collectionViewHeightObservation: NSKeyValueObservation?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        eventCollectionView.delegate = self
        eventCollectionView.dataSource = self
        setupCollectionView()
        eventCollectionView.register(EventV2CVC.nib, forCellWithReuseIdentifier: EventV2CVC.identifier)
        collectionViewHeightObservation = eventCollectionView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.eventCollectionViewHeight.constant = self.eventCollectionView.contentSize.height
            self.eventCollectionView.layoutIfNeeded()
        }
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 16
        let itemsPerRow: CGFloat = 2
        let totalSpacing = (itemsPerRow + 1) * spacing
        let itemWidth = (self.frame.width - totalSpacing) / itemsPerRow
        layout.sectionInset = UIEdgeInsets(top: 0, left: spacing, bottom: spacing, right: spacing)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.itemSize = CGSize(width: itemWidth, height: 228)
        eventCollectionView.collectionViewLayout = layout
    }
}

extension DateSelectionTVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: EventV2CVC = collectionView.dequeue(withIdentifier: EventV2CVC.identifier, for: indexPath)
        return cell
    }
}
