//
//  FullScreenImgVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 25/04/23.
//

import UIKit

final class FullScreenImgVC: UIViewController {

    @IBOutlet private weak var mainImg: UIImageView!
    @IBOutlet private weak var imgHeightConstraint: NSLayoutConstraint!
    
    var imgURL = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainImg.sd_setImage(with: URL(string: imgURL)) { img, _, _, _ in
            if let image = img {
                self.resizeLandscapeImageView(imageViewFrameWidth: UIScreen.main.bounds.width - 20, image: image)
            }
        }
    }
    
    private func resizeLandscapeImageView(imageViewFrameWidth: CGFloat, image: UIImage) {
        let widthOffset = image.size.width - imageViewFrameWidth
        let widthOffsetPercentage = (widthOffset * 100) / image.size.width
        let heightOffset = (widthOffsetPercentage * image.size.height) / 100
        let effectiveHeight = image.size.height - heightOffset
        imgHeightConstraint.constant = effectiveHeight
    }

    @IBAction private func onClickBack(_ sender: Any) {
        dismiss(animated: true)
    }
}
