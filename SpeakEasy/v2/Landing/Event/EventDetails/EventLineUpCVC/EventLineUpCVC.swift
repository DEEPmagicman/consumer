//
//  EventLineUpCVC.swift
//  eventDeatilModule
//
//  Created by MAC on 06/02/26.
//

import UIKit

class EventLineUpCVC: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.cornerRadius = imageView.frame.height / 2
           imageView.clipsToBounds = true
    }

}
