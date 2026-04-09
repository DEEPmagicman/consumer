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
    private var followedVenues: [ClipVenue] = []
    private var isVenueLoading = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViews()
        setupUserData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgView.applyHeaderGradient()
    }
    
    private func setupCollectionViews() {
        
        savedEventCollectionView.delegate = self
        savedEventCollectionView.dataSource = self
        
        followedVenuesCollectionView.delegate = self
        followedVenuesCollectionView.dataSource = self

        savedEventCollectionView.register(EventV2CVC.nib, forCellWithReuseIdentifier: EventV2CVC.identifier)
        followedVenuesCollectionView.register(
            VenueCVC.nib,
            forCellWithReuseIdentifier: VenueCVC.identifier
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
             guard let self = self else { return }
             self.isLoading = false
             self.savedEventCollectionView.reloadData()
            self.isVenueLoading = false
                self.followedVenuesCollectionView.reloadData()
         }
    }
    
    private func setupUserData() {
        
        guard let user = UserDefault.shared.user else { return }
        
        let fullName = "\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespaces)
        let imageUrl = user.image.key
        name.text = fullName
        
        if !imageUrl.isEmpty {
            userImage.isHidden = false
            userFirstWord.isHidden = true
            
            userImage.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(named: "placeholder")
            )
            
        } else {
            
            userImage.isHidden = true
            userFirstWord.isHidden = false
            let firstLetter = user.firstName.first ?? Character("")
            userFirstWord.text = String(firstLetter).uppercased()
            userFirstWord.textAlignment = .center
        }
    }
    
    @IBAction func savedVenueSeeAllBtn(_ sender: Any) {
        
    }
    
    @IBAction func onClickFollowedVenuesBtn(_ sender: Any) {
        
    }
    
    @IBAction func onClickFollowedArtistBtn(_ sender: Any) {
        
    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
}

extension ProfileVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == savedEventCollectionView {
            return isLoading ? 5 : 5
        } else if collectionView == followedVenuesCollectionView {
            return isVenueLoading ? 5 : 5
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == savedEventCollectionView {
            let cell: EventV2CVC = collectionView.dequeue(withIdentifier: EventV2CVC.identifier, for: indexPath)
            
            if isLoading {
                cell.shimmerView.isHidden = false
                for view in cell.shimmerView.subviews where view is ShimmerView {
                    (view as? ShimmerView)?.startAnimating()
                }
            } else {
                cell.shimmerView.isHidden = true
//                let event = savedEvents[indexPath.row]
//                cell.configure(with: event)
            }
            return cell
        }
        
        else if collectionView == followedVenuesCollectionView {
            let cell: VenueCVC = collectionView.dequeue(withIdentifier: VenueCVC.identifier, for: indexPath)
            if isVenueLoading {
                cell.shimmerView.isHidden = false
                for view in cell.shimmerView.subviews where view is ShimmerView {
                    (view as? ShimmerView)?.startAnimating()
                }
            } else {
                cell.shimmerView.isHidden = true
//                let venue = followedVenues[indexPath.row]
//                cell.configure(with: venue)
            }
            return cell
        }
        
        return UICollectionViewCell()
    }
}

extension UIView {
    
    func applyHeaderGradient() {
          layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })

          let gradient = CAGradientLayer()
          gradient.frame = bounds

          gradient.colors = [
              UIColor(hex: "#DC69C3").cgColor,
              UIColor(hex: "#DC69C3").cgColor,
              UIColor(hex: "#121212").cgColor
          ]

          gradient.locations = [0.0, 0.5, 1.0]
          gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
          gradient.endPoint = CGPoint(x: 0.5, y: 1.0)

          layer.insertSublayer(gradient, at: 0)
      }
}
