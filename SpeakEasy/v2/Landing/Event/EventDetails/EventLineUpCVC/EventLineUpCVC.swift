//
//  EventLineUpCVC.swift
//  eventDeatilModule
//
//  Created by MAC on 06/02/26.
//

import UIKit

class EventLineUpCVC: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.cornerRadius = imageView.frame.height / 2
           imageView.clipsToBounds = true
    }
    
    func configure(with artistData: ArtistData) {
          
          let artist = artistData.artist
          nameLbl.text = artist.name
          
          if let imageKey = artist.artistImage?.key,
             !imageKey.isEmpty {
              
              imageView.sd_setImage(
                  with: URL(string: imageKey),
                  placeholderImage: UIImage(named: "placeholder")
              )
              
          } else {
              imageView.image = UIImage(named: "placeholder")
          }
      }
}
