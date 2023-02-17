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
    @IBOutlet weak var waitTimeLbl: UILabelDeviceClass!
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func setData(data: ClipVenue) {
        let imgUrl = "https://speakeasy-storage.s3.amazonaws.com/\(data.venueAttachment.first?.key ?? "")"
        let logoUrl = "https://speakeasy-storage.s3.amazonaws.com/\(data.logo?.key ?? "")"
        self.venueEventImg.sd_setImage(with: URL( string: imgUrl), completed: nil)
        self.logoImg.sd_setImage(with: URL( string: logoUrl), completed: nil)
        self.eventNameLbl.text = data.name
        self.waitTimeLbl.text = data.bookingWaiting
        data.appClipTicket?.forEach({ ganral in
            if ganral.name == "GENERALTICKET" {
                self.coverLbl.text = "$\(ganral.price)"
            }
        })
        if data.bookingStatus == "OPEN" {
            self.liveLbl.text = "LIVE"
            self.liveLbl.textColor = UIColor(red: 84/255, green: 209/255, blue: 24/255, alpha: 1)
        } else {
            self.liveLbl.text = "CLOSED"
            self.liveLbl.textColor = UIColor(red: 114/255, green: 114/255, blue: 114/255, alpha: 1)
        }
    }

    
}
