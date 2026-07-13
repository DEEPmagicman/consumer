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

        let imageKey = artist.artistImage?.key ?? ""

        var finalURLString = imageKey

        // ✅ Handle relative URL
        if !imageKey.isEmpty && !imageKey.lowercased().hasPrefix("http") {
            finalURLString = "\(SharedURL.amazonStorage)\(imageKey)"
        }

        if let url = URL(string: finalURLString), !finalURLString.isEmpty {

            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "artistEmptyIcon")) { [weak self] image, _, _, _ in
                if image == nil {
                    self?.imageView.image = UIImage(named: "artistEmptyIcon")
                }
                self?.imageShimmerView.isHidden = true
            }
        } else {
            imageView.image = UIImage(named: "artistEmptyIcon")
            imageShimmerView.isHidden = true
        }
    }
}
