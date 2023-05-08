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
    @IBOutlet weak var liveLbl: UILabelDeviceClass!
    @IBOutlet weak var logoImg: UIImageView!
    @IBOutlet weak var coverLbl: UILabelDeviceClass!
    @IBOutlet weak var eventNameLbl: UILabelDeviceClass!
    @IBOutlet weak var locationLbl: UILabelDeviceClass!
    @IBOutlet weak var updatedAtLbl: UILabelDeviceClass!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setData(data: ClipVenue) {
        let imgUrl = "https://speakeasy-storage.s3.amazonaws.com/\(data.venueAttachment.first?.key ?? "")"
        let logoUrl = "https://speakeasy-storage.s3.amazonaws.com/\(data.logo?.key ?? "")"
        self.venueEventImg.sd_setImage(with: URL( string: imgUrl), completed: nil)
        self.logoImg.sd_setImage(with: URL( string: logoUrl), completed: nil)
        self.eventNameLbl.text = data.name
        self.locationLbl.text = data.address
        self.updatedAtLbl.text = "Updated: \(data.updatedAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .hmm_a) )"
        if let ticket = data.lowestPriceTicket {
            if ticket.price < 5 && ticket.name.lowercased().contains("general") == true {
                coverLbl.text = "FREE"
            } else {
                coverLbl.text = "$\(ticket.price)"
            }
        } else {
            coverLbl.text = ""
        }
        if data.bookingStatus == "OPEN" {
            self.liveLbl.text = data.displayWaitTime
            self.liveLbl.textColor = UIColor(red: 0/255, green: 255/255, blue: 148/255, alpha: 1)
        } else {
            self.liveLbl.text = "CLOSED"
            self.liveLbl.textColor = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1)
        }
    }
}
