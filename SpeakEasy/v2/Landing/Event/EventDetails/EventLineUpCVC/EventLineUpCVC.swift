//
//  EventLineUpCVC.swift
//  eventDeatilModule
//
//  Created by MAC on 06/02/26.
//

import UIKit
import SDWebImage

class EventLineUpCVC: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var imageShimmerView: UIView!
    @IBOutlet weak var textSimmerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true
    }

    func configure(with artistData: ArtistData) {

        let artist = artistData.artist
        imageShimmerView.isHidden = false
        textSimmerView.isHidden = false

        nameLbl.text = artist.name
        textSimmerView.isHidden = true

        if let imageKey = artist.artistImage?.key,
           let url = URL(string: imageKey),
           !imageKey.isEmpty {

            imageView.sd_setImage(with: url, placeholderImage: nil) { [weak self] _, _, _, _ in
                guard let self = self else { return }
                self.imageShimmerView.isHidden = true
            }

        } else {
            imageView.image = UIImage(named: "placeholder")
            imageShimmerView.isHidden = true
        }
    }
}
