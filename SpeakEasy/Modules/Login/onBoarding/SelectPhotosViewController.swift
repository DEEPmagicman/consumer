//
//  SelectPhotosViewController.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 02/01/23.
//

import UIKit
import SDWebImage

protocol InstagramPhotos: AnyObject {
    func getInstaImages(media:[InstagramMedia], isLastPage: Bool)
}

final class SelectPhotosViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var instaPhoto = [InstagramMedia]()
    weak var selectedImgDelegate: SelectedInstaImgDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        InstagramManager.instagramDelegate = self
        InstagramManager.getInstaImages(token: UserDefault.shared.user?.instagramTokan ?? "")
    }

}

extension SelectPhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return instaPhoto.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionviewCell", for: indexPath) as! PhotoCollectionviewCell
        let imgUrl = instaPhoto[indexPath.row].url
        cell.imageView?.sd_setImage(with: URL( string: imgUrl), completed: nil)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width =  (UIScreen.main.bounds.width / 3)
        let height = width
        
        let size = CGSize(width: width, height: height)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedImgDelegate?.selectedImg(image: instaPhoto[indexPath.row].url)
        self.dismiss(animated: true, completion: nil)
    }
}

extension SelectPhotosViewController: InstagramPhotos {
    func getInstaImages(media: [InstagramMedia], isLastPage: Bool) {
        if instaPhoto.count == 0 {
            self.instaPhoto = media
        } else {
            self.instaPhoto.append(contentsOf: media)
        }
        self.collectionView.reloadData()
        self.collectionView.performBatchUpdates(nil)
        if isLastPage {
            UserDefault.shared.user?.instanextPageURL = ""
        } else {
            InstagramManager.getInstaImages(token: UserDefault.shared.user?.instagramTokan ?? "")
        }
    }
    
}

class PhotoCollectionviewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

