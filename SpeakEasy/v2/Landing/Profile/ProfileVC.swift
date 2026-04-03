//
//  ProfileVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 02/04/26.
//

import UIKit

class ProfileVC: UIViewController {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userFirstWord: UILabel!
    @IBOutlet weak var savedEventCollectionView: UICollectionView!
    @IBOutlet weak var followedVenuesCollectionView: UICollectionView!
    @IBOutlet weak var followedArtistsCollectionView: UICollectionView!
    @IBOutlet weak var bgView: UIView!
    
    private var savedEvents: [Event] = []
    private var isLoading = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgView.applyHeaderGradient()
    }
    
    private func setupCollectionViews() {
        
        savedEventCollectionView.delegate = self
        savedEventCollectionView.dataSource = self
        
        followedVenuesCollectionView.dataSource = nil
        followedArtistsCollectionView.dataSource = nil
        
        savedEventCollectionView.register(EventV2CVC.nib, forCellWithReuseIdentifier: EventV2CVC.identifier)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
             guard let self = self else { return }
             self.isLoading = false
             self.savedEventCollectionView.reloadData()
         }
    }
    
    @IBAction func savedVenueSeeAllBtn(_ sender: Any) {
        
    }
    
    @IBAction func onClickFollowedVenuesBtn(_ sender: Any) {
        
    }
    
    @IBAction func onClickFollowedArtistBtn(_ sender: Any) {
        
    }
}

extension ProfileVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isLoading ? 5 : savedEvents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: EventV2CVC = collectionView.dequeue(withIdentifier: EventV2CVC.identifier, for: indexPath)
        if isLoading {
            cell.shimmerView.isHidden = false
            for view in cell.shimmerView.subviews where view is ShimmerView {
                (view as? ShimmerView)?.startAnimating()
            }
            return cell
        } else {
            cell.shimmerView.isHidden = true
        }
        
        return cell
    }
}



extension UIView {
    
    func applyHeaderGradient() {
          layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })

          let gradient = CAGradientLayer()
          gradient.frame = bounds

          gradient.colors = [
              UIColor(hex: "#DC69C3").cgColor,
              UIColor(hex: "#000000").cgColor,
              UIColor(hex: "#121212").cgColor
          ]

          gradient.locations = [0.0, 0.5, 1.0]
          gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
          gradient.endPoint = CGPoint(x: 0.5, y: 1.0)

          layer.insertSublayer(gradient, at: 0)
      }
}
