//
//  GalleryCVC.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 15/09/2022.
//

import UIKit

class GalleryCVC: UICollectionViewCell {
    
    @IBOutlet weak var imgGallery: UIImageView!
    
    func setData(data: String){
        self.imgGallery.image = UIImage(named: data)
    }
}
