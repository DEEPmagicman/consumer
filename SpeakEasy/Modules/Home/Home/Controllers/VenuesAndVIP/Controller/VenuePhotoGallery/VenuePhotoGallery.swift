//
//  VenuePhotoGallery.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/1/22.
//

import UIKit
import GSImageViewerController

class VenuePhotoGallery: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onBtnBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func registerCell(){
        self.collectionView.register(UINib(nibName: "PhotoGalleryCVC", bundle: nil), forCellWithReuseIdentifier: "PhotoGalleryCVC")
    }
}

//MARK: COLLECTION VIEW DATASOURCE METHODS
extension VenuePhotoGallery: UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoGalleryCVC", for: indexPath) as? PhotoGalleryCVC else {return UICollectionViewCell()}
        return cell
    }
}

//MARK: COLLECTION VIEW DELEGATE METHODS
extension VenuePhotoGallery: UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let menuImageViewCell = self.collectionView.cellForItem(at: indexPath) as? PhotoGalleryCVC else {return}
        
        guard let imageView = menuImageViewCell.imgProduct else {return}
        self.presentGSImageViewerController(imageView: imageView)
    }
    
}
//MARK: COLLECTION VIEW DELEGATE FLOWLAYOUT METHODS
extension VenuePhotoGallery: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height
        let width = collectionView.frame.width
        let size = CGSize(width: width, height: height)
        return size
    }
}

extension VenuePhotoGallery {
    func presentGSImageViewerController(imageView: UIImageView) {
        let image = imageView.image ?? UIImage(named: "ImagePlaceHolder") ?? UIImage()
        let imageInfo      = GSImageInfo(image: image , imageMode: .aspectFit)
        let transitionInfo = GSTransitionInfo(fromView: imageView)
        let imageViewer    = GSImageViewerController(imageInfo: imageInfo, transitionInfo: transitionInfo)
        self.present(imageViewer, animated: true, completion: nil)
    }
}
