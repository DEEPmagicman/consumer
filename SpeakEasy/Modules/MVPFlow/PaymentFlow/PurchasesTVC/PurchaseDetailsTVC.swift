//
//  PurchaseDetailsTVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 29/11/23.
//

import UIKit

class PurchaseDetailsTVC: UITableViewCell {

    @IBOutlet weak var ticketCountLbl: UILabel!
    @IBOutlet weak var ticketTypeImage: UIImageView!
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var monthLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
//    @IBOutlet weak var eventNameLbl: UILabel!
    @IBOutlet weak var eventNameLbl: UILabel!
    @IBOutlet weak var cityNameLbl: UILabel!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var venueLogoImageView: UIImageView!
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    
    private var venueImgHeightObservation: NSKeyValueObservation?
    private var gradient: CAGradientLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    func setUI() {
        let path = UIBezierPath(roundedRect: blurView.bounds, byRoundingCorners: [.topRight, .bottomLeft], cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        blurView.layer.mask = maskLayer
        gradient = bgImage.setGradientColor()
        venueImgHeightObservation = bgImage.observe(\.bounds, options: []) { [weak self] _, _ in
            self?.gradient = self?.bgImage.setGradientColor()
        }
    }
}
