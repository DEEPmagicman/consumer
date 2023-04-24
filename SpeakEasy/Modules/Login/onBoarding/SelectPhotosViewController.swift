//
//  SelectPhotosViewController.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 02/01/23.
//

import UIKit
import SDWebImage

protocol InstagramPhotosDelegate: AnyObject {
    func getInstaImages(media:[InstagramMedia], isLastPage: Bool)
    func getError(errorMsg: String?)
}

final class SelectPhotosViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var instaPhoto = [InstagramMedia]()
    weak var selectedImgDelegate: SelectedInstaImgDelegate?
    private var isLastPage = false

    override func viewDidLoad() {
        super.viewDidLoad()
        InstagramManager.instagramDelegate = self
        UserDefault.shared.user?.instaNextPageURL = nil
        InstagramManager.getInstaImages(token: UserDefault.shared.user?.instagramToken ?? "")
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == instaPhoto.count - 1 {
            if isLastPage &&  UserDefault.shared.user?.instaNextPageURL != nil {
                UserDefault.shared.user?.instaNextPageURL = nil
            } else {
                InstagramManager.getInstaImages(token: UserDefault.shared.user?.instagramToken ?? "")
            }
        }
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

extension SelectPhotosViewController: InstagramPhotosDelegate {
    func getError(errorMsg: String?) {
        UserDefault.shared.removeInstaConnection()
        Utility.main.showAlert(message: errorMsg ?? "Something went wrong. try again later", title: "Error") {
            self.selectedImgDelegate?.loginAgain()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func getInstaImages(media: [InstagramMedia], isLastPage: Bool) {
        if instaPhoto.count == 0 {
            self.instaPhoto = media
        } else {
            self.instaPhoto.append(contentsOf: media)
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        self.isLastPage = isLastPage
    }
    
}

class PhotoCollectionviewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

