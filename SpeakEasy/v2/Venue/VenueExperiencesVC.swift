//
//  VenueExperiencesVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/03/26.
//

import UIKit

final class VenueExperiencesVC: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(EventV2CVC.nib, forCellWithReuseIdentifier: EventV2CVC.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension VenueExperiencesVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        6
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: EventV2CVC = collectionView.dequeue(withIdentifier: EventV2CVC.identifier, for: indexPath)
        return cell
    }
}
