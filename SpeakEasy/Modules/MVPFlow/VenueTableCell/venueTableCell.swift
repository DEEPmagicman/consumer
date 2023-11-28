//
//  venueTableCell.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit
import SDWebImage

class venueTableCell: UITableViewCell {

    @IBOutlet weak var venueEventImg: UIImageView!
    @IBOutlet weak var liveLbl: UILabel!
    @IBOutlet weak var logoImg: UIImageView!
    @IBOutlet weak var coverLbl: UILabelDeviceClass!
    @IBOutlet weak var eventNameLbl: UILabelDeviceClass!
    @IBOutlet weak var liveView: UIView!
    @IBOutlet weak var bookNow: UILabelDeviceClass!
    @IBOutlet weak var bookNowHeight: NSLayoutConstraint!
//    @IBOutlet weak var updatedAtLbl: UILabelDeviceClass!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setData(data: ClipVenue) {
        let imgUrl = "\(SharedURL.amazonStorage)\(data.venueAttachment.first?.key ?? "")"
        let logoUrl = "\(SharedURL.amazonStorage)\(data.logo?.key ?? "")"
        self.venueEventImg.sd_setImage(with: URL( string: imgUrl), completed: nil)
        self.logoImg.sd_setImage(with: URL( string: logoUrl), completed: nil)
        self.eventNameLbl.text = data.name
//        self.locationLbl.text = data.address
//        self.updatedAtLbl.text = data.updatedAt.displayUpdatedAgo(from: .yyyyMMddTHHmmssSSSz, to: .hmm_a)
        let path = UIBezierPath(roundedRect: liveView.bounds, byRoundingCorners: [.topRight, .bottomLeft], cornerRadii: CGSize(width: 10, height: 10))
        let maskLayer = CAShapeLayer()

        maskLayer.path = path.cgPath
        liveView.layer.mask = maskLayer
        if let ticket = data.lowestPriceTicket {
            if ticket.price < 2 && ticket.name.lowercased().contains("general") == true {
                coverLbl.text = "FREE"
            } else {
                coverLbl.text = "\(data.venueSettings?.currencySymbol ?? "$")\(Double(ticket.price).decimalFormat(true))"
            }
        } else {
            coverLbl.text = ""
        }
        if data.bookingStatus == "OPEN" {
            liveLbl.isHidden = false
            liveView.isHidden = false
            bookNow.isHidden = false
            coverLbl.isHidden = false
            bookNowHeight.constant = 20
        } else {
            liveLbl.isHidden = true
            liveView.isHidden = true
            bookNow.isHidden = true
            coverLbl.isHidden = true
            bookNowHeight.constant = 0
        }
    }
}
