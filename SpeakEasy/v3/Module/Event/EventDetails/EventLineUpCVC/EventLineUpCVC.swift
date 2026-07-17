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
    
    let artistEmptyIcon = UIImage(named: "artistEmptyIcon")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = imageView.bounds.height / 2
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.sd_cancelCurrentImageLoad()
        imageView.image = artistEmptyIcon
        nameLbl.text = nil
    }

    deinit {
        imageView.sd_cancelCurrentImageLoad()
    }
    
    func configure(with artistData: ArtistData) {

        let artist = artistData.artist

        imageShimmerView.isHidden = false
        textSimmerView.isHidden = false

        nameLbl.text = artist.name
        textSimmerView.isHidden = true

        let imageKey = artist.artistImage?.key ?? ""

        var finalURLString = imageKey

        // Handle relative URL
        if !imageKey.isEmpty && !imageKey.lowercased().hasPrefix("http") {
            finalURLString = "\(SharedURL.amazonStorage)\(imageKey)"
        }

        if let url = URL(string: finalURLString), !finalURLString.isEmpty {

            let scale = UIScreen.main.scale
            let targetSize = CGSize(
                width: imageView.bounds.width * scale,
                height: imageView.bounds.height * scale
            )

            imageView.sd_setImage(
                with: url,
                placeholderImage: artistEmptyIcon,
                options: [
                    
                    .continueInBackground,
                    .scaleDownLargeImages
                ],
                context: [
                    .imageThumbnailPixelSize: NSValue(cgSize: targetSize)
                ],
                progress: nil
            ) { [weak self] image, _, _, _ in

                guard let self = self else { return }

                if image == nil {
                    self.imageView.image = artistEmptyIcon
                }

                self.imageShimmerView.isHidden = true
            }

        } else {
            imageView.image = artistEmptyIcon
            imageShimmerView.isHidden = true
        }
    }
}
